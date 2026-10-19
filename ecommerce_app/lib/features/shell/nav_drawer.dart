import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';
import 'package:provider/provider.dart';

import '../../core/business_config.dart';
import '../../core/navigation/menu_data.dart';
import '../../core/navigation/nav_helpers.dart';
import '../../core/store/commerce_store.dart';
import '../auth/providers/auth_provider.dart';
import '../config/providers/business_config_provider.dart';
import 'contact_actions.dart';

/// Left slide-in navigation drawer (architecture Â§5.4).
///
/// Text-first menu: rows are plain labels (no decorative icons).
/// Drill-down: top-level accordion rows â†’ category rows â†’ grouped facet links.
/// One top-level section open at a time; drawer footer carries sign-in and
/// the verified support contacts (Â§5.1 / Â§5.8).
class NavDrawer extends StatefulWidget {
  const NavDrawer({super.key});

  @override
  State<NavDrawer> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  int? _openIndex;

  void _follow(String route) {
    Navigator.of(context).maybePop();
    navTo(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final user = context.watch<AuthProvider>().user;
    final menus = context.watch<CommerceStore>().drawerMenus;
    final width = MediaQuery.sizeOf(context).width;

    return Drawer(
      width: (width * 0.85).clamp(280.0, 360.0),
      backgroundColor: AppPalette.surface,
      child: SafeArea(
        child: Column(
          children: [
            _drawerHeader(config),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (var i = 0; i < menus.length; i++)
                    _topRow(i, menus[i]),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(height: 1, color: AppPalette.hairline),
                  _footerRow(
                    label: user?.name.isNotEmpty == true
                        ? user!.name
                        : 'Sign In / Sign Up',
                    onTap: () => _follow(user == null ? '/login' : '/profile'),
                  ),
                  _footerRow(
                    label: 'NEED HELP? CALL ${StoreNav.helpLine}',
                    onTap: () => showContactSheet(
                      context,
                      title: 'Need help?',
                      line1: 'Call ${StoreNav.helpLine}',
                      line2: 'WhatsApp ${StoreNav.whatsappSupport}',
                    ),
                  ),
                  _footerRow(
                    label: 'Chat on WhatsApp',
                    onTap: () => showContactSheet(
                      context,
                      title: 'WhatsApp',
                      line1: StoreNav.whatsappBot,
                      line2: 'Support: ${StoreNav.whatsappSupport}',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerHeader(BusinessConfig config) {
    return Container(
      color: AppPalette.drawerSurface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Close menu',
            icon: const Icon(Icons.close, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              config.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.navLabel.copyWith(
                color: Colors.white,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topRow(int index, NavMenu menu) {
    final open = _openIndex == index;
    return Column(
      children: [
        Material(
          color: open ? AppPalette.copperTint.withValues(alpha: 0.45) : null,
          child: InkWell(
            onTap: () {
              if (!menu.hasPanel) {
                _follow(menu.route);
                return;
              }
              setState(() => _openIndex = open ? null : index);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      menu.label,
                      style: AppTypography.body.copyWith(
                        fontSize: 15,
                        fontWeight: menu.hasPanel && open
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (open && menu.hasPanel)
          Container(
            color: AppPalette.warm,
            width: double.infinity,
            child: _drillDown(menu),
          ),
        const Divider(height: 1, color: AppPalette.hairline),
      ],
    );
  }

  /// Top-level â†’ "View All" â†’ category â†’ grouped facet rows (Â§5.4).
  Widget _drillDown(NavMenu menu) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _follow(menu.route),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                'View All ${menu.label}',
                style: AppTypography.caption.copyWith(
                  color: AppPalette.copperDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (menu.tiles.isNotEmpty)
            for (final tile in menu.tiles)
              _facetRow(label: tile.label, route: tile.route),
          if (menu.groups.isNotEmpty)
            for (final group in menu.groups) ...[
              _groupHeading(group.title),
              for (final link in group.links)
                _facetRow(label: link.label, route: link.route),
            ],
          for (final category in menu.categories) ...[
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: () => _follow(category.route),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text(
                  category.label,
                  style: AppTypography.subtitle.copyWith(fontSize: 14),
                ),
              ),
            ),
            for (final group in category.groups) ...[
              _groupHeading(group.title),
              for (final link in group.links)
                _facetRow(label: link.label, route: link.route),
            ],
          ],
        ],
      ),
    );
  }

  Widget _groupHeading(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
        left: AppSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.eyebrow.copyWith(fontSize: 10.5),
      ),
    );
  }

  Widget _facetRow({required String label, required String route}) {
    return InkWell(
      onTap: () => _follow(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 7,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppPalette.ink,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerRow({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppPalette.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
