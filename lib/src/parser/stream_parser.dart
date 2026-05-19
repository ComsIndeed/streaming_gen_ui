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

  void processChunk(String chunk) {
    throw UnimplementedError();
  }

  void close() {
    throw UnimplementedError();
  }
}
