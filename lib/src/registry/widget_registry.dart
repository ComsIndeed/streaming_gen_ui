import 'package:flutter/widgets.dart';

abstract class WidgetRegistry {
  Widget? buildWidget(String namespace, Map<String, dynamic> properties);
}

class GenUiRegistry implements WidgetRegistry {
  final Map<String, Widget Function(Map<String, dynamic> json)> _builders = {};

  void register(String namespace, Widget Function(Map<String, dynamic> json) builder) {
    _builders[namespace] = builder;
  }

  @override
  Widget? buildWidget(String namespace, Map<String, dynamic> properties) {
    final builder = _builders[namespace];
    if (builder != null) {
      return builder(properties);
    }
    return null;
  }
}
