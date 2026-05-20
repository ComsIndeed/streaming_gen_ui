import 'package:flutter/material.dart';
import 'package:streaming_gen_ui_widget_catalog/core/models/widget_catalog_item.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';

class CatalogCard extends StatefulWidget {
  final WidgetCatalogItem catalogItem;

  const CatalogCard({super.key, required this.catalogItem});

  @override
  State<CatalogCard> createState() => _CatalogCardState();
}

class _CatalogCardState extends State<CatalogCard> {
  late final StreamingGenerativeUi streamingGenUi;

  @override
  void initState() {
    super.initState();

    streamingGenUi = StreamingGenerativeUi(
      registry: Registries.all.only([widget.catalogItem.namespace]),
    );
  }

  Stream<String> get stream => streamTextInChunks(
    text:
        "<interface>${widget.catalogItem.widgetDefinition.jsonExample}</interface>",
    chunkSize: 4,
    interval: Duration(milliseconds: 100),
  );

  @override
  Widget build(BuildContext context) {
    streamingGenUi.stream(stream, viewId: 'main-view');

    return SizedBox(
      width: 480,
      height: 380,
      child: Card(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: FittedBox(child: streamingGenUi.view("main-view")),
      ),
    );
  }
}
