import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_user_profile.dart';

/// Windows Fluent specific user profile primitive.
class StreamingFluentUserProfile extends StatelessWidget {
  final PropertyStream props;

  const StreamingFluentUserProfile({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    return BaseThemedUserProfile(props: props, themeName: 'fluent');
  }
}
