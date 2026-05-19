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

class _AccumulatingStringStreamBuilderState
    extends State<AccumulatingStringStreamBuilder> {
  late String _accumulated;
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _accumulated = widget.initialValue;
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant AccumulatingStringStreamBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stream != oldWidget.stream) {
      _unsubscribe();
      _accumulated = widget.initialValue;
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    _subscription = widget.stream.listen(
      (chunk) {
        if (mounted) {
          setState(() {
            _accumulated += chunk;
          });
        }
      },
      onError: (error) {
        // Gracefully ignore or handle stream errors
      },
    );
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _accumulated);
  }
}
