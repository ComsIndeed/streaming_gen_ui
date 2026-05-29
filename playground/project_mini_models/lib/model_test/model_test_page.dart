import 'dart:ui' as ui;
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
                  label: 'Simultaneous Runs',
                  currentPage: _currentPage,
                  onTap: () => _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
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
                _SimultaneousRunsPage(
                  testProvider: testProvider,
                  homepageProvider: homepageProvider,
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
                  maxLines: 3,
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

// ─────────────────────────────────────────────────────────────────────────────
// SIMULTANEOUS RUNS BENCHMARK PAGE
// ─────────────────────────────────────────────────────────────────────────────

class _SimultaneousRunsPage extends StatefulWidget {
  final ModelTestProvider testProvider;
  final HomepageProvider homepageProvider;

  const _SimultaneousRunsPage({
    required this.testProvider,
    required this.homepageProvider,
  });

  @override
  State<_SimultaneousRunsPage> createState() => _SimultaneousRunsPageState();
}

class _SimultaneousRunsPageState extends State<_SimultaneousRunsPage> {
  int _concurrencyCount = 3;

  @override
  Widget build(BuildContext context) {
    final runs = widget.testProvider.simultaneousRuns;
    final isRunning = widget.testProvider.isSimultaneousRunning;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Controls Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.layers, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Concurrent Parallel Streams',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Spawns multiple simultaneous streams concurrently against the same model.\n'
                  'Validates that the streaming gen-ui harness can handle parallel executions.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Parallel Count:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _concurrencyCount.toDouble(),
                        min: 2,
                        max: 5,
                        divisions: 3,
                        label: '$_concurrencyCount streams',
                        onChanged: isRunning
                            ? null
                            : (val) {
                                setState(() => _concurrencyCount = val.toInt());
                                widget.testProvider.resetSimultaneous(_concurrencyCount);
                              },
                      ),
                    ),
                    Text(
                      '$_concurrencyCount',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isRunning
                            ? null
                            : () => widget.testProvider.runParallelBenchmark(
                                  modelConfig: widget.homepageProvider.useOllama
                                      ? HomepageProvider.ollamaConfig
                                      : HomepageProvider.groqConfig,
                                  concurrencyCount: _concurrencyCount,
                                ),
                        icon: Icon(
                          isRunning ? Icons.hourglass_top : Icons.bolt,
                        ),
                        label: Text(isRunning ? 'Benchmarking...' : 'Trigger Streams'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: isRunning
                          ? () => widget.testProvider.resetSimultaneous(_concurrencyCount)
                          : null,
                      child: const Text('Cancel / Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // PERFORMANCE METRICS GLOWING CHARTS
        _PerformanceChartSection(testProvider: widget.testProvider),
        const SizedBox(height: 16),

        // Live stream progression indicators
        Text(
          'Active Parallel Runners',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...runs.map((run) => _SimultaneousRunCard(run: run)),
      ],
    );
  }
}

class _SimultaneousRunCard extends StatelessWidget {
  final SimultaneousRun run;

  const _SimultaneousRunCard({required this.run});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStreaming = run.status == 'Streaming';
    final isCompleted = run.status == 'Completed';
    final isFailed = run.status == 'Failed';

    final ttftStr = run.ttft != null ? '${run.ttft!.inMilliseconds}ms' : '--';
    final totalStr = run.totalDuration != null ? '${(run.totalDuration!.inMilliseconds / 1000.0).toStringAsFixed(2)}s' : '--';

    Color statusColor = Colors.grey;
    if (run.status == 'Connecting') statusColor = Colors.amber;
    if (isStreaming) statusColor = theme.colorScheme.primary;
    if (isCompleted) statusColor = Colors.green;
    if (isFailed) statusColor = theme.colorScheme.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title & Header info
            Row(
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Text(
                    '${run.id}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    run.prompt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    run.status,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Live progress indicator
            if (isStreaming || run.status == 'Connecting')
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: LinearProgressIndicator(
                  value: run.progress,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  minHeight: 3,
                ),
              ),

            // Captured streaming tokens
            if (run.response.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.5),
                ),
                child: Text(
                  run.response,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
              ),

            // Error display if failed
            if (isFailed && run.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  run.error!,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                ),
              ),

            // Performance chips row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RunDetailChip(label: 'TTFT', value: ttftStr, icon: Icons.timer_outlined),
                _RunDetailChip(label: 'Total', value: totalStr, icon: Icons.hourglass_empty),
                _RunDetailChip(
                  label: 'Speed',
                  value: '${run.tokensPerSecond.toStringAsFixed(1)} t/s',
                  icon: Icons.speed,
                  color: isStreaming ? theme.colorScheme.primary : null,
                ),
                _RunDetailChip(label: 'Tokens', value: '${run.tokenCount}', icon: Icons.text_snippet_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RunDetailChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _RunDetailChip({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetColor = color ?? theme.colorScheme.onSurface.withOpacity(0.5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: targetColor),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: targetColor,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM PERFORMANCE LIVE CHART RENDERING
// ─────────────────────────────────────────────────────────────────────────────

class _PerformanceChartSection extends StatelessWidget {
  final ModelTestProvider testProvider;

  const _PerformanceChartSection({required this.testProvider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Analytics Dashboard',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              if (testProvider.isSimultaneousRunning)
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.cyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Live Metrics',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Charts side-by-side or stacked depending on size
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              final chartWidth = isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

              final children = [
                // 1. Throughput Chart (Speed t/s)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flash_on, color: Colors.cyan, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Combined Speed (Throughput)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: chartWidth,
                      height: 110,
                      child: _LiveLineChart(
                        data: testProvider.throughputHistory,
                        maxVal: 60.0,
                        unit: 't/s',
                        glowColor: Colors.cyan,
                      ),
                    ),
                  ],
                ),
                if (!isWide) const SizedBox(height: 16),
                // 2. Resource Overhead Chart (Simulated System Resources)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.memory, color: Colors.purpleAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Estimated Resource Utilization',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.purpleAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: chartWidth,
                      height: 110,
                      child: _LiveLineChart(
                        data: testProvider.resourceHistory,
                        maxVal: 100.0,
                        unit: '%',
                        glowColor: Colors.purpleAccent,
                      ),
                    ),
                  ],
                ),
              ];

              return isWide
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: children,
                    )
                  : Column(children: children);
            },
          ),
        ],
      ),
    );
  }
}

