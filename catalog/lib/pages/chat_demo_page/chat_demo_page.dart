import 'package:flutter/material.dart';
import 'package:streaming_gen_ui_widget_catalog/widgets/graph_background.dart';

class ChatDemoPage extends StatefulWidget {
  const ChatDemoPage({super.key});

  @override
  State<ChatDemoPage> createState() => _ChatDemoPageState();
}

class _ChatDemoPageState extends State<ChatDemoPage> {
  bool isChatExpanded = false;
  bool isCanvasExpanded = false;

  @override
  Widget build(BuildContext context) {
    final sizes = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: GraphBackground(
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: sizes.height * 1.5),
                padding: EdgeInsets.all(16),
                child: Column(children: [
        
                  ],
                ),
              ),
            ),
          ),
          AnimatedAlign(
            duration: Durations.short4,
            curve: Curves.easeInOut,
            alignment: .bottomCenter,
            child: AnimatedPadding(
              duration: Durations.short4,
              padding: EdgeInsets.all(isChatExpanded ? 16 : 32.0),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                width: 512 + (isChatExpanded ? 64 : 0),
                height: isChatExpanded ? 256 : 64,
                decoration: ShapeDecoration(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  color: theme.colorScheme.secondaryContainer,
                ),
                duration: Durations.medium2,
                curve: Curves.easeOutBack,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: .center,
                    children: [
                      AnimatedAlign(
                        alignment: isChatExpanded ? .topLeft : .centerLeft,
                        duration: Durations.short1,
                        child: IconButton(
                          onPressed: () =>
                              setState(() => isChatExpanded = !isChatExpanded),
                          icon: AnimatedSwitcher(
                            duration: Durations.short4,
                            child: isChatExpanded
                                ? Icon(Icons.close)
                                : Icon(Icons.add),
                          ),
                        ),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: Durations.short4,
                          child: isChatExpanded
                              ? SizedBox.expand()
                              : TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Talk to AI',
                                    border: InputBorder.none,
                                    suffixIcon: IconButton.filled(
                                      onPressed: () {},
                                      icon: Icon(
                                        Icons.arrow_upward,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
