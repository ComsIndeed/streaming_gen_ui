import 'package:streaming_gen_ui/src/models/widget_registry.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/core_registry.dart';

/// Central catalog class for built-in registries. Exposes highly segmented
/// widget sets and supports dynamic union (+) composition.
class Registries {
  /// The master collection of all standard built-in widgets.
  static WidgetRegistry get core => WidgetRegistry(widgets: coreRegistry);

  /// Base layout components (Column, Row, Container)
  static WidgetRegistry get layout => WidgetRegistry(
    widgets: {
      "core:column": coreRegistry["core:column"]!,
      "core:row": coreRegistry["core:row"]!,
      "core:container": coreRegistry["core:container"]!,
    },
  );

  /// Stateful user interaction widgets (Button, TextField)
  static WidgetRegistry get interactive => WidgetRegistry(
    widgets: {
      "core:elevated_button": coreRegistry["core:elevated_button"]!,
      "core:textfield": coreRegistry["core:textfield"]!,
    },
  );

  /// The default go-to essentials package (Layout + Text typography)
  /// Composed dynamically by combining the Layout registry and the core Text widget
  static WidgetRegistry get essentials =>
      layout +
      WidgetRegistry(widgets: {"core:text": coreRegistry["core:text"]!});
}
