import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/theme_style_helper.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';

/// A premium themed Product Comparison Card (comparing multiple items side-by-side)
/// supporting M3, Fluent, Apple, Glassmorphic, Neumorphic, Skeuomorphic, and Neo-Brutalist styles.
class BaseThemedComparisonCard extends StatefulWidget {
  final PropertyStream props;
  final String themeName;

  const BaseThemedComparisonCard({
    super.key,
    required this.props,
    required this.themeName,
  });

  @override
  State<BaseThemedComparisonCard> createState() => _BaseThemedComparisonCardState();
}

class _BaseThemedComparisonCardState extends State<BaseThemedComparisonCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final mapStream = widget.props.asMap;

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: mapStream.stream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};
          final settings = data["themeSettings"] as Map<String, dynamic>? ?? const {};

          final title = data["title"] as String? ?? 'Compare Products';
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
            mapStream.getListProperty("products"),
            mapStream.getListProperty("features"),
          );

          Widget cardFrame;

          if (widget.themeName == 'glassmorphic') {
            cardFrame = ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: BackdropFilter(
                filter: ColorFilter.mode(Colors.black.withValues(alpha: 0.02), BlendMode.dstATop),
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
                filter: ColorFilter.mode(Colors.black.withValues(alpha: 0.04), BlendMode.dstATop),
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
                debugPrint('[GEN_UI:COMPARISON_ACTION] Comparison card clicked -> $action');
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
    PropertyStream productsProp,
    PropertyStream featuresProp,
  ) {
    final themeData = Theme.of(context);
    final isBrutalist = widget.themeName == 'brutalist';
    final titleStyle = ThemeStyleHelper.getTextStyle(widget.themeName, context, isTitle: true);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: titleStyle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          // Streaming layout for side-by-side comparative elements
          StreamBuilder2<List<dynamic>, List<dynamic>>(
            streamA: productsProp.asList.stream,
            streamB: featuresProp.asList.stream,
            builder: (context, products, features) {
              final safeProducts = products ?? const [];
              final safeFeatures = features ?? const [];

              if (safeProducts.isEmpty) {
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  ),
                );
              }

              // Features always includes price and rating by default
              final allSpecs = ['Price', 'Rating', ...safeFeatures.map((f) => f.toString())];

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
                      color: isBrutalist ? Colors.black : themeData.colorScheme.outline.withValues(alpha: 0.12),
                      width: isBrutalist ? 2.0 : 1.0,
                    ),
                    children: [
                      // Header Row: Blank first cell, then Product Names
                      TableRow(
                        decoration: BoxDecoration(
                          color: isBrutalist
                              ? const Color(0xFFFFFF00)
                              : themeData.colorScheme.primaryContainer.withValues(alpha: 0.4),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                            child: Text(
                              'Feature',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: isBrutalist ? Colors.black : themeData.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          ...safeProducts.map((p) {
                            final prod = p as Map<String, dynamic>? ?? const {};
                            final name = prod["name"] as String? ?? 'Product';
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: isBrutalist ? Colors.black : themeData.colorScheme.onSurface,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      // Spec rows
                      ...allSpecs.map((spec) {
                        return TableRow(
                          children: [
                            // Spec title cell
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              child: Text(
                                spec,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: isBrutalist ? Colors.black : themeData.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            // Comparative spec value for each product
                            ...safeProducts.map((p) {
                              final prod = p as Map<String, dynamic>? ?? const {};

                              String specVal = '';
                              if (spec == 'Price') {
                                final pr = prod["price"];
                                specVal = pr != null ? (pr is num ? "\$${pr.toStringAsFixed(2)}" : pr.toString()) : '--';
                              } else if (spec == 'Rating') {
                                final rt = prod["rating"];
                                specVal = rt != null ? "${rt.toString()}/5.0" : '--';
                              } else {
                                final specs = prod["specs"] as Map<String, dynamic>? ?? const {};
                                specVal = specs[spec]?.toString() ?? '--';
                              }

                              Color textColor;
                              if (widget.themeName == 'brutalist') {
                                textColor = Colors.black;
                              } else if (widget.themeName == 'skeumorphic') {
                                textColor = themeData.brightness == Brightness.dark ? Colors.grey.shade100 : Colors.grey.shade900;
                              } else {
                                textColor = themeData.colorScheme.onSurface;
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                                child: Text(
                                  specVal,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textColor,
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Reusable StreamBuilder2 in same file (matching base_themed_graph.dart definition)
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
