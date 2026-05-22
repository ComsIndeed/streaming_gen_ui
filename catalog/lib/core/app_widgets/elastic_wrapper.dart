import 'package:flutter/material.dart';

/// A wrapper widget that animates the scale of its child when pressed or hovered,
/// providing a premium, interactive "elastic" feel.
/// 
/// It does not require [onTap] to animate; it will scale down on press even if
/// [onTap] is null or does nothing.
class ElasticWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final double hoveredScale;
  final Duration duration;
  final Curve curve;

  const ElasticWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.95,
    this.hoveredScale = 1.0, // Default to 1.0 for tap-only scale down, can be set to 1.05 for hover state
    this.duration = const Duration(milliseconds: 150),
    this.curve = const Cubic(0.2, 0.8, 0.2, 1.0),
  });

  @override
  State<ElasticWrapper> createState() => _ElasticWrapperState();
}

class _ElasticWrapperState extends State<ElasticWrapper> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Determine the target scale based on interactions
    final double scale = _isPressed
        ? widget.pressedScale
        : _isHovered
            ? widget.hoveredScale
            : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: widget.duration,
          curve: widget.curve,
          child: widget.child,
        ),
      ),
    );
  }
}
