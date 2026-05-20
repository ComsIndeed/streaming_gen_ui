import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:streaming_gen_ui_widget_catalog/core/models/widget_catalog_item.dart';

class PropertyEditable extends StatefulWidget {
  const PropertyEditable({
    super.key,
    required this.catalogItem,
    required this.propertyKey,
    required this.controller,
  });
  final WidgetCatalogItem catalogItem;
  final String propertyKey;
  final TextEditingController controller;

  @override
  State<PropertyEditable> createState() => _PropertyEditableState();
}

class _PropertyEditableState extends State<PropertyEditable> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(widget.propertyKey, style: TextStyle(fontWeight: .bold)),
        Text(
          widget.catalogItem.widgetDefinition.properties[widget.propertyKey]!,
        ),
        SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(border: OutlineInputBorder()),
          controller: widget.controller,
        ),
        SizedBox(height: 20),
      ],
    );
  }
}
