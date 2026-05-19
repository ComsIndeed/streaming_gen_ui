import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';

final Map<String, Widget Function(BuildContext context, PropertyStream props)>
coreRegistry = {
  // Basic text rendering
  "core:text": (context, props) {
    final textStream = props.asMap.getStringProperty("content");
    return AccumulatingStringStreamBuilder(
      stream: textStream.stream,
      builder: (context, accumulatedText) => Text(accumulatedText),
    );
  },
  // Dynamic action-activated button
  "core:elevated_button": (context, props) {
    final mapStream = props.asMap;
    final child = mapStream.getMapProperty("child");
    final actionFuture = mapStream.getStringProperty("action").future;

    return FutureBuilder<String>(
      future: actionFuture,
      builder: (context, snapshot) {
        final action = snapshot.data;
        final isEnabled = snapshot.connectionState == ConnectionState.done && action != null;
        
        return ElevatedButton(
          onPressed: isEnabled ? () {
            // Action dispatcher placeholder
            debugPrint('Interaction: Button action clicked -> $action');
          } : null,
          child: StreamingWidget(props: child),
        );
      },
    );
  },
  // Highly optimized self-appending Column
  "core:column": (context, props) {
    final childrenProperty = props.asMap.getListProperty("children");
    return _StreamingColumn(childrenProperty: childrenProperty);
  },
  // Highly optimized self-appending Row
  "core:row": (context, props) {
    final childrenProperty = props.asMap.getListProperty("children");
    return _StreamingRow(childrenProperty: childrenProperty);
  },
  // Smoothly animating styling container
  "core:container": (context, props) {
    final mapStream = props.asMap;
    final childProperty = mapStream.getMapProperty("child");

    return StreamBuilder<Map<String, dynamic>>(
      stream: mapStream.stream,
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
            color: parsedColor,
            borderRadius: parsedColor != null ? BorderRadius.circular(8) : null,
          ),
          child: StreamingWidget(props: childProperty),
        );
      },
    );
  },
  // Dynamic action-activated TextField
  "core:textfield": (context, props) {
    final mapStream = props.asMap;
    final actionFuture = mapStream.getStringProperty("action").future;

    return StreamBuilder<Map<String, dynamic>>(
      stream: mapStream.stream,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const {};
        final hintText = data["placeholder"] as String? ?? data["hintText"] as String?;
        final labelText = data["labelText"] as String?;

        return FutureBuilder<String>(
          future: actionFuture,
          builder: (context, actionSnapshot) {
            final action = actionSnapshot.data;
            final isEnabled = actionSnapshot.connectionState == ConnectionState.done && action != null;

            return TextField(
              enabled: isEnabled,
              decoration: InputDecoration(
                hintText: hintText,
                labelText: labelText,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: isEnabled ? (value) {
                debugPrint('Interaction: TextField submitted value -> $value for action -> $action');
              } : null,
            );
          },
        );
      },
    );
  },
};

// --- Helper Stateful Widgets & Parsers ---

class _StreamingColumn extends StatefulWidget {
  final ListPropertyStream<dynamic> childrenProperty;

  const _StreamingColumn({required this.childrenProperty});

  @override
  State<_StreamingColumn> createState() => _StreamingColumnState();
}

class _StreamingColumnState extends State<_StreamingColumn> {
  final List<Widget> _children = [];

  @override
  void initState() {
    super.initState();
    // Arm the trap: only append new elements when they start parsing
    widget.childrenProperty.onElement((propertyStream, index) {
      if (mounted) {
        setState(() {
          _children.add(StreamingWidget(props: propertyStream));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _children,
    );
  }
}

class _StreamingRow extends StatefulWidget {
  final ListPropertyStream<dynamic> childrenProperty;

  const _StreamingRow({required this.childrenProperty});

  @override
  State<_StreamingRow> createState() => _StreamingRowState();
}

class _StreamingRowState extends State<_StreamingRow> {
  final List<Widget> _children = [];

  @override
  void initState() {
    super.initState();
    widget.childrenProperty.onElement((propertyStream, index) {
      if (mounted) {
        setState(() {
          _children.add(StreamingWidget(props: propertyStream));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: _children,
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
