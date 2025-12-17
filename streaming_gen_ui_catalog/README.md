# streaming_gen_ui_catalog

A comprehensive Flutter application that demonstrates the capabilities of the `streaming_gen_ui` package. This app serves as both a reference implementation and testing ground for streaming UI generation from LLM outputs.

## About

The streaming_gen_ui_catalog application showcases:

- 📱 Real-time streaming UI generation
- 🎯 Widget rendering from LLM JSON streams
- 🌐 Multi-platform support (iOS, Android, Web, macOS, Linux, Windows)
- 🎨 UI pattern examples and best practices
- ⚡ Performance benchmarks and optimizations

## Getting started

### Prerequisites

- Flutter SDK: >=1.17.0
- Dart SDK: ^3.10.1
- A device or emulator for testing

### Installation

1. Navigate to the catalog directory:

```bash
cd streaming_gen_ui_catalog
```

2. Get dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run
```

### Specifying a Device

To run on a specific device:

```bash
# List available devices
flutter devices

# Run on a specific device
flutter run -d <device_id>
```

## Building for Distribution

### Android

```bash
flutter build apk --release          # APK
flutter build appbundle --release    # App Bundle (recommended for Play Store)
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

### macOS

```bash
flutter build macos --release
```

### Linux

```bash
flutter build linux --release
```

### Windows

```bash
flutter build windows --release
```

## Project Structure

```
streaming_gen_ui_catalog/
├── lib/
│   ├── main.dart          # Application entry point
│   └── screens/           # UI screens and examples
├── android/               # Android-specific configuration
├── ios/                   # iOS-specific configuration
├── web/                   # Web-specific configuration
├── linux/                 # Linux-specific configuration
├── macos/                 # macOS-specific configuration
├── windows/               # Windows-specific configuration
└── pubspec.yaml          # Project dependencies
```

## Features

- ✨ Clean Material Design UI
- 🧪 Example implementations of streaming widgets
- 📊 Performance monitoring and debugging
- 🎨 Customizable themes and styles
- 🔄 Real-time updates and state management

## Development

### Running in Debug Mode

```bash
flutter run
```

### Running with Verbose Logging

```bash
flutter run -v
```

### Hot Reload

During development, use `r` to hot reload or `R` to hot restart:

```
flutter run
# In the terminal, press 'r' for hot reload
```

### Code Generation (if needed)

```bash
flutter pub run build_runner build
```

## Testing

```bash
flutter test
```

## Troubleshooting

### Common Issues

**Issue**: "Android SDK not found"
- **Solution**: Set the ANDROID_SDK_ROOT environment variable or run `flutter doctor` to verify installation

**Issue**: "iOS pods need updating"
- **Solution**: Run `cd ios && pod install && cd ..`

**Issue**: "Web build fails"
- **Solution**: Run `flutter pub get` and ensure all dependencies are up to date

### Getting Help

- Run `flutter doctor` for environment diagnostics
- Check [Flutter Documentation](https://flutter.dev/docs)
- Visit [streaming_gen_ui Issues](https://github.com/ComsIndeed/streaming_gen_ui/issues)

## Contributing

This catalog app is part of the streaming_gen_ui project. See the [main repository README](../README.md) for contribution guidelines.

## Related Resources

- [streaming_gen_ui Package](../streaming_gen_ui/) - Core package documentation
- [Flutter Documentation](https://flutter.dev)
- [Dart Documentation](https://dart.dev)

## License

This application is licensed under the same license as the main repository.
