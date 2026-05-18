import 'dart:async';
import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'widget_registry.dart';
import '../widgets/gen_ui_view.dart';

class BuiltinRegistry implements WidgetRegistry {
  @override
  Widget? buildWidget(String namespace, MapPropertyStream properties) {
    switch (namespace) {
      case 'core:text':
        return StreamingText(
          stringStream: properties.getStringProperty('text'),
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF1F2937),
            height: 1.4,
          ),
        );
      case 'core:button':
      case 'core:elevated_button':
        return StreamingButton(
          mapStream: properties,
          registry: this,
        );
      case 'core:column':
        return StreamingColumn(
          mapStream: properties,
          registry: this,
        );
      case 'core:row':
        return StreamingRow(
          mapStream: properties,
          registry: this,
        );
      case 'core:container':
        return StreamingContainer(
          mapStream: properties,
          registry: this,
        );
      case 'core:textfield':
        return StreamingTextField(
          mapStream: properties,
        );
      default:
        return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STREAMING COMPONENT IMPLEMENTATIONS
// ─────────────────────────────────────────────────────────────────────────────

class StreamingText extends StatefulWidget {
  final StringPropertyStream stringStream;
  final TextStyle? style;

  const StreamingText({
    super.key,
    required this.stringStream,
    this.style,
  });

  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText> {
  String _accumulated = '';
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.stringStream.stream.listen((chunk) {
      setState(() {
        _accumulated += chunk;
      });
    });
    widget.stringStream.future.then((full) {
      if (mounted && _accumulated != full) {
        setState(() {
          _accumulated = full;
        });
      }
    });
  }

