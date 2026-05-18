import 'package:flutter/widgets.dart';

class CoreColumn extends StatelessWidget {
  final Map<String, dynamic> properties;

  const CoreColumn({Key? key, required this.properties}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Extract properties and build Column widget
    return const SizedBox.shrink();
  }
}
