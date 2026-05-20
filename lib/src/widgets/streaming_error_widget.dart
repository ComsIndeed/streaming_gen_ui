import 'package:flutter/material.dart';

/// A custom builder function that allows developers to customize the look of 
/// Generative UI parser, registry, and rendering exceptions.
typedef GenerativeUiErrorBuilder = Widget Function(BuildContext context, String errorMessage);

/// A unified widget for displaying errors during stream parsing or component rendering.
class StreamingErrorWidget extends StatelessWidget {
  final String error;
  final bool showInternalErrors;
  final GenerativeUiErrorBuilder? customBuilder;

  const StreamingErrorWidget({
    super.key,
    required this.error,
    required this.showInternalErrors,
    this.customBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (!showInternalErrors) return const SizedBox.shrink();

    if (customBuilder != null) {
      try {
        return customBuilder!(context, error);
      } catch (e) {
        // Fallback to default styling if custom builder fails
        debugPrint('Custom GenerativeUiErrorBuilder failed: $e');
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F), // Deep Red
        border: Border.all(color: Colors.black, width: 3), // Black border
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFFFEB3B), size: 20),
              SizedBox(width: 8),
              Text(
                'Generative UI Error',
                style: TextStyle(
                  color: Color(0xFFFFEB3B),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              color: Color(0xFFFFEB3B),
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
