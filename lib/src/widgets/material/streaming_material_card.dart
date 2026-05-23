import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_card.dart';

/// Material 3 specific card layout primitive.
class StreamingMaterialCard extends StatelessWidget {
  final PropertyStream props;

  const StreamingMaterialCard({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    return BaseThemedCard(props: props, themeName: 'material');
  }
}
