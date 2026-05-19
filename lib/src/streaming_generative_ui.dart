import 'package:flutter/widgets.dart';
import 'package:streaming_gen_ui/src/models/view_state.dart';
import 'package:streaming_gen_ui/src/models/widget_registry.dart';

class StreamingGenerativeUi with ChangeNotifier {
  final WidgetRegistry registry;
  final Map<String, ViewState> _views = {};

  StreamingGenerativeUi({required this.registry});

  // Input
  Future<void> stream(Stream<String> stream, {required String viewId}) async {
    final viewState = ViewState(stream: stream, widgetRegistry: registry);
    _views[viewId] = viewState;
    notifyListeners();

    await stream.last;
  }

  void restore(String content, {required String viewId}) =>
      stream(Stream.value(content), viewId: viewId);

  // Output
  Widget view(String viewId) =>
      _views[viewId]?.widget ?? const SizedBox.shrink();

  void disposeView(String viewId) => _views.remove(viewId);
}
