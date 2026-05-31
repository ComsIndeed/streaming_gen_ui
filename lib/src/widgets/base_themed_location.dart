import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/theme_style_helper.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';
import 'package:streaming_gen_ui/src/widgets/core/themed_streaming_text.dart';
import 'package:streaming_gen_ui/src/widgets/base_streaming_image.dart';
import 'package:streaming_gen_ui/src/widgets/adaptive_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/core/adaptive_animated_size.dart';

/// A premium themed Location Search Card supporting M3, Fluent, Apple,
/// Glassmorphic, Neumorphic, Skeuomorphic, and Neo-Brutalist design aesthetics.
class BaseThemedLocationCard extends StatefulWidget {
  final PropertyStream props;
  final String themeName;

  const BaseThemedLocationCard({
    super.key,
    required this.props,
    required this.themeName,
  });

  @override
  State<BaseThemedLocationCard> createState() => _BaseThemedLocationCardState();
}

class _BaseThemedLocationCardState extends State<BaseThemedLocationCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final mapStream = widget.props.asMap;

    return StreamingEntrance(
      child: AdaptiveStreamBuilder<Map<String, dynamic>>(
        stream: mapStream.stream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};
          final settings =
              data["themeSettings"] as Map<String, dynamic>? ?? const {};

          final name = data["name"] as String? ?? 'Scenic Location';
          final address = data["address"] as String? ?? '';
          final latitude = (data["latitude"] as num?)?.toDouble();
          final longitude = (data["longitude"] as num?)?.toDouble();
          final rating = (data["rating"] as num?)?.toDouble();
          final imageUrl = data["imageUrl"] as String?;
          final distance = data["distance"] as String?;
          final phone = data["phone"] as String?;
          final hours = data["hours"] as String?;
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

          final cardContent = AdaptiveAnimatedSize(
            alignment: Alignment.topLeft,
            child: _buildCardContent(
              context,
              widget.props,
              name,
              address,
              latitude,
              longitude,
              rating,
              imageUrl,
              distance,
              phone,
              hours,
            ),
          );

          Widget cardFrame;

          if (widget.themeName == 'glassmorphic') {
            cardFrame = ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: BackdropFilter(
                filter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.02),
                  BlendMode.dstATop,
                ),
                child: Container(decoration: decoration, child: cardContent),
              ),
            );
          } else if (widget.themeName == 'fluent') {
            cardFrame = ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: BackdropFilter(
                filter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.04),
                  BlendMode.dstATop,
                ),
                child: Container(decoration: decoration, child: cardContent),
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
                debugPrint(
                  '[GEN_UI:LOCATION_ACTION] Location card clicked -> $action',
                );
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
    String name,
    String address,
    double? latitude,
    double? longitude,
    double? rating,
    String? imageUrl,
    String? distance,
    String? phone,
    String? hours,
  ) {
    final themeData = Theme.of(context);
    final isBrutalist = widget.themeName == 'brutalist';
    final titleStyle = ThemeStyleHelper.getTextStyle(
      widget.themeName,
      context,
      isTitle: true,
    );
    final subStyle = ThemeStyleHelper.getTextStyle(
      widget.themeName,
      context,
      isTitle: false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (imageUrl != null)
          AspectRatio(
            aspectRatio: 1.8,
            child: BaseStreamingImage(
              props: props,
              propertyName: 'imageUrl',
              themeName: widget.themeName,
              borderRadius: 0,
              fit: BoxFit.cover,
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Pin / Location Name
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on,
                    color: isBrutalist
                        ? Colors.black
                        : themeData.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ThemedStreamingText(
                          name,
                          themeName: widget.themeName,
                          style: titleStyle.copyWith(fontSize: 18),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (distance != null && distance.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            "$distance away",
                            style: subStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: themeData.colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (address.isNotEmpty)
                ThemedStreamingText(
                  address,
                  themeName: widget.themeName,
                  style: subStyle.copyWith(
                    color: themeData.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.9,
                    ),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (rating != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          rating > index ? Icons.star : Icons.star_border,
                          color: isBrutalist
                              ? Colors.black
                              : const Color(0xFFFFB300),
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      rating.toStringAsFixed(1),
                      style: subStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // Meta details (Phone & Hours)
              if (phone != null || hours != null) ...[
                Divider(
                  color: themeData.colorScheme.outline.withValues(alpha: 0.12),
                  height: 1,
                ),
                const SizedBox(height: 12),
                if (hours != null && hours.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: themeData.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hours,
                        style: subStyle.copyWith(
                          fontSize: 12,
                          color: themeData.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                if (phone != null && phone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 14,
                        color: themeData.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        phone,
                        style: subStyle.copyWith(
                          fontSize: 12,
                          color: themeData.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 16),
              // Direction & Call Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        debugPrint(
                          '[GEN_UI:LOCATION_DIR] Direct path map -> lat:$latitude lon:$longitude',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isBrutalist
                              ? Colors.black
                              : themeData.colorScheme.primary,
                          width: isBrutalist ? 2.0 : 1.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: isBrutalist
                              ? BorderRadius.zero
                              : BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(
                        Icons.directions_outlined,
                        color: isBrutalist
                            ? Colors.black
                            : themeData.colorScheme.primary,
                        size: 16,
                      ),
                      label: Text(
                        'Directions',
                        style: subStyle.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isBrutalist
                              ? Colors.black
                              : themeData.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        debugPrint(
                          '[GEN_UI:LOCATION_SHARE] Share details: $name',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBrutalist
                            ? const Color(0xFFFFFF00)
                            : themeData.colorScheme.primary,
                        foregroundColor: isBrutalist
                            ? Colors.black
                            : themeData.colorScheme.onPrimary,
                        elevation: isBrutalist ? 0 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: isBrutalist
                              ? BorderRadius.zero
                              : BorderRadius.circular(8),
                          side: isBrutalist
                              ? const BorderSide(
                                  color: Colors.black,
                                  width: 2.0,
                                )
                              : BorderSide.none,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(
                        Icons.share_outlined,
                        color: isBrutalist
                            ? Colors.black
                            : themeData.colorScheme.onPrimary,
                        size: 16,
                      ),
                      label: Text(
                        'Share',
                        style: subStyle.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isBrutalist
                              ? Colors.black
                              : themeData.colorScheme.onPrimary,
                        ),
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
