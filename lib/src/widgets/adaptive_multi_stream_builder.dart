import 'dart:async';
import 'package:flutter/material.dart';

/// A utility widget that flatly listens to multiple streams and combines their emissions
/// to prevent deep, nested [StreamBuilder] pyramids.
class AdaptiveMultiStreamBuilder extends StatefulWidget {
  final List<Stream<dynamic>> streams;
  final List<dynamic>? initialData;
  final Widget Function(BuildContext context, List<dynamic> dataList) builder;

  const AdaptiveMultiStreamBuilder({
    super.key,
    required this.streams,
    this.initialData,
    required this.builder,
  });

  @override
  State<AdaptiveMultiStreamBuilder> createState() => _AdaptiveMultiStreamBuilderState();
}

class _AdaptiveMultiStreamBuilderState extends State<AdaptiveMultiStreamBuilder> {
  late List<dynamic> _latestValues;
  late List<StreamSubscription<dynamic>> _subscriptions;

  @override
  void initState() {
    super.initState();
    _latestValues = widget.initialData ?? List.filled(widget.streams.length, null);
    _subscribeAll();
  }

  @override
  void didUpdateWidget(covariant AdaptiveMultiStreamBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _unsubscribeAll();
    _latestValues = widget.initialData ?? List.filled(widget.streams.length, null);
    _subscribeAll();
  }

  void _subscribeAll() {
    _subscriptions = List.generate(widget.streams.length, (index) {
      return widget.streams[index].listen(
        (data) {
          if (mounted) {
            setState(() {
              _latestValues[index] = data;
            });
          } else {
            _latestValues[index] = data;
          }
        },
        onError: (_) {},
      );
    });
  }

  void _unsubscribeAll() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions = [];
  }

  @override
  void dispose() {
    _unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _latestValues);
  }
}
