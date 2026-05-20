import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';

import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

/// A layout component that dynamically displays nested children horizontally
/// as they stream in progressively.
class StreamingRow extends StatelessWidget {
  final ListPropertyStream<dynamic> childrenProperty;

  const StreamingRow({super.key, required this.childrenProperty});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: childrenProperty.stream,
      builder: (context, snapshot) {
        final list = snapshot.data ?? const [];

        if (snapshot.connectionState == ConnectionState.done && list.isEmpty) {
          debugPrint('[GEN_UI:WARNING] core:row layout streaming complete but contains 0 items!');
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

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: childrenList,
          ),
        );
      },
    );
  }
}
