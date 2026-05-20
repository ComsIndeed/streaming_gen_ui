import 'package:flutter/material.dart';
import 'package:streaming_gen_ui_widget_catalog/core/models/widget_catalog_item.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
import 'package:streaming_gen_ui_widget_catalog/core/utilities/stream_text_in_chunks.dart';

class CatalogCard extends StatelessWidget {
  final WidgetCatalogItem catalogItem;

  const CatalogCard({super.key, required this.catalogItem});

  Stream<String> get stream => streamTextInChunks(
    text: "<interface>${catalogItem.widgetDefinition.jsonExample}</interfacex>",
    chunkSize: 4,
    interval: Duration(milliseconds: 100),
    chunkSizeImmediatelyEmit: '<interface>{"namespace":"core:'.length,
  );

  @override
  Widget build(BuildContext context) {
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
      child: Card(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FittedBox(child: streamingGenUi.view('main-view')),
        ),
      ),
    );
  }
}
