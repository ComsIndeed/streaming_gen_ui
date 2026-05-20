import 'package:flutter/material.dart';
import 'package:streaming_gen_ui_widget_catalog/widgets/graph_background.dart';

class ChatDemoPage extends StatelessWidget {
  const ChatDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sizes = MediaQuery.sizeOf(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: GraphBackground(
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: sizes.height * 1.5),
            padding: EdgeInsets.all(16),
            child: Column(children: []),
          ),
        ),
      ),
    );
  }
}
