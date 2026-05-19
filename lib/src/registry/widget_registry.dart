import 'package:flutter/widgets.dart';
import 'package:llm_json_stream/llm_json_stream.dart';

abstract class WidgetRegistry {
  Widget? buildWidget(String namespace, MapPropertyStream properties);
}

class GenUiRegistry implements WidgetRegistry {
  void register(String namespace, Widget Function(MapPropertyStream json) builder) {
    throw UnimplementedError();
  }

  @override
  Widget? buildWidget(String namespace, MapPropertyStream properties) {
    throw UnimplementedError();
  }
}
