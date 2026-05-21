import 'package:flutter_bloc/flutter_bloc.dart';

enum TextBoxMode { textfield, media, view }

enum CanvasMode { hidden, code, document, ui }

class ChatDemoCubit extends Cubit<ChatDemoEvent> {
  TextBoxMode textBoxMode = .textfield;
  CanvasMode canvasMode = .code;

  ChatDemoCubit() : super(InitialChatDemoEvent());
}

abstract class ChatDemoEvent {}

class InitialChatDemoEvent extends ChatDemoEvent {}
