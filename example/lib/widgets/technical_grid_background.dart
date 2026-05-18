import 'package:flutter/material.dart';

class TechnicalGridBackground extends StatelessWidget {
  final Widget child;

  const TechnicalGridBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Clean graph paper grid CustomPainter
        Positioned.fill(
          child: CustomPaint(
            painter: _GridPaperPainter(),
          ),
        ),
        // Child content above the grid
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}

class _GridPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintFine = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.4) // Soft slate grid lines
      ..strokeWidth = 0.5;

    final paintPrimary = Paint()
      ..color = const Color(0xFFCBD5E1).withOpacity(0.6) // Slightly thicker major grid lines
      ..strokeWidth = 1.0;

    final double gridSpacingFine = 25.0;
    final int subgridCount = 5; // Major grid every 5 subgrids (125px)
    final double gridSpacingPrimary = gridSpacingFine * subgridCount;

    // Draw horizontal grid lines
    for (double y = 0; y < size.height; y += gridSpacingFine) {
      final isMajor = (y % gridSpacingPrimary).abs() < 0.1;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isMajor ? paintPrimary : paintFine,
      );
    }

    // Draw vertical grid lines
    for (double x = 0; x < size.width; x += gridSpacingFine) {
      final isMajor = (x % gridSpacingPrimary).abs() < 0.1;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isMajor ? paintPrimary : paintFine,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
