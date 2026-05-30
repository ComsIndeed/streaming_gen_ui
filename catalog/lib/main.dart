import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:streaming_gen_ui_widget_catalog/homepage.dart';
import 'package:streaming_gen_ui_widget_catalog/pages/chat_demo_page/chat_demo_cubit.dart';

void main() {
  runApp(
    MultiBlocProvider(
      providers: [BlocProvider(create: (_) => ChatDemoCubit())],
      child: const MainApp(),
    ),
  );
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(
  ThemeMode.system,
);

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          builder: (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: [
              const Breakpoint(start: 0, end: 450, name: MOBILE),
              const Breakpoint(start: 451, end: 800, name: TABLET),
              const Breakpoint(start: 801, end: 1920, name: DESKTOP),
            ],
          ),
          // Configure clean default light and dark themes
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed: Colors.blueGrey,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.blueGrey,
          ),
          themeMode: currentThemeMode,
          home: const Homepage(),
        );
      },
    );
  }
}
