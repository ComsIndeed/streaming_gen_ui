import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:example/data/mock_data.dart';
import 'package:example/widgets/technical_grid_background.dart';
import 'package:example/widgets/generation_preview.dart';
import 'package:example/widgets/top_bar_visualizer.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Test case data loaded cleanly from data module
  final List<ExampleData> _examples = mockExamples;
  
  // Package instance to drive reactive Dynamic UI streams
  final StreamingGenUi _genUi = StreamingGenUi();

  late PageController _pageController;
  int _currentPageIndex = 0;

  // Active streams for each page index
  final Map<int, Stream<String>?> _activeStreams = {0: null, 1: null, 2: null};
  // Simulation counters to force rebuild of preview widgets upon manual trigger
  final Map<int, int> _simulationCounters = {0: 0, 1: 0, 2: 0};

  // State to drive the top bar visualizer bars
  bool _isStreamingActive = false;

  // Customizable simulation parameters (Wider and larger)
  int _chunkSize = 6;
  int _speedMs = 40;
  bool _isPaused = false;
  bool _isTokenSaver = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  /// Split a full string into chunks of a given size and push them
  /// onto a stream at specified intervals.
  Stream<String> streamTextInChunks(String text, int chunkSize, Duration interval) async* {
    int totalLength = text.length;
    int numChunks = (totalLength / chunkSize).ceil();

    for (int i = 0; i < numChunks; i++) {
      while (_isPaused) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      int start = i * chunkSize;
      int end = (start + chunkSize < totalLength) ? start + chunkSize : totalLength;
      yield text.substring(start, end);
      await Future.delayed(interval);
    }
  }

  String _minifyInteractiveBlock(String text) {
    try {
      int startMatch = text.indexOf('<interface>');
      int tagLength = '<interface>'.length;
      int endMatch = text.indexOf('</interface>');
      if (startMatch == -1) {
        startMatch = text.indexOf('<interactive>');
        tagLength = '<interactive>'.length;
        endMatch = text.indexOf('</interactive>');
      }

      if (startMatch != -1 && endMatch != -1 && startMatch < endMatch) {
        final innerStart = startMatch + tagLength;
        final inner = text.substring(innerStart, endMatch);
        final parsed = jsonDecode(inner);
        final minified = jsonEncode(parsed);
        return '${text.substring(0, innerStart)}\n$minified\n${text.substring(endMatch)}';
      }
    } catch (e) {
      // Ignore parsing errors and return raw
    }
    return text;
  }

  void _resetStream() {
    setState(() {
      _activeStreams[_currentPageIndex] = null;
      _isStreamingActive = false;
      _isPaused = false;
    });
    _genUi.cancelStream('page-$_currentPageIndex');
    _genUi.getViewState('page-$_currentPageIndex').clear();
  }

  void _runStreamingSimulationForPage(int pageIndex) {
    setState(() {
      _isPaused = false;
      _simulationCounters[pageIndex] = (_simulationCounters[pageIndex] ?? 0) + 1;
      
      String textToStream = _examples[pageIndex].content;
      if (_isTokenSaver) {
        textToStream = _minifyInteractiveBlock(textToStream);
      }
      final stream = streamTextInChunks(
        textToStream,
        _chunkSize,
        Duration(milliseconds: _speedMs),
      ).asBroadcastStream();
      
      _activeStreams[pageIndex] = stream;
      _isStreamingActive = true;
    });

    // Pipe LLM stream directly into the package engine under a unique page ID
    _genUi.stream(
      _activeStreams[pageIndex]!,
      viewId: 'page-$pageIndex',
    );

    _activeStreams[pageIndex]!.listen(
      null,
      onDone: () {
        if (mounted) {
          setState(() {
            _isStreamingActive = false;
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isStreamingActive = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeExample = _examples[_currentPageIndex];

    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF030712) : const Color(0xFFF8FAFC), // Textured grid base
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Vertical PageView (Grid scrolls with each page)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 80.0, // Top margin to keep transparent header free
                  left: 64.0, // Left padding to give room to centered indicators
                  right: 24.0,
                  bottom: 24.0,
                ),
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                    });
                  },
                  itemCount: _examples.length,
                  itemBuilder: (context, index) {
                    final item = _examples[index];
                    final stream = _activeStreams[index];

                    String displayContent = item.content;
                    if (_isTokenSaver) {
                      displayContent = _minifyInteractiveBlock(displayContent);
                    }

                    return TechnicalGridBackground(
                      isDarkMode: widget.isDarkMode,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GenerationPreview(
                          key: ValueKey('preview-$index'),
                          textStream: stream,
                          fullText: displayContent,
                          title: item.name,
                          isPaused: _isPaused && _isStreamingActive,
                          isTokenSaverEnabled: _isTokenSaver,
                          isDarkMode: widget.isDarkMode,
                          genUi: _genUi,
                          viewId: 'page-$index',
                          onTokenSaverToggled: (val) {
                            setState(() {
                              _isTokenSaver = val;
                            });
                            if (_isStreamingActive) {
                              _resetStream();
                              _runStreamingSimulationForPage(_currentPageIndex);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 2. Static Floating Top Control Bar (Transparent, sits above all scrolling pages)
            Positioned(
              top: 0,
              left: 24,
              right: 24,
              height: 80,
              child: Center(
                child: _buildTransparentTopBar(activeExample),
              ),
            ),

            // 3. Page navigation dots floating at the center left
            Positioned(
              left: 24,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildPageNavigatorIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TRANS-PARENT TOP BAR AND ACTION CONTROLS ---

  Widget _buildTransparentTopBar(ExampleData active) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Column: Slider parameters & visualizer bouncing equalizer bars
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouncing micro-animated equalizer bars representing signal activity
            TopBarVisualizer(
              isActive: _isStreamingActive && !_isPaused,
              activeColor: widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
              inactiveColor: widget.isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8).withValues(alpha: 0.5),
            ),
            const SizedBox(width: 20),

            // Chunk Size parameter slider
            _buildCompactSlider(
              label: 'CHUNK SIZE',
              value: _chunkSize.toDouble(),
              min: 1,
              max: 100,
              displayValue: '$_chunkSize characters',
              onChanged: (val) {
                setState(() {
                  _chunkSize = val.toInt();
                });
              },
            ),
            const SizedBox(width: 32),

            // Speed Interval parameter slider
            _buildCompactSlider(
              label: 'INTERVAL SPEED',
              value: _speedMs.toDouble(),
              min: 5,
              max: 1000,
              displayValue: '$_speedMs ms',
              onChanged: (val) {
                setState(() {
                  _speedMs = val.toInt();
                });
              },
            ),
          ],
        ),

        // Right Row: Live indicators and manual trigger button
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Informative telemetry text
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isStreamingActive 
                            ? (widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF2563EB))
                            : (widget.isDarkMode ? const Color(0xFF475569) : const Color(0xFF64748B)),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PAGE 0${_currentPageIndex + 1}/03 // ${active.shortName}',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'SWIPE VERTICALLY TO NAVIGATE',
                  style: TextStyle(
                    fontSize: 8,
                    fontFamily: 'monospace',
                    color: widget.isDarkMode 
                        ? const Color(0xFF94A3B8).withValues(alpha: 0.8) 
                        : const Color(0xFF64748B).withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),

            // Rotating micro-animated Dark Mode Toggle
            IconButton(
              onPressed: widget.onThemeToggle,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  key: ValueKey(widget.isDarkMode),
                  color: widget.isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFF475569),
                  size: 20,
                ),
              ),
              tooltip: widget.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              style: IconButton.styleFrom(
                backgroundColor: widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                padding: const EdgeInsets.all(10),
              ),
            ),
            const SizedBox(width: 12),

            // Play, Pause, Reset Controls
            if (!_isStreamingActive)
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: widget.isDarkMode 
                          ? const BorderSide(color: Color(0xFF334155)) 
                          : BorderSide.none,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 0,
                  ),
                  onPressed: () => _runStreamingSimulationForPage(_currentPageIndex),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18, color: Color(0xFF38BDF8)),
                  label: const Text(
                    'Start Stream',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: widget.isDarkMode 
                              ? const BorderSide(color: Color(0xFF334155)) 
                              : BorderSide.none,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        elevation: 0,
                      ),
                      onPressed: () => setState(() { _isPaused = !_isPaused; }),
                      icon: Icon(
                        _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, 
                        size: 18, 
                        color: const Color(0xFF38BDF8)
                      ),
                      label: Text(
                        _isPaused ? 'Resume' : 'Pause',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        foregroundColor: widget.isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        elevation: 0,
                      ),
                      onPressed: _resetStream,
                      icon: const Icon(Icons.stop_rounded, size: 18, color: Color(0xFFEF4444)),
                      label: const Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 9,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 24,
          width: 180, // Slider made longer as requested
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3, // Thicker slide bar
              activeTrackColor: widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
              inactiveTrackColor: widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              thumbColor: widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), // Larger thumb size
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageNavigatorIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_examples.length, (index) {
        final isSelected = index == _currentPageIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: InkWell(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 8,
              height: isSelected ? 24 : 8,
              decoration: BoxDecoration(
                color: isSelected 
                    ? (widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF2563EB))
                    : (widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(4),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (widget.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF2563EB))
                              .withValues(alpha: 0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}
