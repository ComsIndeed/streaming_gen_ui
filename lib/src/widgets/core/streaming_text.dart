import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';

/// A utility widget that progressively listens to and accumulates a specific
/// text property from a [PropertyStream].
class StreamingText extends StatefulWidget {
  final PropertyStream props;
  final String propertyName;
  final String initialValue;
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
              // Empty parameter protection: do not render anything if empty
              if (accumulatedText.isEmpty) {
                return const SizedBox.shrink();
              }

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
