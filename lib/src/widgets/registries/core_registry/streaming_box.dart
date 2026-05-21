import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';

class StreamingBox extends StatelessWidget {
  final PropertyStream props;

  const StreamingBox({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    final mapStream = props.asMap;
    final boxStream = mapStream.stream;
    final childProp = mapStream.getMapProperty("child");

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: boxStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final padding = _parseEdgeInsets(data["padding"]);
          final margin = _parseEdgeInsets(data["margin"]);
          final bgColor = _parseColor(data["bgColor"] as String?);
          final borderRadius = (data["borderRadius"] as num?)?.toDouble() ?? 8.0;
          final alignment = _parseAlignment(data["alignment"] as String?);
          final width = (data["width"] as num?)?.toDouble();
          final height = (data["height"] as num?)?.toDouble();

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: const Cubic(0.2, 0.8, 0.2, 1.0),
            margin: margin,
            width: width,
            height: height,
            alignment: alignment,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topLeft,
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: StreamingWidget(props: childProp),
              ),
            ),
          );
        },
      ),
    );
  }
}

EdgeInsetsGeometry? _parseEdgeInsets(dynamic value) {
  if (value == null) return null;
  if (value is num) return EdgeInsets.all(value.toDouble());
  if (value is String) {
    final parts = value.split(',').map((p) => double.tryParse(p.trim()) ?? 0.0).toList();
    if (parts.length == 1) return EdgeInsets.all(parts[0]);
    if (parts.length == 2) return EdgeInsets.symmetric(vertical: parts[0], horizontal: parts[1]);
    if (parts.length >= 4) {
      return EdgeInsets.only(left: parts[0], top: parts[1], right: parts[2], bottom: parts[3]);
    }
  }
  return null;
}

AlignmentGeometry? _parseAlignment(String? align) {
  if (align == null) return null;
  switch (align) {
    case 'topLeft': return Alignment.topLeft;
    case 'topCenter': return Alignment.topCenter;
    case 'topRight': return Alignment.topRight;
    case 'centerLeft': return Alignment.centerLeft;
    case 'center': return Alignment.center;
    case 'centerRight': return Alignment.centerRight;
    case 'bottomLeft': return Alignment.bottomLeft;
    case 'bottomCenter': return Alignment.bottomCenter;
    case 'bottomRight': return Alignment.bottomRight;
  }
  return null;
}

Color? _parseColor(String? hexString) {
  if (hexString == null) return null;
  var hex = hexString.replaceAll('#', '');
  if (hex.length == 3) {
    hex = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
  }
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  if (hex.length == 8) {
    final val = int.tryParse(hex, radix: 16);
    if (val != null) return Color(val);
  }
  return null;
}
