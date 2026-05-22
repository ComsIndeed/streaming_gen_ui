import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dartantic_ai/dartantic_ai.dart';

class ChatAgentService {
  final Agent _agent;

  ChatAgentService._(this._agent);

  /// Factory constructor to create and configure the Agent.
  /// Throws an ArgumentError if the DeepSeek API Key is missing.
  factory ChatAgentService.create() {
    final apiKey = _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw ArgumentError(
        'Missing DEEPSEEK_API_KEY environment variable. '
        'Please define it via Platform environment or --dart-define=DEEPSEEK_API_KEY=your_key.',
      );
    }

    final provider = OpenAIProvider(
      apiKey: apiKey,
      baseUrl: Uri.parse('https://api.deepseek.com/v1'),
    );

    final agent = Agent.forProvider(
      provider,
      chatModelName: 'deepseek-v4-flash',
    );

    return ChatAgentService._(agent);
  }

  /// Streams the agent's response for a given prompt and conversational history.
  /// Converts the chunk output stream to a standard `Stream<String>` of text deltas.
  Stream<String> streamResponse(String prompt, List<ChatMessage> history) {
    return _agent
        .sendStream(prompt, history: history)
        .map((chunk) => chunk.output);
  }

  static String? _getApiKey() {
    const envKey = String.fromEnvironment('DEEPSEEK_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    if (!kIsWeb) {
      return Platform.environment['DEEPSEEK_API_KEY'];
    }
    return null;
  }
}
