import 'package:flutter/material.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/catalog_page/catalog_page.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/chat_demo_page/chat_demo_page.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: PageView(
              controller: pageController,
              children: [CatalogPage(), ChatDemoPage()],
            ),
          ),
          SizedBox.expand(
            child: Align(
              alignment: .topCenter,
              child: Row(
                mainAxisSize: .min,
                children: [
                  TextButton(
                    onPressed: () => pageController.animateToPage(
                      0,
                      duration: Durations.medium3,
                      curve: Curves.easeInOutCubicEmphasized,
                    ),
                    child: Text("Widget Catalog"),
                  ),
                  TextButton(
                    onPressed: () => pageController.animateToPage(
                      1,
                      duration: Durations.medium3,
                      curve: Curves.easeInOutCubicEmphasized,
                    ),
                    child: Text("Chat Demo"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
