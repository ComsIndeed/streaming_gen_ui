import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';

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
          final aspectRatio = (data["aspectRatio"] as num?)?.toDouble() ?? 1.777;
          final borderRadius = (data["borderRadius"] as num?)?.toDouble() ?? 12.0;
          final fitString = data["fit"] as String? ?? 'cover';

          // Empty parameter protection: do not render anything if parameters are missing
          if (url == null || url.isEmpty) {
            return const SizedBox.shrink();
          }

          final fit = _parseBoxFit(fitString);

          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Image.network(
                  url,
                  key: ValueKey(url),
                  fit: fit,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const _ShimmerPlaceholder();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    );
                  },
                ),
              ),
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

class _ShimmerPlaceholder extends StatefulWidget {
  const _ShimmerPlaceholder();

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.8 * _controller.value + 0.2),
                Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.image_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
              size: 32,
            ),
          ),
        );
      },
    );
  }
}
