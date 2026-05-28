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

class ModelTestProvider with ChangeNotifier {
  ModelTestProvider() {
    _initResults();
  }

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  int _currentTestIndex = -1;
  int get currentTestIndex => _currentTestIndex;

  late List<TestResult> _results;
  List<TestResult> get results => _results;

  void _initResults() {
    _results = kTestMessages
        .map((msg) => TestResult(message: msg))
        .toList(growable: false);
    notifyListeners();
  }

  void reset() {
    _isRunning = false;
    _currentTestIndex = -1;
    _initResults();
  }

  Future<void> runTest({
    required ModelConfig modelConfig,
    String? systemPrompt,
  }) async {
    if (_isRunning) return;
    _isRunning = true;
    _currentTestIndex = -1;
    notifyListeners();

    for (int i = 0; i < kTestMessages.length; i++) {
      if (!_isRunning) break; // Allow cancellation via reset
      _currentTestIndex = i;

      // Mark as running
      _results[i] = TestResult(message: kTestMessages[i], running: true);
      notifyListeners();

      final stopwatch = Stopwatch()..start();
      Duration? ttft;
      final responseBuffer = StringBuffer();

      try {
        final session = ChatSession(
          systemPrompt:
              systemPrompt ??
              'You are a helpful assistant that answers concisely.',
          modelConfig: modelConfig,
        );

        final stream = session.sendMessage(kTestMessages[i]);
        await for (final chunk in stream) {
          ttft ??= stopwatch.elapsed;
          responseBuffer.write(chunk);
          // Notify on each chunk to show live progress
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
}
