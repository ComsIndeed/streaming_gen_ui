import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/chat_demo_page/chat_agent_service.dart';

enum TextBoxMode { textfield, media, view }

enum CanvasMode { hidden, code, document, ui }

class DemoMessage {
  final String id;
  final bool isUser;
  final String text;

  DemoMessage({
    required this.id,
    required this.isUser,
    required this.text,
  });

  DemoMessage copyWith({String? text}) {
    return DemoMessage(
      id: id,
      isUser: isUser,
      text: text ?? this.text,
    );
  }
}

class ChatDemoState {
  final TextBoxMode textBoxMode;
  final CanvasMode canvasMode;
  final List<DemoMessage> messages;
  final bool isThinking;
  final String? errorMessage;

  const ChatDemoState({
    required this.textBoxMode,
    required this.canvasMode,
    required this.messages,
    required this.isThinking,
    this.errorMessage,
  });

  ChatDemoState copyWith({
    TextBoxMode? textBoxMode,
    CanvasMode? canvasMode,
    List<DemoMessage>? messages,
    bool? isThinking,
    String? errorMessage,
  }) {
    return ChatDemoState(
      textBoxMode: textBoxMode ?? this.textBoxMode,
      canvasMode: canvasMode ?? this.canvasMode,
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  ChatDemoState copyWithClearedError({
    TextBoxMode? textBoxMode,
    CanvasMode? canvasMode,
    List<DemoMessage>? messages,
    bool? isThinking,
  }) {
    return ChatDemoState(
      textBoxMode: textBoxMode ?? this.textBoxMode,
      canvasMode: canvasMode ?? this.canvasMode,
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      errorMessage: null,
    );
  }
}

class ChatDemoCubit extends Cubit<ChatDemoState> {
  final StreamingGenerativeUi generativeUi = StreamingGenerativeUi(
    registry: Registries.all,
  );

  final List<ChatMessage> _history = [];
  ChatAgentService? _agentService;

  ChatDemoCubit()
    : super(
        const ChatDemoState(
          textBoxMode: TextBoxMode.textfield,
          canvasMode: CanvasMode.hidden,
          messages: [],
          isThinking: false,
        ),
      );

  void setTextBoxMode(TextBoxMode mode) {
    emit(state.copyWith(textBoxMode: mode));
  }

  void setCanvasMode(CanvasMode mode) {
    emit(state.copyWith(canvasMode: mode));
  }

  void clearError() {
    emit(state.copyWithClearedError());
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add user message to UI state and internal history
    final userMsgId = 'user-${DateTime.now().millisecondsSinceEpoch}';
    final userMsg = DemoMessage(
      id: userMsgId,
      isUser: true,
      text: text,
    );
    _history.add(ChatMessage.user(text));

    emit(state.copyWithClearedError(
      messages: [...state.messages, userMsg],
      isThinking: true,
    ));

    // 2. Instantiate Agent Service (checks API key)
    try {
      _agentService ??= ChatAgentService.create();
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
        isThinking: false,
      ));
      return;
    }

    // 3. Setup streaming assistant message representation
    final aiMsgId = 'ai-${DateTime.now().millisecondsSinceEpoch}';
    final aiMsg = DemoMessage(
      id: aiMsgId,
      isUser: false,
      text: '',
    );

    emit(state.copyWithClearedError(
      messages: [...state.messages, aiMsg],
    ));

    try {
      final textStream = _agentService!.streamResponse(text, _history);

      await generativeUi.stream(
        textStream,
        viewId: aiMsgId,
        onComplete: (raw) {
          // Add to LLM history for subsequent turns
          _history.add(ChatMessage.model(raw));

          // Update message text when stream completes
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
      emit(state.copyWith(
        errorMessage: 'Streaming error: ${e.toString()}',
        isThinking: false,
      ));
    }
  }
}
