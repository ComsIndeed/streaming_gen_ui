import 'dart:async';
import 'package:flutter/material.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';

// ---------------------------------------------------------------------------
// This example demonstrates the core streaming_gen_ui workflow:
//
//   1. Instantiate StreamingGenerativeUi with your chosen registries.
//   2. Include the auto-generated systemPrompt in your LLM system instructions.
//   3. Feed the LLM token stream to .stream(stream, viewId: '...').
//   4. Place .view('...') anywhere in your widget tree to display the output.
//
// In production, replace _simulatedLlmStream() with your real LLM stream.
// ---------------------------------------------------------------------------

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'streaming_gen_ui Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // 1. Create instance — pick the registries you want the LLM to use.
  //    Registries.material gives you a full set of Material 3 styled UI cards.
  //    Add Registries.primitives for raw layout/text/button primitives.
  late final StreamingGenerativeUi _genUi;

  @override
  void initState() {
    super.initState();
    _genUi = StreamingGenerativeUi(
      registries: [Registries.material, Registries.primitives],
    );

    // 2. In production, pass _genUi.systemPrompt to your LLM system prompt:
    //
    //   final response = await yourLlm.sendMessageStream(
    //     message: userMessage,
    //     systemPrompt: 'You are a helpful assistant.\n${_genUi.systemPrompt}',
    //   );
    //   _genUi.stream(response, viewId: 'chat-1');
  }

  /// Simulates a streaming LLM response that mixes conversational text with
  /// a generative UI widget declared via an <interface> tag.
  void _sendMessage() {
    final controller = StreamController<String>();

    // 3. Feed the stream to the engine — it handles tag parsing automatically.
    _genUi.stream(controller.stream, viewId: 'chat-1');

    // Simulate character-by-character token emission from an LLM.
    const response =
        'Here is a quick profile card for you:\n\n'
        '<interface>'
        '{"namespace":"material_ui:card",'
        '"title":"Flutter Developer",'
        '"subtitle":"Building reactive UIs with streaming_gen_ui",'
        '"body":[{"namespace":"core:text","content":"Skills: Dart, Flutter, LLM integration"}]}'
        '</interface>'
        '\n\nLet me know if you\'d like any changes!';

    int i = 0;
    Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (i < response.length) {
        controller.add(response[i++]);
      } else {
        controller.close();
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('streaming_gen_ui Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 4. Display the reactive view — renders Markdown + widgets in order.
            Expanded(child: _genUi.view('chat-1')),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Send example message'),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _genUi.disposeView('chat-1');
    super.dispose();
  }
}
