import 'dart:async';
import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

/// A confirmation hold-to-confirm action button designed for highly sensitive operations.
class StreamingDestructiveActionButton extends StatefulWidget {
  final PropertyStream props;

  const StreamingDestructiveActionButton({super.key, required this.props});

  @override
  State<StreamingDestructiveActionButton> createState() => _StreamingDestructiveActionButtonState();
}

class _StreamingDestructiveActionButtonState extends State<StreamingDestructiveActionButton> with SingleTickerProviderStateMixin {
  late Stream<Map<String, dynamic>> _btnStream;
  late Future<String> _actionFuture;
  late AnimationController _progressController;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _initProps();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerAction();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StreamingDestructiveActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initProps();
    }
  }

  void _initProps() {
    final mapStream = widget.props.asMap;
    _btnStream = mapStream.stream;
    _actionFuture = mapStream.getStringProperty("action").future;
  }

  void _startHolding() {
    setState(() {
      _isHolding = true;
    });
    _progressController.forward();
  }

  void _stopHolding() {
    if (_progressController.status != AnimationStatus.completed) {
      setState(() {
        _isHolding = false;
      });
      _progressController.reverse();
    }
  }

  void _triggerAction() async {
    final action = await _actionFuture;
    debugPrint('[GEN_UI:DESTRUCTIVE_BUTTON] Hold completed! Triggered -> $action');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Action '$action' executed successfully!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        _isHolding = false;
      });
      _progressController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _btnStream,
        builder: (context, snapshot) {
          final labelProp = widget.props.asMap.getStringProperty("label");
          final labelStream = labelProp.stream;
          final labelFuture = labelProp.future;

          return FutureBuilder<String>(
            future: _actionFuture,
            builder: (context, actionSnapshot) {
              final action = actionSnapshot.data;
              final isEnabled = actionSnapshot.connectionState == ConnectionState.done && action != null;

              return GestureDetector(
                onTapDown: isEnabled ? (_) => _startHolding() : null,
                onTapUp: isEnabled ? (_) => _stopHolding() : null,
                onTapCancel: isEnabled ? () => _stopHolding() : null,
                child: AnimatedScale(
                  scale: _isHolding ? 0.96 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? const Color(0xFFFEF2F2)
                          : theme.colorScheme.surfaceContainerHigh.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isEnabled
                            ? const Color(0xFFFCA5A5)
                            : theme.colorScheme.outline.withOpacity(0.08),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Holding sweep progress bar
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                return FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _progressController.value,
                                  child: Container(
                                    color: const Color(0xFFFEE2E2),
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 18,
                                  color: isEnabled ? const Color(0xFFDC2626) : theme.colorScheme.onSurface.withOpacity(0.3),
                                ),
                                const SizedBox(width: 8),
                                FutureBuilder<String>(
                                  future: labelFuture,
                                  builder: (context, labelSnapshot) {
                                    final isDone = labelSnapshot.connectionState == ConnectionState.done && labelSnapshot.hasData;
                                    final initial = isDone ? labelSnapshot.data! : '';

                                    return AccumulatingStringStreamBuilder(
                                      stream: labelStream,
                                      initialValue: initial,
                                      builder: (context, labelText) {
                                        final displayStr = labelText.isEmpty ? "Hold to Confirm" : labelText;

                                        return Text(
                                          _isHolding ? "Keep holding..." : displayStr,
                                          style: TextStyle(
                                            color: isEnabled ? const Color(0xFFDC2626) : theme.colorScheme.onSurface.withOpacity(0.4),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
