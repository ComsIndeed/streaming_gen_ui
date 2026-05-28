/// Role of a chat message.
enum Role { user, model, system }

/// A single message in a chat conversation.
class ChatMessage {
  final Role role;
  final String content;

  /// Optional thinking/chain-of-thought text (rendered differently in UI).
  final String? thinking;

  /// Whether this message is a primer (sample conversation injected before
  /// the real chat starts). Primers are rendered with reduced opacity in the UI.
  final bool isPrimer;

  const ChatMessage({
    required this.role,
    required this.content,
    this.thinking,
    this.isPrimer = false,
  });

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
