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
  bool _primersExpanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomepageProvider>();
    final theme = Theme.of(context);
    final chatMessages = provider.history;
    final activeStreamId = provider.activeStreamId;

    // Partition by flag, not index — system prompt lives in right panel.
    final primerMessages =
        chatMessages.where((m) => m.isPrimer).toList();
    final nonPrimerMessages =
        chatMessages.where((m) => m.role != Role.system && !m.isPrimer).toList();
    final hasRealMessages =
        nonPrimerMessages.isNotEmpty || activeStreamId != null;

    // Main list slots (system prompt moved to right panel)
    final int primerSlot = primerMessages.isNotEmpty ? 1 : 0;
    final int dividerSlot = hasRealMessages ? 1 : 0;
    final int realSlot = nonPrimerMessages.length;
    final int streamSlot = activeStreamId != null ? 1 : 0;
    final int totalItems = primerSlot + dividerSlot + realSlot + streamSlot;

    // ---- Primer bubble renderer (system prompt excluded — lives in panel) ----
    Widget buildPrimerBubble(ChatMessage msg) {
      const double opac = 0.35;
      if (msg.role == Role.user) {
        return Opacity(
          opacity: opac,
          child: Padding(
            padding: const EdgeInsets.only(left: 48.0),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: ShapeDecoration(
                color: theme.colorScheme.secondaryContainer,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
        );
      } else {
        return Opacity(
          opacity: opac,
          child: Padding(
            padding: const EdgeInsets.only(right: 48.0),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: ShapeDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (msg.thinking != null && msg.thinking!.isNotEmpty) ...[
                    SelectableText(
                      msg.thinking!.trimLeft(),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.35,
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Divider(height: 1),
                    ),
                  ],
                  SelectableText(
                    msg.content.trimLeft(),
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // ---- Right panel: system prompt (40% of screen when expanded) ----
    final double rightPanelWidth =
        provider.showPanel ? MediaQuery.of(context).size.width * 0.40 : 0.0;

    return Stack(
      children: [
        // Main chat area
        SizedBox.expand(
          child: Row(
            children: [
              // Chat list
              Expanded(
                child: Stack(
                  children: [
                    Center(
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
                            int cursor = 0;

                            // ---- 1. Collapsible primers ----
                            if (primerSlot > 0) {
                              if (index == cursor) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: ShapeDecoration(
                                    color: theme.colorScheme.surfaceContainerLow,
                                    shape: RoundedSuperellipseBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: ExpansionTile(
                                      initiallyExpanded: _primersExpanded,
                                      onExpansionChanged: (v) =>
                                          setState(() => _primersExpanded = v),
                                      tilePadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      childrenPadding: const EdgeInsets.only(
                                        left: 8,
                                        right: 8,
                                        bottom: 8,
                                      ),
                                      leading: Icon(
                                        _primersExpanded
                                            ? Icons.auto_awesome
                                            : Icons.auto_awesome_outlined,
                                        size: 18,
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.5),
                                      ),
                                      title: Text(
                                        'Primers (${primerMessages.length} injected messages)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurfaceVariant
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      children: primerMessages
                                          .map(buildPrimerBubble)
                                          .toList(),
                                    ),
                                  ),
                                );
                              }
                              cursor++;
                            }

                            // ---- 2. Divider ----
                            if (dividerSlot > 0) {
                              if (index == cursor) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      const Expanded(child: Divider()),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          'Conversation starts here',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.8,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withOpacity(0.4),
                                          ),
                                        ),
                                      ),
                                      const Expanded(child: Divider()),
                                    ],
                                  ),
                                );
                              }
                              cursor++;
                            }

                            // ---- 3. Real messages ----
                            if (index < cursor + realSlot) {
                              final msg = nonPrimerMessages[index - cursor];
                              if (msg.role == Role.user) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 64.0),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: ShapeDecoration(
                                      color: theme.colorScheme.secondaryContainer,
                                      shape: RoundedSuperellipseBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      msg.content,
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 64.0),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: ShapeDecoration(
                                      color:
                                          theme.colorScheme.surfaceContainerHighest,
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
                                              color: theme
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
                                            color:
                                                theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            }
                            cursor += realSlot;

                            // ---- 4. Active stream ----
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: ShapeDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  shape: RoundedSuperellipseBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  provider.activeStreamText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Chat field — part of left panel
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

              // ---- Right panel (system prompt) ----
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: rightPanelWidth,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  color: theme.colorScheme.surfaceContainerLow,
                ),
                child: rightPanelWidth > 0
                    ? _SystemPromptPanel(
                        systemPrompt: MaterialPrompts.systemPrompt,
                      )
                    : null,
              ),
            ],
          ),
        ),

        // ---- Top bar buttons ----
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
        Positioned(
          top: 4,
          right: 4 + rightPanelWidth,
          child: IconButton(
            icon: Icon(
              provider.showPanel
                  ? Icons.info_rounded
                  : Icons.info_outline_rounded,
            ),
            tooltip: 'Toggle system prompt panel',
            onPressed: () => provider.togglePanel(),
          ),
        ),
      ],
    );
  }
}

/// Right-side panel displaying the system prompt.
class _SystemPromptPanel extends StatelessWidget {
  const _SystemPromptPanel({required this.systemPrompt});

  final String systemPrompt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 56, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'System Prompt',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Styled system message box
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: ShapeDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.12),
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings_suggest,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SYSTEM PROMPT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      systemPrompt,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
