import 'package:flutter/material.dart';

class CatalogSearchBar extends StatelessWidget {
  const CatalogSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SearchAnchor.bar(
      suggestionsBuilder: (context, controller) => [],
      barHintText: "Search Widgets",
    );
  }
}
