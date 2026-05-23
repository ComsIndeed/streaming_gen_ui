import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_carousel.dart';

/// Skeuomorphic heavy bevel texture media carousel slider primitive.
class StreamingSkeumorphicCarousel extends StatelessWidget {
  final PropertyStream props;

  const StreamingSkeumorphicCarousel({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    return BaseThemedCarousel(props: props, themeName: 'skeumorphic');
  }
}
