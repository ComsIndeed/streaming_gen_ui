import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_mini_models/homepage/chat_field.dart';
import 'package:project_mini_models/homepage/homepage_provider.dart';
import 'package:project_mini_models/core/chat_core_service/chat_core_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final sizes = MediaQuery.sizeOf(context);
    final provider = context.watch<HomepageProvider>();
    final showPanel = provider.showPanel;

    // Filter out system prompt for the chat bubbles display
    final chatMessages = provider.history.where((m) => m.role != Role.system).toList();
    final activeStreamId = provider.activeStreamId;
    final totalItems = chatMessages.length + (activeStreamId != null ? 1 : 0);

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                SizedBox.expand(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 96, left: 16, right: 16, top: 16),
                        itemCount: totalItems,
                        itemBuilder: (context, index) {
                          if (index < chatMessages.length) {
                            final msg = chatMessages[index];
                            if (msg.role == Role.user) {
                              return Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: ShapeDecoration(
                                    color: Theme.of(context).colorScheme.secondaryContainer,
                                    shape: RoundedSuperellipseBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    msg.content,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              final viewId = 'msg_$index';
                              provider.restoreMessageView(viewId, msg.content);
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: ShapeDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    shape: RoundedSuperellipseBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: provider.genUi.view(viewId),
                                ),
                              );
                            }
                          } else {
                            // Active stream bubble
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: ShapeDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: provider.genUi.view(activeStreamId!),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: const ChatField(),
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
              child: const Column(),
            ),
          ),
        ],
      ),
    );
  }
}
