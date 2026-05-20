import 'package:flutter/widgets.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/models/widget_registry.dart';

/// Hosts the active [WidgetRegistry] in the widget tree.
class StreamingUiProvider extends InheritedWidget {
  final WidgetRegistry registry;

  const StreamingUiProvider({
    super.key,
    required this.registry,
    required super.child,
  });

  /// Tries to look up the [WidgetRegistry] from the closest ancestor [StreamingUiProvider].
  static WidgetRegistry? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StreamingUiProvider>()?.registry;
  }

  /// Looks up the [WidgetRegistry] from the closest ancestor [StreamingUiProvider].
  /// Throws an assertion error if not found.
  static WidgetRegistry of(BuildContext context) {
    final registry = maybeOf(context);
    assert(registry != null, 'No StreamingUiProvider found in context. Make sure your view is mounted within the StreamingGenerativeUi system.');
    return registry!;
  }

  @override
  bool updateShouldNotify(StreamingUiProvider oldWidget) =>
      registry != oldWidget.registry;
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
    if (widget.props != oldWidget.props) {
      _initFuture();
    }
  }

  void _initFuture() {
    _namespaceFuture = widget.props.asMap.getStringProperty("namespace").future;
  }

  @override
  Widget build(BuildContext context) {
    final registry = StreamingUiProvider.of(context);

    return FutureBuilder<String>(
      future: _namespaceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return Text('Error loading widget namespace: ${snapshot.error}');
        }

        final name = snapshot.data!;
        final widgetDefinition = registry.widgets[name];

        if (widgetDefinition == null) {
          return Text('Widget $name not found in registry');
        }

        return widgetDefinition.builder(context, widget.props);
      },
    );
  }
}
