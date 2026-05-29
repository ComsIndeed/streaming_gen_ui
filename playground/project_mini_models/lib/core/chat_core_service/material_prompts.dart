import 'package:project_mini_models/core/chat_core_service/chat_core_service.dart';

/// Builds the system prompt for streaming generative UI injection.
///
/// The catalog section is compiled from [WidgetCatalog]:
/// - [WidgetCatalog.base] is rendered with full examples (layout primitives).
/// - [WidgetCatalog.ui] is rendered compressed — tag blueprint only, no examples.
abstract final class MaterialPrompts {
  static final String systemPrompt = _build();

  static const List<ChatMessage> primeMessages = [
    ChatMessage(role: Role.user, content: 'Hey, assistant?', isPrimer: true),
    ChatMessage(
      role: .model,
      content:
          'Hi there! I am your AI Assistant. I will help you with anything you need. Just ask me!\n'
          'Before answering, I will first look up the information online for you.\n',
      isPrimer: true,
    ),
    ChatMessage(
      role: .user,
      content:
          'Sure! What is the value of the Philippine peso against the US dollar right now? (January 14, 2026)', // needs to be a day from now or something
      isPrimer: true,
    ),
    ChatMessage(
      role: .model,
      content:
          'I\'ll look that up for you.\n'
          '<ask_system>What is the current exchange rate of Philippine peso to US dollar?</ask_system>\n',
      isPrimer: true,
    ),
    ChatMessage(
      role: Role.user,
      content:
          '<system_results>'
          '<Search output="1 PHP = 0.018 USD" />'
          '</system_results>',
      isPrimer: true,
    ),
    ChatMessage(
      role: .model,
      content:
          'The results came back! According to the results, the current exchange rate of Philippine peso to US dollar is 1 PHP = 0.018 USD.\n'
          '<interface>\n'
          '  <Ui.WebResult title="1 PHP = 0.018 USD" />\n'
          '</interface>\n'
          'Is there anything else I can help you with?',
      isPrimer: true,
    ),

    // THE FOLLOWING ARE TEMPORARY
    ChatMessage(
      role: .user,
      content: 'What about yen to yuan?',
      isPrimer: true,
    ),
    ChatMessage(
      role: .model,
      content:
          'I\'ll look that up for you.\n<ask_system>What is the current exchange rate of Japanese yen to Chinese yuan?</ask_system>',
      isPrimer: true,
    ),
    ChatMessage(
      role: .user,
      content:
          '<system_results>'
          '<Search output="1 JPY = 0.058 CNY" />'
          '</system_results>',
      isPrimer: true,
    ),
    ChatMessage(
      role: .model,
      content:
          'The results came back! According to the results, the current exchange rate of Japanese yen to Chinese yuan is 1 JPY = 0.058 CNY.\n'
          '<interface>\n'
          '  <Ui.WebResult title="1 JPY = 0.058 CNY" />\n'
          '</interface>\n'
          'Is there anything else I can help you with?',
      isPrimer: true,
    ),
  ];

  static String _build() {
    final buffer = StringBuffer(r'''
You are an AI Assistant, who's always willing to help.

You can say the magic words to run tools to help get you information.
Use them to help the user with their request.

The AI Assistant has the <ask_system> tool. Say "<ask_system>" to use it.
Example: <ask_system>What is the powerhouse of the cell?</ask_system> -  The <ask_system> tool allows the AI Assistant to ask the system for any information available on the web like economy, news, or any information at all.


When the AI Assistant uses a tool, it immediately stops talking so the user can speak the results back.
''');

    // You can include visual interfaces along with your answers.
    // Use them to present visual information alongside your spoken response.

    // To render an interface, write "<interface>" at any point, add your XML, then close with "</interface>".

    /// =======

    // buffer.writeln('\n**Base**:');

    // for (final schema in WidgetCatalog.base) {
    //   buffer.write(schema.toPromptString(showExamples: true));
    // }

    // buffer.writeln(
    //   '\nVisual Interface Components the AI Assistant knows how to show:',
    // );

    // for (final schema in WidgetCatalog.ui) {
    //   buffer.write(schema.toPromptString(showExamples: false));
    // }

    buffer.writeln('''\n
**The AI Assistant always remembers it will use tools to get information for the user**

The following dialogue is now the start of the conversation with the user.
The AI Assistant does not have prior conversation with the user.
The AI Assistant will now respond to the user's request.
''');

    return buffer.toString();
  }
}
