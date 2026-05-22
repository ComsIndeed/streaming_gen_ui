import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

/// A custom horizontal progress roadmap tracking steps or timeline milestones.
class StreamingTimelineStepper extends StatefulWidget {
  final PropertyStream props;

  const StreamingTimelineStepper({super.key, required this.props});

  @override
  State<StreamingTimelineStepper> createState() => _StreamingTimelineStepperState();
}

class _StreamingTimelineStepperState extends State<StreamingTimelineStepper> {
  late Stream<Map<String, dynamic>> _stepperStream;

  @override
  void initState() {
    super.initState();
    _initProps();
  }

  @override
  void didUpdateWidget(covariant StreamingTimelineStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initProps();
    }
  }

  void _initProps() {
    final mapStream = widget.props.asMap;
    _stepperStream = mapStream.stream;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _stepperStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};
          final rawSteps = data["steps"] as List<dynamic>? ?? const [];
          final steps = rawSteps
              .where((e) => e is Map)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          if (steps.isEmpty) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.06),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(steps.length, (index) {
                  final step = steps[index];
                  final label = step["label"] as String? ?? "";
                  final status = step["status"] as String? ?? "pending"; // complete, active, pending

                  final isLast = index == steps.length - 1;

                  Color dotColor;
                  Widget icon;

                  switch (status) {
                    case 'complete':
                      dotColor = const Color(0xFF10B981); // Emerald
                      icon = const Icon(Icons.check_rounded, size: 10, color: Colors.white);
                      break;
                    case 'active':
                      dotColor = theme.colorScheme.primary;
                      icon = Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      );
                      break;
                    case 'pending':
                    default:
                      dotColor = theme.colorScheme.outline.withOpacity(0.2);
                      icon = const SizedBox.shrink();
                      break;
                  }

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                              boxShadow: status == 'active'
                                  ? [
                                      BoxShadow(
                                        color: theme.colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                            ),
                            alignment: Alignment.center,
                            child: icon,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: status == 'active' ? FontWeight.w700 : FontWeight.w500,
                              color: status == 'pending'
                                  ? theme.colorScheme.onSurfaceVariant.withOpacity(0.4)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      if (!isLast) ...[
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 40,
                          height: 2.5,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: status == 'complete'
                                ? const Color(0xFF10B981)
                                : theme.colorScheme.outline.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
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
