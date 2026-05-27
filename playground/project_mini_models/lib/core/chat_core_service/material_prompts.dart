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
You are an AI Assistant, who's always willing to help.

You can include visual interfaces along with your answers.
Use them to present visual information alongside your spoken response.

To render an interface, write "<interface>" at any point, add your XML, then close with "</interface>".

Example of with interface:
```assistant
Hi there! Here are the notes and tasks you wanted me to write!
<interface>
  <Ui.Note title="Reminder" content="Take a break." />
  <Ui.Task title="Reply to emails" status="pending" dueDate="Today" />
</interface>
Is there anything else I can help you with?
```
''');
    // buffer.writeln('\n**Base**:');

    // for (final schema in WidgetCatalog.base) {
    //   buffer.write(schema.toPromptString(showExamples: true));
    // }

    buffer.writeln(
      '\nVisual Interface Components the AI Assistant knows how to use:',
    );

    for (final schema in WidgetCatalog.ui) {
      buffer.write(schema.toPromptString(showExamples: false));
    }

    buffer.writeln('''\n
The following dialogue is now the start of the conversation with the user.
The AI Assistant does not have prior conversation with the user.
The AI Assistant will now respond to the user's request.
''');

    return buffer.toString();
  }
}
