import 'package:flutter/foundation.dart';
import 'package:llm_json_stream/llm_json_stream.dart';

abstract class ViewBlock {}

class TextBlock extends ViewBlock {
  String text = '';
}

class InteractiveBlock extends ViewBlock {
  final String targetViewId;
  final MapPropertyStream rootMapStream;
  bool isComplete = false;

  InteractiveBlock({
    required this.targetViewId,
    required this.rootMapStream,
    this.isComplete = false,
  });
}

class ViewState extends ChangeNotifier {
  final List<ViewBlock> _blocks = [];
  List<ViewBlock> get blocks => _blocks;

  /// Full raw input text (Conversational + XML tags) accumulated so far
  String get rawContent => throw UnimplementedError();

  bool get isProcessing => throw UnimplementedError();

  void setProcessing(bool processing) {
    throw UnimplementedError();
  }

  /// Concatenates all text blocks for conversational markdown queries
  String get conversationalText => throw UnimplementedError();

  /// Whether the view contains any interactive blocks
  bool get hasInteractive => throw UnimplementedError();

  /// Backwards compatibility getter for the primary/first root map stream
  MapPropertyStream? get rootMapStream => throw UnimplementedError();

  /// Backwards compatibility check for complete state
  bool get isComplete => throw UnimplementedError();

  void appendText(String chunk) {
    throw UnimplementedError();
  }

  void startInteractiveBlock(String targetViewId, Stream<String> jsonStream) {
    throw UnimplementedError();
  }

  void endInteractiveBlock(String targetViewId) {
    throw UnimplementedError();
  }

  void updateRawContent(String raw) {
    throw UnimplementedError();
  }

  void appendRaw(String chunk) {
    throw UnimplementedError();
  }

  void clear() {
    throw UnimplementedError();
  }
}
