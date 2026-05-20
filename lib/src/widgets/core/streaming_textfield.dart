import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';

/// An input text field that progressively configures its labels and hint text,
/// and dynamically activates once its submit callback action resolves from the stream.
class StreamingTextField extends StatefulWidget {
  final PropertyStream props;

  const StreamingTextField({super.key, required this.props});

  @override
  State<StreamingTextField> createState() => _StreamingTextFieldState();
}

class _StreamingTextFieldState extends State<StreamingTextField> {
  late Stream<Map<String, dynamic>> _textFieldStream;
  late Future<String> _actionFuture;

  @override
  void initState() {
    super.initState();
    _initProps();
  }

  @override
  void didUpdateWidget(covariant StreamingTextField oldWidget) {
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
        final colorHex = data["color"] as String?;
        final fillColor = _parseColor(colorHex) ?? Theme.of(context).colorScheme.surfaceContainer;

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
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
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
