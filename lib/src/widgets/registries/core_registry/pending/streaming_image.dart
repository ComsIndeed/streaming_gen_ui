import 'dart:io';
import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

class StreamingImage extends StatefulWidget {
  final PropertyStream props;

  const StreamingImage({super.key, required this.props});

  @override
  State<StreamingImage> createState() => _StreamingImageState();
}

class _StreamingImageState extends State<StreamingImage> {
  int _activeSlideIndex = 0;

  // Premium glassmorphic gradient assets generated locally
  final List<String> _placeholderPaths = const [
    'C:/Users/Truly/.gemini/antigravity/brain/7e3c74ce-b42c-4084-a120-404a0b6ec9d1/gradient_blue_purple_1779345364333.png',
    'C:/Users/Truly/.gemini/antigravity/brain/7e3c74ce-b42c-4084-a120-404a0b6ec9d1/gradient_rose_amber_1779345382154.png',
    'C:/Users/Truly/.gemini/antigravity/brain/7e3c74ce-b42c-4084-a120-404a0b6ec9d1/gradient_teal_emerald_1779345399455.png',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapStream = widget.props.asMap;
    final imageStream = mapStream.stream;

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: imageStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final url = data["url"] as String?;
          final urlsListRaw = data["urls"];
          final fitStr = data["fit"] as String? ?? "cover";
          final borderRadius =
              (data["borderRadius"] as num?)?.toDouble() ?? 16.0;
          final width = (data["width"] as num?)?.toDouble();
          final height = (data["height"] as num?)?.toDouble() ?? 200.0;

          final fit = _parseBoxFit(fitStr);

          // Convert raw urls list if present
          List<String> urlsList = [];
          if (urlsListRaw is List) {
            urlsList = urlsListRaw.map((e) => e.toString()).toList();
          }

          final isCarousel =
              urlsList.length > 1 || (url == null && urlsList.isEmpty);
          final slideCount = urlsList.isNotEmpty
              ? urlsList.length
              : _placeholderPaths.length;

          return Container(
            width: width ?? double.infinity,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Stack(
                children: [
                  // 1. Image Viewport (Single or Swipable Carousel)
                  Positioned.fill(
                    child: !isCarousel
                        ? _buildImage(url!, fit)
                        : PageView.builder(
                            itemCount: slideCount,
                            onPageChanged: (index) {
                              setState(() {
                                _activeSlideIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              if (urlsList.isNotEmpty) {
                                return _buildImage(urlsList[index], fit);
                              } else {
                                // Load beautiful generated local gradient mockup
                                final file = File(_placeholderPaths[index]);
                                if (file.existsSync()) {
                                  return Image.file(file, fit: fit);
                                } else {
                                  // Fallback safe solid gradient in case of file absence
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.primaryContainer,
                                          theme.colorScheme.secondaryContainer,
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                  ),

                  // 2. Premium Sliding Indicator Dots (Only for Carousel)
                  if (isCarousel)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(slideCount, (index) {
                          final isActive = _activeSlideIndex == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            width: isActive ? 20.0 : 8.0,
                            height: 8.0,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        }),
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

  Widget _buildImage(String path, BoxFit fit) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: Theme.of(context).colorScheme.errorContainer,
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      );
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: fit);
      }
      return const SizedBox.shrink();
    }
  }

  BoxFit _parseBoxFit(String fit) {
    switch (fit) {
      case 'cover':
        return BoxFit.cover;
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      case 'scaleDown':
        return BoxFit.scaleDown;
      default:
        return BoxFit.cover;
    }
  }
}
