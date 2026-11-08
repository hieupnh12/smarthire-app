import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded),
            label: 'Việc làm',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Ứng tuyển',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy_rounded),
            label: 'Test & AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
