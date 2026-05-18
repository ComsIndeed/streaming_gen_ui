import 'package:flutter/widgets.dart';
import 'package:llm_json_stream/llm_json_stream.dart';

abstract class WidgetRegistry {
  Widget? buildWidget(String namespace, MapPropertyStream properties);
}

class GenUiRegistry implements WidgetRegistry {
  final Map<String, Widget Function(MapPropertyStream json)> _builders = {};

  void register(String namespace, Widget Function(MapPropertyStream json) builder) {
    _builders[namespace] = builder;
  }

  @override
  Widget? buildWidget(String namespace, MapPropertyStream properties) {
    final builder = _builders[namespace];
    if (builder != null) {
      return builder(properties);
    }
    return null;
  }
}
