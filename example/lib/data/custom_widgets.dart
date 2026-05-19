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
  late final Stream<String> _nameStream;
  late final Stream<String> _roleStream;
  late final Stream<String> _colorStream;

  @override
  void initState() {
    super.initState();
    _nameStream = widget.props.asMap.getStringProperty('name').stream;
    _roleStream = widget.props.asMap.getStringProperty('role').stream;
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
                        AccumulatingStringStreamBuilder(
                          stream: _nameStream,
                          builder: (context, name) {
                            return Text(
                              name.isEmpty ? 'Typing name...' : name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        AccumulatingStringStreamBuilder(
                          stream: _roleStream,
                          builder: (context, role) {
                            return Text(
                              role.isEmpty ? 'Typing role...' : role,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            );
                          },
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
class CustomHotelCard extends StatefulWidget {
  final PropertyStream props;

  const CustomHotelCard({super.key, required this.props});

  @override
  State<CustomHotelCard> createState() => _CustomHotelCardState();
}

class _CustomHotelCardState extends State<CustomHotelCard> {
  late final Stream<String> _titleStream;
  late final Stream<String> _descStream;
  late final Stream<String> _ratingStream;

  @override
  void initState() {
    super.initState();
    _titleStream = widget.props.asMap.getStringProperty('title').stream;
    _descStream = widget.props.asMap.getStringProperty('description').stream;
    _ratingStream = widget.props.asMap.getStringProperty('rating').stream;
  }

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
                  child: AccumulatingStringStreamBuilder(
                    stream: _titleStream,
                    builder: (context, title) {
                      return Text(
                        title.isEmpty ? 'Typing hotel name...' : title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                AccumulatingStringStreamBuilder(
                  stream: _ratingStream,
                  builder: (context, rating) {
                    return Container(
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
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            AccumulatingStringStreamBuilder(
              stream: _descStream,
              builder: (context, desc) {
                return Text(
                  desc.isEmpty ? 'Typing description...' : desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Registry Map
final Map<String, Widget Function(BuildContext context, PropertyStream props)> customRegistry = {
  'custom:user_profile': (context, props) => CustomUserProfileCard(props: props),
  'custom:hotel_card': (context, props) => CustomHotelCard(props: props),
};
