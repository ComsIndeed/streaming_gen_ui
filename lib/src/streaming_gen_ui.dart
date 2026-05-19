import 'package:flutter/widgets.dart';
import 'registry/widget_registry.dart';
import 'registry/builtin_registry.dart';
import 'views/view_state.dart';

class StreamingGenUi {
  final WidgetRegistry registry;

  StreamingGenUi({WidgetRegistry? registry}) 
      : registry = registry ?? BuiltinRegistry();

  /// The prompt fragment to be injected into the LLM system prompt
  String get systemPrompt => throw UnimplementedError();

  /// Pipes a stream of AI response to a specific view with optional real-time callbacks
  Future<void> stream(
    Stream<String> response, {
    String? viewId,
    void Function(String textChunk)? onText,
    void Function(String fullRaw)? onComplete,
  }) async {
    throw UnimplementedError();
  }

  /// Gets the final raw response string of a view (to save to DB)
  String? getViewData(String viewId) {
    throw UnimplementedError();
  }

  /// Restores from saved raw response — internally just streams it as an instant single-value stream
  void restore({required String viewId, required String raw}) {
    throw UnimplementedError();
  }

  /// Exposes the reactive view state for manual listener bindings
  ViewState getViewState(String viewId) {
    throw UnimplementedError();
  }

  /// Cleanup when a view is permanently gone (e.g., chat cleared, logout)
  void disposeView(String viewId) {
    throw UnimplementedError();
  }

  /// Creates the view widget to be placed anywhere in the tree
  Widget view(String viewId, {Widget Function(BuildContext)? onUnknownWidget}) {
    throw UnimplementedError();
  }
}
