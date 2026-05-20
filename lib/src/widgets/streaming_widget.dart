import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/models/widget_registry.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_error_widget.dart';

/// Hosts the active [WidgetRegistry] in the widget tree.
class StreamingUiProvider extends InheritedWidget {
  final WidgetRegistry registry;
  final bool showInternalErrors;
  final GenerativeUiErrorBuilder? errorBuilder;

  const StreamingUiProvider({
    super.key,
    required this.registry,
    required this.showInternalErrors,
    this.errorBuilder,
    required super.child,
  });

  /// Tries to look up the [WidgetRegistry] from the closest ancestor [StreamingUiProvider].
  static StreamingUiProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StreamingUiProvider>();
  }

  /// Looks up the [WidgetRegistry] from the closest ancestor [StreamingUiProvider].
  /// Throws an assertion error if not found.
  static WidgetRegistry of(BuildContext context) {
    final provider = maybeOf(context);
    assert(provider != null, 'No StreamingUiProvider found in context. Make sure your view is mounted within the StreamingGenerativeUi system.');
    return provider!.registry;
  }

  @override
  bool updateShouldNotify(StreamingUiProvider oldWidget) =>
      registry != oldWidget.registry || 
      showInternalErrors != oldWidget.showInternalErrors ||
      errorBuilder != oldWidget.errorBuilder;
}

/// A reactive widget that dynamically resolves and displays a nested widget
/// using property streams and the context-provided [WidgetRegistry].
class StreamingWidget extends StatefulWidget {
  final PropertyStream props;

  const StreamingWidget({super.key, required this.props});

  @override
  State<StreamingWidget> createState() => _StreamingWidgetState();
}

class _StreamingWidgetState extends State<StreamingWidget> {
  late Future<String> _namespaceFuture;

  @override
  void initState() {
    super.initState();
    _initFuture();
  }

  @override
  void didUpdateWidget(covariant StreamingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      _initFuture();
    }
  }

  void _initFuture() {
    _namespaceFuture = widget.props.asMap.getStringProperty("namespace").future;
  }

  @override
  Widget build(BuildContext context) {
    final provider = StreamingUiProvider.maybeOf(context);
    final registry = provider?.registry;
    final showInternalErrors = provider?.showInternalErrors ?? true;
    final errorBuilder = provider?.errorBuilder;

    if (registry == null) {
      return const Text('No StreamingUiProvider found in context.');
    }

    return FutureBuilder<String>(
      future: _namespaceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return StreamingErrorWidget(
            error: 'Error loading namespace: ${snapshot.error}',
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

        try {
          return widgetDefinition.builder(context, widget.props);
        } catch (e, stack) {
          return StreamingErrorWidget(
            error: 'Rendering Error ($name): $e\n$stack',
            showInternalErrors: showInternalErrors,
            customBuilder: errorBuilder,
          );
        }
      },
    );
  }
}
