import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';

/// A horizontal linear progression bar that adapts its fill dynamically
/// as values arrive. Supports indeterminate state if value is omitted.
class StreamingProgressionBar extends StatelessWidget {
  final PropertyStream props;

  const StreamingProgressionBar({super.key, required this.props});

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
          final height = (data["height"] as num?)?.toDouble() ?? 4.0;
          final borderRadius = (data["borderRadius"] as num?)?.toDouble() ?? 4.0;

          final color = _parseColor(colorHex) ?? theme.colorScheme.primary;

          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: SizedBox(
              height: height,
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
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
