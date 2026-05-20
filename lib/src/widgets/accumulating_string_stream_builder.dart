import 'dart:async';
import 'package:flutter/widgets.dart';

/// A widget that listens to a stream of string chunks (e.g., from an LLM stream)
/// and progressively accumulates them into a single continuous string.
class AccumulatingStringStreamBuilder extends StatefulWidget {
  /// The stream of incoming string chunks.
  final Stream<String> stream;

  /// The builder function that receives the fully accumulated string.
  final Widget Function(BuildContext context, String accumulated) builder;

  /// The initial string value before any chunks are received.
  final String initialValue;

  const AccumulatingStringStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.initialValue = '',
  });

  @override
  State<AccumulatingStringStreamBuilder> createState() =>
      _AccumulatingStringStreamBuilderState();
}

const bool _verboseLog = true;

void _debugLog(String msg) {
  if (_verboseLog) {
    debugPrint('[GEN_UI:STREAM_BUILDER] [${DateTime.now().toIso8601String().substring(11, 23)}] $msg');
  }
}

class _AccumulatingStringStreamBuilderState
    extends State<AccumulatingStringStreamBuilder> {
  late String _accumulated;
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _accumulated = widget.initialValue;
    _debugLog('initState: initial value = "$_accumulated"');
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant AccumulatingStringStreamBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.stream, oldWidget.stream)) {
      _debugLog('didUpdateWidget: stream changed! Re-subscribing...');
      _unsubscribe();
      _accumulated = widget.initialValue;
      _subscribe();
    }
  }

  @override
  void dispose() {
    _debugLog('dispose called.');
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    _debugLog('Subscribing to stream: ${widget.stream.hashCode}...');
    bool hasReceivedData = false;
    _subscription = widget.stream.listen(
      (chunk) {
        if (mounted) {
          _debugLog('Received chunk: "${chunk.replaceAll('\n', '\\n')}"');
          setState(() {
            if (!hasReceivedData) {
              _accumulated = chunk;
              hasReceivedData = true;
            } else {
              _accumulated += chunk;
            }
          });
          _debugLog('Accumulated length is now: ${_accumulated.length}');
        } else {
          _debugLog('Received chunk but widget not mounted: "$chunk"');
        }
      },
      onError: (error) {
        _debugLog('Stream error: $error');
      },
      onDone: () {
        _debugLog('Stream done.');
      },
    );
  }

  void _unsubscribe() {
    if (_subscription != null) {
      _debugLog('Unsubscribing from stream...');
      _subscription?.cancel();
      _subscription = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _accumulated);
  }
}
