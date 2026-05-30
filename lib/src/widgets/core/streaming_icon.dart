import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';

/// Renders a dynamic material icon based on dynamic JSON streams.
class StreamingIcon extends StatelessWidget {
  final PropertyStream props;

  const StreamingIcon({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: props.asMap.stream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};
          final iconName = data["icon"] as String?;
          final size = (data["size"] as num?)?.toDouble() ?? 24.0;
          final colorHex = data["color"] as String?;

          if (iconName == null || iconName.isEmpty) {
            return const SizedBox.shrink(); // Empty parameter protection
          }

          final iconData = _mapIcon(iconName);
          final color =
              _parseColor(colorHex) ?? Theme.of(context).colorScheme.primary;

          return Icon(iconData, size: size, color: color);
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
