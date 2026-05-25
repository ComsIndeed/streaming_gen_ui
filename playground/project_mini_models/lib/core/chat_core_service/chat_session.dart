import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'chat_message.dart';
import 'model_config.dart';

/// A chat session that stores conversation history and sends messages
/// to an OpenAI-compatible API with streaming enabled by default.
class ChatSession {
  /// Public, mutable conversation history.
  final List<ChatMessage> messages = [];

  /// Default model used when no override is provided to [sendMessage].
  ModelConfig? defaultModel;

  ChatSession({ModelConfig? modelConfig, String? systemPrompt})
    : defaultModel = modelConfig {
    if (systemPrompt != null) {
      messages.add(ChatMessage(role: Role.system, content: systemPrompt));
    }
  }

  /// Replace the default model for this session.
  void changeModel(ModelConfig config) {
    defaultModel = config;
  }

  /// Sends a user message and streams the assistant's response.
  ///
  /// The [content] is immediately added to [messages] as a user message.
  /// The model used is [overrideModel] if provided, otherwise [defaultModel].
  /// Throws [StateError] if no model is configured.
  ///
  /// Yields tokens as they arrive. When the stream completes, the full
  /// assistant response is appended to [messages].
  Stream<String> sendMessage(
    String content, {
    ModelConfig? overrideModel,
  }) async* {
    final model = overrideModel ?? defaultModel;
    if (model == null) {
      throw StateError(
        'No model configured. Set defaultModel or pass overrideModel.',
      );
    }

    // Immediately persist the user message
    messages.add(ChatMessage(role: Role.user, content: content));

    // Build the request payload
    final requestMessages = <Map<String, dynamic>>[];

    // Inject instructions as a system message if configured
    if (model.instructions != null) {
      requestMessages.add({'role': 'system', 'content': model.instructions});
    }

    // Append conversation history
    for (final msg in messages) {
      requestMessages.add(msg.toJson());
    }

    final body = jsonEncode({
      'model': model.modelName,
      'messages': requestMessages,
      'stream': true,
    });

    final request = http.Request('POST', Uri.parse(model.endpoint))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${model.apiKey}',
      })
      ..body = body;

    final client = http.Client();
    final response = await client.send(request);
    final buffer = StringBuffer();

    try {
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        // SSE lines may contain multiple "data:" lines in one chunk
        for (final line in chunk.split('\n')) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data: ')) continue;

          final data = trimmed.substring(6);
          if (data == '[DONE]') continue;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>?;
            if (choices == null || choices.isEmpty) continue;

            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            final content = delta?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              buffer.write(content);
              yield content;
            }
          } catch (_) {
            // Skip malformed SSE lines
          }
        }
      }
    } finally {
      client.close();
    }

    // Persist the full assistant response
    final fullResponse = buffer.toString();
    if (fullResponse.isNotEmpty) {
      messages.add(ChatMessage(role: Role.model, content: fullResponse));
    }
  }
}
