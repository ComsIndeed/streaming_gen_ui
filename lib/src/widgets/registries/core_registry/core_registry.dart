import 'package:flutter/material.dart';
import 'package:streaming_gen_ui/src/models/widget_registry.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/pending/streaming_image.dart';
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
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_slider.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_progress_ring.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_alert.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_segmented_control.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_shimmer_button.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_stack_carousel.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_icon_button_row.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_destructive_action_button.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_expanding_accordion_carousel.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_split_screen_carousel.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_stepper_counter.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_timeline_stepper.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_stats_grid.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_log_streamer.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_voice_visualizer.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_weather_card.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_product_card.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_crypto_card.dart';

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
    description:
        "A master utility box container supporting padding, margin, bgColor, alignment, and child constraints.",
    properties: {
      "child": "Component (optional nested child component)",
      "padding": "String or Num (comma separated paddings or single value)",
      "margin": "String or Num (comma separated margins or single value)",
      "bgColor": "String (HEX color code, e.g. #0f172a)",
      "borderRadius": "Num (corner border radius)",
      "alignment":
          "String (topLeft, topCenter, topRight, centerLeft, center, etc.)",
      "width": "Num (optional width)",
      "height": "Num (optional height)",
    },
    jsonExample:
        '{"namespace":"core:box","padding":"16,20","borderRadius":16.0,"bgColor":"#0F172A","child":{"namespace":"core:text","content":"Hello in a core:box!"}}',
  ),

  // Flex container supporting vertical/horizontal direction and dynamic gaps
  "core:flex": WidgetDefinition(
    builder: (context, props) => StreamingFlex(props: props),
    description:
        "A flexible layout component supporting vertical or horizontal flows with automatic child spacing.",
    properties: {
      "direction": "String (vertical or horizontal)",
      "gap": "Num (spacing between nested children)",
      "mainAxisAlignment": "String (start, center, end, spaceBetween, etc.)",
      "crossAxisAlignment": "String (start, center, end, stretch)",
      "children": "List<Component> (nested child components)",
    },
    jsonExample:
        '{"namespace":"core:flex","direction":"vertical","gap":12.0,"children":[{"namespace":"core:text","content":"Flex Line 1"},{"namespace":"core:text","content":"Flex Line 2"}]}',
  ),

  // Small styled status tag/badge
  "core:badge": WidgetDefinition(
    builder: (context, props) => StreamingBadge(props: props),
    description:
        "A compact status tag badge displaying curated success, warning, error, info, or neutral themes.",
    properties: {
      "label": "String (the text display content)",
      "style": "String (success, warning, error, info, neutral)",
      "color": "String (optional custom HEX background color)",
      "textColor": "String (optional custom HEX text color)",
    },
    jsonExample:
        '{"namespace":"core:badge","label":"In Progress","style":"info"}',
  ),

  // Bento Card Layout
  "ui:bento_card": WidgetDefinition(
    builder: (context, props) => StreamingBentoCard(props: props),
    description:
        "A premium bento grid card with rounded borders, title, subtitle, custom theme highlights, and bodies.",
    properties: {
      "title": "String (primary headline text)",
      "subtitle": "String (optional sub-explanation text)",
      "themeColor": "String (optional custom hex color theme)",
      "body": "List<Component> (list of components inside the card body)",
      "footer": "Component (optional nested footer component)",
    },
    jsonExample:
        '{"namespace":"ui:bento_card","title":"Analytics Profile","subtitle":"System overview","themeColor":"#8B5CF6","body":[{"namespace":"core:text","content":"Active card data body"}]}',
  ),

  // List Item Tile
  "ui:list_tile": WidgetDefinition(
    builder: (context, props) => StreamingListTile(props: props),
    description:
        "A structured item list tile with a leading circle icon, a title, a subtitle, and an optional trailing widget.",
    properties: {
      "title": "String (primary title text)",
      "subtitle": "String (optional subtitle explanation)",
      "iconName": "String (material icon name e.g., person, settings, star)",
      "iconColor": "String (optional custom HEX icon color)",
      "trailing": "Component (optional nested trailing widget)",
    },
    jsonExample:
        '{"namespace":"ui:list_tile","title":"Vincent Sani-Nicolas","subtitle":"Design Engineer","iconName":"account_circle","iconColor":"#6366F1"}',
  ),

  // Tight spec key value row
  "ui:key_value_row": WidgetDefinition(
    builder: (context, props) => StreamingKeyValueRow(props: props),
    description:
        "A clean row mapping a metadata label to a key value, optionally styled in monospace.",
    properties: {
      "label": "String (metadata category title on left)",
      "value": "String (value text on right)",
      "isMonospace": "Bool (renders value in monospace font)",
      "color": "String (optional custom HEX text color for value)",
    },
    jsonExample:
        '{"namespace":"ui:key_value_row","label":"System Uptime","value":"99.98%","isMonospace":true}',
  ),

  // Dark-mode Code/Log Terminal
  "doc:terminal": WidgetDefinition(
    builder: (context, props) => StreamingTerminal(props: props),
    description:
        "A premium dark-themed terminal log viewer with Mac-style control buttons and code syntax highlighting.",
    properties: {
      "title": "String (process name or filename heading)",
      "language":
          "String (syntax language formatting code: javascript, dart, bash)",
      "code": "String (raw code logs or multi-line command output)",
    },
    jsonExample:
        '{"namespace":"doc:terminal","title":"deploy.sh","language":"bash","code":"deploying to production...\\ndone!"}',
  ),

  // Multi-step reasoning timeline
  "doc:agent_stepper": WidgetDefinition(
    builder: (context, props) => StreamingAgentStepper(props: props),
    description:
        "A vertical progress timeline listing agent processing execution steps and completion states.",
    properties: {
      "steps":
          "List<Map> (each step has title, status [completed/running/failed/pending], and duration)",
    },
    jsonExample:
        '{"namespace":"doc:agent_stepper","steps":[{"title":"Planning task","status":"completed","duration":"140ms"},{"title":"Analyzing workspace","status":"running"}]}',
  ),

  // Dashboard Metric Big Number
  "dash:metric": WidgetDefinition(
    builder: (context, props) => StreamingMetric(props: props),
    description:
        "A high-visibility metric tile showing a label, a large value, and color-coded green/red arrow trends.",
    properties: {
      "label": "String (metric subtitle label)",
      "value": "String (large bold metric output value)",
      "trend": "String (percentage or growth comparison text)",
      "trendDirection": "String (up, down, neutral)",
      "color": "String (optional hex accent color)",
    },
    jsonExample:
        r'{"namespace":"dash:metric","label":"Monthly Revenue","value":"$142,300","trend":"+12.4% vs last month","trendDirection":"up"}',
  ),

  // Styled spreadsheet data table
  "dash:data_table": WidgetDefinition(
    builder: (context, props) => StreamingDataTable(props: props),
    description:
        "A clean structured data table supporting horizontal scrolling, column headers, and multi-row cells.",
    properties: {
      "title": "String (optional table caption title)",
      "columns": "List<String> (ordered list of column headers)",
      "rows": "List<List<String>> (2D matrix of row cell contents)",
    },
    jsonExample:
        r'{"namespace":"dash:data_table","title":"Products","columns":["ID","Name","Price"],"rows":[["1","Product A","$10.00"],["2","Product B","$20.00"]]}',
  ),

  "media:image": WidgetDefinition(
    builder: (context, props) => StreamingImage(props: props),
    description:
        "A universal media player and swipable image carousel widget supporting single images, multiple images, and smooth pagination indicators.",
    properties: {
      "url": "String (optional single network image source URL)",
      "urls": "List<String> (optional list of swipable image URLs)",
      "fit": "String (cover, contain, fill, etc.)",
      "borderRadius": "Num (corner border radius, default 16)",
      "width": "Num (optional width)",
      "height": "Num (optional height, default 200)",
    },
    jsonExample:
        '{"namespace":"media:image","borderRadius":20.0,"height":240.0,"urls":["https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800","https://images.unsplash.com/photo-1604871000636-074fa5117945?w=800"]}',
  ),

  "core:slider": WidgetDefinition(
    builder: (context, props) => StreamingSlider(props: props),
    description:
        "An interactive slider input that morphs its state when loaded.",
    properties: {
      "min": "Num (optional minimum value, default 0.0)",
      "max": "Num (optional maximum value, default 100.0)",
      "value": "Num (optional initial slider value)",
      "label": "String (optional title label string)",
      "action": "String (the action key triggered on submit)",
    },
    jsonExample:
        '{"namespace":"core:slider","min":0,"max":100,"value":45,"label":"Volumetric Flow Rate","action":"slider_change"}',
  ),

  "core:progress_ring": WidgetDefinition(
    builder: (context, props) => StreamingProgressRing(props: props),
    description:
        "A premium circular progress ring displaying numeric percentage indicators.",
    properties: {
      "value": "Num (the progress percentage, e.g., 0.0 to 1.0 or 0 to 100)",
      "size": "Num (optional circle diameter size, default 80)",
      "strokeWidth": "Num (optional track thickness width, default 8)",
      "color": "String (optional custom HEX progress color)",
      "label": "String (optional text label displayed beside)",
    },
    jsonExample:
        '{"namespace":"core:progress_ring","value":78,"size":80,"strokeWidth":8,"color":"#10B981","label":"Optimizing Memory..."}',
  ),

  "core:alert": WidgetDefinition(
    builder: (context, props) => StreamingAlert(props: props),
    description:
        "A premium status banner supporting success, warning, error, or info themes.",
    properties: {
      "title": "String (primary bold status heading)",
      "description": "String (paragraph details text)",
      "style": "String (success, warning, error, info)",
      "action": "String (optional action key callback triggered on dismiss)",
    },
    jsonExample:
        '{"namespace":"core:alert","title":"Deployment Succeeded","description":"The production server has completed all automated rollouts successfully.","style":"success","action":"dismiss_alert"}',
  ),

  "core:segmented_control": WidgetDefinition(
    builder: (context, props) => StreamingSegmentedControl(props: props),
    description:
        "A sliding choices tab capsule supporting dynamic multi-option selection.",
    properties: {
      "options": "List<String> (ordered list of choice tabs)",
      "selected": "String (currently active/selected choice tab)",
      "action": "String (the action key callback triggered on selection)",
    },
    jsonExample:
        '{"namespace":"core:segmented_control","options":["Visual View","Log Code","Terminal"],"selected":"Visual View","action":"change_tab"}',
  ),

  "core:shimmer_button": WidgetDefinition(
    builder: (context, props) => StreamingShimmerButton(props: props),
    description:
        "A premium call-to-action button featuring a shiny sweeping linear gradient shimmer when active.",
    properties: {
      "child": "Component (a nested component, usually core:text)",
      "action": "String (the callback action key)",
    },
    jsonExample:
        '{"namespace":"core:shimmer_button","child":{"namespace":"core:text","content":"Activate Neural Model"},"action":"activate_model"}',
  ),

  "media:3d_stack_carousel": WidgetDefinition(
    builder: (context, props) => StreamingStackCarousel(props: props),
    description:
        "A premium 3D stacked card carousel with depth perspective scaling and horizontal swipe navigation.",
    properties: {
      "items":
          "List<Map> (each item has title, description, and optional color HEX)",
    },
    jsonExample:
        '{"namespace":"media:3d_stack_carousel","items":[{"title":"Creative Assistant","description":"Generate creative story concepts, visuals, and dynamic character arcs instantly.","color":"#E0F2FE"},{"title":"Technical Analyzer","description":"Deep-dive codebase logic, run unit tests, and resolve security vulnerabilities.","color":"#F3E8FF"},{"title":"Financial Strategist","description":"Forecast business revenue models, track expenses, and chart growth trends.","color":"#ECFDF5"}]}',
  ),

  "core:icon_button_row": WidgetDefinition(
    builder: (context, props) => StreamingIconButtonRow(props: props),
    description:
        "A horizontal row toolbar of sequentially revealing tactile icon buttons.",
    properties: {
      "buttons": "List<Map> (each map has icon, label, and action key)",
    },
    jsonExample:
        '{"namespace":"core:icon_button_row","buttons":[{"icon":"edit","label":"Edit Record","action":"edit_row"},{"icon":"share","label":"Share Flow","action":"share_row"},{"icon":"favorite","label":"Like Item","action":"like_row"}]}',
  ),

  "core:destructive_action_button": WidgetDefinition(
    builder: (context, props) => StreamingDestructiveActionButton(props: props),
    description:
        "A secure confirmation-hold operation button for sensitive destructive commands.",
    properties: {
      "label": "String (text label showing inside button)",
      "action": "String (the command key triggered after holding 2 seconds)",
    },
    jsonExample:
        '{"namespace":"core:destructive_action_button","label":"Destroy Master Cluster","action":"terminate_cluster"}',
  ),

  "media:expanding_accordion_carousel": WidgetDefinition(
    builder: (context, props) =>
        StreamingExpandingAccordionCarousel(props: props),
    description:
        "A responsive side-by-side vertical accordion panel column slider.",
    properties: {
      "items":
          "List<Map> (each map has title, description, and optional color HEX)",
    },
    jsonExample:
        '{"namespace":"media:expanding_accordion_carousel","items":[{"title":"Security Shield","description":"Enterprise grade automated guardrails.","color":"#FEF2F2"},{"title":"Performance Peak","description":"High-throughput asynchronous scaling.","color":"#EFF6FF"}]}',
  ),

  "media:split_screen_carousel": WidgetDefinition(
    builder: (context, props) => StreamingSplitScreenCarousel(props: props),
    description:
        "A dual-viewport card showing sliding images alongside synchronized text panels.",
    properties: {
      "slides": "List<Map> (each slide contains image, title, and description)",
    },
    jsonExample:
        '{"namespace":"media:split_screen_carousel","slides":[{"image":"https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800","title":"Neural Synapse","description":"Mapping multi-dimensional connections."},{"image":"https://images.unsplash.com/photo-1604871000636-074fa5117945?w=800","title":"Quantum Matrix","description":"Decoding superposition logic gates."}]}',
  ),

  "ui:stepper_counter": WidgetDefinition(
    builder: (context, props) => StreamingStepperCounter(props: props),
    description:
        "A capsule numeric selector containing minus and plus bounds controllers.",
    properties: {
      "label": "String (title caption label)",
      "value": "Num (initial value)",
      "min": "Num (minimum boundary limit)",
      "max": "Num (maximum boundary limit)",
      "action": "String (action key triggered on change)",
    },
    jsonExample:
        '{"namespace":"ui:stepper_counter","label":"Server Allocations","value":3,"min":1,"max":10,"action":"change_servers"}',
  ),

  "ui:timeline_stepper": WidgetDefinition(
    builder: (context, props) => StreamingTimelineStepper(props: props),
    description:
        "A horizontal timeline milestones tracker indicating task progress.",
    properties: {
      "steps":
          "List<Map> (each step has label and status: complete, active, pending)",
    },
    jsonExample:
        '{"namespace":"ui:timeline_stepper","steps":[{"label":"Init","status":"complete"},{"label":"Deploy","status":"active"},{"label":"Verify","status":"pending"}]}',
  ),

  "ui:stats_grid": WidgetDefinition(
    builder: (context, props) => StreamingStatsGrid(props: props),
    description:
        "A grid dashboard displaying rich analytics cards with micro-sparklines.",
    properties: {
      "metrics":
          "List<Map> (each metric has label, value, trend, and sparkline list)",
    },
    jsonExample:
        '{"namespace":"ui:stats_grid","metrics":[{"label":"API Calls","value":"89.4k","trend":"+22.4% vs yesterday","sparkline":[12,24,19,30,45]},{"label":"Error Rate","value":"0.04%","trend":"-5.2% vs yesterday","sparkline":[8,6,7,4,2]}]}',
  ),

  "doc:log_streamer": WidgetDefinition(
    builder: (context, props) => StreamingLogStreamer(props: props),
    description:
        "A terminal console log viewer emulator with active blinking cursors.",
    properties: {
      "logs": "List<String> (ordered list of string terminal outputs)",
    },
    jsonExample:
        '{"namespace":"doc:log_streamer","logs":["[SYSTEM] Initiating server sync...","[INFO] Establishing SSL handshake...","[SUCCESS] Sync sequence completed in 142ms."]}',
  ),

  "doc:voice_visualizer": WidgetDefinition(
    builder: (context, props) => StreamingVoiceVisualizer(props: props),
    description:
        "An animated voice audio waveform card expressing listening state.",
    properties: {
      "label": "String (listening status message)",
      "active": "Bool (wave pulse trigger)",
    },
    jsonExample:
        '{"namespace":"doc:voice_visualizer","label":"Analyzing voice patterns...","active":true}',
  ),

  "weather:forecast_card": WidgetDefinition(
    builder: (context, props) => StreamingWeatherCard(props: props),
    description:
        "A premium glassmorphic weather card with condition-based gradients and forecasts.",
    properties: {
      "cityName": "String (the name of the city)",
      "temperature": "String (the current temperature, e.g. 24°C)",
      "condition": "String (sunny, rainy, cloudy, snowy)",
      "humidity": "String (the humidity, e.g. 64%)",
      "windSpeed": "String (the wind speed, e.g. 12 km/h)",
      "forecast": "List<Map> (3-day forecast items with day, temp, condition)",
    },
    jsonExample:
        '{"namespace":"weather:forecast_card","cityName":"Paris","temperature":"22°C","condition":"cloudy","humidity":"58%","windSpeed":"14 km/h","forecast":[{"day":"Mon","temp":"24°C","condition":"sunny"},{"day":"Tue","temp":"21°C","condition":"rainy"}]}',
  ),

  "ecommerce:product_card": WidgetDefinition(
    builder: (context, props) => StreamingProductCard(props: props),
    description:
        "A premium product showcase tile with shimmers and rating stars.",
    properties: {
      "title": "String (the name of the product)",
      "description": "String (the item description)",
      "price": "String (price string, e.g. \$999)",
      "imageUrl": "String (URL to product image)",
      "rating": "Num (average rating 1.0-5.0)",
      "action": "String (action key triggered on click)",
    },
    jsonExample:
        '{"namespace":"ecommerce:product_card","title":"Precision Chrono","description":"Classic styling with premium mechanical accuracy.","price":"\$249","imageUrl":"https://dummyjson.com/images/watch.jpg","rating":4.7,"action":"buy_chrono"}',
  ),

  "crypto:price_card": WidgetDefinition(
    builder: (context, props) => StreamingCryptoCard(props: props),
    description:
        "A premium dark glassmorphic cryptocurrency ticker card with trend badges and an inline CustomPainter sparkline.",
    properties: {
      "symbol": "String (coin symbol, e.g. BTC, ETH, SOL)",
      "name": "String (full name of the coin, e.g. Bitcoin)",
      "price": "String (formatted current price, e.g. \$63,245.20)",
      "change24h":
          "String (percentage change with sign, e.g. +2.51% or -1.42%)",
      "isPositive":
          "Bool (true if the price change is positive, false otherwise)",
      "high24h": "String (optional high price string)",
      "low24h": "String (optional low price string)",
      "sparkline": "List<Double> (numeric list of 24h rolling price trends)",
    },
    jsonExample:
        '{"namespace":"crypto:price_card","symbol":"BTC","name":"Bitcoin","price":"\$63,245.20","change24h":"+2.51%","isPositive":true,"high24h":"\$64,100","low24h":"\$62,800","sparkline":[62.8,63.1,62.9,63.4,64.1,63.2]}',
  ),
};
