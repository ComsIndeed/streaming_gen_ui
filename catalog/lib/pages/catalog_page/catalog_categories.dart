import 'package:flutter/material.dart';

class CatalogCategories extends StatelessWidget {
  final Set<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const CatalogCategories({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allCategories = ["All Widgets", ...categories];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: allCategories.map((category) {
          final isAllOption = category == "All Widgets";
          final isSelected = isAllOption
              ? selectedCategory == null
              : selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Material(
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(32),
                  side: BorderSide(
                    color: isSelected
                        ? Colors.transparent
                        : theme.colorScheme.outline.withValues(alpha: 0.12),
                  ),
                ),
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    if (isAllOption) {
                      onCategorySelected(null);
                    } else {
                      onCategorySelected(isSelected ? null : category);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
