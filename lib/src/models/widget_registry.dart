import 'package:flutter/widgets.dart';
import 'package:llm_json_stream/llm_json_stream.dart';

typedef WidgetBuilderFunction = Widget Function(BuildContext context, PropertyStream props);

class WidgetDefinition {
  final WidgetBuilderFunction builder;
  final String description;
  final Map<String, String> properties;
  final String jsonExample;

  const WidgetDefinition({
    required this.builder,
    required this.description,
    required this.properties,
    required this.jsonExample,
  });
}

class WidgetRegistry {
  final Map<String, WidgetDefinition> widgets;

  WidgetRegistry({required this.widgets});

  /// ➕ Union Operator: Merge two registries together seamlessly.
  WidgetRegistry operator +(WidgetRegistry other) {
    return WidgetRegistry(widgets: {
      ...widgets,
      ...other.widgets,
    });
  }

  /// 🎯 Subset Filter: Derive a new registry containing only selected IDs.
  WidgetRegistry only(List<String> ids) {
    final filtered = <String, WidgetDefinition>{};
    for (final id in ids) {
      if (widgets.containsKey(id)) {
        filtered[id] = widgets[id]!;
      }
    }
    return WidgetRegistry(widgets: filtered);
  }

  /// ➖ Subtraction: Derive a new registry excluding selected IDs.
  WidgetRegistry without(List<String> ids) {
    final filtered = Map<String, WidgetDefinition>.from(widgets);
    for (final id in ids) {
      filtered.remove(id);
    }
    return WidgetRegistry(widgets: filtered);
  }

  String get systemPromptFragment {
    final catalog = widgets.entries.map((entry) {
      final key = entry.key;
      final def = entry.value;

      final propsList = def.properties.isEmpty
          ? '  * None'
          : def.properties.entries.map((p) => '  * `${p.key}`: ${p.value}').join('\n');

      return '''
#### Component: `$key`
* **Description:** ${def.description}
* **Properties:**
$propsList
* **Example JSON:** `<interface>${def.jsonExample}</interface>`''';
    }).join('\n\n');

    return '''
You are a real-time Generative UI assistant. You can mix standard conversational text with rich, interactive UI components.

### 1. Tag Wrapping Rule
When you decide to render an interactive UI component, write the component's exact JSON definition inside an `<interface>...</interface>` tag block.
All conversational text must be written outside the tags.
* Never use markdown code blocks (like ```json) inside the tags. Write only raw, compact JSON.
* You can place multiple `<interface>` tags in a single response.

### 2. Component Catalog
You have access to the following component namespace identifiers and their schemas:

$catalog
'''.trim();
  }
}
