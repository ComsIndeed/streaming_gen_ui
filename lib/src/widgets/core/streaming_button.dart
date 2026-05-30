import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';

/// A raw tactile button primitive that supports pressed scale feedback,
/// active color morphs, and progressively loads its child.
class StreamingButton extends StatefulWidget {
  final PropertyStream props;

  const StreamingButton({super.key, required this.props});

  @override
  State<StreamingButton> createState() => _StreamingButtonState();
}

class _StreamingButtonState extends State<StreamingButton> {
  bool _isPressed = false;

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
          final isEnabled =
              snapshot.connectionState == ConnectionState.done &&
              action != null &&
              action.isNotEmpty;

          return GestureDetector(
            onTapDown: isEnabled
                ? (_) => setState(() => _isPressed = true)
                : null,
            onTapUp: isEnabled
                ? (_) => setState(() => _isPressed = false)
                : null,
            onTapCancel: isEnabled
                ? () => setState(() => _isPressed = false)
                : null,
            onTap: isEnabled
                ? () {
                    debugPrint('[GEN_UI:ACTION] Button tapped -> $action');
                  }
                : null,
            child: AnimatedScale(
              scale: _isPressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: const Cubic(0.2, 0.8, 0.2, 1.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHigh.withValues(
                          alpha: 0.6,
                        ),
                  borderRadius: BorderRadius.circular(isEnabled ? 12 : 8),
                  border: Border.all(
                    color: isEnabled
                        ? Colors.transparent
                        : theme.colorScheme.outline.withValues(alpha: 0.12),
                  ),
                  boxShadow: isEnabled
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.16,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isEnabled) ...[
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Support standard or themed children
                    StreamingWidget(props: childProp),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
