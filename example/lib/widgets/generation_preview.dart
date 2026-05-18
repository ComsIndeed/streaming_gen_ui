import 'dart:async';
import 'package:flutter/material.dart';
import 'package:example/models/parsed_result.dart';
import 'package:example/utils/json_parser.dart';
import 'package:example/widgets/custom_painters.dart';
import 'package:example/widgets/skeleton_loader.dart';
import 'package:example/widgets/dynamic_widget_renderer.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';

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
  final bool isDarkMode;
  final StreamingGenUi genUi;
  final String viewId;

  const GenerationPreview({
    super.key,
    this.textStream,
    required this.fullText,
    required this.title,
    this.isPaused = false,
    this.isTokenSaverEnabled = false,
    this.onTokenSaverToggled,
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
  int _activeRightTabIndex = 0;

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
    
    // Check initial state
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
    final state = widget.genUi.getViewState(widget.viewId);
    if (_blueprintScrollController.hasClients) {
      // Calculate the exact height of the streamed text so far
      final textPainter = TextPainter(
        text: TextSpan(
          text: state.rawContent,
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
        // Parse accumulated text using external parser
        final parsedResult = parseText(state.rawContent);

        return LayoutBuilder(
          builder: (context, constraints) {
            // Vertical or Horizontal depending on screen width
            final bool isWide = constraints.maxWidth > 800;

            final blueprintPanel = _buildBlueprintPanel(parsedResult, state);
            final arrowPanel = _buildArrowPanel(isWide, state);
            final whitePaperPanel = _buildWhitePaperPanel(parsedResult, state);

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

  // --- WIDGET BUILDERS ---

  Widget _buildBlueprintPanel(ParsedResult parsed, ViewState state) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isDarkMode
              ? [
                  const Color(0xFF031525), // Very rich dark cyan
                  const Color(0xFF07243A),
                ]
              : [
                  const Color(0xFFF0F9FF), // Very soft cyan light blue
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
            // Blueprint Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RAW LLM STREAM INPUT',
                  style: TextStyle(
                    color: widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0369A1), // Elegant ocean blue title
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
                            color: widget.isTokenSaverEnabled 
                                ? (widget.isDarkMode ? const Color(0xFF34D399).withValues(alpha: 0.15) : const Color(0xFF059669).withValues(alpha: 0.1)) 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: widget.isTokenSaverEnabled 
                                  ? (widget.isDarkMode ? const Color(0xFF34D399).withValues(alpha: 0.4) : const Color(0xFF059669).withValues(alpha: 0.3)) 
                                  : (widget.isDarkMode ? const Color(0xFF475569).withValues(alpha: 0.4) : const Color(0xFF94A3B8).withValues(alpha: 0.3)),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.compress,
                                size: 12,
                                color: widget.isTokenSaverEnabled 
                                    ? (widget.isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669)) 
                                    : (widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'TOKEN SAVER',
                                style: TextStyle(
                                  color: widget.isTokenSaverEnabled 
                                      ? (widget.isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669)) 
                                      : (widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
                          color: state.isProcessing 
                              ? (widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF38BDF8)) 
                              : (widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
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
                          if (widget.isPaused) ...[
                            Icon(Icons.pause, size: 10, color: widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0369A1)),
                            const SizedBox(width: 4),
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
              color: widget.isDarkMode 
                  ? const Color(0xFF0284C7).withValues(alpha: 0.4) 
                  : const Color(0xFFBAE6FD), 
              height: 20,
            ),

            // Stream text scroll view
            Expanded(
              child: SingleChildScrollView(
                controller: _blueprintScrollController,
                physics: const BouncingScrollPhysics(),
                child: CustomPaint(
                  // Blueprint grid background drawing directly in scrollable viewport to scroll with content!
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
                    child: Stack(
                      children: [
                        // 1. Ghost of the JSON being generated in very low opacity behind the typewriter text
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                            children: _buildBlueprintTextSpans(widget.fullText, isGhost: true),
                          ),
                        ),

                        // 2. Active typing text overlayed exactly on top (Dark Slate Theme / Bright Theme)
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              ..._buildBlueprintTextSpans(state.rawContent, isGhost: false),
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
    
    // Shared typography base to secure pixel-perfect alignment
    final TextStyle baseStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12.5,
      height: 1.5,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.0,
      color: isGhost 
          ? (widget.isDarkMode ? const Color(0xFF38BDF8).withValues(alpha: 0.15) : const Color(0xFF0EA5E9).withValues(alpha: 0.12)) 
          : (widget.isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
    );

    final Color tagColor = isGhost 
        ? (widget.isDarkMode ? const Color(0xFF38BDF8).withValues(alpha: 0.25) : const Color(0xFF0EA5E9).withValues(alpha: 0.2)) 
        : (widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0284C7));

    final List<InlineSpan> spans = [];

    // 1. Pre text (Markdown parsed)
    spans.addAll(_parseMarkdownToSpans(parsed.preText, baseStyle, isGhost));

    // 2. Interactive block (JSON Syntax Highlighted + verbatim tags)
    if (parsed.hasInteractive) {
      spans.add(TextSpan(
        text: '\n${parsed.startTag}\n',
        style: baseStyle.copyWith(
          color: tagColor,
          fontWeight: FontWeight.bold,
        ),
      ));

      spans.addAll(_parseJsonToSpans(parsed.jsonText, baseStyle, isGhost));

      if (parsed.isInteractiveClosed) {
        spans.add(TextSpan(
          text: '\n${parsed.endTag}',
          style: baseStyle.copyWith(
            color: tagColor,
            fontWeight: FontWeight.bold,
          ),
        ));
      }
    }

    // 3. Post text (Markdown parsed)
    spans.addAll(_parseMarkdownToSpans(parsed.postText, baseStyle, isGhost));

    return spans;
  }

  List<InlineSpan> _parseJsonToSpans(String jsonStr, TextStyle baseStyle, bool isGhost) {
    // Premium HSL-derived syntax colors for JSON tokens
    // Ghost colors will be the same hues, but with very low opacity (0.2 to 0.3) so they stay readable yet dim.
    final Color keyColor = isGhost 
        ? (widget.isDarkMode ? const Color(0xFFF472B6).withValues(alpha: 0.25) : const Color(0xFFDB2777).withValues(alpha: 0.25)) // Pink
        : (widget.isDarkMode ? const Color(0xFFF472B6) : const Color(0xFFDB2777));
    
    final Color stringColor = isGhost 
        ? (widget.isDarkMode ? const Color(0xFF34D399).withValues(alpha: 0.25) : const Color(0xFF059669).withValues(alpha: 0.25)) // Green
        : (widget.isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669));

    final Color numberColor = isGhost 
        ? (widget.isDarkMode ? const Color(0xFFFBBF24).withValues(alpha: 0.25) : const Color(0xFFD97706).withValues(alpha: 0.25)) // Amber
        : (widget.isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFFD97706));

    final Color keywordColor = isGhost 
        ? (widget.isDarkMode ? const Color(0xFFC084FC).withValues(alpha: 0.25) : const Color(0xFF7C3AED).withValues(alpha: 0.25)) // Purple
        : (widget.isDarkMode ? const Color(0xFFC084FC) : const Color(0xFF7C3AED));

    final Color braceColor = isGhost 
        ? (widget.isDarkMode ? const Color(0xFF38BDF8).withValues(alpha: 0.3) : const Color(0xFF0284C7).withValues(alpha: 0.25)) // Cyber Blue
        : (widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0284C7));

    final Color normalColor = isGhost 
        ? (widget.isDarkMode ? const Color(0xFFE2E8F0).withValues(alpha: 0.2) : const Color(0xFF475569).withValues(alpha: 0.15))
        : (widget.isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF475569));

    // Monospaced tokenizer regex for JSON values
    final regExp = RegExp(
      r'("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*")|(-?\d+(?:\.\d*)?(?:[eE][+-]?\d+)?)|(true|false|null)|([{}[\]:,])|([^\s"{}[\]:,]+)',
      multiLine: true,
    );

    final List<InlineSpan> spans = [];
    int lastIndex = 0;

    for (final match in regExp.allMatches(jsonStr)) {
      if (match.start > lastIndex) {
        final String whitespace = jsonStr.substring(lastIndex, match.start);
        spans.add(TextSpan(text: whitespace, style: baseStyle.copyWith(color: normalColor)));
      }

      final String token = match.group(0)!;
      if (match.group(1) != null) {
        // String literal (key or value)
        // Check if followed by colon (ignoring space) to determine if it is a JSON Key
        final int colonCheckIndex = jsonStr.indexOf(':', match.end);
        bool isKey = false;
        if (colonCheckIndex != -1) {
          final String between = jsonStr.substring(match.end, colonCheckIndex).trim();
          if (between.isEmpty) {
            isKey = true;
          }
        }

        spans.add(TextSpan(
          text: token,
          style: baseStyle.copyWith(
            color: isKey ? keyColor : stringColor,
            fontWeight: FontWeight.w600,
          ),
        ));
      } else if (match.group(3) != null) {
        // Number literal
        spans.add(TextSpan(
          text: token,
          style: baseStyle.copyWith(
            color: numberColor,
            fontWeight: FontWeight.w600,
          ),
        ));
      } else if (match.group(4) != null) {
        // Boolean/null keyword
        spans.add(TextSpan(
          text: token,
          style: baseStyle.copyWith(
            color: keywordColor,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(5) != null) {
        // Brackets / punctuation
        spans.add(TextSpan(
          text: token,
          style: baseStyle.copyWith(
            color: braceColor,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else {
        // Other unmatched literals
        spans.add(TextSpan(
          text: token,
          style: baseStyle.copyWith(color: normalColor),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < jsonStr.length) {
      spans.add(TextSpan(
        text: jsonStr.substring(lastIndex),
        style: baseStyle.copyWith(color: normalColor),
      ));
    }

    return spans;
  }

  List<InlineSpan> _parseMarkdownToSpans(String text, TextStyle baseStyle, bool isGhost) {
    final List<InlineSpan> spans = [];
    final List<String> lines = text.split('\n');

    final Color bulletColor = isGhost
        ? (widget.isDarkMode ? const Color(0xFF38BDF8).withValues(alpha: 0.3) : const Color(0xFF0284C7).withValues(alpha: 0.2))
        : (widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0284C7));

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      final String suffix = (i == lines.length - 1) ? '' : '\n';

      if (line.startsWith('### ')) {
        spans.addAll(_parseInlineMarkdown(
          line.substring(4) + suffix, 
          baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: baseStyle.fontSize! * 1.15,
          ),
          isGhost,
        ));
      } else if (line.startsWith('## ')) {
        spans.addAll(_parseInlineMarkdown(
          line.substring(3) + suffix, 
          baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: baseStyle.fontSize! * 1.3,
          ),
          isGhost,
        ));
      } else if (line.startsWith('# ')) {
        spans.addAll(_parseInlineMarkdown(
          line.substring(2) + suffix, 
          baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: baseStyle.fontSize! * 1.45,
          ),
          isGhost,
        ));
      } else if (line.startsWith('- ')) {
        spans.add(TextSpan(
          text: '• ',
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: bulletColor,
          ),
        ));
        spans.addAll(_parseInlineMarkdown(line.substring(2) + suffix, baseStyle, isGhost));
      } else {
        spans.addAll(_parseInlineMarkdown(line + suffix, baseStyle, isGhost));
      }
    }
    return spans;
  }

  List<InlineSpan> _parseInlineMarkdown(String text, TextStyle baseStyle, bool isGhost) {
    final List<InlineSpan> spans = [];
    final regExp = RegExp(
      r'(\*\*(.*?)\*\*)|(\*(.*?)\*)|(`(.*?)`)',
      multiLine: true,
    );

    final Color codeBg = isGhost
        ? (widget.isDarkMode ? const Color(0xFF0284C7).withValues(alpha: 0.05) : const Color(0xFFBAE6FD).withValues(alpha: 0.05))
        : (widget.isDarkMode ? const Color(0xFF0284C7).withValues(alpha: 0.15) : const Color(0xFFBAE6FD).withValues(alpha: 0.3));

    final Color codeColor = isGhost
        ? (widget.isDarkMode ? const Color(0xFF38BDF8).withValues(alpha: 0.35) : const Color(0xFF0369A1).withValues(alpha: 0.25))
        : (widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0369A1));

    int lastIndex = 0;
    for (final match in regExp.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      if (match.group(1) != null) {
        // Bold
        final String content = match.group(2)!;
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(3) != null) {
        // Italic
        final String content = match.group(4)!;
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(5) != null) {
        // Inline code block
        final String content = match.group(6)!;
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: codeBg,
            color: codeColor,
            fontWeight: FontWeight.bold,
          ),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return spans;
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

  Widget _buildWhitePaperPanel(ParsedResult parsed, ViewState state) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white, // Crisp drafting paper sheet / dark blueprint paper
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
          // Paper subtle grid watermark
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: CustomPaint(
                painter: PaperWatermarkPainter(
                  gridColor: widget.isDarkMode 
                      ? const Color(0xFF1E293B).withValues(alpha: 0.4) 
                      : const Color(0xFFF1F5F9),
                ),
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

                  // High-tech premium tab selector
                  Row(
                    children: [
                      _buildTabButton(0, '🎨 VISUAL PREVIEW'),
                      const SizedBox(width: 8),
                      _buildTabButton(1, '🔍 STATE INSPECTOR (DEBUG)'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: _activeRightTabIndex == 0
                        ? SingleChildScrollView(
                            controller: _previewScrollController,
                            physics: const BouncingScrollPhysics(),
                            child: widget.genUi.view(widget.viewId),
                          )
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: _buildStateInspector(),
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

  Widget _buildTabButton(int index, String label) {
    final isActive = _activeRightTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeRightTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive 
              ? (widget.isDarkMode ? const Color(0xFF38BDF8).withValues(alpha: 0.15) : const Color(0xFF0EA5E9).withValues(alpha: 0.12))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive 
                ? (widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9))
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: isActive 
                ? (widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9))
                : (widget.isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
          ),
        ),
      ),
    );
  }

  Widget _buildStateInspector() {
    final state = widget.genUi.getViewState(widget.viewId);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        if (state.blocks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 40.0),
            child: Center(
              child: Text(
                'NO ACTIVE PARSED BLOCKS YET',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(state.blocks.length, (index) {
            final block = state.blocks[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Block header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'BLOCK #0${index + 1} // ${block is TextBlock ? "TEXT_BLOCK" : "INTERACTIVE_BLOCK"}',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: block is TextBlock
                              ? (widget.isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669))
                              : (widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                        ),
                      ),
                      if (block is InteractiveBlock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: block.isComplete
                                ? const Color(0x2210B981)
                                : const Color(0x223B82F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            block.isComplete ? 'COMPLETE' : 'STREAMING',
                            style: TextStyle(
                              fontSize: 8,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: block.isComplete ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  if (block is TextBlock)
                    Text(
                      block.text.isEmpty ? '(Empty spacer text block)' : block.text,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.4,
                        color: widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    )
                  else if (block is InteractiveBlock)
                    _buildInteractiveBlockDebug(block),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildInteractiveBlockDebug(InteractiveBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LiveMapInspector(
          mapStream: block.rootMapStream,
          isDarkMode: widget.isDarkMode,
          indentLevel: 0,
        ),
      ],
    );
  }
}

class LiveMapInspector extends StatefulWidget {
  final MapPropertyStream mapStream;
  final bool isDarkMode;
  final int indentLevel;

  const LiveMapInspector({
    super.key,
    required this.mapStream,
    required this.isDarkMode,
    this.indentLevel = 1,
  });

  @override
  State<LiveMapInspector> createState() => _LiveMapInspectorState();
}

class _LiveMapInspectorState extends State<LiveMapInspector> {
  final Map<String, dynamic> _values = {};
  final Map<String, StreamSubscription> _subscriptions = {};

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    widget.mapStream.onProperty((propertyStream, key) {
      if (!mounted) return;

      setState(() {
        _values[key] = '...'; // Initial placeholder
      });

      _subscribeToProperty(key, propertyStream);
    });
  }

  void _subscribeToProperty(String key, PropertyStream propertyStream) {
    if (propertyStream is StringPropertyStream) {
      String accumulated = '';
      final sub = propertyStream.stream.listen((chunk) {
        if (mounted) {
          setState(() {
            accumulated += chunk;
            _values[key] = accumulated;
          });
        }
      });
      _subscriptions['$key-stream'] = sub;

      propertyStream.future.then((full) {
        if (mounted) {
          setState(() {
            _values[key] = full;
          });
        }
      }).catchError((_) {});
    } else if (propertyStream is NumberPropertyStream) {
      final sub = propertyStream.stream.listen((val) {
        if (mounted) {
          setState(() {
            _values[key] = val;
          });
        }
      });
      _subscriptions['$key-stream'] = sub;

      propertyStream.future.then((val) {
        if (mounted) {
          setState(() {
            _values[key] = val;
          });
        }
      }).catchError((_) {});
    } else if (propertyStream is BooleanPropertyStream) {
      final sub = propertyStream.stream.listen((val) {
        if (mounted) {
          setState(() {
            _values[key] = val;
          });
        }
      });
      _subscriptions['$key-stream'] = sub;

      propertyStream.future.then((val) {
        if (mounted) {
          setState(() {
            _values[key] = val;
          });
        }
      }).catchError((_) {});
    } else if (propertyStream is NullPropertyStream) {
      propertyStream.future.then((_) {
        if (mounted) {
          setState(() {
            _values[key] = null;
          });
        }
      }).catchError((_) {});
    } else if (propertyStream is MapPropertyStream) {
      if (mounted) {
        setState(() {
          _values[key] = propertyStream;
        });
      }
    } else if (propertyStream is ListPropertyStream) {
      if (mounted) {
        setState(() {
          _values[key] = propertyStream;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant LiveMapInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapStream != widget.mapStream) {
      _cancelSubscriptions();
      _values.clear();
      _startListening();
    }
  }

  void _cancelSubscriptions() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String indent = '  ' * widget.indentLevel;
    final keys = _values.keys.toList()..sort();

    if (keys.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Text(
          '{}',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: widget.isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: keys.map((key) {
        final val = _values[key];

        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$indent"$key": ',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    ),
                  ),
                  Expanded(
                    child: _buildValueWidget(val),
                  ),
                ],
              ),
              if (val is MapPropertyStream) ...[
                LiveMapInspector(
                  mapStream: val,
                  isDarkMode: widget.isDarkMode,
                  indentLevel: widget.indentLevel + 1,
                ),
              ] else if (val is ListPropertyStream) ...[
                LiveListInspector(
                  listStream: val,
                  isDarkMode: widget.isDarkMode,
                  indentLevel: widget.indentLevel + 1,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildValueWidget(dynamic val) {
    if (val is MapPropertyStream) {
      return Text(
        '{',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: widget.isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
      );
    }
    if (val is ListPropertyStream) {
      return Text(
        '[',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: widget.isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
      );
    }
    if (val == null) {
      return Text(
        'null',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: widget.isDarkMode ? const Color(0xFFF43F5E) : const Color(0xFFE11D48),
        ),
      );
    }
    if (val is bool) {
      return Text(
        val.toString(),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: widget.isDarkMode ? const Color(0xFFFB923C) : const Color(0xFFEA580C),
        ),
      );
    }
    if (val is num) {
      return Text(
        val.toString(),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: widget.isDarkMode ? const Color(0xFFC084FC) : const Color(0xFF9333EA),
        ),
      );
    }

    final isStreamingPlaceholder = val == '...';
    return Text(
      '"$val"',
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 11,
        color: isStreamingPlaceholder
            ? (widget.isDarkMode ? const Color(0xFFFB7185) : const Color(0xFFF43F5E))
            : (widget.isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669)),
        fontStyle: isStreamingPlaceholder ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }
}

class LiveListInspector extends StatefulWidget {
  final ListPropertyStream listStream;
  final bool isDarkMode;
  final int indentLevel;

  const LiveListInspector({
    super.key,
    required this.listStream,
    required this.isDarkMode,
    required this.indentLevel,
  });

  @override
  State<LiveListInspector> createState() => _LiveListInspectorState();
}

class _LiveListInspectorState extends State<LiveListInspector> {
  final List<dynamic> _elements = [];
  final Map<int, StreamSubscription> _subscriptions = {};

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    widget.listStream.onElement((propertyStream, index) {
      if (!mounted) return;

      setState(() {
        if (index >= _elements.length) {
          _elements.add('...');
        } else {
          _elements[index] = '...';
        }
      });

      _subscribeToElement(index, propertyStream);
    });
  }

  void _subscribeToElement(int index, PropertyStream propertyStream) {
    if (propertyStream is StringPropertyStream) {
      String accumulated = '';
      final sub = propertyStream.stream.listen((chunk) {
        if (mounted) {
          setState(() {
            accumulated += chunk;
            _elements[index] = accumulated;
          });
        }
      });
      _subscriptions[index] = sub;

      propertyStream.future.then((full) {
        if (mounted) {
          setState(() {
            _elements[index] = full;
          });
        }
      }).catchError((_) {});
    } else if (propertyStream is NumberPropertyStream) {
      final sub = propertyStream.stream.listen((val) {
        if (mounted) {
          setState(() {
            _elements[index] = val;
          });
        }
      });
      _subscriptions[index] = sub;

      propertyStream.future.then((val) {
        if (mounted) {
          setState(() {
            _elements[index] = val;
          });
        }
      }).catchError((_) {});
    } else if (propertyStream is BooleanPropertyStream) {
      final sub = propertyStream.stream.listen((val) {
        if (mounted) {
          setState(() {
            _elements[index] = val;
          });
        }
      });
      _subscriptions[index] = sub;

      propertyStream.future.then((val) {
        if (mounted) {
          setState(() {
            _elements[index] = val;
          });
        }
      }).catchError((_) {});
    } else if (propertyStream is NullPropertyStream) {
      propertyStream.future.then((_) {
        if (mounted) {
          setState(() {
            _elements[index] = null;
          });
        }
      }).catchError((_) {});
    } else if (propertyStream is MapPropertyStream) {
      if (mounted) {
        setState(() {
          _elements[index] = propertyStream;
        });
      }
    } else if (propertyStream is ListPropertyStream) {
      if (mounted) {
        setState(() {
          _elements[index] = propertyStream;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant LiveListInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listStream != widget.listStream) {
      _cancelSubscriptions();
      _elements.clear();
      _startListening();
    }
  }

  void _cancelSubscriptions() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String indent = '  ' * widget.indentLevel;

    if (_elements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Text(
          '[]',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: widget.isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_elements.length, (index) {
        final val = _elements[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$indent- ',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                    ),
                  ),
                  Expanded(
                    child: _buildValueWidget(val),
                  ),
                ],
              ),
              if (val is MapPropertyStream) ...[
                LiveMapInspector(
                  mapStream: val,
                  isDarkMode: widget.isDarkMode,
                  indentLevel: widget.indentLevel + 1,
                ),
              ] else if (val is ListPropertyStream) ...[
                LiveListInspector(
                  listStream: val,
                  isDarkMode: widget.isDarkMode,
                  indentLevel: widget.indentLevel + 1,
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildValueWidget(dynamic val) {
    if (val is MapPropertyStream) {
      return Text(
        '{',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: widget.isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
      );
    }
    if (val is ListPropertyStream) {
      return Text(
        '[',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: widget.isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
      );
    }
    if (val == null) {
      return Text(
        'null',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: widget.isDarkMode ? const Color(0xFFF43F5E) : const Color(0xFFE11D48),
        ),
      );
    }
    if (val is bool) {
      return Text(
        val.toString(),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: widget.isDarkMode ? const Color(0xFFFB923C) : const Color(0xFFEA580C),
        ),
      );
    }
    if (val is num) {
      return Text(
        val.toString(),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: widget.isDarkMode ? const Color(0xFFC084FC) : const Color(0xFF9333EA),
        ),
      );
    }

    final isStreamingPlaceholder = val == '...';
    return Text(
      '"$val"',
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 11,
        color: isStreamingPlaceholder
            ? (widget.isDarkMode ? const Color(0xFFFB7185) : const Color(0xFFF43F5E))
            : (widget.isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669)),
        fontStyle: isStreamingPlaceholder ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }
}
