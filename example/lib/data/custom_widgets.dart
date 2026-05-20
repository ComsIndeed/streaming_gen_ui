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
    return AccumulatingStringStreamBuilder(
      stream: _colorStream,
      initialValue: '#2196F3',
      builder: (context, hexColor) {
        Color color;
        try {
          color = Color(int.parse(hexColor.replaceAll('#', '0xff')));
        } catch (_) {
          color = Colors.blue;
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreamingText(
                          props: widget.props,
                          propertyName: 'name',
                          initialValue: 'Typing name...',
                          builder: (context, name) => Text(
                            name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: color,
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
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- Custom Hotel Card ---
class CustomHotelCard extends StatelessWidget {
  final PropertyStream props;

  const CustomHotelCard({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                StreamingText(
                  props: props,
                  propertyName: 'rating',
                  builder: (context, rating) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: rating.isEmpty ? Colors.grey : Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          rating.isEmpty ? '...' : rating,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamingText(
              props: props,
              propertyName: 'description',
              initialValue: 'Typing description...',
              builder: (context, desc) => Text(
                desc,
                style: TextStyle(
                  fontSize: 13,
                  // ignore: deprecated_member_use
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
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
