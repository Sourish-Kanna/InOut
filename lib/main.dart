import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'screens/app_shell.dart';

void main() => runApp(const ProviderScope(child: InOutApp()));

class InOutApp extends StatelessWidget {
  const InOutApp({super.key});

  static const _seed = Colors.deepPurple;
  static const _orange = Color(0xFFFF9800);

  ColorScheme _scheme(Brightness b) => ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: b,
    secondary: _orange,
    onSecondary: Colors.black, // dark text stays readable on orange
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InOut',
      theme: ThemeData(colorScheme: _scheme(Brightness.light)),
      darkTheme: ThemeData(colorScheme: _scheme(Brightness.dark)),
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
