import 'package:flutter/foundation.dart';
import 'package:llm_json_stream/llm_json_stream.dart';

class ViewState extends ChangeNotifier {
  /// Accumulated clean conversational text (Markdown portions outside tag blocks)
  String _conversationalText = '';
  String get conversationalText => _conversationalText;

  /// The root JSON map property stream when parsing starts inside the tag block
  MapPropertyStream? _rootMapStream;
  MapPropertyStream? get rootMapStream => _rootMapStream;

  /// Full raw input text (Conversational + XML tags) accumulated so far
  String _rawContent = '';
  String get rawContent => _rawContent;

  /// Active JSON stream parser
  JsonStreamParser? _jsonParser;
  JsonStreamParser? get jsonParser => _jsonParser;

  /// Whether the interactive tag block has been opened
  bool _hasInteractive = false;
  bool get hasInteractive => _hasInteractive;

  /// Whether the interactive tag block is fully parsed and completed
  bool _isComplete = false;
  bool get isComplete => _isComplete;

  void appendText(String chunk) {
    _conversationalText += chunk;
    notifyListeners();
  }

  void startInteractive(Stream<String> jsonStream) {
    _hasInteractive = true;
    _jsonParser = JsonStreamParser(jsonStream);
    _rootMapStream = _jsonParser!.getMapProperty('');
    notifyListeners();
  }

  void endInteractive() {
    _isComplete = true;
    notifyListeners();
  }

  void updateRawContent(String raw) {
    _rawContent = raw;
    notifyListeners();
  }

  void clear() {
    _conversationalText = '';
    _rootMapStream = null;
    _jsonParser = null;
    _hasInteractive = false;
    _isComplete = false;
    _rawContent = '';
    notifyListeners();
  }
}
