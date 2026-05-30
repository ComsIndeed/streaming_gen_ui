import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';

/// A premium, theme-aware streaming image loader that handles placeholders,
/// fading transitions, and custom theme ornaments.
class BaseStreamingImage extends StatefulWidget {
  final PropertyStream props;
  final String propertyName;
  final String themeName;
  final double borderRadius;
  final double? aspectRatio;
  final BoxFit fit;

  const BaseStreamingImage({
    super.key,
    required this.props,
    this.propertyName = 'imageUrl',
    required this.themeName,
    this.borderRadius = 8.0,
    this.aspectRatio,
    this.fit = BoxFit.cover,
  });

  @override
  State<BaseStreamingImage> createState() => _BaseStreamingImageState();
}

class _BaseStreamingImageState extends State<BaseStreamingImage>
    with SingleTickerProviderStateMixin {
  bool _loaded = false;
  late Future<String> _urlFuture;

  @override
  void initState() {
    super.initState();
    _initFuture();
  }

  @override
  void didUpdateWidget(covariant BaseStreamingImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props) ||
        widget.propertyName != oldWidget.propertyName) {
      _loaded = false;
      _initFuture();
    }
  }

  void _initFuture() {
    _urlFuture = widget.props.asMap.getStringProperty(widget.propertyName).future;
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    // Theme-specific placeholder
    Widget placeholder;
    switch (widget.themeName) {
      case 'apple':
        // Multicolored acrylic gradient
        placeholder = Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC), Color(0xFFFFD1FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
        break;
      case 'fluent':
        // Windows Fluent solid color gradient (Microsoft branding blue-gray tones)
        placeholder = Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0078D4), Color(0xFF106EBE), Color(0xFF005A9E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
        break;
      case 'glassmorphic':
        placeholder = Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.white,
              ),
            ),
          ),
        );
        break;
      case 'neumorphic':
        placeholder = Container(
          color: themeData.brightness == Brightness.dark
              ? Colors.grey.shade900
              : Colors.grey.shade100,
          child: Center(
            child: Icon(
              Icons.image_outlined,
              color: Colors.grey.shade400,
              size: 24,
            ),
          ),
        );
        break;
      case 'skeumorphic':
        placeholder = Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey.shade200, Colors.grey.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(Icons.collections, color: Colors.grey, size: 24),
          ),
        );
        break;
      case 'brutalist':
        placeholder = Container(
          color: const Color(0xFFFFFF00), // Stark brutalist yellow
          child: const Center(
            child: Icon(
              Icons.image_search_outlined,
              color: Colors.black,
              size: 24,
            ),
          ),
        );
        break;
      case 'material':
      default:
        placeholder = const _ShimmerPlaceholder();
        break;
    }

    return FutureBuilder<String>(
      future: _urlFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          Widget composite = placeholder;
          if (widget.borderRadius > 0) {
            composite = ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: composite,
            );
          }
          if (widget.aspectRatio != null) {
            return AspectRatio(aspectRatio: widget.aspectRatio!, child: composite);
          }
          return composite;
        }

        final imageUrl = snapshot.data!;

        Widget imageWidget = Image.network(
          imageUrl,
          fit: widget.fit,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_loaded) {
                  setState(() {
                    _loaded = true;
                  });
                }
              });
              return child;
            }
            return const SizedBox.shrink();
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.withValues(alpha: 0.1),
            child: const Center(
              child: Icon(Icons.error_outline, size: 20, color: Colors.red),
            ),
          ),
        );

        Widget composite = Stack(
          children: [
            Positioned.fill(child: placeholder),
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _loaded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                child: imageWidget,
              ),
            ),
          ],
        );

        if (widget.borderRadius > 0) {
          composite = ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: composite,
          );
        }

        if (widget.aspectRatio != null) {
          return AspectRatio(aspectRatio: widget.aspectRatio!, child: composite);
        }

        return composite;
      },
    );
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  const _ShimmerPlaceholder();

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: _SlidingGradientTransform(_controller.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent - 0.5) * 2,
      0.0,
      0.0,
    );
  }
}
