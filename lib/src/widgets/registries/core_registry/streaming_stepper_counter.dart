import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

/// A custom capsule-styled numeric quantifier selector containing minus and plus buttons.
class StreamingStepperCounter extends StatefulWidget {
  final PropertyStream props;

  const StreamingStepperCounter({super.key, required this.props});

  @override
  State<StreamingStepperCounter> createState() => _StreamingStepperCounterState();
}

class _StreamingStepperCounterState extends State<StreamingStepperCounter> {
  late Stream<Map<String, dynamic>> _stepperStream;
  late Future<String> _actionFuture;
  int? _localValue;

  @override
  void initState() {
    super.initState();
    _initProps();
  }

  @override
  void didUpdateWidget(covariant StreamingStepperCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initProps();
    }
  }

  void _initProps() {
    final mapStream = widget.props.asMap;
    _stepperStream = mapStream.stream;
    _actionFuture = mapStream.getStringProperty("action").future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _stepperStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final min = (data["min"] as num?)?.toInt() ?? 0;
          final max = (data["max"] as num?)?.toInt() ?? 99;
          final initialValue = (data["value"] as num?)?.toInt() ?? min;

          final currentValue = (_localValue ?? initialValue).clamp(min, max);

          final labelProp = widget.props.asMap.getStringProperty("label");
          final labelStream = labelProp.stream;
          final labelFuture = labelProp.future;

          return FutureBuilder<String>(
            future: _actionFuture,
            builder: (context, actionSnapshot) {
              final action = actionSnapshot.data;
              final isEnabled = actionSnapshot.connectionState == ConnectionState.done && action != null;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.06),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: FutureBuilder<String>(
                        future: labelFuture,
                        builder: (context, labelSnapshot) {
                          final isDone = labelSnapshot.connectionState == ConnectionState.done && labelSnapshot.hasData;
                          final initial = isDone ? labelSnapshot.data! : '';

                          return AccumulatingStringStreamBuilder(
                            stream: labelStream,
                            initialValue: initial,
                            builder: (context, labelText) {
                              if (labelText.isEmpty) return const SizedBox.shrink();

                              return Text(
                                labelText,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Minus button
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.remove_rounded,
                              size: 16,
                              color: isEnabled && currentValue > min
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withOpacity(0.2),
                            ),
                            onPressed: isEnabled && currentValue > min
                                ? () {
                                    setState(() {
                                      _localValue = currentValue - 1;
                                    });
                                    debugPrint('[GEN_UI:STEPPER] Value decremented to: ${currentValue - 1} -> $action');
                                  }
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 150),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: theme.colorScheme.onSurface,
                              ),
                              child: Text('$currentValue'),
                            ),
                          ),
                          // Plus button
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: isEnabled && currentValue < max
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withOpacity(0.2),
                            ),
                            onPressed: isEnabled && currentValue < max
                                ? () {
                                    setState(() {
                                      _localValue = currentValue + 1;
                                    });
                                    debugPrint('[GEN_UI:STEPPER] Value incremented to: ${currentValue + 1} -> $action');
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
