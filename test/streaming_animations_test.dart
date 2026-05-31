import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';

void main() {
  group('StreamingAnimations Context Propagation & Snapping', () {
    testWidgets('StreamingUiProvider propagates disableAnimations',
        (WidgetTester tester) async {
      final reg = WidgetRegistry(widgets: {});

      bool resolvedValue = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StreamingUiProvider(
            registry: reg,
            showInternalErrors: false,
            disableAnimations: true,
            child: Builder(
              builder: (context) {
                resolvedValue =
                    StreamingUiProvider.maybeOf(context)?.disableAnimations ??
                        false;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(resolvedValue, isTrue);
    });

    testWidgets(
        'StreamingEntrance snaps immediately when disableAnimations is true',
        (WidgetTester tester) async {
      final reg = WidgetRegistry(widgets: {});

      await tester.pumpWidget(
        MaterialApp(
          home: StreamingUiProvider(
            registry: reg,
            showInternalErrors: false,
            disableAnimations: true,
            child: const StreamingEntrance(
              duration: Duration(milliseconds: 500),
              child: Text('Target'),
            ),
          ),
        ),
      );

      // On the very first frame, with disableAnimations: true, the opacity should immediately resolve to 1.0
      final opacityFinder = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacityFinder.opacity, equals(1.0));
    });
  });
}
