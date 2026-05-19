import 'package:streaming_gen_ui/src/models/widget_registry.dart';

class StreamingGenerativeUi {
  final WidgetRegistry registry;

  StreamingGenerativeUi({required this.registry});

  // Input
  Future<void> stream(Stream<String> stream, {required String viewId}) async {}

  void restore(String content, {required String viewId}) =>
      stream(Stream.value(content), viewId: viewId);

  // Output
  void view(String viewId) {}

  void disposeView(String viewId) {}
}
