import 'dart:async';
import 'package:flutter/material.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
import 'package:example/data/mock_data.dart';
import 'package:example/data/custom_widgets.dart';
import 'package:example/chat_screen.dart';
import 'package:example/utilities/stream_text_in_chunk.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final StreamingGenerativeUi _genUi;
  late ExampleData _selectedExample;
  double _speedMs = 50.0;
  double _chunkSize = 4.0;
  bool _isStreaming = false;
  bool _isPaused = false;
  String _terminalText = '';
  StreamSubscription<String>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize our library controller with the combined widget registry list
    _genUi = StreamingGenerativeUi(
      registries: [
        Registries.core,
        WidgetRegistry(widgets: customRegistry),
      ],
    );
    _selectedExample = mockExamples.first;
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  void _startSimulation() async {
    // Clean up previous runs
    await _streamSubscription?.cancel();
    _genUi.disposeView('playground-view');

    setState(() {
      _terminalText = '';
      _isStreaming = true;
      _isPaused = false;
    });

    // 1. Create chunked string stream with dynamic chunk size
    final rawStream = streamTextInChunks(
      _selectedExample.content,
      chunkSize: _chunkSize.round(),
      interval: Duration(milliseconds: _speedMs.round()),
    );

    // 2. Convert to broadcast so both the engine and terminal can listen concurrently
    final broadcastStream = rawStream.asBroadcastStream();

    // 3. Pipe directly into our Generative UI engine
    _genUi.stream(broadcastStream, viewId: 'playground-view');

    // 4. Synchronously capture events to update the terminal window
    _streamSubscription = broadcastStream.listen(
      (chunk) {
        setState(() {
          _terminalText += chunk;
        });
      },
      onDone: () {
        setState(() {
          _isStreaming = false;
          _isPaused = false;
        });
      },
      onError: (err) {
        setState(() {
          _terminalText += '\n[Stream Error: $err]';
          _isStreaming = false;
          _isPaused = false;
        });
      },
    );
  }

  void _pauseOrResumeSimulation() {
    if (_streamSubscription == null) return;
    setState(() {
      if (_isPaused) {
        _streamSubscription!.resume();
        _isPaused = false;
      } else {
        _streamSubscription!.pause();
        _isPaused = true;
      }
    });
  }

  void _stopSimulation() async {
    await _streamSubscription?.cancel();
    setState(() {
      _isStreaming = false;
      _isPaused = false;
    });
  }

  void _resetSimulation() async {
    await _streamSubscription?.cancel();
    _genUi.disposeView('playground-view');
    setState(() {
      _terminalText = '';
      _isStreaming = false;
      _isPaused = false;
    });
  }

  bool _shouldShowChatDemo() {
    try {
      final uri = Uri.base;
      final path = uri.path.toLowerCase();
      final fragment = uri.fragment.toLowerCase();

      // Check query parameters (e.g. ?chat-demo, ?chat, ?page=chat-demo)
      if (uri.queryParameters.containsKey('chat-demo') ||
          uri.queryParameters.containsKey('chat') ||
          uri.queryParameters['page'] == 'chat' ||
          uri.queryParameters['page'] == 'chat-demo') {
        return true;
      }

      // Check path (e.g. /chat-demo, /chat_demo)
      if (path.contains('chat-demo') || path.contains('chat_demo')) {
        return true;
      }

      // Check hash fragment (e.g. #/chat-demo, #chat-demo)
      if (fragment.contains('chat-demo') || fragment.contains('chat_demo')) {
        return true;
      }
    } catch (e) {
      // Fail-safe
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 13.0,
      height: 1.4,
    );

    return DefaultTabController(
      length: 2,
      initialIndex: _shouldShowChatDemo() ? 1 : 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Generative UI Playground'),
          bottom: const TabBar(
            tabs: [
              Tab(
                text: '💻 Simulation Playground',
                icon: Icon(Icons.psychology_outlined),
              ),
              Tab(
                text: '🤖 Live AI LLM Chat',
                icon: Icon(Icons.forum_outlined),
              ),
            ],
          ),
        ),
        body: TabBarView(
          physics:
              const NeverScrollableScrollPhysics(), // Prevent swipe-slide gesture conflicts
          children: [
            // Tab 1: Simulation Playground
            Column(
              children: [
                // Control Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Dataset: '),
                          DropdownButton<ExampleData>(
                            value: _selectedExample,
                            items: mockExamples.map((ex) {
                              return DropdownMenuItem<ExampleData>(
                                value: ex,
                                child: Text(ex.name),
                              );
                            }).toList(),
                            onChanged: _isStreaming
                                ? null
                                : (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedExample = val;
                                        _terminalText =
                                            ''; // Clear terminal preview
                                      });
                                    }
                                  },
                          ),
                          const SizedBox(width: 20),
                          const Text('Speed Delay: '),
                          Expanded(
                            child: Slider(
                              min: 10,
                              max: 500,
                              value: _speedMs,
                              onChanged: _isStreaming
                                  ? null
                                  : (val) {
                                      setState(() {
                                        _speedMs = val;
                                      });
                                    },
                            ),
                          ),
                          Text('${_speedMs.round()}ms'),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Chunk Size: '),
                          Expanded(
                            child: Slider(
                              min: 1,
                              max: 30,
                              value: _chunkSize,
                              onChanged: _isStreaming
                                  ? null
                                  : (val) {
                                      setState(() {
                                        _chunkSize = val;
                                      });
                                    },
                            ),
                          ),
                          Text('${_chunkSize.round()} chars'),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: !_isStreaming
                                ? _startSimulation
                                : _pauseOrResumeSimulation,
                            child: Text(
                              !_isStreaming
                                  ? 'Start'
                                  : (_isPaused ? 'Resume' : 'Pause'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _isStreaming ? _stopSimulation : null,
                            child: const Text('Stop'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _isStreaming || _terminalText.isNotEmpty
                                ? _resetSimulation
                                : null,
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Viewport panels
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Panel: Raw terminal output with stacked ghost text
                      Expanded(
                        child: Container(
                          color: Colors.black87,
                          padding: const EdgeInsets.all(12.0),
                          child: SingleChildScrollView(
                            child: Stack(
                              children: [
                                // Ghost template background
                                Text(
                                  _selectedExample.content,
                                  style: textStyle.copyWith(
                                    color: Colors.white30,
                                  ),
                                ),
                                // Live active text overlay
                                Text(
                                  _terminalText,
                                  style: textStyle.copyWith(
                                    color: Colors.greenAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      // Right Panel: Visual rendering of generative UI view
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Visual Canvas Output:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              // Display the reactive view from our engine
                              _genUi.view('playground-view'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Tab 2: Live Gemini AI Chat
            ChatScreen(genUi: _genUi),
          ],
        ),
      ),
    );
  }
}
