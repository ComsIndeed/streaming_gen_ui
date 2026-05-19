import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/models/widget_registry.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';

sealed class Block {
  final WidgetRegistry registry;
  final List<String> _chunks = [];
  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  bool _isClosed = false;

  Block({required this.registry});

  /// A stream of chunks for this block.
  /// When a new listener subscribes, all historical chunks are fired immediately,
  /// followed by any new chunks in real-time.
  Stream<String> get stream {
    final controller = StreamController<String>();

    // Emit all historical chunks immediately
    for (final chunk in _chunks) {
      controller.add(chunk);
    }

    if (_isClosed) {
      controller.close();
    } else {
      // Forward new chunks
      final subscription = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () => subscription.cancel();
    }

    return controller.stream;
  }

  @mustCallSuper
  void addChunk(String chunk) {
    if (_isClosed) return;
    _chunks.add(chunk);
    _controller.add(chunk);
  }

  @mustCallSuper
  void close() {
    if (_isClosed) return;
    _isClosed = true;
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

  WidgetBlock({required super.registry}) {
    parser = JsonStreamParser(stream, skipThoughts: true);
    // Note: The spec uses "namespace" as the identifier key.
    _nameFuture = parser.getStringProperty("namespace").future;
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
        final widgetBuilder = registry.widgets[name];

        if (widgetBuilder == null) {
          return Text('Widget $name not found in registry');
        }

        return widgetBuilder(context, parser.getMapProperty(''));
      },
    );
  }
}
