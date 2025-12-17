# streaming_gen_ui Monorepo

A comprehensive Dart and Flutter monorepo for building streaming UI components from generative AI outputs. This project demonstrates how to stream and decode JSON data from LLMs in real-time, converting them into Flutter widgets.

## 📦 Packages

### [`streaming_gen_ui`](./streaming_gen_ui/) - Main Package
The core Dart package that handles streaming JSON decoding and UI widget generation from LLM outputs.

- **Purpose**: Provides utilities for decoding streamed JSON data and converting it to Flutter widgets
- **Version**: 0.0.1
- **Key Features**:
  - Real-time JSON streaming support
  - Widget generation from streamed data
  - Integration with LLM JSON stream outputs
- **Dependencies**: `llm_json_stream`, `flutter`
- [Full README](./streaming_gen_ui/README.md)

### [`streaming_gen_ui_catalog`](./streaming_gen_ui_catalog/) - Demo App
A Flutter application that showcases the streaming_gen_ui package in action.

- **Purpose**: Serves as a comprehensive example and testing ground for the streaming UI components
- **Version**: 0.0.1
- **Platforms**: iOS, Android, Web, macOS, Linux, Windows
- [Full README](./streaming_gen_ui_catalog/README.md)

## 🚀 Getting Started

### Prerequisites
- Dart SDK: ^3.10.1
- Flutter SDK: >=1.17.0
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/ComsIndeed/streaming_gen_ui.git
cd streaming_gen_ui_monorepo
```

2. Get dependencies for all packages:
```bash
cd streaming_gen_ui && flutter pub get
cd ../streaming_gen_ui_catalog && flutter pub get
```

## 📚 Project Structure

```
streaming_gen_ui_monorepo/
├── streaming_gen_ui/              # Main Dart package (publishable to pub.dev)
│   ├── lib/
│   │   ├── streaming_gen_ui.dart  # Main entry point
│   │   └── src/
│   │       ├── ui_streamer.dart   # UI streaming logic
│   │       ├── json_decoder.dart  # JSON decoding utilities
│   │       └── streaming_widgets/ # Widget components
│   ├── test/                      # Package tests
│   ├── pubspec.yaml
│   ├── CHANGELOG.md
│   └── README.md
│
└── streaming_gen_ui_catalog/      # Flutter app (demo/testing)
    ├── lib/
    ├── android/
    ├── ios/
    ├── web/
    ├── linux/
    ├── macos/
    ├── windows/
    ├── pubspec.yaml
    └── README.md
```

## 🔧 Development

### Running the Catalog App

```bash
cd streaming_gen_ui_catalog
flutter run
```

### Running Tests

```bash
cd streaming_gen_ui
flutter test
```

### Building for Release

For Android:
```bash
cd streaming_gen_ui_catalog
flutter build apk --release
```

For iOS:
```bash
flutter build ios --release
```

For Web:
```bash
flutter build web --release
```

## 📦 Publishing

The `streaming_gen_ui` package is configured for publication to pub.dev:

```bash
cd streaming_gen_ui
dart pub publish --dry-run  # Verify publishing setup
dart pub publish            # Publish to pub.dev
```

## 🐛 Issues & Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

For issues, please use the [GitHub Issues](https://github.com/ComsIndeed/streaming_gen_ui/issues) page.

## 📄 License

This project is licensed under the License specified in the [LICENSE](./streaming_gen_ui/LICENSE) file.

## 🎯 Roadmap

- [ ] Initial release (v0.0.1)
- [ ] Enhanced widget support
- [ ] Performance optimizations
- [ ] Extended documentation
- [ ] Community contributions

## 📞 Contact

For questions or support, please reach out to the maintainers or open an issue on GitHub.

---

**Last Updated**: December 2025  
**Maintainer**: ComsIndeed
