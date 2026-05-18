import 'package:flutter/material.dart';
import 'package:example/utils/json_parser.dart';

class DynamicWidgetRenderer extends StatelessWidget {
  final Map<String, dynamic> json;
  final bool isDarkMode;

  const DynamicWidgetRenderer({
    super.key,
    required this.json,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return _buildWidgetFromJson(context, json);
  }

  Color? _mapColor(Color? original, bool isDarkMode) {
    if (original == null) return null;
    if (!isDarkMode) return original;

    final double luminance = original.computeLuminance();
    if (luminance > 0.85) {
      // Map pure white / off-white container backgrounds to premium dark slate
      return const Color(0xFF1D2432);
    } else if (luminance > 0.5) {
      // Map medium light grays to a dark background highlight
      return const Color(0xFF2D3748);
    } else if (luminance < 0.15) {
      // Map deep charcoal / black texts to crisp slate-100 off-white
      return const Color(0xFFF1F5F9);
    } else if (luminance < 0.35) {
      // Map slate-700 / slate-800 to slate-300 soft text
      return const Color(0xFFCBD5E1);
    }

    return original;
  }

  Widget _buildWidgetFromJson(BuildContext context, Map<String, dynamic> json) {
    final String ns = json['namespace'] ?? '';
    final childrenRaw = json['children'];
    final childRaw = json['child'];

    // Map children
    List<Widget> children = [];
    if (childrenRaw is List) {
      children = childrenRaw.map((c) => _buildWidgetFromJson(context, c as Map<String, dynamic>)).toList();
    }

    // Map child
    Widget? child;
    if (childRaw is Map) {
      child = _buildWidgetFromJson(context, childRaw as Map<String, dynamic>);
    }

    switch (ns) {
      case 'core:column':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        );

      case 'core:row':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        );

      case 'core:container':
        final double? w = json['width'] != null ? double.tryParse(json['width'].toString()) : null;
        final double? h = json['height'] != null ? double.tryParse(json['height'].toString()) : null;
        final double pad = double.tryParse(json['padding']?.toString() ?? '0') ?? 0;

        // Custom decoration parser
        BoxDecoration? decoration;
        final decRaw = json['decoration'];
        if (decRaw is Map) {
          final String? hexBg = decRaw['color'];
          final double borderRad = double.tryParse(decRaw['borderRadius']?.toString() ?? '0') ?? 0;
          final borderRaw = decRaw['border'];

          Border? border;
          if (borderRaw is Map) {
            final String? bColor = borderRaw['color'];
            final double bWidth = double.tryParse(borderRaw['width']?.toString() ?? '1') ?? 1;
            
            Color borderColor = bColor != null 
                ? (parseHexColor(bColor) ?? const Color(0xFFCBD5E1)) 
                : const Color(0xFFCBD5E1);
            if (isDarkMode) {
              borderColor = const Color(0xFF334155);
            }

            border = Border.all(
              color: borderColor,
              width: bWidth,
            );
          }

          Color? bgColor = hexBg != null ? parseHexColor(hexBg) : null;
          if (isDarkMode) {
            if (bgColor == null || bgColor.computeLuminance() > 0.8) {
              bgColor = const Color(0xFF1E293B);
            } else {
              bgColor = _mapColor(bgColor, true);
            }
          }

          decoration = BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRad),
            border: border,
          );
        }

        return Container(
          width: w,
          height: h,
          padding: pad > 0 ? EdgeInsets.all(pad) : null,
          decoration: decoration,
          child: child,
        );

      case 'core:text':
        final String text = json['text'] ?? '';
        final styleRaw = json['style'];

        TextStyle textStyle = TextStyle(
          fontSize: 13, 
          color: isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
        );
        if (styleRaw is Map) {
          final double fs = double.tryParse(styleRaw['fontSize']?.toString() ?? '13') ?? 13;
          final String? hexColor = styleRaw['color'];
          final String? fontWeight = styleRaw['fontWeight'];
          final String? fontStyle = styleRaw['fontStyle'];

          Color textColor = hexColor != null 
              ? (parseHexColor(hexColor) ?? const Color(0xFF334155)) 
              : const Color(0xFF334155);
          
          if (isDarkMode) {
            textColor = _mapColor(textColor, true) ?? const Color(0xFFCBD5E1);
          }

          textStyle = TextStyle(
            fontSize: fs,
            color: textColor,
            fontWeight: fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
            fontStyle: fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
          );
        }

        return Text(text, style: textStyle);

      case 'core:elevated_button':
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB), // Premium Royal Blue button
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Action Registered Successfully!',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                backgroundColor: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFF1E3A8A),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          },
          child: child ?? const Text('Action'),
        );

      default:
        // Unknown namespace warning handler
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF451A03) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isDarkMode ? const Color(0xFF9A3412) : const Color(0xFFFCD34D)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: isDarkMode ? const Color(0xFFFDBA74) : const Color(0xFFD97706)),
              const SizedBox(width: 6),
              Text(
                'Unknown Namespace: $ns',
                style: TextStyle(
                  fontSize: 11,
                  color: isDarkMode ? const Color(0xFFFDBA74) : const Color(0xFFB45309),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
    }
  }
}
