import 'package:flutter/widgets.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';

/// A utility widget that progressively listens to and accumulates a specific
/// text property from a [PropertyStream]. 
///
/// It provides a clean API for developers creating custom widgets in the registry.
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

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.props != oldWidget.props || widget.propertyName != oldWidget.propertyName) {
      _initStream();
    }
  }

  void _initStream() {
    _textStream = widget.props.asMap.getStringProperty(widget.propertyName).stream;
  }

  @override
  Widget build(BuildContext context) {
    return AccumulatingStringStreamBuilder(
      stream: _textStream,
      initialValue: widget.initialValue,
      builder: (context, accumulatedText) {
        if (widget.builder != null) {
          return widget.builder!(context, accumulatedText);
        }
        return Text(accumulatedText);
      },
    );
  }
}
