import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_card.dart';

/// Windows Fluent specific card layout primitive.
class StreamingFluentCard extends StatelessWidget {
  final PropertyStream props;

  const StreamingFluentCard({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    return BaseThemedCard(props: props, themeName: 'fluent');
  }
}
