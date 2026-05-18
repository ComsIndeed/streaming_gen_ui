# Streaming Gen Ui Specifications

## Expectations:

### Syntax and Usage

The intended minimal use:

```dart
// ─────────────────────────────────────────────
// INTENDED USAGE
// ─────────────────────────────────────────────

// Setup
final genUi = StreamingGenUi(registry: myRegistry);

// Inject the prompt fragment into your LLM system prompt however you want
final systemPrompt = genUi.systemPrompt;

// Pipe the LLM response stream in, save raw response on completion
await genUi.stream(
  llmStream,
  viewId: 'message-42',
  onComplete: (raw) => db.save(raw),
);

// Restore a past response from DB
genUi.restore(viewId: 'message-42', raw: db.load('message-42'));

// Place the view anywhere in your widget tree
genUi.view('message-42')

// Cleanup when permanently gone
genUi.disposeView('message-42');
```

Full API being demonstrated:

```dart
// ─────────────────────────────────────────────
// FULL API
// ─────────────────────────────────────────────

// Setup
final genUi = StreamingGenUi(registry: myRegistry);

// System prompt fragment to inject into your LLM
final systemPrompt = genUi.systemPrompt;

// Stream — all parameters
await genUi.stream(
  llmStream,
  viewId: 'side-panel',          // optional — omit if only using callbacks
  onText: (chunk) => ...,        // text portions only, tags stripped, as they stream
  onComplete: (raw) => ...,      // full raw response (text + tags) for DB storage
);

// Multiple views from one response via <interface viewId="..."> tags
// The LLM can target any mounted view by its ID in the tag itself
await genUi.stream(
  llmStream,
  viewId: 'message-42',          // default target for untagged <interface> blocks
  onText: (chunk) => ...,
  onComplete: (raw) => db.save(raw),
);

// Restore from saved raw response
genUi.restore(viewId: 'message-42', raw: savedRawString);

// Place views anywhere in the widget tree
genUi.view('side-panel')         // Flowserract side panel case
genUi.view('message-42')         // Chat bubble case  
genUi.view('global-modal')       // Global action case

// Cleanup
genUi.disposeView('message-42');
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

The model is instructed to respond normally using natural conversational
language. At any point in the stream—whether between paragraphs or inline—the
model can seamlessly embed a dynamic UI widget tree by enclosing a valid JSON
payload within custom `<interface>` and `</interface>` tags. The streaming
parser isolates these tagged blocks to render the visual UI components
on-the-fly, while treating all content outside of them as standard markdown or
text.

### Streaming View & Target Routing Modes

When the LLM streams its response, there are two layout modes based on the tags:

#### 1. Single-View / Inline Chat Mode (Default)

If the model streams an untagged `<interface>` block (meaning no `viewId` attribute is provided on the XML tag itself), all elements are rendered on the default view specified in `genUi.stream(...)`.

- The `.view('message-42')` widget handles the entire layout sandwich.
- It displays the preceding text, followed by the active dynamic widget, followed by the succeeding text.
- Conversational text portions are automatically rendered in standard Markdown.

#### 2. Multi-View / Target-Routed Mode

If the model streams an interface block targeting a specific view (e.g. `<interface viewId="side-panel">`), the engine splits and routes the widgets dynamically.

- The default stream view (like the active chat bubble) only displays the conversational text.
- The target view container (mounted elsewhere via `genUi.view('side-panel')`) dynamically catches and compiles the dynamic widget layout on-the-fly.
- Allows the LLM to control multiple separate layout zones across your application.

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

### Streaming Generative Architecture (`llm_json_stream` Integration)

The package is powered by `llm_json_stream` under the hood. Instead of decoding static maps on completion, we digest tokens and build/update widgets progressively in real-time.

This changes the `.register()` method's signature. Instead of static JSON maps, builders receive reactive property stream containers:

```dart
// The stream-aware builder signature
void register(String namespace, Widget Function(MapPropertyStream mapStream) builder)
```

#### 1. Hierarchical Prop Passing (Recursive Stream Passing)

For nested layouts, we extract the `MapPropertyStream` or `ListPropertyStream` of sub-properties and pass them recursively down the child widget trees.

- Parents don't wait for the child block to finish.
- They immediately mount the child widget, passing its dedicated sub-stream down for self-reactive updating.

#### 2. The Accumulating String Builder

To keep text typing continuously without flickering or losing context, standard text widgets utilize an accumulating string builder that progressively grows on every text token chunk.

#### 3. Dynamic Action Activation (Disabled-to-Enabled Transitions)

Buttons and inputs start in a disabled state (`onPressed = null` / greyed out) when first painted.

- We listen to the action future via `mapStream.getStringProperty('action').future`.
- The exact millisecond the LLM finishes streaming the button's action payload, the callback resolves, setting the onPressed method.
- The button dynamically transitions from disabled (grey/inactive) to fully interactive in real-time.

### User Interactivity on the UIs

- Interactivity actions (like form submissions or button clicks) are mapped back to the application using a centralized action dispatcher.
- Developers register active action callbacks inside the `StreamingGenUi` controller to listen to user interactions triggered by dynamic screens.
