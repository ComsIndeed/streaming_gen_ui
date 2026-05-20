import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';

import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

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
    if (!identical(widget.props, oldWidget.props)) {
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
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _textFieldStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};
          final hintText = data["placeholder"] as String? ?? data["hintText"] as String?;
          final labelText = data["labelText"] as String?;
          final colorHex = data["color"] as String?;
          final fillColor = _parseColor(colorHex) ?? theme.colorScheme.surfaceContainerLow;

          return FutureBuilder<String>(
            future: _actionFuture,
            builder: (context, actionSnapshot) {
              final action = actionSnapshot.data;
              final isEnabled = actionSnapshot.connectionState == ConnectionState.done && action != null;

              return TextField(
                enabled: isEnabled,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: hintText ?? "Enter text...",
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.35),
                    fontSize: 14,
                  ),
                  labelText: labelText,
                  labelStyle: TextStyle(color: theme.colorScheme.primary),
                  filled: true,
                  fillColor: isEnabled
                      ? fillColor
                      : theme.colorScheme.surfaceContainerLowest.withOpacity(0.4),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: isEnabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.12),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      // ignore: deprecated_member_use
                      color: theme.colorScheme.outline.withOpacity(0.12),
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      // ignore: deprecated_member_use
                      color: theme.colorScheme.outline.withOpacity(0.06),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                onSubmitted: isEnabled ? (value) {
                  debugPrint('[GEN_UI:TEXTFIELD] Submitted: "$value" -> $action');
                } : null,
              );
            },
          );
        },
      ),
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
