import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
import 'package:streaming_gen_ui_widget_catalog/core/app_widgets/elastic_button.dart';
import 'package:streaming_gen_ui_widget_catalog/core/app_widgets/elastic_wrapper.dart';
import 'package:streaming_gen_ui_widget_catalog/core/models/widget_catalog_item.dart';
import 'package:streaming_gen_ui_widget_catalog/core/utilities/stream_text_in_chunks.dart';
import 'package:streaming_gen_ui_widget_catalog/core/utilities/web_downloader.dart';
import 'package:streaming_gen_ui_widget_catalog/core/widget_sources.g.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/preview_page/property_editable.dart';
import 'package:streaming_gen_ui_widget_catalog/widgets/graph_background.dart';
import 'package:http/http.dart' as http;

class PreviewPage extends StatefulWidget {
  final WidgetCatalogItem catalogItem;

  const PreviewPage({super.key, required this.catalogItem});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  Map<String, TextEditingController> propertyControllers = {};

  // Stream & Engine instances
  StreamingGenerativeUi? _streamingGenUi;
  StreamController<String>? _streamController;
  StreamSubscription<String>? _streamSubscription;

  String _accumulatedText = "";
  bool _isStreaming = false;
  bool _isPaused = false;
  UniqueKey _viewKey = UniqueKey();
  Timer? _debounceTimer;

  // Sandbox Adjustment and Tab states
  int _chunkSize = 4;
  int _intervalMs = 150;
  bool _isCodeExpanded = false;
  bool _isPropertiesExpanded = false;
  int _currentLeftPanelPage = 0;
  String _latestVersion = "0.1.0";

  @override
  void initState() {
    super.initState();

    // Decode properties & initialize input controllers
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

    // Initiate first simulated stream
    _startStream();
    _fetchLatestVersion();
  }

