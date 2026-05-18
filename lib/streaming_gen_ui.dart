import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';

class StreamingGenUi {
  StreamingGenUi({required Stream<String> stream}) {
    final jsonStream = JsonStreamParser(stream);
  }

  Widget get view => const SizedBox.shrink();
}
