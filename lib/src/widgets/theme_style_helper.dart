import 'package:flutter/material.dart';

/// Central Design System tokens and custom shapes supporting
/// all 7 aesthetic UI styles: Material, Fluent, Apple, Glassmorphic,
/// Neumorphic, Skeuomorphic, and Brutalist.
class ThemeStyleHelper {
  /// Parses theme settings overrides, falling back to clean context defaults.
  static Color parseColor(String? hexString, Color fallback) {
    if (hexString == null) return fallback;
    var hex = hexString.replaceAll('#', '');
    if (hex.length == 3) {
      hex = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
    }
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length == 8) {
      final val = int.tryParse(hex, radix: 16);
      if (val != null) return Color(val);
    }
    return fallback;
  }

  /// Resolves the design card geometry based on selected theme prefix.
  static ShapeBorder getCardShape(String theme, double? borderRadiusOverride, BuildContext context) {
    final themeData = Theme.of(context);
    switch (theme) {
      case 'apple':
        return RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(borderRadiusOverride ?? 18.0),
          side: BorderSide(
            color: themeData.colorScheme.outline.withValues(alpha: 0.06),
            width: 0.5,
          ),
        );
      case 'brutalist':
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusOverride ?? 0.0),
          side: const BorderSide(
            color: Colors.black,
            width: 3.0,
          ),
        );
      case 'fluent':
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusOverride ?? 8.0),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.0,
          ),
        );
      case 'neumorphic':
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusOverride ?? 24.0),
        );
      case 'glassmorphic':
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusOverride ?? 16.0),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.0,
          ),
        );
      case 'skeumorphic':
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusOverride ?? 12.0),
          side: BorderSide(
            color: Colors.grey.shade400,
            width: 1.5,
          ),
        );
      case 'material':
      default:
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusOverride ?? 16.0),
          side: BorderSide(
            color: themeData.colorScheme.outline.withValues(alpha: 0.08),
            width: 1.0,
          ),
        );
    }
  }

  /// Resolves the card container decoration (colors, blurs, and shadows).
  static Decoration getCardDecoration(
    String theme,
    Map<String, dynamic> settings,
    BuildContext context, {
    bool isPressed = false,
  }) {
    final themeData = Theme.of(context);
    final isDark = themeData.brightness == Brightness.dark;

    final primaryColorOverride = settings["primaryColor"] as String?;
    final cardBgOverride = settings["backgroundColor"] as String?;

    final primaryColor = parseColor(primaryColorOverride, themeData.colorScheme.primary);
    final defaultBg = isDark ? themeData.colorScheme.surfaceContainerHigh : Colors.white;
    final cardBg = parseColor(cardBgOverride, defaultBg);

    switch (theme) {
      case 'brutalist':
        // Pop highlight style
        final highlightHex = settings["highlightColor"] as String?;
        final highlight = parseColor(highlightHex, const Color(0xFFFFFF00)); // Hot Yellow
        return BoxDecoration(
          color: isPressed ? primaryColor : highlight,
          boxShadow: isPressed
              ? []
              : [
                  const BoxShadow(
                    color: Colors.black,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
        );

      case 'neumorphic':
        // Soft physical bevel shadows
        final surfaceColor = cardBgOverride != null
            ? parseColor(cardBgOverride, themeData.colorScheme.surface)
            : themeData.colorScheme.surface;

        return BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(settings["borderRadius"] as double? ?? 24.0),
          boxShadow: isPressed
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.7),
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(5, 5),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    offset: const Offset(-5, -5),
                    blurRadius: 10,
                  ),
                ],
        );

      case 'glassmorphic':
        return BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(settings["borderRadius"] as double? ?? 16.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.02),
            ],
          ),
        );

      case 'fluent':
        return BoxDecoration(
          color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(settings["borderRadius"] as double? ?? 8.0),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.0,
          ),
        );

      case 'skeumorphic':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade100,
              Colors.grey.shade300,
            ],
          ),
          borderRadius: BorderRadius.circular(settings["borderRadius"] as double? ?? 12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.9),
              offset: const Offset(-2, -2),
              blurRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              offset: const Offset(2, 2),
              blurRadius: 3,
            ),
          ],
        );

      case 'apple':
      case 'material':
      default:
        return BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(settings["borderRadius"] as double? ?? 16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );
    }
  }

  /// Typography styling standard for title/subtitle under themes.
  static TextStyle getTextStyle(String theme, BuildContext context, {bool isTitle = true}) {
    final themeData = Theme.of(context);
    switch (theme) {
      case 'brutalist':
        return TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: isTitle ? 16.0 : 13.0,
          color: Colors.black,
        );
      case 'apple':
        return TextStyle(
          fontWeight: isTitle ? FontWeight.w600 : FontWeight.normal,
          fontSize: isTitle ? 16.0 : 13.0,
          letterSpacing: -0.2,
          color: themeData.colorScheme.onSurface,
        );
      case 'fluent':
      case 'glassmorphic':
        return TextStyle(
          fontWeight: isTitle ? FontWeight.w600 : FontWeight.normal,
          fontSize: isTitle ? 15.0 : 12.5,
          color: themeData.colorScheme.onSurface,
        );
      case 'material':
      default:
        return TextStyle(
          fontWeight: isTitle ? FontWeight.w500 : FontWeight.normal,
          fontSize: isTitle ? 16.0 : 13.0,
          color: themeData.colorScheme.onSurface,
        );
    }
  }
}

/// A mathematical Rounded Superellipse Squircle Border (macOS/iOS style).
class RoundedSuperellipseBorder extends OutlinedBorder {
  final BorderRadius borderRadius;

  const RoundedSuperellipseBorder({
    super.side,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  ShapeBorder scale(double t) {
    return RoundedSuperellipseBorder(
      side: side.scale(t),
      borderRadius: borderRadius * t,
    );
  }

  @override
  RoundedSuperellipseBorder copyWith({BorderSide? side, BorderRadius? borderRadius}) {
    return RoundedSuperellipseBorder(
      side: side ?? this.side,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect.deflate(side.width), textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final path = Path();
    final width = rect.width;
    final height = rect.height;
    final left = rect.left;
    final top = rect.top;

    final radius = borderRadius.topLeft.x.clamp(0.0, width / 2.0);

    if (radius <= 0.0) {
      path.addRect(rect);
      return path;
    }

    // Mathematical Squircle path approximation using cubic Beziers
    path.moveTo(left + radius, top);
    path.lineTo(left + width - radius, top);
    path.cubicTo(
      left + width - radius * 0.45, top,
      left + width, top + radius * 0.45,
      left + width, top + radius,
    );
    path.lineTo(left + width, top + height - radius);
    path.cubicTo(
      left + width, top + height - radius * 0.45,
      left + width - radius * 0.45, top + height,
      left + width - radius, top + height,
    );
    path.lineTo(left + radius, top + height);
    path.cubicTo(
      left + radius * 0.45, top + height,
      left, top + height - radius * 0.45,
      left, top + height - radius,
    );
    path.lineTo(left, top + radius);
    path.cubicTo(
      left, top + radius * 0.45,
      left + radius * 0.45, top,
      left + radius, top,
    );
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;

    final paint = side.toPaint();
    final path = getOuterPath(rect, textDirection: textDirection);
    canvas.drawPath(path, paint);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is RoundedSuperellipseBorder &&
        other.side == side &&
        other.borderRadius == borderRadius;
  }

  @override
  int get hashCode => Object.hash(side, borderRadius);
}
