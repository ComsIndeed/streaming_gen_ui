import 'package:flutter/material.dart';

class GraphBackground extends StatelessWidget {
  final Widget child;
  final double gridSize;
  final double majorGridMultiplier;
  final Color? gridColor;
  final Color? backgroundColor;

  const GraphBackground({
    super.key,
    required this.child,
    this.gridSize = 24.0,
    this.majorGridMultiplier = 5.0, // Every 5th line is a major line (120px)
    this.gridColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeGridColor =
        gridColor ?? theme.colorScheme.onSurface.withOpacity(0.04);
    final activeBgColor = backgroundColor ?? theme.colorScheme.surface;

    return CustomPaint(
      painter: _GraphPainter(
        gridSize: gridSize,
        majorGridMultiplier: majorGridMultiplier,
        gridColor: activeGridColor,
        backgroundColor: activeBgColor,
      ),
      child: child,
    );
  }
}

class _GraphPainter extends CustomPainter {
  final double gridSize;
  final double majorGridMultiplier;
  final Color gridColor;
  final Color backgroundColor;

  _GraphPainter({
    required this.gridSize,
    required this.majorGridMultiplier,
    required this.gridColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Paint background
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Prepare grid line paints
    final minorPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final majorPaint = Paint()
      ..color = gridColor
          .withOpacity(gridColor.opacity * 2.5) // Make major lines more visible
      ..strokeWidth = 1.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      final isMajor = (x / gridSize).round() % majorGridMultiplier == 0;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isMajor ? majorPaint : minorPaint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      final isMajor = (y / gridSize).round() % majorGridMultiplier == 0;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isMajor ? majorPaint : minorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize ||
        oldDelegate.majorGridMultiplier != majorGridMultiplier ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
