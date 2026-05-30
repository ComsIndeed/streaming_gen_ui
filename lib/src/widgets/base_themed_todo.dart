import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/theme_style_helper.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';
import 'package:streaming_gen_ui/src/widgets/core/themed_streaming_text.dart';

/// A premium themed Todo & Checklists card supporting M3, Fluent, Apple,
/// Glassmorphic, Neumorphic, Skeuomorphic, and Neo-Brutalist design systems.
class BaseThemedTodoCard extends StatefulWidget {
  final PropertyStream props;
  final String themeName;

  const BaseThemedTodoCard({
    super.key,
    required this.props,
    required this.themeName,
  });

  @override
  State<BaseThemedTodoCard> createState() => _BaseThemedTodoCardState();
}

class _BaseThemedTodoCardState extends State<BaseThemedTodoCard> {
  bool _isPressed = false;
  // Local completion state overrides
  final Map<int, bool> _localCompleted = {};

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

          final title = data["title"] as String? ?? 'Pending Tasks';
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
                  '[GEN_UI:TODO_LIST_ACTION] Todo Card clicked -> $action',
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

    // Get color based on priority
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ThemedStreamingText(
                title,
                themeName: widget.themeName,
                style: titleStyle.copyWith(fontSize: 16),
              ),
              const Icon(Icons.playlist_add_check, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          // Streaming checklists
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

              return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index] as Map<String, dynamic>? ?? const {};
                  final text = item["text"] as String? ?? '';
                  final rawCompleted = item["completed"] as bool? ?? false;
                  final dueDate = item["dueDate"] as String?;
                  final priority = item["priority"] as String?;

                  final completed = _localCompleted[index] ?? rawCompleted;
                  final priorityColor = getPriorityColor(priority);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _localCompleted[index] = !completed;
                      });
                      debugPrint(
                        '[GEN_UI:TODO_TOGGLE] Task index $index toggled -> ${!completed}',
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          // Task Checkbox Box
                          Container(
                            width: 22,
                            height: 22,
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
                                    size: 14,
                                    color: isBrutalist
                                        ? Colors.black
                                        : themeData.colorScheme.onPrimary,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ThemedStreamingText(
                                  text,
                                  themeName: widget.themeName,
                                  style: subStyle.copyWith(
                                    fontSize: 13,
                                    decoration: completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: completed
                                        ? themeData.colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.5)
                                        : themeData.colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (dueDate != null && dueDate.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    "Due: $dueDate",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: themeData
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Priority Tag Dot
                          if (priority != null && priority.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.15),
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
                                priority.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: isBrutalist
                                      ? Colors.black
                                      : priorityColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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
