import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

/// A set of vertical panels side-by-side. Tapping a panel expands its width smoothly, compressing the others.
class StreamingExpandingAccordionCarousel extends StatefulWidget {
  final PropertyStream props;

  const StreamingExpandingAccordionCarousel({super.key, required this.props});

  @override
  State<StreamingExpandingAccordionCarousel> createState() => _StreamingExpandingAccordionCarouselState();
}

class _StreamingExpandingAccordionCarouselState extends State<StreamingExpandingAccordionCarousel> {
  late Stream<Map<String, dynamic>> _accordionStream;
  int _expandedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initProps();
  }

  @override
  void didUpdateWidget(covariant StreamingExpandingAccordionCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initProps();
    }
  }

  void _initProps() {
    final mapStream = widget.props.asMap;
    _accordionStream = mapStream.stream;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _accordionStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};
          final rawItems = data["items"] as List<dynamic>? ?? const [];
          final items = rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList();

          if (items.isEmpty) return const SizedBox.shrink();

          return SizedBox(
            height: 240,
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final title = item["title"] as String? ?? "";
                final desc = item["description"] as String? ?? "";
                final colorHex = item["color"] as String?;
                final bg = _parseColor(colorHex) ?? theme.colorScheme.surfaceContainerHigh;

                final isExpanded = _expandedIndex == index;

                return Expanded(
                  flex: isExpanded ? 3 : 1,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: const Cubic(0.2, 0.8, 0.2, 1.0), // Standard Snap Curve
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isExpanded ? theme.colorScheme.primary.withOpacity(0.3) : theme.colorScheme.outline.withOpacity(0.06),
                          width: isExpanded ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded,
                                color: isExpanded ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.4),
                                size: 20,
                              ),
                              if (isExpanded) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (!isExpanded) ...[
                            const Spacer(),
                            RotatedBox(
                              quarterTurns: 3,
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Spacer(),
                          ] else ...[
                            const SizedBox(height: 12),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: Text(
                                  desc,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
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
