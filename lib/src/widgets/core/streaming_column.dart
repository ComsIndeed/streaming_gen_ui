import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';
import 'package:streaming_gen_ui/src/widgets/core/adaptive_animated_size.dart';

/// A layout component that dynamically displays nested children vertically
/// as they stream in progressively.
class StreamingColumn extends StatelessWidget {
  final ListPropertyStream<dynamic> childrenProperty;

  const StreamingColumn({super.key, required this.childrenProperty});

  @override
  Widget build(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<StreamingUiProvider>();
    final provider = element?.widget as StreamingUiProvider?;
    final isClosed = provider?.disableAnimations ?? false;

    if (isClosed) {
      final list = provider?.latestProperties?["children"] as List<dynamic>? ??
          const [];
      final childrenList = List.generate(
        list.length,
        (index) => StreamingEntrance(
          child: StreamingWidget(
            props: childrenProperty.getMapProperty('[$index]'),
          ),
        ),
      );

      return AdaptiveAnimatedSize(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: childrenList,
        ),
      );
    }

    return StreamBuilder<List<dynamic>>(
      stream: childrenProperty.stream,
      builder: (context, snapshot) {
        final list = snapshot.data ?? const [];

        if (snapshot.connectionState == ConnectionState.done && list.isEmpty) {
          debugPrint(
            '[GEN_UI:WARNING] core:column layout streaming complete but contains 0 items!',
          );
        }

        // Dynamically instantiate clean, reactive PropertyStream wrappers for each element index
        final childrenList = List.generate(
          list.length,
          (index) => StreamingEntrance(
            child: StreamingWidget(
              props: childrenProperty.getMapProperty('[$index]'),
            ),
          ),
        );

        return AdaptiveAnimatedSize(
          alignment: Alignment
              .topCenter, // Lock alignment vertically to top-center to prevent jitter
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: childrenList,
          ),
        );
      },
    );
  }
}
