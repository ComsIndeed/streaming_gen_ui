import 'dart:async';
import 'package:flutter/material.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Streaming Gen UI Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const StreamingUiScreen(),
    );
  }
}

class StreamingUiScreen extends StatefulWidget {
  const StreamingUiScreen({super.key});

  @override
  State<StreamingUiScreen> createState() => _StreamingUiScreenState();
}

class _StreamingUiScreenState extends State<StreamingUiScreen> {
  // 1. Initialize the central controller with registered widgets
  late final StreamingGenerativeUi _genUi;

  @override
  void initState() {
    super.initState();
    _genUi = StreamingGenerativeUi(
      registry: WidgetRegistry(
        widgets: {
          ...Registries.core.widgets,
          // Register any custom domain widgets here...
        },
      ),
    );
  }

  void _simulateLlmStream() {
    final streamController = StreamController<String>();

    // 2. Feed the streaming text chunks directly into the Generative UI engine
    _genUi.stream(streamController.stream, viewId: 'welcome-view');

    // Simulate progressive JSON tag streaming from an LLM
    const chunks = [
      'Hello! Here is the layout you requested:\n',
      '<ui-block>',
      '{"namespace":"core:container",',
      '"width":300,"height":150,',
      '"child":{"namespace":"core:text","content":"Hello from the progressive stream!"}}',
      '</ui-block>',
      '\nStream completed successfully!',
    ];

    int index = 0;
    Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (index < chunks.length) {
        streamController.add(chunks[index++]);
      } else {
        streamController.close();
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Streaming Generative UI Demo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Simulate LLM Stream'),
                onPressed: _simulateLlmStream,
              ),
              const SizedBox(height: 24),
              // 3. Display the reactive, progressive generative view
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 320,
                    height: 200,
                    child: _genUi.view('welcome-view'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
