import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';
import 'package:streaming_gen_ui/src/models/generative_ui_config.dart';

/// A premium stacked card carousel. Cards are stacked behind one another in 3D depth perspective.
/// Swiping moves the top card to the back of the stack.
class StreamingStackCarousel extends StatefulWidget {
  final PropertyStream props;

  const StreamingStackCarousel({super.key, required this.props});

  @override
  State<StreamingStackCarousel> createState() => _StreamingStackCarouselState();
}

class _StreamingStackCarouselState extends State<StreamingStackCarousel> {
  late Stream<Map<String, dynamic>> _carouselStream;
  int _topCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _initProps();
  }

  @override
  void didUpdateWidget(covariant StreamingStackCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initProps();
    }
  }

  void _initProps() {
    final mapStream = widget.props.asMap;
    _carouselStream = mapStream.stream;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _carouselStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final rawItems = data["items"] as List<dynamic>? ?? const [];
          final items = rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList();

          if (items.isEmpty) {
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
              ),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final total = items.length;
          final topIndex = _topCardIndex.clamp(0, total - 1);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 220,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      alignment: Alignment.center,
                      children: List.generate(total, (index) {
                        // Offset cards based on their relative index from the top card
                        final relativeIndex = (index - topIndex) % total;
                        final isBehind = relativeIndex > 0;

                        // Limit rendering depth to top 3 cards
                        if (relativeIndex >= 3) return const SizedBox.shrink();

                        final scale = 1.0 - (relativeIndex * 0.06);
                        final offset = relativeIndex * 14.0;
                        final opacity = (1.0 - (relativeIndex * 0.25)).clamp(0.0, 1.0);

                        final item = items[index];
                        final title = item["title"] as String? ?? "";
                        final desc = item["description"] as String? ?? "";
                        final colorHex = item["color"] as String?;
                        final exactColor = (item["exactColor"] as bool?) ?? (data["exactColor"] as bool?) ?? false;
                        final provider = StreamingUiProvider.maybeOf(context);
                        final rawCardColor = _parseColor(colorHex) ?? theme.colorScheme.surfaceContainerLow;
                        final cardColor = adjustColorForTheme(
                          context,
                          rawCardColor,
                          isBackground: true,
                          exactColor: exactColor,
                          config: provider?.config,
                        );

                        return AnimatedPositioned(
                          key: ValueKey(index),
                          duration: const Duration(milliseconds: 300),
                          curve: const Cubic(0.2, 0.8, 0.2, 1.0),
                          top: offset,
                          width: constraints.maxWidth - (isBehind ? 24.0 : 0.0),
                          height: 180,
                          child: Opacity(
                            opacity: opacity,
                            child: Transform.scale(
                              scale: scale,
                              child: GestureDetector(
                                onHorizontalDragEnd: (details) {
                                  if (details.primaryVelocity! < 0) {
                                    // Swipe left (next card)
                                    setState(() {
                                      _topCardIndex = (_topCardIndex + 1) % total;
                                    });
                                  } else if (details.primaryVelocity! > 0) {
                                    // Swipe right (prev card)
                                    setState(() {
                                      _topCardIndex = (_topCardIndex - 1 + total) % total;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: theme.colorScheme.outline.withOpacity(0.08),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(isBehind ? 0.02 : 0.08),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: Text(
                                          desc,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                                            height: 1.4,
                                          ),
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).reversed.toList(), // paint background cards first
                    );
                  },
                ),
              ),
              // Pagination Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(total, (index) {
                  final isActive = topIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
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
