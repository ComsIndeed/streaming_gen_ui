import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_card.dart';

/// Skeuomorphic heavy bevel texture card layout primitive.
class StreamingSkeumorphicCard extends StatelessWidget {
  final PropertyStream props;

  const StreamingSkeumorphicCard({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    return BaseThemedCard(props: props, themeName: 'skeumorphic');
  }
}
