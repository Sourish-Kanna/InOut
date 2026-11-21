import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'screens/home_screen.dart';

void main() => runApp(const ProviderScope(child: InOutApp()));

class InOutApp extends StatelessWidget {
  const InOutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InOut',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // builder: (context, child) => MaterialUiCompatibilityBridge(child: child!),
      home: const HomeScreen(),
    );
  }
}
