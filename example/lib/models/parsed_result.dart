class ParsedResult {
  final String preText;
  final String jsonText;
  final String postText;
  final bool hasInteractive;
  final bool isInteractiveClosed;
  final String startTag;
  final String endTag;

  ParsedResult({
    required this.preText,
    required this.jsonText,
    required this.postText,
    required this.hasInteractive,
    required this.isInteractiveClosed,
    required this.startTag,
    required this.endTag,
  });
}
