import 'streaming_widget_schema.dart';

/// Complete widget catalog for the streaming generative UI system.
///
/// Widgets are split into two groups:
/// - [base] — layout primitives (Column, Row, Text). Rendered with examples.
/// - [ui]   — display widgets (Note, Weather, Graph, etc.). Rendered compressed.
abstract final class WidgetCatalog {
  // ---------------------------------------------------------------------------
  // Base — layout primitives
  // ---------------------------------------------------------------------------

  static const column = StreamingWidgetSchema(
    group: WidgetGroup.base,
    tag: 'Base.Column',
    description: 'Vertical stack. Place any widgets as children.',
    childTags: ['*'],
    examples: [
      WidgetExample(
        '<Base.Column>\n'
        '  <Base.Text content="Hello!" style="heading" />\n'
        '  <Ui.Note title="Quick note" content="Remember this." />\n'
        '</Base.Column>',
      ),
    ],
  );

  static const row = StreamingWidgetSchema(
    group: WidgetGroup.base,
    tag: 'Base.Row',
    description: 'Horizontal stack. Place any widgets as children.',
    childTags: ['*'],
    examples: [
      WidgetExample(
        '<Base.Row>\n'
        '  <Base.Text content="Left side" />\n'
        '  <Base.Text content="Right side" />\n'
        '</Base.Row>',
      ),
    ],
  );

  static const text = StreamingWidgetSchema(
    group: WidgetGroup.base,
    tag: 'Base.Text',
    description: 'Inline text block.',
    requiredProps: [WidgetProp('content')],
    optionalProps: [WidgetProp('style', hint: 'heading|subheading|body|caption')],
    examples: [
      WidgetExample('<Base.Text content="Hello, world!" style="heading" />'),
    ],
  );

  // ---------------------------------------------------------------------------
  // Ui — productivity / content
  // ---------------------------------------------------------------------------

  static const note = StreamingWidgetSchema(
    group: WidgetGroup.ui,
    tag: 'Ui.Note',
    description: 'Freeform note card.',
    requiredProps: [
      WidgetProp('title'),
      WidgetProp('content'),
    ],
    optionalProps: [
      WidgetProp('tags', hint: "['tag1','tag2']"),
    ],
    examples: [
      WidgetExample(
        """<Ui.Note title="Meeting Notes" content="Discussed animations and glassmorphism." tags="['design']" />""",
      ),
    ],
  );

  static const task = StreamingWidgetSchema(
    group: WidgetGroup.ui,
    tag: 'Ui.Task',
    description: 'A single actionable task card.',
    requiredProps: [
      WidgetProp('title'),
      WidgetProp('status', hint: 'pending|done'),
    ],
    optionalProps: [
      WidgetProp('dueDate'),
      WidgetProp('priority', hint: 'high|medium|low'),
    ],
    examples: [
      WidgetExample(
        '<Ui.Task title="Finalize UI specs" status="pending" dueDate="Monday" priority="high" />',
      ),
    ],
  );

  static const reminder = StreamingWidgetSchema(
    group: WidgetGroup.ui,
    tag: 'Ui.Reminder',
    description: 'A time-anchored reminder card.',
    requiredProps: [
      WidgetProp('title'),
      WidgetProp('due'),
    ],
    optionalProps: [
      WidgetProp('content'),
    ],
    examples: [
      WidgetExample(
        '<Ui.Reminder title="Doctor appointment" due="Monday 9am" content="Bring insurance card." />',
      ),
    ],
  );

