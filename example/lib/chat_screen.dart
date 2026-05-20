import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';

class ChatMessage {
  final String sender; // 'user' or 'assistant'
  String rawText;
  String cleanText;
  final String viewId;
  final StreamController<String> streamController;

  ChatMessage({
    required this.sender,
    required this.rawText,
    required this.cleanText,
    required this.viewId,
    required this.streamController,
  });
}

class ChatScreen extends StatefulWidget {
  final StreamingGenerativeUi genUi;

  const ChatScreen({super.key, required this.genUi});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _apiKey = '';
  bool _isSending = false;
  bool _showApiKey = true;
  bool _showRawText = false; // The switcher state: Raw vs Parsed

  @override
  void dispose() {
    for (final msg in _messages) {
      msg.streamController.close();
    }
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    if (_apiKey.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your Gemini API Key first!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        _showApiKey = true;
      });
      return;
    }

    _textController.clear();
    final userViewId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final userController = StreamController<String>.broadcast();

    setState(() {
      _messages.add(ChatMessage(
        sender: 'user',
        rawText: text,
        cleanText: text,
        viewId: userViewId,
        streamController: userController,
      ));
      _isSending = true;
      _showApiKey = false; // Auto-collapse API key banner once active
    });
    _scrollToBottom();

    // AI message setup
    final aiViewId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    final aiController = StreamController<String>.broadcast();
    final aiMessage = ChatMessage(
      sender: 'assistant',
      rawText: '',
      cleanText: '',
      viewId: aiViewId,
      streamController: aiController,
    );

    setState(() {
      _messages.add(aiMessage);
    });
    _scrollToBottom();

    // Pipe the AI stream controller directly into our Generative UI engine!
    widget.genUi.stream(
      aiController.stream,
      viewId: aiViewId,
      onText: (textChunk) {
        aiMessage.cleanText += textChunk;
        if (!_showRawText) {
          setState(() {});
          _scrollToBottom();
        }
      },
    );

    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.postUrl(Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions',
      ));
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $_apiKey');

      // Create history payload
      final history = <Map<String, String>>[];
      // Seed with our dynamic registry system prompt!
      history.add({
        'role': 'system',
        'content': widget.genUi.registry.systemPromptFragment +
            '\n\nCRITICAL: Always generate valid custom/core widgets when requested. If asked to recommend hotels or show profiles, leverage the specific custom widgets: `custom:user_profile` and `custom:hotel_card`.',
      });

      for (var i = 0; i < _messages.length - 1; i++) {
        final m = _messages[i];
        history.add({
          'role': m.sender,
          'content': m.rawText,
        });
      }

      final payload = {
        'model': 'gemini-3-flash-preview',
        'messages': history,
        'stream': true,
      };

      request.write(jsonEncode(payload));
      final response = await request.close();

      if (response.statusCode != 200) {
        final errorBody = await response.transform(utf8.decoder).join();
        throw Exception('API error (${response.statusCode}): $errorBody');
      }

      await for (final line in response
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final dataStr = line.substring(6).trim();
          if (dataStr == '[DONE]') break;
          try {
            final data = jsonDecode(dataStr);
            final content = data['choices'][0]['delta']['content'] as String?;
            if (content != null && content.isNotEmpty) {
              aiMessage.rawText += content;
              aiController.add(content);
              if (_showRawText) {
                setState(() {});
                _scrollToBottom();
              }
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      setState(() {
        aiMessage.rawText = 'Failed to connect to AI: $e';
        aiMessage.cleanText = 'Failed to connect to AI: $e';
      });
    } finally {
      aiController.close();
      client?.close();
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Collapsible API Key settings
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _showApiKey ? 120 : 45,
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🔑 Gemini API Configuration (OpenAI Compatibility)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(_showApiKey ? Icons.expand_less : Icons.expand_more),
                        onPressed: () {
                          setState(() {
                            _showApiKey = !_showApiKey;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_showApiKey) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: 'Enter your Gemini API Key...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _apiKey = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showApiKey = false;
                            });
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        // Chat viewport
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ask Gemini to display dynamic widgets!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'E.g. "Create a profile for Vincent Sanicolas using blue theme"',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      Text(
                        'or "Show me a nice hotel card for Paris"',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg.sender == 'user';
                    final dispText = isUser ? msg.rawText : (_showRawText ? msg.rawText : msg.cleanText);

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isUser ? 16 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUser ? 'You' : 'Gemini AI',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: isUser
                                    ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Message content
                            if (isUser)
                              Text(
                                dispText,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              )
                            else if (_showRawText)
                              Text(
                                dispText.isEmpty ? 'Thinking...' : dispText,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              )
                            else ...[
                              if (msg.cleanText.isEmpty)
                                Text(
                                  'Thinking...',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              else
                                widget.genUi.view(msg.viewId),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        // Input bar with parsed/raw switcher
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Ask anything, or request components...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              // Segmented toggle container for parsed vs raw mode
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Show Parsed UI (Generative UI)',
                      icon: Icon(
                        Icons.dashboard_customize_outlined,
                        color: !_showRawText ? Theme.of(context).colorScheme.primary : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _showRawText = false;
                        });
                      },
                    ),
                    IconButton(
                      tooltip: 'Show Raw LLM Stream',
                      icon: Icon(
                        Icons.code,
                        color: _showRawText ? Theme.of(context).colorScheme.primary : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _showRawText = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
