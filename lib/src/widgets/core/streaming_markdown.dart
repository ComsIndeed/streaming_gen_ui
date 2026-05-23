import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';

/// A dynamic markdown primitive supporting progressive streaming and customizable
/// custom markdown builders (to swap in flutter_markdown or markdown_widget).
class StreamingMarkdown extends StatefulWidget {
  final PropertyStream props;
  final Widget Function(BuildContext context, String rawMarkdown)? markdownBuilder;

  const StreamingMarkdown({
    super.key,
    required this.props,
    this.markdownBuilder,
  });

  @override
  State<StreamingMarkdown> createState() => _StreamingMarkdownState();
}

class _StreamingMarkdownState extends State<StreamingMarkdown> {
  late Stream<String> _textStream;
  late Future<String> _textFuture;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant StreamingMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initStream();
    }
  }

  void _initStream() {
    final prop = widget.props.asMap.getStringProperty("content");
    _textStream = prop.stream;
    _textFuture = prop.future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: FutureBuilder<String>(
        future: _textFuture,
        builder: (context, snapshot) {
          final isDone = snapshot.connectionState == ConnectionState.done && snapshot.hasData;
          final currentInitial = isDone ? snapshot.data! : '';

          return AccumulatingStringStreamBuilder(
            stream: _textStream,
            initialValue: currentInitial,
            builder: (context, accumulatedText) {
              if (accumulatedText.isEmpty) {
                return const SizedBox.shrink(); // Empty parameter protection
              }

              // Give option to change/use custom markdown renderer
              if (widget.markdownBuilder != null) {
                return widget.markdownBuilder!(context, accumulatedText);
              }

              // Highly stylized local fallback that parses simple markdown markers (bold, italic, list)
              return RichText(
                text: _parseLocalMarkdown(accumulatedText, theme),
              );
            },
          );
        },
      ),
    );
  }

  TextSpan _parseLocalMarkdown(String text, ThemeData theme) {
    final List<TextSpan> spans = [];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Bullet List Item
      if (line.trimLeft().startsWith('- ')) {
        spans.add(
          TextSpan(
            text: '  •  ',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        );
        spans.add(_parseLineContent(line.trimLeft().substring(2), theme));
      }
      // Headings
      else if (line.startsWith('# ')) {
        spans.add(
          TextSpan(
            text: '${line.substring(2)}\n',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        );
        continue;
      } else if (line.startsWith('## ')) {
        spans.add(
          TextSpan(
            text: '${line.substring(3)}\n',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
        );
        continue;
      } else if (line.startsWith('### ')) {
        spans.add(
          TextSpan(
            text: '${line.substring(4)}\n',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        );
        continue;
      } else {
        spans.add(_parseLineContent(line, theme));
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(
      children: spans,
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  TextSpan _parseLineContent(String line, ThemeData theme) {
    // Simple bold/italic regex fallback
    final List<TextSpan> parts = [];
    final boldPattern = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (final match in boldPattern.allMatches(line)) {
      if (match.start > start) {
        parts.add(TextSpan(text: line.substring(start, match.start)));
      }
      parts.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      start = match.end;
    }

    if (start < line.length) {
      parts.add(TextSpan(text: line.substring(start)));
    }

    return TextSpan(children: parts);
  }
}
