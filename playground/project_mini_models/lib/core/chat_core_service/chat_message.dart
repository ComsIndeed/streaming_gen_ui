/// Role of a chat message.
enum Role { user, model, system }

/// A single message in a chat conversation.
class ChatMessage {
  final Role role;
  final String content;

  const ChatMessage({required this.role, required this.content});

  /// Converts to the API-expected JSON format.
  /// "model" role is mapped to "assistant" for OpenAI compatibility.
  Map<String, dynamic> toJson() => {
    'role': role == Role.model ? 'assistant' : role.name,
    'content': content,
  };

  @override
  String toString() => '[$role]: $content';
}
