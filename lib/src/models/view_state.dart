import 'package:flutter/widgets.dart';
import 'package:llm_tag_parser/llm_tag_parser.dart';
import 'package:streaming_gen_ui/src/models/block.dart';
import 'package:streaming_gen_ui/src/models/widget_registry.dart';

/// Holds the column of widgets that will be displayed in the UI
class ViewState with ChangeNotifier {
  final List<Block> _blocks = [];
  final WidgetRegistry widgetRegistry;

  ViewState({required Stream<String> stream, required this.widgetRegistry}) {
    seperateStream(stream);
  }

  void seperateStream(Stream<String> stream) {
    final parser = LlmTagParser(
      stream: stream,
      tags: [LlmTag(open: "<interface>", close: "</interface>")],
    );
    parser
        .within("<interface>")
        .stream
        .listen((chunk) => _addWidgetBlock(chunk));
    parser
        .outside("<interface>")
        .stream
        .listen((chunk) => _addTextBlock(chunk));
  }

  void _addTextBlock(String chunk) {
    if (_blocks.isEmpty || _blocks.last is! TextBlock) {
      if (_blocks.isNotEmpty) {
        _blocks.last.close();
      }
      _blocks.add(TextBlock(registry: widgetRegistry));
    }
    final block = _blocks.last as TextBlock;
    block.addChunk(chunk);

    notifyListeners();
  }

  void _addWidgetBlock(String chunk) {
    if (_blocks.isEmpty || _blocks.last is! WidgetBlock) {
      if (_blocks.isNotEmpty) {
        _blocks.last.close();
      }
      _blocks.add(WidgetBlock(registry: widgetRegistry));
    }
    final block = _blocks.last as WidgetBlock;
    block.addChunk(chunk);

    notifyListeners();
  }

  Widget get widget {
    return AnimatedBuilder(
      animation: this,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _blocks.map((block) => block.build(context)).toList(),
        );
      },
    );
  }
}
