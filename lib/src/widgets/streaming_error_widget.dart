import 'package:flutter/material.dart';

/// A custom builder function that allows developers to customize the look of 
/// Generative UI parser, registry, and rendering exceptions.
typedef GenerativeUiErrorBuilder = Widget Function(BuildContext context, String errorMessage);

/// A unified widget for displaying errors during stream parsing or component rendering.
/// Features a contained orange card design with ghostly entry animation and scrollable details.
class StreamingErrorWidget extends StatefulWidget {
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
  State<StreamingErrorWidget> createState() => _StreamingErrorWidgetState();
}

class _StreamingErrorWidgetState extends State<StreamingErrorWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showInternalErrors) return const SizedBox.shrink();

    if (widget.customBuilder != null) {
      try {
        return widget.customBuilder!(context, widget.error);
      } catch (e) {
        debugPrint('Custom GenerativeUiErrorBuilder failed: $e');
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          constraints: const BoxConstraints(
            maxWidth: 650, // Prevents expanding infinitely horizontally
          ),
          decoration: BoxDecoration(
            // Soft orange glaze background
            color: isDark ? const Color(0x1AFF9800) : const Color(0x0DFF9800),
            border: const Border(
              left: BorderSide(
                color: Color(0xFFFF9800), // Vibrant Orange Accent
                width: 4,
              ),
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Contained vertically
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFF9800),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GENERATIVE_UI_FAULT',
                    style: TextStyle(
                      color: const Color(0xFFFF9800),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Enforce containment with constraints on the stack details
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 180, // Absolute containment: scroll if it exceeds this
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        widget.error,
                        style: TextStyle(
                          color: isDark ? const Color(0xFFFFCC80) : const Color(0xFFE65100),
                          fontFamily: 'monospace',
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tracks the nesting/building stack of widget namespaces to help trace where layout/build exceptions occurred.
final List<String> _buildNamespaceStack = [];
final List<String> _buildPropsStack = [];

/// Pushes a widget namespace and properties to the build stack during builder execution.
void pushBuildTrace(String namespace, String properties) {
  _buildNamespaceStack.add(namespace);
  _buildPropsStack.add(properties);
}

/// Pops the top element of the build stack.
void popBuildTrace() {
  if (_buildNamespaceStack.isNotEmpty) {
    _buildNamespaceStack.removeLast();
    _buildPropsStack.removeLast();
  }
}

/// Retrieves the active widget namespace currently building.
String get activeBuildNamespace => _buildNamespaceStack.isNotEmpty ? _buildNamespaceStack.last : 'Unknown';

/// Retrieves the active widget properties currently building.
String get activeBuildProperties => _buildPropsStack.isNotEmpty ? _buildPropsStack.last : '{}';

/// Prints a highly readable, structured, and orange-colored error block to the developer console.
void logGenUiError({
  required String namespace,
  required String error,
  required String properties,
  StackTrace? stack,
}) {
  debugPrint('╔══════════════════════════════════════════════════════════════════════════╗');
  debugPrint('║ 🍊 \x1B[33m[STREAMING_GEN_UI] Widget Rendering Fault Detected\x1B[0m                   ║');
  debugPrint('╠══════════════════════════════════════════════════════════════════════════╣');
  debugPrint('  Namespace:  $namespace');
  debugPrint('  Properties: $properties');
  debugPrint('  Exception:  $error');
  debugPrint('╚══════════════════════════════════════════════════════════════════════════╝');
  if (stack != null) {
    debugPrint('Stack trace:\n$stack');
  }
}bool _errorBuilderInitialized = false;

/// Ensures the global Flutter ErrorWidget.builder is configured to intercept and isolate
/// Generative UI layout and build-phase errors as contained orange warning boxes.
void ensureGlobalErrorBuilderInitialized() {
  if (_errorBuilderInitialized) return;
  _errorBuilderInitialized = true;

  final originalBuilder = ErrorWidget.builder;
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final detailsString = details.toString();
    final isGenUi = detailsString.contains('StreamingWidget') ||
                    detailsString.contains('WidgetBlock') ||
                    activeBuildNamespace != 'Unknown';

    if (isGenUi) {
      final namespace = activeBuildNamespace;
      final properties = activeBuildProperties;

      // Log the exception in the console, self-identifying the failing widget
      logGenUiError(
        namespace: namespace,
        error: details.exceptionAsString(),
        properties: properties,
        stack: details.stack,
      );

      return StreamingErrorWidget(
        error: 'Subtree Build/Layout Fault ($namespace):\n${details.exceptionAsString()}',
        showInternalErrors: true,
      );
    }

    return originalBuilder(details);
  };
}
