import 'dart:math';
import 'package:flutter/material.dart';

class TopBarVisualizer extends StatefulWidget {
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;

  const TopBarVisualizer({
    super.key,
    required this.isActive,
    this.activeColor = const Color(0xFF2563EB),
    this.inactiveColor = const Color(0xFF94A3B8),
  });

  @override
  State<TopBarVisualizer> createState() => _TopBarVisualizerState();
}

class _TopBarVisualizerState extends State<TopBarVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant TopBarVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(8, (index) {
            double factor = 0.35;
            if (widget.isActive) {
              // Smooth pulsing equalizer heights
              factor = 0.3 + 0.7 * (0.5 + 0.5 * sin(_controller.value * 2 * pi + index * 0.9)).clamp(0.0, 1.0);
            }
            return Container(
              width: 3.5,
              height: 14 * factor,
              margin: const EdgeInsets.symmetric(horizontal: 2.0),
              decoration: BoxDecoration(
                color: widget.isActive ? widget.activeColor : widget.inactiveColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }
}
