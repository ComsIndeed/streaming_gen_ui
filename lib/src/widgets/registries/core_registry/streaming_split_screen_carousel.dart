import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

/// A premium split-viewport layout slider where the left side contains a swipable image,
/// and the right side displays corresponding text content.
class StreamingSplitScreenCarousel extends StatefulWidget {
  final PropertyStream props;

  const StreamingSplitScreenCarousel({super.key, required this.props});

  @override
  State<StreamingSplitScreenCarousel> createState() => _StreamingSplitScreenCarouselState();
}

class _StreamingSplitScreenCarouselState extends State<StreamingSplitScreenCarousel> {
  late Stream<Map<String, dynamic>> _splitStream;
  late PageController _pageController;
  int _activePageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initProps();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StreamingSplitScreenCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initProps();
    }
  }

  void _initProps() {
    final mapStream = widget.props.asMap;
    _splitStream = mapStream.stream;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _splitStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};
          final rawSlides = data["slides"] as List<dynamic>? ?? const [];
          final slides = rawSlides
              .where((e) => e is Map)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          if (slides.isEmpty) return const SizedBox.shrink();

          final slideCount = slides.length;
          final currentSlide = slides[_activePageIndex.clamp(0, slideCount - 1)];

          final imageUrl = currentSlide["image"] as String? ?? "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800";
          final title = currentSlide["title"] as String? ?? "";
          final desc = currentSlide["description"] as String? ?? "";

          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.08),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  // Left image half
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: theme.colorScheme.surfaceContainerHigh,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: slideCount,
                        onPageChanged: (index) {
                          setState(() {
                            _activePageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final img = slides[index]["image"] as String? ?? "";
                          return Image.network(
                            img.isNotEmpty ? img : imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                              alignment: Alignment.center,
                              child: Icon(Icons.image_not_supported_rounded, color: theme.colorScheme.primary, size: 24),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Right text half
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              title,
                              key: ValueKey('title_$_activePageIndex'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                desc,
                                key: ValueKey('desc_$_activePageIndex'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                                  height: 1.4,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          // Pager dots indicator row
                          Row(
                            children: List.generate(slideCount, (index) {
                              final isDotActive = _activePageIndex == index;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                                width: isDotActive ? 12 : 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isDotActive ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
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
