import 'package:streaming_gen_ui/streaming_gen_ui.dart';

class WidgetCatalogItem {
  String get provider => namespace.split(':')[0];
  String get displayName => namespace.split(':')[1];
  String namespace;
  WidgetDefinition widgetDefinition;

  WidgetCatalogItem({required this.namespace, required this.widgetDefinition});

  static List<WidgetCatalogItem> fromRegistry(WidgetRegistry registry) =>
      registry.widgets.keys
          .map(
            (namespace) => WidgetCatalogItem(
              namespace: namespace,
              widgetDefinition: registry.widgets[namespace]!,
            ),
          )
          .toList();
}
