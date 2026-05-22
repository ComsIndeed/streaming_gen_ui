import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

/// A premium glassmorphic cryptocurrency status card with live ticker details,
/// trend color themes, and a dynamic inline sparkline chart.
class StreamingCryptoCard extends StatefulWidget {
  final PropertyStream props;

  const StreamingCryptoCard({super.key, required this.props});

  @override
  State<StreamingCryptoCard> createState() => _StreamingCryptoCardState();
}

class _StreamingCryptoCardState extends State<StreamingCryptoCard> {
  late Stream<Map<String, dynamic>> _cryptoStream;

  @override
  void initState() {
    super.initState();
    _cryptoStream = widget.props.asMap.stream;
  }

  @override
  void didUpdateWidget(covariant StreamingCryptoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      setState(() {
        _cryptoStream = widget.props.asMap.stream;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _cryptoStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final symbol = (data["symbol"] as String? ?? "").toUpperCase();
          final name = data["name"] as String? ?? "";
          final price = data["price"] as String? ?? "";
          final change24h = data["change24h"] as String? ?? "";
          final isPositive = data["isPositive"] as bool? ?? true;
          final high24h = data["high24h"] as String? ?? "";
          final low24h = data["low24h"] as String? ?? "";

          final rawSparkline = data["sparkline"] as List<dynamic>? ?? const [];
          final sparkline = rawSparkline
              .map((e) => e is num ? e.toDouble() : 0.0)
              .toList();

          final trendColor = isPositive
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444); // Emerald vs Crimson
          final accentColor = trendColor.withOpacity(0.15);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(
                0xFF0F172A,
              ).withOpacity(0.85), // Deep Slate metallic
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: trendColor.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: trendColor.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header: Coin Meta & Symbol
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Decorative Glowing Coin Icon
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: trendColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.currency_bitcoin_rounded,
                                  color: trendColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (name.isNotEmpty)
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  if (symbol.isNotEmpty)
                                    Text(
                                      symbol,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white.withOpacity(0.4),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),

                          // 24h Change Pill
                          if (change24h.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: trendColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPositive
                                        ? Icons.trending_up_rounded
                                        : Icons.trending_down_rounded,
                                    color: trendColor,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    change24h,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: trendColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Price readout
                      if (price.isNotEmpty) ...[
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],

                      // High & Low stats
                      if (high24h.isNotEmpty || low24h.isNotEmpty) ...[
                        Row(
                          children: [
                            if (high24h.isNotEmpty) ...[
                              Text(
                                "H: $high24h",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.4),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (low24h.isNotEmpty)
                              Text(
                                "L: $low24h",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.4),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Glowing Custom Painter Sparkline
                      if (sparkline.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _SparklinePainter(
                              dataPoints: sparkline,
                              lineColor: trendColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> dataPoints;
  final Color lineColor;

  _SparklinePainter({required this.dataPoints, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.length < 2) return;

    final double minVal = dataPoints.reduce((a, b) => a < b ? a : b);
    final double maxVal = dataPoints.reduce((a, b) => a > b ? a : b);
    final double range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    final double widthBetweenPoints = size.width / (dataPoints.length - 1);

    final Path path = Path();
    final Path fillPath = Path();

    // Map starting coordinate
    final double startX = 0;
    final double startY =
        size.height - ((dataPoints.first - minVal) / range) * size.height;

    path.moveTo(startX, startY);
    fillPath.moveTo(startX, size.height);
    fillPath.lineTo(startX, startY);

    for (int i = 1; i < dataPoints.length; i++) {
      final double x = i * widthBetweenPoints;
      final double y =
          size.height - ((dataPoints[i] - minVal) / range) * size.height;
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw glowing shadow gradient fill under the line
    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [lineColor.withOpacity(0.25), lineColor.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Paint the stroke line
    final Paint strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.lineColor != lineColor;
  }
}
