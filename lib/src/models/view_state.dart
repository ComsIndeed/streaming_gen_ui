import 'package:flutter/widgets.dart';
import 'package:llm_tag_parser/llm_tag_parser.dart';
import 'package:streaming_gen_ui/src/models/block.dart';
import 'package:streaming_gen_ui/src/models/widget_registry.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_widget.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_error_widget.dart';

const bool _verboseLog = true;

void _debugLog(String msg) {
  if (_verboseLog) {
    debugPrint('[GEN_UI:VIEW_STATE] [${DateTime.now().toIso8601String().substring(11, 23)}] $msg');
  }
}

/// Holds the column of widgets that will be displayed in the UI
class ViewState with ChangeNotifier {
  final List<Block> _blocks = [];
  final WidgetRegistry widgetRegistry;
  final bool showInternalErrors;
  final GenerativeUiErrorBuilder? errorBuilder;

  ViewState({
    required Stream<String> stream,
    required this.widgetRegistry,
    this.showInternalErrors = true,
    this.errorBuilder,
  }) {
    _debugLog('ViewState initialized.');
    seperateStream(stream);
  }

  void seperateStream(Stream<String> stream) {
    _debugLog('seperateStream: setting up LlmTagParser...');
    final parser = LlmTagParser(
      stream: stream,
      tags: [LlmTag(open: "<interface>", close: "</interface>")],
    );
    
    parser
        .within("<interface>")
        .stream
        .listen(
          (chunk) {
            _debugLog('LlmTagParser: received within("<interface>"): "$chunk"');
            _addWidgetBlock(chunk);
          },
          onDone: () => _debugLog('LlmTagParser: within("<interface>") done.'),
          onError: (err) => _debugLog('LlmTagParser: within("<interface>") error: $err'),
        );
        
    parser
        .outside("<interface>")
        .stream
        .listen(
          (chunk) {
            _debugLog('LlmTagParser: received outside("<interface>"): "${chunk.replaceAll('\n', '\\n')}"');
            _addTextBlock(chunk);
          },
          onDone: () => _debugLog('LlmTagParser: outside("<interface>") done.'),
          onError: (err) => _debugLog('LlmTagParser: outside("<interface>") error: $err'),
        );
  }

  void _addTextBlock(String chunk) {
    if (_blocks.isEmpty || _blocks.last is! TextBlock) {
      if (_blocks.isNotEmpty) {
        _debugLog('_addTextBlock: closing previous block ${_blocks.last.runtimeType}');
        _blocks.last.close();
      }
      _debugLog('_addTextBlock: creating new TextBlock');
      _blocks.add(TextBlock(registry: widgetRegistry));
    }
    final block = _blocks.last as TextBlock;
    block.addChunk(chunk);

    _debugLog('_addTextBlock: notifying views. Total block count: ${_blocks.length}');
    notifyListeners();
  }

  void _addWidgetBlock(String chunk) {
    if (_blocks.isEmpty || _blocks.last is! WidgetBlock) {
      if (_blocks.isNotEmpty) {
        _debugLog('_addWidgetBlock: closing previous block ${_blocks.last.runtimeType}');
        _blocks.last.close();
      }
      _debugLog('_addWidgetBlock: creating new WidgetBlock');
      _blocks.add(WidgetBlock(
        registry: widgetRegistry,
        showInternalErrors: showInternalErrors,
        errorBuilder: errorBuilder,
      ));
    }
    final block = _blocks.last as WidgetBlock;
    block.addChunk(chunk);

    _debugLog('_addWidgetBlock: notifying views. Total block count: ${_blocks.length}');
    notifyListeners();
  }

  Widget? _cachedWidget;

  Widget get widget {
    _cachedWidget ??= StreamingUiProvider(
      registry: widgetRegistry,
      showInternalErrors: showInternalErrors,
      errorBuilder: errorBuilder,
      child: AnimatedBuilder(
        animation: this,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _blocks.map((block) {
              return KeyedSubtree(
                key: ObjectKey(block),
                child: block.build(context),
              );
            }).toList(),
          );
        },
      ),
    );
    return _cachedWidget!;
  }
}
