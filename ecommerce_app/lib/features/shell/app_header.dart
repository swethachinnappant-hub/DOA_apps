import 'dart:async';

import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/keyboard_hooks.dart';
import '../../core/navigation/menu_data.dart';
import '../../core/navigation/nav_helpers.dart';
import '../../core/store/commerce_store.dart';
import '../auth/providers/auth_provider.dart';
import '../config/providers/business_config_provider.dart';
import '../mini_cart/mini_cart_drawer.dart';
import '../search/search_overlay.dart';

/// Storefront header (architecture Â§5.2).
///
/// * compact  (< 1200)  â€” menu Â· brand Â· account-menu circle Â· cart
/// * expanded (1200+)   â€” logo Â· horizontal nav with hover panels Â· right cluster
class AppHeader extends StatefulWidget {
  const AppHeader({super.key, required this.onMenu});

  final VoidCallback onMenu;

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  final LayerLink _anchorLink = LayerLink();
  final OverlayPortalController _panelController = OverlayPortalController();

  NavMenu? _openMenu;
  Timer? _closeTimer;
  LocalHistoryEntry? _panelHistory;

  bool get _canHover =>
      MediaQuery.sizeOf(context).width >= Responsive.tabletMax;

  void _openPanel(NavMenu menu) {
    if (!_canHover || !menu.hasPanel) return;
    _closeTimer?.cancel();
    if (_openMenu == null) {
      _panelController.show();
      // System back closes the panel before leaving the route (§16.4).
      final route = ModalRoute.of(context);
      if (route != null) {
        _panelHistory = LocalHistoryEntry(onRemove: _handlePanelHistoryRemoved);
        route.addLocalHistoryEntry(_panelHistory!);
      }
      activeEscapeHandler = _closePanelNow;
    }
    setState(() => _openMenu = menu);
  }

  void _scheduleClose() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _panelController.hide();
      setState(() => _openMenu = null);
      _removePanelHistory();
      activeEscapeHandler = null;
    });
  }

  void _closePanelNow() {
    _closeTimer?.cancel();
    _panelController.hide();
    _openMenu = null;
    _removePanelHistory();
    activeEscapeHandler = null;
    if (mounted) setState(() {});
  }

  /// The navigator popped the local history entry: the panel UI closes and
  /// the entry is already detached, so only the UI state is cleared here.
  void _handlePanelHistoryRemoved() {
    _panelHistory = null;
    _closeTimer?.cancel();
    _panelController.hide();
    _openMenu = null;
    activeEscapeHandler = null;
    if (mounted) setState(() {});
  }

  void _removePanelHistory() {
    final entry = _panelHistory;
    if (entry == null) return;
    _panelHistory = null;
    entry.remove();
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _removePanelHistory();
    activeEscapeHandler = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final expanded = width >= Responsive.tabletMax;

    return CompositedTransformTarget(
      link: _anchorLink,
      child: OverlayPortal(
        controller: _panelController,
        overlayChildBuilder: (context) => CompositedTransformFollower(
          link: _anchorLink,
          showWhenUnlinked: false,
          offset: Offset(0, _headerHeight(context)),
          child: _openMenu == null
              ? const SizedBox.shrink()
              : _NavPanel(
                  menu: _openMenu!,
                  onEnter: () => _closeTimer?.cancel(),
                  onExit: _scheduleClose,
                  onClose: _closePanelNow,
                ),
        ),
        child: Container(
          color: AppPalette.surface,
          child: Column(
            children: [
              Container(
                height: _headerHeight(context),
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.pageInset(context),
                ),
                child: expanded
                    ? _ExpandedHeader(
                        onMenuOpenPanel: _openPanel,
                        onMenuClosePanel: _scheduleClose,
                      )
                    : _CompactHeader(onMenu: widget.onMenu),
              ),
              const Divider(height: 1, thickness: 1, color: AppPalette.hairline),
            ],
          ),
        ),
      ),
    );
  }

  static double _headerHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= Responsive.tabletMax ? 72 : 56;
}

// --------------------------------------------------------------- compact

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({required this.onMenu});

  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final user = context.watch<AuthProvider>().user;
    final unread = store.unreadCount(user?.id ?? '');

    return Row(
      children: [
        // Pulled flush to the screen edge: the header gutter used to leave a
        // dead gap between the left edge and the menu button. Translate keeps
        // the 44 px slot (and its hit target) while shifting the icon over.
        Transform.translate(
          offset: const Offset(-AppSpacing.screenH, 0),
          child: Semantics(
            button: true,
            label: 'Menu',
            // §11.5: a 44 px hit target even though the icon stays 22 px.
            child: SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: onMenu,
                tooltip: 'Menu',
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.menu, size: 22),
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: InkWell(
            onTap: () => navGo(context, '/app'),
            borderRadius: AppRadius.allSm,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    // §1.3: a gold-framed monogram reads more premium than a
                    // flat brand-color square, using the palette's own tokens.
                    color: AppPalette.goldLight,
                    border: Border.all(color: AppPalette.gold),
                    borderRadius: AppRadius.allSm,
                    boxShadow: AppShadows.subtle,
                  ),
                  child: Icon(config.icon, size: 18, color: AppPalette.goldDark),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  // The full name always shows — it shrinks to fit instead of
                  // ellipsizing when the right cluster squeezes it.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      config.name.toUpperCase(),
                      maxLines: 1,
                      style: AppTypography.navLabel.copyWith(
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Phone header: menu · brand · account menu · cart. Notifications,
        // wishlist and profile fold behind one circular button so the brand
        // name is never squeezed by a row of loose icons.
        _AccountMenuButton(
          unread: unread,
          wishlistCount: store.wishlistCount,
          profileRoute: user == null ? '/login' : '/profile',
        ),
        _HeaderIcon(
          icon: Icons.shopping_bag_outlined,
          tooltip: 'Cart',
          onTap: () => showMiniCart(context),
          count: store.cartCount,
        ),
      ],
    );
  }
}