  Future<void> _fetchLatestVersion() async {
    try {
      final response = await http.get(
        Uri.parse('https://pub.dev/api/packages/streaming_gen_ui'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final version = decoded['latest']['version'] as String;
        if (mounted) {
          setState(() {
            _latestVersion = version;
          });
        }
      }
    } catch (_) {
      // Keep fallback
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _streamSubscription?.cancel();
    _streamController?.close();
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
    _streamController?.close();

    // Re-create a completely fresh engine slate and controller
    final engine = StreamingGenerativeUi(registry: Registries.all);
    final controller = StreamController<String>.broadcast();
    engine.stream(controller.stream, viewId: 'main-view');

    setState(() {
      _streamingGenUi = engine;
      _streamController = controller;
      _accumulatedText = "";
      _isStreaming = true;
      _isPaused = false;
      _viewKey = UniqueKey(); // Forces visual widget replacement
    });

    final sourceStream = streamTextInChunks(
      text: "<interface>$updatedExample</interface>",
      chunkSize: _chunkSize,
      interval: Duration(milliseconds: _intervalMs),
      chunkSizeImmediatelyEmit: '<interface>{"namespace":"  core:'.length,
    );

    _streamSubscription = sourceStream.listen(
      (chunk) {
        if (!controller.isClosed) {
          controller.add(chunk);
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

  String get widgetSourceCode {
    final parts = widget.catalogItem.namespace.split(':');
    if (parts.length < 2) return '';
    final name = parts[1];
    final filename = 'streaming_$name.dart';
    final base64Source = widgetSources[filename];
    if (base64Source == null) return '// Source code not found for this widget';
    try {
      return utf8.decode(base64.decode(base64Source));
    } catch (e) {
      return '// Error decoding source code: $e';
    }
  }

  String get widgetClassName {
    final parts = widget.catalogItem.namespace.split(':');
    if (parts.length < 2) return 'StreamingWidget';
    final name = parts[1];
    // Convert snake_case to PascalCase
    final pascalName = name
        .split('_')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        })
        .join('');
    return 'Streaming$pascalName';
  }

  void _downloadWidgetSource() async {
    final name = widget.catalogItem.namespace.split(':').last;
    final filename = 'streaming_$name.dart';
    final sourceCode = widgetSourceCode;
    final messenger = ScaffoldMessenger.of(context);

    if (kIsWeb) {
      try {
        downloadFileWeb(sourceCode, filename);
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Download triggered in new tab!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        await Clipboard.setData(ClipboardData(text: sourceCode));
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Couldn't auto-download. Code copied to clipboard!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Desktop / Local file writing
      try {
        final Directory customWidgetsDir = Directory('lib/widgets/custom');
        if (!customWidgetsDir.existsSync()) {
          customWidgetsDir.createSync(recursive: true);
        }
        final File outputFile = File('lib/widgets/custom/$filename');
        outputFile.writeAsStringSync(sourceCode);

        messenger.showSnackBar(
          SnackBar(
            content: Text("Saved locally to: ${outputFile.path}!"),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        await Clipboard.setData(ClipboardData(text: sourceCode));
        messenger.showSnackBar(
          SnackBar(
            content: Text("Saved code to clipboard: $e"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Pure custom Regex syntax highlighters for console view
  TextSpan _buildHighlightedCode(String code, ThemeData theme) {
    final spans = <TextSpan>[];

    // Regular expression matching XML, JSON and Dart styles
    final regExp = RegExp(
      r'(<\/?[a-zA-Z0-9_:]+>)|("([a-zA-Z0-9_:]+)")\s*:|("([^"]*)")|(\b\d+(\.\d+)?\b)|(\b(true|false|null)\b)|(\b(class|extends|implements|override|import|final|const|return|super|dynamic|Map|String|Widget|void|int|double|bool|get|static|Text|Container|Column|Row|SizedBox|Card|Padding|InkWell|BuildContext|statelesswidget|statefulwidget)\b)|([{}[\],:])',
      multiLine: true,
      caseSensitive: false,
    );

    int lastMatchIndex = 0;

    for (final match in regExp.allMatches(code)) {
      if (match.start > lastMatchIndex) {
        spans.add(TextSpan(text: code.substring(lastMatchIndex, match.start)));
      }

      final matchText = match.group(0)!;

      if (match.group(1) != null) {
        // XML Tags
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
        // JSON Keys
        spans.add(
          TextSpan(
            text: match.group(2)!,
            style: TextStyle(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        spans.add(const TextSpan(text: " :"));
      } else if (match.group(4) != null) {
        // Strings
        spans.add(
          TextSpan(
            text: matchText,
            style: TextStyle(color: theme.colorScheme.tertiary),
          ),
        );
      } else if (match.group(6) != null) {
        // Numbers
        spans.add(
          TextSpan(
            text: matchText,
            style: const TextStyle(color: Colors.orangeAccent),
          ),
        );
      } else if (match.group(8) != null) {
        // Booleans
        spans.add(
          TextSpan(
            text: matchText,
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (match.group(10) != null) {
        // Dart keywords / classes
        spans.add(
          TextSpan(
            text: matchText,
            style: TextStyle(
              color: theme.colorScheme.primary.withRed(180),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else {
        // Punctuations
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

  Widget _buildSandboxPage(ThemeData theme) {
    return Column(
      key: const ValueKey('sandbox-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Collapsible Properties Header
        _PropertiesHeaderToggle(
          isExpanded: _isPropertiesExpanded,
          fieldCount:
              widget.catalogItem.widgetDefinition.properties.keys.length,
          onTap: () {
            setState(() {
              _isPropertiesExpanded = !_isPropertiesExpanded;
            });
          },
        ),

        // Dynamic Interactive Forms (Collapsible list)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: const Cubic(0.2, 0.8, 0.2, 1.0),
          alignment: Alignment.topCenter,
          clipBehavior: Clip.antiAlias,
          child: _isPropertiesExpanded
              ? Column(
                  key: const ValueKey('properties-expanded-container'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    ...widget.catalogItem.widgetDefinition.properties.keys.map((
                      key,
                    ) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: PropertyEditable(
                          controller: propertyControllers[key]!,
                          propertyKey: key,
                          catalogItem: widget.catalogItem,
                        ),
                      );
                    }),
                  ],
                )
              : const SizedBox(
                  key: ValueKey('properties-collapsed-container'),
                  height: 0,
                  width: double.infinity,
                ),
        ),
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
          color: theme.colorScheme.surfaceContainer,
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
                minHeight: 110,
                maxHeight: 220,
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
  }

  Widget _buildPremiumCodeBlock({
    required String fileName,
    required String code,
    required ThemeData theme,
    required VoidCallback onCopy,
    bool isExpandable = false,
  }) {
    final codeBlockBg = theme.colorScheme.surfaceContainer;
    final headerBg = theme.colorScheme.surfaceContainerHigh;
    final borderCol = theme.colorScheme.outline.withOpacity(0.12);

    final codeBlockWidget = Container(
      decoration: BoxDecoration(
        color: codeBlockBg,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: borderCol),
      ),
      width: double.infinity,
      child: Stack(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (isExpandable && !_isCodeExpanded)
                  ? 220.0
                  : double.infinity,
            ),
            child: SingleChildScrollView(
              physics: (isExpandable && !_isCodeExpanded)
                  ? const NeverScrollableScrollPhysics()
                  : const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                (isExpandable && !_isCodeExpanded) ? 48.0 : 16.0,
              ),
              child: SelectionArea(
                child: RichText(text: _buildHighlightedCode(code, theme)),
              ),
            ),
          ),
          if (isExpandable && !_isCodeExpanded)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 90,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      codeBlockBg.withOpacity(0.0),
                      codeBlockBg.withOpacity(0.85),
                      codeBlockBg,
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isCodeExpanded = true;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.12),
                          ),
                        ),
                        elevation: 1,
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        "See Full Code",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (isExpandable && _isCodeExpanded)
            Positioned(
              right: 16,
              bottom: 12,
              child: Opacity(
                opacity: 0.85,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isCodeExpanded = false;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.12),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 14),
                  label: const Text(
                    "Collapse",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: headerBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: Border(
              top: BorderSide(color: borderCol),
              left: BorderSide(color: borderCol),
              right: BorderSide(color: borderCol),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    fileName.endsWith('.yaml')
                        ? Icons.description_rounded
                        : Icons.code_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    fileName,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.9,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 28,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    foregroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 13),
                  label: const Text(
                    "Copy",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        codeBlockWidget,
      ],
    );
  }

  Widget _buildIntegrationPage(ThemeData theme) {
    final className = widgetClassName;
    final name = widget.catalogItem.namespace.split(':').last;
    final filename = 'streaming_$name.dart';
    final isBuiltIn = widget.catalogItem.isBuiltIn;

    return Column(
      key: const ValueKey('integration-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Import Widget",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isBuiltIn
              ? "This widget is built into streaming_gen_ui. No extra files needed."
              : "Follow these steps to import and use the generated streaming component.",
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.85),
          ),
        ),
        const SizedBox(height: 24),

        // Step 1 — same for both paths
        Text(
          "1. pubspec.yaml Setup",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Add the package to your dependencies list.",
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        _buildPremiumCodeBlock(
          fileName: "pubspec.yaml",
          code: "dependencies:\n  streaming_gen_ui: ^$_latestVersion",
          theme: theme,
          onCopy: () async {
            final messenger = ScaffoldMessenger.of(context);
            await Clipboard.setData(
              ClipboardData(
                text: "dependencies:\n  streaming_gen_ui: ^$_latestVersion",
              ),
            );
            messenger.showSnackBar(
              const SnackBar(
                content: Text("pubspec.yaml dependency snippet copied!"),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(height: 28),

        if (isBuiltIn) ...[
          // ── Built-In Path ──────────────────────────────────────

          // Step 2: Register
          Text(
            "2. Register the Widget",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Use the + operator on Registries.all, filtered to only the widget you need.",
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          _buildPremiumCodeBlock(
            fileName: "registration.dart",
            code:
                "import 'package:streaming_gen_ui/streaming_gen_ui.dart';\n\n"
                "final myRegistry = WidgetRegistry()\n"
                "  + Registries.all.only('${widget.catalogItem.namespace}');",
            theme: theme,
            onCopy: () async {
              final messenger = ScaffoldMessenger.of(context);
              final snippet =
                  "import 'package:streaming_gen_ui/streaming_gen_ui.dart';\n\n"
                  "final myRegistry = WidgetRegistry()\n"
                  "  + Registries.all.only('${widget.catalogItem.namespace}');";
              await Clipboard.setData(ClipboardData(text: snippet));
              messenger.showSnackBar(
                const SnackBar(
                  content: Text("Registration snippet copied!"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // Step 3: Pipe & Display
          Text(
            "3. Pipe & Display",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Pass the system prompt fragment to your LLM, pipe the response stream "
            "into .stream(), then place .view() anywhere in your build method.",
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          _buildPremiumCodeBlock(
            fileName: "usage.dart",
            code:
                "final genUi = StreamingGenerativeUi(registry: myRegistry);\n\n"
                "// Inject the prompt fragment into your LLM system prompt\n"
                "final systemPrompt = genUi.systemPrompt;\n\n"
                "// Pipe the LLM response stream in\n"
                "await genUi.stream(\n"
                "  llmStream,\n"
                "  viewId: 'message-42',\n"
                "  onComplete: (raw) => db.save(raw),\n"
                ");",
            theme: theme,
            onCopy: () async {
              final messenger = ScaffoldMessenger.of(context);
              const snippet =
                  "final genUi = StreamingGenerativeUi(registry: myRegistry);\n\n"
                  "// Inject the prompt fragment into your LLM system prompt\n"
                  "final systemPrompt = genUi.systemPrompt;\n\n"
                  "// Pipe the LLM response stream in\n"
                  "await genUi.stream(\n"
                  "  llmStream,\n"
                  "  viewId: 'message-42',\n"
                  "  onComplete: (raw) => db.save(raw),\n"
                  ");";
              await Clipboard.setData(const ClipboardData(text: snippet));
              messenger.showSnackBar(
                const SnackBar(
                  content: Text("Stream setup snippet copied!"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildPremiumCodeBlock(
            fileName: "build.dart",
            code:
                "// Somewhere in your build() method:\n"
                "genUi.view('message-42')",
            theme: theme,
            onCopy: () async {
              final messenger = ScaffoldMessenger.of(context);
              const snippet =
                  "// Somewhere in your build() method:\n"
                  "genUi.view('message-42')";
              await Clipboard.setData(const ClipboardData(text: snippet));
              messenger.showSnackBar(
                const SnackBar(
                  content: Text("View snippet copied!"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ] else ...[
          // ── Importable Path ────────────────────────────────────

          // Step 2
          Text(
            "2. Self-Registration Setup",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Map the custom namespace in your local WidgetRegistry list.",
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          _buildPremiumCodeBlock(
            fileName: "registration.dart",
            code: "'${widget.catalogItem.namespace}': $className.definition,",
            theme: theme,
            onCopy: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(
                ClipboardData(
                  text:
                      "'${widget.catalogItem.namespace}': $className.definition,",
                ),
              );
              messenger.showSnackBar(
                const SnackBar(
                  content: Text("Registration snippet copied!"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // Step 3
          Text(
            "3. Standalone Widget File",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Add this standalone widget file to your project codebase.",
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          _buildPremiumCodeBlock(
            fileName: filename,
            code: widgetSourceCode,
            theme: theme,
            isExpandable: true,
            onCopy: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: widgetSourceCode));
              messenger.showSnackBar(
                const SnackBar(
                  content: Text("Full source code copied to clipboard!"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(
                      ClipboardData(text: widgetSourceCode),
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text("Full source code copied!"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_all_rounded),
                  label: const Text("Copy Full Code"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _downloadWidgetSource,
                  icon: const Icon(Icons.download_rounded),
                  label: Text(
                    kIsWeb ? "Download Dart File" : "Save to Project",
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = MediaQuery.sizeOf(context);
    final isMobile = sizes.width < 768;

    final Widget header = Column(
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
      ],
    );

    final Widget leftPanel = isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _currentLeftPanelPage == 0
                    ? _buildSandboxPage(theme)
                    : _buildIntegrationPage(theme),
              ),
            ],
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _currentLeftPanelPage == 0
                      ? _buildSandboxPage(theme)
                      : _buildIntegrationPage(theme),
                ),
              ],
            ),
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
                      child: _streamingGenUi != null
                          ? ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: _streamingGenUi!.view('main-view'),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

              // 2. Playback Floating Control Bar & Tab Switcher Side-by-Side
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pill 1: Streaming Controls Pill
                        ElasticWrapper(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
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
                                const SizedBox(width: 12),
                                Container(
                                  width: 1,
                                  height: 18,
                                  color: theme.colorScheme.outline.withOpacity(
                                    0.2,
                                  ),
                                ),
                                const SizedBox(width: 4),

                                // Chunk size adjuster
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.remove_rounded,
                                    size: 16,
                                  ),
                                  tooltip: "Decrease Chunk Size",
                                  onPressed: () {
                                    if (_chunkSize > 1) {
                                      setState(() {
                                        _chunkSize--;
                                      });
                                      _resetStream();
                                    }
                                  },
                                ),
                                Text(
                                  "$_chunkSize",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  tooltip: "Increase Chunk Size",
                                  onPressed: () {
                                    if (_chunkSize < 50) {
                                      setState(() {
                                        _chunkSize++;
                                      });
                                      _resetStream();
                                    }
                                  },
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 1,
                                  height: 18,
                                  color: theme.colorScheme.outline.withOpacity(
                                    0.2,
                                  ),
                                ),
                                const SizedBox(width: 4),

                                // Interval Speed Adjuster
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.remove_rounded,
                                    size: 16,
                                  ),
                                  tooltip: "Speed Up Stream (Reduce Interval)",
                                  onPressed: () {
                                    if (_intervalMs > 50) {
                                      setState(() {
                                        _intervalMs -= 50;
                                      });
                                      _resetStream();
                                    }
                                  },
                                ),
                                Text(
                                  "${_intervalMs}ms",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  tooltip:
                                      "Slow Down Stream (Increase Interval)",
                                  onPressed: () {
                                    if (_intervalMs < 2000) {
                                      setState(() {
                                        _intervalMs += 50;
                                      });
                                      _resetStream();
                                    }
                                  },
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 1,
                                  height: 18,
                                  color: theme.colorScheme.outline.withOpacity(
                                    0.2,
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Pause / Play Button
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: _isPaused
                                      ? "Resume Streaming"
                                      : "Pause Streaming",
                                  icon: Icon(
                                    _isPaused
                                        ? Icons.play_arrow_rounded
                                        : Icons.pause_rounded,
                                    size: 18,
                                  ),
                                  onPressed: _togglePlayPause,
                                ),

                                // Restart Button
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: "Restart Stream",
                                  icon: const Icon(
                                    Icons.replay_rounded,
                                    size: 18,
                                  ),
                                  onPressed: _resetStream,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Pill 2: Tab Switching Toggle Pill
                        AnimatedSize(
                          duration: const Duration(milliseconds: 100),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: _currentLeftPanelPage == 0
                                ? ElasticButton(
                                    sizeFactor: 1.2,
                                    key: const ValueKey('btn-integrate'),
                                    onPressed: () {
                                      setState(() {
                                        _currentLeftPanelPage = 1;
                                      });
                                    },
                                    icon: const Icon(Icons.download_rounded),
                                    label: const Text("Import Widget"),
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor:
                                        theme.colorScheme.onPrimary,
                                  )
                                : ElasticButton(
                                    key: const ValueKey('btn-sandbox'),
                                    onPressed: () {
                                      setState(() {
                                        _currentLeftPanelPage = 0;
                                      });
                                    },
                                    icon: const Icon(Icons.tune_rounded),
                                    label: const Text("Configure Widget"),
                                    backgroundColor: theme
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.5),
                                    foregroundColor:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                          ),
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
                    // Properties page view on the left
                    Expanded(flex: 4, child: SizedBox.expand(child: leftPanel)),
                    const SizedBox(width: 24),
                    // Interactive live rendering sandbox on the right
                    Expanded(flex: 5, child: rightPanel),
                  ],
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

class _TactileWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TactileWrapper({required this.child, required this.onTap});

  @override
  State<_TactileWrapper> createState() => _TactileWrapperState();
}

class _TactileWrapperState extends State<_TactileWrapper> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _PropertiesHeaderToggle extends StatefulWidget {
  final bool isExpanded;
  final int fieldCount;
  final VoidCallback onTap;

  const _PropertiesHeaderToggle({
    required this.isExpanded,
    required this.fieldCount,
    required this.onTap,
  });

  @override
  State<_PropertiesHeaderToggle> createState() =>
      _PropertiesHeaderToggleState();
}

class _PropertiesHeaderToggleState extends State<_PropertiesHeaderToggle> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Scale animation: slightly larger on hover, smaller on tap
    final double scale = _isPressed
        ? 0.97
        : _isHovered
        ? 1.02
        : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: const Cubic(0.2, 0.8, 0.2, 1.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: _isHovered
                  ? theme.colorScheme.surfaceContainer
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? theme.colorScheme.primary.withOpacity(0.15)
                    : theme.colorScheme.outline.withOpacity(0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.03),
                  blurRadius: _isHovered ? 8 : 3,
                  offset: Offset(0, _isHovered ? 4 : 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: _isHovered
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withOpacity(0.8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Properties Editor",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        _isHovered ? 1.0 : 0.9,
                      ),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                // Small indicator badge with property count
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _isHovered
                        ? theme.colorScheme.primary.withOpacity(0.12)
                        : theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${widget.fieldCount} fields",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary.withOpacity(0.8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: widget.isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: const Cubic(0.2, 0.8, 0.2, 1.0),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(
                      _isHovered ? 0.8 : 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
