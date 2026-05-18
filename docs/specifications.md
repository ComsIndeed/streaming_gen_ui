# Streaming Gen Ui Specifications

## Expectations:

### Syntax and Usage

```dart
// The one class you actually need
final genUi = StreamingGenUi(registry: myRegistry);

// Expose the prompt fragment — they inject it wherever they want
final prompt = genUi.systemPrompt;

// They call their LLM however they want, then pipe the stream in
await genUi.stream(response, surfaceId: 'side-panel');  // Flowserract case
await genUi.stream(response, surfaceId: 'message-42');  // Chat bubble case
await genUi.stream(response, surfaceId: 'global-modal'); // Global action case

// Get final parsed data after completion (e.g. to save to DB)
final data = genUi.getSurfaceData('message-42');

// Restore from saved data — internally just streams it as an instant single-value stream
genUi.restore(surfaceId: 'message-42', data: savedJson);

// Cleanup when a surface is permanently gone (e.g. chat cleared, logout)
genUi.disposeSurface('message-42');

// They place the surface widget wherever they want in their tree
GenUiSurface(controller: genUi, id: 'side-panel')
GenUiSurface(controller: genUi, id: 'message-42')
GenUiSurface(controller: genUi, id: 'global-modal')
```

- On initialize, they handle what UIs to register (or they use our prepackaged
  ones)
- The developer will handle the chat history, calling the LLM, displaying the
  text, etc.
- We handle the:
- Providing of prompt fragment
- Parsing of the AI's stream response provided
- Piping the parsed UI on the surface ID they provided
- Displaying the UI of a surface ID requested

Basically: We give them a prompt fragment, they share us the response and which
surface we pipe the UI to, and we display the UI of a surface ID requested.
