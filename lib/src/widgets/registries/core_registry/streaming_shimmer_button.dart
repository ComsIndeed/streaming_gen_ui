import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

/// A premium CTA button that has a sweeping shiny shimmer animation when active.
class StreamingShimmerButton extends StatefulWidget {
  final PropertyStream props;

  const StreamingShimmerButton({super.key, required this.props});

  @override
  State<StreamingShimmerButton> createState() => _StreamingShimmerButtonState();
}

class _StreamingShimmerButtonState extends State<StreamingShimmerButton> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapStream = widget.props.asMap;
    final actionFuture = mapStream.getStringProperty("action").future;
    final childProp = mapStream.getMapProperty("child");

    return StreamingEntrance(
      child: FutureBuilder<String>(
        future: actionFuture,
        builder: (context, snapshot) {
          final action = snapshot.data;
          final isEnabled = snapshot.connectionState == ConnectionState.done && action != null;

          return GestureDetector(
            onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
            onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
            onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
            onTap: isEnabled
                ? () {
                    debugPrint('[GEN_UI:SHIMMER_BUTTON] Action tapped -> $action');
                  }
                : null,
            child: AnimatedScale(
              scale: _isPressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOutCubic,
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: const Cubic(0.2, 0.8, 0.2, 1.0),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: isEnabled
                          ? LinearGradient(
                              colors: const [
                                Color(0xFF6366F1), // Indigo
                                Color(0xFFA855F7), // Purple
                                Color(0xFFEC4899), // Pink
                                Color(0xFF6366F1),
                              ],
                              stops: [
                                0.0,
                                _shimmerController.value * 0.5,
                                _shimmerController.value,
                                1.0,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isEnabled
                          ? null
                          : theme.colorScheme.surfaceContainerHigh.withOpacity(0.6),
                      border: Border.all(
                        color: isEnabled
                            ? Colors.transparent
                            : theme.colorScheme.outline.withOpacity(0.12),
                      ),
                      boxShadow: isEnabled
                          ? [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [],
                    ),
                    child: Theme(
                      data: theme.copyWith(
                        textTheme: theme.textTheme.copyWith(
                          bodyMedium: theme.textTheme.bodyMedium?.copyWith(
                            color: isEnabled
                                ? Colors.white
                                : theme.colorScheme.onSurface.withOpacity(0.4),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!isEnabled) ...[
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onSurface.withOpacity(0.3),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          StreamingWidget(props: childProp),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
