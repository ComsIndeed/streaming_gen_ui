import 'package:flutter/material.dart';

/// Configuration options for the Streaming Generative UI rendering system.
class GenerativeUiConfig {
  /// Whether to automatically adjust widget colors to match light or dark theme brightness.
  /// When true (default), colors provided dynamically (like HEX background colors) will be
  /// mathematically adjusted/tinted for high contrast and visual cohesion in dark/light modes.
  /// This can be bypassed per-widget by supplying `exactColor: true`.
  final bool adaptColorsToTheme;

  const GenerativeUiConfig({
    this.adaptColorsToTheme = true,
  });
}

/// Helper function to automatically adjust dynamic colors to match active theme brightness
/// if [GenerativeUiConfig.adaptColorsToTheme] is enabled.
Color adjustColorForTheme(
  BuildContext context,
  Color color, {
  bool isBackground = true,
  bool exactColor = false,
  GenerativeUiConfig? config,
}) {
  final adapt = config?.adaptColorsToTheme ?? true;
  if (!adapt || exactColor) return color;

  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (!isDark) {
    // In light mode, the colors are already comfortable.
    return color;
  }

  // In dark mode:
  final hsl = HSLColor.fromColor(color);
  if (isBackground) {
    // Background: Darken the lightness to a comfortable dark slate range (0.07 to 0.15)
    // and desaturate to blend nicely with slate/grid backgrounds.
    final double newLightness = hsl.lightness > 0.4
        ? 0.07 + (hsl.lightness - 0.4) * 0.08
        : hsl.lightness.clamp(0.05, 0.15);
    final double newSaturation = hsl.saturation.clamp(0.1, 0.35);
    return hsl.withLightness(newLightness).withSaturation(newSaturation).toColor();
  } else {
    // Text/Foreground: Lighten the lightness to make it high contrast & pastel readable (0.75 to 0.95).
    final double newLightness = hsl.lightness < 0.6
        ? 0.8 - (0.6 - hsl.lightness) * 0.15
        : hsl.lightness.clamp(0.75, 0.95);
    final double newSaturation = hsl.saturation.clamp(0.2, 0.65);
    return hsl.withLightness(newLightness).withSaturation(newSaturation).toColor();
  }
}
