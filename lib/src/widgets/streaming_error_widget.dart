import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A custom builder function that allows developers to customize the look of
/// Generative UI parser, registry, and rendering exceptions.
typedef GenerativeUiErrorBuilder =
    Widget Function(BuildContext context, String errorMessage);

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

class _StreamingErrorWidgetState extends State<StreamingErrorWidget>
    with SingleTickerProviderStateMixin {
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
    _scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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

    const bsodBlue = Color(0xFF003FAD); // Royal Windows-style BSOD Blue
    const stripeYellow = Color(0xFFFFCC00); // Construction Yellow
    const stripeBlack = Color(0xFF1E1E1E); // Construction Charcoal

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          constraints: const BoxConstraints(
            maxWidth: 650, // Prevents expanding infinitely horizontally
          ),
          decoration: BoxDecoration(
            color: bsodBlue,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior:
              Clip.antiAlias, // Clips the custom stripes to rounded corners
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min, // Contained vertically
            children: [
              // Top Hazard striped banner
              const SizedBox(
                height: 10,
                child: CustomPaint(
                  painter: HazardStripesPainter(
                    color1: stripeYellow,
                    color2: stripeBlack,
                    stripeWidth: 8,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          ':(',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DYNAMIC_SUBTREE_FAULT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'A rendering or state exception occurred inside a dynamic streaming widget. This is a isolated generative UI fault, not a host app UI crash.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 10,
                                  height: 1.3,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ERROR DETAILS:',
                      style: TextStyle(
                        color: Color(0xFF8BE9FD), // Light Cyan terminal color
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Enforce containment with constraints on the stack details
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight:
                            180, // Absolute containment: scroll if it exceeds this
                      ),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              widget.error,
                              style: const TextStyle(
                                color: Colors.white,
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
              // Bottom Hazard striped banner to frame it nicely
              const SizedBox(
                height: 6,
                child: CustomPaint(
                  painter: HazardStripesPainter(
                    color1: stripeYellow,
                    color2: stripeBlack,
                    stripeWidth: 6,
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
String get activeBuildNamespace =>
    _buildNamespaceStack.isNotEmpty ? _buildNamespaceStack.last : 'Unknown';

/// Retrieves the active widget properties currently building.
String get activeBuildProperties =>
    _buildPropsStack.isNotEmpty ? _buildPropsStack.last : '{}';

/// Prints a highly readable, structured, and orange-colored error block to the developer console.
void logGenUiError({
  required String namespace,
  required String error,
  required String properties,
  StackTrace? stack,
}) {
  debugPrint(
    '╔══════════════════════════════════════════════════════════════════════════╗',
  );
  debugPrint(
    '║ 🍊 \x1B[33m[STREAMING_GEN_UI] Widget Rendering Fault Detected\x1B[0m                   ║',
  );
  debugPrint(
    '╠══════════════════════════════════════════════════════════════════════════╣',
  );
  debugPrint('  Namespace:  $namespace');
  debugPrint('  Properties: $properties');
  debugPrint('  Exception:  $error');
  debugPrint(
    '╚══════════════════════════════════════════════════════════════════════════╝',
  );
  if (stack != null) {
    debugPrint('Stack trace:\n$stack');
  }
}

bool _errorBuilderInitialized = false;

/// Ensures the global Flutter ErrorWidget.builder is configured to intercept and isolate
/// Generative UI layout and build-phase errors as contained orange warning boxes.
void ensureGlobalErrorBuilderInitialized() {
  if (_errorBuilderInitialized) return;
  _errorBuilderInitialized = true;

  final originalBuilder = ErrorWidget.builder;
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final detailsString = details.toString();
    final isGenUi =
        detailsString.contains('StreamingWidgetWrapper') ||
        detailsString.contains('WidgetBlock') ||
        detailsString.contains('StreamingUiProvider') ||
        activeBuildNamespace != 'Unknown';

    if (isGenUi) {
      var namespace = activeBuildNamespace;
      if (namespace == 'Unknown') {
        final match = RegExp(
          'StreamingWidgetWrapper\\(namespace:\\s*["\']?([^"\'\\s)]+)',
        ).firstMatch(detailsString);
        if (match != null) {
          namespace = match.group(1)!;
        }
      }
      final properties = activeBuildProperties;

      // Log the exception in the console, self-identifying the failing widget
      logGenUiError(
        namespace: namespace,
        error: details.exceptionAsString(),
        properties: properties,
        stack: details.stack,
      );

      return StreamingErrorWidget(
        error:
            'Subtree Build/Layout Fault ($namespace):\n${details.exceptionAsString()}',
        showInternalErrors: true,
      );
    }

    return originalBuilder(details);
  };
}

/// A custom painter that draws alternating diagonal safety warning stripes (hazard tape pattern).
class HazardStripesPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final double stripeWidth;

  const HazardStripesPainter({
    required this.color1,
    required this.color2,
    this.stripeWidth = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final double width = size.width;
    final double height = size.height;

    // Draw background color1
    paint.color = color1;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);

    // Draw diagonal stripes of color2
    paint.color = color2;
    paint.strokeWidth = stripeWidth;
    paint.style = PaintingStyle.stroke;

    final double step = stripeWidth * 2;
    // Draw diagonal lines from top-left to bottom-right (tilted at 45 degrees)
    for (double x = -height; x < width + height; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + height, height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant HazardStripesPainter oldDelegate) {
    return color1 != oldDelegate.color1 ||
        color2 != oldDelegate.color2 ||
        stripeWidth != oldDelegate.stripeWidth;
  }
}

/// A wrapper widget that wraps a parsed streaming widget to trace its build lifecycle
/// and intercept exceptions during layout or paint phases using Flutter's ErrorWidget.builder.
class StreamingWidgetWrapper extends StatelessWidget {
  final String namespace;
  final Widget child;

  const StreamingWidgetWrapper({
    super.key,
    required this.namespace,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('namespace', namespace));
  }
}
