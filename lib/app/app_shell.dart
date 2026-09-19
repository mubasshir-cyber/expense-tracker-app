import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The root application shell holding the bottom navigation bar and global action button.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
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
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Transaction',
        onPressed: () => context.push('/add-transaction'),
        child: const Icon(LucideIcons.plus, size: 24),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.home),
            selectedIcon: Icon(LucideIcons.home, color: Color(0xFF4F46E5)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.receipt),
            selectedIcon: Icon(LucideIcons.receipt, color: Color(0xFF4F46E5)),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.pieChart),
            selectedIcon: Icon(LucideIcons.pieChart, color: Color(0xFF4F46E5)),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.user),
            selectedIcon: Icon(LucideIcons.user, color: Color(0xFF4F46E5)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
