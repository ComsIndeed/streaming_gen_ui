import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_user_profile.dart';

/// Glassmorphic premium frosted glass profile layout primitive.
class StreamingGlassmorphicUserProfile extends StatelessWidget {
  final PropertyStream props;

  const StreamingGlassmorphicUserProfile({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    return BaseThemedUserProfile(props: props, themeName: 'glassmorphic');
  }
}
