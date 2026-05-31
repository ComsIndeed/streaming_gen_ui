import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';

void main() {
  group('Synchronous Hydration Verification Tests', () {
    testWidgets('Standard StreamBuilder has 1-frame asynchronous delay (flickers)',
        (WidgetTester tester) async {
      final controller = StreamController<String>.broadcast(sync: true);

      String? renderedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: StreamBuilder<String>(
            stream: controller.stream,
            // Without initialData (which is exactly how our catalog cards are currently implemented),
            // standard StreamBuilder has a ConnectionState.waiting phase on frame 1 and builds null.
            builder: (context, snapshot) {
              renderedValue = snapshot.data;
              return Text(snapshot.data ?? 'waiting');
            },
          ),
        ),
      );

      // Without initialData, standard StreamBuilder is ALWAYS 'waiting' on Frame 1
      expect(find.text('waiting'), findsOneWidget);
      expect(renderedValue, isNull);

      await controller.close();
    });

    testWidgets('AdaptiveStreamBuilder with initialData resolves synchronously on Frame 1 (no flicker)',
        (WidgetTester tester) async {
      final controller = StreamController<String>.broadcast(sync: true);

      String? renderedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveStreamBuilder<String>(
            stream: controller.stream,
            initialData: 'initial_value',
            builder: (context, snapshot) {
              renderedValue = snapshot.data;
              return Text(snapshot.data ?? 'waiting');
            },
          ),
        ),
      );

      // AdaptiveStreamBuilder immediately paints the initialData on the very first frame!
      expect(find.text('initial_value'), findsOneWidget);
      expect(renderedValue, equals('initial_value'));

      await controller.close();
    });

    testWidgets('AdaptiveStreamBuilder automatically resolves Map properties synchronously using context fallback',
        (WidgetTester tester) async {
      final controller = StreamController<Map<String, dynamic>>.broadcast(sync: true);
      final registry = WidgetRegistry(widgets: {});

      Map<String, dynamic>? renderedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: StreamingUiProvider(
            registry: registry,
            showInternalErrors: false,
            disableAnimations: true,
            latestProperties: const {'temp': 24.5, 'location': 'London'},
            child: Builder(
              builder: (context) {
                return AdaptiveStreamBuilder<Map<String, dynamic>>(
                  stream: controller.stream,
                  builder: (context, snapshot) {
                    renderedValue = snapshot.data;
                    return Text(snapshot.data?['location'] ?? 'waiting');
                  },
                );
              },
            ),
          ),
        ),
      );

      // On Frame 1, it automatically queries latestProperties from the context
      // and paints 'London' synchronously!
      expect(find.text('London'), findsOneWidget);
      expect(renderedValue, equals(const {'temp': 24.5, 'location': 'London'}));

      await controller.close();
    });
  });
}
