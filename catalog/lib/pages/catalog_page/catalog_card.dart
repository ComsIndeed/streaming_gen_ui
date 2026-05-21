import 'dart:math';

import 'package:flutter/material.dart';
import 'package:streaming_gen_ui_widget_catalog/core/models/widget_catalog_item.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
import 'package:streaming_gen_ui_widget_catalog/core/utilities/stream_text_in_chunks.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/preview_page/preview_page.dart';

class CatalogCard extends StatefulWidget {
  final WidgetCatalogItem catalogItem;

  const CatalogCard({super.key, required this.catalogItem});

  @override
  State<CatalogCard> createState() => _CatalogCardState();
}

class _CatalogCardState extends State<CatalogCard> {
  late final StreamingGenerativeUi _streamingGenUi;
  late final Stream<String> _stream;

  @override
  void initState() {
    super.initState();
    _streamingGenUi = StreamingGenerativeUi(registry: Registries.all);
    _stream = streamTextInChunks(
      text: "<interface>${widget.catalogItem.widgetDefinition.jsonExample}</interface>",
      chunkSize: 4,
      interval: const Duration(milliseconds: 100),
      chunkSizeImmediatelyEmit: '<interface>{"namespace":"  core:'.length,
    );
    _streamingGenUi.stream(_stream, viewId: 'main-view');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Hero(
      tag: "catalog-card-${widget.catalogItem.namespace}",
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PreviewPage(catalogItem: widget.catalogItem),
            ),
          ),
          child: Stack(
            children: [
              SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 36),
                  child: FittedBox(
                    child: _streamingGenUi.view('main-view'),
                  ),
                ),
              ),
              SizedBox.expand(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      transform: const GradientRotation(pi * 1.5),
                      stops: const [0.0, 0.3],
                      colors: [
                        Colors.black.withAlpha(90),
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
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.catalogItem.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: theme.colorScheme.onSurface.withAlpha(235),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "(${widget.catalogItem.displayProvider})",
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withAlpha(190),
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
    );
  }
}

