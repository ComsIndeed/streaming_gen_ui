import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';

/// A styled layout box container that morphs its sizes and colors fluidly,
/// utilizing AnimatedSize and stable alignment to prevent jitter during streaming.
class StreamingContainer extends StatelessWidget {
  final PropertyStream props;

  const StreamingContainer({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    final mapStream = props.asMap;
    final containerStream = mapStream.stream;
    final childProp = mapStream.getMapProperty("child");

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: containerStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final colorHex = data["color"] as String?;
          final width = (data["width"] as num?)?.toDouble();
          final height = (data["height"] as num?)?.toDouble();
          final paddingVal = (data["padding"] as num?)?.toDouble() ?? 16.0;
          final borderRadiusVal =
              (data["borderRadius"] as num?)?.toDouble() ?? 16.0;

          final parsedColor = _parseColor(colorHex);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: const Cubic(0.2, 0.8, 0.2, 1.0),
            width: width,
            height: height,
            decoration: BoxDecoration(
              color:
                  parsedColor ??
                  Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(borderRadiusVal),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topLeft, // The Stable Alignment Rule
              child: Padding(
                padding: EdgeInsets.all(paddingVal),
                child: StreamingWidget(props: childProp),
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
