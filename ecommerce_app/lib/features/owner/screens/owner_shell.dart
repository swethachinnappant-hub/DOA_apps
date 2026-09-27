import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:common_widgets/common_widgets.dart';

/// Persistent navigation for the seller console.
///
/// Tabs rather than one scrolling page: a seller switching between stock and
/// the order queue should never lose their place in either.
class OwnerShell extends StatelessWidget {
  const OwnerShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const List<({IconData icon, IconData selectedIcon, String label})>
      destinations = [
    (
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
      label: 'Dashboard',
    ),
    (
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'Products',
    ),
    (
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Orders',
    ),
  ];

  void _onSelect(int index) {
    shell.goBranch(
      index,
      // Re-tapping the active tab returns to that tab's first screen.
      initialLocation: index == shell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Responsive.shouldShowSideNav(context)) {
      return Scaffold(
        body: Row(
          children: [
            _Rail(shell: shell, onSelect: _onSelect),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _onSelect,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.shell, required this.onSelect});

  final StatefulNavigationShell shell;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = Responsive.sideNavWidth(context);
    final showLabels = width >= 180;

    return SizedBox(
      width: width,
      child: NavigationRail(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: onSelect,
        labelType: showLabels
            ? NavigationRailLabelType.all
            : NavigationRailLabelType.none,
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child:
                Icon(Icons.storefront_outlined, color: scheme.onPrimaryContainer),
          ),
        ),
        destinations: [
          for (final d in OwnerShell.destinations)
            NavigationRailDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: Text(d.label),
            ),
        ],
      ),
    );
  }
}
