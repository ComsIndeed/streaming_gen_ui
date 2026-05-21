import 'package:flutter/material.dart';
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/catalog_page/catalog_page.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/chat_demo_page/chat_demo_page.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late final PageController pageController;
  double pageOffset = 0.0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    pageController.addListener(() {
      if (mounted && pageController.hasClients) {
        setState(() {
          pageOffset = pageController.page ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // The Page view content
          Positioned.fill(
            child: PageView(
              controller: pageController,
              children: const [CatalogPage(), ChatDemoPage()],
            ),
          ),

          // Floating sliding navigation bar
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(4),
                decoration: ShapeDecoration(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.12),
                    ),
                  ),
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.5,
                  ),
                ),
                child: Stack(
                  children: [
                    // Background capsule sliding pill
                    Positioned(
                      left: pageOffset * 140.0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 140,
                        decoration: ShapeDecoration(
                          shape: RoundedSuperellipseBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          color: theme.colorScheme.primary,
                          shadows: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(
                                0.25,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tap/Click label triggers
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 140,
                          height: 40,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => pageController.animateToPage(
                              0,
                              duration: Durations.medium3,
                              curve: Curves.easeInOutCubicEmphasized,
                            ),
                            child: Center(
                              child: Text(
                                "Widget Catalog",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: pageOffset < 0.5
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          height: 40,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => pageController.animateToPage(
                              1,
                              duration: Durations.medium3,
                              curve: Curves.easeInOutCubicEmphasized,
                            ),
                            child: Center(
                              child: Text(
                                "Chat Demo",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: pageOffset >= 0.5
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
