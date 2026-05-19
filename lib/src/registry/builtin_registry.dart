import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'widget_registry.dart';

class BuiltinRegistry implements WidgetRegistry {
  @override
  Widget? buildWidget(String namespace, MapPropertyStream properties) {
    throw UnimplementedError();
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
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
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
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
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
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
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
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
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
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
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
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
