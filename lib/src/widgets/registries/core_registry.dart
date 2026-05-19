import 'package:flutter/widgets.dart';
import 'package:llm_json_stream/llm_json_stream.dart';

final Map<String, Widget Function(BuildContext context, PropertyStream props)>
coreRegistry = {};
