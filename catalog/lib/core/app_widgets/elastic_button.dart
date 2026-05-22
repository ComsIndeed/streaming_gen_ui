import 'package:flutter/material.dart';

class ElasticButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final Widget label;
  final bool isFlat;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ElasticButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isFlat = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<ElasticButton> createState() => _ElasticButtonState();
}

class _ElasticButtonState extends State<ElasticButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Scale dynamics: slightly larger on hover, slightly smaller on press
    final double scale = _isPressed
        ? 0.95
        : _isHovered
        ? 1.05
        : 1.0;

    // Fat (tall) vs Flat (flat) layouts - fat is default
    final double height = widget.isFlat ? 34.0 : 44.0;
    final double horizontalPadding = widget.isFlat ? 16.0 : 20.0;
    final double fontSize = widget.isFlat ? 11.5 : 12.5;

    final bg = widget.backgroundColor ?? theme.colorScheme.primary;
    final fg = widget.foregroundColor ?? theme.colorScheme.onPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: const Cubic(0.2, 0.8, 0.2, 1.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: height,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(height / 2),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: bg.withOpacity(_isHovered ? 0.24 : 0.12),
                  blurRadius: _isHovered ? 12 : 6,
                  offset: Offset(0, _isHovered ? 4 : 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconTheme(
                  data: IconThemeData(color: fg, size: 16),
                  child: widget.icon,
                ),
                const SizedBox(width: 8),
                DefaultTextStyle(
                  style: TextStyle(
                    color: fg,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                  child: widget.label,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
