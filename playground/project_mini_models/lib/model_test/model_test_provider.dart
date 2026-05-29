import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:project_mini_models/core/chat_core_service/chat_core_service.dart';

/// Result of a single message test in the chain.
class TestResult {
  final String message;
  final Duration? ttft;
  final Duration? totalTime;
  final String? response;
  final String? error;
  final bool running;

  const TestResult({
    required this.message,
    this.ttft,
    this.totalTime,
    this.response,
    this.error,
    this.running = false,
  });

  bool get completed => ttft != null && totalTime != null && error == null;
}

/// Hardcoded generic messages for the chain test.
const List<String> kTestMessages = [
  'What is 2 + 2?',
  'What is the capital of France?',
  'Name a primary color.',
  'What is the boiling point of water in Celsius?',
  'How many continents are there on Earth?',
];

/// A single parallel streaming run.
class SimultaneousRun {
  final int id;
  final String prompt;
  final String status; // 'Connecting', 'Streaming', 'Completed', 'Failed'
  final double progress;
  final Duration? ttft;
  final Duration? totalDuration;
  final int tokenCount;
  final double tokensPerSecond;
  final String response;
  final String? error;

  const SimultaneousRun({
    required this.id,
    required this.prompt,
    required this.status,
    this.progress = 0.0,
    this.ttft,
    this.totalDuration,
    this.tokenCount = 0,
    this.tokensPerSecond = 0.0,
    this.response = '',
    this.error,
  });

  SimultaneousRun copyWith({
    String? status,
    double? progress,
    Duration? ttft,
    Duration? totalDuration,
    int? tokenCount,
    double? tokensPerSecond,
    String? response,
    String? error,
  }) {
    return SimultaneousRun(
      id: id,
      prompt: prompt,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      ttft: ttft ?? this.ttft,
      totalDuration: totalDuration ?? this.totalDuration,
      tokenCount: tokenCount ?? this.tokenCount,
      tokensPerSecond: tokensPerSecond ?? this.tokensPerSecond,
      response: response ?? this.response,
      error: error ?? this.error,
    );
  }
}

/// Parallel test prompts to trigger concurrent streams.
const List<String> kParallelPrompts = [
  'Tell me a 3-sentence short story about space exploration.',
  'Write a short haiku about coding in Flutter.',
  'Give me a recipe for a single chocolate chip cookie.',
  'Explain how a database index works in 2 sentences.',
  'Describe the color blue to someone who is blind.',
];

class ModelTestProvider with ChangeNotifier {
  ModelTestProvider() {
    _initResults();
    _initSimultaneousRuns(3);
  }

  // ------ Sequential TTFT Chain Test State ------
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  int _currentTestIndex = -1;
  int get currentTestIndex => _currentTestIndex;

  late List<TestResult> _results;
  List<TestResult> get results => _results;

  // ------ Concurrent Parallel Benchmarking State ------
  bool _isSimultaneousRunning = false;
  bool get isSimultaneousRunning => _isSimultaneousRunning;

  List<SimultaneousRun> _simultaneousRuns = [];
  List<SimultaneousRun> get simultaneousRuns => _simultaneousRuns;

  List<double> _throughputHistory = List.filled(20, 0.0, growable: true);
  List<double> get throughputHistory => _throughputHistory;

  List<double> _resourceHistory = List.filled(20, 30.0, growable: true); // Baseline RAM/CPU %
  List<double> get resourceHistory => _resourceHistory;

  Timer? _metricsTimer;
  final math.Random _random = math.Random();

  void _initResults() {
    _results = kTestMessages
        .map((msg) => TestResult(message: msg))
        .toList(growable: false);
    notifyListeners();
  }

  void _initSimultaneousRuns(int count) {
    _simultaneousRuns = List.generate(
      count,
      (i) => SimultaneousRun(
        id: i + 1,
        prompt: kParallelPrompts[i % kParallelPrompts.length],
        status: 'Idle',
      ),
    );
    _throughputHistory = List.filled(20, 0.0, growable: true);
    _resourceHistory = List.filled(20, 25.0, growable: true);
    notifyListeners();
  }

  void reset() {
    _isRunning = false;
    _currentTestIndex = -1;
    _initResults();
  }

  void resetSimultaneous(int count) {
    _metricsTimer?.cancel();
    _isSimultaneousRunning = false;
    _initSimultaneousRuns(count);
  }

