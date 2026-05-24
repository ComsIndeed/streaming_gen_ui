<div align="center">

# Streaming Generative UI

### The Streaming Generative UI Engine for Flutter

Render widgets progressively as LLM streams flow in character-by-character
without waiting for a complete JSON response.

[![pub.dev](https://img.shields.io/pub/v/streaming_gen_ui.svg)](https://pub.dev/packages/streaming_gen_ui)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

![streaming_gen_ui in action](https://raw.githubusercontent.com/ComsIndeed/streaming_gen_ui/main/doc/gifs/output/chat-demo-1_small.gif)

[Widget Catalog](https://streaming.vincentsanicolas.me) ·
[AI Chat Demo](https://streaming.vincentsanicolas.me/?page=chat)

</div>

> ## NOTE:
>
> This package only renders text streams from LLMs into Flutter widgets/text. It
> does not manage conversations, pipelines, or tooling.
>
> Just `Stream<String>` in → `Widget` out.

## Why `streaming_gen_ui`?

- **[Generative UI](#generative-ui)** - No more walls of text, mix in some
  interfaces.
- **[Streaming Support](#streaming-support)** - Progressively render UI as it
  streams from the LLM.
- **[Render Anywhere](#render-anywhere)** - Place views elsewhere, instruct LLM
  to render there.
- **[Easy Display](#easy-display)** - By default, render normal response
  markdown with UI.
- **[Simple & Flexible APIs](#simple--flexible-apis)** - Set up however wanted,
  easy to use.
- **[Platform/Framework Agnostic](#platformframework-agnostic)** -
  `Stream<String>` in, `Widget` out.
- **[Batteries Included](#batteries-included)** - Includes lightweight prebuilt
  registries of widgets.
- **[Pre-Built Themes](#pre-built-themes)** - Includes pre-built themed widgets.
- **[Easy Composition](#easy-composition)** - Easily create your own widgets.

> ## ⚠️ Under Active Development
>
> Things may break. APIs may change. Bugs may occur.
>
> But hey, feedback, bug reports, and ideas are genuinely appreciated 💙

## Features

### Generative UI

No more walls of text. Mix in some visuals.

![Walls of text vs mixed with Widgets](https://raw.githubusercontent.com/ComsIndeed/streaming_gen_ui/main/doc/gifs/output/comparison-demo_large.gif)

Elevate standard text-based conversational interfaces. Instead of presenting a
long wall of static text, seamlessly mix in rich, interactive components (like
profile cards, charts, accordion carousels, or metric tiles) that bring your
application to life.

### Streaming Support

No waiting for full schema to generate. We've got incremental parsers, just
render immediately!

![Streaming in action](https://raw.githubusercontent.com/ComsIndeed/streaming_gen_ui/main/doc/gifs/output/clean-mechanics-demo.gif)

Most generative UI packages require you to wait for the complete JSON payload
before decoding and popping the final widget tree onto the screen.
`streaming_gen_ui` progressively parses and renders widgets
_character-by-character_ as the tokens arrive. Buttons start disabled and
transition to active instantly with organic spring animations once their
handlers load.

### Render Anywhere

![Rendering in a different view](https://raw.githubusercontent.com/ComsIndeed/streaming_gen_ui/main/doc/gifs/output/canvas-demo_medium.gif)

Direct the LLM to render specific layouts or controls in custom areas of your
screen (e.g., a dedicated full-screen Canvas or tool panel) rather than the
standard sequential chat thread. Simply define a mapping of custom view IDs and
watch them update reactively.

### Easy Display

Both the LLM's markdown and generated widgets can render in order easily,
progressively displayed.

![streaming_gen_ui in action](https://raw.githubusercontent.com/ComsIndeed/streaming_gen_ui/main/doc/gifs/output/chat-demo-1_small.gif)

Seamlessly blend markdown responses and interfaces. The streaming engine parses
`<interface>` tags out of the stream automatically, keeping the response clean
and displaying markdown blocks alongside active widgets in chronological order.

### Simple & Flexible APIs

Easy developer experience designed for minimal friction with maximum
flexibility.

Simple how? Three steps:

1. Initialize your `StreamingGenerativeUi` class and include registries
2. Include generated prompt to LLM `systemInstructions`
3. Feed LLM response to your class via `.stream(stream, id)`.
4. Display the view via `.view(id)` from your class.

Flexible how?

1. It's just `Stream<String> --> Text + Widgets`.
2. Place views anywhere, instruct LLM to render somewhere.
3. Easy custom **streaming** widget creation.
4. You handle your conversations, persistence, and everything else. This handles
   the rendering.

### Platform/Framework Agnostic

No vendor lock-in. Whether you are using Gemini, Claude, OpenRouter, or local
models via Ollama/llama.cpp, the engine works entirely on standard inputs.
Simply feed a `Stream<String>` of raw tokens in, and get responsive,
state-managed Flutter `Widget` outputs out.

### Batteries Included

Comes packed with built-in and themed widget registries:
![Themes Demo](https://raw.githubusercontent.com/ComsIndeed/streaming_gen_ui/main/doc/gifs/output/theme-demo_small.gif)

And a whole lot more:
![Widget Catalog Demo](https://raw.githubusercontent.com/ComsIndeed/streaming_gen_ui/main/doc/gifs/output/widget-catalog-demo_large.gif)

### Pre-Built Themes

### Easy Composition

Define individual custom widgets inline using `WidgetRegistry.fromDefinition` or
bundle them into custom registries. The package automatically computes the LLM's
system prompt instructions (`systemPrompt`) and even auto-generates compliant
mock JSON examples if they are omitted, leaving you with zero boilerplate to
maintain!

## Quick Setup

```dart
import 'package:streaming_gen_ui/streaming_gen_ui.dart';

// Create instance, use registries (or custom widgets)
final streamingGenUi = StreamingGenerativeUi(
  registries: [Registries.material, Registries.core],
);

// Include generated prompt in instructions
final responseStream = Llm.sendMessageStream(
  message: 'Most durable laptops on the market?',
  systemPrompt:
      'You are a helpful assistant.\n${streamingGenUi.systemPrompt}',
);

// Stream response to target view
streamingGenUi.stream(responseStream, viewId: 'msg-box-1');

// Render response + widgets in view
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      const Text('AI Assistant'),
      streamingGenUi.view('msg-box-1'),
    ],
  );
}
```

## Contributing

Contributions are welcome (even new widgets on the catalog).

1. Check [open issues](https://github.com/ComsIndeed/streaming-gen-ui/issues)
   before starting
2. Discuss major changes in an issue first
3. Run `flutter test` before submitting a PR
4. New registry widgets should include a `description`, `properties`, and a
   working `jsonExample`

---

## License

MIT — see [LICENSE](LICENSE) for details.
