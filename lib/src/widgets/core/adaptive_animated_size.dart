import 'package:flutter/material.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';

/// A wrapper widget that acts exactly like [AnimatedSize] but automatically
/// queries the nearest [StreamingUiProvider] context to determine if animations should be bypassed.
///
/// If [StreamingUiProvider.disableAnimations] is true (e.g. historical completed blocks),
/// this widget immediately returns the [child] directly on Frame 1, completely avoiding
/// [AnimatedSize] internal rendering mutation crashes.
class AdaptiveAnimatedSize extends StatelessWidget {
  final Widget child;
  final AlignmentGeometry alignment;
  final Curve curve;
  final Duration duration;
  final Duration? reverseDuration;
  final Clip clipBehavior;

  const AdaptiveAnimatedSize({
    super.key,
    required this.child,
    this.alignment = Alignment.topLeft,
    this.curve = Curves.easeOutCubic,
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration,
    this.clipBehavior = Clip.hardEdge,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        StreamingUiProvider.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      return child;
    }

    return AnimatedSize(
      alignment: alignment,
      curve: curve,
      duration: duration,
      reverseDuration: reverseDuration,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}
