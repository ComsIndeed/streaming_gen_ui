import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_card.dart';

/// Brutalist retro high-contrast Pop Art card layout primitive.
class StreamingBrutalistCard extends StatelessWidget {
  final PropertyStream props;

  const StreamingBrutalistCard({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    return BaseThemedCard(props: props, themeName: 'brutalist');
  }
}
