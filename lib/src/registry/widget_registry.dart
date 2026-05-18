import 'package:flutter/widgets.dart';

abstract class WidgetRegistry {
  Widget? buildWidget(String namespace, Map<String, dynamic> properties);
}
