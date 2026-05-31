import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';

/// A multi-step progressive vertical accordion stepper that uses SizeTransition
/// to open the active step and collapse inactive steps fluidly.
class StreamingStepper extends StatefulWidget {
  final PropertyStream props;

  const StreamingStepper({super.key, required this.props});

  @override
  State<StreamingStepper> createState() => _StreamingStepperState();
}

class _StreamingStepperState extends State<StreamingStepper> {
  int _activeStepIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stepsProperty = widget.props.asMap.getListProperty("steps");
    final element =
        context.getElementForInheritedWidgetOfExactType<StreamingUiProvider>();
    final provider = element?.widget as StreamingUiProvider?;
    final isClosed = provider?.disableAnimations ?? false;

    if (isClosed) {
      final list = provider?.latestProperties?["steps"] as List<dynamic>? ??
          const [];

      if (list.isEmpty) {
        return const SizedBox.shrink();
      }

      return StreamingEntrance(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(list.length, (index) {
            final data = list[index] as Map<String, dynamic>? ?? const {};
            final stepProp = stepsProperty.getMapProperty('[$index]');
            final stepMapStream = stepProp.asMap;
            final childProp = stepMapStream.getMapProperty("content");

            final title = data["title"] as String? ?? "Step ${index + 1}";
            final description = data["description"] as String?;
            final isOpen = _activeStepIndex == index;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isOpen
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : theme.colorScheme.outline.withValues(alpha: 0.08),
                  width: isOpen ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clickable Accordion Header
                  ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: isOpen
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(
                              alpha: 0.12,
                            ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOpen
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: (description != null && description.isNotEmpty)
                        ? Text(
                            description,
                            style: const TextStyle(fontSize: 11),
                          )
                        : null,
                    trailing: Icon(
                      isOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      setState(() {
                        _activeStepIndex = index;
                      });
                    },
                  ),
                  // Fluid SizeTransition content pane
                  _FluidAccordionPane(
                    isOpen: isOpen,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StreamingWidget(props: childProp),
                          const SizedBox(height: 12),
                          // Next step button if there is a next step
                          if (index < list.length - 1)
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.tonal(
                                onPressed: () {
                                  setState(() {
                                    _activeStepIndex = index + 1;
                                  });
                                },
                                child: const Text(
                                  'Next Step',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      );
    }

    return StreamingEntrance(
      child: StreamBuilder<List<dynamic>>(
        stream: stepsProperty.stream,
        builder: (context, snapshot) {
          final list = snapshot.data ?? const [];

          if (list.isEmpty) {
            return const SizedBox.shrink(); // Empty parameter protection
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(list.length, (index) {
              final stepProp = stepsProperty.getMapProperty('[$index]');
              final stepMapStream = stepProp.asMap;

              return StreamBuilder<Map<String, dynamic>>(
                stream: stepMapStream.stream,
                builder: (context, stepSnapshot) {
                  final data = stepSnapshot.data ?? const {};
                  final title = data["title"] as String? ?? "Step ${index + 1}";
                  final description = data["description"] as String?;
                  final childProp = stepMapStream.getMapProperty("content");

                  final isOpen = _activeStepIndex == index;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isOpen
                            ? theme.colorScheme.primary.withValues(alpha: 0.3)
                            : theme.colorScheme.outline.withValues(alpha: 0.08),
                        width: isOpen ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Clickable Accordion Header
                        ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: isOpen
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(
                                    alpha: 0.12,
                                  ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isOpen
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle:
                              (description != null && description.isNotEmpty)
                                  ? Text(
                                      description,
                                      style: const TextStyle(fontSize: 11),
                                    )
                                  : null,
                          trailing: Icon(
                            isOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onTap: () {
                            setState(() {
                              _activeStepIndex = index;
                            });
                          },
                        ),
                        // Fluid SizeTransition content pane
                        _FluidAccordionPane(
                          isOpen: isOpen,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StreamingWidget(props: childProp),
                                const SizedBox(height: 12),
                                // Next step button if there is a next step
                                if (index < list.length - 1)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton.tonal(
                                      onPressed: () {
                                        setState(() {
                                          _activeStepIndex = index + 1;
                                        });
                                      },
                                      child: const Text(
                                        'Next Step',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
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
            }),
          );
        },
      ),
    );
  }
}

class _FluidAccordionPane extends StatefulWidget {
  final bool isOpen;
  final Widget child;

  const _FluidAccordionPane({required this.isOpen, required this.child});

  @override
  State<_FluidAccordionPane> createState() => _FluidAccordionPaneState();
}

class _FluidAccordionPaneState extends State<_FluidAccordionPane>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.isOpen) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _FluidAccordionPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
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
    return SizeTransition(
      sizeFactor: _animation,
      axisAlignment: -1.0,
      child: widget.child,
    );
  }
}
