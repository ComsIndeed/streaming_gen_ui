import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

/// A premium, alert notification banner that expands smoothly and maps status styles
/// (success, warning, error, info) to customized glows, icons, and action options.
class StreamingAlert extends StatefulWidget {
  final PropertyStream props;

  const StreamingAlert({super.key, required this.props});

  @override
  State<StreamingAlert> createState() => _StreamingAlertState();
}

class _StreamingAlertState extends State<StreamingAlert> {
  late Stream<Map<String, dynamic>> _alertStream;
  late Future<String> _actionFuture;

  @override
  void initState() {
    super.initState();
    _initProps();
  }

  @override
  void didUpdateWidget(covariant StreamingAlert oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initProps();
    }
  }

  void _initProps() {
    final mapStream = widget.props.asMap;
    _alertStream = mapStream.stream;
    _actionFuture = mapStream.getStringProperty("action").future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _alertStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final style = data["style"] as String? ?? "info";

          // Styled palettes
          Color bg;
          Color border;
          Color text;
          IconData iconData;

          switch (style) {
            case 'success':
              bg = const Color(0xFFF0FDF4);
              border = const Color(0xFFBBF7D0);
              text = const Color(0xFF166534);
              iconData = Icons.check_circle_outline_rounded;
              break;
            case 'warning':
              bg = const Color(0xFFFFFBEB);
              border = const Color(0xFFFDE68A);
              text = const Color(0xFF92400E);
              iconData = Icons.warning_amber_rounded;
              break;
            case 'error':
              bg = const Color(0xFFFEF2F2);
              border = const Color(0xFFFECACA);
              text = const Color(0xFF991B1B);
              iconData = Icons.error_outline_rounded;
              break;
            case 'info':
            default:
              bg = const Color(0xFFEFF6FF);
              border = const Color(0xFFBFDBFE);
              text = const Color(0xFF1E40AF);
              iconData = Icons.info_outline_rounded;
              break;
          }

          final titleProp = widget.props.asMap.getStringProperty("title");
          final titleStream = titleProp.stream;
          final titleFuture = titleProp.future;

          final descProp = widget.props.asMap.getStringProperty("description");
          final descStream = descProp.stream;
          final descFuture = descProp.future;

          return FutureBuilder<String>(
            future: _actionFuture,
            builder: (context, actionSnapshot) {
              final action = actionSnapshot.data;
              final hasAction =
                  actionSnapshot.connectionState == ConnectionState.done &&
                  action != null;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: border.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(iconData, color: text, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FutureBuilder<String>(
                            future: titleFuture,
                            builder: (context, titleSnapshot) {
                              final isDone =
                                  titleSnapshot.connectionState ==
                                      ConnectionState.done &&
                                  titleSnapshot.hasData;
                              final initial = isDone ? titleSnapshot.data! : '';

                              return AccumulatingStringStreamBuilder(
                                stream: titleStream,
                                initialValue: initial,
                                builder: (context, titleText) {
                                  if (titleText.isEmpty)
                                    return const SizedBox.shrink();

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      titleText,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: text,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          FutureBuilder<String>(
                            future: descFuture,
                            builder: (context, descSnapshot) {
                              final isDone =
                                  descSnapshot.connectionState ==
                                      ConnectionState.done &&
                                  descSnapshot.hasData;
                              final initial = isDone ? descSnapshot.data! : '';

                              return AccumulatingStringStreamBuilder(
                                stream: descStream,
                                initialValue: initial,
                                builder: (context, descText) {
                                  if (descText.isEmpty)
                                    return const SizedBox.shrink();

                                  return Text(
                                    descText,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: text.withOpacity(0.85),
                                      height: 1.4,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (hasAction) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.close_rounded,
                          color: text.withOpacity(0.6),
                          size: 18,
                        ),
                        onPressed: () {
                          debugPrint(
                            '[GEN_UI:ALERT] Action dismissed -> $action',
                          );
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
