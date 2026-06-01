import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:edit_implementation_test/cubit/chat_demo_cubit.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatDemoCubit(),
      child: const _HomepageContent(),
    );
  }
}

class _HomepageContent extends StatefulWidget {
  const _HomepageContent();

  @override
  State<_HomepageContent> createState() => _HomepageContentState();
}

class _HomepageContentState extends State<_HomepageContent> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatDemoCubit>();

    return Scaffold(
      body: Row(
        children: [
          // Left Panel: Chat (Fixed 720px width)
          SizedBox(
            width: 720,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Chat Header
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Streaming Gen UI",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                "DeepSeek Dev Playground",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                                label: const Text("Clear"),
                                onPressed: () => cubit.clearChat(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  // Error Banner
                  BlocBuilder<ChatDemoCubit, ChatDemoState>(
                    builder: (context, state) {
                      if (state.errorMessage == null) return const SizedBox.shrink();
                      return Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => cubit.clearError(),
                            )
                          ],
                        ),
                      );
                    },
                  ),

                  // Chat Message List
                  Expanded(
                    child: BlocConsumer<ChatDemoCubit, ChatDemoState>(
                      listener: (context, state) {
                        _scrollToBottom();
                      },
                      builder: (context, state) {
                        if (state.messages.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "No messages yet",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Try asking weather check or a custom component request like:",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      _controller.text = "Check the weather in Paris. Is it warm?";
                                    },
                                    child: const Text("Preset: Weather check"),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final message = state.messages[index];
                            final isUser = message.isUser;

                            return Align(
                              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(12),
                                constraints: const BoxConstraints(maxWidth: 580),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? Theme.of(context).colorScheme.primaryContainer
                                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isUser ? "You" : "AI Agent",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isUser
                                            ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                                            : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (isUser)
                                      Text(
                                        message.text,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        ),
                                      )
                                    else
                                      ListenableBuilder(
                                        listenable: cubit.generativeUi,
                                        builder: (context, _) {
                                          return cubit.generativeUi.view(
                                            message.id,
                                            textBlockBuilder: (context, text) => GptMarkdown(text),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Bottom Input Field Console
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: BlocBuilder<ChatDemoCubit, ChatDemoState>(
                        builder: (context, state) {
                          return Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    hintText: state.isThinking ? "Thinking..." : "Type your prompt...",
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  enabled: !state.isThinking,
                                  onSubmitted: (val) {
                                    if (!state.isThinking && val.trim().isNotEmpty) {
                                      cubit.sendMessage(val.trim());
                                      _controller.clear();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                icon: state.isThinking
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.send),
                                onPressed: state.isThinking
                                    ? () => cubit.stopResponse()
                                    : () {
                                        final text = _controller.text.trim();
                                        if (text.isNotEmpty) {
                                          cubit.sendMessage(text);
                                          _controller.clear();
                                        }
                                      },
                              )
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Panel: Generative UI Canvas Preview (Always Expanded)
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.dashboard_customize_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Generative UI Canvas (canvas-ui)",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 800),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).dividerColor),
                            borderRadius: BorderRadius.circular(16),
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          padding: const EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: ListenableBuilder(
                              listenable: cubit.generativeUi,
                              builder: (context, _) {
                                return cubit.generativeUi.view(
                                  'canvas-ui',
                                  textBlockBuilder: (context, text) => GptMarkdown(text),
                                );
                              },
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
        ],
      ),
    );
  }
}
