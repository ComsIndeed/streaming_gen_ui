class ExampleData {
  final String category;
  final String name;
  final String content;

  ExampleData({
    required this.category,
    required this.name,
    required this.content,
  });
}

final List<ExampleData> mockExamples = [
  // ── Category 1: Core Mechanics ──────────────────────────────────
  ExampleData(
    category: 'Core Mechanics',
    name: 'Generative UI (Inline Widgets)',
    content:
        'Below is a standard conversational reply but with an interactive profile card inline:\n\n<interface>{"namespace":"core:profile_card","name":"Antigravity AI","avatarUrl":"https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe","bio":"State-of-the-art AI assistant for Flutter.","theme":"brutalist"}</interface>\n\nLet me know if you want to modify this card!',
  ),
  ExampleData(
    category: 'Core Mechanics',
    name: 'Streaming Support (Progressive Activation)',
    content:
        'Interactive button that starts disabled and unlocks progressively as action loads:\n\n<interface>{"namespace":"core:elevated_button","child":{"namespace":"core:text","content":"Start Engine"},"action":"start_engine_action"}</interface>\n\nNotice that the button turns interactive the instant the action property is parsed.',
  ),
  ExampleData(
    category: 'Core Mechanics',
    name: 'Render Anywhere (Dedicated Canvas)',
    content:
        'Directing layout output into a dedicated "playground-view" instead of the current chat page:\n\n<interface view="playground-view">{"namespace":"core:container","width":250,"height":150,"color":"#3b82f6","child":{"namespace":"core:text","content":"Rendering directly on the Canvas!"}}</interface>\n\nNotice that this widget rendered completely inside the right-hand panel instead of in-line!',
  ),
  ExampleData(
    category: 'Core Mechanics',
    name: 'Easy Display (Inline Markdown & Widgets)',
    content:
        '### Introduction\nThis is a markdown heading. Below is an inline chip widget:\n\n<interface>{"namespace":"core:chip","label":"Flutter Premium","color":"#8b5cf6"}</interface>\n\n### Conclusion\nAll in a single message stream! Automatically parsed and seamlessly placed.',
  ),

  // ── Category 2: Batteries Included ──────────────────────────────
  ExampleData(
    category: 'Batteries Included',
    name: 'Layout Registry (Column, Spacer, Container)',
    content:
        'Showcasing row, column, spacer, and container:\n\n<interface>{"namespace":"core:column","children":[{"namespace":"core:text","content":"Row Layout Example:"},{"namespace":"core:row","children":[{"namespace":"core:container","width":50,"height":50,"color":"#ef4444"},{"namespace":"core:spacer"},{"namespace":"core:container","width":50,"height":50,"color":"#10b981"}]}]}</interface>',
  ),
  ExampleData(
    category: 'Batteries Included',
    name: 'Display Registry (Heading, Text, Badge)',
    content:
        'Showcasing heading, text, badge, and chip:\n\n<interface>{"namespace":"core:column","children":[{"namespace":"core:heading","text":"Premium Showcase","level":2},{"namespace":"core:badge","label":"Hot Update","color":"#f59e0b"}]}</interface>',
  ),
  ExampleData(
    category: 'Batteries Included',
    name: 'Cards Registry (KeyValueCard, ListTile)',
    content:
        'Showcasing card and key_value_card:\n\n<interface>{"namespace":"core:key_value_card","title":"Server Telemetry","pairs":{"CPU":"87%","RAM":"12.4GB / 16GB","Status":"OPTIMAL"}}</interface>',
  ),
  ExampleData(
    category: 'Batteries Included',
    name: 'Dashboard Registry (MetricTile, ChartBar)',
    content:
        'Showcasing metrics and charts:\n\n<interface>{"namespace":"core:column","children":[{"namespace":"core:metric_tile","title":"Total Revenue","value":"\$142,500","change":"+18.2%"},{"namespace":"core:chart_bar","values":[12,34,56,23,89],"labels":["Mon","Tue","Wed","Thu","Fri"]}]}</interface>',
  ),

  // ── Category 3: Pre-Built Themes ─────────────────────────────────
  ExampleData(
    category: 'Pre-Built Themes',
    name: 'Neumorphic Theme (Dual Light Shadow)',
    content:
        'Pillowy soft neumorphic profile card:\n\n<interface>{"namespace":"core:profile_card","name":"Neumorphic Card","avatarUrl":"https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5","bio":"A beautiful soft-shadowed design system.","theme":"neumorphic"}</interface>',
  ),
  ExampleData(
    category: 'Pre-Built Themes',
    name: 'Brutalist Theme (Flat Shadow High Contrast)',
    content:
        'Aggressive borders and high contrast brutalist card:\n\n<interface>{"namespace":"core:profile_card","name":"Brutalist Card","avatarUrl":"https://images.unsplash.com/photo-1541701494587-cb58502866ab","bio":"Aggressive borders, flat shadows.","theme":"brutalist"}</interface>',
  ),
  ExampleData(
    category: 'Pre-Built Themes',
    name: 'Skeuomorphic Theme (3D Gloss Bevel)',
    content:
        'Old-school 3D glossy extruded skeuomorphic card:\n\n<interface>{"namespace":"core:profile_card","name":"Skeuomorphic Card","avatarUrl":"https://images.unsplash.com/photo-1507525428034-b723cf961d3e","bio":"Glossy bevels, real-world materials.","theme":"skeuomorphic"}</interface>',
  ),

  // ── Category 4: Custom Composition ──────────────────────────────
  ExampleData(
    category: 'Custom Composition',
    name: 'Custom Domain Widgets',
    content:
        'Rendering custom domain widgets registered under a custom namespace:\n\n<interface>{"namespace":"core:column","children":[{"namespace":"custom:user_profile","name":"Vincent Sanicolas","role":"Senior Architect","themeColor":"#3b82f6"},{"namespace":"custom:hotel_card","title":"🏨 Le Bristol Paris","description":"A beautiful palace hotel.","rating":"4.9"}]}</interface>',
  ),
];
