import 'dart:convert';
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

// TODO: TEMPORARY SETUP FOR TESTING DUAL-STYLE MIGRATION.
// Antigravity / future agents: This registry modification is a temporary quick solution
// to modify the exported generated system prompt catalog for the purpose of testing the dot-notation
// XML format. It filters the catalog to only show Core, CoreExtended, and MaterialUi widgets,
// and maps their namespaces directly to XML dot-notation tags.
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

  static String toXmlTagName(String id) {
    return id
        .split(':')
        .map((segment) {
          return segment
              .split('_')
              .map((word) {
                if (word.isEmpty) return '';
                if (word == 'ui') return 'Ui';
                return word[0].toUpperCase() + word.substring(1);
              })
              .join('');
        })
        .join('.');
  }

  static String _jsonToXml(dynamic json) {
    if (json is String) {
      try {
        return _jsonToXml(jsonDecode(json));
      } catch (_) {
        return json;
      }
    }
    if (json is! Map) {
      return '';
    }

    final namespace = json['namespace'] as String?;
    if (namespace == null) return '';

    final tagName = toXmlTagName(namespace);
    final attributes = <String>[];
    final children = <String>[];

    for (final entry in json.entries) {
      final key = entry.key;
      final val = entry.value;
      if (key == 'namespace') continue;

      if (val is Map && val.containsKey('namespace')) {
        children.add(_jsonToXml(val));
      } else if (val is List) {
        bool allWidgets = true;
        final listChildren = <String>[];
        for (final item in val) {
          if (item is Map && item.containsKey('namespace')) {
            listChildren.add(_jsonToXml(item));
          } else {
            allWidgets = false;
            break;
          }
        }
        if (allWidgets && listChildren.isNotEmpty) {
          children.addAll(listChildren);
        } else {
          final escapedVal = jsonEncode(val).replaceAll('"', '\\"');
          attributes.add('$key="$escapedVal"');
        }
      } else if (val is String) {
        final escaped = val.replaceAll('\n', '\\n').replaceAll('"', '\\"');
        attributes.add('$key="$escaped"');
      } else {
        attributes.add('$key="$val"');
      }
    }

    final attrStr = attributes.isEmpty ? '' : ' ${attributes.join(' ')}';
    if (children.isEmpty) {
      return '<$tagName$attrStr />';
    } else {
      return '<$tagName$attrStr>${children.join('')}</$tagName>';
    }
  }

  String get systemPromptFragment {
    final catalog = widgets.entries
        .take(2)
        .map((entry) {
          final key = entry.key;
          final def = entry.value;

          final propsList = def.properties.isEmpty
              ? '  * None'
              : def.properties.entries
                    .map((p) => '  * `${p.key}`: ${p.value}')
                    .join('\n');

          final xmlExample = _jsonToXml(def.jsonExample);

          return '''
`<${toXmlTagName(key)} />`
* **Description:** ${def.description}
* **Properties:**
$propsList
* **Example XML:** `<interface>$xmlExample</interface>`''';
        })
        .join('\n\n');

    return '''
You can include visual interfaces into your answers.
Use visual interfaces along with your responses to present visual information to the user.

To start rendering widgets, write "<interface>" at any point, followed by your interface code in XML.
End your interface code by saying "</interface>", and then you can continue with your spoken response.

Example response:
```assistant
This is me speaking. Now, I will show you something!
<interface>
  <MaterialUi.Carousel>
    <MaterialUi.Weather temp="24.5" condition="sunny" location="San Francisco" size="normal">
      <MaterialUi.Forecast day="Mon" temp="25" condition="sunny" />
      <MaterialUi.Forecast day="Tue" temp="23" condition="cloudy" />
    </MaterialUi.Weather>
    <MaterialUi.Weather temp="24.5" condition="sunny" location="Manila" size="normal">
      <MaterialUi.Forecast day="Mon" temp="25" condition="sunny" />
      <MaterialUi.Forecast day="Tue" temp="23" condition="cloudy" />
    </MaterialUi.Weather>
    <MaterialUi.Weather temp="24.5" condition="sunny" location="San Francisco" size="normal">
      <MaterialUi.Forecast day="Mon" temp="25" condition="sunny" />
      <MaterialUi.Forecast day="Tue" temp="23" condition="cloudy" />
    </MaterialUi.Weather>
  </MaterialUi.Carousel>
  <MaterialUi.Note type="note" title="Take a shower" content="Don't forget to take a shower" completed="false" tags="["personal", "reminder"] />
  <MaterialUi.Note type="todo" title="Buy groceries" content="Buy groceries for the week" completed="false" tags="["personal"] />
  <MaterialUi.Note type="reminder" title="Meeting with Bob" content="Meeting with Bob at 3pm" completed="false" tags="["work"] />
</interface>
This is me speaking again. Did that interface I have shown you looked cool? It's got a scrollable carousel with three weather cards, and below the carousel, there are three note cards.
```

$catalog
'''
        .trim();
  }
}
