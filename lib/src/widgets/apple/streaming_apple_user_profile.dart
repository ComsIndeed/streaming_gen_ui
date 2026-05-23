import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_user_profile.dart';

/// Apple iOS/macOS specific mathematical Squircle user profile contact primitive.
class StreamingAppleUserProfile extends StatelessWidget {
  final PropertyStream props;

  const StreamingAppleUserProfile({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    return BaseThemedUserProfile(props: props, themeName: 'apple');
  }
}
