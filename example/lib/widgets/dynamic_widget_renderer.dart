import 'package:flutter/material.dart';
import 'package:example/utils/json_parser.dart';

class DynamicWidgetRenderer extends StatelessWidget {
  final Map<String, dynamic> json;

  const DynamicWidgetRenderer({super.key, required this.json});

  @override
  Widget build(BuildContext context) {
    return _buildWidgetFromJson(context, json);
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
            border = Border.all(
              color: bColor != null ? (parseHexColor(bColor) ?? const Color(0xFFCBD5E1)) : const Color(0xFFCBD5E1),
              width: bWidth,
            );
          }

          decoration = BoxDecoration(
            color: hexBg != null ? parseHexColor(hexBg) : null,
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

        TextStyle textStyle = const TextStyle(fontSize: 13, color: Color(0xFF334155));
        if (styleRaw is Map) {
          final double fs = double.tryParse(styleRaw['fontSize']?.toString() ?? '13') ?? 13;
          final String? hexColor = styleRaw['color'];
          final String? fontWeight = styleRaw['fontWeight'];
          final String? fontStyle = styleRaw['fontStyle'];

          textStyle = TextStyle(
            fontSize: fs,
            color: hexColor != null ? (parseHexColor(hexColor) ?? const Color(0xFF334155)) : const Color(0xFF334155),
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
                backgroundColor: const Color(0xFF1E3A8A),
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
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFCD34D)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
              const SizedBox(width: 6),
              Text(
                'Unknown Namespace: $ns',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFB45309),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
    }
  }
}
