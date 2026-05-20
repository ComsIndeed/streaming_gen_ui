import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';

class StreamingBentoCard extends StatefulWidget {
  final PropertyStream props;

  const StreamingBentoCard({super.key, required this.props});

  @override
  State<StreamingBentoCard> createState() => _StreamingBentoCardState();
}

class _StreamingBentoCardState extends State<StreamingBentoCard> {
  late Stream<Map<String, dynamic>> _cardStream;
  late Stream<String> _titleStream;
  late Future<String> _titleFuture;
  late Stream<String> _subtitleStream;
  late Future<String> _subtitleFuture;
  late ListPropertyStream<dynamic> _bodyProperty;
  late PropertyStream _footerProperty;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant StreamingBentoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initStream();
    }
  }

  void _initStream() {
    final mapStream = widget.props.asMap;
    _cardStream = mapStream.stream;

    final titleProp = mapStream.getStringProperty("title");
    _titleStream = titleProp.stream;
    _titleFuture = titleProp.future;

    final subtitleProp = mapStream.getStringProperty("subtitle");
    _subtitleStream = subtitleProp.stream;
    _subtitleFuture = subtitleProp.future;

    _bodyProperty = mapStream.getListProperty("body");
    _footerProperty = mapStream.getMapProperty("footer");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _cardStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final themeColorHex = data["themeColor"] as String?;
          final themeColor = _parseColor(themeColorHex) ?? theme.colorScheme.primary;

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
                      future: _titleFuture,
                      builder: (context, titleSnap) {
                        final isDone = titleSnap.connectionState == ConnectionState.done && titleSnap.hasData;
                        final initialTitle = isDone ? titleSnap.data! : '';

                        return AccumulatingStringStreamBuilder(
                          stream: _titleStream,
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
                                  future: _subtitleFuture,
                                  builder: (context, subSnap) {
                                    final isSubDone = subSnap.connectionState == ConnectionState.done && subSnap.hasData;
                                    final initialSub = isSubDone ? subSnap.data! : '';

                                    return AccumulatingStringStreamBuilder(
                                      stream: _subtitleStream,
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
                      stream: _bodyProperty.stream,
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
                                  props: _bodyProperty.getMapProperty('[$index]'),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Optional Footer Widget
                    FutureBuilder<String>(
                      future: _footerProperty.asMap.getStringProperty("namespace").future,
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
                                child: StreamingWidget(props: _footerProperty),
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
