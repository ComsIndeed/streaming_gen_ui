import 'dart:async';
import 'package:flutter/material.dart';
import 'package:example/widgets/custom_painters.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';

/// A premium widget that displays raw stream input in a classic blueprint paper style
/// on the left, an animated processing arrow in the center, and the beautifully rendered
/// dynamic view from the package engine on the right.
class GenerationPreview extends StatefulWidget {
  final Stream<String>? textStream;
  final String fullText;
  final String title;
  final bool isPaused;
  final bool isDarkMode;
  final StreamingGenUi genUi;
  final String viewId;

  const GenerationPreview({
    super.key,
    this.textStream,
    required this.fullText,
    required this.title,
    this.isPaused = false,
    this.isDarkMode = false,
    required this.genUi,
    required this.viewId,
  });

  @override
  State<GenerationPreview> createState() => _GenerationPreviewState();
}

class _GenerationPreviewState extends State<GenerationPreview> with SingleTickerProviderStateMixin {
  bool _autoScroll = true;
  final ScrollController _blueprintScrollController = ScrollController();
  final ScrollController _previewScrollController = ScrollController();

  // For arrow animations
  late final AnimationController _arrowAnimController;

  @override
  void initState() {
    super.initState();
    _arrowAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    widget.genUi.getViewState(widget.viewId).addListener(_onViewStateChanged);
    _updateArrowAnimation();
  }

  void _onViewStateChanged() {
    if (mounted) {
      setState(() {
        _scrollPreviewToBottom();
        _scrollToBottom();
        _updateArrowAnimation();
      });
    }
  }

  void _updateArrowAnimation() {
    final state = widget.genUi.getViewState(widget.viewId);
    final active = state.isProcessing && !widget.isPaused;
    if (active) {
      if (!_arrowAnimController.isAnimating) {
        _arrowAnimController.repeat();
      }
    } else {
      _arrowAnimController.stop();
    }
  }

  @override
  void didUpdateWidget(covariant GenerationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewId != oldWidget.viewId) {
      widget.genUi.getViewState(oldWidget.viewId).removeListener(_onViewStateChanged);
      widget.genUi.getViewState(widget.viewId).addListener(_onViewStateChanged);
    }
    _updateArrowAnimation();
  }

  void _scrollToBottom() {
    if (!_autoScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_blueprintScrollController.hasClients) {
        _blueprintScrollController.animateTo(
          _blueprintScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollPreviewToBottom() {
    if (!_autoScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_previewScrollController.hasClients) {
        _previewScrollController.animateTo(
          _previewScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    widget.genUi.getViewState(widget.viewId).removeListener(_onViewStateChanged);
    _arrowAnimController.dispose();
    _blueprintScrollController.dispose();
    _previewScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.genUi.getViewState(widget.viewId);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth > 800;

            final blueprintPanel = _buildBlueprintPanel(state);
            final arrowPanel = _buildArrowPanel(isWide, state);
            final whitePaperPanel = _buildWhitePaperPanel(state);

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 10, child: blueprintPanel),
                  SizedBox(width: 80, child: arrowPanel),
                  Expanded(flex: 11, child: whitePaperPanel),
                ],
              );
            } else {
              return Column(
                children: [
                  Expanded(flex: 5, child: blueprintPanel),
                  SizedBox(height: 60, child: arrowPanel),
                  Expanded(flex: 6, child: whitePaperPanel),
                ],
              );
            }
          },
        );
      },
    );
  }

  Widget _buildBlueprintPanel(ViewState state) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isDarkMode
              ? [
                  const Color(0xFF031525),
                  const Color(0xFF07243A),
                ]
              : [
                  const Color(0xFFF0F9FF),
                  const Color(0xFFE0F2FE),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode 
              ? const Color(0xFF0284C7).withValues(alpha: 0.6) 
              : const Color(0xFFBAE6FD), 
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isDarkMode 
                ? Colors.black.withValues(alpha: 0.2) 
                : Colors.blue.withValues(alpha: 0.03),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RAW LLM STREAM INPUT',
                  style: TextStyle(
                    color: widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _autoScroll = !_autoScroll;
                        });
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _autoScroll 
                              ? (widget.isDarkMode ? const Color(0xFF38BDF8).withValues(alpha: 0.15) : const Color(0xFF0369A1).withValues(alpha: 0.1)) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _autoScroll 
                                ? (widget.isDarkMode ? const Color(0xFF38BDF8).withValues(alpha: 0.4) : const Color(0xFF0369A1).withValues(alpha: 0.3)) 
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _autoScroll ? Icons.lock_outline : Icons.lock_open,
                              size: 12,
                              color: widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _autoScroll ? 'FOLLOW STREAM' : 'FREE SCROLL',
                              style: TextStyle(
                                color: widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                                fontFamily: 'monospace',
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: state.isProcessing
                            ? (widget.isDarkMode ? const Color(0xFF0284C7).withValues(alpha: 0.3) : const Color(0xFFBAE6FD).withValues(alpha: 0.6))
                            : (widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0).withValues(alpha: 0.6)),
                        border: Border.all(
                          color: state.isProcessing ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.isProcessing && !widget.isPaused) ...[
                            SizedBox(
                              width: 8,
                              height: 8,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            widget.isPaused ? 'PAUSED' : (state.isProcessing ? 'STREAMING' : 'IDLE'),
                            style: TextStyle(
                              color: state.isProcessing 
                                  ? (widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0369A1)) 
                                  : (widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              fontFamily: 'monospace',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Divider(
              color: widget.isDarkMode ? const Color(0xFF0284C7).withValues(alpha: 0.4) : const Color(0xFFBAE6FD), 
              height: 20,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _blueprintScrollController,
                physics: const BouncingScrollPhysics(),
                child: CustomPaint(
                  painter: BlueprintGridPainter(
                    gridColor: widget.isDarkMode 
                        ? const Color(0xFF38BDF8).withValues(alpha: 0.08) 
                        : const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                    majorColor: widget.isDarkMode 
                        ? const Color(0xFF38BDF8).withValues(alpha: 0.16) 
                        : const Color(0xFF0EA5E9).withValues(alpha: 0.24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12.5,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: widget.isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          ),
                          children: [
                            TextSpan(text: state.rawContent),
                            if (state.isProcessing)
                              TextSpan(
                                text: ' █',
                                style: TextStyle(
                                  color: widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrowPanel(bool isWide, ViewState state) {
    return Center(
      child: SizedBox(
        width: isWide ? 50 : 35,
        height: isWide ? 40 : 25,
        child: AnimatedBuilder(
          animation: _arrowAnimController,
          builder: (context, child) {
            return CustomPaint(
              painter: ArrowPainter(
                animationValue: _arrowAnimController.value,
                isActive: state.isProcessing,
                isWide: isWide,
                isDarkMode: widget.isDarkMode,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWhitePaperPanel(ViewState state) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0), 
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isDarkMode ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: CustomPaint(
                painter: PaperWatermarkPainter(
                  gridColor: widget.isDarkMode ? const Color(0xFF1E293B).withValues(alpha: 0.4) : const Color(0xFFF1F5F9),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.title.toUpperCase(),
                        style: TextStyle(
                          color: widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Icon(Icons.architecture, size: 16, color: widget.isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                    ],
                  ),
                  Divider(
                    color: widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), 
                    height: 16, 
                    thickness: 1.5,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _previewScrollController,
                      physics: const BouncingScrollPhysics(),
                      child: widget.genUi.view(widget.viewId),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
