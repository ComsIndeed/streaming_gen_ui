import 'package:flutter/material.dart';

/// The visual animation effects supported by [ThemedStreamingText].
enum TextStreamingEffect {
  /// Renders instantly with no transition.
  none,

  /// Word-by-word smooth opacity fade.
  fade,

  /// Snappy word-by-word opacity fade and slide-up.
  slide,

  /// Premium soft-glow reveal with fading shadows.
  glowingReveal,

  /// Classic retro character-by-character typewriter with a blinking cursor.
  typewriter,
}

/// A premium, high-fidelity text widget that automatically animates newly appended
/// streaming text chunks according to the chosen category design theme or effect override.
class ThemedStreamingText extends StatefulWidget {
  final String text;
  final String themeName;
  final TextStyle? style;
  final TextStreamingEffect? effect;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const ThemedStreamingText(
    this.text, {
    super.key,
    required this.themeName,
    this.style,
    this.effect,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  State<ThemedStreamingText> createState() => _ThemedStreamingTextState();
}

class _ThemedStreamingTextState extends State<ThemedStreamingText>
    with SingleTickerProviderStateMixin {
  List<String> _tokens = [];
  AnimationController? _controller;
  Animation<double>? _animation;
  double _revealIndex = 0.0;

  @override
  void initState() {
    super.initState();
    _tokens = _tokenize(widget.text);
    _revealIndex = _tokens.length.toDouble();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _controller!.addListener(() {
      setState(() {
        if (_animation != null) {
          _revealIndex = _animation!.value;
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant ThemedStreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      final oldTokens = _tokenize(oldWidget.text);
      final newTokens = _tokenize(widget.text);

      if (widget.text.startsWith(oldWidget.text) && oldWidget.text.isNotEmpty) {
        // Active stream append
        _tokens = newTokens;

        _controller!.stop();
        _animation =
            Tween<double>(
              begin: oldTokens.length.toDouble(),
              end: newTokens.length.toDouble(),
            ).animate(
              CurvedAnimation(parent: _controller!, curve: Curves.easeOutCubic),
            );
        _controller!.forward(from: 0.0);
      } else {
        // Complete reset or non-contiguous change
        _tokens = newTokens;
        if (oldWidget.text.isEmpty && widget.text.isNotEmpty) {
          // Animate from scratch
          _controller!.stop();
          _animation =
              Tween<double>(
                begin: 0.0,
                end: newTokens.length.toDouble(),
              ).animate(
                CurvedAnimation(
                  parent: _controller!,
                  curve: Curves.easeOutCubic,
                ),
              );
          _controller!.forward(from: 0.0);
        } else {
          // Instant jump
          _revealIndex = newTokens.length.toDouble();
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  List<String> _tokenize(String val) {
    if (val.isEmpty) return [];
    // Splits by spaces/newlines but keeps them as separate tokens
    final regex = RegExp(r'(\n|\s+|\S+)');
    return regex.allMatches(val).map((m) => m.group(0)!).toList();
  }

  TextStreamingEffect _getEffect() {
    if (widget.effect != null) {
      return widget.effect!;
    }
    switch (widget.themeName.toLowerCase()) {
      case 'brutalist':
        return TextStreamingEffect.typewriter;
      case 'apple':
        return TextStreamingEffect.fade;
      case 'glassmorphic':
        return TextStreamingEffect.glowingReveal;
      case 'fluent':
      case 'neumorphic':
      case 'material':
      case 'skeuomorphic':
      default:
        return TextStreamingEffect.slide;
    }
  }

  double _getTokenProgress(int index) {
    if (_revealIndex >= _tokens.length) return 1.0;
    return (_revealIndex - index).clamp(0.0, 1.0);
  }

  Widget _buildAnimatedWord(
    String token,
    double t,
    TextStyle style,
    TextStreamingEffect effect,
  ) {
    if (t >= 1.0) {
      return Text(token, style: style);
    }
    if (t <= 0.0) {
      return const SizedBox.shrink();
    }

    final child = Text(token, style: style);

    switch (effect) {
      case TextStreamingEffect.fade:
        return Opacity(opacity: t, child: child);
      case TextStreamingEffect.slide:
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 4.0 * (1.0 - t)),
            child: child,
          ),
        );
      case TextStreamingEffect.glowingReveal:
        final double blurSigma = 3.0 * (1.0 - t);
        return Opacity(
          opacity: t,
          child: Text(
            token,
            style: style.copyWith(
              shadows: [
                Shadow(
                  color:
                      style.color?.withValues(alpha: 0.6 * t) ??
                      Colors.blue.withValues(alpha: 0.6 * t),
                  blurRadius: blurSigma * 2.5,
                ),
              ],
            ),
          ),
        );
      case TextStreamingEffect.typewriter:
      case TextStreamingEffect.none:
        return child;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effect = _getEffect();
    final defaultStyle = DefaultTextStyle.of(context).style.merge(widget.style);

    // Dynamic Optimization: if finished animating, fallback to standard native Text widget
    final isDone = _revealIndex >= _tokens.length.toDouble();
    if (isDone && effect != TextStreamingEffect.typewriter) {
      return Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }

    if (effect == TextStreamingEffect.typewriter) {
      // Character-based typewriter
      final charCount = widget.text.length;
      final currentTokensLength = _tokens.length;
      final progressRatio = currentTokensLength > 0
          ? _revealIndex / currentTokensLength
          : 1.0;
      final currentLength = (charCount * progressRatio).round().clamp(
        0,
        charCount,
      );
      final visibleText = widget.text.substring(0, currentLength);
      final isAnimating = currentLength < charCount;

      return RichText(
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        text: TextSpan(
          style: defaultStyle,
          children: [
            TextSpan(text: visibleText),
            if (isAnimating)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _BlinkingCursor(
                  color: defaultStyle.color ?? Colors.black,
                ),
              ),
          ],
        ),
      );
    }

    // Word-based inline rich layout
    final List<InlineSpan> spans = [];
    for (int i = 0; i < _tokens.length; i++) {
      final token = _tokens[i];
      if (token == '\n') {
        spans.add(const TextSpan(text: '\n'));
      } else {
        final t = _getTokenProgress(i);
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _buildAnimatedWord(token, t, defaultStyle, effect),
          ),
        );
      }
    }

    return RichText(
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      text: TextSpan(children: spans),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  final Color color;
  const _BlinkingCursor({required this.color});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        return Opacity(
          opacity: _blinkController.value > 0.5 ? 1.0 : 0.0,
          child: Text(
            '▋',
            style: TextStyle(
              color: widget.color,
              fontSize: DefaultTextStyle.of(context).style.fontSize,
            ),
          ),
        );
      },
    );
  }
}