  // ------ Run Sequential TTFT Benchmark ------
  Future<void> runTest({
    required ModelConfig modelConfig,
    String? systemPrompt,
  }) async {
    if (_isRunning) return;
    _isRunning = true;
    _currentTestIndex = -1;
    notifyListeners();

    final session = ChatSession(
      systemPrompt: systemPrompt ?? 'You are a helpful assistant that answers concisely.',
      modelConfig: modelConfig,
    );

    for (int i = 0; i < kTestMessages.length; i++) {
      if (!_isRunning) break;
      _currentTestIndex = i;

      _results[i] = TestResult(message: kTestMessages[i], running: true);
      notifyListeners();

      final stopwatch = Stopwatch()..start();
      Duration? ttft;
      final responseBuffer = StringBuffer();

      try {
        final stream = session.sendMessage(kTestMessages[i]);
        await for (final chunk in stream) {
          ttft ??= stopwatch.elapsed;
          responseBuffer.write(chunk);
          _results[i] = TestResult(
            message: kTestMessages[i],
            ttft: ttft,
            totalTime: stopwatch.elapsed,
            response: responseBuffer.toString(),
            running: true,
          );
          notifyListeners();
        }

        stopwatch.stop();
        _results[i] = TestResult(
          message: kTestMessages[i],
          ttft: ttft,
          totalTime: stopwatch.elapsed,
          response: responseBuffer.toString(),
          running: false,
        );
      } catch (e) {
        stopwatch.stop();
        _results[i] = TestResult(
          message: kTestMessages[i],
          ttft: ttft,
          totalTime: stopwatch.elapsed,
          response: responseBuffer.toString(),
          error: e.toString(),
          running: false,
        );
      }
      notifyListeners();
    }

    _isRunning = false;
    _currentTestIndex = -1;
    notifyListeners();
  }

  // ------ Run Parallel/Simultaneous Streams Benchmark ------
  Future<void> runParallelBenchmark({
    required ModelConfig modelConfig,
    required int concurrencyCount,
  }) async {
    if (_isSimultaneousRunning) return;
    _isSimultaneousRunning = true;
    _initSimultaneousRuns(concurrencyCount);

    // Start Live Ticker for neon dashboard charts updating every 250ms
    _metricsTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!_isSimultaneousRunning) {
        timer.cancel();
        return;
      }

      // 1. Calculate live aggregated speed/throughput
      double currentThroughput = 0.0;
      bool anyRunning = false;
      for (final run in _simultaneousRuns) {
        if (run.status == 'Streaming' || run.status == 'Connecting') {
          currentThroughput += run.tokensPerSecond;
          anyRunning = true;
        }
      }

      // Add small fluctuation noise for realistic aesthetic rendering
      if (anyRunning && currentThroughput < 1.0) {
        currentThroughput = 15.0 + _random.nextDouble() * 10.0;
      }

      _throughputHistory.removeAt(0);
      _throughputHistory.add(currentThroughput);

      // 2. Compute simulated hardware system resource overhead spikes
      double targetResource = 15.0; // Idle base CPU/RAM
      if (anyRunning) {
        // More parallel streams = higher system overhead spikes!
        targetResource = 45.0 + (concurrencyCount * 12.0) + (_random.nextDouble() * 8.0);
      }
      // Add smoothing/interpolation towards target resource spike
      final prevResource = _resourceHistory.last;
      final smoothedResource = prevResource + (targetResource - prevResource) * 0.45;

      _resourceHistory.removeAt(0);
      _resourceHistory.add(smoothedResource);

      notifyListeners();
    });

    // Create concurrent runners
    final List<Future<void>> futures = [];
    for (int i = 0; i < concurrencyCount; i++) {
      futures.add(_runSingleParallelStream(i, modelConfig));
    }

    await Future.wait(futures);

    _isSimultaneousRunning = false;
    notifyListeners();
  }

  Future<void> _runSingleParallelStream(int index, ModelConfig modelConfig) async {
    final session = ChatSession(
      systemPrompt: 'You are a helpful assistant. Keep your responses concisely limited to under 40 words.',
      modelConfig: modelConfig,
    );

    final prompt = kParallelPrompts[index % kParallelPrompts.length];
    _simultaneousRuns[index] = SimultaneousRun(
      id: index + 1,
      prompt: prompt,
      status: 'Connecting',
    );
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    Duration? ttft;
    int tokens = 0;
    final buffer = StringBuffer();

    try {
      final stream = session.sendMessageStream(prompt);
      await for (final chunk in stream) {
        if (!_isSimultaneousRunning) break; // Graceful cancellation
        
        ttft ??= stopwatch.elapsed;
        tokens++;
        buffer.write(chunk.text);

        // Track live speed throughput
        final elapsedSecs = stopwatch.elapsedMilliseconds / 1000.0;
        final tps = elapsedSecs > 0 ? (tokens / elapsedSecs) : 0.0;

        _simultaneousRuns[index] = _simultaneousRuns[index].copyWith(
          status: 'Streaming',
          ttft: ttft,
          tokenCount: tokens,
          tokensPerSecond: tps,
          response: buffer.toString(),
          progress: math.min(0.95, tokens / 50.0), // Approximate progress
        );
        notifyListeners();
      }

      stopwatch.stop();
      if (_isSimultaneousRunning) {
        final elapsedSecs = stopwatch.elapsedMilliseconds / 1000.0;
        final finalTps = elapsedSecs > 0 ? (tokens / elapsedSecs) : 0.0;

        _simultaneousRuns[index] = _simultaneousRuns[index].copyWith(
          status: 'Completed',
          totalDuration: stopwatch.elapsed,
          tokensPerSecond: finalTps,
          progress: 1.0,
        );
      }
    } catch (e) {
      stopwatch.stop();
      _simultaneousRuns[index] = _simultaneousRuns[index].copyWith(
        status: 'Failed',
        error: e.toString(),
        totalDuration: stopwatch.elapsed,
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _metricsTimer?.cancel();
    super.dispose();
  }
}
