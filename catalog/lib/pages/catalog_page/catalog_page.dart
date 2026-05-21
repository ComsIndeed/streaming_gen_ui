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
  late final List<WidgetCatalogItem> allItems;
  String searchQuery = "";
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    allItems = WidgetCatalogItem.fromRegistry(Registries.all);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Derived unique categories from loaded widgets
    final categories = allItems.map((e) => e.displayProvider).toSet();

    // Perform live query filtering
    final filteredItems = allItems.where((item) {
      final matchesSearch = item.displayName.toLowerCase().contains(searchQuery.toLowerCase()) || 
                            item.namespace.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == null || item.displayProvider == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      body: GraphBackground(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(32, 48, 32, 16),
              sliver: SliverToBoxAdapter(
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
                          const TextSpan(
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
                    const SizedBox(height: 48),

                    // 2. Search Bar & Categories
                    CatalogSearchBar(
                      value: searchQuery,
                      onChanged: (val) {
                        setState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    CatalogCategories(
                      categories: categories,
                      selectedCategory: selectedCategory,
                      onCategorySelected: (cat) {
                        setState(() {
                          selectedCategory = cat;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 3. Lazy-Loaded Responsive Sliver Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              sliver: filteredItems.isEmpty
                  ? SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 64),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No widgets found matching your criteria",
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverGrid.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        mainAxisExtent: 240,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return CatalogCard(
                          key: ValueKey(item.namespace),
                          catalogItem: item,
                        );
                      },
                    ),
            ),

            // Safe bottom padding for scroll space
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }
}

