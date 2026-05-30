import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/theme_style_helper.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';

/// A premium themed List Results Card (minified list tiles / recent items catalog)
/// supporting M3, Fluent, Apple, Glassmorphic, Neumorphic, Skeuomorphic, and Neo-Brutalist styles.
class BaseThemedListResultsCard extends StatefulWidget {
  final PropertyStream props;
  final String themeName;

  const BaseThemedListResultsCard({
    super.key,
    required this.props,
    required this.themeName,
  });

  @override
  State<BaseThemedListResultsCard> createState() =>
      _BaseThemedListResultsCardState();
}

class _BaseThemedListResultsCardState extends State<BaseThemedListResultsCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final mapStream = widget.props.asMap;

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: mapStream.stream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};
          final settings =
              data["themeSettings"] as Map<String, dynamic>? ?? const {};

          final title = data["title"] as String? ?? 'Recent Files';
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
              title,
              mapStream.getListProperty("items"),
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
                  '[GEN_UI:LIST_ACTION] List results card clicked -> $action',
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
    String title,
    PropertyStream itemsProp,
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

    // Dynamic map of common icon names to IconData
    IconData getFileIcon(String? iconName) {
      if (iconName == null) return Icons.description_outlined;
      switch (iconName.toLowerCase()) {
        case 'image':
        case 'photo':
        case 'png':
        case 'jpg':
          return Icons.image_outlined;
        case 'video':
        case 'movie':
        case 'mp4':
          return Icons.video_library_outlined;
        case 'audio':
        case 'music':
        case 'mp3':
          return Icons.audiotrack_outlined;
        case 'pdf':
        case 'doc':
        case 'document':
          return Icons.picture_as_pdf_outlined;
        case 'code':
        case 'json':
        case 'dart':
          return Icons.code_outlined;
        case 'folder':
          return Icons.folder_open_outlined;
        case 'link':
          return Icons.link_outlined;
        case 'archive':
        case 'zip':
          return Icons.archive_outlined;
        default:
          return Icons.description_outlined;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: titleStyle.copyWith(fontSize: 16)),
              const Icon(Icons.arrow_forward_ios, size: 12),
            ],
          ),
          const SizedBox(height: 12),
          // Streaming tile rows
          StreamBuilder<List<dynamic>>(
            stream: itemsProp.asList.stream,
            builder: (context, snapshot) {
              final list = snapshot.data ?? const [];
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  ),
                );
              }

              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: list.length,
                separatorBuilder: (context, index) => Divider(
                  color: themeData.colorScheme.outline.withValues(alpha: 0.08),
                  height: 12,
                ),
                itemBuilder: (context, index) {
                  final item = list[index] as Map<String, dynamic>? ?? const {};
                  final itemTitle = item["title"] as String? ?? 'Document';
                  final itemSubtitle = item["subtitle"] as String?;
                  final itemIcon = item["icon"] as String?;
                  final itemDate = item["date"] as String?;
                  final itemSize = item["size"] as String?;
                  final itemStatus = item["status"] as String?;

                  final rowIcon = getFileIcon(itemIcon);

                  return Row(
                    children: [
                      // Circular leading icon box
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isBrutalist
                              ? const Color(0xFF00FFFF)
                              : themeData.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.4),
                          borderRadius: isBrutalist
                              ? BorderRadius.zero
                              : BorderRadius.circular(8),
                          border: isBrutalist
                              ? Border.all(color: Colors.black, width: 1.5)
                              : null,
                        ),
                        child: Icon(
                          rowIcon,
                          size: 20,
                          color: isBrutalist
                              ? Colors.black
                              : themeData.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              itemTitle,
                              style: subStyle.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (itemSubtitle != null &&
                                itemSubtitle.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                itemSubtitle,
                                style: subStyle.copyWith(
                                  fontSize: 11,
                                  color: themeData.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Meta side info (date, size, or badge status)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (itemDate != null && itemDate.isNotEmpty)
                            Text(
                              itemDate,
                              style: TextStyle(
                                fontSize: 10,
                                color: themeData.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          if (itemSize != null && itemSize.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              itemSize,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: themeData.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                          if (itemStatus != null && itemStatus.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Container(
                              decoration: BoxDecoration(
                                color: isBrutalist
                                    ? const Color(0xFF00FF00)
                                    : themeData.colorScheme.primaryContainer
                                          .withValues(alpha: 0.4),
                                borderRadius: isBrutalist
                                    ? BorderRadius.zero
                                    : BorderRadius.circular(4),
                                border: isBrutalist
                                    ? Border.all(
                                        color: Colors.black,
                                        width: 1.0,
                                      )
                                    : null,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Text(
                                itemStatus.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      themeData.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
