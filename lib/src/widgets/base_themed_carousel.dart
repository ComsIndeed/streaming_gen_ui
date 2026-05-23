import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';

/// A premium, shared media and widget slider supporting horizontal page-snapping
/// viewport slides and 3D layered stacking cards deck.
class BaseThemedCarousel extends StatefulWidget {
  final PropertyStream props;
  final String themeName;

  const BaseThemedCarousel({
    super.key,
    required this.props,
    required this.themeName,
  });

  @override
  State<BaseThemedCarousel> createState() => _BaseThemedCarouselState();
}

class _BaseThemedCarouselState extends State<BaseThemedCarousel> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapStream = widget.props.asMap;
    final itemsProperty = mapStream.getListProperty("items");

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: mapStream.stream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};
          final list = data["items"] as List<dynamic>? ?? const [];
          final carouselType = data["carouselType"] as String? ?? 'slide';

          if (list.isEmpty) {
            return const SizedBox.shrink(); // Empty parameter protection
          }

          if (carouselType == 'stack') {
            return _buildStackCarousel(context, list, itemsProperty);
          } else {
            return _buildSlideCarousel(context, list, itemsProperty);
          }
        },
      ),
    );
  }

  /// 1. Sliding Media Viewport Carousel (Edgemost items scaled and dimmed)
  Widget _buildSlideCarousel(
    BuildContext context,
    List<dynamic> list,
    ListPropertyStream<dynamic> itemsProperty,
  ) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 220,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: list.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final isCurrent = index == _currentIndex;
                final scale = isCurrent ? 1.0 : 0.92;
                final opacity = isCurrent ? 1.0 : 0.6;

                return AnimatedScale(
                  scale: scale,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: opacity,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: StreamingWidget(
                        props: itemsProperty.getMapProperty('[$index]'),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Page Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(list.length, (index) {
              final active = index == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                height: 6,
                width: active ? 16 : 6,
                decoration: BoxDecoration(
                  color: active
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 2. 3D Stack Cards Carousel
  Widget _buildStackCarousel(
    BuildContext context,
    List<dynamic> list,
    ListPropertyStream<dynamic> itemsProperty,
  ) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 240,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                // Swipe left -> next
                if (details.primaryVelocity! < 0) {
                  setState(() {
                    _currentIndex = (_currentIndex + 1) % list.length;
                  });
                }
                // Swipe right -> previous
                else if (details.primaryVelocity! > 0) {
                  setState(() {
                    _currentIndex = (_currentIndex - 1 + list.length) % list.length;
                  });
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: List.generate(list.length, (index) {
                  // Draw from back to front
                  // We only display up to 3 cards in stack at once
                  final relativeIdx = (index - _currentIndex) % list.length;
                  if (relativeIdx > 2) return const SizedBox.shrink();

                  final offsetMultiplier = relativeIdx;
                  final scaleMultiplier = 1.0 - (0.05 * relativeIdx);
                  final opacity = relativeIdx == 0 ? 1.0 : (relativeIdx == 1 ? 0.7 : 0.4);

                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    top: offsetMultiplier * 10.0,
                    child: AnimatedScale(
                      scale: scaleMultiplier,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: opacity,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.76,
                          child: IgnorePointer(
                            ignoring: relativeIdx != 0, // Click only the topmost card
                            child: StreamingWidget(
                              props: itemsProperty.getMapProperty('[$index]'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).reversed.toList(), // Reversed to draw topmost last
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(list.length, (index) {
              final active = index == _currentIndex;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                height: 6,
                width: 6,
                decoration: BoxDecoration(
                  color: active
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
