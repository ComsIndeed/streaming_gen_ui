# Streaming Gen Ui Specifications

## Expectations:

### Syntax and Usage

```dart
// The one class you actually need
final genUi = StreamingGenUi(registry: myRegistry);

// Expose the prompt fragment — they inject it wherever they want
final prompt = genUi.systemPrompt;

// They call their LLM however they want, then pipe the stream in
await genUi.stream(response, viewId: 'side-panel');  // Flowserract case
await genUi.stream(response, viewId: 'message-42');  // Chat bubble case
await genUi.stream(response, viewId: 'global-modal'); // Global action case

// Get final parsed data after completion (e.g. to save to DB)
final data = genUi.getViewData('message-42');

// Restore from saved data — internally just streams it as an instant single-value stream
genUi.restore(viewId: 'message-42', data: savedJson);

// Cleanup when a view is permanently gone (e.g. chat cleared, logout)
genUi.disposeView('message-42');

// They place the view widget wherever they want in their tree
genUi.view('side-panel')
genUi.view('message-42')
genUi.view('global-modal')
```

- On initialize, they handle what UIs to register (or they use our prepackaged
  ones)
- The developer will handle the chat history, calling the LLM, displaying the
  text, etc.
- We handle the:
- Providing of prompt fragment
- Parsing of the AI's stream response provided
- Piping the parsed UI on the view ID they provided
- Displaying the UI of a view ID requested

Basically: We give them a prompt fragment, they share us the response and which
view we pipe the UI to, and we display the UI of a view ID requested.

Cases:

- If unknown widget, allow an onUnknownWidget handler, default to error widget.

### JSON Schema & Protocal

A widget JSON type will have the following JSON structure:

```json
{
  "namespace": name here,
  
  ... (specific properties follows)
}
```

Example:

```json
{
  "namespace": "core:text",
  "text": "A property specific to 'core:text'"
}

or 

{
  "namespace": "core:column",
  "children": [
    {
      "namespace": "core:text",
      "text": "Do not press the button!",
    },
    {
      "namespace": "core:elevated_button",
      "child": {
        "namespace": "core:text",
        "text": "The button."
      }
    }
  ]
}
```

We use flat maps for each widget, no nesting. This allows for nesting to only
mean the widgets are nesting.

### Built-In & Custom Registries

On our built-in types, we create IDs for each widgets and don't sort them yet.

Then we finally package them by category and use. Some widget collections may
overlap with one another, which would've typically caused duplicate entries and
prompting, but the ID system would allow a fix for that.

The ID system will also serve as the namespacing system. The ID format is:

`<provider>:name_in_snake_case` (like Minecraft lol)

All the built-in widgets will have the provider as `core`

Alpha V1 Built-In Widget Registry:

- Text, Button, Column, Row, Container, Textfield,

### User Interactivity on the UIs

<!-- TODO -->
