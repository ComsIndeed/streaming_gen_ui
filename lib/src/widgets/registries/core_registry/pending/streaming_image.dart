import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';

class StreamingImage extends StatefulWidget {
  final PropertyStream props;

  const StreamingImage({super.key, required this.props});

  @override
  State<StreamingImage> createState() => _StreamingImageState();
}

class _StreamingImageState extends State<StreamingImage> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(duration: Durations.short4);
  }
}
