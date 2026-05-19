import 'package:flutter/material.dart';
import 'blueprint_card.dart';
import 'white_paper_card.dart';

/// A completely stateless widget that arranges the empty BlueprintCard (left)
/// and empty WhitePaperCard (right) with a central static arrow icon.
class GenerationPreview extends StatelessWidget {
  final String title;
  final bool isDarkMode;

  const GenerationPreview({
    super.key,
    required this.title,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 800;

        final blueprintCard = BlueprintCard(isDarkMode: isDarkMode);
        final arrowSpacer = _buildStaticArrow(isWide, isDarkMode);
        final whitePaperCard = WhitePaperCard(isDarkMode: isDarkMode, title: title);

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 10, child: blueprintCard),
              SizedBox(width: 80, child: arrowSpacer),
              Expanded(flex: 11, child: whitePaperCard),
            ],
          );
        } else {
          return Column(
            children: [
              Expanded(flex: 5, child: blueprintCard),
              SizedBox(height: 60, child: arrowSpacer),
              Expanded(flex: 6, child: whitePaperCard),
            ],
          );
        }
      },
    );
  }

  Widget _buildStaticArrow(bool isWide, bool isDarkMode) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isWide ? Icons.arrow_forward_rounded : Icons.arrow_downward_rounded,
          size: 20,
          color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}
