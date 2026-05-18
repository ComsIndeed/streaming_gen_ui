import 'dart:math';
import 'package:flutter/material.dart';

/// Blueprint custom grid lines painter that paints on scrollable content height
class BlueprintGridPainter extends CustomPainter {
  final Color gridColor;
  final Color majorColor;

  BlueprintGridPainter({required this.gridColor, required this.majorColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final paintMajor = Paint()
      ..color = majorColor
      ..strokeWidth = 1.0;

    const double spacing = 20.0;
    const int majorStep = 5;

    // Draw horizontal grid lines
    for (double y = 0; y < size.height; y += spacing) {
      final isMajor = (y % (spacing * majorStep)).abs() < 0.1;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? paintMajor : paintGrid);
    }

    // Draw vertical grid lines
    for (double x = 0; x < size.width; x += spacing) {
      final isMajor = (x % (spacing * majorStep)).abs() < 0.1;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? paintMajor : paintGrid);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paper grid watermark painter for White Paper Layout
class PaperWatermarkPainter extends CustomPainter {
  final Color gridColor;

  PaperWatermarkPainter({this.gridColor = const Color(0xFFF1F5F9)});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    const double spacing = 15.0;

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A very thick, bold arrow that shows moving gradient animations when active
class ArrowPainter extends CustomPainter {
  final double animationValue;
  final bool isActive;
  final bool isWide;
  final bool isDarkMode;

  ArrowPainter({
    required this.animationValue,
    required this.isActive,
    required this.isWide,
    this.isDarkMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double arrowWidth = size.width;
    final double arrowHeight = size.height;

    // Define the Arrow Path (Thick industrial arrow pointing right)
    final Path arrowPath = Path();
    final double shaftThickPercent = 0.45; // Thickness of the arrow tail
    final double tailYStart = arrowHeight * (1 - shaftThickPercent) / 2;
    final double tailYEnd = arrowHeight * (1 + shaftThickPercent) / 2;

    final double headWidth = arrowWidth * 0.4; // Width of the arrow head tip
    final double headXStart = arrowWidth - headWidth;

    arrowPath.moveTo(0, tailYStart);
    arrowPath.lineTo(headXStart, tailYStart);
    arrowPath.lineTo(headXStart, 0); // Out to top tip point
    arrowPath.lineTo(arrowWidth, arrowHeight / 2); // Main tip
    arrowPath.lineTo(headXStart, arrowHeight); // Down to bottom tip point
    arrowPath.lineTo(headXStart, tailYEnd);
    arrowPath.lineTo(0, tailYEnd);
    arrowPath.close();

    // Base paint
    final Paint fillPaint = Paint()..style = PaintingStyle.fill;

    if (isActive) {
      // Loop a beautiful linear gradient running from left to right along the arrow
      final gradient = LinearGradient(
        colors: const [
          Color(0xFF2563EB), // Sleek Royal Blue
          Color(0xFF60A5FA), // Soft bright light blue
          Color(0xFF38BDF8), // Cyber Cyan
          Color(0xFF60A5FA),
          Color(0xFF2563EB),
        ],
        stops: const [
          0.0,
          0.25,
          0.5,
          0.75,
          1.0,
        ],
        transform: GradientRotation(animationValue * 2 * pi),
      );

      fillPaint.shader = gradient.createShader(Offset.zero & size);
    } else {
      // Idle style
      fillPaint.color = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1);
    }

    // Draw arrow body shadow/glow
    if (isActive) {
      canvas.drawPath(
        arrowPath,
        Paint()
          ..color = const Color(0xFF38BDF8).withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Draw main arrow
    canvas.drawPath(arrowPath, fillPaint);

    // Draw soft border around the arrow
    final Paint borderPaint = Paint()
      ..color = isActive
          ? (isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF60A5FA))
          : (isDarkMode ? const Color(0xFF334155) : const Color(0xFF94A3B8))
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(arrowPath, borderPaint);

    // If active, draw cute chevron details moving
    if (isActive) {
      final double chevX = headXStart * (animationValue);
      final double chevSize = 6.0;

      final chevPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (chevX < headXStart) {
        canvas.drawPath(
          Path()
            ..moveTo(chevX - chevSize, arrowHeight / 2 - chevSize / 2)
            ..lineTo(chevX, arrowHeight / 2)
            ..lineTo(chevX - chevSize, arrowHeight / 2 + chevSize / 2),
          chevPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ArrowPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isActive != isActive ||
        oldDelegate.isWide != isWide ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
