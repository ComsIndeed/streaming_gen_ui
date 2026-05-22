import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

/// A premium animated voice audio visualizer waveform card.
class StreamingVoiceVisualizer extends StatefulWidget {
  final PropertyStream props;

  const StreamingVoiceVisualizer({super.key, required this.props});

  @override
  State<StreamingVoiceVisualizer> createState() =>
      _StreamingVoiceVisualizerState();
}

class _StreamingVoiceVisualizerState extends State<StreamingVoiceVisualizer>
    with SingleTickerProviderStateMixin {
  late Stream<Map<String, dynamic>> _visualizerStream;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _initProps();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StreamingVoiceVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initProps();
    }
  }

  void _initProps() {
    final mapStream = widget.props.asMap;
    _visualizerStream = mapStream.stream;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _visualizerStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};
          final isActive = data["active"] as bool? ?? true;

          final labelProp = widget.props.asMap.getStringProperty("label");
          final labelStream = labelProp.stream;
          final labelFuture = labelProp.future;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: FutureBuilder<String>(
                    future: labelFuture,
                    builder: (context, labelSnapshot) {
                      final isDone =
                          labelSnapshot.connectionState ==
                              ConnectionState.done &&
                          labelSnapshot.hasData;
                      final initial = isDone ? labelSnapshot.data! : '';

                      return AccumulatingStringStreamBuilder(
                        stream: labelStream,
                        initialValue: initial,
                        builder: (context, labelText) {
                          final statusText = labelText.isEmpty
                              ? "Listening for voice input..."
                              : labelText;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "VOICE TRANSCRIBER",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Premium pulsing waveform lines
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(6, (index) {
                        final waveVal = _waveController.value;
                        final factor = (index - 2.5).abs();
                        final pulseHeight = isActive
                            ? (12 +
                                  20 *
                                      (0.5 + 0.5 * waveVal) *
                                      (1 - factor * 0.15))
                            : 4.0;

                        return Container(
                          width: 3.5,
                          height: pulseHeight,
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          decoration: BoxDecoration(
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withOpacity(0.24),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
