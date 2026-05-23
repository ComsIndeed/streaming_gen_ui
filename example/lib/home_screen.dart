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
  String _selectedCategory = 'Core Mechanics';
  late ExampleData _selectedExample;
  double _speedMs = 50.0;
  double _chunkSize = 4.0;
  bool _isStreaming = false;
  bool _isPaused = false;
  String _terminalText = '';
  StreamSubscription<String>? _streamSubscription;
  StreamController<String>? _streamController;

  @override
  void initState() {
    super.initState();
    // Initialize our library controller with the combined widget registry list
    _genUi = StreamingGenerativeUi(
      registries: [
        Registries.all,
        WidgetRegistry(widgets: customRegistry),
      ],
    );
    _selectedExample = mockExamples.firstWhere((ex) => ex.category == _selectedCategory);
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _streamController?.close();
    super.dispose();
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _selectedExample = mockExamples.firstWhere((ex) => ex.category == category);
      _terminalText = ''; // Clear terminal preview
    });
  }

  void _onExampleChanged(ExampleData example) {
    setState(() {
      _selectedExample = example;
      _terminalText = ''; // Clear terminal preview
    });
  }

  void _startSimulation() async {
    // Clean up previous runs
    await _streamSubscription?.cancel();
    _streamController?.close();
    _genUi.disposeView('playground-view');

    final controller = StreamController<String>.broadcast();
    _genUi.stream(controller.stream, viewId: 'playground-view');

    setState(() {
      _streamController = controller;
      _terminalText = '';
      _isStreaming = true;
      _isPaused = false;
    });

    // 1. Create chunked string stream with dynamic chunk size and speed
    final rawStream = streamTextInChunks(
      _selectedExample.content,
      chunkSize: _chunkSize.round(),
      interval: Duration(milliseconds: _speedMs.round()),
    );

    // 2. Pipe to controller and update terminal simultaneously via single subscriber
    _streamSubscription = rawStream.listen(
      (chunk) {
        if (!controller.isClosed) {
          controller.add(chunk);
          if (mounted) {
            setState(() {
              _terminalText += chunk;
            });
          }
        }
      },
      onDone: () {
        controller.close();
        if (mounted) {
          setState(() {
            _isStreaming = false;
            _isPaused = false;
          });
        }
      },
      onError: (err) {
        controller.close();
        if (mounted) {
          setState(() {
            _terminalText += '\n[Stream Error: $err]';
            _isStreaming = false;
            _isPaused = false;
          });
        }
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
    _streamController?.close();
    setState(() {
      _isStreaming = false;
      _isPaused = false;
    });
  }

  void _resetSimulation() async {
    await _streamSubscription?.cancel();
    _streamController?.close();
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

      if (uri.queryParameters.containsKey('chat-demo') ||
          uri.queryParameters.containsKey('chat') ||
          uri.queryParameters['page'] == 'chat' ||
          uri.queryParameters['page'] == 'chat-demo') {
        return true;
      }

      if (path.contains('chat-demo') || path.contains('chat_demo')) {
        return true;
      }

      if (fragment.contains('chat-demo') || fragment.contains('chat_demo')) {
        return true;
      }
    } catch (_) {
      // Fail-safe
    }
    return false;
  }

  List<TextSpan> _parseAndHighlight(String text) {
    final List<TextSpan> spans = [];
    int i = 0;
    final int len = text.length;

    while (i < len) {
      final int interfaceStart = text.indexOf('<interface', i);
      if (interfaceStart == -1) {
        spans.add(TextSpan(
          text: text.substring(i),
          style: const TextStyle(color: Color(0xFFCCCCCC)), // Light grey for normal text
        ));
        break;
      }

      if (interfaceStart > i) {
        spans.add(TextSpan(
          text: text.substring(i, interfaceStart),
          style: const TextStyle(color: Color(0xFFCCCCCC)), // Light grey for normal text
        ));
      }

      final int tagEnd = text.indexOf('>', interfaceStart);
      if (tagEnd == -1) {
        spans.add(TextSpan(
          text: text.substring(interfaceStart),
          style: const TextStyle(
            color: Color(0xFFFF5F56), // Red for interface tags
            fontWeight: FontWeight.bold,
          ),
        ));
        break;
      }

      spans.add(TextSpan(
        text: text.substring(interfaceStart, tagEnd + 1),
        style: const TextStyle(
          color: Color(0xFFFF5F56), // Red for interface tags
          fontWeight: FontWeight.bold,
        ),
      ));

      i = tagEnd + 1;

      final int closingTagStart = text.indexOf('</interface>', i);
      if (closingTagStart == -1) {
        spans.add(TextSpan(
          text: text.substring(i),
          style: const TextStyle(
            color: Color(0xFF27C93F), // Green for JSON
            fontFamily: 'monospace',
          ),
        ));
        break;
      }

      if (closingTagStart > i) {
        spans.add(TextSpan(
          text: text.substring(i, closingTagStart),
          style: const TextStyle(
            color: Color(0xFF27C93F), // Green for JSON
            fontFamily: 'monospace',
          ),
        ));
      }

      spans.add(const TextSpan(
        text: '</interface>',
        style: TextStyle(
          color: Color(0xFFFF5F56), // Red for interface tags
          fontWeight: FontWeight.bold,
        ),
      ));

      i = closingTagStart + '</interface>'.length;
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
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
          physics: const NeverScrollableScrollPhysics(), // Prevent swipe-slide gesture conflicts
          children: [
            // Tab 1: Simulation Playground
            Column(
              children: [
                // Control Bar
                Card(
                  margin: const EdgeInsets.all(16.0),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Category Dropdown
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "CATEGORY",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    items: ['Core Mechanics', 'Batteries Included', 'Pre-Built Themes', 'Custom Composition'].map((cat) {
                                      return DropdownMenuItem<String>(
                                        value: cat,
                                        child: Text(cat, style: const TextStyle(fontSize: 13)),
                                      );
                                    }).toList(),
                                    onChanged: _isStreaming ? null : (val) {
                                      if (val != null) {
                                        _onCategoryChanged(val);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Case Dropdown
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "FEATURE CASE",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<ExampleData>(
                                    value: _selectedExample,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    items: mockExamples.where((ex) => ex.category == _selectedCategory).map((ex) {
                                      return DropdownMenuItem<ExampleData>(
                                        value: ex,
                                        child: Text(ex.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: _isStreaming ? null : (val) {
                                      if (val != null) {
                                        _onExampleChanged(val);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // Delay Slider
                            Expanded(
                              child: Row(
                                children: [
                                  const Text(
                                    "Delay: ",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      min: 10,
                                      max: 300,
                                      value: _speedMs,
                                      onChanged: _isStreaming ? null : (val) {
                                        setState(() {
                                          _speedMs = val;
                                        });
                                      },
                                    ),
                                  ),
                                  Text(
                                    "${_speedMs.round()}ms",
                                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Chunk Slider
                            Expanded(
                              child: Row(
                                children: [
                                  const Text(
                                    "Chunk: ",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      min: 1,
                                      max: 20,
                                      value: _chunkSize,
                                      onChanged: _isStreaming ? null : (val) {
                                        setState(() {
                                          _chunkSize = val;
                                        });
                                      },
                                    ),
                                  ),
                                  Text(
                                    "${_chunkSize.round()} char",
                                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Action Buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: !_isStreaming ? _startSimulation : _pauseOrResumeSimulation,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: !_isStreaming
                                        ? Theme.of(context).colorScheme.primary
                                        : (_isPaused ? Colors.amber.shade700 : Theme.of(context).colorScheme.secondary),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: Icon(
                                    !_isStreaming
                                        ? Icons.play_arrow_rounded
                                        : (_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                                    size: 16,
                                  ),
                                  label: Text(
                                    !_isStreaming ? 'Start' : (_isPaused ? 'Resume' : 'Pause'),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _isStreaming ? _stopSimulation : null,
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.stop_rounded, size: 16),
                                  label: const Text("Stop", style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _isStreaming || _terminalText.isNotEmpty ? _resetSimulation : null,
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.replay_rounded, size: 16),
                                  label: const Text("Reset", style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Viewport panels
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Panel: Raw terminal output with beautiful syntax highlighting
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF121212),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Terminal Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C1C1C),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.04),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Window control dots
                                      Row(
                                        children: [
                                          Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                                          const SizedBox(width: 6),
                                          Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                                          const SizedBox(width: 6),
                                          Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
                                        ],
                                      ),
                                      const Expanded(
                                        child: Center(
                                          child: Text(
                                            "RAW TOKEN STREAM",
                                            style: TextStyle(
                                              color: Color(0xFF999999),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 42), // Spacer to balance dots
                                    ],
                                  ),
                                ),
                                // Terminal Code Area
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    child: SingleChildScrollView(
                                      child: RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13.0,
                                            height: 1.5,
                                          ),
                                          children: _parseAndHighlight(_terminalText),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right Panel: Visual rendering of generative UI view inside a premium Canvas Card
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Canvas Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainer,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.layers_outlined,
                                        size: 14,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "VISUAL CANVAS OUTPUT",
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Canvas Area
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 400),
                                        child: _genUi.view('playground-view'),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
