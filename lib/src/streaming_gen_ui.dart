import 'package:flutter/widgets.dart';
import 'registry/widget_registry.dart';
import 'registry/builtin_registry.dart';
import 'views/view_controller.dart';
import 'widgets/gen_ui_view.dart';

class StreamingGenUi {
  final WidgetRegistry registry;
  final ViewController _viewController;

  StreamingGenUi({WidgetRegistry? registry}) 
      : registry = registry ?? BuiltinRegistry(),
        _viewController = ViewController();

  /// The prompt fragment to be injected into the LLM system prompt
  String get systemPrompt => 'You are an AI that returns UI in a specific JSON format...'; // TODO: elaborate

  /// Pipes a stream of AI response to a specific view
  Future<void> stream(Stream<String> response, {required String viewId}) async {
    // TODO: implement
  }

  /// Gets the final parsed data after completion (e.g., to save to DB)
  Map<String, dynamic>? getViewData(String viewId) {
    // TODO: implement
    return null;
  }

  /// Restores from saved data — internally just streams it as an instant single-value stream
  void restore({required String viewId, required Map<String, dynamic> data}) {
    // TODO: implement
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
