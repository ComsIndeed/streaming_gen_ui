import 'package:flutter/widgets.dart';
import '../views/view_controller.dart';
import '../registry/widget_registry.dart';

class GenUiView extends StatelessWidget {
  final String viewId;
  final ViewController controller;
  final WidgetRegistry registry;
  final Widget Function(BuildContext)? onUnknownWidget;

  const GenUiView({
    Key? key,
    required this.viewId,
    required this.controller,
    required this.registry,
    this.onUnknownWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Listen to the viewId state from the controller and render
    return const SizedBox.shrink();
  }
}
