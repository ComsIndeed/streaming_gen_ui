import 'package:streaming_gen_ui/src/models/widget_registry.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/core_registry.dart';

/// Central catalog class for built-in registries. Exposes overhauled
/// segmented widget sets, aesthetic sub-themes, and composition operators (+).
class Registries {
  /// The 10 Core Primitive building blocks (low token footprint, high flexibility).
  static WidgetRegistry get primitives => WidgetRegistry(
    widgets: {
      "core:text": coreRegistry["core:text"]!,
      "core:icon": coreRegistry["core:icon"]!,
      "core:media": coreRegistry["core:media"]!,
      "core:markdown": coreRegistry["core:markdown"]!,
      "core:button": coreRegistry["core:button"]!,
      "core:container": coreRegistry["core:container"]!,
      "core:column": coreRegistry["core:column"]!,
      "core:row": coreRegistry["core:row"]!,
      "core:textfield": coreRegistry["core:textfield"]!,
      "core:slider": coreRegistry["core:slider"]!,
    },
  );

  /// Stateful core extended interaction and progressive stepper layouts.
  static WidgetRegistry get extended => WidgetRegistry(
    widgets: {
      "core_extended:icon_button": coreRegistry["core_extended:icon_button"]!,
      "core_extended:text_button": coreRegistry["core_extended:text_button"]!,
      "core_extended:progression_bar":
          coreRegistry["core_extended:progression_bar"]!,
      "core_extended:progression_circle":
          coreRegistry["core_extended:progression_circle"]!,
      "core_extended:stepper": coreRegistry["core_extended:stepper"]!,
    },
  );

  // ==========================================
  // AESTHETIC THEME REGISTRIES
  // ==========================================

  /// Material 3 aesthetic UI widget set.
  static WidgetRegistry get material => _themeRegistry('material');

  /// Windows 11 Fluent aesthetic UI widget set.
  static WidgetRegistry get fluent => _themeRegistry('fluent');

  /// Apple iOS/macOS Squircle aesthetic UI widget set.
  static WidgetRegistry get apple => _themeRegistry('apple');

  /// Frost-blurred Glassmorphism aesthetic UI widget set.
  static WidgetRegistry get glassmorphic => _themeRegistry('glassmorphic');

  /// Soft tactile shadow Neumorphism aesthetic UI widget set.
  static WidgetRegistry get neumorphic => _themeRegistry('neumorphic');

  /// Realistic texture Skeuomorphism aesthetic UI widget set.
  static WidgetRegistry get skeumorphic => _themeRegistry('skeumorphic');

  /// Flat high-contrast Pop-Art Brutalist aesthetic UI widget set.
  static WidgetRegistry get brutalist => _themeRegistry('brutalist');

  /// Dynamic helper to extract a theme's widget set.
  static WidgetRegistry _themeRegistry(String theme) {
    return WidgetRegistry(
      widgets: {
        "${theme}_ui:card": coreRegistry["${theme}_ui:card"]!,
        "${theme}_ui:user_profile": coreRegistry["${theme}_ui:user_profile"]!,
        "${theme}_ui:carousel": coreRegistry["${theme}_ui:carousel"]!,
        "${theme}_ui:weather": coreRegistry["${theme}_ui:weather"]!,
        "${theme}_ui:graph": coreRegistry["${theme}_ui:graph"]!,
        "${theme}_ui:web_result": coreRegistry["${theme}_ui:web_result"]!,
        "${theme}_ui:product_result":
            coreRegistry["${theme}_ui:product_result"]!,
        "${theme}_ui:location": coreRegistry["${theme}_ui:location"]!,
        "${theme}_ui:list_results": coreRegistry["${theme}_ui:list_results"]!,
        "${theme}_ui:todo_list": coreRegistry["${theme}_ui:todo_list"]!,
        "${theme}_ui:note": coreRegistry["${theme}_ui:note"]!,
        "${theme}_ui:comparison": coreRegistry["${theme}_ui:comparison"]!,
      },
    );
  }

  // ==========================================
  // COMPOSED SUPER-BUNDLES
  // ==========================================

  /// The master bundle containing the entire overhauled generative widget catalog.
  static WidgetRegistry get all {
    final Map<String, WidgetDefinition> allWidgets = {};
    allWidgets.addAll(primitives.widgets);
    allWidgets.addAll(extended.widgets);
    for (final theme in [
      'material',
      'fluent',
      'apple',
      'glassmorphic',
      'neumorphic',
      'skeumorphic',
      'brutalist',
    ]) {
      allWidgets.addAll(_themeRegistry(theme).widgets);
    }
    return WidgetRegistry(widgets: allWidgets);
  }

  /// Builds a registry from a specific set of theme IDs.
  /// Optionally includes core primitives and core_extended widgets.
  static WidgetRegistry forThemes(
    Set<String> themes, {
    bool includePrimitives = false,
  }) {
    final Map<String, WidgetDefinition> widgets = {};
    if (includePrimitives) {
      widgets.addAll(primitives.widgets);
      widgets.addAll(extended.widgets);
    }
    for (final theme in themes) {
      widgets.addAll(_themeRegistry(theme).widgets);
    }
    return WidgetRegistry(widgets: widgets);
  }

  // ==========================================
  // BACKWARDS-COMPATIBILITY ALIASES
  // ==========================================

  /// Retro layout components mapping to primitives.
  static WidgetRegistry get layout => WidgetRegistry(
    widgets: {
      "core:column": coreRegistry["core:column"]!,
      "core:row": coreRegistry["core:row"]!,
      "core:container": coreRegistry["core:container"]!,
    },
  );

  /// The master catalog alias.
  static WidgetRegistry get core => all;

  /// Retro essentials layout block.
  static WidgetRegistry get essentials =>
      layout +
      WidgetRegistry(widgets: {"core:text": coreRegistry["core:text"]!});
}
