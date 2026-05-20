import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
import 'package:streaming_gen_ui_widget_catalog/core/models/widget_catalog_item.dart';
import 'package:streaming_gen_ui_widget_catalog/core/utilities/stream_text_in_chunks.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/preview_page/property_editable.dart';
import 'package:streaming_gen_ui_widget_catalog/widgets/graph_background.dart';

class PreviewPage extends StatefulWidget {
  final WidgetCatalogItem catalogItem;

  const PreviewPage({super.key, required this.catalogItem});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  Map<String, TextEditingController> propertyControllers = {};

  @override
  void initState() {
    super.initState();
    final jsonExampleDecoded = jsonDecode(
      widget.catalogItem.widgetDefinition.jsonExample,
    );
    final Map<String, dynamic> jsonExampleMap =
        jsonExampleDecoded as Map<String, dynamic>;
    final properties = widget.catalogItem.widgetDefinition.properties;
    final propKeys = properties.keys;
    final Map<String, TextEditingController> controllers = Map.fromEntries(
      propKeys.map(
        (key) => MapEntry(
          key,
          TextEditingController(text: jsonEncode(jsonExampleMap[key])),
        ),
      ),
    );

    propertyControllers = controllers;
  }

  Map<String, dynamic> get newMap {
    final Map<String, String> jsonMapMap = propertyControllers.map(
      (key, controller) => MapEntry(key, controller.text),
    );
    final Map<String, dynamic> mapMapMap = jsonMapMap.map(
      (key, json) => MapEntry(key, jsonDecode(json)),
    );
    mapMapMap.removeWhere((key, value) {
      if (value == null) return true;

      return false;
    });
    return mapMapMap;
  }

  String get updatedExample {
    final oldMapDecoded = jsonDecode(
      widget.catalogItem.widgetDefinition.jsonExample,
    );
    final oldMap = oldMapDecoded as Map<String, dynamic>;

    final modifiedMap = {...oldMap, ...newMap};

    final encodedModifiedMap = jsonEncode(modifiedMap);
    return encodedModifiedMap;
  }

  Stream<String> get stream {
    return streamTextInChunks(
      text: "<interface>$updatedExample</interface>",
      chunkSize: 4,
      interval: Duration(milliseconds: 300),
      chunkSizeImmediatelyEmit: '<interface>{"namespace":"  core:'.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = MediaQuery.sizeOf(context);

    final streamingGenUi = StreamingGenerativeUi(registry: Registries.all);
    streamingGenUi.stream(stream, viewId: 'main-view');

    return Scaffold(
      body: GraphBackground(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                          widget.catalogItem.displayName,
                          style: TextStyle(fontSize: 32, fontWeight: .bold),
                        ),
                        Text(
                          widget.catalogItem.namespace,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withAlpha(200),
                          ),
                        ),

                        SizedBox(height: 18),

                        Text(
                          widget.catalogItem.widgetDefinition.description,
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.colorScheme.onSurface.withAlpha(250),
                          ),
                        ),

                        SizedBox(height: 24),

                        Column(
                          crossAxisAlignment: .start,
                          children: widget
                              .catalogItem
                              .widgetDefinition
                              .properties
                              .keys
                              .map((key) {
                                return PropertyEditable(
                                  controller: propertyControllers[key]!,
                                  propertyKey: key,
                                  catalogItem: widget.catalogItem,
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
                              child: Stack(
                                children: [
                                  AccumulatingStringStreamBuilder(
                                    stream: stream,
                                    builder: (_, text) => Text(
                                      text,
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  Text(
                                    "<interface>$updatedExample</interface>",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: theme.colorScheme.onSurface
                                          .withAlpha(50),
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
                ),
              ),
              Hero(
                tag: 'catalog-card-${widget.catalogItem.namespace}',
                child: SizedBox(
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
                            padding: const EdgeInsets.all(64),
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
      ),
    );
  }
}
