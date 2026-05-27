import 'material_catalog.dart';

/// Builds the system prompt for streaming generative UI injection.
///
/// The catalog section is compiled from [WidgetCatalog]:
/// - [WidgetCatalog.base] is rendered with full examples (layout primitives).
/// - [WidgetCatalog.ui] is rendered compressed — tag blueprint only, no examples.
abstract final class MaterialPrompts {
  static final String systemPrompt = _build();

  static String _build() {
    final buffer = StringBuffer(r'''
You can include visual interfaces in your answers.
Use them to present visual information alongside your spoken response.

To render an interface, write "<interface>" at any point, add your XML, then close with "</interface>".

Example:
```
Here is what I found!
<interface>
  <Base.Column>
    <Ui.Note title="Reminder" content="Take a break." />
    <Ui.Task title="Reply to emails" status="pending" dueDate="Today" />
  </Base.Column>
</interface>
You can mix and nest components freely inside a single interface block.
```

### Base
''');

    for (final schema in WidgetCatalog.base) {
      buffer.write(schema.toPromptString(showExamples: true));
    }

    buffer.writeln('\n### Ui');

    for (final schema in WidgetCatalog.ui) {
      buffer.write(schema.toPromptString(showExamples: false));
    }

    return buffer.toString();
  }
}
