/// Role of a chat message.
enum Role { user, model, system }

/// A single message in a chat conversation.
class ChatMessage {
  final Role role;
  final String content;

  /// Optional thinking/chain-of-thought text (rendered differently in UI).
  final String? thinking;

  const ChatMessage({required this.role, required this.content, this.thinking});

  /// Converts to the API-expected JSON format.
  /// "model" role is mapped to "assistant" for OpenAI compatibility.
  Map<String, dynamic> toJson() => {
    'role': role == Role.model ? 'assistant' : role.name,
    'content': content,
  };

  @override
  String toString() => thinking != null
      ? '[$role] thinking: $thinking\ncontent: $content'
      : '[$role]: $content';
}
