import 'view_state.dart';

class ViewController {
  final Map<String, ViewState> _states = {};

  ViewState getState(String viewId) {
    return _states.putIfAbsent(viewId, () => ViewState());
  }

  void disposeView(String viewId) {
    _states[viewId]?.dispose();
    _states.remove(viewId);
  }
}
