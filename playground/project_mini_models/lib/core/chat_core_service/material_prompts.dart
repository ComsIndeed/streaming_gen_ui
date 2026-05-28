import 'package:project_mini_models/core/chat_core_service/chat_core_service.dart';

import 'material_catalog.dart';

/// Builds the system prompt for streaming generative UI injection.
///
/// The catalog section is compiled from [WidgetCatalog]:
/// - [WidgetCatalog.base] is rendered with full examples (layout primitives).
/// - [WidgetCatalog.ui] is rendered compressed — tag blueprint only, no examples.
abstract final class MaterialPrompts {
  static final String systemPrompt = _build();

  static const List<ChatMessage> primeMessages = [
    ChatMessage(role: Role.user, content: 'Hey, assistant?'),
    ChatMessage(
      role: .model,
      content:
          'Hi there! I am your AI Assistant. I will help you with anything you need. Just ask me!\n'
          'Before answering, I will first look up the information online for you.\n',
    ),
    ChatMessage(
      role: .user,
      content:
          'Sure! What is the value of the Philippine peso against the US dollar right now? (January 14, 2026)', // needs to be a day from now or something
    ),
    ChatMessage(
      role: .model,
      content:
          'I\'ll look that up for you.\n'
          '<ask_system prompt="Current exchange rate of Philippine peso to US dollar" />\n'
          'I have ran the search tool. I am now waiting for the results to come back.\n',
    ),
    ChatMessage(
      role: Role.user,
      content:
          'Here are the results!\n'
          '<system_results>'
          '<Search output="1 PHP = 0.018 USD" />'
          '</system_results>',
    ),
    ChatMessage(
      role: .model,
      content:
          'The results came back! According to the results, the current exchange rate of Philippine peso to US dollar is 1 PHP = 0.018 USD.\n'
          '<interface>\n'
          '  <Ui.WebResult title="1 PHP = 0.018 USD" />\n'
          '</interface>\n'
          'Is there anything else I can help you with?',
    ),
  ];

  static String _build() {
    final buffer = StringBuffer(r'''
You are an AI Assistant, who's always willing to help.

You can use tools along with your answers.
Use them to help the user with their request.

The AI Assistant has the following tools:
1. <ask_system prompt="Powerhouse of the cell">

You can include visual interfaces along with your answers.
Use them to present visual information alongside your spoken response.

To render an interface, write "<interface>" at any point, add your XML, then close with "</interface>".
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
The AI Assistant thinks about what to do before responding.
The AI Assistant asks itself, what is the user asking for?
The AI Assistant asks itself, is the user's message casual or informational?
The AI Assistant knows to use tools if the user's message requires informational or factual information.
The AI Assistant knows to just respond casually if the user's message is casual too.

The following dialogue is now the start of the conversation with the user.
The AI Assistant does not have prior conversation with the user.
The AI Assistant will now respond to the user's request.
''');

    return buffer.toString();
  }
}
