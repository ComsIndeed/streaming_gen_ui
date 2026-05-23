import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/theme_style_helper.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';

/// A premium, responsive data visualization card supporting M3, Fluent, Apple,
/// Glassmorphic, Neumorphic, Skeuomorphic, and Neo-Brutalist design aesthetics.
/// Dynamically updates and animates as new values stream in.
class BaseThemedGraphCard extends StatefulWidget {
  final PropertyStream props;
  final String themeName;

  const BaseThemedGraphCard({
    super.key,
    required this.props,
    required this.themeName,
  });

  @override
  State<BaseThemedGraphCard> createState() => _BaseThemedGraphCardState();
}

class _BaseThemedGraphCardState extends State<BaseThemedGraphCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final mapStream = widget.props.asMap;

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: mapStream.stream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};
          final settings = data["themeSettings"] as Map<String, dynamic>? ?? const {};

          final title = data["title"] as String? ?? 'Data Analysis';
          final subtitle = data["subtitle"] as String?;
          final type = data["type"] as String? ?? 'bar'; // bar, line, pie, table
          final action = data["action"] as String?;

          final hasAction = action != null && action.isNotEmpty;

          final decoration = ThemeStyleHelper.getCardDecoration(
            widget.themeName,
            settings,
            context,
            isPressed: _isPressed,
          );

          final shape = ThemeStyleHelper.getCardShape(
            widget.themeName,
            (settings["borderRadius"] as num?)?.toDouble(),
            context,
          );

          final cardContent = _buildCardContent(
            context,
            title,
            subtitle,
            type,
            mapStream.getListProperty("labels"),
            mapStream.getListProperty("values"),
            mapStream.getListProperty("headers"),
            mapStream.getListProperty("rows"),
          );

          Widget cardFrame;

          if (widget.themeName == 'glassmorphic') {
            cardFrame = ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: BackdropFilter(
                filter: ColorFilter.mode(Colors.black.withOpacity(0.02), BlendMode.dstATop),
                child: Container(
                  decoration: decoration,
                  child: cardContent,
                ),
              ),
            );
          } else if (widget.themeName == 'fluent') {
            cardFrame = ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: BackdropFilter(
                filter: ColorFilter.mode(Colors.black.withOpacity(0.04), BlendMode.dstATop),
                child: Container(
                  decoration: decoration,
                  child: cardContent,
                ),
              ),
            );
          } else {
            cardFrame = Container(
              decoration: decoration,
              child: Material(
                type: MaterialType.transparency,
                shape: shape,
                clipBehavior: Clip.antiAlias,
                child: cardContent,
              ),
            );
          }

          if (hasAction) {
            return GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: () {
                debugPrint('[GEN_UI:GRAPH_ACTION] Graph card clicked -> $action');
              },
              child: AnimatedScale(
                scale: _isPressed ? 0.97 : 1.0,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOutCubic,
                child: cardFrame,
              ),
            );
          }

          return cardFrame;
        },
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    String title,
    String? subtitle,
    String type,
    PropertyStream labelsProp,
    PropertyStream valuesProp,
    PropertyStream headersProp,
    PropertyStream rowsProp,
  ) {
    final themeData = Theme.of(context);
    final titleStyle = ThemeStyleHelper.getTextStyle(widget.themeName, context, isTitle: true);
    final subStyle = ThemeStyleHelper.getTextStyle(widget.themeName, context, isTitle: false);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: titleStyle.copyWith(fontSize: 18)),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: subStyle.copyWith(
                color: themeData.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Streaming layout for dynamic graph types
          StreamBuilder2<List<dynamic>, List<dynamic>>(
            streamA: labelsProp.asList.stream,
            streamB: valuesProp.asList.stream,
            builder: (context, labels, values) {
              final safeLabels = labels ?? const [];
              final safeValues = values ?? const [];

              switch (type.toLowerCase()) {
                case 'line':
                  return _buildLineChart(context, safeLabels, safeValues);
                case 'pie':
                  return _buildPieChart(context, safeLabels, safeValues);
                case 'table':
                  return _buildDataTable(context, headersProp, rowsProp);
                case 'bar':
                default:
                  return _buildBarChart(context, safeLabels, safeValues);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, List<dynamic> labels, List<dynamic> values) {
    if (values.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('Awaiting streaming data...')),
      );
    }

    final themeData = Theme.of(context);
    final numValues = values.map((e) => (e as num).toDouble()).toList();
    final maxVal = numValues.reduce((a, b) => a > b ? a : b);
    final double scaleMax = maxVal == 0 ? 1.0 : maxVal * 1.15;

    final primaryAccent = widget.themeName == 'brutalist'
        ? const Color(0xFFFFFF00) // Hot yellow
        : themeData.colorScheme.primary;

    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(numValues.length, (index) {
          final val = numValues[index];
          final pct = val / scaleMax;
          final label = index < labels.length ? labels[index].toString() : '';

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: pct.clamp(0.02, 1.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          decoration: BoxDecoration(
                            color: primaryAccent,
                            borderRadius: widget.themeName == 'brutalist'
                                ? BorderRadius.zero
                                : BorderRadius.circular(4),
                            border: widget.themeName == 'brutalist'
                                ? Border.all(color: Colors.black, width: 2.0)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    val.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: themeData.colorScheme.onSurface,
                    ),
                  ),
                  if (label.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        color: themeData.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLineChart(BuildContext context, List<dynamic> labels, List<dynamic> values) {
    if (values.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('Awaiting streaming data...')),
      );
    }

    final themeData = Theme.of(context);
    final numValues = values.map((e) => (e as num).toDouble()).toList();

    return SizedBox(
      height: 160,
      width: double.infinity,
      child: CustomPaint(
        painter: _LineChartPainter(
          values: numValues,
          themeName: widget.themeName,
          primaryColor: widget.themeName == 'brutalist'
              ? Colors.black
              : themeData.colorScheme.primary,
          accentColor: widget.themeName == 'brutalist'
              ? const Color(0xFFFF007F)
              : themeData.colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, List<dynamic> labels, List<dynamic> values) {
    if (values.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('Awaiting streaming data...')),
      );
    }

    final numValues = values.map((e) => (e as num).toDouble()).toList();
    final double total = numValues.reduce((a, b) => a + b);

    final colors = widget.themeName == 'brutalist'
        ? const [
            Color(0xFFFFFF00), // hot yellow
            Color(0xFFFF007F), // hot pink
            Color(0xFF00FFFF), // cyan
            Color(0xFF00FF00), // bright green
          ]
        : const [
            Color(0xFF6366F1),
            Color(0xFF3B82F6),
            Color(0xFF10B981),
            Color(0xFFF59E0B),
            Color(0xFFEF4444),
          ];

    return Row(
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: CustomPaint(
            painter: _PieChartPainter(
              values: numValues,
              colors: colors,
              total: total,
              themeName: widget.themeName,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(numValues.length, (index) {
              final val = numValues[index];
              final label = index < labels.length ? labels[index].toString() : 'Item $index';
              final pct = total == 0 ? 0.0 : (val / total) * 100;
              final col = colors[index % colors.length];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: col,
                        shape: widget.themeName == 'brutalist' ? BoxShape.rectangle : BoxShape.circle,
                        border: widget.themeName == 'brutalist'
                            ? Border.all(color: Colors.black, width: 1.0)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "$label (${pct.toStringAsFixed(0)}%)",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        )
      ],
    );
  }

  Widget _buildDataTable(BuildContext context, PropertyStream headersProp, PropertyStream rowsProp) {
    final themeData = Theme.of(context);
    final isBrutalist = widget.themeName == 'brutalist';

    return StreamBuilder2<List<dynamic>, List<dynamic>>(
      streamA: headersProp.asList.stream,
      streamB: rowsProp.asList.stream,
      builder: (context, headersSnapshot, rowsSnapshot) {
        final headers = headersSnapshot ?? const [];
        final rows = rowsSnapshot ?? const [];

        if (headers.isEmpty && rows.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(child: Text('Awaiting table data...')),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              border: isBrutalist ? Border.all(color: Colors.black, width: 2.0) : null,
              borderRadius: isBrutalist ? BorderRadius.zero : BorderRadius.circular(8.0),
            ),
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.all(
                color: isBrutalist ? Colors.black : themeData.colorScheme.outline.withOpacity(0.15),
                width: isBrutalist ? 2.0 : 1.0,
              ),
              children: [
                // Header row
                if (headers.isNotEmpty)
                  TableRow(
                    decoration: BoxDecoration(
                      color: isBrutalist
                          ? const Color(0xFFFFFF00)
                          : themeData.colorScheme.primaryContainer.withOpacity(0.4),
                    ),
                    children: headers.map((h) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        child: Text(
                          h.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isBrutalist ? Colors.black : themeData.colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                // Data rows
                ...rows.map((row) {
                  final List<dynamic> cells = row is List
                      ? row
                      : (row is Map ? row.values.toList() : [row.toString()]);
                  return TableRow(
                    children: cells.map((cell) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        child: Text(
                          cell.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// StreamBuilder combining two streams
class StreamBuilder2<A, B> extends StatelessWidget {
  final Stream<A> streamA;
  final Stream<B> streamB;
  final Widget Function(BuildContext context, A? a, B? b) builder;

  const StreamBuilder2({
    super.key,
    required this.streamA,
    required this.streamB,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<A>(
      stream: streamA,
      builder: (context, snapA) {
        return StreamBuilder<B>(
          stream: streamB,
          builder: (context, snapB) {
            return builder(context, snapA.data, snapB.data);
          },
        );
      },
    );
  }
}

/// Custom painter to draw a dynamic, sleek line path
class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final String themeName;
  final Color primaryColor;
  final Color accentColor;

  _LineChartPainter({
    required this.values,
    required this.themeName,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double maxVal = values.reduce((a, b) => a > b ? a : b);
    final double minVal = values.reduce((a, b) => a < b ? a : b);
    final double spread = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;
    final double padMax = maxVal + (spread * 0.1);
    final double padMin = minVal - (spread * 0.1);
    final double finalSpread = padMax - padMin;

    final double stepX = size.width / (values.length > 1 ? values.length - 1 : 1);

    final path = Path();
    final fillPath = Path();

    final List<Offset> points = [];

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final ratio = finalSpread == 0 ? 0.5 : (values[i] - padMin) / finalSpread;
      final y = size.height - (ratio * size.height);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw background gradient fill under line
    if (themeName != 'brutalist') {
      final fillPaint = Paint()
        ..shader = LinearGradient(
          colors: [primaryColor.withOpacity(0.25), primaryColor.withOpacity(0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw line
    final linePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = themeName == 'brutalist' ? 3.0 : 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw dots
    final dotPaint = Paint()
      ..color = themeName == 'brutalist' ? Colors.white : primaryColor
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final pt in points) {
      canvas.drawCircle(pt, themeName == 'brutalist' ? 5.5 : 4.0, dotPaint);
      if (themeName == 'brutalist') {
        canvas.drawCircle(pt, 5.5, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}

/// Custom painter to draw beautiful pie slices
class _PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double total;
  final String themeName;

  _PieChartPainter({
    required this.values,
    required this.colors,
    required this.total,
    required this.themeName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final double center = size.width / 2;
    final double radius = size.width / 2;
    final rect = Rect.fromCircle(center: Offset(center, center), radius: radius);

    double startAngle = -math.pi / 2;

    for (int i = 0; i < values.length; i++) {
      final val = values[i];
      final sweepAngle = (val / total) * 2 * math.pi;

      final slicePaint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, slicePaint);

      if (themeName == 'brutalist') {
        final outlinePaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawArc(rect, startAngle, sweepAngle, true, outlinePaint);
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) => true;
}
