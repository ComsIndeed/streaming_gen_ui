import 'package:flutter/widgets.dart';
import 'widget_registry.dart';

class BuiltinRegistry implements WidgetRegistry {
  @override
  Widget? buildWidget(String namespace, Map<String, dynamic> properties) {
    // TODO: Implement built-in widget routing based on namespace
    return null;
  }
}
