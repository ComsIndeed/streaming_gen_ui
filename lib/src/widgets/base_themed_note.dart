import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/theme_style_helper.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';
import 'package:streaming_gen_ui/src/widgets/core/themed_streaming_text.dart';
import 'package:streaming_gen_ui/src/widgets/base_streaming_image.dart';

/// A premium themed Standalone Todo / Reminder / Note card supporting
/// M3, Fluent, Apple, Glassmorphic, Neumorphic, Skeuomorphic, and Neo-Brutalist design aesthetics.
class BaseThemedNoteCard extends StatefulWidget {
  final PropertyStream props;
  final String themeName;

  const BaseThemedNoteCard({
    super.key,
    required this.props,
    required this.themeName,
  });

  @override
  State<BaseThemedNoteCard> createState() => _BaseThemedNoteCardState();
}

class _BaseThemedNoteCardState extends State<BaseThemedNoteCard> {
  bool _isPressed = false;
  bool _localCompleted = false;
  bool _completionOverridden = false;

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

          final type =
              data["type"] as String? ?? 'note'; // note, todo, reminder
          final title = data["title"] as String? ?? 'Quick Note';
          final content = data["content"] as String? ?? '';
          final rawCompleted = data["completed"] as bool? ?? false;
          final dueDate = data["dueDate"] as String?;
          final priority = data["priority"] as String?;
          final imageUrl = data["imageUrl"] as String?;
          final lastModified = data["lastModified"] as String?;
          final action = data["action"] as String?;

          final hasAction = action != null && action.isNotEmpty;

          final completed = _completionOverridden
              ? _localCompleted
              : rawCompleted;

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
              type,
              title,
              content,
              completed,
              dueDate,
              priority,
              imageUrl,
              lastModified,
              mapStream.getListProperty("tags"),
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
                debugPrint('[GEN_UI:NOTE_ACTION] Note Card clicked -> $action');
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
    String type,
    String title,
    String content,
    bool completed,
    String? dueDate,
    String? priority,
    String? imageUrl,
    String? lastModified,
    PropertyStream tagsProp,
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

    // Dynamic icon representing the note category
    IconData getNoteIcon() {
      switch (type.toLowerCase()) {
        case 'todo':
          return Icons.check_circle_outline;
        case 'reminder':
          return Icons.notifications_none_outlined;
        case 'note':
        default:
          return Icons.sticky_note_2_outlined;
      }
    }

    Color getPriorityColor(String? priority) {
      if (priority == null) return Colors.transparent;
      switch (priority.toLowerCase()) {
        case 'high':
          return isBrutalist ? const Color(0xFFFF007F) : Colors.red;
        case 'medium':
          return isBrutalist ? const Color(0xFFFF9800) : Colors.orange;
        case 'low':
          return isBrutalist ? const Color(0xFF00FF00) : Colors.green;
        default:
          return Colors.transparent;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner hero image slot if present
          if (imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: BaseStreamingImage(
                props: props,
                propertyName: 'imageUrl',
                themeName: widget.themeName,
                borderRadius: isBrutalist ? 0 : 8.0,
                aspectRatio: 2.2,
                fit: BoxFit.cover,
              ),
            ),
          // Row Header: Type icon, Title, Priority dot
          Row(
            children: [
              Icon(
                getNoteIcon(),
                size: 20,
                color: isBrutalist
                    ? Colors.black
                    : themeData.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ThemedStreamingText(
                  title,
                  themeName: widget.themeName,
                  style: titleStyle.copyWith(
                    fontSize: 16,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (priority != null && priority.isNotEmpty)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: getPriorityColor(priority),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Content block
          if (content.isNotEmpty)
            ThemedStreamingText(
              content,
              themeName: widget.themeName,
              style: subStyle.copyWith(
                fontSize: 14,
                color: themeData.colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          // Interactive toggle for Standalone Todo/Reminders
          if (type.toLowerCase() == 'todo' ||
              type.toLowerCase() == 'reminder') ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                setState(() {
                  _completionOverridden = true;
                  _localCompleted = !completed;
                });
                debugPrint(
                  '[GEN_UI:NOTE_TODO_TOGGLE] Task state toggled -> ${!completed}',
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: completed
                          ? (isBrutalist
                                ? const Color(0xFF00FF00)
                                : themeData.colorScheme.primary)
                          : Colors.transparent,
                      borderRadius: isBrutalist
                          ? BorderRadius.zero
                          : BorderRadius.circular(4),
                      border: Border.all(
                        color: isBrutalist
                            ? Colors.black
                            : themeData.colorScheme.outline,
                        width: 2.0,
                      ),
                    ),
                    child: completed
                        ? Icon(
                            Icons.check,
                            size: 12,
                            color: isBrutalist
                                ? Colors.black
                                : themeData.colorScheme.onPrimary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    completed ? 'Mark incomplete' : 'Mark complete',
                    style: subStyle.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: themeData.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Streaming Tags Row
          StreamBuilder<List<dynamic>>(
            stream: tagsProp.asList.stream,
            builder: (context, snapshot) {
              final list = snapshot.data ?? const [];
              if (list.isEmpty) return const SizedBox.shrink();

              return Column(
                children: [
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: list.map((tag) {
                      return Container(
                        decoration: BoxDecoration(
                          color: themeData.colorScheme.secondaryContainer
                              .withValues(alpha: 0.4),
                          borderRadius: isBrutalist
                              ? BorderRadius.zero
                              : BorderRadius.circular(4),
                          border: isBrutalist
                              ? Border.all(color: Colors.black, width: 1.0)
                              : null,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        child: Text(
                          "#$tag",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: themeData.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          // Footer due-date and lastModified rows
          if (dueDate != null || lastModified != null) ...[
            const SizedBox(height: 12),
            Divider(
              color: themeData.colorScheme.outline.withValues(alpha: 0.08),
              height: 1,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (dueDate != null && dueDate.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 10,
                        color: themeData.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Due: $dueDate",
                        style: TextStyle(
                          fontSize: 10,
                          color: themeData.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                if (lastModified != null && lastModified.isNotEmpty)
                  Text(
                    "Modified: $lastModified",
                    style: TextStyle(
                      fontSize: 10,
                      color: themeData.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
