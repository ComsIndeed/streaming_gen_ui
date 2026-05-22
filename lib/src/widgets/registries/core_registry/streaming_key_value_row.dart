import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

class StreamingKeyValueRow extends StatelessWidget {
  final PropertyStream props;

  const StreamingKeyValueRow({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapStream = props.asMap;
    final rowStream = mapStream.stream;

    final labelProp = mapStream.getStringProperty("label");
    final labelStream = labelProp.stream;
    final labelFuture = labelProp.future;

    final valueProp = mapStream.getStringProperty("value");
    final valueStream = valueProp.stream;
    final valueFuture = valueProp.future;

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: rowStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final isMonospace = data["isMonospace"] as bool? ?? false;
          final colorHex = data["color"] as String?;
          final color = _parseColor(colorHex) ?? theme.colorScheme.onSurface;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Label
                Expanded(
                  child: FutureBuilder<String>(
                    future: labelFuture,
                    builder: (context, labelSnap) {
                      final isDone =
                          labelSnap.connectionState == ConnectionState.done &&
                          labelSnap.hasData;
                      final initialLabel = isDone ? labelSnap.data! : '';

                      return AccumulatingStringStreamBuilder(
                        stream: labelStream,
                        initialValue: initialLabel,
                        builder: (context, labelText) {
                          return Text(
                            labelText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              // ignore: deprecated_member_use
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.55,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // Right Value
                FutureBuilder<String>(
                  future: valueFuture,
                  builder: (context, valueSnap) {
                    final isDone =
                        valueSnap.connectionState == ConnectionState.done &&
                        valueSnap.hasData;
                    final initialValue = isDone ? valueSnap.data! : '';

                    return AccumulatingStringStreamBuilder(
                      stream: valueStream,
                      initialValue: initialValue,
                      builder: (context, valueText) {
                        return Text(
                          valueText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isMonospace
                                ? FontWeight.w600
                                : FontWeight.w600,
                            fontFamily: isMonospace ? 'monospace' : null,
                            color: color,
                          ),
                          textAlign: TextAlign.right,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
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
