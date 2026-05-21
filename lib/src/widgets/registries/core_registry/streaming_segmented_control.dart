import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

/// A custom capsule-styled segmented control widget that displays swipable choices in
/// a row, with a sliding backdrop highlight animating to selected values when tapped.
class StreamingSegmentedControl extends StatefulWidget {
  final PropertyStream props;

  const StreamingSegmentedControl({super.key, required this.props});

  @override
  State<StreamingSegmentedControl> createState() => _StreamingSegmentedControlState();
}

class _StreamingSegmentedControlState extends State<StreamingSegmentedControl> {
  late Stream<Map<String, dynamic>> _controlStream;
  late Future<String> _actionFuture;
  String? _localSelected;

  @override
  void initState() {
    super.initState();
    _initProps();
  }

  @override
  void didUpdateWidget(covariant StreamingSegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initProps();
    }
  }

  void _initProps() {
    final mapStream = widget.props.asMap;
    _controlStream = mapStream.stream;
    _actionFuture = mapStream.getStringProperty("action").future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _controlStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final rawOptions = data["options"] as List<dynamic>? ?? const [];
          final options = rawOptions.map((e) => e.toString()).toList();
          final defaultSelection = data["selected"] as String? ?? (options.isNotEmpty ? options.first : "");

          if (options.isEmpty) return const SizedBox.shrink();

          final currentSelected = _localSelected ?? defaultSelection;
          final selectedIndex = options.indexOf(currentSelected).clamp(0, options.length - 1);

          return FutureBuilder<String>(
            future: _actionFuture,
            builder: (context, actionSnapshot) {
              final action = actionSnapshot.data;
              final isEnabled = actionSnapshot.connectionState == ConnectionState.done && action != null;

              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.08),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tabWidth = constraints.maxWidth / options.length;

                    return Stack(
                      children: [
                        // Animated sliding slider capsule
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 250),
                          curve: const Cubic(0.2, 0.8, 0.2, 1.0), // Standard Snap Curve
                          left: tabWidth * selectedIndex,
                          top: 0,
                          bottom: 0,
                          width: tabWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isEnabled
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isEnabled
                                  ? [
                                      BoxShadow(
                                        color: theme.colorScheme.primary.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                          ),
                        ),
                        // Segment tabs
                        Row(
                          children: List.generate(options.length, (index) {
                            final option = options[index];
                            final isTabSelected = option == currentSelected;

                            return Expanded(
                              child: GestureDetector(
                                onTap: isEnabled
                                    ? () {
                                        setState(() {
                                          _localSelected = option;
                                        });
                                        debugPrint('[GEN_UI:SEGMENT] Selected: "$option" -> $action');
                                      }
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  color: Colors.transparent, // expand hit area
                                  alignment: Alignment.center,
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 150),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isTabSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isTabSelected
                                          ? (isEnabled
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface)
                                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                    ),
                                    child: Text(
                                      option,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
