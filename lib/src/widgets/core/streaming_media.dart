import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';
import 'package:streaming_gen_ui/src/widgets/base_streaming_image.dart';
import 'package:streaming_gen_ui/src/widgets/core/adaptive_animated_size.dart';

/// Aspect-ratio locked, progressive media renderer that pulses an offline
/// shimmer placeholder and cross-fades loaded network images over 300ms.
class StreamingMedia extends StatelessWidget {
  final PropertyStream props;

  const StreamingMedia({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: props.asMap.stream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};
          final url = data["url"] as String?;
          final aspectRatio =
              (data["aspectRatio"] as num?)?.toDouble() ?? 1.777;
          final borderRadius =
              (data["borderRadius"] as num?)?.toDouble() ?? 12.0;
          final fitString = data["fit"] as String? ?? 'cover';

          // Empty parameter protection: do not render anything if parameters are missing
          if (url == null) {
            return const AdaptiveAnimatedSize(
              child: SizedBox.shrink(),
            );
          }

          final fit = _parseBoxFit(fitString);

          return AdaptiveAnimatedSize(
            alignment: Alignment.topCenter,
            child: BaseStreamingImage(
              props: props,
              propertyName: 'url',
              themeName: 'material',
              borderRadius: borderRadius,
              aspectRatio: aspectRatio,
              fit: fit,
            ),
          );
        },
      ),
    );
  }

  BoxFit _parseBoxFit(String fit) {
    switch (fit.toLowerCase()) {
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitwidth':
        return BoxFit.fitWidth;
      case 'fitheight':
        return BoxFit.fitHeight;
      case 'none':
        return BoxFit.none;
      case 'scaledown':
        return BoxFit.scaleDown;
      case 'cover':
      default:
        return BoxFit.cover;
    }
  }
}
