import 'package:flutter/widgets.dart';
import 'registry/widget_registry.dart';
import 'registry/builtin_registry.dart';
import 'views/view_controller.dart';
import 'views/view_state.dart';
import 'widgets/gen_ui_view.dart';
import 'parser/stream_parser.dart';

class StreamingGenUi {
  final WidgetRegistry registry;
  final ViewController _viewController;

  StreamingGenUi({WidgetRegistry? registry}) 
      : registry = registry ?? BuiltinRegistry(),
        _viewController = ViewController();

  /// The prompt fragment to be injected into the LLM system prompt
  String get systemPrompt => 
      'You are an AI assistant that can dynamically render interactive user interfaces on the fly. '
      'When you want to output a visual UI block, enclose a valid JSON layout description inside '
      '<interface> and </interface> tags. All other text will be rendered as standard Markdown. '
      'ID format: `<provider>:<name_in_snake_case>` (e.g. `core:text`, `core:elevated_button`).';

  /// Pipes a stream of AI response to a specific view with optional real-time callbacks
  Future<void> stream(
    Stream<String> response, {
    String? viewId,
    void Function(String textChunk)? onText,
    void Function(String fullRaw)? onComplete,
  }) async {
    final defaultId = viewId ?? 'default';
    final defaultState = _viewController.getState(defaultId);
    defaultState.clear();

    final parser = StatefulStreamParser(
      defaultViewId: defaultId,
      onText: (chunk) {
        defaultState.appendText(chunk);
        onText?.call(chunk);
      },
      onInterfaceBlockStart: (targetViewId, jsonStream, startTag) {
        final targetState = _viewController.getState(targetViewId);
        targetState.clear();
        targetState.startInteractive(jsonStream);
      },
      onInterfaceBlockEnd: (targetViewId) {
        final targetState = _viewController.getState(targetViewId);
        targetState.endInteractive();
      },
      onComplete: (raw) {
        defaultState.updateRawContent(raw);
        onComplete?.call(raw);
      },
    );

    await for (final chunk in response) {
      parser.processChunk(chunk);
    }
    parser.close();
  }

  /// Gets the final raw response string of a view (to save to DB)
  String? getViewData(String viewId) {
    return _viewController.getState(viewId).rawContent;
  }

  /// Restores from saved raw response — internally just streams it as an instant single-value stream
  void restore({required String viewId, required String raw}) {
    stream(
      Stream.value(raw),
      viewId: viewId,
    );
  }

  /// Exposes the reactive view state for manual listener bindings
  ViewState getViewState(String viewId) {
    return _viewController.getState(viewId);
  }

  /// Cleanup when a view is permanently gone (e.g., chat cleared, logout)
  void disposeView(String viewId) {
    _viewController.disposeView(viewId);
  }

  /// Creates the view widget to be placed anywhere in the tree
  Widget view(String viewId, {Widget Function(BuildContext)? onUnknownWidget}) {
    return GenUiView(
      viewId: viewId,
      controller: _viewController,
      registry: registry,
      onUnknownWidget: onUnknownWidget,
    );
  }
}
