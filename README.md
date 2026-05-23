# streaming_gen_ui

### The Streaming Generative UI Engine for Flutter

Render interactive Flutter widgets progressively as raw LLM token streams flow
in — character-by-character — without waiting for a complete JSON response.

[![pub.dev](https://img.shields.io/pub/v/streaming_gen_ui.svg)](https://pub.dev/packages/streaming_gen_ui)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

[API Docs](https://pub.dev/documentation/streaming_gen_ui/latest/) ·
[GitHub](https://github.com/ComsIndeed/streaming-gen-ui) ·
[Widget Catalog](https://streaming-gen-ui.web.app)

---

## The Problem

When an LLM outputs a UI as JSON, you're typically forced to:

1. Wait for the **entire JSON payload** to finish generating
2. `jsonDecode()` it all at once
3. Build the widget tree in a single frame — everything pops in at once

For long or complex widgets, this means a multi-second blank spinner followed by
a jarring layout snap.

## The Solution

`streaming_gen_ui` parses and renders widgets **as tokens arrive**. Text streams
in like a typewriter. Nested widgets mount and fill in progressively. Buttons
start disabled and activate the millisecond their action property resolves. No
waiting. No pop-in.

Mix conversational Markdown text and dynamic UI components freely in the same
stream — the engine separates and renders them in the correct chronological
order automatically.

---

## Quick Start

```yaml
dependencies:
  streaming_gen_ui: ^0.1.0
```

```dart
import 'package:streaming_gen_ui/streaming_gen_ui.dart';

// 1. Instantiate with registries
final genUi = StreamingGenerativeUi(
  registries: [Registries.essentials],
);

// 2. Inject the auto-generated prompt fragment into your LLM system prompt
final systemPrompt = genUi.registry.systemPromptFragment;

// 3. Pipe the live token stream in
await genUi.stream(
  llmTokenStream,
  viewId: 'message-42',
  onComplete: (raw) => db.save(raw),
);

// 4. Place the reactive view anywhere in your widget tree
genUi.view('message-42')
```

The LLM wraps UI components in `<interface>` tags anywhere in its response:

```
Here's the profile card you asked for:

<interface>{"namespace":"core:card","child":{"namespace":"core:column","children":[
  {"namespace":"core:text","content":"Vincent"},
  {"namespace":"core:elevated_button","child":{"namespace":"core:text","content":"Save"},"action":"save_profile"}
]}}</interface>

Let me know if you'd like any changes!
```

The text renders as Markdown. The widget renders progressively. Both appear in
order.

---

## Features

### Widget-by-Widget Streaming

Widgets mount immediately and fill in their properties as tokens arrive. Parent containers do not wait for children, and children do not wait for siblings—the entire layout compiles and grows incrementally.

### Disabled-to-Active Button Transmutation

Interactive elements (buttons, inputs) are drawn immediately in a disabled state during streaming to maintain layout stability. The exact millisecond their action properties resolve in the stream, they animate into an active state with a micro-bounce transition.

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

Registering your own custom widget is extremely easy using the `fromDefinition` named constructor:

```dart
final myRegistry = WidgetRegistry.fromDefinition(
  id: "custom:user_card",
  description: "A profile summary card.",
  properties: {
    "name": "String",
    "role": "String",
  },
  builder: (context, props) => Card(
    child: Column(
      children: [
        StreamingText(props: props, propertyName: 'name'),
        StreamingText(props: props, propertyName: 'role'),
      ],
    ),
  ),
);

// Drop it seamlessly into the registries list
final genUi = StreamingGenerativeUi(
  registries: [Registries.essentials, myRegistry],
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

| Member                                                                | Description                                 |
| :-------------------------------------------------------------------- | :------------------------------------------ |
| `StreamingGenerativeUi({required registries, showInternalErrors})`  | Instantiate the engine                      |
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
