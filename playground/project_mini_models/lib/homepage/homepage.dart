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
    final provider = context.watch<HomepageProvider>();

    // Keep all messages in history to render system prompt beautifully at the top
    final chatMessages = provider.history;
    final activeStreamId = provider.activeStreamId;
    final bool hasPrimers = chatMessages.any((m) => m.isPrimer);
    final dividerIndex = hasPrimers ? chatMessages.length : -1;
    final totalItems =
        chatMessages.length +
        (hasPrimers ? 1 : 0) +
        (activeStreamId != null ? 1 : 0);

    return Stack(
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
                  // ---- divider after primers ----
                  if (hasPrimers && index == dividerIndex) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Conversation starts here',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                    );
                  }

                  // ---- active stream bubble ----
                  if (index >= chatMessages.length + (hasPrimers ? 1 : 0)) {
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

                  // ---- normal message ----
                  final msg = chatMessages[index];
                  final double opacity = msg.isPrimer ? 0.35 : 1.0;

                  if (msg.role == Role.system) {
                    return Opacity(
                      opacity: opacity,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        padding: const EdgeInsets.all(16),
                        decoration: ShapeDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withOpacity(0.12),
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
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                      ),
                    );
                  } else if (msg.role == Role.user) {
                    return Opacity(
                      opacity: opacity,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 64.0),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
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
                      ),
                    );
                  } else {
                    return Opacity(
                      opacity: opacity,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 64.0),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                  padding: EdgeInsets.symmetric(vertical: 6),
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
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ),
        // Drawer open button — top-left
        Positioned(
          top: 4,
          left: 4,
          child: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
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
    );
  }
}
