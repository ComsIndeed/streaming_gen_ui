import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import '../views/view_controller.dart';
import '../registry/widget_registry.dart';

class GenUiView extends StatelessWidget {
  final String viewId;
  final ViewController controller;
  final WidgetRegistry registry;
  final Widget Function(BuildContext)? onUnknownWidget;

  const GenUiView({
    super.key,
    required this.viewId,
    required this.controller,
    required this.registry,
    this.onUnknownWidget,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class StreamingWidget extends StatelessWidget {
  final MapPropertyStream mapStream;
  final WidgetRegistry registry;
  final Widget Function(BuildContext)? onUnknownWidget;

  const StreamingWidget({
    super.key,
    required this.mapStream,
    required this.registry,
    this.onUnknownWidget,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class StreamingLoadingIndicator extends StatefulWidget {
  const StreamingLoadingIndicator({super.key});

  @override
  State<StreamingLoadingIndicator> createState() => _StreamingLoadingIndicatorState();
}

class _StreamingLoadingIndicatorState extends State<StreamingLoadingIndicator> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
