import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';
import 'package:streaming_gen_ui/src/widgets/theme_style_helper.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';
import 'package:streaming_gen_ui/src/widgets/base_streaming_image.dart';

/// A premium, highly customizable shared card engine supporting M3, Fluent, Apple,
/// Glassmorphism, Neumorphism, Skeuomorphism, and Neo-Brutalist aesthetics.
class BaseThemedCard extends StatefulWidget {
  final PropertyStream props;
  final String themeName;

  const BaseThemedCard({
    super.key,
    required this.props,
    required this.themeName,
  });

  @override
  State<BaseThemedCard> createState() => _BaseThemedCardState();
}

class _BaseThemedCardState extends State<BaseThemedCard> {
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

          final title = data["title"] as String?;
          final subtitle = data["subtitle"] as String?;
          final imageUrl = data["imageUrl"] as String?;
          final imagePos = data["imagePosition"] as String? ?? 'top';
          final statusLabel = data["statusLabel"] as String?;
          final statusStyle = data["statusStyle"] as String? ?? 'info';
          final action = data["action"] as String?;

          final hasAction = action != null && action.isNotEmpty;

          // Resolve aesthetic decorations
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

          // Card contents
          final cardContent = _buildCardContent(
            context,
            title,
            subtitle,
            imageUrl,
            imagePos,
            statusLabel,
            statusStyle,
            mapStream.getMapProperty("body"),
          );

          Widget cardFrame;

          if (widget.themeName == 'glassmorphic') {
            // High sigma frosted glass panel
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
            // Windows Fluent acrylic blurred panel
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
            // Standard container card
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
                debugPrint('[GEN_UI:CARD_ACTION] Card clicked -> $action');
              },
              child: AnimatedScale(
                scale: _isPressed ? 0.97 : 1.0, // Emil tactile pressed scale
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
    String? title,
    String? subtitle,
    String? imageUrl,
    String imagePos,
    String? statusLabel,
    String statusStyle,
    PropertyStream bodyProp,
  ) {
    final themeData = Theme.of(context);
    final titleStyle = ThemeStyleHelper.getTextStyle(widget.themeName, context, isTitle: true);
    final subStyle = ThemeStyleHelper.getTextStyle(widget.themeName, context, isTitle: false);

    // Build the visual text metadata block
    final textMetaBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Empty parameter protection: check title
            if (title != null && title.isNotEmpty)
              Expanded(
                child: Text(
                  title,
                  style: titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (statusLabel != null && statusLabel.isNotEmpty) ...[
              const SizedBox(width: 8),
              _buildStatusBadge(context, statusLabel, statusStyle),
            ],
          ],
        ),
        // Empty parameter protection: check subtitle
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: subStyle.copyWith(
              color: themeData.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    final innerPadding = const EdgeInsets.all(16.0);

    // Build the media block if present
    Widget? mediaBlock;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      mediaBlock = BaseStreamingImage(
        imageUrl: imageUrl,
        themeName: widget.themeName,
        borderRadius: 0,
        fit: BoxFit.cover,
      );
    }

    Widget contentLayout;

    // Arrange card elements according to imagePosition (left, right, top, bottom)
    if (mediaBlock != null) {
      if (imagePos == 'left' || imagePos == 'right') {
        final rowChildren = [
          if (imagePos == 'left')
            SizedBox(
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: mediaBlock,
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  textMetaBlock,
                  const SizedBox(height: 8),
                  StreamingWidget(props: bodyProp),
                ],
              ),
            ),
          ),
          if (imagePos == 'right')
            SizedBox(
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: mediaBlock,
              ),
            ),
        ];

        contentLayout = Padding(
          padding: innerPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren,
          ),
        );
      } else {
        // Top or bottom positions
        final colChildren = [
          if (imagePos == 'top')
            AspectRatio(
              aspectRatio: 2.0,
              child: mediaBlock,
            ),
          Padding(
            padding: innerPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                textMetaBlock,
                const SizedBox(height: 12),
                StreamingWidget(props: bodyProp),
              ],
            ),
          ),
          if (imagePos == 'bottom')
            AspectRatio(
              aspectRatio: 2.0,
              child: mediaBlock,
            ),
        ];

        contentLayout = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: colChildren,
        );
      }
    } else {
      // Standard no media container
      contentLayout = Padding(
        padding: innerPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            textMetaBlock,
            const SizedBox(height: 12),
            StreamingWidget(props: bodyProp),
          ],
        ),
      );
    }

    // Organic height expansions wrapped in AnimatedSize (The Stable Alignment Rule)
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: contentLayout,
    );
  }

  Widget _buildStatusBadge(BuildContext context, String label, String style) {
    final theme = Theme.of(context);
    Color bg;
    Color text;

    switch (style.toLowerCase()) {
      case 'success':
        bg = Colors.green.shade100;
        text = Colors.green.shade900;
        break;
      case 'warning':
        bg = Colors.orange.shade100;
        text = Colors.orange.shade900;
        break;
      case 'danger':
        bg = Colors.red.shade100;
        text = Colors.red.shade900;
        break;
      case 'info':
      default:
        bg = theme.colorScheme.primaryContainer;
        text = theme.colorScheme.onPrimaryContainer;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }
}
