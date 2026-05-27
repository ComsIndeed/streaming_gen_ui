import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';

void main() {
  group('WidgetRegistry.fromDefinition', () {
    test('creates a valid registry with a single widget', () {
      final registry = WidgetRegistry.fromDefinition(
        id: 'custom:avatar',
        description: 'A circular profile avatar.',
        properties: {
          'imageUrl': 'String - image path',
          'radius': 'double - avatar size',
        },
        builder: (context, props) => CircleAvatar(
          child: StreamingText(
            props: props,
            propertyName: 'imageUrl',
          ),
        ),
      );

      expect(registry.widgets.containsKey('custom:avatar'), isTrue);
      final def = registry.widgets['custom:avatar']!;
      expect(def.description, equals('A circular profile avatar.'));
      expect(def.properties['imageUrl'], equals('String - image path'));
      expect(def.properties['radius'], equals('double - avatar size'));
    });

    test('generates mock JSON correctly when omitted', () {
      final registry = WidgetRegistry.fromDefinition(
        id: 'custom:product_tile',
        description: 'Displays a product.',
        properties: {
          'title': 'String',
          'price': 'double',
          'rating': 'double',
          'imageUrl': 'String',
          'isFavorite': 'bool',
        },
        builder: (context, props) => const SizedBox(),
      );

      final def = registry.widgets['custom:product_tile']!;
      expect(def.jsonExample, isNotEmpty);
      expect(def.jsonExample.contains('custom:product_tile'), isTrue);
      expect(def.jsonExample.contains('title'), isTrue);
      expect(def.jsonExample.contains('price'), isTrue);
      expect(def.jsonExample.contains('rating'), isTrue);
      expect(def.jsonExample.contains('imageUrl'), isTrue);
      expect(def.jsonExample.contains('isFavorite'), isTrue);
    });

    test('accepts optional empty properties and generates generic JSON example', () {
      final registry = WidgetRegistry.fromDefinition(
        id: 'custom:simple',
        description: 'No properties required',
        builder: (context, props) => const SizedBox(),
      );

      final def = registry.widgets['custom:simple']!;
      expect(def.properties, isEmpty);
      expect(def.jsonExample, equals('{"namespace":"custom:simple"}'));
    });
  });

  group('Intelligent Default Mock-JSON Generator', () {
    test('infers types correctly from key names', () {
      final registry = WidgetRegistry.fromDefinition(
        id: 'custom:mock_test',
        description: 'Test mock values',
        properties: {
          'url': 'String',
          'avatar': 'String',
          'rating': 'double',
          'score': 'double',
          'count': 'int',
          'total': 'int',
          'amount': 'double',
          'price': 'double',
          'isFavorite': 'bool',
          'active': 'bool',
          'enabled': 'bool',
          'title': 'String',
          'description': 'String',
          'content': 'String',
          'name': 'String',
          'user': 'String',
          'status': 'String',
          'badge': 'String',
          'color': 'String',
          'hex': 'String',
          'date': 'String',
          'time': 'String',
          'action': 'String',
          'otherGeneric': 'String',
        },
        builder: (context, props) => const SizedBox(),
      );

      final jsonStr = registry.widgets['custom:mock_test']!.jsonExample;
      
      // Verify expected field types and formats in generated JSON
      expect(jsonStr.contains('"url":"https://example.com/image.png"'), isTrue);
      expect(jsonStr.contains('"avatar":"https://example.com/image.png"'), isTrue);
      expect(jsonStr.contains('"rating":4.8'), isTrue);
      expect(jsonStr.contains('"score":4.8'), isTrue);
      expect(jsonStr.contains('"count":42'), isTrue);
      expect(jsonStr.contains('"total":42'), isTrue);
      expect(jsonStr.contains('"amount":99.99'), isTrue);
      expect(jsonStr.contains('"price":99.99'), isTrue);
      expect(jsonStr.contains('"isFavorite":true'), isTrue);
      expect(jsonStr.contains('"active":true'), isTrue);
      expect(jsonStr.contains('"enabled":true'), isTrue);
      expect(jsonStr.contains('"title":"Discover Premium Design"'), isTrue);
      expect(jsonStr.contains('"description":"This is a beautiful, interactive card component built with streaming_gen_ui."'), isTrue);
      expect(jsonStr.contains('"content":"This is a beautiful, interactive card component built with streaming_gen_ui."'), isTrue);
      expect(jsonStr.contains('"name":"John Doe"'), isTrue);
      expect(jsonStr.contains('"user":"John Doe"'), isTrue);
      expect(jsonStr.contains('"status":"active"'), isTrue);
      expect(jsonStr.contains('"badge":"active"'), isTrue);
      expect(jsonStr.contains('"color":"#ff0055"'), isTrue);
      expect(jsonStr.contains('"hex":"#ff0055"'), isTrue);
      expect(jsonStr.contains('"date":"Just Now"'), isTrue);
      expect(jsonStr.contains('"time":"Just Now"'), isTrue);
      expect(jsonStr.contains('"action":"submit_event"'), isTrue);
      expect(jsonStr.contains('"otherGeneric":"example_otherGeneric"'), isTrue);
    });
  });

  group('StreamingGenerativeUi List-based Composition', () {
    test('instantiates successfully with a list of registries', () {
      final reg1 = WidgetRegistry.fromDefinition(
        id: 'custom:w1',
        description: 'Widget 1',
        builder: (context, props) => const SizedBox(),
      );

      final reg2 = WidgetRegistry.fromDefinition(
        id: 'custom:w2',
        description: 'Widget 2',
        builder: (context, props) => const SizedBox(),
      );

      final genUi = StreamingGenerativeUi(registries: [reg1, reg2]);

      expect(genUi.registry.widgets.containsKey('custom:w1'), isTrue);
      expect(genUi.registry.widgets.containsKey('custom:w2'), isTrue);
    });

    test('supports updateRegistries and hot-swaps active components', () {
      final reg1 = WidgetRegistry.fromDefinition(
        id: 'custom:w1',
        description: 'Widget 1',
        builder: (context, props) => const SizedBox(),
      );

      final genUi = StreamingGenerativeUi(registries: [reg1]);
      expect(genUi.registry.widgets.containsKey('custom:w1'), isTrue);
      expect(genUi.registry.widgets.containsKey('custom:w2'), isFalse);

      final reg2 = WidgetRegistry.fromDefinition(
        id: 'custom:w2',
        description: 'Widget 2',
        builder: (context, props) => const SizedBox(),
      );

      genUi.updateRegistries([reg2]);
      expect(genUi.registry.widgets.containsKey('custom:w1'), isFalse);
      expect(genUi.registry.widgets.containsKey('custom:w2'), isTrue);
    });
  });

  group('StreamingGenerativeUi UI parsing and rendering', () {
    testWidgets('renders subsequent TextBlocks even if WidgetBlock fails to parse JSON', (WidgetTester tester) async {
      final reg = WidgetRegistry.fromDefinition(
        id: 'core:weather',
        description: 'Weather widget',
        properties: {'city': 'String'},
        builder: (context, props) => Container(),
      );

      final genUi = StreamingGenerativeUi(
        registries: [reg],
        showInternalErrors: false,
      );

      final String streamInput =
          'Preamble text\n<interface>\n  <Weather city="Manila" />\n</interface>\nAfter-amble text';

      await genUi.stream(Stream.value(streamInput), viewId: 'test_view');

      // Now build the view
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: genUi.view('test_view'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // We expect to find 'Preamble text' and 'After-amble text' rendered
      expect(find.textContaining('Preamble text'), findsOneWidget);
      expect(find.textContaining('After-amble text'), findsOneWidget);
    });
  });
}

