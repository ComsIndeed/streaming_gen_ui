import 'package:flutter/widgets.dart';
import 'package:llm_json_stream/llm_json_stream.dart';

typedef WidgetBuilderFunction =
    Widget Function(BuildContext context, PropertyStream props);

class WidgetDefinition {
  final WidgetBuilderFunction builder;
  final String description;
  final Map<String, String> properties;
  final String jsonExample;

  const WidgetDefinition({
    required this.builder,
    required this.description,
    this.properties = const {},
    this.jsonExample = '',
  });
}

class WidgetRegistry {
  final Map<String, WidgetDefinition> widgets;

  WidgetRegistry({required Map<String, WidgetDefinition> widgets})
    : widgets = widgets.map((id, def) {
        if (def.jsonExample.isEmpty) {
          return MapEntry(
            id,
            WidgetDefinition(
              builder: def.builder,
              description: def.description,
              properties: def.properties,
              jsonExample: _generateDefaultJsonExample(id, def.properties),
            ),
          );
        }
        return MapEntry(id, def);
      });

  /// Creates a registry containing a single widget definition inline.
  factory WidgetRegistry.fromDefinition({
    required String id,
    required String description,
    Map<String, String> properties = const {},
    String jsonExample = '',
    required WidgetBuilderFunction builder,
  }) {
    return WidgetRegistry(
      widgets: {
        id: WidgetDefinition(
          builder: builder,
          description: description,
          properties: properties,
          jsonExample: jsonExample,
        ),
      },
    );
  }

  /// ➕ Union Operator: Merge two registries together seamlessly.
  WidgetRegistry operator +(WidgetRegistry other) {
    return WidgetRegistry(widgets: {...widgets, ...other.widgets});
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

  static String _generateDefaultJsonExample(
    String namespace,
    Map<String, String> properties,
  ) {
    final buffer = StringBuffer();
    buffer.write('{"namespace":"$namespace"');
    for (final entry in properties.entries) {
      final key = entry.key.toLowerCase();
      final rawKey = entry.key;
      final typeDesc = entry.value.toLowerCase();

      String mockValue;

      // Check type descriptions first for collections/booleans
      if (typeDesc.contains('list')) {
        mockValue = '[]';
      } else if (typeDesc.contains('map') || typeDesc.contains('component')) {
        mockValue = '{}';
      } else if (typeDesc.contains('bool')) {
        mockValue = 'true';
      } else if (typeDesc.contains('int') ||
          typeDesc.contains('num') ||
          typeDesc.contains('double') ||
          typeDesc.contains('float')) {
        if (key.contains('rating') || key.contains('score')) {
          mockValue = '4.8';
        } else if (key.contains('price') ||
            key.contains('cost') ||
            key.contains('amount')) {
          mockValue = '99.99';
        } else if (key.contains('progress') ||
            key.contains('ratio') ||
            key.contains('percent')) {
          mockValue = '0.75';
        } else if (key.contains('width') ||
            key.contains('height') ||
            key.contains('size') ||
            key.contains('radius')) {
          mockValue = '150';
        } else {
          mockValue = '42';
        }
      } else {
        if (key.contains('url') ||
            key.contains('image') ||
            key.contains('photo') ||
            key.contains('avatar')) {
          mockValue = '"https://example.com/image.png"';
        } else if (key.contains('email')) {
          mockValue = '"user@example.com"';
        } else if (key.contains('title') ||
            key.contains('header') ||
            key.contains('subject')) {
          mockValue = '"Discover Premium Design"';
        } else if (key.contains('subtitle') || key.contains('caption')) {
          mockValue = '"A next-generation user experience"';
        } else if (key.contains('description') ||
            key.contains('bio') ||
            key.contains('content') ||
            key.contains('text')) {
          mockValue =
              '"This is a beautiful, interactive card component built with streaming_gen_ui."';
        } else if (key.contains('name') ||
            key.contains('author') ||
            key.contains('user')) {
          mockValue = '"John Doe"';
        } else if (key.contains('status') ||
            key.contains('badge') ||
            key.contains('state')) {
          mockValue = '"active"';
        } else if (key.contains('color') || key.contains('hex')) {
          mockValue = '"#ff0055"';
        } else if (key.contains('date') || key.contains('time')) {
          mockValue = '"Just Now"';
        } else if (key.contains('action') ||
            key.contains('callback') ||
            key.contains('event')) {
          mockValue = '"submit_event"';
        } else {
          mockValue = '"example_$rawKey"';
        }
      }
      buffer.write(',"$rawKey":$mockValue');
    }
    buffer.write('}');
    return buffer.toString();
  }

  String get systemPromptFragment {
    final catalog = widgets.entries
        .map((entry) {
          final key = entry.key;
          final def = entry.value;

          final propsList = def.properties.isEmpty
              ? '  * None'
              : def.properties.entries
                    .map((p) => '  * `${p.key}`: ${p.value}')
                    .join('\n');

          final example = def.jsonExample;

          return '''
#### Component: `$key`
* **Description:** ${def.description}
* **Properties:**
$propsList
* **Example JSON:** `<interface>$example</interface>`''';
        })
        .join('\n\n');

    return '''
You can mix standard conversational text with rich, interactive UI components.

### 1. Tag Wrapping Rule
When you decide to render an interactive UI component, write the component's exact JSON definition inside an `<interface>...</interface>` tag block.
All conversational text must be written outside the tags.
* Never use markdown code blocks (like ```json) inside the tags. Write only raw, compact JSON.
* You can place multiple `<interface>` tags in a single response.

### 2. Component Catalog
You have access to the following component namespace identifiers and their schemas:

$catalog

### 3. Visual & Styling Consistency (Theme Adaptability)
To guarantee optimal readability and visual harmony (e.g. avoiding bright blinding colors on dark mode or unreadable low contrast text), the host application automatically adjusts/tints dynamic color parameters (like background colors, borders, and icon colors) to match the active system brightness (dark/light theme).
* This applies to widgets utilizing colors, including `media:expanding_accordion_carousel`, `media:3d_stack_carousel`, `core:bento_card`, `core:list_tile`, `core:progress_ring`, `ui:stepper_counter`, `core:alert`, etc.
* **If you explicitly need the absolute, exact color to render exactly as specified** without background darkening or text lightening adjustments, set `"exactColor": true` (optional boolean) in the widget's properties.
'''
        .trim();
  }
}
