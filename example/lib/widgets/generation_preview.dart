import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:example/models/parsed_result.dart';
import 'package:example/utils/json_parser.dart';
import 'package:example/widgets/custom_painters.dart';
import 'package:example/widgets/skeleton_loader.dart';
import 'package:example/widgets/dynamic_widget_renderer.dart';

/// A premium widget that displays raw stream input in a classic blueprint paper style
/// on the left, an animated processing arrow in the center, and a beautiful rendered
/// paper layout on the right.
class GenerationPreview extends StatefulWidget {
  final Stream<String>? textStream;
  final String fullText;
  final String title;
  final bool isPaused;
  final bool isTokenSaverEnabled;
  final ValueChanged<bool>? onTokenSaverToggled;

  const GenerationPreview({
    super.key,
    this.textStream,
    required this.fullText,
    required this.title,
    this.isPaused = false,
    this.isTokenSaverEnabled = false,
    this.onTokenSaverToggled,
  });

  @override
  State<GenerationPreview> createState() => _GenerationPreviewState();
}

class _GenerationPreviewState extends State<GenerationPreview> with SingleTickerProviderStateMixin {
  String _accumulatedText = '';
  bool _isProcessing = false;
  StreamSubscription<String>? _subscription;
  bool _autoScroll = true;
  final ScrollController _blueprintScrollController = ScrollController();

  // For arrow animations
  late final AnimationController _arrowAnimController;

