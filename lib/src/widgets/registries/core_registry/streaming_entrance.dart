import 'package:flutter/widgets.dart';

/// A premium entrance wrapper that automatically fades and scales in a widget
/// from 0.96 to 1.0 using a signature Standard Snap cubic curve.
class StreamingEntrance extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const StreamingEntrance({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: const Cubic(0.2, 0.8, 0.2, 1.0), // Standard Snap Curve
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.96 + (0.04 * value),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
