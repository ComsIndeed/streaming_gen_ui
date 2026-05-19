class ExampleData {
  final String name;
  final String content;

  ExampleData({required this.name, required this.content});
}

final List<ExampleData> mockExamples = [
  ExampleData(
    name: 'Level 1: Simple Leaf Text',
    content: 'Below is a simple streamed text component:\n\n<interface>{"namespace":"core:text","content":"Hello from the real-time generative stream!"}</interface>\n\nHope you enjoyed it!',
  ),
  ExampleData(
    name: 'Level 2: Dynamic Action Button',
    content: 'Press this button to trigger an action:\n\n<interface>{"namespace":"core:elevated_button","child":{"namespace":"core:text","content":"Submit Survey"},"action":"submit_survey_action"}</interface>\n\nNote that the button turns interactive the instant the action property is parsed.',
  ),
  ExampleData(
    name: 'Level 3: Live Input TextField',
    content: 'Type your feedback here:\n\n<interface>{"namespace":"core:textfield","placeholder":"Search for hotels...","action":"search_hotels_action"}</interface>\n\nPlease enter a search query.',
  ),
  ExampleData(
    name: 'Level 4: Compound Animated Layout',
    content: 'Here is a Column with a colored Container:\n\n<interface>{"namespace":"core:column","children":[{"namespace":"core:container","width":200,"height":100,"color":"#ff5500","child":{"namespace":"core:text","content":"Inside Container!"}},{"namespace":"core:text","content":"Directly under the container!"}]}</interface>\n\nAll sub-properties resolve in sequence.',
  ),
];
