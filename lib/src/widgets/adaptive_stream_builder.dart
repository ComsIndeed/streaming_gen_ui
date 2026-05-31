import 'dart:async';
import 'package:flutter/material.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';

/// A high-performance stream builder replacing standard [StreamBuilder] to eliminate
/// the 1-frame asynchronous microtask delay when rendering historical or static content.
///
/// It exposes the exact same [AsyncSnapshot] signature as standard [StreamBuilder]
/// to ensure 100% backward compatibility with existing card builders.
class AdaptiveStreamBuilder<T> extends StatefulWidget {
  final Stream<T> stream;
  final T? initialData;
  final Widget Function(BuildContext context, AsyncSnapshot<T> snapshot) builder;

  const AdaptiveStreamBuilder({
    super.key,
    required this.stream,
    this.initialData,
    required this.builder,
  });

  @override
  State<AdaptiveStreamBuilder<T>> createState() => _AdaptiveStreamBuilderState<T>();
}

class _AdaptiveStreamBuilderState<T> extends State<AdaptiveStreamBuilder<T>> {
  T? _latestValue;
  StreamSubscription<T>? _subscription;
  ConnectionState _connectionState = ConnectionState.waiting;

  @override
  void initState() {
    super.initState();
    _latestValue = widget.initialData;
    if (_latestValue != null) {
      _connectionState = ConnectionState.active;
    }

    // 1. Context Fallback: If in historical mode, try to seed the value synchronously
    if (_latestValue == null) {
      final element = context.getElementForInheritedWidgetOfExactType<StreamingUiProvider>();
      final provider = element?.widget as StreamingUiProvider?;
      if (provider != null && provider.disableAnimations) {
        if (T == Map<String, dynamic>) {
          _latestValue = provider.latestProperties as T?;
          if (_latestValue != null) {
            _connectionState = ConnectionState.active;
          }
        }
      }
    }

    // 2. Subscribe and synchronously capture any immediate/cached stream emissions
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant AdaptiveStreamBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stream != oldWidget.stream) {
      _unsubscribe();
      _latestValue = widget.initialData;
      _connectionState = _latestValue != null ? ConnectionState.active : ConnectionState.waiting;
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription = widget.stream.listen(
      (data) {
        if (mounted) {
          setState(() {
            _latestValue = data;
            _connectionState = ConnectionState.active;
          });
        } else {
          // Captures synchronous replay emissions during initState() execution
          _latestValue = data;
          _connectionState = ConnectionState.active;
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _connectionState = ConnectionState.active;
          });
        } else {
          _connectionState = ConnectionState.active;
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _connectionState = ConnectionState.done;
          });
        } else {
          _connectionState = ConnectionState.done;
        }
      },
    );
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _latestValue != null
        ? AsyncSnapshot<T>.withData(_connectionState, _latestValue as T)
        : AsyncSnapshot<T>.nothing();
    return widget.builder(context, snapshot);
  }
}
