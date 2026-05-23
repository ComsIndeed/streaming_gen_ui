import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
import 'package:streaming_gen_ui_widget_catalog/core/app_widgets/elastic_button.dart';
import 'package:streaming_gen_ui_widget_catalog/core/models/widget_catalog_item.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/catalog_page/catalog_card.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/catalog_page/catalog_search_bar.dart';
import 'package:streaming_gen_ui_widget_catalog/widgets/graph_background.dart';
import 'package:streaming_gen_ui_widget_catalog/main.dart';

class CatalogPage extends StatefulWidget {
  final VoidCallback? onNavigateToChat;
  const CatalogPage({super.key, this.onNavigateToChat});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late final List<WidgetCatalogItem> allItems;
  String searchQuery = "";
  String? selectedTheme;
  String? selectedWidgetType;

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

    // Derived unique themes and widget types from loaded widgets
    final themes = allItems.map((e) => e.displayProvider).toSet().toList()..sort();
    final widgetTypes = allItems.map((e) => e.displayName).toSet().toList()..sort();

    // Perform live query filtering
    final filteredItems = allItems.where((item) {
      final matchesSearch =
          item.displayName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.namespace.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesTheme =
          selectedTheme == null || item.displayProvider == selectedTheme;
      final matchesWidgetType =
          selectedWidgetType == null || item.displayName == selectedWidgetType;
      return matchesSearch && matchesTheme && matchesWidgetType;
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

                    // 2. Search Bar & Theme Switcher
                    Row(
                      children: [
                        Expanded(
                          child: CatalogSearchBar(
                            value: searchQuery,
                            onChanged: (val) {
                              setState(() {
                                searchQuery = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildThemeToggleButton(context),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 3. Responsive Dropdowns
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 600;
                        final dropdownChildren = [
                          Expanded(
                            flex: isNarrow ? 0 : 1,
                            child: _buildDropdown(
                              context: context,
                              label: "DESIGN THEME",
                              value: selectedTheme ?? "All Themes",
                              items: ["All Themes", ...themes],
                              onChanged: (val) {
                                setState(() {
                                  selectedTheme = val == "All Themes" ? null : val;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: isNarrow ? 0 : 16, height: isNarrow ? 12 : 0),
                          Expanded(
                            flex: isNarrow ? 0 : 1,
                            child: _buildDropdown(
                              context: context,
                              label: "WIDGET UI TYPE",
                              value: selectedWidgetType ?? "All Widgets",
                              items: ["All Widgets", ...widgetTypes],
                              onChanged: (val) {
                                setState(() {
                                  selectedWidgetType = val == "All Widgets" ? null : val;
                                });
                              },
                            ),
                          ),
                        ];

                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: dropdownChildren.map((e) => e is Expanded ? e.child : e).toList(),
                          );
                        } else {
                          return Row(
                            children: dropdownChildren,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // 4. Lazy-Loaded Responsive Sliver Grid
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

  Widget _buildThemeToggleButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentMode, _) {
          return IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amber.shade300 : theme.colorScheme.primary,
            ),
            tooltip: "Toggle Light/Dark Theme",
            onPressed: () {
              if (isDark) {
                themeNotifier.value = ThemeMode.light;
              } else {
                themeNotifier.value = ThemeMode.dark;
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        cardColor: theme.colorScheme.surfaceContainerHigh,
      ),
      child: PopupMenuButton<String>(
        onSelected: onChanged,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.12),
          ),
        ),
        elevation: 6,
        offset: const Offset(0, 48),
        itemBuilder: (context) {
          return items.map((item) {
            final isSelected = item == value;
            return PopupMenuItem<String>(
              value: item,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            );
          }).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
