import 'package:streaming_gen_ui/streaming_gen_ui.dart';

class WidgetCatalogItem {
  String get displayProvider {
    final formattedName = namespace
        .split(':')[0]
        .split("_")
        .map((e) => e[0].toUpperCase() + e.substring(1))
        .join(" ");

    if (formattedName == "Ui") return "UI";
    if (formattedName == "Doc") return "Document";
    if (formattedName == "Dash") return "Dashboard";

    return formattedName;
  }

  String get provider => namespace
      .split(':')[0]
      .split("_")
      .map((e) => e[0].toUpperCase() + e.substring(1))
      .join(" ");

  String get displayName => namespace
      .split(':')[1]
      .split("_")
      .map((e) => e[0].toUpperCase() + e.substring(1))
      .join(" ");
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
