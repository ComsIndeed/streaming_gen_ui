import 'package:flutter/material.dart';
import 'package:streaming_gen_ui/src/models/widget_registry.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_text.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_column.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_row.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_container.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_textfield.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_elevated_button.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_box.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_flex.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_badge.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_bento_card.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_list_tile.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_key_value_row.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_terminal.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_agent_stepper.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_metric.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_data_table.dart';

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

  // --- NEWLY REGISTERED WORKSPACE WIDGETS ---

  // Replaces Container, Padding, SizedBox, and Align with a compressed token footprint
  "core:box": WidgetDefinition(
    builder: (context, props) => StreamingBox(props: props),
    description: "A master utility box container supporting padding, margin, bgColor, alignment, and child constraints.",
    properties: {
      "child": "Component (optional nested child component)",
      "padding": "String or Num (comma separated paddings or single value)",
      "margin": "String or Num (comma separated margins or single value)",
      "bgColor": "String (HEX color code, e.g. #0f172a)",
      "borderRadius": "Num (corner border radius)",
      "alignment": "String (topLeft, topCenter, topRight, centerLeft, center, etc.)",
      "width": "Num (optional width)",
      "height": "Num (optional height)"
    },
    jsonExample: '{"namespace":"core:box","padding":"16,20","borderRadius":16.0,"bgColor":"#0F172A","child":{"namespace":"core:text","content":"Hello in a core:box!"}}',
  ),

  // Flex container supporting vertical/horizontal direction and dynamic gaps
  "core:flex": WidgetDefinition(
    builder: (context, props) => StreamingFlex(props: props),
    description: "A flexible layout component supporting vertical or horizontal flows with automatic child spacing.",
    properties: {
      "direction": "String (vertical or horizontal)",
      "gap": "Num (spacing between nested children)",
      "mainAxisAlignment": "String (start, center, end, spaceBetween, etc.)",
      "crossAxisAlignment": "String (start, center, end, stretch)",
      "children": "List<Component> (nested child components)"
    },
    jsonExample: '{"namespace":"core:flex","direction":"vertical","gap":12.0,"children":[{"namespace":"core:text","content":"Flex Line 1"},{"namespace":"core:text","content":"Flex Line 2"}]}',
  ),

  // Small styled status tag/badge
  "core:badge": WidgetDefinition(
    builder: (context, props) => StreamingBadge(props: props),
    description: "A compact status tag badge displaying curated success, warning, error, info, or neutral themes.",
    properties: {
      "label": "String (the text display content)",
      "style": "String (success, warning, error, info, neutral)",
      "color": "String (optional custom HEX background color)",
      "textColor": "String (optional custom HEX text color)"
    },
    jsonExample: '{"namespace":"core:badge","label":"In Progress","style":"info"}',
  ),

  // Bento Card Layout
  "ui:bento_card": WidgetDefinition(
    builder: (context, props) => StreamingBentoCard(props: props),
    description: "A premium bento grid card with rounded borders, title, subtitle, custom theme highlights, and bodies.",
    properties: {
      "title": "String (primary headline text)",
      "subtitle": "String (optional sub-explanation text)",
      "themeColor": "String (optional custom hex color theme)",
      "body": "List<Component> (list of components inside the card body)",
      "footer": "Component (optional nested footer component)"
    },
    jsonExample: '{"namespace":"ui:bento_card","title":"Analytics Profile","subtitle":"System overview","themeColor":"#8B5CF6","body":[{"namespace":"core:text","content":"Active card data body"}]}',
  ),

  // List Item Tile
  "ui:list_tile": WidgetDefinition(
    builder: (context, props) => StreamingListTile(props: props),
    description: "A structured item list tile with a leading circle icon, a title, a subtitle, and an optional trailing widget.",
    properties: {
      "title": "String (primary title text)",
      "subtitle": "String (optional subtitle explanation)",
      "iconName": "String (material icon name e.g., person, settings, star)",
      "iconColor": "String (optional custom HEX icon color)",
      "trailing": "Component (optional nested trailing widget)"
    },
    jsonExample: '{"namespace":"ui:list_tile","title":"Vincent Sani-Nicolas","subtitle":"Design Engineer","iconName":"account_circle","iconColor":"#6366F1"}',
  ),

  // Tight spec key value row
  "ui:key_value_row": WidgetDefinition(
    builder: (context, props) => StreamingKeyValueRow(props: props),
    description: "A clean row mapping a metadata label to a key value, optionally styled in monospace.",
    properties: {
      "label": "String (metadata category title on left)",
      "value": "String (value text on right)",
      "isMonospace": "Bool (renders value in monospace font)",
      "color": "String (optional custom HEX text color for value)"
    },
    jsonExample: '{"namespace":"ui:key_value_row","label":"System Uptime","value":"99.98%","isMonospace":true}',
  ),

  // Dark-mode Code/Log Terminal
  "doc:terminal": WidgetDefinition(
    builder: (context, props) => StreamingTerminal(props: props),
    description: "A premium dark-themed terminal log viewer with Mac-style control buttons and code syntax highlighting.",
    properties: {
      "title": "String (process name or filename heading)",
      "language": "String (syntax language formatting code: javascript, dart, bash)",
      "code": "String (raw code logs or multi-line command output)"
    },
    jsonExample: '{"namespace":"doc:terminal","title":"deploy.sh","language":"bash","code":"deploying to production...\\ndone!"}',
  ),

  // Multi-step reasoning timeline
  "doc:agent_stepper": WidgetDefinition(
    builder: (context, props) => StreamingAgentStepper(props: props),
    description: "A vertical progress timeline listing agent processing execution steps and completion states.",
    properties: {
      "steps": "List<Map> (each step has title, status [completed/running/failed/pending], and duration)"
    },
    jsonExample: '{"namespace":"doc:agent_stepper","steps":[{"title":"Planning task","status":"completed","duration":"140ms"},{"title":"Analyzing workspace","status":"running"}]}',
  ),

  // Dashboard Metric Big Number
  "dash:metric": WidgetDefinition(
    builder: (context, props) => StreamingMetric(props: props),
    description: "A high-visibility metric tile showing a label, a large value, and color-coded green/red arrow trends.",
    properties: {
      "label": "String (metric subtitle label)",
      "value": "String (large bold metric output value)",
      "trend": "String (percentage or growth comparison text)",
      "trendDirection": "String (up, down, neutral)",
      "color": "String (optional hex accent color)"
    },
    jsonExample: r'{"namespace":"dash:metric","label":"Monthly Revenue","value":"$142,300","trend":"+12.4% vs last month","trendDirection":"up"}',
  ),

  // Styled spreadsheet data table
  "dash:data_table": WidgetDefinition(
    builder: (context, props) => StreamingDataTable(props: props),
    description: "A clean structured data table supporting horizontal scrolling, column headers, and multi-row cells.",
    properties: {
      "title": "String (optional table caption title)",
      "columns": "List<String> (ordered list of column headers)",
      "rows": "List<List<String>> (2D matrix of row cell contents)"
    },
    jsonExample: r'{"namespace":"dash:data_table","title":"Products","columns":["ID","Name","Price"],"rows":[["1","Product A","$10.00"],["2","Product B","$20.00"]]}',
  ),
};
