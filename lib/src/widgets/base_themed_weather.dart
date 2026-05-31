import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/theme_style_helper.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_entrance.dart';
import 'package:streaming_gen_ui/src/widgets/adaptive_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/core/adaptive_animated_size.dart';
import 'package:streaming_gen_ui/src/widgets/core/themed_streaming_text.dart';

/// A premium themed Weather Card supporting M3, Fluent, Apple, Glassmorphic,
/// Neumorphic, Skeuomorphic, and Neo-Brutalist design systems.
class BaseThemedWeatherCard extends StatefulWidget {
  final PropertyStream props;
  final String themeName;

  const BaseThemedWeatherCard({
    super.key,
    required this.props,
    required this.themeName,
  });

  @override
  State<BaseThemedWeatherCard> createState() => _BaseThemedWeatherCardState();
}

class _BaseThemedWeatherCardState extends State<BaseThemedWeatherCard> {
  bool _isPressed = false;
  Map<String, dynamic> _latestData = const {};

  @override
  Widget build(BuildContext context) {
    final mapStream = widget.props.asMap;

    return StreamingEntrance(
      child: AdaptiveStreamBuilder<Map<String, dynamic>>(
        stream: mapStream.stream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};
          _latestData = data;
          final settings =
              data["themeSettings"] as Map<String, dynamic>? ?? const {};

          final temp = data["temp"] as num?;
          final condition = data["condition"] as String? ?? 'sunny';
          final location = data["location"] as String? ?? 'Unknown';
          final humidity = data["humidity"] as num?;
          final windSpeed = data["windSpeed"] as num?;
          final size = data["size"] as String? ?? 'normal';
          final action = data["action"] as String?;

          final hasAction = action != null && action.isNotEmpty;

          // Aesthetic parameters
          final decoration = ThemeStyleHelper.getCardDecoration(
            widget.themeName,
            settings,
            context,
            isPressed: _isPressed,
          );

          final shape = ThemeStyleHelper.getCardShape(
            widget.themeName,
            (settings["borderRadius"] as num?)?.toDouble(),
            context,
          );

          final cardContent = AdaptiveAnimatedSize(
            alignment: Alignment.topLeft,
            child: _buildCardContent(
              context,
              temp,
              condition,
              location,
              humidity,
              windSpeed,
              size,
              mapStream.getListProperty("forecast"),
            ),
          );

          Widget cardFrame;

          if (widget.themeName == 'glassmorphic') {
            cardFrame = ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: BackdropFilter(
                filter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.02),
                  BlendMode.dstATop,
                ),
                child: Container(decoration: decoration, child: cardContent),
              ),
            );
          } else if (widget.themeName == 'fluent') {
            cardFrame = ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: BackdropFilter(
                filter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.04),
                  BlendMode.dstATop,
                ),
                child: Container(decoration: decoration, child: cardContent),
              ),
            );
          } else {
            cardFrame = Container(
              decoration: decoration,
              child: Material(
                type: MaterialType.transparency,
                shape: shape,
                clipBehavior: Clip.antiAlias,
                child: cardContent,
              ),
            );
          }

          if (hasAction) {
            return GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: () {
                debugPrint(
                  '[GEN_UI:WEATHER_ACTION] Weather card clicked -> $action',
                );
              },
              child: AnimatedScale(
                scale: _isPressed ? 0.97 : 1.0,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOutCubic,
                child: cardFrame,
              ),
            );
          }

          return cardFrame;
        },
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    num? temp,
    String condition,
    String location,
    num? humidity,
    num? windSpeed,
    String size,
    PropertyStream forecastProp,
  ) {
    final isBrutalist = widget.themeName == 'brutalist';
    final condLower = condition.toLowerCase();

    // Map weather condition to gradient & color scheme
    Gradient weatherGradient;
    Color weatherAccentColor;
    IconData weatherIcon;

    if (condLower.contains('rain') ||
        condLower.contains('storm') ||
        condLower.contains('drizzle')) {
      weatherGradient = const LinearGradient(
        colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      weatherAccentColor = const Color(0xFF64B5F6);
      weatherIcon = Icons.thunderstorm_outlined;
    } else if (condLower.contains('cloud') ||
        condLower.contains('fog') ||
        condLower.contains('mist')) {
      weatherGradient = const LinearGradient(
        colors: [Color(0xFF616161), Color(0xFF9E9E9E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      weatherAccentColor = const Color(0xFFB0BEC5);
      weatherIcon = Icons.cloud_outlined;
    } else if (condLower.contains('snow') ||
        condLower.contains('ice') ||
        condLower.contains('freeze')) {
      weatherGradient = const LinearGradient(
        colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      weatherAccentColor = const Color(0xFF00ACC1);
      weatherIcon = Icons.ac_unit_outlined;
    } else {
      // Sunny / Clear
      weatherGradient = const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      weatherAccentColor = const Color(0xFFFFEB3B);
      weatherIcon = Icons.wb_sunny_outlined;
    }

    final textTitleStyle = ThemeStyleHelper.getTextStyle(
      widget.themeName,
      context,
      isTitle: true,
    );
    final textSubStyle = ThemeStyleHelper.getTextStyle(
      widget.themeName,
      context,
      isTitle: false,
    );

    // If Brutalist, keep it stark black-and-white or hot yellow solid background
    final weatherBg = isBrutalist
        ? null
        : Container(decoration: BoxDecoration(gradient: weatherGradient));

    final textContrastColor = isBrutalist ? Colors.black : Colors.white;

    final tempString = temp != null ? "${temp.toStringAsFixed(1)}°" : "--°";

    if (size == 'mini') {
      // Mini compact list-view weather card
      return Stack(
        children: [
          if (weatherBg != null) Positioned.fill(child: weatherBg),
          if (!isBrutalist && weatherBg != null)
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.15)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ThemedStreamingText(
                      location,
                      themeName: widget.themeName,
                      style: textTitleStyle.copyWith(
                        color: textContrastColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    ThemedStreamingText(
                      condition.toUpperCase(),
                      themeName: widget.themeName,
                      style: textSubStyle.copyWith(
                        color: textContrastColor.withValues(alpha: 0.8),
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      weatherIcon,
                      color: isBrutalist ? Colors.black : weatherAccentColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      tempString,
                      style: textTitleStyle.copyWith(
                        color: textContrastColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Normal full weather card
    return Stack(
      children: [
        if (weatherBg != null) Positioned.fill(child: weatherBg),
        if (!isBrutalist && weatherBg != null)
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.1)),
          ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ThemedStreamingText(
                          location,
                          themeName: widget.themeName,
                          style: textTitleStyle.copyWith(
                            color: textContrastColor,
                            fontSize: 22,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        ThemedStreamingText(
                          condition.toUpperCase(),
                          themeName: widget.themeName,
                          style: textSubStyle.copyWith(
                            color: textContrastColor.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    weatherIcon,
                    color: isBrutalist ? Colors.black : weatherAccentColor,
                    size: 48,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    tempString,
                    style: textTitleStyle.copyWith(
                      color: textContrastColor,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (humidity != null || windSpeed != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (humidity != null)
                          Text(
                            "Humidity: ${humidity.toInt()}%",
                            style: textSubStyle.copyWith(
                              color: textContrastColor.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        if (windSpeed != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Wind: ${windSpeed.toStringAsFixed(1)} km/h",
                            style: textSubStyle.copyWith(
                              color: textContrastColor.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
              // Forecast list if streamed
              Builder(
                builder: (context) {
                  final list =
                      _latestData["forecast"] as List<dynamic>? ?? const [];
                  if (list.isEmpty) return const SizedBox.shrink();

                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      Divider(
                        color: textContrastColor.withValues(alpha: 0.2),
                        height: 1,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: list.map((item) {
                          final itemMap =
                              item as Map<String, dynamic>? ?? const {};
                          final day = itemMap["day"] as String? ?? '';
                          final dayTemp = itemMap["temp"] as num?;
                          final dayCond =
                              itemMap["condition"] as String? ?? 'sunny';

                          IconData miniIcon;
                          final condL = dayCond.toLowerCase();
                          if (condL.contains('rain') ||
                              condL.contains('storm')) {
                            miniIcon = Icons.thunderstorm_outlined;
                          } else if (condL.contains('cloud')) {
                            miniIcon = Icons.cloud_outlined;
                          } else if (condL.contains('snow')) {
                            miniIcon = Icons.ac_unit_outlined;
                          } else {
                            miniIcon = Icons.wb_sunny_outlined;
                          }

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                day,
                                style: textSubStyle.copyWith(
                                  color: textContrastColor.withValues(
                                    alpha: 0.9,
                                  ),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Icon(
                                miniIcon,
                                color: isBrutalist
                                    ? Colors.black
                                    : weatherAccentColor,
                                size: 20,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                dayTemp != null
                                    ? "${dayTemp.toStringAsFixed(0)}°"
                                    : "--°",
                                style: textTitleStyle.copyWith(
                                  color: textContrastColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
