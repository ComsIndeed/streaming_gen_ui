# streaming_gen_ui Example

> ⚠️ **WORK IN PROGRESS** - This example will be expanded as the package develops.

## Overview

The streaming_gen_ui package enables real-time streaming of JSON data from LLMs into Flutter widgets.

## Quick Start

```dart
import 'package:streaming_gen_ui/streaming_gen_ui.dart';
import 'package:llm_json_stream/llm_json_stream.dart';

// Create a UI streamer instance
final streamer = UiStreamer();

// Process streaming JSON data
void processStream(MapPropertyStream stream) {
  streamer.input(stream);
  final output = streamer.output;
  
  // Use in your Flutter UI
  return Scaffold(body: output);
}
```

## Status

This example is under development. Check back soon for a complete working example!

## Learn More

- [README](../README.md)
- [GitHub Repository](https://github.com/ComsIndeed/streaming_gen_ui)
- [llm_json_stream Package](https://pub.dev/packages/llm_json_stream)

---

**Author**: Vincent Sanicolas  
**License**: MIT
