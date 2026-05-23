import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_user_profile.dart';

/// Material 3 specific user profile contact center primitive.
class StreamingMaterialUserProfile extends StatelessWidget {
  final PropertyStream props;

  const StreamingMaterialUserProfile({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    return BaseThemedUserProfile(props: props, themeName: 'material');
  }
}
