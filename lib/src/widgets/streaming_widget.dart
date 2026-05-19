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
class StreamingWidget extends StatelessWidget {
  final PropertyStream props;

  const StreamingWidget({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    final registry = StreamingUiProvider.of(context);

    return FutureBuilder<String>(
      future: props.asMap.getStringProperty("namespace").future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return Text('Error loading widget namespace: ${snapshot.error}');
        }

        final name = snapshot.data!;
        final widgetBuilder = registry.widgets[name];

        if (widgetBuilder == null) {
          return Text('Widget $name not found in registry');
        }

        return widgetBuilder(context, props);
      },
    );
  }
}
