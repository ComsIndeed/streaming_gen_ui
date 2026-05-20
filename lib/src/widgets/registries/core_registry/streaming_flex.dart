import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';

class StreamingFlex extends StatefulWidget {
  final PropertyStream props;

  const StreamingFlex({super.key, required this.props});

  @override
  State<StreamingFlex> createState() => _StreamingFlexState();
}

class _StreamingFlexState extends State<StreamingFlex> {
  late Stream<Map<String, dynamic>> _flexStream;
  late ListPropertyStream<dynamic> _childrenProperty;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant StreamingFlex oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initStream();
    }
  }

  void _initStream() {
    final mapStream = widget.props.asMap;
    _flexStream = mapStream.stream;
    _childrenProperty = mapStream.getListProperty("children");
  }

  @override
  Widget build(BuildContext context) {
    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _flexStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final direction = data["direction"] as String? ?? "vertical";
          final gap = (data["gap"] as num?)?.toDouble() ?? 0.0;
          final mainAlign = _parseMainAlign(data["mainAxisAlignment"] as String?);
          final crossAlign = _parseCrossAlign(data["crossAxisAlignment"] as String?);

          return StreamBuilder<List<dynamic>>(
            stream: _childrenProperty.stream,
            builder: (context, childSnapshot) {
              final list = childSnapshot.data ?? const [];

              final childrenList = <Widget>[];
              for (var i = 0; i < list.length; i++) {
                childrenList.add(
                  StreamingEntrance(
                    child: StreamingWidget(
                      props: _childrenProperty.getMapProperty('[$i]'),
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
                alignment: isVertical ? Alignment.topCenter : Alignment.centerLeft,
                child: isVertical
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: mainAlign ?? MainAxisAlignment.start,
                        crossAxisAlignment: crossAlign ?? CrossAxisAlignment.start,
                        children: childrenList,
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: mainAlign ?? MainAxisAlignment.start,
                        crossAxisAlignment: crossAlign ?? CrossAxisAlignment.center,
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
    case 'start': return MainAxisAlignment.start;
    case 'center': return MainAxisAlignment.center;
    case 'end': return MainAxisAlignment.end;
    case 'spaceBetween': return MainAxisAlignment.spaceBetween;
    case 'spaceAround': return MainAxisAlignment.spaceAround;
    case 'spaceEvenly': return MainAxisAlignment.spaceEvenly;
  }
  return null;
}

CrossAxisAlignment? _parseCrossAlign(String? align) {
  if (align == null) return null;
  switch (align) {
    case 'start': return CrossAxisAlignment.start;
    case 'center': return CrossAxisAlignment.center;
    case 'end': return CrossAxisAlignment.end;
    case 'stretch': return CrossAxisAlignment.stretch;
    case 'baseline': return CrossAxisAlignment.baseline;
  }
  return null;
}
