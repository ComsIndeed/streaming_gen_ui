import 'package:flutter/widgets.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';

final Map<String, Widget Function(BuildContext context, PropertyStream props)>
coreRegistry = {
  "core:text": (context, props) {
    final textStream = props.asMap.getStringProperty("content");
    return AccumulatingStringStreamBuilder(
      stream: textStream.stream,
      builder: (context, accumulatedText) => Text(accumulatedText),
    );
  },
};
