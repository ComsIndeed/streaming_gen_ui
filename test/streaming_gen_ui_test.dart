import 'package:flutter_test/flutter_test.dart';
import 'package:streaming_gen_ui/src/parser/stream_parser.dart';

void main() {
  group('StatefulStreamParser tests', () {
    test('Isolates conversational text and interactive block chunks correctly', () async {
      final textChunks = <String>[];
      final jsonChunks = <String>[];
      String? matchedViewId;

      final parser = StatefulStreamParser(
        defaultViewId: 'chat-bubble',
        onText: (chunk) {
          textChunks.add(chunk);
        },
        onInterfaceBlockStart: (viewId, jsonStream, startTag) {
          matchedViewId = viewId;
          jsonStream.listen((chunk) {
            jsonChunks.add(chunk);
          });
        },
      );

      parser.processChunk('Hello world! <interface viewId="side-panel">{"namesp');
      parser.processChunk('ace": "core:text"} </interface>Welcome back.');
      parser.close();

      // Small async wait to ensure stream listeners resolve fully
      await Future.delayed(Duration.zero);

      expect(textChunks.join(''), equals('Hello world! Welcome back.'));
      expect(matchedViewId, equals('side-panel'));
      expect(jsonChunks.join(''), equals('{"namespace": "core:text"} '));
    });
  });
}
