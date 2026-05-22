import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

/// A premium, built-in product showcase card designed to support morphing layouts,
/// shimmer-to-fade image loads, and dynamic call-to-action buttons.
class StreamingProductCard extends StatefulWidget {
  final PropertyStream props;

  const StreamingProductCard({super.key, required this.props});

  @override
  State<StreamingProductCard> createState() => _StreamingProductCardState();
}

class _StreamingProductCardState extends State<StreamingProductCard> {
  late Stream<Map<String, dynamic>> _productStream;

  @override
  void initState() {
    super.initState();
    _productStream = widget.props.asMap.stream;
  }

  @override
  void didUpdateWidget(covariant StreamingProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      setState(() {
        _productStream = widget.props.asMap.stream;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _productStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final title = data["title"] as String? ?? "";
          final description = data["description"] as String? ?? "";
          final price = data["price"] as String? ?? "";
          final imageUrl = data["imageUrl"] as String? ?? "";
          final ratingVal = data["rating"];
          final rating = ratingVal is num ? ratingVal.toDouble() : 0.0;
          final action = data["action"] as String? ?? "view_product";

          final isImageAvailable =
              imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.isAbsolute == true;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Image (Shimmer-to-Fade-In Media Frame)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Base Skeleton / Shimmer Background
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.surfaceContainerLowest,
                                  theme.colorScheme.surfaceContainerHighest,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: Colors.white24,
                                size: 28,
                              ),
                            ),
                          ),
                          // Cross-Fading Network Image
                          if (isImageAvailable)
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const SizedBox.shrink(); // Show skeleton
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.redAccent,
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Rating row (progressive display)
                  if (rating > 0) ...[
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            final double starValue = index + 1.0;
                            if (rating >= starValue) {
                              return const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF59E0B),
                                size: 16,
                              );
                            } else if (rating >= starValue - 0.5) {
                              return const Icon(
                                Icons.star_half_rounded,
                                color: Color(0xFFF59E0B),
                                size: 16,
                              );
                            } else {
                              return const Icon(
                                Icons.star_outline_rounded,
                                color: Colors.white10,
                                size: 16,
                              );
                            }
                          }),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Title (Evolving string)
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // Description (Evolving string)
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.7,
                        ),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Price & CTA Button (Disabled-to-Active Transmutation)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (price.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "PRICE",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.3,
                                ),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              price,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF10B981), // Emerald Green
                              ),
                            ),
                          ],
                        )
                      else
                        const SizedBox.shrink(),

                      // Action Button
                      _buildActionButton(
                        context: context,
                        isReady: title.isNotEmpty && price.isNotEmpty,
                        actionKey: action,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required bool isReady,
    required String actionKey,
  }) {
    final theme = Theme.of(context);

    // Animating the button properties based on state resolution (Transmutation)
    final bgColor = isReady
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);
    final textColor = isReady
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface.withOpacity(0.3);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isReady
              ? () {
                  // Custom event trigger
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      content: Text(
                        "Triggered action: $actionKey",
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isReady) ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    isReady ? "View Item" : "Loading Details",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
