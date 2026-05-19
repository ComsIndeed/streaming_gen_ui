import 'package:flutter/widgets.dart';
import 'package:llm_json_stream/llm_json_stream.dart';

class WidgetRegistry {
  Map<String, Widget Function(BuildContext context, PropertyStream props)>
  widgets;

  WidgetRegistry({required this.widgets});

  String get systemPromptFragment => throw UnimplementedError();
}
