import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

/// A premium, built-in weather dashboard card with morphing layouts and
/// atmospheric weather condition gradients.
class StreamingWeatherCard extends StatefulWidget {
  final PropertyStream props;

  const StreamingWeatherCard({super.key, required this.props});

  @override
  State<StreamingWeatherCard> createState() => _StreamingWeatherCardState();
}

class _StreamingWeatherCardState extends State<StreamingWeatherCard>
    with SingleTickerProviderStateMixin {
  late Stream<Map<String, dynamic>> _weatherStream;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _weatherStream = widget.props.asMap.stream;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant StreamingWeatherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.props, oldWidget.props)) {
      setState(() {
        _weatherStream = widget.props.asMap.stream;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _weatherStream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const {};

          final cityName = data["cityName"] as String? ?? "Weather Check";
          final temperature = data["temperature"] as String? ?? "";
          final condition = (data["condition"] as String? ?? "sunny")
              .toLowerCase();
          final humidity = data["humidity"] as String? ?? "";
          final windSpeed = data["windSpeed"] as String? ?? "";

          final rawForecast = data["forecast"] as List<dynamic>? ?? const [];
          final forecast = rawForecast
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          // Curated atmospheric gradient based on weather condition
          LinearGradient backgroundGradient;
          Color accentColor;
          IconData weatherIcon;

          if (condition.contains('rain') ||
              condition.contains('drizzle') ||
              condition.contains('storm')) {
            backgroundGradient = const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );
            accentColor = const Color(0xFF3B82F6); // Blue
            weatherIcon = Icons.beach_access_rounded;
          } else if (condition.contains('cloud') ||
              condition.contains('mist') ||
              condition.contains('fog')) {
            backgroundGradient = const LinearGradient(
              colors: [Color(0xFF334155), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );
            accentColor = const Color(0xFF94A3B8); // Slate
            weatherIcon = Icons.cloud_rounded;
          } else if (condition.contains('snow') || condition.contains('ice')) {
            backgroundGradient = const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E1E38)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );
            accentColor = const Color(0xFF38BDF8); // Sky blue
            weatherIcon = Icons.ac_unit_rounded;
          } else {
            // Default sunny/clear
            backgroundGradient = const LinearGradient(
              colors: [Color(0xFF2C1605), Color(0xFF0C0601)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );
            accentColor = const Color(0xFFF59E0B); // Amber
            weatherIcon = Icons.wb_sunny_rounded;
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: backgroundGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: accentColor.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Card Header (City & Pulse Indicator)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cityName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              condition.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: accentColor.withOpacity(0.8),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(
                                0.1 + (0.05 * _pulseController.value),
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              weatherIcon,
                              color: accentColor,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Main Temperature and Key Stats Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (temperature.isNotEmpty) ...[
                        Text(
                          temperature,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                      // Extra stats grid if available
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            if (humidity.isNotEmpty)
                              _buildMetric(
                                label: "HUMIDITY",
                                value: humidity,
                                icon: Icons.water_drop_outlined,
                                color: accentColor,
                              ),
                            if (windSpeed.isNotEmpty)
                              _buildMetric(
                                label: "WIND",
                                value: windSpeed,
                                icon: Icons.air_rounded,
                                color: accentColor,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Forecast grid (rendered progressively as list elements load)
                  if (forecast.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.white10),
                    ),
                    const Text(
                      "3-DAY FORECAST",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white30,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 85,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: forecast.length,
                        separatorBuilder: (context, _) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final item = forecast[index];
                          final day = item["day"] as String? ?? "";
                          final temp = item["temp"] as String? ?? "";
                          final itemCondition =
                              (item["condition"] as String? ?? "sunny")
                                  .toLowerCase();

                          IconData dayIcon = Icons.wb_sunny_rounded;
                          if (itemCondition.contains('rain') ||
                              itemCondition.contains('storm')) {
                            dayIcon = Icons.beach_access_rounded;
                          } else if (itemCondition.contains('cloud')) {
                            dayIcon = Icons.cloud_rounded;
                          }

                          return Container(
                            width: 80,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.03),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  day,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                                Icon(dayIcon, size: 16, color: Colors.white60),
                                Text(
                                  temp,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.white30),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white30,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
