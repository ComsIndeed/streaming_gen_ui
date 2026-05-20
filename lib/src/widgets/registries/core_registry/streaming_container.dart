import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';

/// A styled box container that dynamically listens to visual specifications
/// from a [PropertyStream] and smoothly animates its dimensions and color properties.
class StreamingContainer extends StatefulWidget {
  final PropertyStream props;

  const StreamingContainer({super.key, required this.props});

  @override
  State<StreamingContainer> createState() => _StreamingContainerState();
}

class _StreamingContainerState extends State<StreamingContainer> {
  late Stream<Map<String, dynamic>> _containerStream;
  late PropertyStream _childProp;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant StreamingContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.props != oldWidget.props) {
      _initStream();
    }
  }

  void _initStream() {
    final mapStream = widget.props.asMap;
    _containerStream = mapStream.stream;
    _childProp = mapStream.getMapProperty("child");
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _containerStream,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const {};

        final colorHex = data["color"] as String?;
        final width = (data["width"] as num?)?.toDouble();
        final height = (data["height"] as num?)?.toDouble();
        
        final parsedColor = _parseColor(colorHex);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: parsedColor ?? Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              // ignore: deprecated_member_use
              color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: StreamingWidget(props: _childProp),
          ),
        );
      },
    );
  }
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
