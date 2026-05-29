import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ollama_dart/ollama_dart.dart' as ollama;

import 'chat_message.dart';
import 'model_config.dart';

/// A chunk of streamed text containing whether the text is a thinking/reasoning token.
class ChatStreamChunk {
  final String text;
  final bool isThinking;
  const ChatStreamChunk({required this.text, this.isThinking = false});
}

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

  /// Sends a user message and streams the assistant's response as typed [ChatStreamChunk] instances.
  Stream<ChatStreamChunk> sendMessageStream(
    String content, {
    ModelConfig? overrideModel,
  }) async* {
    final model = overrideModel ?? defaultModel;
    if (model == null) {
      throw StateError(
        'No model configured. Set defaultModel or pass overrideModel.',
      );
    }

    final isRealUserMessage = !content.trim().startsWith('<system_results>');
    if (isRealUserMessage) {
      // Surgically remove any previous system reminders from historical user messages
      for (var i = messages.length - 1; i >= 0; i--) {
        final msg = messages[i];
        if (msg.role == Role.user && msg.content.contains('<system_reminder>')) {
          final cleanContent = msg.content.split('<system_reminder>').first.trim();
          messages[i] = ChatMessage(
            role: msg.role,
            content: cleanContent,
            thinking: msg.thinking,
            isPrimer: msg.isPrimer,
          );
          break; // Only the last one needs clearing
        }
      }
    }

    // Append the reminder to the new user message if it is a real human user query
    var finalContent = content;
    if (isRealUserMessage) {
      finalContent = '$content\n\n<system_reminder>Please remember to use <ask_system> to search the web if you need real-time data to answer the user\'s query.</system_reminder>';
    }

    // Immediately persist the user message
    messages.add(ChatMessage(role: Role.user, content: finalContent));

    if (model.isOllama) {
      final ollamaClient = ollama.OllamaClient.withBaseUrl(model.baseUrl);
      final ollamaMessages = <ollama.ChatMessage>[];

      // Inject instructions as system message
      if (model.instructions != null) {
        ollamaMessages.add(
          ollama.ChatMessage(
            role: ollama.MessageRole.system,
            content: model.instructions!,
          ),
        );
      }

      // Inject history
      for (final msg in messages) {
        ollamaMessages.add(
          ollama.ChatMessage(
            role: msg.role == Role.user
                ? ollama.MessageRole.user
                : msg.role == Role.model
                ? ollama.MessageRole.assistant
                : ollama.MessageRole.system,
            content: msg.content,
          ),
        );
      }

      final request = ollama.ChatRequest(
        model: model.modelName,
        messages: ollamaMessages,
      );

      final ollamaStream = ollamaClient.chat.createStream(request: request);
      final contentBuffer = StringBuffer();
      final thinkingBuffer = StringBuffer();

      try {
        await for (final chunk in ollamaStream) {
          final text = chunk.message?.content;
          final thinking = chunk.message?.thinking;
          if (thinking != null && thinking.isNotEmpty) {
            thinkingBuffer.write(thinking);
            yield ChatStreamChunk(text: thinking, isThinking: true);
          }
          if (text != null && text.isNotEmpty) {
            contentBuffer.write(text);
            yield ChatStreamChunk(text: text, isThinking: false);
          }
        }
      } finally {
        ollamaClient.close();
      }

      final fullContent = contentBuffer.toString();
      final fullThinking = thinkingBuffer.toString();
      if (fullContent.isNotEmpty || fullThinking.isNotEmpty) {
        messages.add(
          ChatMessage(
            role: Role.model,
            content: fullContent,
            thinking: fullThinking.isNotEmpty ? fullThinking : null,
          ),
        );
      }
      return; // Stop here!
    }

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
    final responseStream = response.stream.transform(utf8.decoder);
    final buffer = StringBuffer();

    try {
      await for (final chunk in responseStream) {
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
              yield ChatStreamChunk(text: content, isThinking: false);
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

  /// Sends a user message and streams the assistant's response.
  Stream<String> sendMessage(String content, {ModelConfig? overrideModel}) {
    return sendMessageStream(
      content,
      overrideModel: overrideModel,
    ).map((chunk) => chunk.text);
  }

  void clearChat() => messages.removeWhere((msg) => msg.role != Role.system);
}
