import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';

/// A button that progressively displays its nested children and dynamically
/// transitions to active/tappable once its click action resolves from the stream.
class StreamingElevatedButton extends StatefulWidget {
  final PropertyStream props;

  const StreamingElevatedButton({super.key, required this.props});

  @override
  State<StreamingElevatedButton> createState() => _StreamingElevatedButtonState();
}

class _StreamingElevatedButtonState extends State<StreamingElevatedButton> {
  late Future<String> _actionFuture;
  late PropertyStream _childProp;

  @override
  void initState() {
    super.initState();
    _initProps();
  }

  @override
  void didUpdateWidget(covariant StreamingElevatedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.props != oldWidget.props) {
      _initProps();
    }
  }

  void _initProps() {
    final mapStream = widget.props.asMap;
    _actionFuture = mapStream.getStringProperty("action").future;
    _childProp = mapStream.getMapProperty("child");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _actionFuture,
      builder: (context, snapshot) {
        final action = snapshot.data;
        final isEnabled = snapshot.connectionState == ConnectionState.done && action != null;
        
        return ElevatedButton(
          onPressed: isEnabled ? () {
            debugPrint('Interaction: Button action clicked -> $action');
          } : null,
          child: StreamingWidget(props: _childProp),
        );
      },
    );
  }
}
