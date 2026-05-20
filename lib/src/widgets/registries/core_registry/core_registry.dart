import 'package:flutter/material.dart';
import 'package:streaming_gen_ui/src/models/widget_registry.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_text.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_column.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_row.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_container.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_textfield.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_elevated_button.dart';

/// The default population database of all standard, built-in widget definitions.
final Map<String, WidgetDefinition> coreRegistry = {
  // Basic text rendering
  "core:text": WidgetDefinition(
    builder: (context, props) => StreamingText(
      props: props,
      builder: (context, text) => Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),
    description: "Displays a streamed block of text.",
    properties: {"content": "String (the text content to display)"},
    jsonExample: '{"namespace":"core:text","content":"Hello World!"}',
  ),

  // Dynamic action-activated button
  "core:elevated_button": WidgetDefinition(
    builder: (context, props) => StreamingElevatedButton(props: props),
    description: "A clickable button with action callbacks.",
    properties: {
      "child": "Component (a nested component, usually core:text)",
      "action": "String (the callback action key)",
    },
    jsonExample:
        '{"namespace":"core:elevated_button","child":{"namespace":"core:text","content":"Submit"},"action":"submit_action"}',
  ),

  // Highly optimized self-appending Column
  "core:column": WidgetDefinition(
    builder: (context, props) {
      final childrenProperty = props.asMap.getListProperty("children");
      return StreamingColumn(childrenProperty: childrenProperty);
    },
    description: "A vertical layout system containing nested children.",
    properties: {
      "children": "List<Component> (the child components in vertical order)",
    },
    jsonExample:
        '{"namespace":"core:column","children":[{"namespace":"core:text","content":"First"},{"namespace":"core:text","content":"Second"}]}',
  ),

  // Highly optimized self-appending Row
  "core:row": WidgetDefinition(
    builder: (context, props) {
      final childrenProperty = props.asMap.getListProperty("children");
      return StreamingRow(childrenProperty: childrenProperty);
    },
    description: "A horizontal layout system containing nested children.",
    properties: {
      "children": "List<Component> (the child components in horizontal order)",
    },
    jsonExample:
        '{"namespace":"core:row","children":[{"namespace":"core:text","content":"Left"},{"namespace":"core:text","content":"Right"}]}',
  ),

  // Smoothly animating styling container
  "core:container": WidgetDefinition(
    builder: (context, props) => StreamingContainer(props: props),
    description:
        "A styled box container that smoothly animates dimensions and colors when parsed.",
    properties: {
      "child": "Component (optional nested child component)",
      "width": "Num (optional width)",
      "height": "Num (optional height)",
      "color": "String (optional HEX color code, e.g. #ff5500)",
    },
    jsonExample:
        '{"namespace":"core:container","child":{"namespace":"core:text","content":"Box!"},"width":200,"height":100,"color":"#ff5500"}',
  ),

  // Dynamic action-activated TextField
  "core:textfield": WidgetDefinition(
    builder: (context, props) => StreamingTextField(props: props),
    description: "An input text field for user input.",
    properties: {
      "placeholder": "String (the input placeholder text)",
      "action": "String (the callback action key triggered on submit)",
    },
    jsonExample:
        '{"namespace":"core:textfield","placeholder":"Enter name...","action":"search_action"}',
  ),
};
