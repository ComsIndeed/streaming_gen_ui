# streaming_gen_ui# streaming_gen_ui# streaming_gen_ui<!--



> ⚠️ **WORK IN PROGRESS** - This package is under active development. APIs may change between releases. Use at your own risk.



A powerful Dart package for streaming and decoding JSON data from Large Language Models (LLMs) in real-time, with built-in support for converting streamed data into Flutter widgets.A powerful Dart package for streaming and decoding JSON data from Large Language Models (LLMs) in real-time, with built-in support for converting streamed data into Flutter widgets.This README describes the package. If you publish this package to pub.dev,



## Features



- 🚀 **Real-time JSON Streaming**: Process JSON data as it streams from LLM APIs## FeaturesA powerful Dart package for streaming and decoding JSON data from Large Language Models (LLMs) in real-time, with built-in support for converting streamed data into Flutter widgets.this README's contents appear on the landing page for your package.

- 🎨 **Widget Generation**: Convert streamed JSON into Flutter widgets dynamically

- 📦 **Easy Integration**: Simple APIs for integrating with your Flutter applications

- ⚡ **Performance Optimized**: Built for efficiency and low latency

- 🔧 **Extensible**: Create custom decoders and widgets for your specific needs- 🚀 **Real-time JSON Streaming**: Process JSON data as it streams from LLM APIs



## Status- 🎨 **Widget Generation**: Convert streamed JSON into Flutter widgets dynamically



🚧 This package is in **early development**. The API is subject to change as we work toward a stable v1.0 release.- 📦 **Easy Integration**: Simple APIs for integrating with your Flutter applications## FeaturesFor information about how to write a good package README, see the guide for



## Getting Started- ⚡ **Performance Optimized**: Built for efficiency and low latency



### Prerequisites- 🔧 **Extensible**: Create custom decoders and widgets for your specific needs[writing package pages](https://dart.dev/tools/pub/writing-package-pages).



- Dart SDK: ^3.10.1

- Flutter SDK: >=1.17.0 (for Flutter widget features)

## Getting started- 🚀 **Real-time JSON Streaming**: Process JSON data as it streams from LLM APIs

### Installation



Add this to your `pubspec.yaml`:

### Prerequisites- 🎨 **Widget Generation**: Convert streamed JSON into Flutter widgets dynamicallyFor general information about developing packages, see the Dart guide for

```yaml

dependencies:

  streaming_gen_ui: ^0.0.1

```- Dart SDK: ^3.10.1- 📦 **Easy Integration**: Simple APIs for integrating with your Flutter applications[creating packages](https://dart.dev/guides/libraries/create-packages)



Then run:- Flutter SDK: >=1.17.0 (for Flutter widget features)



```bash- ⚡ **Performance Optimized**: Built for efficiency and low latencyand the Flutter guide for

flutter pub get

```### Installation



## Usage- 🔧 **Extensible**: Create custom decoders and widgets for your specific needs[developing packages and plugins](https://flutter.dev/to/develop-packages).



### Basic ExampleAdd this to your `pubspec.yaml`:



```dart-->

import 'package:streaming_gen_ui/streaming_gen_ui.dart';

import 'package:llm_json_stream/llm_json_stream.dart';```yaml



// Create a UI streamer instancedependencies:## Getting started

final streamer = UiStreamer();

  streaming_gen_ui: ^0.0.1

// Process streaming JSON data

void processStream(MapPropertyStream stream) {```TODO: Put a short description of the package here that helps potential users

  streamer.input(stream);

  

  // Get the generated widget output

  final output = streamer.output;Then run:### Prerequisitesknow whether this package might be useful for them.

  

  // Use the output in your Flutter UI

  return Scaffold(

    body: output,```bash

  );

}flutter pub get

```

```- Dart SDK: ^3.10.1## Features

### Using StreamingWidgetDecoder



```dart

import 'package:streaming_gen_ui/src/json_decoder.dart';## Usage- Flutter SDK: >=1.17.0 (for Flutter widget features)



final decoder = StreamingWidgetDecoder(mapPropertyStream);

// Process and decode the streaming data

```### Basic ExampleTODO: List what your package can do. Maybe include images, gifs, or videos.



## Core Components



### UiStreamer```dart### Installation



Handles the streaming of UI data and manages widget output state.import 'package:streaming_gen_ui/streaming_gen_ui.dart';



- `input(MapPropertyStream)` - Feed streaming data into the streamerimport 'package:llm_json_stream/llm_json_stream.dart';## Getting started

- `output` - Get the current widget output



### StreamingWidgetDecoder

// Create a UI streamer instanceAdd this to your `pubspec.yaml`:

Decodes streaming JSON data into structured widget configurations.

final streamer = UiStreamer();

- Integrates with `llm_json_stream` for seamless LLM output handling

