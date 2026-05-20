import 'dart:math';

import 'package:flutter/material.dart';
import 'package:streaming_gen_ui_widget_catalog/core/models/widget_catalog_item.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
import 'package:streaming_gen_ui_widget_catalog/core/utilities/stream_text_in_chunks.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/preview_page/preview_page.dart';

class CatalogCard extends StatelessWidget {
  final WidgetCatalogItem catalogItem;

  const CatalogCard({super.key, required this.catalogItem});

  Stream<String> get stream => streamTextInChunks(
    text: "<interface>${catalogItem.widgetDefinition.jsonExample}</interface>",
    chunkSize: 4,
    interval: Duration(milliseconds: 100),
    chunkSizeImmediatelyEmit: '<interface>{"namespace":"  core:'.length,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = MediaQuery.sizeOf(context);
    const divisionCount = 5;
    const spacing = 16;
    const windowPadding = 64;

    final streamingGenUi = StreamingGenerativeUi(registry: Registries.all);
    streamingGenUi.stream(stream, viewId: 'main-view');

    return SizedBox(
      width:
          ((sizes.width - windowPadding) / divisionCount) -
          (spacing / 2) -
          5, // where did the 5 come from to make it fit?
      height: 240,
      child: Hero(
        tag: "catalog-card",
        key: ObjectKey('catalog-card-hero'),
        child: Card(
          key: ObjectKey('catalog-card'),
          clipBehavior: Clip.antiAlias,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PreviewPage(catalogItem: catalogItem),
              ),
            ),
            child: Stack(
              children: [
                SizedBox.expand(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
                    child: FittedBox(child: streamingGenUi.view('main-view')),
                  ),
                ),
                SizedBox.expand(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        transform: GradientRotation(pi * 1.5),
                        stops: [0.0, 0.25],
                        colors: [
                          Colors.black.withAlpha(80),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentGeometry.bottomStart,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Text(
                          catalogItem.displayName,
                          style: TextStyle(
                            fontWeight: .bold,
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withAlpha(230),
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          "(${catalogItem.displayProvider})",
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withAlpha(200),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
