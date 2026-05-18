import 'package:flutter/widgets.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import '../views/view_controller.dart';
import '../registry/widget_registry.dart';

class GenUiView extends StatelessWidget {
  final String viewId;
  final ViewController controller;
  final WidgetRegistry registry;
  final Widget Function(BuildContext)? onUnknownWidget;

  const GenUiView({
    super.key,
    required this.viewId,
    required this.controller,
    required this.registry,
    this.onUnknownWidget,
  });

  @override
  Widget build(BuildContext context) {
    final state = controller.getState(viewId);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final children = <Widget>[];

        if (state.conversationalText.isNotEmpty) {
          children.add(
            Text(
              state.conversationalText,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          );
        }

        if (state.hasInteractive && state.rootMapStream != null) {
          if (children.isNotEmpty) {
            children.add(const SizedBox(height: 16));
          }
          children.add(
            StreamingWidget(
              mapStream: state.rootMapStream!,
              registry: registry,
              onUnknownWidget: onUnknownWidget,
            ),
          );
        }

        if (children.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          key: ValueKey('gen_ui_view_$viewId'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        );
      },
    );
  }
}

class StreamingWidget extends StatelessWidget {
  final MapPropertyStream mapStream;
  final WidgetRegistry registry;
  final Widget Function(BuildContext)? onUnknownWidget;

  const StreamingWidget({
    super.key,
    required this.mapStream,
    required this.registry,
    this.onUnknownWidget,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: mapStream.getStringProperty('namespace').future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 48,
            child: StreamingLoadingIndicator(),
          );
        }
        final namespace = snapshot.data!;
        
        final widget = registry.buildWidget(namespace, mapStream);
        if (widget != null) {
          return widget;
        }
        
        if (onUnknownWidget != null) {
          return onUnknownWidget!(context);
        }
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Text(
            'Unknown widget namespace: $namespace',
            style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        );
      },
    );
  }
}

class StreamingLoadingIndicator extends StatefulWidget {
  const StreamingLoadingIndicator({super.key});

  @override
  State<StreamingLoadingIndicator> createState() => _StreamingLoadingIndicatorState();
}

class _StreamingLoadingIndicatorState extends State<StreamingLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.3, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0x3306B6D4), // subtle cyan tint
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF06B6D4), width: 2),
          ),
        ),
      ),
    );
  }
}