- Extensible decoder architecture for custom widget typesTODO: List prerequisites and provide or point to information on how to



## Roadmap// Process streaming JSON data



This package is still in early development. Here's what's planned:void processStream(MapPropertyStream stream) {```yamlstart using the package.



- [ ] Stable API design  streamer.input(stream);

- [ ] Comprehensive widget support

- [ ] Performance optimizations  dependencies:

- [ ] Extended documentation

- [ ] v1.0 stable release  // Get the generated widget output



## Examples  final output = streamer.output;  streaming_gen_ui: ^0.0.1## Usage



For a comprehensive example application, see the [streaming_gen_ui_catalog](../streaming_gen_ui_catalog/) package, which demonstrates real-world usage patterns.  



## Contributing  // Use the output in your Flutter UI```



Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.  return Scaffold(



## Issues    body: output,TODO: Include short and useful examples for package users. Add longer examples



If you encounter any issues, please report them on [GitHub Issues](https://github.com/ComsIndeed/streaming_gen_ui/issues).  );



## License}Then run:to `/example` folder.



This package is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.```



## Support



- **Documentation**: See the inline code documentation### Using StreamingWidgetDecoder

- **Examples**: Check the [streaming_gen_ui_catalog](../streaming_gen_ui_catalog/) app for practical examples

- **Issues**: Report problems on [GitHub](https://github.com/ComsIndeed/streaming_gen_ui/issues)```bash```dart



---```dart



**Author**: Vincent Sanicolas  import 'package:streaming_gen_ui/src/json_decoder.dart';flutter pub getconst like = 'sample';

**Status**: Work in Progress (WIP)  

**License**: MIT


final decoder = StreamingWidgetDecoder(mapPropertyStream);``````

// Process and decode the streaming data

```



## Core Components## Usage## Additional information



### UiStreamer



Handles the streaming of UI data and manages widget output state.### Basic ExampleTODO: Tell users more about the package: where to find more information, how to



- `input(MapPropertyStream)` - Feed streaming data into the streamercontribute to the package, how to file issues, what response they can expect

- `output` - Get the current widget output

```dartfrom the package authors, and more.

### StreamingWidgetDecoder

import 'package:streaming_gen_ui/streaming_gen_ui.dart';

Decodes streaming JSON data into structured widget configurations.import 'package:llm_json_stream/llm_json_stream.dart';



- Integrates with `llm_json_stream` for seamless LLM output handling// Create a UI streamer instance

- Extensible decoder architecture for custom widget typesfinal streamer = UiStreamer();



## Examples// Process streaming JSON data

void processStream(MapPropertyStream stream) {

For a comprehensive example application, see the [streaming_gen_ui_catalog](../streaming_gen_ui_catalog/) package, which demonstrates real-world usage patterns.  streamer.input(stream);

  

## Additional information  // Get the generated widget output

  final output = streamer.output;

### Contributing  

  // Use the output in your Flutter UI

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.  return Scaffold(

    body: output,

### Issues  );

}

If you encounter any issues, please report them on [GitHub Issues](https://github.com/ComsIndeed/streaming_gen_ui/issues).```



### License### Using StreamingWidgetDecoder



This package is licensed under the same license as the main repository. See the [LICENSE](./LICENSE) file for details.```dart

import 'package:streaming_gen_ui/src/json_decoder.dart';

### Support

final decoder = StreamingWidgetDecoder(mapPropertyStream);

- **Documentation**: See the inline code documentation// Process and decode the streaming data

- **Examples**: Check the [streaming_gen_ui_catalog](../streaming_gen_ui_catalog/) app for practical examples```

- **Issues**: Report problems on [GitHub](https://github.com/ComsIndeed/streaming_gen_ui/issues)

## Core Components

### UiStreamer
Handles the streaming of UI data and manages widget output state.

- `input(MapPropertyStream)` - Feed streaming data into the streamer
- `output` - Get the current widget output

### StreamingWidgetDecoder
Decodes streaming JSON data into structured widget configurations.

- Integrates with `llm_json_stream` for seamless LLM output handling
- Extensible decoder architecture for custom widget types

## Examples

For a comprehensive example application, see the [streaming_gen_ui_catalog](../streaming_gen_ui_catalog/) package, which demonstrates real-world usage patterns.

## Additional information

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Issues

If you encounter any issues, please report them on [GitHub Issues](https://github.com/ComsIndeed/streaming_gen_ui/issues).

### License

This package is licensed under the same license as the main repository. See the [LICENSE](./LICENSE) file for details.

### Support

- **Documentation**: See the inline code documentation
- **Examples**: Check the [streaming_gen_ui_catalog](../streaming_gen_ui_catalog/) app for practical examples
- **Issues**: Report problems on [GitHub](https://github.com/ComsIndeed/streaming_gen_ui/issues)
