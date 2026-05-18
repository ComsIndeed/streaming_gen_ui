import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';

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
    // Parse accumulated text
    final parsedResult = _parseText(_accumulatedText);

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

  Widget _buildBlueprintPanel(_ParsedResult parsed) {
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
            color: Colors.blue.withOpacity(0.03),
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
                            color: widget.isTokenSaverEnabled ? const Color(0xFF059669).withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: widget.isTokenSaverEnabled ? const Color(0xFF059669).withOpacity(0.3) : const Color(0xFF94A3B8).withOpacity(0.3),
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
                          color: _autoScroll ? const Color(0xFF0369A1).withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _autoScroll ? const Color(0xFF0369A1).withOpacity(0.3) : Colors.transparent,
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
                            ? const Color(0xFFBAE6FD).withOpacity(0.6)
                            : const Color(0xFFE2E8F0).withOpacity(0.6),
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
                  painter: _BlueprintGridPainter(
                    gridColor: const Color(0xFF0EA5E9).withOpacity(0.12),
                    majorColor: const Color(0xFF0EA5E9).withOpacity(0.24),
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
    final parsed = _parseText(rawText);
    
    final Color tagColor = isGhost ? const Color(0xFF0EA5E9).withOpacity(0.25) : const Color(0xFF0284C7);
    final Color jsonColor = isGhost ? const Color(0xFF0EA5E9).withOpacity(0.18) : const Color(0xFF0F172A);
    final Color normalTextColor = isGhost ? const Color(0xFF0EA5E9).withOpacity(0.14) : const Color(0xFF334155);

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
              painter: _ArrowPainter(
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

  Widget _buildWhitePaperPanel(_ParsedResult parsed) {
    // Dynamic Widget Render Engine on the Right Panel (White Paper)
    final bool hasJson = parsed.hasInteractive && parsed.jsonText.trim().isNotEmpty;
    Map<String, dynamic>? decodedJson;
    String? parseError;

    if (hasJson) {
      try {
        final String cleanedJson = _cleanJsonString(parsed.jsonText);
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Paper subtle grid water-mark to make it feel organic
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: CustomPaint(
                painter: _PaperWatermarkPainter(),
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
      return _buildSkeletonLoader(isActive: _isProcessing);
    }

    if (parseError != null) {
      // 2. Mid-stream or faulty JSON: Draw partial skeletons next to dynamic error feedback
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSkeletonLoader(isActive: _isProcessing),
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
      return _buildWidgetFromJson(decodedJson);
    }

    return const SizedBox();
  }

  Widget _buildSkeletonLoader({required bool isActive}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(4, (index) {
        final widths = [0.85, 0.95, 0.70, 0.40];
        final w = widths[index % widths.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBlock(widthPercent: w, height: 16, isActive: isActive),
              const SizedBox(height: 6),
              _SkeletonBlock(widthPercent: w * 0.8, height: 10, isActive: isActive),
            ],
          ),
        );
      }),
    );
  }

  // --- RECURSIVE JSON WIDGET GENERATOR ---

  Widget _buildWidgetFromJson(Map<String, dynamic> json) {
    final String ns = json['namespace'] ?? '';
    final childrenRaw = json['children'];
    final childRaw = json['child'];

    // Map children
    List<Widget> children = [];
    if (childrenRaw is List) {
      children = childrenRaw.map((c) => _buildWidgetFromJson(c as Map<String, dynamic>)).toList();
    }

    // Map child
    Widget? child;
    if (childRaw is Map) {
      child = _buildWidgetFromJson(childRaw as Map<String, dynamic>);
    }

    switch (ns) {
      case 'core:column':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        );

      case 'core:row':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        );

      case 'core:container':
        final double? w = json['width'] != null ? double.tryParse(json['width'].toString()) : null;
        final double? h = json['height'] != null ? double.tryParse(json['height'].toString()) : null;
        final double pad = double.tryParse(json['padding']?.toString() ?? '0') ?? 0;

        // Custom premium decoration parser
        BoxDecoration? decoration;
        final decRaw = json['decoration'];
        if (decRaw is Map) {
          final String? hexBg = decRaw['color'];
          final double borderRad = double.tryParse(decRaw['borderRadius']?.toString() ?? '0') ?? 0;
          final borderRaw = decRaw['border'];

          Border? border;
          if (borderRaw is Map) {
            final String? bColor = borderRaw['color'];
            final double bWidth = double.tryParse(borderRaw['width']?.toString() ?? '1') ?? 1;
            border = Border.all(
              color: bColor != null ? (_parseHexColor(bColor) ?? const Color(0xFFCBD5E1)) : const Color(0xFFCBD5E1),
              width: bWidth,
            );
          }

          decoration = BoxDecoration(
            color: hexBg != null ? _parseHexColor(hexBg) : null,
            borderRadius: BorderRadius.circular(borderRad),
            border: border,
          );
        }

        return Container(
          width: w,
          height: h,
          padding: pad > 0 ? EdgeInsets.all(pad) : null,
          decoration: decoration,
          child: child,
        );

      case 'core:text':
        final String text = json['text'] ?? '';
        final styleRaw = json['style'];

        TextStyle textStyle = const TextStyle(fontSize: 13, color: Color(0xFF334155));
        if (styleRaw is Map) {
          final double fs = double.tryParse(styleRaw['fontSize']?.toString() ?? '13') ?? 13;
          final String? hexColor = styleRaw['color'];
          final String? fontWeight = styleRaw['fontWeight'];
          final String? fontStyle = styleRaw['fontStyle'];

          textStyle = TextStyle(
            fontSize: fs,
            color: hexColor != null ? (_parseHexColor(hexColor) ?? const Color(0xFF334155)) : const Color(0xFF334155),
            fontWeight: fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
            fontStyle: fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
          );
        }

        return Text(text, style: textStyle);

      case 'core:elevated_button':
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB), // Sleek Royal Blue button
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () {
            // Show cute toast
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Action Registered Successfully!',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF1E3A8A),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          },
          child: child ?? const Text('Action'),
        );

      default:
        // Unknown widget handler - default warning style
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFCD34D)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
              const SizedBox(width: 6),
              Text(
                'Unknown Namespace: $ns',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFB45309),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
    }
  }

  Color? _parseHexColor(String hexString) {
    try {
      hexString = hexString.replaceAll('#', '');
      if (hexString.length == 6) {
        hexString = 'FF$hexString';
      }
      return Color(int.parse(hexString, radix: 16));
    } catch (_) {
      return null;
    }
  }

  // --- STREAM PARSER HELPERS ---

  _ParsedResult _parseText(String text) {
    final int startIndex = text.indexOf('<interactive>');
    if (startIndex == -1) {
      return _ParsedResult(
        preText: text,
        jsonText: '',
        postText: '',
        hasInteractive: false,
        isInteractiveClosed: false,
      );
    }

    final String preText = text.substring(0, startIndex);
    final String remaining = text.substring(startIndex + '<interactive>'.length);

    final int endIndex = remaining.indexOf('</interactive>');
    if (endIndex == -1) {
      return _ParsedResult(
        preText: preText,
        jsonText: remaining,
        postText: '',
        hasInteractive: true,
        isInteractiveClosed: false,
      );
    }

    final String jsonText = remaining.substring(0, endIndex);
    final String postText = remaining.substring(endIndex + '</interactive>'.length);

    return _ParsedResult(
      preText: preText,
      jsonText: jsonText,
      postText: postText,
      hasInteractive: true,
      isInteractiveClosed: true,
    );
  }

  String _cleanJsonString(String rawJson) {
    // LLMs sometimes add trailing characters before close tags
    return rawJson.trim();
  }
}