/// One circular control standing in for the old notification / wishlist /
/// profile icons: tapping it opens a sheet with the three entries.
class _AccountMenuButton extends StatelessWidget {
  const _AccountMenuButton({
    required this.unread,
    required this.wishlistCount,
    required this.profileRoute,
  });

  final int unread;
  final int wishlistCount;
  final String profileRoute;

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetTile(
              sheetContext,
              context,
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              badge: unread,
              destination: '/notifications',
            ),
            _sheetTile(
              sheetContext,
              context,
              icon: Icons.favorite_border,
              label: 'Wishlist',
              badge: wishlistCount,
              destination: '/wishlist',
            ),
            _sheetTile(
              sheetContext,
              context,
              icon: Icons.person_outline,
              label: 'Account',
              destination: profileRoute,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _sheetTile(
    BuildContext sheetContext,
    BuildContext headerContext, {
    required IconData icon,
    required String label,
    required String destination,
    int badge = 0,
  }) => ListTile(
    leading: Icon(icon, size: 22, color: AppPalette.ink),
    title: Text(label, style: AppTypography.body),
    trailing: badge > 0 ? _countPill(badge) : null,
    onTap: () {
      Navigator.pop(sheetContext);
      navTo(headerContext, destination);
    },
  );

  Widget _countPill(int count) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: const BoxDecoration(
      color: AppPalette.copper,
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    constraints: const BoxConstraints(minWidth: 18),
    child: Text(
      count > 99 ? '99+' : '$count',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Account menu',
      child: Tooltip(
        message: 'Account menu',
        child: InkWell(
          onTap: () => _openSheet(context),
          customBorder: const CircleBorder(),
          child: SizedBox(
            height: 44,
            width: 44,
            child: Center(
              child: Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.goldLight,
                  border: Border.all(color: AppPalette.gold),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 18,
                  color: AppPalette.goldDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- expanded

class _ExpandedHeader extends StatelessWidget {
  const _ExpandedHeader({
    required this.onMenuOpenPanel,
    required this.onMenuClosePanel,
  });

  final void Function(NavMenu menu) onMenuOpenPanel;
  final VoidCallback onMenuClosePanel;

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final user = context.watch<AuthProvider>().user;

    return Row(
      children: [
        InkWell(
          onTap: () => navGo(context, '/app'),
          borderRadius: AppRadius.allSm,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  // §1.3: gold-framed monogram, matching the compact header.
                  color: AppPalette.goldLight,
                  border: Border.all(color: AppPalette.gold),
                  borderRadius: AppRadius.allSm,
                  boxShadow: AppShadows.subtle,
                ),
                child: Icon(config.icon, size: 18, color: AppPalette.goldDark),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                config.name.toUpperCase(),
                style: AppTypography.navLabel.copyWith(
                  fontSize: 13,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        // The ten-item nav is wider than the row at 1200–1500, so the nav
        // segment scrolls horizontally instead of overflowing the header.
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final menu in store.headerMenus)
                  _NavItem(
                    menu: menu,
                    onEnter: () => onMenuOpenPanel(menu),
                    onExit: onMenuClosePanel,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _HeaderIcon(
          icon: Icons.search,
          tooltip: 'Search',
          onTap: () => showSearchOverlay(context),
        ),
        // §1.5: a notification bell with the unread count.
        _HeaderIcon(
          icon: Icons.notifications_outlined,
          tooltip: 'Notifications',
          onTap: () => navTo(context, '/notifications'),
          count: store.unreadCount(user?.id ?? ''),
        ),
        const SizedBox(width: AppSpacing.xs),
        InkWell(
          onTap: () =>
              navTo(context, user == null ? '/login' : '/profile'),
          borderRadius: AppRadius.allSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 22,
                  color: AppPalette.ink,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 96),
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name
                        : 'Sign In / Sign Up',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppPalette.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _HeaderIcon(
          icon: Icons.favorite_border,
          tooltip: 'Wishlist',
          onTap: () => navTo(context, '/wishlist'),
          count: store.wishlistCount,
        ),
        _HeaderIcon(
          icon: Icons.shopping_bag_outlined,
          tooltip: 'Cart',
          onTap: () => showMiniCart(context),
          count: store.cartCount,
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.menu,
    required this.onEnter,
    required this.onExit,
  });

  final NavMenu menu;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onEnter(),
      onExit: (_) => onExit(),
      child: InkWell(
        onTap: () {
          onExit();
          navTo(context, menu.route);
        },
        borderRadius: AppRadius.allXs,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                menu.label.toUpperCase(),
                style: AppTypography.navLabel.copyWith(
                  fontSize: 12,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- hover panel

class _NavPanel extends StatefulWidget {
  const _NavPanel({
    required this.menu,
    required this.onEnter,
    required this.onExit,
    required this.onClose,
  });

  final NavMenu menu;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final VoidCallback onClose;

  @override
  State<_NavPanel> createState() => _NavPanelState();
}

class _NavPanelState extends State<_NavPanel> {
  int _selectedCategory = 0;

  NavMenu get menu => widget.menu;
  VoidCallback get onClose => widget.onClose;

  void _follow(BuildContext context, String route) {
    onClose();
    navTo(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.onEnter(),
      onExit: (_) => widget.onExit(),
      child: Container(
        key: const Key('nav-panel'),
        color: Colors.transparent,
        padding: const EdgeInsets.only(top: 2),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: const BoxDecoration(
            color: AppPalette.surface,
            border: Border(bottom: BorderSide(color: AppPalette.hairline)),
            boxShadow: AppShadows.lift,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.pageInset(context),
            vertical: AppSpacing.xxl,
          ),
          child: SingleChildScrollView(
            child: _panelBody(context),
          ),
        ),
      ),
    );
  }

  Widget _panelBody(BuildContext context) {
    if (menu.categories.isNotEmpty) return _categoriesPanel(context);
    if (menu.groups.isNotEmpty) return _groupsPanel(context);
    return _tilesPanel(context);
  }

  Widget _link(BuildContext context, NavFacet facet, {double thumb = 44}) {
    return InkWell(
      onTap: () => _follow(context, facet.route),
      borderRadius: AppRadius.allSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: thumb,
              width: thumb,
              decoration: BoxDecoration(
                color: AppPalette.warm,
                borderRadius: AppRadius.allXs,
                border: Border.all(color: AppPalette.hairline),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.diamond_outlined,
                size: 18,
                color: AppPalette.copper,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              facet.label,
              style: AppTypography.caption.copyWith(
                color: AppPalette.ink,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Metals: left category column (hover switches) + right facet groups (Â§5.3).
  Widget _categoriesPanel(BuildContext context) {
    final selected = menu.categories[
        _selectedCategory < menu.categories.length ? _selectedCategory : 0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < menu.categories.length; i++)
                MouseRegion(
                  onEnter: (_) => setState(() => _selectedCategory = i),
                  child: InkWell(
                    onTap: () => _follow(context, menu.categories[i].route),
                    borderRadius: AppRadius.allXs,
                    child: Container(
                      color: i == _selectedCategory
                          ? AppPalette.copperTint.withValues(alpha: 0.5)
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              menu.categories[i].label,
                              style: AppTypography.caption.copyWith(
                                color: AppPalette.ink,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(width: 1, color: AppPalette.hairline),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _follow(context, selected.route),
                child: Text(
                  selected.label,
                  style: AppTypography.sectionTitle.copyWith(fontSize: 16),
                ),
              ),
              const SizedBox(height: 2),
              InkWell(
                onTap: () => _follow(context, selected.route),
                child: Text(
                  'All ${menu.label} ${selected.label}',
                  style: AppTypography.caption.copyWith(
                    color: AppPalette.copperDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (selected.groups.isEmpty)
                Text(
                  'New designs are being added to this category.',
                  style: AppTypography.caption.copyWith(
                    color: AppPalette.textMuted,
                  ),
                ),
              for (final group in selected.groups) ...[
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    group.title.toUpperCase(),
                    style: AppTypography.eyebrow.copyWith(fontSize: 11),
                  ),
                ),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final facet in group.links) _link(context, facet),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Gifts: headed groups (Â§4.2).
  Widget _groupsPanel(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xxxl,
      runSpacing: AppSpacing.xl,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        for (final group in menu.groups)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                group.title.toUpperCase(),
                style: AppTypography.eyebrow.copyWith(fontSize: 11),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final facet in group.links) _link(context, facet),
            ],
          ),
      ],
    );
  }

  /// Collections / Virtual / By Price / Solitaire: single tile grid (Â§4.2).
  Widget _tilesPanel(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.md,
      children: [
        for (final tile in menu.tiles)
          InkWell(
            onTap: () => _follow(context, tile.route),
            borderRadius: AppRadius.allSm,
            child: Container(
              width: 150,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppPalette.warm,
                borderRadius: AppRadius.allSm,
                border: Border.all(color: AppPalette.hairline),
              ),
              child: Text(
                tile.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppPalette.ink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ----------------------------------------------------------------- shared

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.count = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            height: 44,
            width: 44,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 22, color: AppPalette.ink),
                if (count > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Semantics(
                      container: true,
                      liveRegion: true,
                      label: '$tooltip, $count items',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: const BoxDecoration(
                          color: AppPalette.copper,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        constraints: const BoxConstraints(minWidth: 15),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
