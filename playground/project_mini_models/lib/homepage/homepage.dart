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

    // Keep all messages in history to render system prompt beautifully at the top
    final chatMessages = provider.history;
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
                        padding: const EdgeInsets.only(
                          bottom: 128,
                          left: 16,
                          right: 16,
                          top: 16,
                        ),
                        itemCount: totalItems,
                        itemBuilder: (context, index) {
                          if (index < chatMessages.length) {
                            final msg = chatMessages[index];
                            if (msg.role == Role.system) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                                padding: const EdgeInsets.all(16),
                                decoration: ShapeDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withOpacity(0.12),
                                  shape: RoundedSuperellipseBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.25),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.settings_suggest,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'SYSTEM PROMPT',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.2,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            msg.content,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                              fontStyle: FontStyle.italic,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else if (msg.role == Role.user) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 64.0),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondaryContainer,
                                    shape: RoundedSuperellipseBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    msg.content,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.only(right: 64.0),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    shape: RoundedSuperellipseBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (msg.thinking != null &&
                                          msg.thinking!.isNotEmpty) ...[
                                        SelectableText(
                                          msg.thinking!.trimLeft(),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withOpacity(0.35),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          child: Divider(height: 1),
                                        ),
                                      ],
                                      SelectableText(
                                        msg.content.trimLeft(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          } else {
                            // Active stream bubble
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: ShapeDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  shape: RoundedSuperellipseBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  provider.activeStreamText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
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
