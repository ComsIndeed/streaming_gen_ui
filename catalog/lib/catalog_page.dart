import 'package:flutter/material.dart';
import 'package:streaming_gen_ui_widget_catalog/widgets/graph_background.dart';

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        child: GraphBackground(
          child: SizedBox(
            width: double.infinity,
            height: 2000, // Keep height large so we can test scrolling the pure grid
            child: null,
          ),
        ),
      ),
    );
  }
}
