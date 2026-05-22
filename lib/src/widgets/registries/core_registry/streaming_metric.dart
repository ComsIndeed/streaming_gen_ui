import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

class StreamingMetric extends StatelessWidget {
  final PropertyStream props;

  const StreamingMetric({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapStream = props.asMap;
    final metricStream = mapStream.stream;

    final labelProp = mapStream.getStringProperty("label");
    final labelStream = labelProp.stream;
    final labelFuture = labelProp.future;

    final valueProp = mapStream.getStringProperty("value");
    final valueStream = valueProp.stream;
    final valueFuture = valueProp.future;

    final trendProp = mapStream.getStringProperty("trend");
    final trendStream = trendProp.stream;
    final trendFuture = trendProp.future;

    final trendDirProp = mapStream.getStringProperty("trendDirection");
    final trendDirStream = trendDirProp.stream;
    final trendDirFuture = trendDirProp.future;

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: metricStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final colorHex = data["color"] as String?;
          final themeColor = _parseColor(colorHex) ?? theme.colorScheme.primary;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                // ignore: deprecated_member_use
                color: themeColor.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label text (top)
                  FutureBuilder<String>(
                    future: labelFuture,
                    builder: (context, labelSnap) {
                      final isDone =
                          labelSnap.connectionState == ConnectionState.done &&
                          labelSnap.hasData;
                      final initialLabel = isDone ? labelSnap.data! : '';

                      return AccumulatingStringStreamBuilder(
                        stream: labelStream,
                        initialValue: initialLabel,
                        builder: (context, labelVal) {
                          return Text(
                            labelVal,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              // ignore: deprecated_member_use
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 6),

                  // Large Value Display (middle)
                  FutureBuilder<String>(
                    future: valueFuture,
                    builder: (context, valSnap) {
                      final isDone =
                          valSnap.connectionState == ConnectionState.done &&
                          valSnap.hasData;
                      final initialVal = isDone ? valSnap.data! : '...';

                      return AccumulatingStringStreamBuilder(
                        stream: valueStream,
                        initialValue: initialVal,
                        builder: (context, valText) {
                          return Text(
                            valText,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.8,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 6),

                  // Trend details (bottom)
                  FutureBuilder<String>(
                    future: trendDirFuture,
                    builder: (context, trendDirSnap) {
                      final isDoneDir =
                          trendDirSnap.connectionState ==
                              ConnectionState.done &&
                          trendDirSnap.hasData;
                      final initialDir = isDoneDir
                          ? trendDirSnap.data!
                          : 'neutral';

                      return AccumulatingStringStreamBuilder(
                        stream: trendDirStream,
                        initialValue: initialDir,
                        builder: (context, dirVal) {
                          final dir = dirVal.trim().toLowerCase();

                          IconData? trendIcon;
                          Color trendColor = theme.colorScheme.onSurfaceVariant;

                          if (dir == 'up') {
                            trendIcon = Icons.arrow_upward_rounded;
                            trendColor = const Color(0xFF059669);
                          } else if (dir == 'down') {
                            trendIcon = Icons.arrow_downward_rounded;
                            trendColor = const Color(0xFFDC2626);
                          }

                          return FutureBuilder<String>(
                            future: trendFuture,
                            builder: (context, trendSnap) {
                              final isDoneTrend =
                                  trendSnap.connectionState ==
                                      ConnectionState.done &&
                                  trendSnap.hasData;
                              final initialTrend = isDoneTrend
                                  ? trendSnap.data!
                                  : '';

                              return AccumulatingStringStreamBuilder(
                                stream: trendStream,
                                initialValue: initialTrend,
                                builder: (context, trendVal) {
                                  if (trendVal.isEmpty)
                                    return const SizedBox.shrink();

                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (trendIcon != null) ...[
                                        Icon(
                                          trendIcon,
                                          size: 14,
                                          color: trendColor,
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        trendVal,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: trendColor,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
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
