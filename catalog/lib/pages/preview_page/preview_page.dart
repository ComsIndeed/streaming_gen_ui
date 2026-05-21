import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
import 'package:streaming_gen_ui_widget_catalog/core/models/widget_catalog_item.dart';
import 'package:streaming_gen_ui_widget_catalog/core/utilities/stream_text_in_chunks.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/preview_page/property_editable.dart';
import 'package:streaming_gen_ui_widget_catalog/widgets/graph_background.dart';

class PreviewPage extends StatefulWidget {
  final WidgetCatalogItem catalogItem;

  const PreviewPage({super.key, required this.catalogItem});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  Map<String, TextEditingController> propertyControllers = {};

  // Stream & Engine instances
  late final StreamingGenerativeUi _streamingGenUi;
  late final StreamController<String> _streamController;
  StreamSubscription<String>? _streamSubscription;

  String _accumulatedText = "";
  bool _isStreaming = false;
  bool _isPaused = false;
  UniqueKey _viewKey = UniqueKey();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    // 1. Setup engine and broadcast stream controller
    _streamingGenUi = StreamingGenerativeUi(registry: Registries.all);
    _streamController = StreamController<String>.broadcast();
    _streamingGenUi.stream(_streamController.stream, viewId: 'main-view');

    // 2. Decode properties & initialize input controllers
    final jsonExampleDecoded = jsonDecode(
      widget.catalogItem.widgetDefinition.jsonExample,
    );
    final Map<String, dynamic> jsonExampleMap =
        jsonExampleDecoded as Map<String, dynamic>;
    final properties = widget.catalogItem.widgetDefinition.properties;

    propertyControllers = Map.fromEntries(
      properties.keys.map((key) {
        final controller = TextEditingController(
          text: jsonEncode(jsonExampleMap[key]),
        );
        // Attach debounce listener to automatically update sandbox on input
        controller.addListener(_onPropertyChanged);
        return MapEntry(key, controller);
      }),
    );

