import 'package:flutter/material.dart';

/// A beautiful, clean, static, and stateless card representing the left panel.
/// Ready to display raw token stream contents.
class BlueprintCard extends StatelessWidget {
  final bool isDarkMode;

  const BlueprintCard({
    super.key,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0), 
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RAW LLM STREAM INPUT',
                  style: TextStyle(
                    color: isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'EMPTY SHELL',
                    style: TextStyle(
                      color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Divider(
              color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0), 
              height: 20,
            ),
            Expanded(
              child: Center(
                child: Text(
                  '[Ready for LLM stream parsing logic]',
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
