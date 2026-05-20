import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';

// --- Custom User Profile Card ---
class CustomUserProfileCard extends StatefulWidget {
  final PropertyStream props;

  const CustomUserProfileCard({super.key, required this.props});

  @override
  State<CustomUserProfileCard> createState() => _CustomUserProfileCardState();
}

class _CustomUserProfileCardState extends State<CustomUserProfileCard> {
  late final Stream<String> _colorStream;

  @override
  void initState() {
    super.initState();
    _colorStream = widget.props.asMap.getStringProperty('themeColor').stream;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: AccumulatingStringStreamBuilder(
        stream: _colorStream,
        initialValue: '#2196F3',
        builder: (context, hexColor) {
          Color color;
          try {
            color = Color(int.parse(hexColor.replaceAll('#', '0xff')));
          } catch (_) {
            color = theme.colorScheme.primary;
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: const Cubic(0.2, 0.8, 0.2, 1.0), // Standard Snap Curve
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                // ignore: deprecated_member_use
                color: color.withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: color.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StreamingText(
                          props: widget.props,
                          propertyName: 'name',
                          initialValue: 'Typing name...',
                          builder: (context, name) => Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        StreamingText(
                          props: widget.props,
                          propertyName: 'role',
                          initialValue: 'Typing role...',
                          builder: (context, role) => Text(
                            role,
                            style: TextStyle(
                              fontSize: 13,
                              // ignore: deprecated_member_use
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- Custom Hotel Card ---
class CustomHotelCard extends StatelessWidget {
  final PropertyStream props;

  const CustomHotelCard({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamingEntrance(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            // ignore: deprecated_member_use
            color: theme.colorScheme.outline.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: StreamingText(
                        props: props,
                        propertyName: 'title',
                        initialValue: 'Typing hotel name...',
                        builder: (context, title) => Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StreamingText(
                      props: props,
                      propertyName: 'rating',
                      builder: (context, rating) {
                        final hasRating = rating.isNotEmpty && rating != '...';
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: hasRating
                                ? Colors.amber.shade700
                                : theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: hasRating ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasRating ? rating : '...',
                                style: TextStyle(
                                  color: hasRating ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.4),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamingText(
                  props: props,
                  propertyName: 'description',
                  initialValue: 'Typing description...',
                  builder: (context, desc) => Text(
                    desc,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      // ignore: deprecated_member_use
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
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

// Custom Registry Map
final Map<String, WidgetDefinition> customRegistry = {
  'custom:user_profile': WidgetDefinition(
    builder: (context, props) => CustomUserProfileCard(props: props),
    description: "Displays a premium user profile card with typewriter text animations.",
    properties: {
      "name": "String (user's name)",
      "role": "String (user's professional role)",
      "themeColor": "String (HEX color code, e.g. #3b82f6)"
    },
    jsonExample: '{"namespace":"custom:user_profile","name":"Vincent Sanicolas","role":"Senior Flutter Architect","themeColor":"#3b82f6"}',
  ),
  'custom:hotel_card': WidgetDefinition(
    builder: (context, props) => CustomHotelCard(props: props),
    description: "Displays a premium hotel recommendation card with a rating star badge.",
    properties: {
      "title": "String (hotel name)",
      "description": "String (short review description)",
      "rating": "String (star rating, e.g. 4.9)"
    },
    jsonExample: '{"namespace":"custom:hotel_card","title":"Le Bristol Paris","description":"A historic palace hotel featuring 3-star Michelin dining.","rating":"4.9"}',
  ),
};
