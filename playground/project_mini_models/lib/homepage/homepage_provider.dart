import 'package:flutter/material.dart';
import 'package:project_mini_models/core/chat_core_service/chat_core_service.dart';

class HomepageProvider with ChangeNotifier {
  // ------ Panel ------
  bool _showPanel = false;
  bool get showPanel => _showPanel;
  void togglePanel() {
    _showPanel = !_showPanel;
    notifyListeners();
  }

  // ------ Textfield ------

  // ------ Chat Session ------
  List<ChatMessage> get history => chatSession.messages;

  final chatSession = ChatSession(
    systemPrompt: 'You are a helpful assistant.',
    modelConfig: ModelConfig(
      baseUrl: 'https://api.groq.com/openai/v1',
      modelName: 'llama3-8b-8192',
      apiKey: String.fromEnvironment('GROQ_API_KEY'),
    ),
  );

  void sendMessage(String message) {
    final response = chatSession.sendMessage(message);
  }
}
