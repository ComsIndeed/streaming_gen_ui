import 'package:flutter_test/flutter_test.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
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

    test('Correctly populates sequential TextBlock and InteractiveBlock lists', () async {
      final genUi = StreamingGenUi();

      final responseStream = Stream.fromIterable([
        'Pre-text message. ',
        '<interface>',
        '{"namespace": "core:text", "text": "Inside tag"}',
        '</interface>',
        ' Post-text message.'
      ]);

      await genUi.stream(responseStream, viewId: 'test-view');
      final state = genUi.getViewState('test-view');

      expect(state.blocks.length, equals(3));
      expect(state.blocks[0], isA<TextBlock>());
      expect((state.blocks[0] as TextBlock).text, equals('Pre-text message. '));

      expect(state.blocks[1], isA<InteractiveBlock>());
      final interactive = state.blocks[1] as InteractiveBlock;
      final fullText = await interactive.rootMapStream.getStringProperty('text').future;
      expect(fullText, equals('Inside tag'));

      expect(state.blocks[2], isA<TextBlock>());
      expect((state.blocks[2] as TextBlock).text, equals(' Post-text message.'));
    });
  });
}
