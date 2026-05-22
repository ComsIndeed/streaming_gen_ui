import 'package:flutter/widgets.dart';
import 'package:llm_tag_parser/llm_tag_parser.dart';
import 'package:streaming_gen_ui/src/models/view_state.dart';
import 'package:streaming_gen_ui/src/models/widget_registry.dart';
import 'package:streaming_gen_ui/src/models/generative_ui_config.dart';
import 'package:streaming_gen_ui/src/widgets/streaming_error_widget.dart';

class StreamingGenerativeUi with ChangeNotifier {
  final WidgetRegistry registry;
  final Map<String, ViewState> _views = {};
  final bool showInternalErrors;
  final GenerativeUiErrorBuilder? errorBuilder;
  final GenerativeUiConfig config;

  /// Extra custom instructions to append to the system prompt.
  /// These instructions will be dynamically numbered and formatted under an
  /// "Additional Instructions" section in the system prompt.
  /// 
  /// Example:
  /// ```dart
  /// final genUi = StreamingGenerativeUi(
  ///   registry: myRegistry,
  ///   extraInstructions: [
  ///     'Always keep your responses friendly and professional.',
  ///     'If the user is asking about pricing, render the pricing widget first.',
  ///   ],
  /// );
  /// ```
  final List<String> extraInstructions;

  /// An optional map of custom target view IDs to their descriptions.
  /// When provided, these are injected into the agent's system prompt instructions
  /// to explain the purpose of each view zone and how to target them using the
  /// `<interface viewId="...">` tag attribute.
  /// 
  /// Example:
  /// ```dart
  /// final genUi = StreamingGenerativeUi(
  ///   registry: myRegistry,
  ///   customViewIds: {
  ///     'side-panel': 'Renders supplementary details or secondary controls on the side panel.',
  ///     'global-modal': 'Renders modal-based overlays for actions requiring immediate attention.',
  ///   },
  /// );
  /// ```
  final Map<String, String>? customViewIds;

  StreamingGenerativeUi({
    required this.registry,
    this.showInternalErrors = false,
    this.errorBuilder,
    this.config = const GenerativeUiConfig(),
    this.extraInstructions = const [],
    this.customViewIds,
  });

  /// Returns the programmatically compiled system prompt describing all registered widgets,
  /// routing rules, target view IDs, and additional custom instructions.
  String get systemPrompt {
    final buffer = StringBuffer();
    
    // Base system prompt fragment from the registry.
    buffer.writeln(registry.systemPromptFragment);
    buffer.writeln();

    // Custom view IDs target zones instructions if provided.
    if (customViewIds != null && customViewIds!.isNotEmpty) {
      buffer.writeln('### 4. Target View Zones');
      buffer.writeln('When rendering an interactive component, you can target specific view zones in the application by specifying the `viewId` attribute on the `<interface>` tag:');
      buffer.writeln('`<interface viewId="view_id_here">... </interface>`');
      buffer.writeln();
      buffer.writeln('You can target the following view IDs depending on the context:');
      customViewIds!.forEach((id, desc) {
        buffer.writeln('* `$id`: $desc');
      });
      buffer.writeln();
    }

    // Additional extra instructions.
    if (extraInstructions.isNotEmpty) {
      final startIndex = (customViewIds != null && customViewIds!.isNotEmpty) ? 5 : 4;
      buffer.writeln('### $startIndex. Additional Instructions');
      for (var i = 0; i < extraInstructions.length; i++) {
        buffer.writeln('${i + 1}. ${extraInstructions[i]}');
      }
      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  ViewState _getOrCreateViewState(String viewId) {
    if (!_views.containsKey(viewId)) {
      _views[viewId] = ViewState(
        widgetRegistry: registry,
        showInternalErrors: showInternalErrors,
        errorBuilder: errorBuilder,
        config: config,
      );
      notifyListeners();
    }
    return _views[viewId]!;
  }

  // Input
  Future<void> stream(
    Stream<String> stream, {
    String? viewId,
    void Function(String chunk)? onText,
    void Function(String raw)? onComplete,
  }) async {
    final broadcastStream = stream.asBroadcastStream();

    final defaultViewId = viewId;
    if (defaultViewId != null) {
      _getOrCreateViewState(defaultViewId);
    }

    String activeViewId = defaultViewId ?? '';
    final fullRawBuffer = StringBuffer();

    // Use <interface{attrs}> tag configuration to extract attributes like viewId.
    final parser = LlmTagParser(
      stream: broadcastStream,
      tags: [
        LlmTag(
          open: '<interface{attrs}>',
          close: '</interface>',
          attributePlaceholder: '{attrs}',
        ),
      ],
    );

    // Track active target view ID for the next/current widget block.
    final attrSubscription = parser
        .within('<interface{attrs}>')
        .attribute('viewId')
        .listen((targetId) {
      activeViewId = targetId ?? defaultViewId ?? '';
      if (activeViewId.isNotEmpty) {
        _getOrCreateViewState(activeViewId);
      }
    });

    // Route widget payload chunks to the active target view.
    final widgetSubscription = parser
        .within('<interface{attrs}>')
        .stream
        .listen((chunk) {
      if (activeViewId.isNotEmpty) {
        final viewState = _getOrCreateViewState(activeViewId);
        viewState.addWidgetChunk(chunk);
      }
    });

    // Route conversational text chunks to the default view state and trigger callbacks.
    final textSubscription = parser
        .outside('<interface{attrs}>')
        .stream
        .listen((chunk) {
      if (defaultViewId != null) {
        final viewState = _getOrCreateViewState(defaultViewId);
        viewState.addTextChunk(chunk);
      }
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
      await attrSubscription.cancel();
      await widgetSubscription.cancel();
      await textSubscription.cancel();
      await rawSubscription.cancel();
    }

    // Finalize and close all blocks across views.
    for (final viewState in _views.values) {
      viewState.closeActiveBlock();
    }

    if (onComplete != null) {
      onComplete(fullRawBuffer.toString());
    }
  }

  void restore({required String viewId, required String raw}) =>
      stream(Stream.value(raw), viewId: viewId);

  // Output
  Widget view(
    String viewId, {
    Widget Function(BuildContext context, String text)? textBlockBuilder,
  }) {
    return _StreamingGenerativeUiView(
      controller: this,
      viewId: viewId,
      textBlockBuilder: textBlockBuilder,
    );
  }

  void disposeView(String viewId) {
    _views.remove(viewId);
    notifyListeners();
  }
}

class _StreamingGenerativeUiView extends StatelessWidget {
  final StreamingGenerativeUi controller;
  final String viewId;
  final Widget Function(BuildContext context, String text)? textBlockBuilder;

  const _StreamingGenerativeUiView({
    required this.controller,
    required this.viewId,
    this.textBlockBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final viewState = controller._views[viewId];
        if (viewState == null) {
          return const SizedBox.shrink();
        }
        return viewState.buildWidget(textBlockBuilder: textBlockBuilder);
      },
    );
  }
}
