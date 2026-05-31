import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/theme_style_helper.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';
import 'package:streaming_gen_ui/src/widgets/base_streaming_image.dart';
import 'package:streaming_gen_ui/src/widgets/adaptive_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/core/adaptive_animated_size.dart';

/// A premium search/web query result layout supporting M3, Fluent, Apple,
/// Glassmorphic, Neumorphic, Skeuomorphic, and Neo-Brutalist design systems.
class BaseThemedWebResultCard extends StatefulWidget {
  final PropertyStream props;
  final String themeName;

  const BaseThemedWebResultCard({
    super.key,
    required this.props,
    required this.themeName,
  });

  @override
  State<BaseThemedWebResultCard> createState() =>
      _BaseThemedWebResultCardState();
}

class _BaseThemedWebResultCardState extends State<BaseThemedWebResultCard> {
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

          final title = data["title"] as String? ?? 'Search Query Result';
          final url = data["url"] as String? ?? '';
          final snippet = data["snippet"] as String? ?? '';
          final faviconUrl = data["faviconUrl"] as String?;
          final siteName = data["siteName"] as String?;
          final publishDate = data["publishDate"] as String?;
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
              title,
              url,
              snippet,
              faviconUrl,
              siteName,
              publishDate,
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

          if (hasAction || url.isNotEmpty) {
            return GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: () {
                debugPrint(
                  '[GEN_UI:WEB_ACTION] Clicked Web Result URL -> ${action ?? url}',
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
    String title,
    String url,
    String snippet,
    String? faviconUrl,
    String? siteName,
    String? publishDate,
  ) {
    final themeData = Theme.of(context);
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

    final siteDisplay =
        siteName ?? (url.isNotEmpty ? Uri.tryParse(url)?.host ?? url : '');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Site Info / Breadcrumbs / Favicon Row
          if (siteDisplay.isNotEmpty) ...[
            Row(
              children: [
                if (faviconUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: BaseStreamingImage(
                        props: props,
                        propertyName: 'faviconUrl',
                        themeName: widget.themeName,
                        borderRadius: 0,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  const Icon(Icons.public_outlined, size: 16),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        siteDisplay,
                        style: subStyle.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: themeData.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (url.isNotEmpty)
                        Text(
                          url,
                          style: TextStyle(
                            fontSize: 10,
                            color: themeData.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // Headline / Link Title
          Text(
            title,
            style: titleStyle.copyWith(
              fontSize: 16,
              color: widget.themeName == 'brutalist'
                  ? Colors.black
                  : (widget.themeName == 'apple'
                        ? Colors.blue.shade700
                        : themeData.colorScheme.primary),
              decoration: TextDecoration.underline,
              decorationColor: widget.themeName == 'brutalist'
                  ? Colors.black
                  : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Snippet Description & Meta
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (publishDate != null && publishDate.isNotEmpty) ...[
                Text(
                  "$publishDate — ",
                  style: subStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: themeData.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              Expanded(
                child: Text(
                  snippet,
                  style: subStyle.copyWith(
                    fontSize: 13,
                    color: themeData.colorScheme.onSurface.withValues(
                      alpha: 0.85,
                    ),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
