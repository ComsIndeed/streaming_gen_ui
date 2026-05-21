import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';
import 'package:streaming_gen_ui/src/models/generative_ui_config.dart';

class StreamingBentoCard extends StatelessWidget {
  final PropertyStream props;

  const StreamingBentoCard({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapStream = props.asMap;
    final cardStream = mapStream.stream;

    final titleProp = mapStream.getStringProperty("title");
    final titleStream = titleProp.stream;
    final titleFuture = titleProp.future;

    final subtitleProp = mapStream.getStringProperty("subtitle");
    final subtitleStream = subtitleProp.stream;
    final subtitleFuture = subtitleProp.future;

    final bodyProperty = mapStream.getListProperty("body");
    final footerProperty = mapStream.getMapProperty("footer");

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: cardStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final themeColorHex = data["themeColor"] as String?;
          final exactColor = data["exactColor"] as bool? ?? false;
          final provider = StreamingUiProvider.maybeOf(context);
          final rawThemeColor = _parseColor(themeColorHex) ?? theme.colorScheme.primary;
          final themeColor = adjustColorForTheme(
            context,
            rawThemeColor,
            isBackground: false,
            exactColor: exactColor,
            config: provider?.config,
          );

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                // ignore: deprecated_member_use
                color: themeColor.withOpacity(0.12),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: themeColor.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Block
                    FutureBuilder<String>(
                      future: titleFuture,
                      builder: (context, titleSnap) {
                        final isDone = titleSnap.connectionState == ConnectionState.done && titleSnap.hasData;
                        final initialTitle = isDone ? titleSnap.data! : '';

                        return AccumulatingStringStreamBuilder(
                          stream: titleStream,
                          initialValue: initialTitle,
                          builder: (context, titleText) {
                            if (titleText.isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  titleText,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FutureBuilder<String>(
                                  future: subtitleFuture,
                                  builder: (context, subSnap) {
                                    final isSubDone = subSnap.connectionState == ConnectionState.done && subSnap.hasData;
                                    final initialSub = isSubDone ? subSnap.data! : '';

                                    return AccumulatingStringStreamBuilder(
                                      stream: subtitleStream,
                                      initialValue: initialSub,
                                      builder: (context, subText) {
                                        if (subText.isEmpty) return const SizedBox.shrink();
                                        return Text(
                                          subText,
                                          style: TextStyle(
                                            fontSize: 13,
                                            // ignore: deprecated_member_use
                                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(height: 1),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),

                    // Body List of Widgets
                    StreamBuilder<List<dynamic>>(
                      stream: bodyProperty.stream,
                      builder: (context, bodySnap) {
                        final bodyList = bodySnap.data ?? const [];
                        if (bodyList.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            bodyList.length,
                            (index) => Padding(
                              padding: EdgeInsets.only(bottom: index == bodyList.length - 1 ? 0 : 12.0),
                              child: StreamingEntrance(
                                child: StreamingWidget(
                                  props: bodyProperty.getMapProperty('[$index]'),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Optional Footer Widget
                    FutureBuilder<String>(
                      future: footerProperty.asMap.getStringProperty("namespace").future,
                      builder: (context, footerSnap) {
                        if (footerSnap.connectionState == ConnectionState.done &&
                            footerSnap.hasData &&
                            footerSnap.data!.isNotEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1),
                              ),
                              StreamingEntrance(
                                child: StreamingWidget(props: footerProperty),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
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
