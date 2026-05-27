import 'streaming_widget_schema.dart';

/// Complete catalog of Material 3 streaming UI widget schemas.
///
/// [all] contains every top-level widget the model can directly instantiate.
/// [children] contains child-only widgets that are nested inside parent tags.
abstract final class MaterialCatalog {
  // ---------------------------------------------------------------------------
  // Top-level widgets
  // ---------------------------------------------------------------------------

  static const card = StreamingWidgetSchema(
    tag: 'MaterialUi.Card',
    description: 'Standard content card.',
    requiredProps: [
      WidgetProp('title'),
    ],
    optionalProps: [
      WidgetProp('subtitle'),
      WidgetProp('imageUrl'),
      WidgetProp('action'),
    ],
    examples: [
      WidgetExample(
        '<MaterialUi.Card title="Premium Design" subtitle="Next-gen UX" imageUrl="https://..." />',
      ),
    ],
  );

  static const userProfile = StreamingWidgetSchema(
    tag: 'MaterialUi.UserProfile',
    description: 'User bio and social card.',
    requiredProps: [
      WidgetProp('name'),
      WidgetProp('bio'),
    ],
    optionalProps: [
      WidgetProp('avatarUrl'),
      WidgetProp('email'),
      WidgetProp('badge'),
    ],
    examples: [
      WidgetExample(
        '<MaterialUi.UserProfile name="Jane Doe" bio="Creative designer." avatarUrl="https://..." badge="Pro" />',
      ),
    ],
  );

  static const carousel = StreamingWidgetSchema(
    tag: 'MaterialUi.Carousel',
    description: 'Horizontal item gallery. Nest CarouselItem children.',
    requiredProps: [
      WidgetProp('title'),
    ],
    childTags: ['MaterialUi.CarouselItem'],
    examples: [
      WidgetExample(
        '<MaterialUi.Carousel title="Featured">\n'
        '  <MaterialUi.CarouselItem title="Alpha" imageUrl="https://..." />\n'
        '  <MaterialUi.CarouselItem title="Beta" imageUrl="https://..." />\n'
        '</MaterialUi.Carousel>',
      ),
    ],
  );

  static const weather = StreamingWidgetSchema(
    tag: 'MaterialUi.Weather',
    description: 'Weather card. Optionally nest Forecast children for a forecast row.',
    requiredProps: [
      WidgetProp('temp'),
      WidgetProp('condition', hint: 'sunny|rainy|cloudy|snowy'),
      WidgetProp('location'),
    ],
    examples: [
      WidgetExample(
        '<MaterialUi.Weather temp="24" condition="sunny" location="San Francisco">\n'
        '  <MaterialUi.Forecast day="Mon" temp="25" condition="sunny" />\n'
        '  <MaterialUi.Forecast day="Tue" temp="23" condition="cloudy" />\n'
        '</MaterialUi.Weather>',
      ),
    ],
  );

