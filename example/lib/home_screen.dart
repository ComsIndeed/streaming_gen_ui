import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:example/widgets/technical_grid_background.dart';
import 'package:example/widgets/generation_preview.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Test case data
  final List<_ExampleData> _examples = [
    _ExampleData(
      name: '🏨 Paris Hotel Recommendations',
      shortName: 'HOTELS_SCHEMA',
      content: _exampleHotels,
    ),
    _ExampleData(
      name: '👤 Vincent\'s Profile Card',
      shortName: 'PROFILE_SCHEMA',
      content: _exampleProfile,
    ),
    _ExampleData(
      name: '✈️ Airline Boarding Pass',
      shortName: 'BOARDING_PASS_SCHEMA',
      content: _exampleInvoice,
    ),
  ];

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    
    // Auto-run first example on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runStreamingSimulationForPage(0);
    });
  }

  /// Split a full string into chunks of a given size and push them
  /// onto a stream at specified intervals.
  Stream<String> streamTextInChunks(String text, int chunkSize, Duration interval) async* {
    int totalLength = text.length;
    int numChunks = (totalLength / chunkSize).ceil();

    for (int i = 0; i < numChunks; i++) {
      int start = i * chunkSize;
      int end = (start + chunkSize < totalLength) ? start + chunkSize : totalLength;
      yield text.substring(start, end);
      await Future.delayed(interval);
    }
  }

  void _runStreamingSimulationForPage(int pageIndex) {
    setState(() {
      _simulationCounters[pageIndex] = (_simulationCounters[pageIndex] ?? 0) + 1;
      
      final String textToStream = _examples[pageIndex].content;
      final stream = streamTextInChunks(
        textToStream,
        _chunkSize,
        Duration(milliseconds: _speedMs),
      ).asBroadcastStream();
      
      _activeStreams[pageIndex] = stream;
      _isStreamingActive = true;
    });

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
      backgroundColor: const Color(0xFFF8FAFC), // Textured grid base
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
                    _runStreamingSimulationForPage(index);
                  },
                  itemCount: _examples.length,
                  itemBuilder: (context, index) {
                    final item = _examples[index];
                    final simCount = _simulationCounters[index] ?? 0;
                    final stream = _activeStreams[index];

                    return TechnicalGridBackground(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GenerationPreview(
                          key: ValueKey('preview-$index-$simCount-$_chunkSize-$_speedMs'),
                          textStream: stream,
                          fullText: item.content, // Pass full text for background ghost JSON alignment
                          title: item.name,
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

  Widget _buildTransparentTopBar(_ExampleData active) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Column: Slider parameters & visualizer bouncing equalizer bars
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouncing micro-animated equalizer bars representing signal activity
            TopBarVisualizer(isActive: _isStreamingActive),
            const SizedBox(width: 20),

            // Chunk Size parameter slider
            _buildCompactSlider(
              label: 'CHUNK SIZE',
              value: _chunkSize.toDouble(),
              min: 1,
              max: 20,
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
              max: 250,
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
                        color: _isStreamingActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PAGE 0${_currentPageIndex + 1}/03 // ${active.shortName}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
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
                    color: const Color(0xFF64748B).withOpacity(0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),

            // Start Stream Button
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              style: const TextStyle(
                fontSize: 8.5,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              displayValue,
              style: const TextStyle(
                fontSize: 9,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
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
              activeTrackColor: const Color(0xFF2563EB),
              inactiveTrackColor: const Color(0xFFE2E8F0),
              thumbColor: const Color(0xFF2563EB),
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
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
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

class _ExampleData {
  final String name;
  final String shortName;
  final String content;

  _ExampleData({
    required this.name,
    required this.shortName,
    required this.content,
  });
}

// --- DATASETS (TEST EXAMPLES WITH XML + SPEC COMPLIANT JSON) ---

const String _exampleHotels = '''
Here are some excellent hotel recommendations for your stay in Paris, curated just for you:

<interactive>
{
  "namespace": "core:column",
  "children": [
    {
      "namespace": "core:container",
      "padding": "12",
      "decoration": {
        "color": "#F1F5F9",
        "borderRadius": "8",
        "border": {
          "color": "#3B82F6",
          "width": "1"
        }
      },
      "child": {
        "namespace": "core:column",
        "children": [
          {
            "namespace": "core:text",
            "text": "🏨 Hotel Plaza Athénée",
            "style": {
              "fontWeight": "bold",
              "fontSize": "16",
              "color": "#1E3A8A"
            }
          },
          {
            "namespace": "core:container",
            "height": "4"
          },
          {
            "namespace": "core:text",
            "text": "Luxury hotel near Champs-Élysées with stunning views of the Eiffel Tower. Rating: 4.9/5",
            "style": {
              "fontSize": "12",
              "color": "#475569"
            }
          }
        ]
      }
    },
    {
      "namespace": "core:container",
      "height": "8"
    },
    {
      "namespace": "core:container",
      "padding": "12",
      "decoration": {
        "color": "#F1F5F9",
        "borderRadius": "8",
        "border": {
          "color": "#3B82F6",
          "width": "1"
        }
      },
      "child": {
        "namespace": "core:column",
        "children": [
          {
            "namespace": "core:text",
            "text": "🏨 Le Bristol Paris",
            "style": {
              "fontWeight": "bold",
              "fontSize": "16",
              "color": "#1E3A8A"
            }
          },
          {
            "namespace": "core:container",
            "height": "4"
          },
          {
            "namespace": "core:text",
            "text": "A historic palace hotel featuring a beautiful rooftop pool and 3-star Michelin dining. Rating: 4.8/5",
            "style": {
              "fontSize": "12",
              "color": "#475569"
            }
          }
        ]
      }
    },
    {
      "namespace": "core:container",
      "height": "12"
    },
    {
      "namespace": "core:elevated_button",
      "child": {
        "namespace": "core:text",
        "text": "Book Now • Explore Paris"
      }
    }
  ]
}
</interactive>

I hope these recommendations help you plan an unforgettable trip to Paris. Please let me know if you would like to filter by specific price ranges or search for other locations!
''';

const String _exampleProfile = '''
Here is the user profile schema loaded from the secure production database:

<interactive>
{
  "namespace": "core:container",
  "padding": "16",
  "decoration": {
    "color": "#F8FAFC",
    "borderRadius": "12",
    "border": {
      "color": "#64748B",
      "width": "1.5"
    }
  },
  "child": {
    "namespace": "core:column",
    "children": [
      {
        "namespace": "core:row",
        "children": [
          {
            "namespace": "core:text",
            "text": "👤 Vincent Sanicolas",
            "style": {
              "fontWeight": "bold",
              "fontSize": "18",
              "color": "#0F172A"
            }
          }
        ]
      },
      {
        "namespace": "core:text",
        "text": "Senior Flutter Developer & Web Architect",
        "style": {
          "fontSize": "12",
          "fontStyle": "italic",
          "color": "#475569"
        }
      },
      {
        "namespace": "core:container",
        "height": "8"
      },
      {
        "namespace": "core:row",
        "children": [
          {
            "namespace": "core:container",
            "padding": "6",
            "decoration": {
              "color": "#E0F2FE",
              "borderRadius": "4"
            },
            "child": {
              "namespace": "core:text",
              "text": "Tags: Flutter • Dart • Web",
              "style": {
                "fontSize": "10",
                "color": "#0369A1"
              }
            }
          }
        ]
      },
      {
        "namespace": "core:container",
        "height": "12"
      },
      {
        "namespace": "core:row",
        "children": [
          {
            "namespace": "core:elevated_button",
            "child": {
              "namespace": "core:text",
              "text": "Contact Author"
            }
          }
        ]
      }
    ]
  }
}
</interactive>

I have confirmed this profile has active read/write permissions. Let me know if you would like me to render another profile card or query the DB.
''';

const String _exampleInvoice = '''
Here is your airline invoice and electronic boarding pass information:

<interactive>
{
  "namespace": "core:column",
  "children": [
    {
      "namespace": "core:text",
      "text": "✈️ Flight Booking Confirmed",
      "style": {
        "fontWeight": "bold",
        "fontSize": "16",
        "color": "#15803D"
      }
    },
    {
      "namespace": "core:container",
      "height": "8"
    },
    {
      "namespace": "core:container",
      "padding": "10",
      "decoration": {
        "color": "#F0FDF4",
        "borderRadius": "6",
        "border": {
          "color": "#86EFAC",
          "width": "1"
        }
      },
      "child": {
        "namespace": "core:text",
        "text": "Reservation Reference: #AG-255463",
        "style": {
          "fontWeight": "bold",
          "fontSize": "11",
          "color": "#166534"
        }
      }
    },
    {
      "namespace": "core:container",
      "height": "12"
    },
    {
      "namespace": "core:row",
      "children": [
        {
          "namespace": "core:text",
          "text": "Depart: MNL ➔ Arrive: CDG",
          "style": {
            "fontSize": "13",
            "fontWeight": "bold",
            "color": "#1E293B"
          }
        }
      ]
    },
    {
      "namespace": "core:container",
      "height": "4"
    },
    {
      "namespace": "core:text",
      "text": "Gate: A12 | Boarding: 21:50 | Seat: 12B",
      "style": {
        "fontSize": "11",
        "color": "#475569"
      }
    },
    {
      "namespace": "core:container",
      "height": "12"
    },
    {
      "namespace": "core:elevated_button",
      "child": {
        "namespace": "core:text",
        "text": "Download Boarding Pass"
      }
    }
  ]
}
</interactive>

Your ticket has been sent to your registered email address. Have a wonderful and safe flight with us!
''';

// --- ANINMATED BAR VISUALIZER BLOCK ---

class TopBarVisualizer extends StatefulWidget {
  final bool isActive;
  const TopBarVisualizer({super.key, required this.isActive});

  @override
  State<TopBarVisualizer> createState() => _TopBarVisualizerState();
}

class _TopBarVisualizerState extends State<TopBarVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant TopBarVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(8, (index) {
            double factor = 0.35;
            if (widget.isActive) {
              // Smooth pulsing equalizer heights
              factor = 0.3 + 0.7 * (0.5 + 0.5 * sin(_controller.value * 2 * pi + index * 0.9)).clamp(0.0, 1.0);
            }
            return Container(
              width: 3.5,
              height: 14 * factor,
              margin: const EdgeInsets.symmetric(horizontal: 2.0),
              decoration: BoxDecoration(
                color: widget.isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8).withOpacity(0.5),
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }
}
