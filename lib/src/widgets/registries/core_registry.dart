import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/models/widget_registry.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_text.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';

final Map<String, WidgetDefinition>
coreRegistry = {
  // Basic text rendering
  "core:text": WidgetDefinition(
    builder: (context, props) => StreamingText(props: props),
    description: "Displays a streamed block of text.",
    properties: {"content": "String (the text content to display)"},
    jsonExample: '{"namespace":"core:text","content":"Hello World!"}',
  ),
  
  // Dynamic action-activated button
  "core:elevated_button": WidgetDefinition(
    builder: (context, props) => _StreamingElevatedButton(props: props),
    description: "A clickable button with action callbacks.",
    properties: {
      "child": "Component (a nested component, usually core:text)",
      "action": "String (the callback action key)"
    },
    jsonExample: '{"namespace":"core:elevated_button","child":{"namespace":"core:text","content":"Submit"},"action":"submit_action"}',
  ),
  
  // Highly optimized self-appending Column
  "core:column": WidgetDefinition(
    builder: (context, props) {
      final childrenProperty = props.asMap.getListProperty("children");
      return _StreamingColumn(childrenProperty: childrenProperty);
    },
    description: "A vertical layout system containing nested children.",
    properties: {"children": "List<Component> (the child components in vertical order)"},
    jsonExample: '{"namespace":"core:column","children":[{"namespace":"core:text","content":"First"},{"namespace":"core:text","content":"Second"}]}',
  ),
  
  // Highly optimized self-appending Row
  "core:row": WidgetDefinition(
    builder: (context, props) {
      final childrenProperty = props.asMap.getListProperty("children");
      return _StreamingRow(childrenProperty: childrenProperty);
    },
    description: "A horizontal layout system containing nested children.",
    properties: {"children": "List<Component> (the child components in horizontal order)"},
    jsonExample: '{"namespace":"core:row","children":[{"namespace":"core:text","content":"Left"},{"namespace":"core:text","content":"Right"}]}',
  ),
  
  // Smoothly animating styling container
  "core:container": WidgetDefinition(
    builder: (context, props) => _StreamingContainer(props: props),
    description: "A styled box container that smoothly animates dimensions and colors when parsed.",
    properties: {
      "child": "Component (optional nested child component)",
      "width": "Num (optional width)",
      "height": "Num (optional height)",
      "color": "String (optional HEX color code, e.g. #ff5500)"
    },
    jsonExample: '{"namespace":"core:container","child":{"namespace":"core:text","content":"Box!"},"width":200,"height":100,"color":"#ff5500"}',
  ),
  
  // Dynamic action-activated TextField
  "core:textfield": WidgetDefinition(
    builder: (context, props) => _StreamingTextField(props: props),
    description: "An input text field for user input.",
    properties: {
      "placeholder": "String (the input placeholder text)",
      "action": "String (the callback action key triggered on submit)"
    },
    jsonExample: '{"namespace":"core:textfield","placeholder":"Enter name...","action":"search_action"}',
  ),
};

// --- Stateful Cached Core Widgets ---

class _StreamingElevatedButton extends StatefulWidget {
  final PropertyStream props;

  const _StreamingElevatedButton({required this.props});

  @override
  State<_StreamingElevatedButton> createState() => _StreamingElevatedButtonState();
}

class _StreamingElevatedButtonState extends State<_StreamingElevatedButton> {
  late Future<String> _actionFuture;
  late PropertyStream _childProp;

  @override
  void initState() {
    super.initState();
    _initProps();
  }

  @override
  void didUpdateWidget(covariant _StreamingElevatedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.props != oldWidget.props) {
      _initProps();
    }
  }

  void _initProps() {
    final mapStream = widget.props.asMap;
    _actionFuture = mapStream.getStringProperty("action").future;
    _childProp = mapStream.getMapProperty("child");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _actionFuture,
      builder: (context, snapshot) {
        final action = snapshot.data;
        final isEnabled = snapshot.connectionState == ConnectionState.done && action != null;
        
        return ElevatedButton(
          onPressed: isEnabled ? () {
            debugPrint('Interaction: Button action clicked -> $action');
          } : null,
          child: StreamingWidget(props: _childProp),
        );
      },
    );
  }
}

class _StreamingContainer extends StatefulWidget {
  final PropertyStream props;

  const _StreamingContainer({required this.props});

  @override
  State<_StreamingContainer> createState() => _StreamingContainerState();
}

class _StreamingContainerState extends State<_StreamingContainer> {
  late Stream<Map<String, dynamic>> _containerStream;
  late PropertyStream _childProp;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant _StreamingContainer oldWidget) {
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
            color: parsedColor,
            borderRadius: parsedColor != null ? BorderRadius.circular(8) : null,
          ),
          child: StreamingWidget(props: _childProp),
        );
      },
    );
  }
}

class _StreamingTextField extends StatefulWidget {
  final PropertyStream props;

  const _StreamingTextField({required this.props});

  @override
  State<_StreamingTextField> createState() => _StreamingTextFieldState();
}

class _StreamingTextFieldState extends State<_StreamingTextField> {
  late Stream<Map<String, dynamic>> _textFieldStream;
  late Future<String> _actionFuture;

  @override
  void initState() {
    super.initState();
    _initProps();
  }

  @override
  void didUpdateWidget(covariant _StreamingTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.props != oldWidget.props) {
      _initProps();
    }
  }

  void _initProps() {
    final mapStream = widget.props.asMap;
    _textFieldStream = mapStream.stream;
    _actionFuture = mapStream.getStringProperty("action").future;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _textFieldStream,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const {};
        final hintText = data["placeholder"] as String? ?? data["hintText"] as String?;
        final labelText = data["labelText"] as String?;

        return FutureBuilder<String>(
          future: _actionFuture,
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
  }
}

// --- Helper Stateful Widgets & Parsers ---

class _StreamingColumn extends StatelessWidget {
  final ListPropertyStream<dynamic> childrenProperty;

  const _StreamingColumn({required this.childrenProperty});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: childrenProperty.stream,
      builder: (context, snapshot) {
        final list = snapshot.data ?? const [];

        if (snapshot.connectionState == ConnectionState.done && list.isEmpty) {
          debugPrint('[GEN_UI:WARNING] core:column layout streaming complete but contains 0 items!');
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: list.map((elementProp) => StreamingWidget(props: elementProp as PropertyStream)).toList(),
        );
      },
    );
  }
}

class _StreamingRow extends StatelessWidget {
  final ListPropertyStream<dynamic> childrenProperty;

  const _StreamingRow({required this.childrenProperty});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: childrenProperty.stream,
      builder: (context, snapshot) {
        final list = snapshot.data ?? const [];

        if (snapshot.connectionState == ConnectionState.done && list.isEmpty) {
          debugPrint('[GEN_UI:WARNING] core:row layout streaming complete but contains 0 items!');
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: list.map((elementProp) => StreamingWidget(props: elementProp as PropertyStream)).toList(),
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
