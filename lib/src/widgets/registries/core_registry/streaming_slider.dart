import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

/// A custom-designed slider control that reveals its elements procedurally as properties
/// are streamed and morphs visually to enable dragging once the action callback resolves.
class StreamingSlider extends StatefulWidget {
  final PropertyStream props;

  const StreamingSlider({super.key, required this.props});

  @override
  State<StreamingSlider> createState() => _StreamingSliderState();
}

class _StreamingSliderState extends State<StreamingSlider> {
  late Stream<Map<String, dynamic>> _sliderStream;
  late Future<String> _actionFuture;
  double? _currentValue;

  @override
  void initState() {
    super.initState();
    _initProps();
  }

  @override
  void didUpdateWidget(covariant StreamingSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initProps();
    }
  }

  void _initProps() {
    final mapStream = widget.props.asMap;
    _sliderStream = mapStream.stream;
    _actionFuture = mapStream.getStringProperty("action").future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _sliderStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final min = (data["min"] as num?)?.toDouble() ?? 0.0;
          final max = (data["max"] as num?)?.toDouble() ?? 100.0;
          final initialValue = (data["value"] as num?)?.toDouble() ?? min;

          _currentValue ??= initialValue;
          // Clamp value to ensure bounds
          final clampedValue = (_currentValue ?? initialValue).clamp(min, max);

          final labelProp = widget.props.asMap.getStringProperty("label");
          final labelStream = labelProp.stream;
          final labelFuture = labelProp.future;

          return FutureBuilder<String>(
            future: _actionFuture,
            builder: (context, actionSnapshot) {
              final action = actionSnapshot.data;
              final isEnabled = actionSnapshot.connectionState == ConnectionState.done && action != null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FutureBuilder<String>(
                    future: labelFuture,
                    builder: (context, labelSnapshot) {
                      final isDone = labelSnapshot.connectionState == ConnectionState.done && labelSnapshot.hasData;
                      final initial = isDone ? labelSnapshot.data! : '';

                      return AccumulatingStringStreamBuilder(
                        stream: labelStream,
                        initialValue: initial,
                        builder: (context, labelText) {
                          if (labelText.isEmpty) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  labelText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isEnabled
                                        ? theme.colorScheme.primaryContainer.withOpacity(0.4)
                                        : theme.colorScheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    clampedValue.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      color: isEnabled
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  Row(
                    children: [
                      Text(
                        min.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: theme.sliderTheme.copyWith(
                            activeTrackColor: isEnabled
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withOpacity(0.12),
                            inactiveTrackColor: theme.colorScheme.outline.withOpacity(0.06),
                            disabledActiveTrackColor: theme.colorScheme.outline.withOpacity(0.12),
                            disabledInactiveTrackColor: theme.colorScheme.outline.withOpacity(0.06),
                            thumbColor: isEnabled
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withOpacity(0.24),
                            disabledThumbColor: theme.colorScheme.outline.withOpacity(0.24),
                            trackHeight: 4,
                            thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: isEnabled ? 8 : 6,
                              disabledThumbRadius: 6,
                            ),
                            overlayColor: theme.colorScheme.primary.withOpacity(0.12),
                          ),
                          child: Slider(
                            min: min,
                            max: max,
                            value: clampedValue,
                            onChanged: isEnabled
                                ? (val) {
                                    setState(() {
                                      _currentValue = val;
                                    });
                                  }
                                : null,
                            onChangeEnd: isEnabled
                                ? (val) {
                                    debugPrint('[GEN_UI:SLIDER] Value changed to: $val -> $action');
                                  }
                                : null,
                          ),
                        ),
                      ),
                      Text(
                        max.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
