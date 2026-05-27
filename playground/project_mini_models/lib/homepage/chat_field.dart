import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_mini_models/homepage/homepage_provider.dart';

class ChatField extends StatefulWidget {
  const ChatField({super.key});

  @override
  State<ChatField> createState() => _ChatFieldState();
}

class _ChatFieldState extends State<ChatField> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _controller.clear();
      context.read<HomepageProvider>().sendMessage(text);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomepageProvider>();
    final isRaw = provider.showRawView;
    final isPriming = provider.primingEnabled;

    return Container(
      decoration: ShapeDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      hintText: 'Ask anything...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                IconButton.filled(
                  onPressed: _submit,
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
            ),
            const Divider(height: 8, thickness: 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: provider.toggleRawView,
                  icon: Icon(isRaw ? Icons.visibility : Icons.code, size: 16),
                  label: Text(
                    isRaw ? "Show UI" : "Show Raw",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
                TextButton.icon(
                  onPressed: provider.toggleModelProvider,
                  icon: Icon(
                    provider.useOllama ? Icons.dns : Icons.cloud,
                    size: 16,
                  ),
                  label: Text(
                    provider.useOllama ? "Ollama" : "Groq",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
                TextButton.icon(
                  onPressed: provider.togglePriming,
                  icon: Icon(
                    isPriming
                        ? Icons.auto_awesome
                        : Icons.auto_awesome_outlined,
                    size: 16,
                  ),
                  label: Text(
                    "Priming",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPriming
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: isPriming
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
                TextButton.icon(
                  onPressed: provider.clearHistory,
                  icon: const Icon(Icons.delete_sweep, size: 16),
                  label: const Text(
                    "Clear Chat",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.error.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
