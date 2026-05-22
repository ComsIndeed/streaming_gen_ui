import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';

import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

/// A utility widget that progressively listens to and accumulates a specific
/// text property from a [PropertyStream].
class StreamingText extends StatefulWidget {
  /// The reactive property stream to parse from.
  final PropertyStream props;

  /// The JSON key of the text property to parse (defaults to 'content').
  final String propertyName;

  /// The fallback/initial text before the stream starts emitting.
  final String initialValue;

  /// A custom builder function to style or layout the accumulated text.
  final Widget Function(BuildContext context, String accumulatedText)? builder;

  const StreamingText({
    super.key,
    required this.props,
    this.propertyName = 'content',
    this.initialValue = '',
    this.builder,
  });

  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText> {
  late Stream<String> _textStream;
  late Future<String> _textFuture;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props) ||
        widget.propertyName != oldWidget.propertyName) {
      _initStream();
    }
  }

  void _initStream() {
    final prop = widget.props.asMap.getStringProperty(widget.propertyName);
    _textStream = prop.stream;
    _textFuture = prop.future;
  }

  @override
  Widget build(BuildContext context) {
    return StreamingEntrance(
      child: FutureBuilder<String>(
        future: _textFuture,
        builder: (context, snapshot) {
          final isDone =
              snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData;
          final currentInitial = isDone ? snapshot.data! : widget.initialValue;

          return AccumulatingStringStreamBuilder(
            stream: _textStream,
            initialValue: currentInitial,
            builder: (context, accumulatedText) {
              if (widget.builder != null) {
                return widget.builder!(context, accumulatedText);
              }
              return Text(accumulatedText);
            },
          );
        },
      ),
    );
  }
}
