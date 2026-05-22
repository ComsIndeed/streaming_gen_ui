import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

class StreamingAgentStepper extends StatefulWidget {
  final PropertyStream props;

  const StreamingAgentStepper({super.key, required this.props});

  @override
  State<StreamingAgentStepper> createState() => _StreamingAgentStepperState();
}

class _StreamingAgentStepperState extends State<StreamingAgentStepper> {
  late ListPropertyStream<dynamic> _stepsProperty;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant StreamingAgentStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initStream();
    }
  }

  void _initStream() {
    _stepsProperty = widget.props.asMap.getListProperty("steps");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<List<dynamic>>(
        stream: _stepsProperty.stream,
        builder: (context, snapshot) {
          final list = snapshot.data ?? const [];
          if (list.isEmpty) return const SizedBox.shrink();

          return AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  // ignore: deprecated_member_use
                  color: theme.colorScheme.outline.withOpacity(0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(list.length, (index) {
                  final stepProps = _stepsProperty.getMapProperty('[$index]');

                  return _StepRow(
                    stepProps: stepProps,
                    isLast: index == list.length - 1,
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StepRow extends StatefulWidget {
  final PropertyStream stepProps;
  final bool isLast;

  const _StepRow({required this.stepProps, required this.isLast});

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow> {
  late Stream<Map<String, dynamic>> _stepStream;
  late Stream<String> _titleStream;
  late Future<String> _titleFuture;
  late Stream<String> _statusStream;
  late Future<String> _statusFuture;
  late Stream<String> _durationStream;
  late Future<String> _durationFuture;

  @override
  void initState() {
    super.initState();
    _initProps();
  }

  @override
  void didUpdateWidget(covariant _StepRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.stepProps, oldWidget.stepProps)) {
      _initProps();
    }
  }

  void _initProps() {
    final mapStream = widget.stepProps.asMap;
    _stepStream = mapStream.stream;

    final titleProp = mapStream.getStringProperty("title");
    _titleStream = titleProp.stream;
    _titleFuture = titleProp.future;

    final statusProp = mapStream.getStringProperty("status");
    _statusStream = statusProp.stream;
    _statusFuture = statusProp.future;

    final durProp = mapStream.getStringProperty("duration");
    _durationStream = durProp.stream;
    _durationFuture = durProp.future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<Map<String, dynamic>>(
      stream: _stepStream,
      builder: (context, snapshot) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left timeline indicator
              Column(
                children: [
                  FutureBuilder<String>(
                    future: _statusFuture,
                    builder: (context, statusSnap) {
                      final isDone =
                          statusSnap.connectionState == ConnectionState.done &&
                          statusSnap.hasData;
                      final initialStatus = isDone
                          ? statusSnap.data!
                          : 'pending';

                      return AccumulatingStringStreamBuilder(
                        stream: _statusStream,
                        initialValue: initialStatus,
                        builder: (context, statusVal) {
                          return _buildStatusIcon(statusVal, theme);
                        },
                      );
                    },
                  ),
                  if (!widget.isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: theme.colorScheme.outlineVariant.withOpacity(
                          0.4,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Title and details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FutureBuilder<String>(
                          future: _titleFuture,
                          builder: (context, titleSnap) {
                            final isDone =
                                titleSnap.connectionState ==
                                    ConnectionState.done &&
                                titleSnap.hasData;
                            final initialTitle = isDone ? titleSnap.data! : '';

                            return AccumulatingStringStreamBuilder(
                              stream: _titleStream,
                              initialValue: initialTitle,
                              builder: (context, titleVal) {
                                return Text(
                                  titleVal,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FutureBuilder<String>(
                        future: _durationFuture,
                        builder: (context, durSnap) {
                          final isDone =
                              durSnap.connectionState == ConnectionState.done &&
                              durSnap.hasData;
                          final initialDur = isDone ? durSnap.data! : '';

                          return AccumulatingStringStreamBuilder(
                            stream: _durationStream,
                            initialValue: initialDur,
                            builder: (context, durVal) {
                              if (durVal.isEmpty)
                                return const SizedBox.shrink();
                              return Text(
                                durVal,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  // ignore: deprecated_member_use
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.4),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(String status, ThemeData theme) {
    switch (status.trim().toLowerCase()) {
      case 'completed':
        return const Icon(
          Icons.check_circle_rounded,
          color: Colors.green,
          size: 20,
        );
      case 'running':
        return Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        );
      case 'failed':
        return const Icon(Icons.error_rounded, color: Colors.red, size: 20);
      case 'pending':
      default:
        return Icon(
          Icons.circle_outlined,
          color: theme.colorScheme.outlineVariant,
          size: 20,
        );
    }
  }
}
