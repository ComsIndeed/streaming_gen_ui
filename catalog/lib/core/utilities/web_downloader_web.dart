import 'dart:convert';
import 'dart:js' as js;

void downloadFileWeb(String sourceCode, String filename) {
  final bytes = utf8.encode(sourceCode);
  final base64Code = base64.encode(bytes);
  final dataUri = 'data:text/javascript;base64,$base64Code';
  js.context.callMethod('open', [dataUri]);
}
