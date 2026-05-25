import 'package:flutter/material.dart';
import 'core/chat_core_service/chat_core_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _session = ChatSession(
    systemPrompt: 'You are a helpful assistant.',
    modelConfig: ModelConfig(
      baseUrl: 'https://api.openai.com/v1',
      modelName: 'gpt-3.5-turbo',
      apiKey: 'your-api-key-here',
    ),
  );

  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() => _isLoading = true);

    // Add a placeholder model message for streaming
    final dummyMessage = ChatMessage(role: Role.model, content: '');
    _session.messages.add(dummyMessage);

    try {
      await for (final token in _session.sendMessage(text)) {
        // Update the last message in place as tokens arrive
        final idx = _session.messages.length - 1;
        _session.messages[idx] = ChatMessage(
          role: Role.model,
          content: _session.messages[idx].content + token,
        );
        setState(() {});
        _scrollToBottom();
      }
    } catch (e) {
      _session.messages.removeLast();
      _session.messages.add(
        ChatMessage(role: Role.model, content: 'Error: $e'),
      );
      setState(() {});
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _session.messages.length,
              itemBuilder: (context, index) {
                final msg = _session.messages[index];
                final isUser = msg.role == Role.user;
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blue.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Text(
                      isUser ? msg.content : msg.content,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
