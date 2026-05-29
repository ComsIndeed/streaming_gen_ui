import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:llm_tag_parser/llm_tag_parser.dart';
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
  bool _showPanel = true;
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

  // ------ Priming Toggle ------
  bool _primingEnabled = false;
  bool get primingEnabled => _primingEnabled;

  // static final _groqConfig = ModelConfig(
  //   baseUrl: 'https://api.groq.com/openai/v1',
  //   modelName: 'llama-3.1-8b-instant',
  //   apiKey: _getApiKey(),
  // );

  static final ModelConfig ollamaConfig = const ModelConfig(
    baseUrl: 'http://localhost:11434',
    modelName: 'qwen3:0.6b',
    apiKey: '',
    isOllama: true,
  );

  static final ModelConfig groqConfig = ModelConfig(
    baseUrl: 'https://api.groq.com/openai/v1',
    modelName: 'llama-3.1-8b-instant',
    apiKey: _getApiKey(),
  );

  /// The shared-preferences key for the priming setting for the current provider.
  String get _primingKey => _useOllama ? 'priming_ollama' : 'priming_groq';

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showRawView = prefs.getBool('show_raw_view') ?? true;
      _useOllama = prefs.getBool('use_ollama') ?? false;
      _primingEnabled =
          prefs.getBool(_primingKey) ?? _useOllama; // default on for Ollama
      _reinitChatSession();
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
    // Load priming pref for the new provider
    try {
      final prefs = await SharedPreferences.getInstance();
      _primingEnabled = prefs.getBool(_primingKey) ?? _useOllama;
    } catch (_) {
      _primingEnabled = _useOllama;
    }
    chatSession.changeModel(_useOllama ? ollamaConfig : groqConfig);
    _reinitChatSession();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('use_ollama', _useOllama);
    } catch (_) {}
  }

  Future<void> togglePriming() async {
    _primingEnabled = !_primingEnabled;
    _reinitChatSession();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_primingKey, _primingEnabled);
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
    modelConfig: ollamaConfig,
    // modelConfig: _groqConfig,
  );

  /// Clears the chat history and rebuilds it from scratch:
  /// system prompt (always) + prime messages (if priming enabled).
  void _reinitChatSession() {
    chatSession.clearChat(); // removes everything except system
    if (_primingEnabled) {
      MaterialPrompts.primeMessages.forEach(chatSession.messages.add);
    }
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    _activeStreamText = '';
    _activeStreamId = 'active';
    notifyListeners();

    String? foundQuery;
    final chunkController = StreamController<String>();
    final parser = LlmTagParser(
      stream: chunkController.stream,
      tags: [
        LlmTag(open: '<ask_system>', close: '</ask_system>'),
      ],
    );

    final parserSubscription = parser.within('<ask_system>').instances.listen((node) {
      node.future.then((value) {
        foundQuery = value.trim();
      });
    });

    try {
      final stream = chatSession.sendMessageStream(message);
      await for (final chunk in stream) {
        _activeStreamText += chunk.text;
        if (!chunk.isThinking) {
          chunkController.add(chunk.text);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      await chunkController.close();
      await parserSubscription.cancel();

      _activeStreamId = null;
      _activeStreamText = '';
      notifyListeners();
    }

    if (foundQuery != null && foundQuery!.isNotEmpty) {
      final query = foundQuery!;
      debugPrint('Intercepted <ask_system> tool query: "$query"');
      
      final systemResults = await fetchDuckDuckGoSearch(query);
      debugPrint('Generated system results:\n$systemResults');

      await sendMessage(systemResults);
    }
  }

  void clearHistory() {
    _reinitChatSession();
    _activeStreamId = null;
    _activeStreamText = '';
    notifyListeners();
  }
}
