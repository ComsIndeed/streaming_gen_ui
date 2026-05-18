import 'package:flutter/widgets.dart';
import 'dart:async';
import 'src/registry/widget_registry.dart';
import 'src/registry/builtin_registry.dart';
import 'src/views/view_controller.dart';
import 'src/views/view_state.dart';
import 'src/widgets/gen_ui_view.dart';
import 'src/parser/stream_parser.dart';

export 'src/views/view_state.dart' show ViewState, ViewBlock, TextBlock, InteractiveBlock;
export 'package:llm_json_stream/llm_json_stream.dart';

class StreamingGenUi {
  final WidgetRegistry registry;
  final ViewController _viewController;
  final Map<String, StreamSubscription<String>> _subscriptions = {};

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
    
    // Automatically cancel any active streaming subscription on this view to prevent race overlaps!
    await cancelStream(defaultId);

    final defaultState = _viewController.getState(defaultId);
    defaultState.clear();

    final parser = StatefulStreamParser(
      defaultViewId: defaultId,
      onText: (chunk) {
        defaultState.appendText(chunk);
        onText?.call(chunk);
      },
      onInterfaceBlockStart: (targetViewId, jsonStream, startTag) {
        if (targetViewId == defaultId) {
          defaultState.startInteractiveBlock(targetViewId, jsonStream);
        } else {
          final targetState = _viewController.getState(targetViewId);
          targetState.clear();
          targetState.startInteractiveBlock(targetViewId, jsonStream);
        }
      },
      onInterfaceBlockEnd: (targetViewId) {
        if (targetViewId == defaultId) {
          defaultState.endInteractiveBlock(targetViewId);
        } else {
          final targetState = _viewController.getState(targetViewId);
          targetState.endInteractiveBlock(targetViewId);
        }
      },
      onComplete: (raw) {
        defaultState.updateRawContent(raw);
        onComplete?.call(raw);
      },
    );

    final completer = Completer<void>();

    // Bind subscription manually so it can be cleanly cancelled midway
    final subscription = response.listen(
      (chunk) {
        parser.processChunk(chunk);
      },
      onDone: () {
        parser.close();
        _subscriptions.remove(defaultId);
        completer.complete();
      },
      onError: (err) {
        parser.close();
        _subscriptions.remove(defaultId);
        completer.completeError(err);
      },
      cancelOnError: true,
    );

    _subscriptions[defaultId] = subscription;

    await completer.future;
  }

  /// Cancels and flushes any active stream running on a specific view
  Future<void> cancelStream(String viewId) async {
    final sub = _subscriptions.remove(viewId);
    if (sub != null) {
      await sub.cancel();
    }
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
    cancelStream(viewId);
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
