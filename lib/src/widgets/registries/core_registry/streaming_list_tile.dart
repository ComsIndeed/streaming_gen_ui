import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';

class StreamingListTile extends StatelessWidget {
  final PropertyStream props;

  const StreamingListTile({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapStream = props.asMap;
    final tileStream = mapStream.stream;

    final titleProp = mapStream.getStringProperty("title");
    final titleStream = titleProp.stream;
    final titleFuture = titleProp.future;

    final subtitleProp = mapStream.getStringProperty("subtitle");
    final subtitleStream = subtitleProp.stream;
    final subtitleFuture = subtitleProp.future;

    final trailingProperty = mapStream.getMapProperty("trailing");

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: tileStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final iconName = data["iconName"] as String?;
          final iconColorHex = data["iconColor"] as String?;
          final iconColor = _parseColor(iconColorHex) ?? theme.colorScheme.primary;
          final iconData = _resolveIcon(iconName);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                // ignore: deprecated_member_use
                color: theme.colorScheme.outline.withOpacity(0.04),
              ),
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  // Icon block
                  if (iconData != null) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconData,
                        color: iconColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FutureBuilder<String>(
                          future: titleFuture,
                          builder: (context, titleSnap) {
                            final isDone = titleSnap.connectionState == ConnectionState.done && titleSnap.hasData;
                            final initialTitle = isDone ? titleSnap.data! : '';

                            return AccumulatingStringStreamBuilder(
                              stream: titleStream,
                              initialValue: initialTitle,
                              builder: (context, titleText) {
                                return Text(
                                  titleText,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: -0.2,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        FutureBuilder<String>(
                          future: subtitleFuture,
                          builder: (context, subSnap) {
                            final isDone = subSnap.connectionState == ConnectionState.done && subSnap.hasData;
                            final initialSub = isDone ? subSnap.data! : '';

                            return AccumulatingStringStreamBuilder(
                              stream: subtitleStream,
                              initialValue: initialSub,
                              builder: (context, subText) {
                                if (subText.isEmpty) return const SizedBox.shrink();

                                return Text(
                                  subText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    // ignore: deprecated_member_use
                                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Trailing widget
                  FutureBuilder<String>(
                    future: trailingProperty.asMap.getStringProperty("namespace").future,
                    builder: (context, trailingSnap) {
                      if (trailingSnap.connectionState == ConnectionState.done &&
                          trailingSnap.hasData &&
                          trailingSnap.data!.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: StreamingWidget(props: trailingProperty),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

IconData? _resolveIcon(String? name) {
  if (name == null) return null;
  switch (name.toLowerCase()) {
    case 'account_circle': return Icons.account_circle_rounded;
    case 'person': return Icons.person_rounded;
    case 'settings': return Icons.settings_rounded;
    case 'star': return Icons.star_rounded;
    case 'home': return Icons.home_rounded;
    case 'info': return Icons.info_rounded;
    case 'warning': return Icons.warning_rounded;
    case 'error': return Icons.error_rounded;
    case 'check': return Icons.check_circle_rounded;
    case 'search': return Icons.search_rounded;
    case 'play': return Icons.play_arrow_rounded;
    case 'notifications': return Icons.notifications_rounded;
    case 'mail': return Icons.mail_rounded;
    case 'phone': return Icons.phone_rounded;
    case 'cloud': return Icons.cloud_rounded;
    case 'download': return Icons.download_rounded;
    case 'upload': return Icons.upload_rounded;
    case 'bolt': return Icons.bolt_rounded;
    case 'lock': return Icons.lock_rounded;
  }
  return Icons.widgets_rounded; // Fallback default icon
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
