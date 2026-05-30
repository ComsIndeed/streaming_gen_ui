import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:streaming_gen_ui_widget_catalog/core/app_widgets/elastic_wrapper.dart';
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

  bool _shouldShowChatDemo() {
    try {
      final uri = Uri.base;
      final path = uri.path.toLowerCase();
      final fragment = uri.fragment.toLowerCase();

      // Check query parameters (e.g. ?chat-demo, ?chat, ?page=chat-demo)
      if (uri.queryParameters.containsKey('chat-demo') ||
          uri.queryParameters.containsKey('chat') ||
          uri.queryParameters['page'] == 'chat' ||
          uri.queryParameters['page'] == 'chat-demo') {
        return true;
      }

      // Check path (e.g. /chat-demo, /chat_demo)
      if (path.contains('chat-demo') || path.contains('chat_demo')) {
        return true;
      }

      // Check hash fragment (e.g. #/chat-demo, #chat-demo)
      if (fragment.contains('chat-demo') || fragment.contains('chat_demo')) {
        return true;
      }
    } catch (e) {
      // Fail-safe default
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    final initialPage = _shouldShowChatDemo() ? 1 : 0;
    pageController = PageController(initialPage: initialPage);
    pageOffset = initialPage.toDouble();
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
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      body: Stack(
        children: [
          // The Page view content
          Positioned.fill(
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: pageController,
              children: [
                CatalogPage(
                  onNavigateToChat: () => pageController.animateToPage(
                    1,
                    duration: Durations.medium3,
                    curve: Curves.easeInOutCubicEmphasized,
                  ),
                ),
                ChatDemoPage(
                  onBack: () => pageController.animateToPage(
                    0,
                    duration: Durations.medium3,
                    curve: Curves.easeInOutCubicEmphasized,
                  ),
                ),
              ],
            ),
          ),

          // Compact Floating Top Right Tab Navigation bar (hidden on mobile)
          if (!isMobile)
            Align(
              alignment: Alignment.topRight,
              child: SafeArea(
                child: ElasticWrapper(
                  child: Container(
                    margin: const EdgeInsets.only(top: 16, right: 16),
                    padding: const EdgeInsets.all(4),
                    decoration: ShapeDecoration(
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.06,
                          ),
                        ),
                      ),
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.2),
                    ),
                    child: Stack(
                      children: [
                        // Background capsule sliding pill (Width 100)
                        Positioned(
                          left: pageOffset * 100.0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 100,
                            decoration: ShapeDecoration(
                              shape: RoundedSuperellipseBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.85,
                              ),
                              shadows: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
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
                              width: 100,
                              height: 32,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => pageController.animateToPage(
                                  0,
                                  duration: Durations.medium3,
                                  curve: Curves.easeInOutCubicEmphasized,
                                ),
                                child: Center(
                                  child: Text(
                                    "Catalog",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: pageOffset < 0.5
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              height: 32,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
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
                                      fontSize: 12,
                                      color: pageOffset >= 0.5
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.8),
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
            ),
        ],
      ),
    );
  }
}
