import 'package:streaming_gen_ui/src/models/widget_registry.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/core_registry.dart';

/// Central catalog class for built-in registries. Exposes highly segmented
/// widget sets and supports dynamic union (+) composition.
class Registries {
  /// Just the raw building blocks. High token cost, maximum flexibility.
  static WidgetRegistry get primitives => WidgetRegistry(widgets: {
    "core:box": coreRegistry["core:box"]!,
    "core:flex": coreRegistry["core:flex"]!,
    "core:text": coreRegistry["core:text"]!,
    "core:column": coreRegistry["core:column"]!,
    "core:row": coreRegistry["core:row"]!,
    "core:container": coreRegistry["core:container"]!,
    "core:badge": coreRegistry["core:badge"]!,
  });

  /// Stateful user interaction widgets (Button, TextField)
  static WidgetRegistry get interactive => WidgetRegistry(
    widgets: {
      "core:elevated_button": coreRegistry["core:elevated_button"]!,
      "core:textfield": coreRegistry["core:textfield"]!,
    },
  );

  /// The daily drivers. Fast streaming, beautiful defaults.
  static WidgetRegistry get standardCards => WidgetRegistry(widgets: {
    "ui:bento_card": coreRegistry["ui:bento_card"]!,
    "ui:list_tile": coreRegistry["ui:list_tile"]!,
    "ui:key_value_row": coreRegistry["ui:key_value_row"]!,
  });

  /// For chat reasoning timelines and code terminals.
  static WidgetRegistry get documents => WidgetRegistry(widgets: {
    "doc:terminal": coreRegistry["doc:terminal"]!,
    "doc:agent_stepper": coreRegistry["doc:agent_stepper"]!,
  });

  /// For dashboards, big numbers, and spreadsheets.
  static WidgetRegistry get metrics => WidgetRegistry(widgets: {
    "dash:metric": coreRegistry["dash:metric"]!,
    "dash:data_table": coreRegistry["dash:data_table"]!,
  });

  // ==========================================
  // COMPOSED SUPER-BUNDLES
  // ==========================================

  /// Perfect for a standard ChatGPT-style clone.
  static WidgetRegistry get chatApp =>
      documents +
      standardCards +
      primitives.only(["core:text", "core:badge"]);

  /// Perfect for an AI admin panel or dashboard tracker.
  static WidgetRegistry get dashboard =>
      metrics +
      standardCards +
      primitives.only(["core:box", "core:flex"]);

  /// Gives the model the entire widget ecosystem.
  static WidgetRegistry get all =>
      primitives +
      interactive +
      standardCards +
      documents +
      metrics;

  // ==========================================
  // RETRO-COMPATIBILITY ALIASES
  // ==========================================

  /// Base layout components (Column, Row, Container)
  static WidgetRegistry get layout => WidgetRegistry(
    widgets: {
      "core:column": coreRegistry["core:column"]!,
      "core:row": coreRegistry["core:row"]!,
      "core:container": coreRegistry["core:container"]!,
    },
  );

  /// The master collection of all standard built-in widgets.
  static WidgetRegistry get core => all;

  /// Composed Essentials bundle.
  static WidgetRegistry get essentials =>
      layout +
      WidgetRegistry(widgets: {"core:text": coreRegistry["core:text"]!});
}
