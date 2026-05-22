import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

class StreamingTerminal extends StatefulWidget {
  final PropertyStream props;

  const StreamingTerminal({super.key, required this.props});

  @override
  State<StreamingTerminal> createState() => _StreamingTerminalState();
}

class _StreamingTerminalState extends State<StreamingTerminal> {
  late Stream<String> _titleStream;
  late Future<String> _titleFuture;
  late Stream<String> _codeStream;
  late Future<String> _codeFuture;
  late Stream<String> _langStream;
  late Future<String> _langFuture;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant StreamingTerminal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initStream();
    }
  }

  void _initStream() {
    final mapStream = widget.props.asMap;

    final titleProp = mapStream.getStringProperty("title");
    _titleStream = titleProp.stream;
    _titleFuture = titleProp.future;

    final codeProp = mapStream.getStringProperty("code");
    _codeStream = codeProp.stream;
    _codeFuture = codeProp.future;

    final langProp = mapStream.getStringProperty("language");
    _langStream = langProp.stream;
    _langFuture = langProp.future;
  }

  @override
  Widget build(BuildContext context) {
    return StreamingEntrance(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Slate 900
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF334155), // Slate 700
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mac Title Bar Window Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // Mac Control Dots
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _circleDot(const Color(0xFFEF4444)), // Red
                        const SizedBox(width: 6),
                        _circleDot(const Color(0xFFF59E0B)), // Orange
                        const SizedBox(width: 6),
                        _circleDot(const Color(0xFF10B981)), // Green
                      ],
                    ),
                    const Expanded(child: SizedBox()),

                    // Streaming Terminal Title
                    FutureBuilder<String>(
                      future: _titleFuture,
                      builder: (context, titleSnap) {
                        final isDone =
                            titleSnap.connectionState == ConnectionState.done &&
                            titleSnap.hasData;
                        final initialTitle = isDone
                            ? titleSnap.data!
                            : 'terminal';

                        return AccumulatingStringStreamBuilder(
                          stream: _titleStream,
                          initialValue: initialTitle,
                          builder: (context, titleText) {
                            return Text(
                              titleText.isEmpty ? 'terminal' : titleText,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8), // Slate 400
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'monospace',
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const Expanded(child: SizedBox()),

                    // Language indicator label
                    FutureBuilder<String>(
                      future: _langFuture,
                      builder: (context, langSnap) {
                        final isDone =
                            langSnap.connectionState == ConnectionState.done &&
                            langSnap.hasData;
                        final initialLang = isDone ? langSnap.data! : '';

                        return AccumulatingStringStreamBuilder(
                          stream: _langStream,
                          initialValue: initialLang,
                          builder: (context, langText) {
                            if (langText.isEmpty)
                              return const SizedBox(width: 44);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                langText.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8), // Light Blue
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFF1E293B), height: 1, thickness: 1),

              // Code Display Pane
              Padding(
                padding: const EdgeInsets.all(16),
                child: FutureBuilder<String>(
                  future: _codeFuture,
                  builder: (context, codeSnap) {
                    final isDone =
                        codeSnap.connectionState == ConnectionState.done &&
                        codeSnap.hasData;
                    final initialCode = isDone ? codeSnap.data! : '';

                    return AccumulatingStringStreamBuilder(
                      stream: _codeStream,
                      initialValue: initialCode,
                      builder: (context, codeText) {
                        return SelectableText(
                          codeText,
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0), // Slate 200
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.45,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
