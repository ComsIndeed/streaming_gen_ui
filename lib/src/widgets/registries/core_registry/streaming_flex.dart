import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';

class StreamingFlex extends StatelessWidget {
  final PropertyStream props;

  const StreamingFlex({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    final mapStream = props.asMap;
    final flexStream = mapStream.stream;
    final childrenProperty = mapStream.getListProperty("children");

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: flexStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final direction = data["direction"] as String? ?? "vertical";
          final gap = (data["gap"] as num?)?.toDouble() ?? 0.0;
          final mainAlign = _parseMainAlign(
            data["mainAxisAlignment"] as String?,
          );
          final crossAlign = _parseCrossAlign(
            data["crossAxisAlignment"] as String?,
          );

          return StreamBuilder<List<dynamic>>(
            stream: childrenProperty.stream,
            builder: (context, childSnapshot) {
              final list = childSnapshot.data ?? const [];

              final childrenList = <Widget>[];
              for (var i = 0; i < list.length; i++) {
                childrenList.add(
                  StreamingEntrance(
                    child: StreamingWidget(
                      props: childrenProperty.getMapProperty('[$i]'),
                    ),
                  ),
                );
                if (gap > 0 && i < list.length - 1) {
                  childrenList.add(
                    direction == 'horizontal'
                        ? SizedBox(width: gap)
                        : SizedBox(height: gap),
                  );
                }
              }

              final isVertical = direction != 'horizontal';

              return AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: isVertical
                    ? Alignment.topCenter
                    : Alignment.centerLeft,
                child: isVertical
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: mainAlign ?? MainAxisAlignment.start,
                        crossAxisAlignment:
                            crossAlign ?? CrossAxisAlignment.start,
                        children: childrenList,
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: mainAlign ?? MainAxisAlignment.start,
                        crossAxisAlignment:
                            crossAlign ?? CrossAxisAlignment.center,
                        children: childrenList,
                      ),
              );
            },
          );
        },
      ),
    );
  }
}

MainAxisAlignment? _parseMainAlign(String? align) {
  if (align == null) return null;
  switch (align) {
    case 'start':
      return MainAxisAlignment.start;
    case 'center':
      return MainAxisAlignment.center;
    case 'end':
      return MainAxisAlignment.end;
    case 'spaceBetween':
      return MainAxisAlignment.spaceBetween;
    case 'spaceAround':
      return MainAxisAlignment.spaceAround;
    case 'spaceEvenly':
      return MainAxisAlignment.spaceEvenly;
  }
  return null;
}

CrossAxisAlignment? _parseCrossAlign(String? align) {
  if (align == null) return null;
  switch (align) {
    case 'start':
      return CrossAxisAlignment.start;
    case 'center':
      return CrossAxisAlignment.center;
    case 'end':
      return CrossAxisAlignment.end;
    case 'stretch':
      return CrossAxisAlignment.stretch;
    case 'baseline':
      return CrossAxisAlignment.baseline;
  }
  return null;
}
