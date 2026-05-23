import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';

/// A flat text button or hyperlink with tactile pressed feedback,
/// supporting progressive text streams and dynamic action triggers.
class StreamingTextButton extends StatefulWidget {
  final PropertyStream props;

  const StreamingTextButton({super.key, required this.props});

  @override
  State<StreamingTextButton> createState() => _StreamingTextButtonState();
}

class _StreamingTextButtonState extends State<StreamingTextButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapStream = widget.props.asMap;
    final actionFuture = mapStream.getStringProperty("action").future;
    final textProp = mapStream.getStringProperty("text");

    return StreamingEntrance(
      child: FutureBuilder<String>(
        future: actionFuture,
        builder: (context, actionSnapshot) {
          final action = actionSnapshot.data;
          final isEnabled =
              actionSnapshot.connectionState == ConnectionState.done &&
              action != null &&
              action.isNotEmpty;

          return FutureBuilder<String>(
            future: textProp.future,
            builder: (context, textSnapshot) {
              final isDone = textSnapshot.connectionState == ConnectionState.done && textSnapshot.hasData;
              final initial = isDone ? textSnapshot.data! : '';

              return AccumulatingStringStreamBuilder(
                stream: textProp.stream,
                initialValue: initial,
                builder: (context, textVal) {
                  if (textVal.isEmpty) return const SizedBox.shrink(); // Empty parameter protection

                  return GestureDetector(
                    onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
                    onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
                    onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
                    onTap: isEnabled
                        ? () {
                            debugPrint('[GEN_UI:ACTION] TextButton tapped -> $action');
                          }
                        : null,
                    child: AnimatedScale(
                      scale: _isPressed ? 0.97 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOutCubic,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          textVal,
                          style: TextStyle(
                            color: isEnabled
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
