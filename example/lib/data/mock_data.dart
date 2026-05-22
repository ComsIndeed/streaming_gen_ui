class ExampleData {
  final String name;
  final String content;

  ExampleData({required this.name, required this.content});
}

final List<ExampleData> mockExamples = [
  ExampleData(
    name: 'Level 1: Simple Leaf Text',
    content:
        'Below is a simple streamed text component:\n\n<interface>{"namespace":"core:text","content":"Hello from the real-time generative stream!"}</interface>\n\nHope you enjoyed it!',
  ),
  ExampleData(
    name: 'Level 2: Dynamic Action Button',
    content:
        'Press this button to trigger an action:\n\n<interface>{"namespace":"core:elevated_button","child":{"namespace":"core:text","content":"Submit Survey"},"action":"submit_survey_action"}</interface>\n\nNote that the button turns interactive the instant the action property is parsed.',
  ),
  ExampleData(
    name: 'Level 3: Live Input TextField',
    content:
        'Type your feedback here:\n\n<interface>{"namespace":"core:textfield","placeholder":"Search for hotels...","action":"search_hotels_action"}</interface>\n\nPlease enter a search query.',
  ),
  ExampleData(
    name: 'Level 4: Compound Animated Layout',
    content:
        'Here is a Column with a colored Container:\n\n<interface>{"namespace":"core:column","children":[{"namespace":"core:container","child":{"namespace":"core:text","content":"Inside Container!"},"width":200,"height":100,"color":"#ff5500"},{"namespace":"core:text","content":"Directly under the container!"}]}</interface>\n\nAll sub-properties resolve in sequence.',
  ),
  ExampleData(
    name: 'Level 5: Deeply Nested Column/Row',
    content:
        'Here is a deeply nested real-time layout:\n\n<interface>{"namespace":"core:column","children":[{"namespace":"core:text","content":"🚀 Deep Nesting Example"},{"namespace":"core:container","child":{"namespace":"core:row","children":[{"namespace":"core:text","content":"Status: "},{"namespace":"core:container","child":{"namespace":"core:text","content":" ACTIVE "},"color":"#00aa55"}]},"width":250,"height":60,"color":"#222222"},{"namespace":"core:elevated_button","child":{"namespace":"core:text","content":"Reboot Server"},"action":"reboot_server"}]}</interface>\n\nObserve how rows and columns update reactively.',
  ),
  ExampleData(
    name: 'Level 6: Custom Premium Domain Widgets',
    content:
        'Here is a showcase of custom widgets registered under a custom namespace:\n\n<interface>{"namespace":"core:column","children":[{"namespace":"custom:user_profile","name":"Vincent Sanicolas","role":"Senior Flutter & Web Architect","themeColor":"#3b82f6"},{"namespace":"custom:hotel_card","title":"🏨 Le Bristol Paris","description":"A historic palace hotel featuring a beautiful rooftop pool and 3-star Michelin dining.","rating":"4.9"}]}</interface>\n\nCustom schemas let your LLM emit domain-specific components!',
  ),
];
