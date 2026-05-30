import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';

/// An interactive, tactile icon button with full pressed feedback,
/// supporting custom icons, sizes, and colors.
class StreamingIconButton extends StatefulWidget {
  final PropertyStream props;

  const StreamingIconButton({super.key, required this.props});

  @override
  State<StreamingIconButton> createState() => _StreamingIconButtonState();
}

class _StreamingIconButtonState extends State<StreamingIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapStream = widget.props.asMap;
    final actionFuture = mapStream.getStringProperty("action").future;

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: mapStream.stream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};
          final iconName = data["icon"] as String?;
          final iconSize = (data["size"] as num?)?.toDouble() ?? 20.0;
          final colorHex = data["color"] as String?;
          final bgHex = data["backgroundColor"] as String?;

          if (iconName == null || iconName.isEmpty) {
            return const SizedBox.shrink(); // Empty parameter protection
          }

          final iconData = _mapIcon(iconName);
          final color = _parseColor(colorHex) ?? theme.colorScheme.primary;
          final bgColor =
              _parseColor(bgHex) ??
              theme.colorScheme.primaryContainer.withValues(alpha: 0.2);

          return FutureBuilder<String>(
            future: actionFuture,
            builder: (context, actionSnapshot) {
              final action = actionSnapshot.data;
              final isEnabled =
                  actionSnapshot.connectionState == ConnectionState.done &&
                  action != null &&
                  action.isNotEmpty;

              return GestureDetector(
                onTapDown: isEnabled
                    ? (_) => setState(() => _isPressed = true)
                    : null,
                onTapUp: isEnabled
                    ? (_) => setState(() => _isPressed = false)
                    : null,
                onTapCancel: isEnabled
                    ? () => setState(() => _isPressed = false)
                    : null,
                onTap: isEnabled
                    ? () {
                        debugPrint(
                          '[GEN_UI:ACTION] IconButton tapped -> $action',
                        );
                      }
                    : null,
                child: AnimatedScale(
                  scale: _isPressed ? 0.97 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOutCubic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? bgColor
                          : theme.colorScheme.surfaceContainerHigh.withValues(
                              alpha: 0.4,
                            ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(
                          alpha: 0.08,
                        ),
                      ),
                    ),
                    child: Icon(
                      iconData,
                      size: iconSize,
                      color: isEnabled
                          ? color
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _mapIcon(String name) {
    final clean = name.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    switch (clean) {
      case 'check':
      case 'done':
      case 'success':
        return Icons.check_circle_outline;
      case 'close':
      case 'cancel':
      case 'error':
      case 'fail':
        return Icons.cancel_outlined;
      case 'settings':
      case 'gear':
        return Icons.settings_outlined;
      case 'person':
      case 'user':
      case 'profile':
        return Icons.person_outline;
      case 'star':
      case 'favorite':
        return Icons.star_outline;
      case 'info':
      case 'about':
        return Icons.info_outline;
      case 'warning':
      case 'alert':
        return Icons.warning_amber_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'search':
        return Icons.search;
      case 'menu':
        return Icons.menu;
      case 'arrowback':
      case 'back':
        return Icons.arrow_back_ios_new;
      case 'arrowforward':
      case 'next':
        return Icons.arrow_forward_ios;
      case 'play':
        return Icons.play_arrow_outlined;
      case 'pause':
        return Icons.pause_circle_outline;
      case 'image':
      case 'photo':
      case 'media':
        return Icons.image_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color? _parseColor(String? hexString) {
    if (hexString == null) return null;
    var hex = hexString.replaceAll('#', '');
    if (hex.length == 3) {
      hex = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
    }
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length == 8) {
      final val = int.tryParse(hex, radix: 16);
      if (val != null) return Color(val);
    }
    return null;
  }
}
