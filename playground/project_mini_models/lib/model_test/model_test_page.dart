import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_mini_models/homepage/homepage_provider.dart';
import 'package:project_mini_models/model_test/model_test_provider.dart';

class ModelTestPage extends StatefulWidget {
  const ModelTestPage({super.key});

  @override
  State<ModelTestPage> createState() => _ModelTestPageState();
}

class _ModelTestPageState extends State<ModelTestPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final testProvider = context.watch<ModelTestProvider>();
    final homepageProvider = context.watch<HomepageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Tests'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Column(
        children: [
          // Page indicator dots
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PageDot(
                  index: 0,
                  label: 'TTFT Chain',
                  currentPage: _currentPage,
                  onTap: () => _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
                const SizedBox(width: 8),
                _PageDot(
                  index: 1,
                  label: 'More...',
                  currentPage: _currentPage,
                  onTap: null,
                ),
              ],
            ),
          ),
          // PageView
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _ChainTTFTPage(
                  testProvider: testProvider,
                  homepageProvider: homepageProvider,
                ),
                // Placeholder for future tests
                const Center(
                  child: Text(
                    'More tests coming soon...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  final int index;
  final String label;
  final int currentPage;
  final VoidCallback? onTap;

  const _PageDot({
    required this.index,
    required this.label,
    required this.currentPage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentPage;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

/// The first test page that runs a chain of messages and measures TTFT.
class _ChainTTFTPage extends StatelessWidget {
  final ModelTestProvider testProvider;
  final HomepageProvider homepageProvider;

  const _ChainTTFTPage({
    required this.testProvider,
    required this.homepageProvider,
  });

  @override
  Widget build(BuildContext context) {
    final results = testProvider.results;
    final isRunning = testProvider.isRunning;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.speed,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TTFT Chain Test',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Sends 5 generic messages in sequence as fresh conversations.\n'
                  'Measures Time-to-First-Token (TTFT) for each.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isRunning
                            ? null
                            : () => testProvider.runTest(
                                // Always use the current Ollama model for testing
                                modelConfig: HomepageProvider.ollamaConfig,
                                systemPrompt:
                                    'You are a helpful assistant that answers concisely.',
                              ),
                        icon: Icon(
                          isRunning ? Icons.hourglass_top : Icons.play_arrow,
                        ),
                        label: Text(isRunning ? 'Running...' : 'Start Test'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: isRunning ? testProvider.reset : null,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Result list
        ...results.asMap().entries.map((entry) {
          final index = entry.key;
          final result = entry.value;
          final isCurrent = isRunning && index == testProvider.currentTestIndex;
          return _ResultCard(index: index, result: result, isActive: isCurrent);
        }),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final int index;
  final TestResult result;
  final bool isActive;

  const _ResultCard({
    required this.index,
    required this.result,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final ttftMs = result.ttft != null
        ? '${result.ttft!.inMilliseconds} ms'
        : '--';
    final totalMs = result.totalTime != null
        ? '${result.totalTime!.inMilliseconds} ms'
        : '--';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isActive
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : result.completed
          ? null
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: result.running
                      ? Theme.of(context).colorScheme.primary
                      : result.completed
                      ? Colors.green.withOpacity(0.8)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: result.running
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        )
                      : result.completed
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.message,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (result.error != null)
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 18,
                  ),
              ],
            ),
            if (result.response != null && result.response!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  result.response!,
                  maxLines: isActive ? 3 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(isActive ? 0.6 : 0.5),
                  ),
                ),
              ),
            if (result.ttft != null || result.totalTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    _StatChip(
                      label: 'TTFT',
                      value: ttftMs,
                      color: Theme.of(context).colorScheme.primary,
                      isActive: isActive,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Total',
                      value: totalMs,
                      color: Colors.grey,
                      isActive: false,
                    ),
                  ],
                ),
              ),
            if (result.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  result.error!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isActive;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(isActive ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
