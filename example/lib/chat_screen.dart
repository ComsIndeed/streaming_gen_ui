import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
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
  bool _lockScrollToBottom = true; // Scroll lock default is active
  bool _isAutoScrolling = false; // Track programmatic scrolls

  bool _enableSpeedLimit = false; // By default off
  double _speedFactor = 1.0; // 0.01 to 1.0

  Stream<String> _throttleStream(Stream<String> sourceStream) async* {
    if (!_enableSpeedLimit) {
      yield* sourceStream;
      return;
    }

    final random = math.Random();

    await for (final chunk in sourceStream) {
      // Scale delay based on the Speedometer factor
      int i = 0;
      while (i < chunk.length) {
        // Randomized small chunk sizes between 1 and 3 characters
        final size = random.nextInt(3) + 1;
        final end = (i + size < chunk.length) ? i + size : chunk.length;
        final subChunk = chunk.substring(i, end);
        yield subChunk;
        i = end;

        // Scale randomized base delay by the speed factor
        final baseDelayMs = random.nextInt(20) + 10; // 10ms to 30ms base delay
        final scaledDelayMs = (baseDelayMs / _speedFactor).round();
        await Future.delayed(Duration(milliseconds: scaledDelayMs));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadEnvApiKey();
    _scrollController.addListener(_onScroll);
  }

  void _loadEnvApiKey() {
    try {
      // 1. Try reading from environment define first
      final envKey = const String.fromEnvironment('GEMINI_API_KEY');
      if (envKey.isNotEmpty && envKey != 'YOUR_GEMINI_API_KEY_HERE') {
        setState(() {
          _apiKey = envKey;
          _showApiKey = false;
        });
        debugPrint(
          'Loaded GEMINI_API_KEY from environment define successfully!',
        );
        return;
      }

      // 2. Try reading from local files (.env) at root or example root
      final possiblePaths = ['.env', 'example/.env', '../.env'];

      for (final path in possiblePaths) {
        final file = File(path);
        if (file.existsSync()) {
          final lines = file.readAsLinesSync();
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.startsWith('GEMINI_API_KEY=')) {
              final key = trimmed.split('=').sublist(1).join('=').trim();
              // Remove quotes if present
              var cleanKey = key;
              if ((cleanKey.startsWith("'") && cleanKey.endsWith("'")) ||
                  (cleanKey.startsWith('"') && cleanKey.endsWith('"'))) {
                cleanKey = cleanKey.substring(1, cleanKey.length - 1);
              }
              if (cleanKey.isNotEmpty &&
                  cleanKey != 'YOUR_GEMINI_API_KEY_HERE') {
                setState(() {
                  _apiKey = cleanKey;
                  _showApiKey = false;
                });
                debugPrint('Loaded GEMINI_API_KEY from $path successfully!');
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load local .env key: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    for (final msg in _messages) {
      msg.streamController.close();
    }
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_lockScrollToBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _isAutoScrolling = true;
        _scrollController
            .animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            )
            .then((_) {
              _isAutoScrolling = false;
            });
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isAutoScrolling) return;

    final threshold = 20.0;
    final isAtBottom =
        _scrollController.position.pixels >=
        (_scrollController.position.maxScrollExtent - threshold);

    if (isAtBottom && !_lockScrollToBottom) {
      setState(() {
        _lockScrollToBottom = true;
      });
    } else if (!isAtBottom && _lockScrollToBottom) {
      setState(() {
        _lockScrollToBottom = false;
      });
    }
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
    final userController = StreamController<String>();

    setState(() {
      _messages.add(
        ChatMessage(
          sender: 'user',
          rawText: text,
          cleanText: text,
          viewId: userViewId,
          streamController: userController,
        ),
      );
      _isSending = true;
      _showApiKey = false; // Auto-collapse API key banner once active
    });
    _scrollToBottom();

    // AI message setup
    final aiViewId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    final aiController = StreamController<String>();
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

    // 1. Create a throttled/delayed stream from the original raw controller stream
    final throttledAiStream = _throttleStream(
      aiController.stream,
    ).asBroadcastStream();

    // 2. Pipe the throttled stream directly into our Generative UI engine!
    widget.genUi.stream(
      throttledAiStream,
      viewId: aiViewId,
      onText: (textChunk) {
        aiMessage.cleanText += textChunk;
        if (!_showRawText) {
          setState(() {});
          _scrollToBottom();
        }
      },
    );

    // 3. Listen to the throttled stream to update the raw text in raw mode at the matching speed!
    final throttledSubscription = throttledAiStream.listen(
      (chunk) {
        aiMessage.rawText += chunk;
        if (_showRawText) {
          setState(() {});
          _scrollToBottom();
        }
      },
      onError: (err) {
        debugPrint('Throttled stream error: $err');
      },
    );

    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.postUrl(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions',
        ),
      );
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $_apiKey');

      // Create history payload
      final history = <Map<String, String>>[];
      // Seed with our dynamic registry system prompt!
      history.add({
        'role': 'system',
        'content':
            '${widget.genUi.registry.systemPromptFragment}\n\nCRITICAL: Always generate valid custom/core widgets when requested. If asked to recommend hotels or show profiles, leverage the specific custom widgets: `custom:user_profile` and `custom:hotel_card`.',
      });

      for (var i = 0; i < _messages.length - 1; i++) {
        final m = _messages[i];
        history.add({'role': m.sender, 'content': m.rawText});
      }

      final payload = {
        'model': 'gemma-4-26b-a4b-it',
        'messages': history,
        'stream': true,
      };

      request.write(jsonEncode(payload));
      final response = await request.close();

      if (response.statusCode != 200) {
        final errorBody = await response.transform(utf8.decoder).join();
        throw Exception('API error (${response.statusCode}): $errorBody');
      }

      await for (final line
          in response.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final dataStr = line.substring(6).trim();
          if (dataStr == '[DONE]') break;
          try {
            final data = jsonDecode(dataStr);
            final content = data['choices'][0]['delta']['content'] as String?;
            if (content != null && content.isNotEmpty) {
              // Add direct content to our controller, which feeds the throttled delayed stream!
              aiController.add(content);
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
      await throttledSubscription.cancel();
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
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.4),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
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
                        icon: Icon(
                          _showApiKey ? Icons.expand_less : Icons.expand_more,
                        ),
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
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
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
        // Speedometer / Throttle Simulator Control Panel
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Row(
            children: [
              Icon(
                Icons.speed_outlined,
                color: _enableSpeedLimit
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '⚡ Stream Speedometer:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: _enableSpeedLimit
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _enableSpeedLimit,
                onChanged: (val) {
                  setState(() {
                    _enableSpeedLimit = val;
                  });
                },
              ),
              if (_enableSpeedLimit) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'Delay Factor:',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Expanded(
                        child: Slider(
                          value: _speedFactor,
                          min: 0.01,
                          max: 1.0,
                          onChanged: (val) {
                            setState(() {
                              _speedFactor = val;
                            });
                          },
                        ),
                      ),
                      Text(
                        _speedFactor == 1.0
                            ? 'Full Speed'
                            : '${(_speedFactor * 100).round()}% (${(1.0 / _speedFactor).toStringAsFixed(0)}x slower)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Spacer(),
                const Text(
                  'Running at full API speed',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        // Chat viewport
        Expanded(
          child: Stack(
            children: [
              _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Ask Gemini to display dynamic widgets!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'E.g. "Create a profile for Vincent Sanicolas using blue theme"',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            'or "Show me a nice hotel card for Paris"',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
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
                        final dispText = isUser
                            ? msg.rawText
                            : (_showRawText ? msg.rawText : msg.cleanText);

                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
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
                                        ? Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                              .withValues(alpha: 0.7)
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Message content
                                if (isUser)
                                  Text(
                                    dispText,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    ),
                                  )
                                else if (_showRawText)
                                  Text(
                                    dispText.isEmpty ? 'Thinking...' : dispText,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  )
                                else ...[
                                  if (msg.cleanText.isEmpty)
                                    Text(
                                      'Thinking...',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
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
              if (!_lockScrollToBottom && _messages.isNotEmpty)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    tooltip: 'Scroll to bottom & lock',
                    onPressed: () {
                      setState(() {
                        _lockScrollToBottom = true;
                      });
                      _scrollToBottom();
                    },
                    child: const Icon(Icons.arrow_downward),
                  ),
                ),
            ],
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              // Segmented toggle container for parsed vs raw mode
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Show Parsed UI (Generative UI)',
                      icon: Icon(
                        Icons.dashboard_customize_outlined,
                        color: !_showRawText
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
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
                        color: _showRawText
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
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
              // Scroll lock toggle button
              Container(
                decoration: BoxDecoration(
                  color: _lockScrollToBottom
                      ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _lockScrollToBottom
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3)
                        : Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: IconButton(
                  tooltip: _lockScrollToBottom
                      ? 'Scroll Lock Active'
                      : 'Scroll Lock Disabled',
                  icon: Icon(
                    Icons.vertical_align_bottom,
                    color: _lockScrollToBottom
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  onPressed: () {
                    setState(() {
                      _lockScrollToBottom = !_lockScrollToBottom;
                    });
                    if (_lockScrollToBottom) {
                      _scrollToBottom();
                    }
                  },
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
