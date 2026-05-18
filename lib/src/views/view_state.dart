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
  String _rawContent = '';
  String get rawContent => _rawContent;

  /// Concatenates all text blocks for conversational markdown queries
  String get conversationalText => _blocks
      .whereType<TextBlock>()
      .map((b) => b.text)
      .join('');

  /// Whether the view contains any interactive blocks
  bool get hasInteractive => _blocks.any((b) => b is InteractiveBlock);

  /// Backwards compatibility getter for the primary/first root map stream
  MapPropertyStream? get rootMapStream {
    final interactive = _blocks.whereType<InteractiveBlock>();
    return interactive.isNotEmpty ? interactive.first.rootMapStream : null;
  }

  /// Backwards compatibility check for complete state
  bool get isComplete => _blocks.whereType<InteractiveBlock>().every((b) => b.isComplete);

  void appendText(String chunk) {
    if (_blocks.isEmpty || _blocks.last is! TextBlock) {
      _blocks.add(TextBlock()..text = chunk);
    } else {
      (_blocks.last as TextBlock).text += chunk;
    }
    notifyListeners();
  }

  void startInteractiveBlock(String targetViewId, Stream<String> jsonStream) {
    final parser = JsonStreamParser(jsonStream);
    final rootMap = parser.getMapProperty('');
    final block = InteractiveBlock(
      targetViewId: targetViewId,
      rootMapStream: rootMap,
    );
    _blocks.add(block);
    notifyListeners();
  }

  void endInteractiveBlock(String targetViewId) {
    for (int i = _blocks.length - 1; i >= 0; i--) {
      final block = _blocks[i];
      if (block is InteractiveBlock && block.targetViewId == targetViewId) {
        block.isComplete = true;
        break;
      }
    }
    // Prepare a fresh TextBlock to catch subsequent streamed characters
    _blocks.add(TextBlock());
    notifyListeners();
  }

  void updateRawContent(String raw) {
    _rawContent = raw;
    notifyListeners();
  }

  void clear() {
    _blocks.clear();
    _rawContent = '';
    notifyListeners();
  }
}
