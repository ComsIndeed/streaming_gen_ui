import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';

/// A circular progressive loader widget supporting custom dimensions,
/// color specifications, and percent-complete value tracking.
class StreamingProgressionCircle extends StatelessWidget {
  final PropertyStream props;

  const StreamingProgressionCircle({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: props.asMap.stream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};
          final value = (data["value"] as num?)?.toDouble();
          final colorHex = data["color"] as String?;
          final strokeWidth = (data["strokeWidth"] as num?)?.toDouble() ?? 3.5;
          final size = (data["size"] as num?)?.toDouble() ?? 24.0;

          final color = _parseColor(colorHex) ?? theme.colorScheme.primary;

          return SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: strokeWidth,
              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          );
        },
      ),
    );
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
}
