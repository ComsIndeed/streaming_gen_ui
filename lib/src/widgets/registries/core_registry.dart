import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';

final Map<String, Widget Function(BuildContext context, PropertyStream props)>
coreRegistry = {
  // Basic rendering
  "core:text": (context, props) {
    final textStream = props.asMap.getStringProperty("content");
    return AccumulatingStringStreamBuilder(
      stream: textStream.stream,
      builder: (context, accumulatedText) => Text(accumulatedText),
    );
  },
  // Demonstrates how a child is passed
  "core:elevated_button": (context, props) {
    final child = props.asMap.getMapProperty("child");
    return ElevatedButton(
      onPressed: null, 
      child: StreamingWidget(props: child),
    );
  },
};
