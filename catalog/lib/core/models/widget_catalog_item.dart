import 'package:streaming_gen_ui/streaming_gen_ui.dart';

class WidgetCatalogItem {
  String get displayProvider {
    final formattedName = namespace
        .split(':')[0]
        .split("_")
        .map(
          (e) => e.toLowerCase() == "ui"
              ? "UI"
              : (e[0].toUpperCase() + e.substring(1)),
        )
        .join(" ");

    if (formattedName == "Doc") return "Document";
    if (formattedName == "Dash") return "Dashboard";

    return formattedName;
  }

  String get provider => namespace
      .split(':')[0]
      .split("_")
      .map(
        (e) => e.toLowerCase() == "ui"
            ? "UI"
            : (e[0].toUpperCase() + e.substring(1)),
      )
      .join(" ");

  String get displayName => namespace
      .split(':')[1]
      .split("_")
      .map((e) => e[0].toUpperCase() + e.substring(1))
      .join(" ");
  String namespace;
  WidgetDefinition widgetDefinition;
  bool isBuiltIn;

  WidgetCatalogItem({
    required this.namespace,
    required this.widgetDefinition,
    required this.isBuiltIn,
  });

  static List<WidgetCatalogItem> fromRegistry({
    required WidgetRegistry registry,
    required bool isBuiltIn,
  }) => registry.widgets.keys
      .map(
        (namespace) => WidgetCatalogItem(
          namespace: namespace,
          widgetDefinition: registry.widgets[namespace]!,
          isBuiltIn: isBuiltIn,
        ),
      )
      .toList();
}
