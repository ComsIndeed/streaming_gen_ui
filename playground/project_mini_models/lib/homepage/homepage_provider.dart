import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_mini_models/core/chat_core_service/chat_core_service.dart';

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
  HomepageProvider() {
    _loadPreferences();
  }

  // ------ Panel ------
  bool _showPanel = false;
  bool get showPanel => _showPanel;
  void togglePanel() {
    _showPanel = !_showPanel;
    notifyListeners();
  }

  // ------ View Toggle (Kept for interface but does nothing now) ------
  bool _showRawView = true;
  bool get showRawView => _showRawView;

  // ------ Model Provider Toggle ------
  bool _useOllama = false;
  bool get useOllama => _useOllama;

  static final _groqConfig = ModelConfig(
    baseUrl: 'https://api.groq.com/openai/v1',
    modelName: 'llama-3.1-8b-instant',
    apiKey: _getApiKey(),
  );

  static final _ollamaConfig = const ModelConfig(
    baseUrl: 'http://localhost:11434',
    modelName: 'qwen3.5:0.8b',
    apiKey: '',
    isOllama: true,
  );

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showRawView = prefs.getBool('show_raw_view') ?? true;
      _useOllama = prefs.getBool('use_ollama') ?? false;
      chatSession.changeModel(_useOllama ? _ollamaConfig : _groqConfig);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleRawView() async {
    _showRawView = !_showRawView;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_raw_view', _showRawView);
    } catch (_) {}
  }

  Future<void> toggleModelProvider() async {
    _useOllama = !_useOllama;
    chatSession.changeModel(_useOllama ? _ollamaConfig : _groqConfig);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('use_ollama', _useOllama);
    } catch (_) {}
  }

  // ------ Streaming Accumulation ------
  String? _activeStreamId;
  String? get activeStreamId => _activeStreamId;
  String _activeStreamText = '';
  String get activeStreamText => _activeStreamText;

  // ------ Chat Session ------
  List<ChatMessage> get history => chatSession.messages;

  late final chatSession = ChatSession(
    systemPrompt:
        'You are a helpful assistant. ${MaterialPrompts.systemPrompt}',
    modelConfig: _groqConfig,
  );

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    _activeStreamText = '';
    _activeStreamId = 'active';
    notifyListeners();

    try {
      final stream = chatSession.sendMessage(message);
      await for (final chunk in stream) {
        _activeStreamText += chunk;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      _activeStreamId = null;
      _activeStreamText = '';
      notifyListeners();
    }
  }

  void clearHistory() {
    chatSession.clearChat();
    _activeStreamId = null;
    _activeStreamText = '';
    notifyListeners();
  }
}