  static const graph = StreamingWidgetSchema(
    tag: 'MaterialUi.Graph',
    description: 'Chart for visualizing data.',
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
        """<MaterialUi.Graph type="bar" title="Quarterly Sales" labels="['Q1','Q2','Q3']" values="[120,150,180]" />""",
      ),
    ],
  );

  static const webResult = StreamingWidgetSchema(
    tag: 'MaterialUi.WebResult',
    description: 'Search engine result snippet.',
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
        '<MaterialUi.WebResult title="Flutter Package" url="pub.dev" snippet="Cross-platform UI toolkit." siteName="pub.dev" />',
      ),
    ],
  );

  static const productResult = StreamingWidgetSchema(
    tag: 'MaterialUi.ProductResult',
    description: 'E-commerce product card.',
    requiredProps: [
      WidgetProp('title'),
      WidgetProp('price'),
    ],
    optionalProps: [
      WidgetProp('originalPrice'),
      WidgetProp('rating'),
      WidgetProp('imageUrl'),
      WidgetProp('description'),
      WidgetProp('badge'),
    ],
    examples: [
      WidgetExample(
        '<MaterialUi.ProductResult title="Mechanical Keyboard" price="129.99" rating="4.8" imageUrl="https://..." badge="Sale" />',
      ),
    ],
  );

  static const location = StreamingWidgetSchema(
    tag: 'MaterialUi.Location',
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
        '<MaterialUi.Location name="Blue Bottle Coffee" address="1355 Market St, SF" distance="0.4 mi" rating="4.5" hours="7am-6pm" />',
      ),
    ],
  );

  static const todoList = StreamingWidgetSchema(
    tag: 'MaterialUi.TodoList',
    description: 'Checklist. Nest TodoItem children.',
    requiredProps: [
      WidgetProp('title'),
    ],
    childTags: ['MaterialUi.TodoItem'],
    examples: [
      WidgetExample(
        '<MaterialUi.TodoList title="Tasks">\n'
        '  <MaterialUi.TodoItem text="Buy groceries" completed="false" />\n'
        '  <MaterialUi.TodoItem text="Call dentist" completed="true" />\n'
        '</MaterialUi.TodoList>',
      ),
    ],
  );

  static const note = StreamingWidgetSchema(
    tag: 'MaterialUi.Note',
    description: 'Standalone note, todo, or reminder card.',
    requiredProps: [
      WidgetProp('type', hint: 'note|todo|reminder'),
      WidgetProp('title'),
      WidgetProp('content'),
    ],
    optionalProps: [
      WidgetProp('tags', hint: "['tag1','tag2']"),
      WidgetProp('dueDate'),
      WidgetProp('priority', hint: 'high|medium|low'),
    ],
    examples: [
      WidgetExample(
        """<MaterialUi.Note type="note" title="Meeting Notes" content="Discussed dynamic animations." tags="['design','sprint-5']" />""",
      ),
    ],
  );

  static const listResults = StreamingWidgetSchema(
    tag: 'MaterialUi.ListResults',
    description: 'File or item directory listing. Nest ListItem children.',
    requiredProps: [
      WidgetProp('title'),
    ],
    childTags: ['MaterialUi.ListItem'],
    examples: [
      WidgetExample(
        '<MaterialUi.ListResults title="Recent Files">\n'
        '  <MaterialUi.ListItem title="profile_spec.pdf" subtitle="Design blueprint" icon="pdf" size="2.4 MB" />\n'
        '  <MaterialUi.ListItem title="hero.png" subtitle="Asset graphic" icon="image" size="1.1 MB" />\n'
        '</MaterialUi.ListResults>',
      ),
    ],
  );

  static const comparison = StreamingWidgetSchema(
    tag: 'MaterialUi.Comparison',
    description: 'Side-by-side product comparison table. Nest ComparisonProduct children.',
    requiredProps: [
      WidgetProp('title'),
      WidgetProp('features', hint: "['Switch','Format']"),
    ],
    childTags: ['MaterialUi.ComparisonProduct'],
    examples: [
      WidgetExample(
        """<MaterialUi.Comparison title="Pro Keyboards" features="['Switch','Format']">\n"""
        '  <MaterialUi.ComparisonProduct name="Apex" price="129" Switch="Brown" Format="75%" />\n'
        '  <MaterialUi.ComparisonProduct name="Craft" price="149" Switch="Red" Format="100%" />\n'
        '</MaterialUi.Comparison>',
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // Child-only widgets (nested inside parents; not directly instantiated)
  // ---------------------------------------------------------------------------

  static const carouselItem = StreamingWidgetSchema(
    tag: 'MaterialUi.CarouselItem',
    description: 'A single slide inside a Carousel.',
    requiredProps: [WidgetProp('title')],
    optionalProps: [WidgetProp('imageUrl'), WidgetProp('description')],
  );

  static const forecast = StreamingWidgetSchema(
    tag: 'MaterialUi.Forecast',
    description: 'A single day forecast row inside a Weather widget.',
    requiredProps: [
      WidgetProp('day'),
      WidgetProp('temp'),
      WidgetProp('condition', hint: 'sunny|rainy|cloudy|snowy'),
    ],
  );

  static const todoItem = StreamingWidgetSchema(
    tag: 'MaterialUi.TodoItem',
    description: 'A single checklist item inside a TodoList.',
    requiredProps: [
      WidgetProp('text'),
      WidgetProp('completed', hint: 'true|false'),
    ],
    optionalProps: [
      WidgetProp('dueDate'),
      WidgetProp('priority', hint: 'high|medium|low'),
    ],
  );

  static const listItem = StreamingWidgetSchema(
    tag: 'MaterialUi.ListItem',
    description: 'A single entry inside ListResults.',
    requiredProps: [WidgetProp('title')],
    optionalProps: [
      WidgetProp('subtitle'),
      WidgetProp('icon', hint: 'pdf|image|file|folder'),
      WidgetProp('date'),
      WidgetProp('size'),
    ],
  );

  static const comparisonProduct = StreamingWidgetSchema(
    tag: 'MaterialUi.ComparisonProduct',
    description: 'A product column inside a Comparison table.',
    requiredProps: [
      WidgetProp('name'),
      WidgetProp('price'),
    ],
    optionalProps: [WidgetProp('rating')],
  );

  // ---------------------------------------------------------------------------
  // Catalog lists
  // ---------------------------------------------------------------------------

  /// All top-level widgets the model can directly instantiate.
  static const List<StreamingWidgetSchema> all = [
    card,
    userProfile,
    carousel,
    weather,
    graph,
    webResult,
    productResult,
    location,
    todoList,
    note,
    listResults,
    comparison,
  ];

  /// Child-only widgets, nested inside their respective parent tags.
  static const List<StreamingWidgetSchema> children = [
    carouselItem,
    forecast,
    todoItem,
    listItem,
    comparisonProduct,
  ];
}
