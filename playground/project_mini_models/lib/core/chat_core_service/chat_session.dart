import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ollama_dart/ollama_dart.dart' as ollama;

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

    if (model.isOllama) {
      final ollamaClient = ollama.OllamaClient.withBaseUrl(model.baseUrl);
      final ollamaMessages = <ollama.ChatMessage>[];

      // Inject instructions as system message
      if (model.instructions != null) {
        ollamaMessages.add(ollama.ChatMessage(
          role: ollama.MessageRole.system,
          content: model.instructions!,
        ));
      }

      // Inject history
      for (final msg in messages) {
        ollamaMessages.add(ollama.ChatMessage(
          role: msg.role == Role.user
              ? ollama.MessageRole.user
              : msg.role == Role.model
                  ? ollama.MessageRole.assistant
                  : ollama.MessageRole.system,
          content: msg.content,
        ));
      }

      final request = ollama.ChatRequest(
        model: model.modelName,
        messages: ollamaMessages,
        think: const ollama.ThinkValue.enabled(false), // Set to no think
      );

      final ollamaStream = ollamaClient.chat.createStream(request: request);
      final buffer = StringBuffer();

      try {
        await for (final chunk in ollamaStream) {
          final text = chunk.message?.content;
          if (text != null && text.isNotEmpty) {
            buffer.write(text);
            yield text;
          }
        }
      } finally {
        ollamaClient.close();
      }

      final fullResponse = buffer.toString();
      if (fullResponse.isNotEmpty) {
        messages.add(ChatMessage(role: Role.model, content: fullResponse));
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

  void clearChat() => messages.removeWhere((msg) => msg.role != Role.system);
}
