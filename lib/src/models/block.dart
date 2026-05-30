import 'dart:async';
import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/models/widget_registry.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_error_widget.dart';

const bool _verboseLog = false;

void _debugLog(String msg) {
  if (_verboseLog) {
    debugPrint(
      '[GEN_UI:BLOCK] [${DateTime.now().toIso8601String().substring(11, 23)}] $msg',
    );
  }
}

sealed class Block {
  final WidgetRegistry registry;
  final List<String> _chunks = [];
  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  bool _isClosed = false;

  Block({required this.registry}) {
    _debugLog('Block created: $runtimeType');
  }

  Stream<String>? _cachedStream;

  /// Returns a stream that replays all historically accumulated chunks immediately
  /// to each new subscriber, and then forwards future chunks in real-time.
  Stream<String> get stream {
    _cachedStream ??= Stream<String>.multi((controller) {
      // Emit all historical chunks immediately to this new subscriber
      for (final chunk in _chunks) {
        controller.add(chunk);
      }

      if (_isClosed) {
        controller.close();
        return;
      }

      // Forward real-time chunks from the broadcast _controller
      final subscription = _controller.stream.listen(
        (chunk) {
          controller.add(chunk);
        },
        onError: (err) {
          controller.addError(err);
        },
        onDone: () {
          controller.close();
        },
      );

      controller.onCancel = () {
        subscription.cancel();
      };
    });
    return _cachedStream!;
  }

  @mustCallSuper
  void addChunk(String chunk) {
    if (_isClosed) {
      _debugLog(
        '$runtimeType addChunk failed: Block already closed. (Chunk: "$chunk")',
      );
      return;
    }
    _chunks.add(chunk);
    _debugLog(
      '$runtimeType addChunk: buffered chunk "${chunk.replaceAll('\n', '\\n')}" (Total count: ${_chunks.length})',
    );
    _controller.add(chunk);
  }

  @mustCallSuper
  void close() {
    if (_isClosed) return;
    _isClosed = true;
    _debugLog('$runtimeType close called.');
    _controller.close();
  }

  Widget build(
    BuildContext context, {
    Widget Function(BuildContext context, String text)? textBlockBuilder,
  });
}

class TextBlock extends Block {
  TextBlock({required super.registry});

  @override
  Widget build(
    BuildContext context, {
    Widget Function(BuildContext context, String text)? textBlockBuilder,
  }) {
    return AccumulatingStringStreamBuilder(
      stream: stream,
      builder: (context, accumulated) {
        if (textBlockBuilder != null) {
          return textBlockBuilder(context, accumulated);
        }
        return Text(accumulated);
      },
    );
  }
}

class WidgetBlock extends Block {
  late final JsonStreamParser parser;
  late final Future<String> _nameFuture;
  late final PropertyStream rootProps;
  final bool showInternalErrors;
  final GenerativeUiErrorBuilder? errorBuilder;

  WidgetBlock({
    required super.registry,
    this.showInternalErrors = true,
    this.errorBuilder,
  }) {
    _debugLog('WidgetBlock constructor start.');
    parser = JsonStreamParser(stream, skipThoughts: true);
    // Note: The spec uses "namespace" as the identifier key.
    _nameFuture = parser.getStringProperty("namespace").future;
    rootProps = parser.getMapProperty('');
    _debugLog('WidgetBlock constructor end. rootProps initialized.');
  }

  @override
  Widget build(
    BuildContext context, {
    Widget Function(BuildContext context, String text)? textBlockBuilder,
  }) {
    return FutureBuilder<String>(
      future: _nameFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return StreamingErrorWidget(
            error: 'Error parsing widget: ${snapshot.error}',
            showInternalErrors: showInternalErrors,
            customBuilder: errorBuilder,
          );
        }

        final name = snapshot.data!;
        final widgetDefinition = registry.widgets[name];

        if (widgetDefinition == null) {
          return StreamingErrorWidget(
            error: 'Widget "$name" not found in registry',
            showInternalErrors: showInternalErrors,
            customBuilder: errorBuilder,
          );
        }

        final propsString = rootProps.toString();
        pushBuildTrace(name, propsString);
        try {
          final child = widgetDefinition.builder(context, rootProps);
          return StreamingWidgetWrapper(namespace: name, child: child);
        } catch (e, stack) {
          logGenUiError(
            namespace: name,
            error: e.toString(),
            properties: propsString,
            stack: stack,
          );
          return StreamingErrorWidget(
            error: 'Rendering Error ($name): $e\n$stack',
            showInternalErrors: showInternalErrors,
            customBuilder: errorBuilder,
          );
        } finally {
          popBuildTrace();
        }
      },
    );
  }
}
