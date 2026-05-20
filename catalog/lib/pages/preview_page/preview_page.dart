import 'dart:math';

import 'package:flutter/material.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
import 'package:streaming_gen_ui_widget_catalog/core/models/widget_catalog_item.dart';
import 'package:streaming_gen_ui_widget_catalog/core/utilities/stream_text_in_chunks.dart';

class PreviewPage extends StatelessWidget {
  final WidgetCatalogItem catalogItem;

  const PreviewPage({super.key, required this.catalogItem});

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

    final streamingGenUi = StreamingGenerativeUi(registry: Registries.all);
    streamingGenUi.stream(stream, viewId: 'main-view');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: .start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        label: Text("Back"),
                        icon: Icon(Icons.arrow_back),
                      ),
                      SizedBox(height: 24),

                      Text(
                        catalogItem.displayName,
                        style: TextStyle(fontSize: 32, fontWeight: .bold),
                      ),
                      Text(
                        catalogItem.namespace,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface.withAlpha(200),
                        ),
                      ),

                      SizedBox(height: 18),

                      Text(
                        catalogItem.widgetDefinition.description,
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.colorScheme.onSurface.withAlpha(250),
                        ),
                      ),

                      SizedBox(height: 24),

                      Column(
                        crossAxisAlignment: .start,
                        children: catalogItem.widgetDefinition.properties.keys
                            .map((key) {
                              return Column(
                                crossAxisAlignment: .start,
                                children: [
                                  Text(
                                    key,
                                    style: TextStyle(fontWeight: .bold),
                                  ),
                                  Text(
                                    catalogItem
                                        .widgetDefinition
                                        .properties[key]!,
                                  ),
                                  SizedBox(height: 8),
                                ],
                              );
                            })
                            .toList(),
                      ),

                      SizedBox(height: 32),

                      Text(
                        "JSON Example",
                        style: TextStyle(
                          fontSize: 24,
                          color: theme.colorScheme.onSurface.withAlpha(250),
                        ),
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: double.infinity,
                              minHeight: 256,
                            ),
                            child: Text(
                              catalogItem.widgetDefinition.jsonExample,
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Hero(
              tag: 'catalog-card',
              key: ObjectKey('catalog-card-hero'),
              child: SizedBox(
                key: ObjectKey('catalog-card'),
                width: sizes.width * 0.60,
                height: double.infinity,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      SizedBox.expand(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
                          child: FittedBox(
                            child: streamingGenUi.view('main-view'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
