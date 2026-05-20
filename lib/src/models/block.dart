import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/models/widget_registry.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';

const bool _verboseLog = true;

void _debugLog(String msg) {
  if (_verboseLog) {
    debugPrint('[GEN_UI:BLOCK] [${DateTime.now().toIso8601String().substring(11, 23)}] $msg');
  }
}

sealed class Block {
  final WidgetRegistry registry;
  final List<String> _chunks = [];
  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  bool _isClosed = false;

  late final Stream<String> stream;

  Block({required this.registry}) {
    _debugLog('Block created: $runtimeType');

    // Create a stable broadcast controller for the cached stream
    final controller = StreamController<String>.broadcast();

    controller.onListen = () {
      _debugLog('$runtimeType onListen: active subscriber connected. Replaying ${_chunks.length} chunks.');
      // Emit all historical chunks immediately to the active subscriber
      for (final chunk in _chunks) {
        controller.add(chunk);
      }

      if (_isClosed) {
        _debugLog('$runtimeType onListen: already closed, closing subscriber controller.');
        controller.close();
      } else {
        _debugLog('$runtimeType onListen: open, subscribing to real-time _controller.');
        // Forward future chunks in real-time
        final subscription = _controller.stream.listen(
          (chunk) {
            _debugLog('$runtimeType forwarded real-time chunk: "$chunk"');
            controller.add(chunk);
          },
          onError: (err) {
            _debugLog('$runtimeType forwarded error: $err');
            controller.addError(err);
          },
          onDone: () {
            _debugLog('$runtimeType real-time stream done, closing controller.');
            controller.close();
          },
        );
        controller.onCancel = () {
          _debugLog('$runtimeType subscriber cancelled subscription.');
          subscription.cancel();
        };
      }
    };

    stream = controller.stream;
  }

  @mustCallSuper
  void addChunk(String chunk) {
    if (_isClosed) {
      _debugLog('$runtimeType addChunk failed: Block already closed. (Chunk: "$chunk")');
      return;
    }
    _chunks.add(chunk);
    _debugLog('$runtimeType addChunk: buffered chunk "${chunk.replaceAll('\n', '\\n')}" (Total count: ${_chunks.length})');
    _controller.add(chunk);
  }

  @mustCallSuper
  void close() {
    if (_isClosed) return;
    _isClosed = true;
    _debugLog('$runtimeType close called.');
    _controller.close();
  }

  Widget build(BuildContext context);
}

class TextBlock extends Block {
  TextBlock({required super.registry});

  @override
  Widget build(BuildContext context) {
    return AccumulatingStringStreamBuilder(
      stream: stream,
      builder: (context, accumulated) {
        return Text(accumulated);
      },
    );
  }
}

class WidgetBlock extends Block {
  late final JsonStreamParser parser;
  late final Future<String> _nameFuture;
  late final PropertyStream rootProps;

  WidgetBlock({required super.registry}) {
    _debugLog('WidgetBlock constructor start.');
    parser = JsonStreamParser(stream, skipThoughts: true);
    // Note: The spec uses "namespace" as the identifier key.
    _nameFuture = parser.getStringProperty("namespace").future;
    rootProps = parser.getMapProperty('');
    _debugLog('WidgetBlock constructor end. rootProps initialized.');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _nameFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return Text('Error parsing widget: ${snapshot.error}');
        }

        final name = snapshot.data!;
        final widgetDefinition = registry.widgets[name];

        if (widgetDefinition == null) {
          return Text('Widget $name not found in registry');
        }

        return widgetDefinition.builder(context, rootProps);
      },
    );
  }
}
