import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

/// A horizontal bar of icon buttons that fade and scale in sequentially,
/// presenting quick actions with tactile feedback.
class StreamingIconButtonRow extends StatefulWidget {
  final PropertyStream props;

  const StreamingIconButtonRow({super.key, required this.props});

  @override
  State<StreamingIconButtonRow> createState() => _StreamingIconButtonRowState();
}

class _StreamingIconButtonRowState extends State<StreamingIconButtonRow> {
  late Stream<Map<String, dynamic>> _rowStream;

  @override
  void initState() {
    super.initState();
    _initProps();
  }

  @override
  void didUpdateWidget(covariant StreamingIconButtonRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initProps();
    }
  }

  void _initProps() {
    final mapStream = widget.props.asMap;
    _rowStream = mapStream.stream;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _rowStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};
          final rawButtons = data["buttons"] as List<dynamic>? ?? const [];
          final buttons = rawButtons
              .where((e) => e is Map)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          if (buttons.isEmpty) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.06),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(buttons.length, (index) {
                final btn = buttons[index];
                final iconName = btn["icon"] as String? ?? "help_outline";
                final action = btn["action"] as String? ?? "";
                final label = btn["label"] as String?;

                final iconData = _parseIcon(iconName);

                return Padding(
                  padding: EdgeInsets.only(right: index == buttons.length - 1 ? 0 : 8.0),
                  child: Tooltip(
                    message: label ?? action,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: action.isNotEmpty
                            ? () {
                                debugPrint('[GEN_UI:ICON_ROW] Tapped: "$action"');
                              }
                            : null,
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            iconData,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  IconData _parseIcon(String name) {
    switch (name.toLowerCase()) {
      case 'edit':
        return Icons.edit_rounded;
      case 'share':
        return Icons.share_rounded;
      case 'favorite':
      case 'like':
        return Icons.favorite_rounded;
      case 'delete':
      case 'trash':
        return Icons.delete_outline_rounded;
      case 'copy':
        return Icons.copy_all_rounded;
      case 'download':
        return Icons.download_rounded;
      case 'settings':
        return Icons.settings_rounded;
      case 'info':
        return Icons.info_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
