import 'package:material_ui/material_ui.dart';

import 'calendar_screen.dart';
import 'home_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: const [HomeScreen(), CalendarScreen()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.access_time), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Calendar'),
        ],
      ),
    );
  }
}
