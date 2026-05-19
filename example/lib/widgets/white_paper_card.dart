import 'package:flutter/material.dart';

/// A beautiful, static, and stateless card representing the right panel.
/// Ready to display rendered dynamic widgets.
class WhitePaperCard extends StatelessWidget {
  final bool isDarkMode;
  final String title;

  const WhitePaperCard({
    super.key,
    required this.isDarkMode,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0), 
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Icon(Icons.architecture, size: 16, color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
              ],
            ),
            Divider(
              color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), 
              height: 16, 
              thickness: 1.5,
            ),
            Expanded(
              child: Center(
                child: Text(
                  '[Ready for dynamic UI visualization]',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
