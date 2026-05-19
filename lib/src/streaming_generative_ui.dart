import 'package:flutter/widgets.dart';
import 'package:llm_tag_parser/llm_tag_parser.dart';
import 'package:streaming_gen_ui/src/models/view_state.dart';
import 'package:streaming_gen_ui/src/models/widget_registry.dart';

class StreamingGenerativeUi with ChangeNotifier {
  final WidgetRegistry registry;
  final Map<String, ViewState> _views = {};

  StreamingGenerativeUi({required this.registry});

  // Input
  Future<void> stream(
    Stream<String> stream, {
    String? viewId,
    void Function(String chunk)? onText,
    void Function(String raw)? onComplete,
  }) async {
    final broadcastStream = stream.asBroadcastStream();

    if (viewId != null) {
      final viewState = ViewState(stream: broadcastStream, widgetRegistry: registry);
      _views[viewId] = viewState;
      notifyListeners();
    }

    final fullRawBuffer = StringBuffer();

    final parser = LlmTagParser(
      stream: broadcastStream,
      tags: [LlmTag(open: "<interface>", close: "</interface>")],
    );

    final textSubscription = parser.outside("<interface>").stream.listen((chunk) {
      if (onText != null) {
        onText(chunk);
      }
    });

    final rawSubscription = broadcastStream.listen((chunk) {
      fullRawBuffer.write(chunk);
    });

    try {
      await broadcastStream.drain();
    } catch (_) {
      rethrow;
    } finally {
      await textSubscription.cancel();
      await rawSubscription.cancel();
    }

    if (onComplete != null) {
      onComplete(fullRawBuffer.toString());
    }
  }

  void restore({required String viewId, required String raw}) =>
      stream(Stream.value(raw), viewId: viewId);

  // Output
  Widget view(String viewId) =>
      _views[viewId]?.widget ?? const SizedBox.shrink();

  void disposeView(String viewId) => _views.remove(viewId);
}
