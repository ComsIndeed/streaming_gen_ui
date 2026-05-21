import 'package:flutter_bloc/flutter_bloc.dart';

enum TextBoxMode { textfield, media, view }

enum CanvasMode { hidden, code, document, ui }

class ChatDemoState {
  final TextBoxMode textBoxMode;
  final CanvasMode canvasMode;

  const ChatDemoState({
    required this.textBoxMode,
    required this.canvasMode,
  });

  ChatDemoState copyWith({
    TextBoxMode? textBoxMode,
    CanvasMode? canvasMode,
  }) {
    return ChatDemoState(
      textBoxMode: textBoxMode ?? this.textBoxMode,
      canvasMode: canvasMode ?? this.canvasMode,
    );
  }
}

class ChatDemoCubit extends Cubit<ChatDemoState> {
  ChatDemoCubit()
      : super(const ChatDemoState(
          textBoxMode: TextBoxMode.textfield,
          canvasMode: CanvasMode.code,
        ));

  void setTextBoxMode(TextBoxMode mode) {
    emit(state.copyWith(textBoxMode: mode));
  }

  void setCanvasMode(CanvasMode mode) {
    emit(state.copyWith(canvasMode: mode));
  }
}
