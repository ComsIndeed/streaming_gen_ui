import 'package:flutter/material.dart';

class SkeletonLoader extends StatelessWidget {
  final bool isActive;
  const SkeletonLoader({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(4, (index) {
        final widths = [0.85, 0.95, 0.70, 0.40];
        final w = widths[index % widths.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBlock(widthPercent: w, height: 16, isActive: isActive),
              const SizedBox(height: 6),
              SkeletonBlock(widthPercent: w * 0.8, height: 10, isActive: isActive),
            ],
          ),
        );
      }),
    );
  }
}

class SkeletonBlock extends StatefulWidget {
  final double widthPercent;
  final double height;
  final bool isActive;

  const SkeletonBlock({
    super.key,
    required this.widthPercent,
    required this.height,
    required this.isActive,
  });

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.isActive) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SkeletonBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _shimmerController.repeat();
      } else {
        _shimmerController.stop();
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widget.widthPercent,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          final gradient = LinearGradient(
            colors: const [
              Color(0xFFF1F5F9), // Light grey paper color
              Color(0xFFE2E8F0),
              Color(0xFFF1F5F9),
            ],
            stops: const [0.0, 0.5, 1.0],
            transform: SlidingGradientTransform(
              widget.isActive ? _shimmerController.value : 0.0,
            ),
          );

          return Container(
            height: widget.height,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 0.5),
            ),
          );
        },
      ),
    );
  }
}

class SlidingGradientTransform extends GradientTransform {
  final double value;
  const SlidingGradientTransform(this.value);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final double width = bounds.width;
    return Matrix4.translationValues(width * (value * 2 - 1.0), 0.0, 0.0);
  }
}
