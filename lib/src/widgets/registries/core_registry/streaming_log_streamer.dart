import 'dart:async';
import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

/// A premium, terminal-styled log streaming emulator with scrolling indicators.
class StreamingLogStreamer extends StatefulWidget {
  final PropertyStream props;

  const StreamingLogStreamer({super.key, required this.props});

  @override
  State<StreamingLogStreamer> createState() => _StreamingLogStreamerState();
}

class _StreamingLogStreamerState extends State<StreamingLogStreamer> {
  late Stream<Map<String, dynamic>> _logStream;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _initProps();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StreamingLogStreamer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initProps();
    }
  }

  void _initProps() {
    final mapStream = widget.props.asMap;
    _logStream = mapStream.stream;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _logStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};
          final rawLogs = data["logs"] as List<dynamic>? ?? const [];
          final logs = rawLogs.map((e) => e.toString()).toList();

          _scrollToBottom();

          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), // Slate 900
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF1E293B),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                children: [
                  // Header bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: const Color(0xFF1E293B), // Slate 800
                    child: Row(
                      children: [
                        // Window buttons
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                          ],
                        ),
                        const Expanded(
                          child: Text(
                            "console.log",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24), // spacing offset
                      ],
                    ),
                  ),
                  // Log contents
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: logs.isEmpty ? 1 : logs.length,
                      itemBuilder: (context, index) {
                        if (logs.isEmpty) {
                          return Row(
                            children: const [
                              Text(
                                "\$ ",
                                style: TextStyle(color: Color(0xFF10B981), fontFamily: 'monospace', fontSize: 12),
                              ),
                              _FlashingCursor(),
                            ],
                          );
                        }

                        final isLast = index == logs.length - 1;
                        final logText = logs[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "\$ ",
                                style: TextStyle(color: Color(0xFF10B981), fontFamily: 'monospace', fontSize: 12),
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: Color(0xFFF8FAFC),
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                    children: [
                                      TextSpan(text: logText),
                                      if (isLast) const WidgetSpan(child: _FlashingCursor()),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
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

class _FlashingCursor extends StatefulWidget {
  const _FlashingCursor();

  @override
  State<_FlashingCursor> createState() => _FlashingCursorState();
}

class _FlashingCursorState extends State<_FlashingCursor> {
  bool _visible = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _visible = !_visible;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _visible ? 1.0 : 0.0,
      child: const Text(
        "█",
        style: TextStyle(
          color: Color(0xFF10B981),
          fontSize: 12,
        ),
      ),
    );
  }
}