  static const contactCard = StreamingWidgetSchema(
    group: WidgetGroup.ui,
    tag: 'Ui.ContactCard',
    description: 'A person or business contact card.',
    requiredProps: [
      WidgetProp('name'),
      WidgetProp('role'),
    ],
    optionalProps: [
      WidgetProp('avatarUrl'),
      WidgetProp('email'),
      WidgetProp('phone'),
      WidgetProp('company'),
    ],
    examples: [
      WidgetExample(
        '<Ui.ContactCard name="Jane Doe" role="Lead Designer" email="jane@example.com" company="Acme Co." />',
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // Ui — media / display
  // ---------------------------------------------------------------------------

  static const carouselItem = StreamingWidgetSchema(
    group: WidgetGroup.ui,
    tag: 'Ui.CarouselItem',
    description: 'A single slide inside Ui.Carousel.',
    requiredProps: [WidgetProp('title')],
    optionalProps: [WidgetProp('imageUrl'), WidgetProp('description')],
  );

  static const carousel = StreamingWidgetSchema(
    group: WidgetGroup.ui,
    tag: 'Ui.Carousel',
    description: 'Horizontal item gallery. Nest CarouselItem children.',
    requiredProps: [WidgetProp('title')],
    childTags: ['Ui.CarouselItem'],
    examples: [
      WidgetExample(
        '<Ui.Carousel title="Featured">\n'
        '  <Ui.CarouselItem title="Alpha" imageUrl="https://..." />\n'
        '  <Ui.CarouselItem title="Beta" imageUrl="https://..." />\n'
        '</Ui.Carousel>',
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // Ui — data / charts
  // ---------------------------------------------------------------------------

  static const forecast = StreamingWidgetSchema(
    group: WidgetGroup.ui,
    tag: 'Ui.Forecast',
    description: 'A single forecast row inside Ui.Weather.',
    requiredProps: [
      WidgetProp('day'),
      WidgetProp('temp'),
      WidgetProp('condition', hint: 'sunny|rainy|cloudy|snowy'),
    ],
  );

  static const weather = StreamingWidgetSchema(
    group: WidgetGroup.ui,
    tag: 'Ui.Weather',
    description: 'Weather card. Optionally nest Ui.Forecast children.',
    requiredProps: [
      WidgetProp('temp'),
      WidgetProp('condition', hint: 'sunny|rainy|cloudy|snowy'),
      WidgetProp('location'),
    ],
    childTags: ['Ui.Forecast'],
    examples: [
      WidgetExample(
        '<Ui.Weather temp="24" condition="sunny" location="San Francisco">\n'
        '  <Ui.Forecast day="Mon" temp="25" condition="sunny" />\n'
        '  <Ui.Forecast day="Tue" temp="23" condition="cloudy" />\n'
        '</Ui.Weather>',
      ),
    ],
  );

  static const graph = StreamingWidgetSchema(
    group: WidgetGroup.ui,
    tag: 'Ui.Graph',
    description: 'Data chart.',
    requiredProps: [
      WidgetProp('type', hint: 'bar|line|pie'),
      WidgetProp('labels', hint: "['Q1','Q2']"),
      WidgetProp('values', hint: '[120,150]'),
    ],
    optionalProps: [
      WidgetProp('title'),
      WidgetProp('subtitle'),
    ],
    examples: [
      WidgetExample(
        """<Ui.Graph type="bar" title="Quarterly Sales" labels="['Q1','Q2','Q3']" values="[120,150,180]" />""",
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // Ui — search / discovery
  // ---------------------------------------------------------------------------

  static const webResult = StreamingWidgetSchema(
    group: WidgetGroup.ui,
    tag: 'Ui.WebResult',
    description: 'A web search result snippet.',
    requiredProps: [
      WidgetProp('title'),
      WidgetProp('url'),
    ],
    optionalProps: [
      WidgetProp('snippet'),
      WidgetProp('siteName'),
      WidgetProp('publishDate'),
    ],
    examples: [
      WidgetExample(
        '<Ui.WebResult title="Flutter Package" url="pub.dev" snippet="Cross-platform UI toolkit." siteName="pub.dev" />',
      ),
    ],
  );

  static const itemCard = StreamingWidgetSchema(
    group: WidgetGroup.ui,
    tag: 'Ui.ItemCard',
    description: 'A rich card for any online listing — product, article, or result.',
    requiredProps: [WidgetProp('title')],
    optionalProps: [
      WidgetProp('price'),
      WidgetProp('rating'),
      WidgetProp('imageUrl'),
      WidgetProp('description'),
      WidgetProp('badge'),
    ],
    examples: [
      WidgetExample(
        '<Ui.ItemCard title="Mechanical Keyboard" price="129.99" rating="4.8" imageUrl="https://..." badge="Sale" />',
      ),
    ],
  );

  static const location = StreamingWidgetSchema(
    group: WidgetGroup.ui,
    tag: 'Ui.Location',
    description: 'Location and navigation card.',
    requiredProps: [
      WidgetProp('name'),
      WidgetProp('address'),
    ],
    optionalProps: [
      WidgetProp('rating'),
      WidgetProp('distance'),
      WidgetProp('hours'),
      WidgetProp('imageUrl'),
    ],
    examples: [
      WidgetExample(
        '<Ui.Location name="Blue Bottle Coffee" address="1355 Market St, SF" distance="0.4 mi" rating="4.5" hours="7am-6pm" />',
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // Catalog lists
  // ---------------------------------------------------------------------------

  /// Layout primitives. Shown in the prompt with full examples.
  static const List<StreamingWidgetSchema> base = [column, row, text];

  /// Display widgets. Shown in the prompt compressed (no examples).
  static const List<StreamingWidgetSchema> ui = [
    // productivity
    note, task, reminder, contactCard,
    // media
    carousel,
    // data
    weather, graph,
    // discovery
    webResult, itemCard, location,
  ];

  /// All top-level widgets the model can directly instantiate.
  static const List<StreamingWidgetSchema> all = [...base, ...ui];

  /// Child-only widgets (nested inside their parent tag; not directly instantiated).
  static const List<StreamingWidgetSchema> children = [carouselItem, forecast];
}
