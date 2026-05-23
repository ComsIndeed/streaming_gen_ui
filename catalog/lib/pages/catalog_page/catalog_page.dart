import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
import 'package:streaming_gen_ui_widget_catalog/core/app_widgets/elastic_button.dart';
import 'package:streaming_gen_ui_widget_catalog/core/models/widget_catalog_item.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/catalog_page/catalog_card.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/catalog_page/catalog_categories.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/catalog_page/catalog_search_bar.dart';
import 'package:streaming_gen_ui_widget_catalog/widgets/graph_background.dart';

class CatalogPage extends StatefulWidget {
  final VoidCallback? onNavigateToChat;
  const CatalogPage({super.key, this.onNavigateToChat});

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
    allItems = WidgetCatalogItem.fromRegistry(
      registry: Registries.all,
      isBuiltIn: true,
    );
    allItems.sort((a, b) {
      final partsA = a.namespace.split(':');
      final partsB = b.namespace.split(':');

      final themeA = partsA[0];
      final themeB = partsB[0];

      final uiA = partsA.length > 1 ? partsA[1] : '';
      final uiB = partsB.length > 1 ? partsB[1] : '';

      // Determine priority:
      // 0: Non-core themes (sorted alphabetically by theme name)
      // 1: Core themes (like 'core')
      // 2: Extended core themes (like 'core_extended')
      int getThemePriority(String theme) {
        if (theme.startsWith('core')) {
          if (theme.contains('extended')) {
            return 2;
          }
          return 1;
        }
        return 0;
      }

      final pA = getThemePriority(themeA);
      final pB = getThemePriority(themeB);

      if (pA != pB) {
        return pA.compareTo(pB);
      }

      final themeComp = themeA.compareTo(themeB);
      if (themeComp != 0) {
        return themeComp;
      }

      return uiA.compareTo(uiB);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final double paddingVal = isMobile ? 16 : 32;

    // Derived unique categories from loaded widgets
    final categories = allItems.map((e) => e.displayProvider).toSet();

    // Perform live query filtering
    final filteredItems = allItems.where((item) {
      final matchesSearch =
          item.displayName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.namespace.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory =
          selectedCategory == null || item.displayProvider == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      body: GraphBackground(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(paddingVal, isMobile ? 32 : 48, paddingVal, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: isMobile ? 36 : 48,
                                    fontWeight: FontWeight.w400,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: -0.8,
                                    fontFamily: theme.textTheme.titleLarge?.fontFamily,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: "Streaming ",
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    TextSpan(text: "Generative UI"),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "WIDGET CATALOG",
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(
                                    0.7,
                                  ),
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isMobile && widget.onNavigateToChat != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ElasticButton(
                              onPressed: widget.onNavigateToChat!,
                              icon: const Icon(Icons.chat_bubble_outline_rounded),
                              label: const Text("Chat"),
                            ),
                          ),
                      ],
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
              padding: EdgeInsets.symmetric(horizontal: paddingVal),
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
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No widgets found matching your criteria",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.6)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverGrid.builder(
                      gridDelegate: isMobile
                          ? const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 170,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            )
                          : const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 320,
                              mainAxisExtent: 340,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1,
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
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}
