/// Catalog group that controls how a widget's schema is rendered in the prompt.
///
/// - [base] — layout primitives; rendered with full examples.
/// - [ui] — display/domain widgets; rendered compressed (no examples).
enum WidgetGroup { base, ui }

/// An XML attribute definition for a streaming UI widget.
class WidgetProp {
  /// The attribute name, e.g. `title`.
  final String name;

  /// Optional value hint shown in the prompt, e.g. `'bar|line|pie'`.
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
class StreamingWidgetSchema {
  /// Catalog group this widget belongs to.
  final WidgetGroup group;

  /// XML tag identifier, e.g. `Base.Column`, `Ui.Weather`.
  final String tag;

  /// One-line description of what the widget renders.
  final String description;

  /// Attributes the model must always include.
  final List<WidgetProp> requiredProps;

  /// Attributes the model may optionally include.
  /// Omitted in compact (small-model) mode.
  final List<WidgetProp> optionalProps;

  /// Tags permitted as direct XML children.
  /// Use `['*']` to indicate any widget is accepted (e.g. Base.Column).
  final List<String> childTags;

  /// Concrete examples shown beneath the tag blueprint.
  final List<WidgetExample> examples;

  const StreamingWidgetSchema({
    required this.group,
    required this.tag,
    required this.description,
    this.requiredProps = const [],
    this.optionalProps = const [],
    this.childTags = const [],
    this.examples = const [],
  });

  /// Generates the prompt entry for this schema.
  ///
  /// [compact] — when `true` (default), only [requiredProps] appear in the
  /// tag blueprint; set to `false` to include [optionalProps] as well.
  ///
  /// [showExamples] — when `false`, example lines are omitted entirely.
  /// Used for the compressed Ui group.
  String toPromptString({bool compact = true, bool showExamples = true}) {
    final props = compact
        ? requiredProps
        : [...requiredProps, ...optionalProps];

    final propsStr = props.map((p) => p.promptAttr).join(' ');
    final hasProps = propsStr.isNotEmpty;
    final hasChildren = childTags.isNotEmpty;
    final wildcardChildren = hasChildren && childTags.first == '*';

    final buffer = StringBuffer('- `<$tag${hasProps ? ' $propsStr' : ''}');

    if (hasChildren) {
      final childRef = wildcardChildren ? '...' : '<${childTags.first} .../>';
      buffer.write('>$childRef</$tag>`');
    } else {
      buffer.write(' />`');
    }

    buffer.write(' - $description');

    if (hasChildren && !wildcardChildren && childTags.length > 1) {
      final tags = childTags.map((t) => '<$t>').join(', ');
      buffer.write(' Accepts: $tags.');
    }

    buffer.writeln();

    if (showExamples) {
      for (final ex in examples) {
        buffer.writeln('  - Example: <interface>${ex.xml}</interface>');
      }
    }

    return buffer.toString();
  }
}
