import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_card.dart';

/// Neumorphic soft tactile shadow card layout primitive.
class StreamingNeumorphicCard extends StatelessWidget {
  final PropertyStream props;

  const StreamingNeumorphicCard({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    return BaseThemedCard(props: props, themeName: 'neumorphic');
  }
}
