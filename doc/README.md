# <center>streaming_gen_ui</center>

### The Streaming Generative UI Engine for Flutter

Render widgets progressively as LLM streams flow in character-by-character
without waiting for a complete JSON response.

[![pub.dev](https://img.shields.io/pub/v/streaming_gen_ui.svg)](https://pub.dev/packages/streaming_gen_ui)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

![streaming_gen_ui in action](https://raw.githubusercontent.com/ComsIndeed/streaming_gen_ui/main/doc/gifs/chat-demo-1_small.gif)

[GitHub](https://github.com/ComsIndeed/streaming-gen-ui) ·
[Widget Catalog](https://streaming.vincentsanicolas.me) ·
[Test](https://streaming.vincentsanicolas.me)

---

---

---

## Features

### Widget-by-Widget Streaming

<!--
  GIF: progressive_build.gif
  Show a core:column with 3 children building itself — each child fades/scales in
  as its JSON is parsed. The parent container grows in height via AnimatedSize.
  About 4 seconds. No interaction needed.
-->

![Progressive widget build](https://raw.githubusercontent.com/ComsIndeed/streaming-gen-ui/main/demos/progressive_build.gif)

Widgets mount immediately and fill in their properties as tokens arrive. Parent
containers don't wait for children. Children don't wait for siblings.

### Disabled-to-Active Button Transmutation

<!--
  GIF: button_activation.gif
  Show a button starting grey and visually muted while text streams into its label.
  The instant the "action" property token arrives, it triggers a micro-bounce and
  morphs to the primary theme color. About 3 seconds. Clean loop.
-->

![Button activation](https://raw.githubusercontent.com/ComsIndeed/streaming-gen-ui/main/demos/button_activation.gif)

Interactive elements (buttons, inputs) are drawn immediately in a disabled
state. The exact millisecond their action property resolves in the stream, they
activate with a micro-bounce transition.

### Self-Documenting Registry

Every widget in the registry carries its own schema and JSON example. The engine
automatically compiles these into a precise LLM system prompt fragment — no
manual prompt maintenance, no drift between what the LLM thinks exists and
what's actually registered.

```dart
// The prompt updates automatically as your registry changes
final systemPrompt = genUi.registry.systemPromptFragment;
```

### Set-Theory Registry Composition

```dart
// Union — combine registries
final registry = Registries.essentials + Registries.dashboard;

// Subtraction — strip what you don't need
final readOnly = Registries.essentials.without(['core:elevated_button', 'core:textfield']);

// Subset — allow only specific widgets
final locked = Registries.essentials.only(['core:text', 'core:card']);
```

### Restore Past Responses

```dart
// Restore a previously saved raw response from your database
genUi.restore(viewId: 'message-42', raw: savedRaw);
```

The view rebuilds identically from the stored string — no re-prompting the LLM.

---

## Built-In Widget Catalog

| Registry               | Widgets                                                                                                                                                      | Use Case                                 |
| :--------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------- |
| `Registries.layout`    | `core:column`, `core:row`, `core:stack`, `core:wrap`, `core:container`, `core:spacer`, `core:divider`                                                        | Structural layout primitives             |
| `Registries.display`   | `core:text`, `core:heading`, `core:label`, `core:badge`, `core:chip`, `core:icon`, `core:avatar`, `core:code_block`                                          | Typography and display                   |
| `Registries.cards`     | `core:card`, `core:stat_card`, `core:profile_card`, `core:list_tile`, `core:key_value_card`, `core:media_card`, `core:timeline_item`, `core:comparison_card` | General-purpose AI response cards        |
| `Registries.status`    | `core:alert`, `core:progress_bar`, `core:progress_ring`, `core:skeleton`, `core:empty_state`                                                                 | Feedback and status indicators           |
| `Registries.advanced`  | `core:terminal_card`, `core:log_viewer`, `core:document_card`, `core:diff_card`, `core:json_viewer`                                                          | Developer tools, agent output, documents |
| `Registries.dashboard` | `core:metric_tile`, `core:chart_bar`, `core:dashboard_header`, `core:dashboard_grid`, `core:dashboard_preset`                                                | Analytics and dashboard layouts          |

**Pre-composed bundles:**

```dart
Registries.base        // layout + display only — minimal prompt cost
Registries.essentials  // base + cards + status — covers most AI chat apps
Registries.full        // everything
```

> Browse all widgets with live streaming previews at the
> **[Widget Catalog →](https://streaming-gen-ui.web.app)**

---

## Custom Widgets

Registering your own widget takes a single `WidgetDefinition`:

```dart
final myRegistry = WidgetRegistry(
  widgets: {
    "custom:user_card": WidgetDefinition(
      description: "A profile summary card.",
      properties: {
        "name": "String — the user's full name",
        "role": "String — their current title",
      },
      jsonExample: '{"namespace":"custom:user_card","name":"Ada Lovelace","role":"Mathematician"}',
      builder: (context, props) => Card(
        child: Column(
          children: [
            StreamingText(props: props, propertyName: 'name'),
            StreamingText(props: props, propertyName: 'role'),
          ],
        ),
      ),
    ),
  },
);

// Merge seamlessly with built-ins
final genUi = StreamingGenerativeUi(
  registry: Registries.essentials + myRegistry,
);
```

`StreamingText` and `StreamingWidget` are exposed publicly so custom widget
builders stay stateless and boilerplate-free.

---

## LLM Provider Setup

### Anthropic

```dart
final tokenStream = anthropic.messages
  .stream(model: 'claude-sonnet-4-20250514', messages: messages)
  .map((event) => event.delta?.text ?? '');

await genUi.stream(tokenStream, viewId: 'view-id');
```

### OpenAI

```dart
final tokenStream = OpenAI.instance.chat
  .createStream(model: 'gpt-4o', messages: messages)
  .map((chunk) => chunk.choices.first.delta.content ?? '');

await genUi.stream(tokenStream, viewId: 'view-id');
```

### Gemini

```dart
final tokenStream = model
  .generateContentStream(content)
  .map((chunk) => chunk.text ?? '');

await genUi.stream(tokenStream, viewId: 'view-id');
```

---

## API Reference

### `StreamingGenerativeUi`

| Member                                                           | Description                                 |
| :--------------------------------------------------------------- | :------------------------------------------ |
| `StreamingGenerativeUi({required registry, showInternalErrors})` | Instantiate the engine                      |
| `stream(tokenStream, {viewId, onText, onComplete})`              | Pipe a live token stream                    |
| `restore({viewId, raw})`                                         | Rebuild a past response from a saved string |
| `view(viewId)`                                                   | Get the reactive widget for a view          |
| `disposeView(viewId)`                                            | Free memory for a view                      |

### `WidgetRegistry`

| Member                          | Description                             |
| :------------------------------ | :-------------------------------------- |
| `registry + other`              | Union — merge two registries            |
| `registry.only(ids)`            | Subset — keep only listed widget IDs    |
| `registry.without(ids)`         | Subtraction — remove listed widget IDs  |
| `registry.systemPromptFragment` | Auto-generated LLM system prompt string |

### Public Leaf Widgets

| Widget            | Description                                                                  |
| :---------------- | :--------------------------------------------------------------------------- |
| `StreamingText`   | Binds to a named property on a `PropertyStream` and renders accumulated text |
| `StreamingWidget` | Resolves a nested child from a sub-property stream into a widget subtree     |

---

## Contributing

Contributions are welcome — especially new widget definitions for the community
catalog.

1. Check [open issues](https://github.com/ComsIndeed/streaming-gen-ui/issues)
   before starting
2. Discuss major changes in an issue first
3. Run `flutter test` before submitting a PR
4. New registry widgets should include a `description`, `properties`, and a
   working `jsonExample`

---

## License

MIT — see [LICENSE](LICENSE) for details.