  @override
  void initState() {
    super.initState();
    _arrowAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.textStream != null) {
      _startListening();
    }
  }

  @override
  void didUpdateWidget(covariant GenerationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.textStream != oldWidget.textStream) {
      _stopListening();
      _accumulatedText = '';
      if (widget.textStream != null) {
        _startListening();
      }
    }
    
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _arrowAnimController.stop();
      } else if (_isProcessing) {
        _arrowAnimController.repeat();
      }
    }
  }

  void _startListening() {
    setState(() {
      _isProcessing = true;
      _accumulatedText = '';
    });
    _arrowAnimController.repeat();

    _subscription = widget.textStream!.listen(
      (chunk) {
        setState(() {
          _accumulatedText += chunk;
        });
        // Auto scroll raw stream panel to bottom
        _scrollToBottom();
      },
      onDone: () {
        setState(() {
          _isProcessing = false;
        });
        _arrowAnimController.stop();
      },
      onError: (err) {
        setState(() {
          _isProcessing = false;
        });
        _arrowAnimController.stop();
      },
      cancelOnError: true,
    );
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _scrollToBottom() {
    if (!_autoScroll) return;
    if (_blueprintScrollController.hasClients) {
      // Calculate the exact height of the streamed text so far
      final textPainter = TextPainter(
        text: TextSpan(
          text: _accumulatedText,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12.5,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      // Account for the horizontal padding of 8.0 on each side (16.0 total)
      final double maxWidth = _blueprintScrollController.position.viewportDimension - 16.0;
      textPainter.layout(maxWidth: maxWidth > 0 ? maxWidth : double.infinity);
      final double currentTextHeight = textPainter.size.height;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_blueprintScrollController.hasClients) {
          final double viewportHeight = _blueprintScrollController.position.viewportDimension;
          
          // Center the active typing cursor in the viewport
          double targetScroll = currentTextHeight - (viewportHeight / 2);

          if (targetScroll < 0) {
            targetScroll = 0;
          } else if (targetScroll > _blueprintScrollController.position.maxScrollExtent) {
            targetScroll = _blueprintScrollController.position.maxScrollExtent;
          }

          _blueprintScrollController.animateTo(
            targetScroll,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _stopListening();
    _arrowAnimController.dispose();
    _blueprintScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Parse accumulated text using external parser
    final parsedResult = parseText(_accumulatedText);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Vertical or Horizontal depending on screen width
        final bool isWide = constraints.maxWidth > 800;

        final blueprintPanel = _buildBlueprintPanel(parsedResult);
        final arrowPanel = _buildArrowPanel(isWide);
        final whitePaperPanel = _buildWhitePaperPanel(parsedResult);

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
  }

  // --- WIDGET BUILDERS ---

  Widget _buildBlueprintPanel(ParsedResult parsed) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0F9FF), // Very soft cyan light blue
            Color(0xFFE0F2FE),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.03),
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
            // Blueprint Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RAW LLM STREAM INPUT',
                  style: TextStyle(
                    color: Color(0xFF0369A1), // Elegant ocean blue title
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onTokenSaverToggled != null) ...[
                      InkWell(
                        onTap: () {
                          widget.onTokenSaverToggled!(!widget.isTokenSaverEnabled);
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.isTokenSaverEnabled ? const Color(0xFF059669).withValues(alpha: 0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: widget.isTokenSaverEnabled ? const Color(0xFF059669).withValues(alpha: 0.3) : const Color(0xFF94A3B8).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.compress,
                                size: 12,
                                color: widget.isTokenSaverEnabled ? const Color(0xFF059669) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'TOKEN SAVER',
                                style: TextStyle(
                                  color: widget.isTokenSaverEnabled ? const Color(0xFF059669) : const Color(0xFF64748B),
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
                    ],
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
                          color: _autoScroll ? const Color(0xFF0369A1).withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _autoScroll ? const Color(0xFF0369A1).withValues(alpha: 0.3) : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _autoScroll ? Icons.lock_outline : Icons.lock_open,
                              size: 12,
                              color: const Color(0xFF0369A1),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _autoScroll ? 'FOLLOW STREAM' : 'FREE SCROLL',
                              style: const TextStyle(
                                color: Color(0xFF0369A1),
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
                        color: _isProcessing
                            ? const Color(0xFFBAE6FD).withValues(alpha: 0.6)
                            : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                        border: Border.all(
                          color: _isProcessing ? const Color(0xFF38BDF8) : const Color(0xFFCBD5E1),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isProcessing && !widget.isPaused) ...[
                            const SizedBox(
                              width: 8,
                              height: 8,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (widget.isPaused) ...[
                            const Icon(Icons.pause, size: 10, color: Color(0xFF0369A1)),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            widget.isPaused ? 'PAUSED' : (_isProcessing ? 'STREAMING' : 'IDLE'),
                            style: TextStyle(
                              color: _isProcessing ? const Color(0xFF0369A1) : const Color(0xFF64748B),
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
            const Divider(color: Color(0xFFBAE6FD), height: 20),

            // Stream text scroll view
            Expanded(
              child: SingleChildScrollView(
                controller: _blueprintScrollController,
                physics: const BouncingScrollPhysics(),
                child: CustomPaint(
                  // Blueprint grid background drawing directly in scrollable viewport to scroll with content!
                  painter: BlueprintGridPainter(
                    gridColor: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                    majorColor: const Color(0xFF0EA5E9).withValues(alpha: 0.24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                    child: Stack(
                      children: [
                        // 1. Ghost of the JSON being generated in very low opacity behind the typewriter text
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              height: 1.5,
                            ),
                            children: _buildBlueprintTextSpans(widget.fullText, isGhost: true),
                          ),
                        ),

                        // 2. Active typing text overlayed exactly on top (Dark Slate Theme)
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              height: 1.5,
                              color: Color(0xFF0F172A), // Soft dark slate text
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              ..._buildBlueprintTextSpans(_accumulatedText, isGhost: false),
                              if (_isProcessing)
                                const TextSpan(
                                  text: ' █',
                                  style: TextStyle(
                                    color: Color(0xFF0284C7),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
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

  List<InlineSpan> _buildBlueprintTextSpans(String rawText, {required bool isGhost}) {
    final parsed = parseText(rawText);
    
    final Color tagColor = isGhost ? const Color(0xFF0EA5E9).withValues(alpha: 0.25) : const Color(0xFF0284C7);
    final Color jsonColor = isGhost ? const Color(0xFF0EA5E9).withValues(alpha: 0.18) : const Color(0xFF0F172A);
    final Color normalTextColor = isGhost ? const Color(0xFF0EA5E9).withValues(alpha: 0.14) : const Color(0xFF334155);

    return [
      TextSpan(
        text: parsed.preText,
        style: TextStyle(color: normalTextColor),
      ),
      if (parsed.hasInteractive) ...[
        TextSpan(
          text: '\n<interactive>\n',
          style: TextStyle(
            color: tagColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: parsed.jsonText,
          style: TextStyle(
            color: jsonColor,
            fontWeight: isGhost ? FontWeight.normal : FontWeight.w500,
          ),
        ),
        if (parsed.isInteractiveClosed)
          TextSpan(
            text: '\n</interactive>',
            style: TextStyle(
              color: tagColor,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
      TextSpan(
        text: parsed.postText,
        style: TextStyle(color: normalTextColor),
      ),
    ];
  }

  Widget _buildArrowPanel(bool isWide) {
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
                isActive: _isProcessing,
                isWide: isWide,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWhitePaperPanel(ParsedResult parsed) {
    // Dynamic Widget Render Engine on the Right Panel (White Paper)
    final bool hasJson = parsed.hasInteractive && parsed.jsonText.trim().isNotEmpty;
    Map<String, dynamic>? decodedJson;
    String? parseError;

    if (hasJson) {
      try {
        final String cleanedJson = cleanJsonString(parsed.jsonText);
        decodedJson = jsonDecode(cleanedJson) as Map<String, dynamic>;
      } catch (e) {
        parseError = e.toString();
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Crisp drafting paper sheet
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Paper subtle grid watermark
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: CustomPaint(
                painter: PaperWatermarkPainter(),
              ),
            ),
          ),

          // Main compiled body
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Page Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.title.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Icon(Icons.architecture, size: 16, color: Color(0xFF94A3B8)),
                    ],
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 16, thickness: 1.5),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildRenderOutput(hasJson, decodedJson, parseError),
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

  // --- RENDERING STRATEGIES ---

  Widget _buildRenderOutput(bool hasJson, Map<String, dynamic>? decodedJson, String? parseError) {
    if (!hasJson) {
      // 1. Initial State: Draw animated loading lines
      return SkeletonLoader(isActive: _isProcessing);
    }

    if (parseError != null) {
      // 2. Mid-stream or faulty JSON: Draw partial skeletons next to dynamic error feedback
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonLoader(isActive: _isProcessing),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.sync, size: 14, color: Color(0xFFE11D48)),
                    SizedBox(width: 6),
                    Text(
                      'COMPILING STREAM SCHEMA...',
                      style: TextStyle(
                        fontSize: 9,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBE123C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Waiting for closed </interactive> tag to finalize widgets. Current compiler status:\n$parseError',
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontFamily: 'monospace',
                    color: Color(0xFF9F1239),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (decodedJson != null) {
      // 3. Complete and successfully decoded: Render the dynamic widgets!
      return DynamicWidgetRenderer(json: decodedJson);
    }

    return const SizedBox();
  }
}
