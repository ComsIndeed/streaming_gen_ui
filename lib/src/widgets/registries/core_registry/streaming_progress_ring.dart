import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

/// A premium radial progress ring indicator that animates its arc smoothly
/// as the progress values are streamed in real time.
class StreamingProgressRing extends StatefulWidget {
  final PropertyStream props;

  const StreamingProgressRing({super.key, required this.props});

  @override
  State<StreamingProgressRing> createState() => _StreamingProgressRingState();
}

class _StreamingProgressRingState extends State<StreamingProgressRing> {
  late Stream<Map<String, dynamic>> _ringStream;

  @override
  void initState() {
    super.initState();
    _initProps();
  }

  @override
  void didUpdateWidget(covariant StreamingProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initProps();
    }
  }

  void _initProps() {
    final mapStream = widget.props.asMap;
    _ringStream = mapStream.stream;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _ringStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final rawValue = (data["value"] as num?)?.toDouble() ?? 0.0;
          // Accept progress values from both 0.0-1.0 and 0.0-100.0 ranges
          final percent = (rawValue > 1.0) ? (rawValue / 100.0) : rawValue;
          final clampedPercent = percent.clamp(0.0, 1.0);

          final size = (data["size"] as num?)?.toDouble() ?? 80.0;
          final strokeWidth = (data["strokeWidth"] as num?)?.toDouble() ?? 8.0;

          final colorHex = data["color"] as String?;
          final color = _parseColor(colorHex) ?? theme.colorScheme.primary;

          final labelProp = widget.props.asMap.getStringProperty("label");
          final labelStream = labelProp.stream;
          final labelFuture = labelProp.future;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.06),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: size,
                      height: size,
                      child: CircularProgressIndicator(
                        value: clampedPercent,
                        strokeWidth: strokeWidth,
                        backgroundColor: theme.colorScheme.outline.withOpacity(0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    Text(
                      '${(clampedPercent * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: (size * 0.22).clamp(12.0, 20.0),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: FutureBuilder<String>(
                    future: labelFuture,
                    builder: (context, labelSnapshot) {
                      final isDone = labelSnapshot.connectionState == ConnectionState.done && labelSnapshot.hasData;
                      final initial = isDone ? labelSnapshot.data! : '';

                      return AccumulatingStringStreamBuilder(
                        stream: labelStream,
                        initialValue: initial,
                        builder: (context, labelText) {
                          if (labelText.isEmpty) return const SizedBox.shrink();

                          return Text(
                            labelText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Color? _parseColor(String? hexString) {
  if (hexString == null) return null;
  var hex = hexString.replaceAll('#', '');
  if (hex.length == 3) {
    hex = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
  }
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  if (hex.length == 8) {
    final val = int.tryParse(hex, radix: 16);
    if (val != null) return Color(val);
  }
  return null;
}
