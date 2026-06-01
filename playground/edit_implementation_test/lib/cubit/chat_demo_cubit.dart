import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
import 'package:dartantic_ai/dartantic_ai.dart' as ai;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edit_implementation_test/services/chat_agent_service.dart';

class ChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.isError = false,
  });

  ChatMessage copyWith({String? text, bool? isError}) {
    return ChatMessage(
      id: id,
      isUser: isUser,
      text: text ?? this.text,
      isError: isError ?? this.isError,
    );
  }
}

class ChatDemoState {
  final List<ChatMessage> messages;
  final bool isThinking;
  final String? errorMessage;
  final bool showRawView;

  const ChatDemoState({
    required this.messages,
    required this.isThinking,
    this.errorMessage,
    this.showRawView = false,
  });

  ChatDemoState copyWith({
    List<ChatMessage>? messages,
    bool? isThinking,
    String? errorMessage,
    bool? showRawView,
  }) {
    return ChatDemoState(
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      errorMessage: errorMessage ?? this.errorMessage,
      showRawView: showRawView ?? this.showRawView,
    );
  }

  ChatDemoState copyWithClearedError({
    List<ChatMessage>? messages,
    bool? isThinking,
    bool? showRawView,
  }) {
    return ChatDemoState(
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      errorMessage: null,
      showRawView: showRawView ?? this.showRawView,
    );
  }
}

class ChatDemoCubit extends Cubit<ChatDemoState> {
  late StreamingGenerativeUi generativeUi;
  final List<ai.ChatMessage> _history = [];
  ChatAgentService? _agentService;

  StreamSubscription<String>? _currentStreamSubscription;
  StreamController<String>? _currentResponseController;

  ChatDemoCubit()
      : super(const ChatDemoState(messages: [], isThinking: false)) {
    generativeUi = StreamingGenerativeUi(
      registries: [
        Registries.forThemes({'apple'}),
      ],
      customViewIds: const {
        'canvas-ui': 'Renders a dedicated full-screen dynamic mini app, interactive dashboard, or tool requested by the user.',
      },
    );
    _history.add(ai.ChatMessage.system(systemPrompt));
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getBool('show_raw_view') ?? false;
      emit(state.copyWith(showRawView: raw));
    } catch (_) {}
  }

  Future<void> toggleRawView() async {
    final newVal = !state.showRawView;
    emit(state.copyWith(showRawView: newVal));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_raw_view', newVal);
    } catch (_) {}
  }

  String get systemPrompt => '''
You are a helpful AI Assistant demonstrating your ability to show UI components in your chat.
Help the user with their requests. Use the correct widgets.

${generativeUi.systemPrompt}

### GENERAL GUIDELINES:
- For product searches, use product cards. Include images.
- For weather queries, use the weather card.
- For queries that include quantitative data, use charts.
- Only use canvas-ui for explicitly mini-app like requests (e.g., "show me a calculator", "create a timer").
- For everything else, don't use a view ID.
''';

  void clearError() {
    emit(state.copyWithClearedError());
  }

  void stopResponse() {
    if (state.isThinking) {
      _currentStreamSubscription?.cancel();
      _currentStreamSubscription = null;

      if (_currentResponseController != null && !_currentResponseController!.isClosed) {
        _currentResponseController!.close();
      }
      _currentResponseController = null;

      emit(state.copyWith(isThinking: false));
    }
  }

  void clearChat() {
    stopResponse();
    _history.clear();
    _history.add(ai.ChatMessage.system(systemPrompt));
    generativeUi.disposeView('canvas-ui');
    emit(const ChatDemoState(messages: [], isThinking: false));
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsgId = 'user-${DateTime.now().millisecondsSinceEpoch}';
    final userMsg = ChatMessage(id: userMsgId, isUser: true, text: text);
    _history.add(ai.ChatMessage.user(text));

    emit(state.copyWithClearedError(
      messages: [...state.messages, userMsg],
      isThinking: true,
    ));

    try {
      _agentService ??= ChatAgentService.create();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString(), isThinking: false));
      return;
    }

    final aiMsgId = 'ai-${DateTime.now().millisecondsSinceEpoch}';
    final aiMsg = ChatMessage(id: aiMsgId, isUser: false, text: '');

    emit(state.copyWithClearedError(messages: [...state.messages, aiMsg]));

    try {
      final textStream = _agentService!.streamResponse(text, _history);
      _currentResponseController = StreamController<String>();
      final StringBuffer accumulated = StringBuffer();

      _currentStreamSubscription = textStream.listen(
        (chunk) {
          accumulated.write(chunk);

          final updatedMessages = state.messages.map((m) {
            if (m.id == aiMsgId) {
              return m.copyWith(text: accumulated.toString());
            }
            return m;
          }).toList();

          emit(state.copyWith(messages: updatedMessages));

          if (_currentResponseController != null && !_currentResponseController!.isClosed) {
            _currentResponseController!.add(chunk);
          }
        },
        onError: (e) {
          final updatedMessages = state.messages.map((m) {
            if (m.id == aiMsgId) {
              return m.copyWith(
                text: 'Streaming error: ${e.toString()}',
                isError: true,
              );
            }
            return m;
          }).toList();

          emit(state.copyWith(
            messages: updatedMessages,
            errorMessage: 'Streaming error: ${e.toString()}',
            isThinking: false,
          ));
          stopResponse();
        },
        onDone: () {
          if (_currentResponseController != null && !_currentResponseController!.isClosed) {
            _currentResponseController!.close();
          }
        },
      );

      await generativeUi.stream(
        _currentResponseController!.stream,
        viewId: aiMsgId,
        onComplete: (raw) {
          _history.add(ai.ChatMessage.model(raw));

          final updatedMessages = state.messages.map((m) {
            if (m.id == aiMsgId) {
              return m.copyWith(text: raw);
            }
            return m;
          }).toList();

          emit(state.copyWithClearedError(
            messages: updatedMessages,
            isThinking: false,
          ));
        },
      );
    } catch (e) {
      final updatedMessages = state.messages.map((m) {
        if (m.id == aiMsgId) {
          return m.copyWith(
            text: 'Streaming error: ${e.toString()}',
            isError: true,
          );
        }
        return m;
      }).toList();

      emit(state.copyWith(
        messages: updatedMessages,
        errorMessage: 'Streaming error: ${e.toString()}',
        isThinking: false,
      ));
    }
  }

  @override
  Future<void> close() {
    stopResponse();
    return super.close();
  }
}
