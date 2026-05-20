import 'package:flutter/material.dart';
import 'package:streaming_gen_ui_widget_catalog/core/widget_catalog.dart';

class CatalogCategories extends StatelessWidget {
  final WidgetCatalog widgetCatalog;

  const CatalogCategories({super.key, required this.widgetCatalog});

  Set<String> get providerNames =>
      widgetCatalog.catalogItems.map((e) => e.provider).toSet();
  Set<String> get providerDisplayNames =>
      widgetCatalog.catalogItems.map((e) => e.displayProvider).toSet();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: providerDisplayNames.map((e) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Chip(label: Text(e)),
        );
      }).toList(),
    );
  }
}
