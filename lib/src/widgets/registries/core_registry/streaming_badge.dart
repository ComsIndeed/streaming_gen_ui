import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

class StreamingBadge extends StatefulWidget {
  final PropertyStream props;

  const StreamingBadge({super.key, required this.props});

  @override
  State<StreamingBadge> createState() => _StreamingBadgeState();
}

class _StreamingBadgeState extends State<StreamingBadge> {
  late Stream<String> _labelStream;
  late Future<String> _labelFuture;
  late Stream<Map<String, dynamic>> _badgeStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant StreamingBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initStream();
    }
  }

  void _initStream() {
    final mapStream = widget.props.asMap;
    _badgeStream = mapStream.stream;
    final labelProp = mapStream.getStringProperty("label");
    _labelStream = labelProp.stream;
    _labelFuture = labelProp.future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _badgeStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final style = data["style"] as String? ?? "neutral";
          final colorHex = data["color"] as String?;
          final textColorHex = data["textColor"] as String?;

          // Curated, beautiful theme palettes
          Color bg;
          Color text;

          switch (style) {
            case 'success':
              bg = const Color(0xFFECFDF5);
              text = const Color(0xFF047857);
              break;
            case 'warning':
              bg = Colors.amber.shade50;
              text = Colors.amber.shade800;
              break;
            case 'error':
              bg = const Color(0xFFFFF1F2);
              text = const Color(0xFFB91C1C);
              break;
            case 'info':
              bg = Colors.indigo.shade50;
              text = Colors.indigo.shade700;
              break;
            case 'neutral':
            default:
              bg = theme.colorScheme.surfaceContainerHigh;
              text = theme.colorScheme.onSurfaceVariant;
              break;
          }

          // Override with custom hex colors if supplied
          if (colorHex != null) {
            final parsedBg = _parseColor(colorHex);
            if (parsedBg != null) bg = parsedBg;
          }
          if (textColorHex != null) {
            final parsedText = _parseColor(textColorHex);
            if (parsedText != null) text = parsedText;
          }

          return FutureBuilder<String>(
            future: _labelFuture,
            builder: (context, labelSnapshot) {
              final isDone = labelSnapshot.connectionState == ConnectionState.done && labelSnapshot.hasData;
              final initial = isDone ? labelSnapshot.data! : '';

              return AccumulatingStringStreamBuilder(
                stream: _labelStream,
                initialValue: initial,
                builder: (context, labelText) {
                  if (labelText.isEmpty) return const SizedBox.shrink();

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      labelText,
                      style: TextStyle(
                        color: text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                  );
                },
              );
            },
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
