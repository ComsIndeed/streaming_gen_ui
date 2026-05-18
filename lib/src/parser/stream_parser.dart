import 'dart:async';

enum ParserState { text, startTag, json }

class StatefulStreamParser {
  final String defaultViewId;
  final void Function(String chunk)? onText;
  final void Function(String fullRaw)? onComplete;
  final void Function(String viewId, Stream<String> jsonStream, String startTag)? onInterfaceBlockStart;
  final void Function(String viewId)? onInterfaceBlockEnd;

  StatefulStreamParser({
    required this.defaultViewId,
    this.onText,
    this.onComplete,
    this.onInterfaceBlockStart,
    this.onInterfaceBlockEnd,
  });

  ParserState _state = ParserState.text;
  String _lookahead = '';
  String _currentViewId = '';
  StreamController<String>? _activeJsonController;
  String _rawAccumulated = '';
  
  void processChunk(String chunk) {
    _rawAccumulated += chunk;
    for (int i = 0; i < chunk.length; i++) {
      final char = chunk[i];
      _processCharacter(char);
    }
  }

  void _processCharacter(String char) {
    switch (_state) {
      case ParserState.text:
        _handleTextChar(char);
        break;
      case ParserState.startTag:
        _handleStartTagChar(char);
        break;
      case ParserState.json:
        _handleJsonChar(char);
        break;
    }
  }
  
  void _handleTextChar(String char) {
    if (_lookahead.isEmpty) {
      if (char == '<') {
        _lookahead = '<';
      } else {
        _emitText(char);
      }
      return;
    }

    final nextLookahead = _lookahead + char;
    const target = '<interface';
    if (target.startsWith(nextLookahead)) {
      _lookahead = nextLookahead;
      if (_lookahead == target) {
        _state = ParserState.startTag;
        _lookahead = '';
      }
    } else {
      _emitText(_lookahead);
      _lookahead = '';
      if (char == '<') {
        _lookahead = '<';
      } else {
        _emitText(char);
      }
    }
  }
  
  void _handleStartTagChar(String char) {
    _lookahead += char;
    if (char == '>') {
      // Start tag completed!
      final fullTag = '<interface$_lookahead';
      // Parse viewId
      String targetViewId = defaultViewId;
      final idx = _lookahead.indexOf('viewId=');
      if (idx != -1 && idx + 7 < _lookahead.length) {
        final quoteChar = _lookahead[idx + 7]; // either " or '
        if (quoteChar == '"' || quoteChar == "'") {
          final startIdx = idx + 8;
          final endIdx = _lookahead.indexOf(quoteChar, startIdx);
          if (endIdx != -1) {
            targetViewId = _lookahead.substring(startIdx, endIdx);
          }
        }
      }
      
      _currentViewId = targetViewId;
      _state = ParserState.json;
      _lookahead = ''; // Clear lookahead for the end-tag check
      
      // Start JSON stream
      _activeJsonController = StreamController<String>();
      onInterfaceBlockStart?.call(_currentViewId, _activeJsonController!.stream, fullTag);
    }
  }
  
  void _handleJsonChar(String char) {
    if (_lookahead.isEmpty) {
      if (char == '<') {
        _lookahead = '<';
      } else {
        _activeJsonController?.add(char);
      }
      return;
    }

    final nextLookahead = _lookahead + char;
    const target = '</interface>';
    if (target.startsWith(nextLookahead)) {
      _lookahead = nextLookahead;
      if (_lookahead == target) {
        _activeJsonController?.close();
        _activeJsonController = null;
        onInterfaceBlockEnd?.call(_currentViewId);
        
        _state = ParserState.text;
        _lookahead = '';
      }
    } else {
      _activeJsonController?.add(_lookahead);
      _lookahead = '';
      if (char == '<') {
        _lookahead = '<';
      } else {
        _activeJsonController?.add(char);
      }
    }
  }
  
  void _emitText(String text) {
    if (text.isEmpty) return;
    onText?.call(text);
  }
  
  void close() {
    // If we end while still in a buffer/JSON state, flush everything
    if (_lookahead.isNotEmpty) {
      if (_state == ParserState.text) {
        _emitText(_lookahead);
      } else if (_state == ParserState.json) {
        _activeJsonController?.add(_lookahead);
      }
    }
    _activeJsonController?.close();
    onComplete?.call(_rawAccumulated);
  }
}