class _ParsedResult {
  final String preText;
  final String jsonText;
  final String postText;
  final bool hasInteractive;
  final bool isInteractiveClosed;

  _ParsedResult({
    required this.preText,
    required this.jsonText,
    required this.postText,
    required this.hasInteractive,
    required this.isInteractiveClosed,
  });
}

// --- CUSTOM PAINTERS ---

/// Blueprint custom grid lines painter that paints on scrollable content height
class _BlueprintGridPainter extends CustomPainter {
  final Color gridColor;
  final Color majorColor;

  _BlueprintGridPainter({required this.gridColor, required this.majorColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final paintMajor = Paint()
      ..color = majorColor
      ..strokeWidth = 1.0;

    const double spacing = 20.0;
    const int majorStep = 5;

    // Draw horizontal grid lines
    for (double y = 0; y < size.height; y += spacing) {
      final isMajor = (y % (spacing * majorStep)).abs() < 0.1;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? paintMajor : paintGrid);
    }

    // Draw vertical grid lines
    for (double x = 0; x < size.width; x += spacing) {
      final isMajor = (x % (spacing * majorStep)).abs() < 0.1;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? paintMajor : paintGrid);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paper grid watermark painter for White Paper Layout
class _PaperWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 0.5;

    const double spacing = 15.0;

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A very thick, bold arrow that shows moving gradient animations when active
class _ArrowPainter extends CustomPainter {
  final double animationValue;
  final bool isActive;
  final bool isWide;

  _ArrowPainter({
    required this.animationValue,
    required this.isActive,
    required this.isWide,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double arrowWidth = size.width;
    final double arrowHeight = size.height;

    // Define the Arrow Path (Thick industrial arrow pointing right)
    final Path arrowPath = Path();
    final double shaftThickPercent = 0.45; // Thickness of the arrow tail
    final double tailYStart = arrowHeight * (1 - shaftThickPercent) / 2;
    final double tailYEnd = arrowHeight * (1 + shaftThickPercent) / 2;

    final double headWidth = arrowWidth * 0.4; // Width of the arrow head tip
    final double headXStart = arrowWidth - headWidth;

    arrowPath.moveTo(0, tailYStart);
    arrowPath.lineTo(headXStart, tailYStart);
    arrowPath.lineTo(headXStart, 0); // Out to top tip point
    arrowPath.lineTo(arrowWidth, arrowHeight / 2); // Main tip
    arrowPath.lineTo(headXStart, arrowHeight); // Down to bottom tip point
    arrowPath.lineTo(headXStart, tailYEnd);
    arrowPath.lineTo(0, tailYEnd);
    arrowPath.close();

    // Base paint
    final Paint fillPaint = Paint()..style = PaintingStyle.fill;

    if (isActive) {
      // Loop a beautiful linear gradient running from left to right along the arrow
      final gradient = LinearGradient(
        colors: const [
          Color(0xFF2563EB), // Sleek Royal Blue
          Color(0xFF60A5FA), // Soft bright light blue
          Color(0xFF38BDF8), // Cyber Cyan
          Color(0xFF60A5FA),
          Color(0xFF2563EB),
        ],
        stops: const [
          0.0,
          0.25,
          0.5,
          0.75,
          1.0,
        ],
        transform: GradientRotation(animationValue * 2 * pi),
      );

      fillPaint.shader = gradient.createShader(Offset.zero & size);
    } else {
      // Idle grey style
      fillPaint.color = const Color(0xFFCBD5E1);
    }

    // Draw arrow body shadow/glow
    if (isActive) {
      canvas.drawPath(
        arrowPath,
        Paint()
          ..color = const Color(0xFF38BDF8).withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Draw main arrow
    canvas.drawPath(arrowPath, fillPaint);

    // Draw soft border around the arrow
    final Paint borderPaint = Paint()
      ..color = isActive ? const Color(0xFF60A5FA) : const Color(0xFF94A3B8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(arrowPath, borderPaint);

    // If active, draw cute chevron details moving
    if (isActive) {
      final double chevX = headXStart * (animationValue);
      final double chevSize = 6.0;

      final chevPaint = Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (chevX < headXStart) {
        canvas.drawPath(
          Path()
            ..moveTo(chevX - chevSize, arrowHeight / 2 - chevSize / 2)
            ..lineTo(chevX, arrowHeight / 2)
            ..lineTo(chevX - chevSize, arrowHeight / 2 + chevSize / 2),
          chevPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isActive != isActive ||
        oldDelegate.isWide != isWide;
  }
}

// --- CORE SKELETON WIDGET ---

class _SkeletonBlock extends StatefulWidget {
  final double widthPercent;
  final double height;
  final bool isActive;

  const _SkeletonBlock({
    required this.widthPercent,
    required this.height,
    required this.isActive,
  });

  @override
  State<_SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<_SkeletonBlock> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.isActive) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _SkeletonBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _shimmerController.repeat();
      } else {
        _shimmerController.stop();
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widget.widthPercent,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          final gradient = LinearGradient(
            colors: const [
              Color(0xFFF1F5F9), // Light grey paper color
              Color(0xFFE2E8F0),
              Color(0xFFF1F5F9),
            ],
            stops: const [0.0, 0.5, 1.0],
            transform: _SlidingGradientTransform(
              widget.isActive ? _shimmerController.value : 0.0,
            ),
          );

          return Container(
            height: widget.height,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 0.5),
            ),
          );
        },
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double value;
  const _SlidingGradientTransform(this.value);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final double width = bounds.width;
    return Matrix4.translationValues(width * (value * 2 - 1.0), 0.0, 0.0);
  }
}