  @override
  void didUpdateWidget(StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stringStream != widget.stringStream) {
      _subscription?.cancel();
      _accumulated = '';
      _subscription = widget.stringStream.stream.listen((chunk) {
        setState(() {
          _accumulated += chunk;
        });
      });
      widget.stringStream.future.then((full) {
        if (mounted && _accumulated != full) {
          setState(() {
            _accumulated = full;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _accumulated,
      style: widget.style,
    );
  }
}

class StreamingButton extends StatefulWidget {
  final MapPropertyStream mapStream;
  final WidgetRegistry registry;

  const StreamingButton({
    super.key,
    required this.mapStream,
    required this.registry,
  });

  @override
  State<StreamingButton> createState() => _StreamingButtonState();
}

class _StreamingButtonState extends State<StreamingButton> {
  String? _action;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _resolveAction();
  }

  void _resolveAction() async {
    try {
      final actionStr = await widget.mapStream.getStringProperty('action').future;
      if (mounted) {
        setState(() {
          _action = actionStr;
          _resolved = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolved = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(StreamingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapStream != widget.mapStream) {
      _resolved = false;
      _action = null;
      _resolveAction();
    }
  }

  @override
  Widget build(BuildContext context) {
    final childMap = widget.mapStream.getMapProperty('child');
    final isEnabled = _resolved && _action != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: isEnabled ? () {
          // Action triggers can be dispatched or printed for demonstration
          debugPrint('GenUI Action Triggered: $_action');
        } : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isEnabled
                ? const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)],
                  ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: StreamingWidget(
            mapStream: childMap,
            registry: widget.registry,
          ),
        ),
      ),
    );
  }
}

class StreamingColumn extends StatefulWidget {
  final MapPropertyStream mapStream;
  final WidgetRegistry registry;

  const StreamingColumn({
    super.key,
    required this.mapStream,
    required this.registry,
  });

  @override
  State<StreamingColumn> createState() => _StreamingColumnState();
}

class _StreamingColumnState extends State<StreamingColumn> {
  final List<MapPropertyStream> _children = [];

  @override
  void initState() {
    super.initState();
    _listenToChildren();
  }

  void _listenToChildren() {
    final listStream = widget.mapStream.getListProperty('children');
    listStream.onElement((element, index) {
      if (element is MapPropertyStream) {
        if (mounted) {
          setState(() {
            if (index >= _children.length) {
              _children.add(element);
            } else {
              _children[index] = element;
            }
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(StreamingColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapStream != widget.mapStream) {
      _children.clear();
      _listenToChildren();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: _children.map((childStream) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: StreamingWidget(
            mapStream: childStream,
            registry: widget.registry,
          ),
        );
      }).toList(),
    );
  }
}

class StreamingRow extends StatefulWidget {
  final MapPropertyStream mapStream;
  final WidgetRegistry registry;

  const StreamingRow({
    super.key,
    required this.mapStream,
    required this.registry,
  });

  @override
  State<StreamingRow> createState() => _StreamingRowState();
}

class _StreamingRowState extends State<StreamingRow> {
  final List<MapPropertyStream> _children = [];

  @override
  void initState() {
    super.initState();
    _listenToChildren();
  }

  void _listenToChildren() {
    final listStream = widget.mapStream.getListProperty('children');
    listStream.onElement((element, index) {
      if (element is MapPropertyStream) {
        if (mounted) {
          setState(() {
            if (index >= _children.length) {
              _children.add(element);
            } else {
              _children[index] = element;
            }
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(StreamingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapStream != widget.mapStream) {
      _children.clear();
      _listenToChildren();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: _children.map((childStream) {
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: StreamingWidget(
            mapStream: childStream,
            registry: widget.registry,
          ),
        );
      }).toList(),
    );
  }
}

class StreamingContainer extends StatefulWidget {
  final MapPropertyStream mapStream;
  final WidgetRegistry registry;

  const StreamingContainer({
    super.key,
    required this.mapStream,
    required this.registry,
  });

  @override
  State<StreamingContainer> createState() => _StreamingContainerState();
}

class _StreamingContainerState extends State<StreamingContainer> {
  Color _color = Colors.white;
  double _borderRadius = 16.0;
  double? _height;
  double? _width;

  @override
  void initState() {
    super.initState();
    _listenToStyles();
  }

  void _listenToStyles() {
    // 1. Resolve background color (Hex or standard color string)
    widget.mapStream.getStringProperty('color').stream.listen((colorHex) {
      if (colorHex.isNotEmpty && mounted) {
        setState(() {
          _color = _parseColor(colorHex);
        });
      }
    });

    widget.mapStream.getStringProperty('color').future.then((colorHex) {
      if (colorHex.isNotEmpty && mounted) {
        setState(() {
          _color = _parseColor(colorHex);
        });
      }
    }).catchError((_) {});

    // 2. Resolve border radius
    widget.mapStream.getStringProperty('borderRadius').stream.listen((radiusStr) {
      if (radiusStr.isNotEmpty && mounted) {
        setState(() {
          _borderRadius = double.tryParse(radiusStr) ?? 16.0;
        });
      }
    });

    widget.mapStream.getStringProperty('borderRadius').future.then((radiusStr) {
      if (radiusStr.isNotEmpty && mounted) {
        setState(() {
          _borderRadius = double.tryParse(radiusStr) ?? 16.0;
        });
      }
    }).catchError((_) {});

    // 3. Resolve height
    widget.mapStream.getStringProperty('height').stream.listen((heightStr) {
      if (heightStr.isNotEmpty && mounted) {
        setState(() {
          _height = double.tryParse(heightStr);
        });
      }
    });

    widget.mapStream.getStringProperty('height').future.then((heightStr) {
      if (heightStr.isNotEmpty && mounted) {
        setState(() {
          _height = double.tryParse(heightStr);
        });
      }
    }).catchError((_) {});

    // 4. Resolve width
    widget.mapStream.getStringProperty('width').stream.listen((widthStr) {
      if (widthStr.isNotEmpty && mounted) {
        setState(() {
          _width = double.tryParse(widthStr);
        });
      }
    });

    widget.mapStream.getStringProperty('width').future.then((widthStr) {
      if (widthStr.isNotEmpty && mounted) {
        setState(() {
          _width = double.tryParse(widthStr);
        });
      }
    }).catchError((_) {});
  }

  Color _parseColor(String colorStr) {
    if (colorStr.startsWith('#')) {
      final hex = colorStr.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    }
    return Colors.white;
  }

  @override
  void didUpdateWidget(StreamingContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapStream != widget.mapStream) {
      _color = Colors.white;
      _borderRadius = 16.0;
      _height = null;
      _width = null;
      _listenToStyles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final childMap = widget.mapStream.getMapProperty('child');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      height: _height,
      width: _width,
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: StreamingWidget(
        mapStream: childMap,
        registry: widget.registry,
      ),
    );
  }
}

class StreamingTextField extends StatefulWidget {
  final MapPropertyStream mapStream;

  const StreamingTextField({
    super.key,
    required this.mapStream,
  });

  @override
  State<StreamingTextField> createState() => _StreamingTextFieldState();
}

class _StreamingTextFieldState extends State<StreamingTextField> {
  final TextEditingController _controller = TextEditingController();
  String _placeholder = 'Type here...';

  @override
  void initState() {
    super.initState();
    _loadPlaceholder();
  }

  void _loadPlaceholder() async {
    try {
      final p = await widget.mapStream.getStringProperty('placeholder').future;
      if (mounted) {
        setState(() {
          _placeholder = p;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: _placeholder,
          border: InputBorder.none,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        ),
        style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      ),
    );
  }
}
