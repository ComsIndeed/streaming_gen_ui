import 'dart:io';
import 'package:flutter/material.dart';
import 'package:project_mini_models/core/chat_core_service/chat_core_service.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';

String _getApiKey() {
  const compileTimeKey = String.fromEnvironment('GROQ_API_KEY');
  if (compileTimeKey.isNotEmpty) return compileTimeKey;

  final processEnvKey = Platform.environment['GROQ_API_KEY'];
  if (processEnvKey != null && processEnvKey.isNotEmpty) return processEnvKey;

  try {
    final paths = ['.env', '../.env', '../../.env'];
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        final lines = file.readAsLinesSync();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('GROQ_API_KEY=')) {
            final value = trimmed.substring('GROQ_API_KEY='.length).trim();
            if (value.isNotEmpty) return value;
          }
        }
      }
    }
  } catch (_) {}

  return '';
}

class HomepageProvider with ChangeNotifier {
  // ------ Panel ------
  bool _showPanel = false;
  bool get showPanel => _showPanel;
  void togglePanel() {
    _showPanel = !_showPanel;
    notifyListeners();
  }

  // ------ Textfield ------

  // ------ Streaming Gen UI ------
  final StreamingGenerativeUi genUi = StreamingGenerativeUi(registries: []);
  String? _activeStreamId;
  String? get activeStreamId => _activeStreamId;

  final Set<String> _restoredViewIds = {};

  void restoreMessageView(String viewId, String raw) {
    if (!_restoredViewIds.contains(viewId)) {
      _restoredViewIds.add(viewId);
      genUi.restore(viewId: viewId, raw: raw);
    }
  }

  // ------ Chat Session ------
  List<ChatMessage> get history => chatSession.messages;

  final chatSession = ChatSession(
    systemPrompt: 'You are a helpful assistant.',
    modelConfig: ModelConfig(
      baseUrl: 'https://api.groq.com/openai/v1',
      modelName: 'llama-3.1-8b-instant',
      apiKey: _getApiKey(),
    ),
  );

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final streamId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    _activeStreamId = streamId;
    notifyListeners();

    try {
      final stream = chatSession.sendMessage(message);
      await genUi.stream(
        stream,
        viewId: streamId,
        onComplete: (fullText) {
          _restoredViewIds.add(streamId);
        },
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      _activeStreamId = null;
      notifyListeners();
    }
  }

  void clearHistory() {
    chatSession.clearChat();
    for (final viewId in _restoredViewIds) {
      genUi.disposeView(viewId);
    }
    _restoredViewIds.clear();
    if (_activeStreamId != null) {
      genUi.disposeView(_activeStreamId!);
      _activeStreamId = null;
    }
    notifyListeners();
  }
}