    // 3. Initiate first simulated stream
    _startStream();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _streamSubscription?.cancel();
    _streamController.close();
    for (final controller in propertyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPropertyChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _resetStream();
    });
  }

  void _startStream() {
    _streamSubscription?.cancel();
    setState(() {
      _accumulatedText = "";
      _isStreaming = true;
      _isPaused = false;
    });

    final sourceStream = streamTextInChunks(
      text: "<interface>$updatedExample</interface>",
      chunkSize: 4,
      interval: const Duration(milliseconds: 150),
      chunkSizeImmediatelyEmit: '<interface>{"namespace":"  core:'.length,
    );

    _streamSubscription = sourceStream.listen(
      (chunk) {
        if (!_streamController.isClosed) {
          _streamController.add(chunk);
          if (mounted) {
            setState(() {
              _accumulatedText += chunk;
            });
          }
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _isStreaming = false;
          });
        }
      },
    );
  }

  void _togglePlayPause() {
    if (_isStreaming) {
      if (_isPaused) {
        _streamSubscription?.resume();
        setState(() => _isPaused = false);
      } else {
        _streamSubscription?.pause();
        setState(() => _isPaused = true);
      }
    } else {
      // Re-play if completed
      _startStream();
    }
  }

  void _resetStream() {
    setState(() {
      _viewKey = UniqueKey(); // Force visual widget replacement
    });
    _startStream();
  }

  Map<String, dynamic> get newMap {
    final Map<String, dynamic> mapMapMap = {};
    propertyControllers.forEach((key, controller) {
      try {
        final decoded = jsonDecode(controller.text);
        if (decoded != null) {
          mapMapMap[key] = decoded;
        }
      } catch (_) {
        // Fallback to raw text if it doesn't parse as JSON
        mapMapMap[key] = controller.text;
      }
    });
    return mapMapMap;
  }

  String get updatedExample {
    try {
      final oldMapDecoded = jsonDecode(
        widget.catalogItem.widgetDefinition.jsonExample,
      );
      final oldMap = oldMapDecoded as Map<String, dynamic>;
      final modifiedMap = {...oldMap, ...newMap};
      return jsonEncode(modifiedMap);
    } catch (_) {
      return widget.catalogItem.widgetDefinition.jsonExample;
    }
  }

  // Pure custom Regex syntax highlighters for console view
  TextSpan _buildHighlightedCode(String code, ThemeData theme) {
    final spans = <TextSpan>[];

    // Regular expression matching: XML tags, JSON keys, string values, numeric/booleans, and punctuation
    final regExp = RegExp(
      r'(<\/?[a-zA-Z0-9_:]+>)|("([a-zA-Z0-9_:]+)")\s*:|("([^"]*)")|(\b\d+(\.\d+)?\b)|(\b(true|false|null)\b)|([{}[\],:])',
      multiLine: true,
    );

    int lastMatchIndex = 0;

    for (final match in regExp.allMatches(code)) {
      if (match.start > lastMatchIndex) {
        spans.add(TextSpan(text: code.substring(lastMatchIndex, match.start)));
      }

      final matchText = match.group(0)!;

      if (match.group(1) != null) {
        // XML Tags like <interface>
        spans.add(
          TextSpan(
            text: matchText,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (match.group(2) != null) {
        // JSON keys like "namespace":
        spans.add(
          TextSpan(
            text: matchText,
            style: TextStyle(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      } else if (match.group(4) != null) {
        // JSON String values
        spans.add(
          TextSpan(
            text: matchText,
            style: TextStyle(color: Colors.amber.shade700),
          ),
        );
      } else if (match.group(6) != null || match.group(8) != null) {
        // Numbers, Booleans, Null
        spans.add(
          TextSpan(
            text: matchText,
            style: TextStyle(
              color: Colors.lightBlueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else {
        // Formatting brackets and commas
        spans.add(
          TextSpan(
            text: matchText,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        );
      }

      lastMatchIndex = match.end;
    }

    if (lastMatchIndex < code.length) {
      spans.add(TextSpan(text: code.substring(lastMatchIndex)));
    }

    return TextSpan(
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        height: 1.3,
      ),
      children: spans,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = MediaQuery.sizeOf(context);
    final isMobile = sizes.width < 768;

    final Widget leftPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back Button
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          label: const Text("Back to Catalog"),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
        ),
        const SizedBox(height: 16),

        // Widget Headings
        Text(
          widget.catalogItem.displayName,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          widget.catalogItem.namespace,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.catalogItem.widgetDefinition.description,
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.85),
          ),
        ),
        const SizedBox(height: 24),

        // Properties Heading
        Text(
          "Properties Editor",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        // Dynamic Interactive Forms
        ...widget.catalogItem.widgetDefinition.properties.keys.map((key) {
          return PropertyEditable(
            controller: propertyControllers[key]!,
            propertyKey: key,
            catalogItem: widget.catalogItem,
          );
        }),
        const SizedBox(height: 24),

        // Realtime Streaming syntax terminal
        Text(
          "Generative UI Stream Console",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: double.infinity,
                minHeight: 180,
                maxHeight: 300,
              ),
              child: SingleChildScrollView(
                child: RichText(
                  text: _buildHighlightedCode(
                    _accumulatedText.isEmpty
                        ? "<interface>$updatedExample</interface>"
                        : _accumulatedText,
                    theme,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    final Widget rightPanel = Hero(
      tag: 'catalog-card-${widget.catalogItem.namespace}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 8,
        shadowColor: theme.colorScheme.shadow.withOpacity(0.08),
        child: Container(
          decoration: BoxDecoration(color: theme.colorScheme.surface),
          child: Stack(
            children: [
              // 1. Sandbox Stream Display
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: KeyedSubtree(
                      key: _viewKey,
                      child: _streamingGenUi.view('main-view'),
                    ),
                  ),
                ),
              ),

              // 2. Playback Floating Control Bar (Emil Kowalski style player controls)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: ShapeDecoration(
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.85),
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Live indicator
                        const BreathingDot(),
                        const SizedBox(width: 8),
                        Text(
                          _isStreaming
                              ? (_isPaused ? "PAUSED" : "STREAMING")
                              : "COMPLETED",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 1,
                          height: 20,
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                        const SizedBox(width: 8),

                        // Pause / Play Button
                        IconButton(
                          tooltip: _isPaused
                              ? "Resume Streaming"
                              : "Pause Streaming",
                          icon: Icon(
                            _isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            size: 20,
                          ),
                          onPressed: _togglePlayPause,
                        ),

                        // Restart Button
                        IconButton(
                          tooltip: "Restart Stream",
                          icon: const Icon(Icons.replay_rounded, size: 20),
                          onPressed: _resetStream,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: GraphBackground(
        child: SafeArea(
          child: isMobile
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SizedBox(height: 350, child: rightPanel),
                      const SizedBox(height: 32),
                      leftPanel,
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      // Properties forms on the left
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(right: 16),
                          child: leftPanel,
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Interactive live rendering sandbox on the right
                      Expanded(flex: 5, child: rightPanel),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

// Custom animated Breathing/Pulsing Dot indicator widget
class BreathingDot extends StatefulWidget {
  const BreathingDot({super.key});

  @override
  State<BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<BreathingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.lightBlueAccent.withOpacity(
              0.3 + (0.7 * _controller.value),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.lightBlueAccent.withOpacity(
                  0.3 * _controller.value,
                ),
                blurRadius: 4 + (6 * _controller.value),
                spreadRadius: 2 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
