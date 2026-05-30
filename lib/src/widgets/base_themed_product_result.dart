import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/theme_style_helper.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';
import 'package:streaming_gen_ui/src/widgets/core/themed_streaming_text.dart';
import 'package:streaming_gen_ui/src/widgets/base_streaming_image.dart';

/// A premium, customizable Product Result Card supporting M3, Fluent, Apple,
/// Glassmorphic, Neumorphic, Skeuomorphic, and Neo-Brutalist design aesthetics.
class BaseThemedProductResultCard extends StatefulWidget {
  final PropertyStream props;
  final String themeName;

  const BaseThemedProductResultCard({
    super.key,
    required this.props,
    required this.themeName,
  });

  @override
  State<BaseThemedProductResultCard> createState() => _BaseThemedProductResultCardState();
}

class _BaseThemedProductResultCardState extends State<BaseThemedProductResultCard> {
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

          final title = data["title"] as String? ?? 'Premium Product';
          final price = data["price"] as dynamic;
          final originalPrice = data["originalPrice"] as dynamic;
          final rating = (data["rating"] as num?)?.toDouble();
          final imageUrl = data["imageUrl"] as String?;
          final description = data["description"] as String?;
          final badge = data["badge"] as String?;
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

          final cardContent = AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topLeft,
            child: _buildCardContent(
              context,
              widget.props,
              title,
              price,
              originalPrice,
              rating,
              imageUrl,
              description,
              badge,
              mapStream.getListProperty("features"),
            ),
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
                debugPrint('[GEN_UI:PRODUCT_ACTION] Product card clicked -> $action');
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
    PropertyStream props,
    String title,
    dynamic price,
    dynamic originalPrice,
    double? rating,
    String? imageUrl,
    String? description,
    String? badge,
    PropertyStream featuresProp,
  ) {
    final themeData = Theme.of(context);
    final isBrutalist = widget.themeName == 'brutalist';
    final titleStyle = ThemeStyleHelper.getTextStyle(widget.themeName, context, isTitle: true);
    final subStyle = ThemeStyleHelper.getTextStyle(widget.themeName, context, isTitle: false);

    // Format prices safely
    String formatPrice(dynamic p) {
      if (p == null) return '';
      if (p is num) return "\$${p.toStringAsFixed(2)}";
      return p.toString();
    }

    final priceStr = formatPrice(price);
    final origPriceStr = formatPrice(originalPrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Product Hero Image block
        if (imageUrl != null)
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.6,
                child: BaseStreamingImage(
                  props: props,
                  propertyName: 'imageUrl',
                  themeName: widget.themeName,
                  borderRadius: 0,
                  fit: BoxFit.cover,
                ),
              ),
              // Optional badge
              if (badge != null && badge.isNotEmpty)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isBrutalist ? const Color(0xFFFFFF00) : themeData.colorScheme.primary,
                      borderRadius: isBrutalist ? BorderRadius.zero : BorderRadius.circular(4),
                      border: isBrutalist ? Border.all(color: Colors.black, width: 2.0) : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      badge.toUpperCase(),
                      style: TextStyle(
                        color: isBrutalist ? Colors.black : themeData.colorScheme.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ThemedStreamingText(
                      title,
                      themeName: widget.themeName,
                      style: titleStyle.copyWith(fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (rating != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        final starFilled = rating > index;
                        return Icon(
                          starFilled ? Icons.star : Icons.star_border,
                          color: isBrutalist ? Colors.black : const Color(0xFFFFB300),
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      rating.toStringAsFixed(1),
                      style: subStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ],
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 8),
                ThemedStreamingText(
                  description,
                  themeName: widget.themeName,
                  style: subStyle.copyWith(
                    color: themeData.colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Dynamic feature bullet items
              StreamBuilder<List<dynamic>>(
                stream: featuresProp.asList.stream,
                builder: (context, featuresSnapshot) {
                  final list = featuresSnapshot.data ?? const [];
                  if (list.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: list.map((item) {
                          return Container(
                            decoration: BoxDecoration(
                              color: themeData.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: isBrutalist ? BorderRadius.zero : BorderRadius.circular(6),
                              border: isBrutalist ? Border.all(color: Colors.black, width: 1.5) : null,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: Text(
                              item.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: themeData.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Divider(
                color: themeData.colorScheme.outline.withValues(alpha: 0.15),
                height: 1,
              ),
              const SizedBox(height: 12),
              // Price and Call-To-Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (priceStr.isNotEmpty)
                        Text(
                          priceStr,
                          style: titleStyle.copyWith(
                            fontSize: 22,
                            color: isBrutalist ? Colors.black : themeData.colorScheme.primary,
                          ),
                        ),
                      if (origPriceStr.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          origPriceStr,
                          style: TextStyle(
                            fontSize: 14,
                            color: themeData.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Compact elegant purchase button
                  ElevatedButton(
                    onPressed: () {
                      debugPrint('[GEN_UI:PRODUCT_CTA] Buy item click: $title');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBrutalist ? const Color(0xFFFFFF00) : themeData.colorScheme.primary,
                      foregroundColor: isBrutalist ? Colors.black : themeData.colorScheme.onPrimary,
                      elevation: isBrutalist ? 0 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: isBrutalist ? BorderRadius.zero : BorderRadius.circular(8),
                        side: isBrutalist ? const BorderSide(color: Colors.black, width: 2.0) : BorderSide.none,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(
                      'View Details',
                      style: subStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isBrutalist ? Colors.black : themeData.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
