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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0000AA), // Classic BSOD Blue
        border: Border.all(color: Colors.white, width: 2), // Clean white border
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: const [
              Icon(Icons.monitor_heart, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                '*** GEN_UI_FAULT_DETECTION ***',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'A streaming parser or layout mismatch error has occurred. The UI rendering was halted to protect tree stability.',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'ERROR_CODE: EXCEPTION_TYPE_CAST_FAILED',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '* Check that JSON matches the WidgetDefinition schema.\n'
            '* Press Raw/Parsed mode switch to retry state mounting.',
            style: TextStyle(
              color: Colors.white54,
              fontFamily: 'monospace',
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
