import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:common_widgets/common_widgets.dart';
import '../../auth/widgets/sign_out_action.dart';

/// Persistent navigation for the seller console.
///
/// Tabs rather than one scrolling page: a seller switching between stock and
/// the order queue should never lose their place in either. Beyond the three
/// workspace tabs, the console carries six storefront pages (SPEC-18) — they
/// push full-screen from the sidebar's STOREFRONT group, and from the
/// bottom bar's "More" sheet on a phone.
class OwnerShell extends StatelessWidget {
  const OwnerShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  /// The three branch tabs: indices match [StatefulShellBranch] order.
  static const List<({
    IconData icon,
    IconData selectedIcon,
    String label,
    String description,
  })> destinations = [
    (
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
      description: 'Store performance and activity',
    ),
    (
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'Products',
      description: 'Manage your jewellery range',
    ),
    (
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag,
      label: 'Orders',
      description: 'Review and fulfil purchases',
    ),
  ];

  /// The SPEC-18 storefront pages, pushed (not branched) full-screen.
  static const List<({
    String path,
    IconData icon,
    IconData selectedIcon,
    String label,
    String description,
  })> storefront = [
    (
      path: '/owner/categories',
      icon: Icons.menu_open_outlined,
      selectedIcon: Icons.menu_open,
      label: 'Categories & Menu',
      description: 'Labels, order and visibility',
    ),
    (
      path: '/owner/collections',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view,
      label: 'Collections',
      description: 'Tiles, images and products',
    ),
    (
      path: '/owner/home-builder',
      icon: Icons.dashboard_customize_outlined,
      selectedIcon: Icons.dashboard_customize,
      label: 'Home Builder',
      description: 'Sections and hero slides',
    ),
    (
      path: '/owner/coupons',
      icon: Icons.local_offer_outlined,
      selectedIcon: Icons.local_offer,
      label: 'Coupons',
      description: 'Codes, limits and validity',
    ),
    (
      path: '/owner/gold-rate',
      icon: Icons.monetization_on_outlined,
      selectedIcon: Icons.monetization_on,
      label: 'Gold rate',
      description: 'Daily rates and estimates',
    ),
    (
      path: '/owner/customers',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      label: 'Customers',
      description: 'Loyalty points and history',
    ),
  ];

  void _onSelect(BuildContext context, int index) {
    if (index >= destinations.length) {
      _showMoreSheet(context);
      return;
    }
    shell.goBranch(
      index,
      // Re-tapping the active tab returns to that tab's first screen.
      initialLocation: index == shell.currentIndex,
    );
  }

  /// Phone entry point for the six storefront pages, plus settings and
  /// sign-out so the bottom bar never needs a fourth tab for either.
  static void _showMoreSheet(BuildContext context) {
    final rootContext = context;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        void follow(VoidCallback action) {
          Navigator.of(sheetContext).pop();
          action();
        }

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            children: [
              for (final item in storefront)
                _OwnerMenuItem(
                  icon: item.icon,
                  selectedIcon: item.selectedIcon,
                  label: item.label,
                  description: item.description,
                  onTap: () =>
                      follow(() => rootContext.push(item.path)),
                ),
              const Divider(height: 24),
              _OwnerMenuItem(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
                label: 'Shop settings',
                description: 'Account and notifications',
                onTap: () => follow(() => rootContext.push('/profile')),
              ),
              _OwnerMenuItem(
                icon: Icons.logout_outlined,
                selectedIcon: Icons.logout_rounded,
                label: 'Sign out',
                description: 'Leave seller studio',
                destructive: true,
                onTap: () => follow(() => confirmSignOut(rootContext)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Responsive.shouldShowSideNav(context)) {
      return Scaffold(
        body: Row(
          children: [
            _OwnerMenu(
              currentIndex: shell.currentIndex,
              onSelect: (index) => _onSelect(context, index),
              onSettings: () => context.push('/profile'),
              onSignOut: () => confirmSignOut(context),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppPalette.divider,
            ),
            Expanded(child: shell),
          ],
        ),
      );
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) => _onSelect(context, index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class _OwnerMenu extends StatelessWidget {
  const _OwnerMenu({
    required this.currentIndex,
    required this.onSelect,
    required this.onSettings,
    required this.onSignOut,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = Responsive.sideNavWidth(context);

    return SizedBox(
      width: width,
      child: ColoredBox(
        color: scheme.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppPalette.textPrimary,
                    borderRadius: AppRadius.allLg,
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8C39A).withValues(alpha: .16),
                          borderRadius: AppRadius.allMd,
                        ),
                        child: const Icon(
                          Icons.diamond_outlined,
                          color: Color(0xFFD8C39A),
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DOA ATELIER',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'SELLER STUDIO',
                              style: TextStyle(
                                color: Color(0xFFB9B2A6),
                                fontSize: 9,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // The two groups scroll together so eleven destinations fit
                // any window height; settings and sign-out stay pinned.
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 10),
                        child: Text(
                          'WORKSPACE',
                          style: AppTypography.overline.copyWith(
                            color: AppPalette.textHint,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      for (
                        var index = 0;
                        index < OwnerShell.destinations.length;
                        index++
                      )
                        _OwnerMenuItem(
                          icon: OwnerShell.destinations[index].icon,
                          selectedIcon:
                              OwnerShell.destinations[index].selectedIcon,
                          label: OwnerShell.destinations[index].label,
                          description:
                              OwnerShell.destinations[index].description,
                          selected: currentIndex == index,
                          onTap: () => onSelect(index),
                        ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 10),
                        child: Text(
                          'STOREFRONT',
                          style: AppTypography.overline.copyWith(
                            color: AppPalette.textHint,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      for (final item in OwnerShell.storefront)
                        _OwnerMenuItem(
                          icon: item.icon,
                          selectedIcon: item.selectedIcon,
                          label: item.label,
                          description: item.description,
                          onTap: () => context.push(item.path),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                _OwnerMenuItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: 'Shop settings',
                  description: 'Account and notifications',
                  onTap: onSettings,
                ),
                _OwnerMenuItem(
                  icon: Icons.logout_outlined,
                  selectedIcon: Icons.logout_rounded,
                  label: 'Sign out',
                  description: 'Leave seller studio',
                  onTap: onSignOut,
                  destructive: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerMenuItem extends StatelessWidget {
  const _OwnerMenuItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.description,
    required this.onTap,
    this.selected = false,
    this.destructive = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final foreground = destructive
        ? const Color(0xFF8A4943)
        : selected
        ? AppPalette.textPrimary
        : AppPalette.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? const Color(0xFFF3EFE7) : Colors.transparent,
        borderRadius: AppRadius.allMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.allMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : AppPalette.surfaceMuted,
                    borderRadius: AppRadius.allSm,
                  ),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    size: 19,
                    color: foreground,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.label.copyWith(
                          color: foreground,
                          letterSpacing: 0,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppPalette.goldDark,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
