import 'package:flutter/material.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
import 'package:streaming_gen_ui_widget_catalog/core/models/widget_catalog_item.dart';
import 'package:streaming_gen_ui_widget_catalog/core/widget_catalog.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/catalog_page/catalog_card.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/catalog_page/catalog_categories.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/catalog_page/catalog_search_bar.dart';
import 'package:streaming_gen_ui_widget_catalog/widgets/graph_background.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final widgetCatalog = WidgetCatalog(
    catalogItems: [...WidgetCatalogItem.fromRegistry(Registries.all)],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: GraphBackground(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              minHeight: 1200, // Ensure long scrolling on the blueprint grid
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Section
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.8,
                      fontFamily: theme.textTheme.titleLarge?.fontFamily,
                    ),
                    children: [
                      TextSpan(
                        text: "Streaming ",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const TextSpan(text: "Generative UI"),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "WIDGET CATALOG",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 64),

                // 2. Search Bar
                Wrap(
                  children: [
                    CatalogSearchBar(),
                    CatalogCategories(widgetCatalog: widgetCatalog),
                  ],
                ),
                const SizedBox(height: 24),

                // Catalog list
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: widgetCatalog.catalogItems.map((catalogItem) {
                    return CatalogCard(catalogItem: catalogItem);
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
