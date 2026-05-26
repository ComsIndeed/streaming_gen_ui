import 'package:flutter/material.dart';
import 'package:project_mini_models/homepage/chat_field.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool showPanel = false;

  @override
  Widget build(BuildContext context) {
    final sizes = MediaQuery.sizeOf(context);
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                Align(
                  alignment: .bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ChatField(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AnimatedContainer(
              duration: Durations.short4,
              width: showPanel ? sizes.width * 0.4 : 0,
              child: Column(),
            ),
          ),
        ],
      ),
    );
  }
}
