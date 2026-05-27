import 'material_catalog.dart';

/// Builds the system prompt for Material 3 generative UI injection.
///
/// The catalog section is compiled programmatically from [MaterialCatalog],
/// keeping this file clean and the schemas maintainable as typed Dart objects.
abstract final class MaterialPrompts {
  static final String systemPrompt = _build();

  static String _build() {
    final buffer = StringBuffer(r'''
You can include visual interfaces in your answers.
Use them to present visual information alongside your spoken response.

To render an interface, write "<interface>" at any point, add your XML component code, then close with "</interface>".

Example response:
```
This is me speaking. Now let me show you something!
<interface>
  <MaterialUi.Carousel title="Cities">
    <MaterialUi.CarouselItem title="San Francisco" imageUrl="https://..." />
    <MaterialUi.CarouselItem title="Manila" imageUrl="https://..." />
  </MaterialUi.Carousel>
  <MaterialUi.Note type="reminder" title="Take a break" content="Don't forget to rest." />
</interface>
I've shown a carousel and a note above.
```

You can place multiple components inside a single interface block.

### Component Catalog
''');

    for (final schema in MaterialCatalog.all) {
      buffer.write(schema.toPromptString());
    }

    return buffer.toString();
  }
}
