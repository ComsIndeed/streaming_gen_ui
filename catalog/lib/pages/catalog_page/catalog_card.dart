import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:streaming_gen_ui_widget_catalog/core/models/widget_catalog_item.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
import 'package:streaming_gen_ui_widget_catalog/core/utilities/stream_text_in_chunks.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/preview_page/preview_page.dart';

import 'package:streaming_gen_ui_widget_catalog/core/app_widgets/elastic_wrapper.dart';

class CatalogCard extends StatefulWidget {
  final WidgetCatalogItem catalogItem;
  static final ValueNotifier<int> resetSignal = ValueNotifier<int>(0);

  const CatalogCard({super.key, required this.catalogItem});

  @override
  State<CatalogCard> createState() => _CatalogCardState();
}

class _CatalogCardState extends State<CatalogCard> {
  late final StreamingGenerativeUi _streamingGenUi;
  bool _disposed = false;
  bool _isHovered = false;
  Timer? _loopTimer;
  int _currentCycle = 0;
  StreamController<String>? _activeStreamController;
  StreamSubscription<String>? _activeStreamSubscription;

  @override
  void initState() {
    super.initState();
    _streamingGenUi = StreamingGenerativeUi(registries: [Registries.all]);
    CatalogCard.resetSignal.addListener(_onResetSignal);
    currentStreamingMode.addListener(_onResetSignal);
    _startStreamLoop();
  }

  void _onResetSignal() {
    _startStreamLoop();
  }

  void _startStreamLoop() {
    _loopTimer?.cancel();
    _activeStreamSubscription?.cancel();
    _activeStreamSubscription = null;
    _activeStreamController?.close();
    _activeStreamController = null;

    _currentCycle++;
    _streamingGenUi.disposeView('main-view');
    _runSingleStreamCycle(_currentCycle);
  }

  Future<void> _runSingleStreamCycle(int cycleId) async {
    if (_disposed || cycleId != _currentCycle) return;

    final controller = StreamController<String>();
    _activeStreamController = controller;

    final rawStream = streamTextInChunks(
      text:
          "<interface>${widget.catalogItem.widgetDefinition.jsonExample}</interface>",
      chunkSize: 4,
      interval: const Duration(milliseconds: 100),
      chunkSizeImmediatelyEmit: '<interface>{"namespace":"  core:'.length,
    );

    final Stream<String> processedStream;
    switch (currentStreamingMode.value) {
      case StreamingMode.streaming:
        processedStream = rawStream;
        break;
      case StreamingMode.noWidgetStreaming:
        processedStream = transformNoWidgetStreaming(rawStream);
        break;
      case StreamingMode.noStreaming:
        processedStream = transformNoStreaming(rawStream);
        break;
    }

    _activeStreamSubscription = processedStream.listen(
      (chunk) {
        if (!controller.isClosed) {
          controller.add(chunk);
        }
      },
      onError: (err) {
        if (!controller.isClosed) {
          controller.close();
        }
      },
      onDone: () {
        if (!controller.isClosed) {
          controller.close();
        }
      },
      cancelOnError: true,
    );

    await _streamingGenUi.stream(controller.stream, viewId: 'main-view');

    if (_disposed || cycleId != _currentCycle) return;

    _loopTimer = Timer(const Duration(milliseconds: 3000), () {
      _runSingleStreamCycle(cycleId);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _loopTimer?.cancel();
    _activeStreamSubscription?.cancel();
    _activeStreamController?.close();
    CatalogCard.resetSignal.removeListener(_onResetSignal);
    currentStreamingMode.removeListener(_onResetSignal);
    super.dispose();
  }

  String _getBackgroundImage(String namespace) {
    final theme = namespace.split(':')[0].replaceAll('_ui', '');
    switch (theme) {
      case 'apple':
        return 'https://images.unsplash.com/photo-1634017839464-5c339ebe3cb4?q=80&w=400&auto=format&fit=crop';
      case 'fluent':
        return 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=400&auto=format&fit=crop';
      case 'material':
        return 'https://images.unsplash.com/photo-1620641788421-7a1c342ea42e?q=80&w=400&auto=format&fit=crop';
      case 'glassmorphic':
        return 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?q=80&w=400&auto=format&fit=crop';
      case 'neumorphic':
        return 'https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=400&auto=format&fit=crop';
      case 'skeumorphic':
        return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=400&auto=format&fit=crop';
      case 'brutalist':
        return 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=400&auto=format&fit=crop';
      default:
        // Default core / core_extended abstract pattern
        return 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=400&auto=format&fit=crop';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return ElasticWrapper(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PreviewPage(catalogItem: widget.catalogItem),
        ),
      ),
      hoveredScale: 1.03,
      pressedScale: 0.97,
      child: Hero(
        tag: "catalog-card-${widget.catalogItem.namespace}",
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                // Subtle image background on hover
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _isHovered ? 0.15 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Image.network(
                      _getBackgroundImage(widget.catalogItem.namespace),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
                SizedBox.expand(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(8, 8, 8, isMobile ? 24 : 36),
                    child: FittedBox(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: ListenableBuilder(
                          listenable: _streamingGenUi,
                          builder: (context, _) =>
                              _streamingGenUi.view('main-view'),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox.expand(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        transform: const GradientRotation(pi * 1.5),
                        stops: const [0.0, 0.3],
                        colors: [
                          Colors.black.withAlpha(30),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentGeometry.bottomStart,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 16,
                      vertical: isMobile ? 4 : 8,
                    ),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        Text(
                          widget.catalogItem.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 11 : 15,
                            color: theme.colorScheme.onSurface.withAlpha(235),
                          ),
                        ),
                        Text(
                          "(${widget.catalogItem.displayProvider})",
                          style: TextStyle(
                            fontSize: isMobile ? 9 : 13,
                            color: theme.colorScheme.onSurface.withAlpha(190),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
