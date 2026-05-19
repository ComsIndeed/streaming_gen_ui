import 'package:flutter/material.dart';
import 'package:example/data/mock_data.dart';
import 'package:example/widgets/generation_preview.dart';

/// A clean, static screen showing fullscreen pageviews of empty GenerationPreview card pairs.
/// Contains no active streaming state, controllers, or playback controls.
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
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeExample = mockExamples[_currentPageIndex];

    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF030712) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Vertical PageView for Fullscreen Previews
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 80.0,
                  left: 64.0,
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
                  itemCount: mockExamples.length,
                  itemBuilder: (context, index) {
                    final example = mockExamples[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GenerationPreview(
                        title: example.name,
                        isDarkMode: widget.isDarkMode,
                      ),
                    );
                  },
                ),
              ),
            ),

            // 2. Static Floating Top Header Bar (Transparent, sits above scrolling pages)
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

  Widget _buildTransparentTopBar(ExampleData active) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Title
        Text(
          'STREAMING GEN UI // STATIC SHELLS',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.1,
            color: widget.isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
          ),
        ),

        // Right Row: Theme toggle and page counter
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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

            // Theme Toggle
            IconButton(
              onPressed: widget.onThemeToggle,
              icon: Icon(
                widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: widget.isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFF475569),
                size: 20,
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
          ],
        ),
      ],
    );
  }

  Widget _buildPageNavigatorIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(mockExamples.length, (index) {
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
