import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';

// --- Custom User Profile Card ---
class CustomUserProfileCard extends StatefulWidget {
  final PropertyStream props;

  const CustomUserProfileCard({super.key, required this.props});

  @override
  State<CustomUserProfileCard> createState() => _CustomUserProfileCardState();
}

class _CustomUserProfileCardState extends State<CustomUserProfileCard> {
  late final Future<String> _nameFuture;
  late final Future<String> _roleFuture;
  late final Future<String> _colorFuture;

  @override
  void initState() {
    super.initState();
    _nameFuture = widget.props.asMap.getStringProperty('name').future;
    _roleFuture = widget.props.asMap.getStringProperty('role').future;
    _colorFuture = widget.props.asMap.getStringProperty('themeColor').future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: Future.wait([_nameFuture, _roleFuture, _colorFuture]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final name = snapshot.data![0];
        final role = snapshot.data![1];
        final hexColor = snapshot.data![2];

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
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          role,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
class CustomHotelCard extends StatefulWidget {
  final PropertyStream props;

  const CustomHotelCard({super.key, required this.props});

  @override
  State<CustomHotelCard> createState() => _CustomHotelCardState();
}

class _CustomHotelCardState extends State<CustomHotelCard> {
  late final Future<String> _titleFuture;
  late final Future<String> _descFuture;
  late final Future<String> _ratingFuture;

  @override
  void initState() {
    super.initState();
    _titleFuture = widget.props.asMap.getStringProperty('title').future;
    _descFuture = widget.props.asMap.getStringProperty('description').future;
    _ratingFuture = widget.props.asMap.getStringProperty('rating').future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: Future.wait([_titleFuture, _descFuture, _ratingFuture]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final title = snapshot.data![0];
        final desc = snapshot.data![1];
        final rating = snapshot.data![2];

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
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Custom Registry Map
final Map<String, Widget Function(BuildContext context, PropertyStream props)> customRegistry = {
  'custom:user_profile': (context, props) => CustomUserProfileCard(props: props),
  'custom:hotel_card': (context, props) => CustomHotelCard(props: props),
};