class _LiveLineChart extends StatelessWidget {
  final List<double> data;
  final double maxVal;
  final String unit;
  final Color glowColor;

  const _LiveLineChart({
    required this.data,
    required this.maxVal,
    required this.unit,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentVal = data.isNotEmpty ? data.last : 0.0;

    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: _LineChartPainter(
            data: data,
            maxVal: maxVal,
            lineColor: glowColor,
            gridColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
            textColor: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        // Live counter bubble in corner
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: glowColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: glowColor.withOpacity(0.3), width: 0.5),
            ),
            child: Text(
              '${currentVal.toStringAsFixed(1)} $unit',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: glowColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final double maxVal;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  _LineChartPainter({
    required this.data,
    required this.maxVal,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final width = size.width;
    final height = size.height;

    // Draw horizontal grid lines (3 divisions)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 3; i++) {
      final y = height - (i * height / 3);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Map data points
    final count = data.length;
    final double stepX = width / (count - 1);
    final List<Offset> points = [];

    for (int i = 0; i < count; i++) {
      final val = data[i];
      // Clamp values and map linearly
      final clamped = val.clamp(0.0, maxVal);
      final x = i * stepX;
      final y = height - (clamped * height / maxVal);
      points.add(Offset(x, y));
    }

    // Build Cubic Bezier Curve path for smooth premium analytics look
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlPointX1 = p1.dx + (p2.dx - p1.dx) / 2;
      final controlPointY1 = p1.dy;
      final controlPointX2 = p1.dx + (p2.dx - p1.dx) / 2;
      final controlPointY2 = p2.dy;

      path.cubicTo(
        controlPointX1,
        controlPointY1,
        controlPointX2,
        controlPointY2,
        p2.dx,
        p2.dy,
      );
    }

    // Draw gradient fill under the line
    final fillPath = Path.from(path)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, height),
        [
          lineColor.withOpacity(0.25),
          lineColor.withOpacity(0.00),
        ],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw secondary neon glow path (thicker stroke, lower opacity)
    final glowPaint = Paint()
      ..color = lineColor.withOpacity(0.3)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, glowPaint);

    // Draw core crisp line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw active glowing dot at the end
    final endPoint = points.last;
    final dotOuterPaint = Paint()
      ..color = lineColor.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endPoint, 6.0, dotOuterPaint);

    final dotInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endPoint, 2.5, dotInnerPaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
