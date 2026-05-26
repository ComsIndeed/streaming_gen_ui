import 'package:flutter/material.dart';

class ChatField extends StatelessWidget {
  const ChatField({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(32),
        ),
      ),
      constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            IconButton(onPressed: () {}, icon: Icon(Icons.menu)),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Ask anything...',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton.filled(onPressed: () {}, icon: Icon(Icons.arrow_upward)),
          ],
        ),
      ),
    );
  }
}
