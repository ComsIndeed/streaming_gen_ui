/// An XML attribute definition for a streaming UI widget.
class WidgetProp {
  /// The attribute name, e.g. `title`.
  final String name;

  /// Optional value hint displayed in the prompt, e.g. `'bar|line|pie'`.
  /// When null, an empty string placeholder `""` is shown.
  final String? hint;

  const WidgetProp(this.name, {this.hint});

  String get _valueHint => hint != null ? '"$hint"' : '""';

  /// Renders the attribute with its placeholder value, e.g. `title=""`.
  String get promptAttr => '$name=$_valueHint';
}

/// A concrete XML usage example for a streaming widget.
class WidgetExample {
  final String xml;

  const WidgetExample(this.xml);
}

/// Schema definition for a single streamable XML UI widget.
///
/// Used to programmatically generate compact LLM prompt entries and to
/// support dynamic catalog pruning based on context.
class StreamingWidgetSchema {
  /// XML tag identifier, e.g. `MaterialUi.Card`.
  final String tag;

  /// One-line description of what the widget renders.
  final String description;

  /// Attributes the model must always include. Shown in every prompt mode.
  final List<WidgetProp> requiredProps;

  /// Attributes the model may optionally include.
  /// Omitted in compact (small-model) mode; included in full mode.
  final List<WidgetProp> optionalProps;

  /// Tags permitted as direct XML children of this widget.
  /// When non-empty, the tag blueprint renders as an open/close pair.
  final List<String> childTags;

  /// Concrete examples rendered in the prompt beneath the tag blueprint.
  final List<WidgetExample> examples;

  const StreamingWidgetSchema({
    required this.tag,
    required this.description,
    this.requiredProps = const [],
    this.optionalProps = const [],
    this.childTags = const [],
    this.examples = const [],
  });

  /// Generates the prompt entry for this schema.
  ///
  /// [compact] (default `true`) renders only [requiredProps] in the tag
  /// blueprint — ideal for small models with tight context budgets.
  /// Set [compact] to `false` to include [optionalProps] as well.
  String toPromptString({bool compact = true}) {
    final props = compact
        ? requiredProps
        : [...requiredProps, ...optionalProps];

    final propsStr = props.map((p) => p.promptAttr).join(' ');
    final hasProps = propsStr.isNotEmpty;
    final hasChildren = childTags.isNotEmpty;

    final buffer = StringBuffer('- `<$tag${hasProps ? ' $propsStr' : ''}');

    if (hasChildren) {
      buffer.write('><${childTags.first} .../></$tag>`');
    } else {
      buffer.write(' />`');
    }

    buffer.write(' - $description');

    if (childTags.length > 1) {
      final tags = childTags.map((t) => '<$t>').join(', ');
      buffer.write(' Accepts: $tags.');
    }

    buffer.writeln();

    for (final ex in examples) {
      buffer.writeln('  - Example: <interface>${ex.xml}</interface>');
    }

    return buffer.toString();
  }
}
