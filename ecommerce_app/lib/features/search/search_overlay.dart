import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../core/business_config.dart';
import '../../core/navigation/keyboard_hooks.dart';
import '../../core/pricing.dart';
import '../../core/product.dart';
import '../../core/router/app_router.dart';
import '../../core/store/commerce_store.dart';
import '../config/providers/business_config_provider.dart';
import '../../widgets/search_action_buttons.dart';
import 'search_provider.dart';

/// App-level shortcut intent: Ctrl+K (Windows/Linux) or Cmd+K (macOS).
class OpenSearchIntent extends Intent {
  const OpenSearchIntent();
}

const Map<ShortcutActivator, Intent> appSearchShortcuts = {
  SingleActivator(LogicalKeyboardKey.keyK, control: true): OpenSearchIntent(),
  SingleActivator(LogicalKeyboardKey.keyK, meta: true): OpenSearchIntent(),
};

Map<Type, Action<Intent>> buildAppSearchActions() {
  return <Type, Action<Intent>>{
    OpenSearchIntent: CallbackAction<OpenSearchIntent>(
      onInvoke: (intent) {
        final context = rootNavigatorKey.currentContext;
        if (context != null) showSearchOverlay(context);
        return null;
      },
    ),
  };
}

/// Hosts the Ctrl/Cmd+K shortcut for the whole app. The autofocus [Focus]
/// keeps a focus node in the chain so key events always bubble to the
/// [Shortcuts] wrapper, whether or not a text field currently holds focus.
///
/// Escape bubbles here too (§16.4): it closes the mega-menu hover panel via
/// [activeEscapeHandler]. Deeper overlays (the search panel itself) handle
/// Escape first and stop it from bubbling.
class SearchShortcutHost extends StatelessWidget {
  const SearchShortcutHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: appSearchShortcuts,
      child: Actions(
        actions: buildAppSearchActions(),
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              final handler = activeEscapeHandler;
              if (handler != null) {
                handler();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: child,
        ),
      ),
    );
  }
}

bool _searchOverlayOpen = false;

/// Opens the search overlay: full-screen route on compact, 640 px top sheet
/// with a dimmed backdrop on wider layouts.
Future<void> showSearchOverlay(BuildContext context) {
  if (_searchOverlayOpen) return Future<void>.value();
  if (Responsive.isMobile(context)) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const SearchOverlay(compact: true)),
    );
  }
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close search',
    barrierColor: Colors.black54,
    pageBuilder: (dialogContext, _, _) => const SearchOverlay(compact: false),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.08),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class SearchOverlay extends StatefulWidget {
  const SearchOverlay({super.key, required this.compact});

  final bool compact;

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  @override
  void initState() {
    super.initState();
    _searchOverlayOpen = true;
  }

  @override
  void dispose() {
    _searchOverlayOpen = false;
    super.dispose();
  }

  void _close() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SearchProvider>(
      create: (ctx) => SearchProvider(store: ctx.read<CommerceStore>()),
      child: Builder(
        builder: (context) {
          if (widget.compact) {
            return Scaffold(
              backgroundColor: AppPalette.surface,
              body: SafeArea(
                child: SearchPanel(onClose: _close, compact: true),
              ),
            );
          }
          return Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              bottom: false,
              child: Material(
                color: AppPalette.surface,
                elevation: 16,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: SearchPanel(onClose: _close, compact: false),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SearchPanel extends StatefulWidget {
  const SearchPanel({super.key, required this.onClose, required this.compact});

  final VoidCallback onClose;
  final bool compact;

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigate(String route) {
    final router = GoRouter.of(context);
    widget.onClose();
    router.push(route);
  }

  void _submit(SearchProvider provider) {
    final q = provider.query.trim();
    if (q.isEmpty) return;
    provider.recordRecent(q);
    _navigate('/catalogue?search=${Uri.encodeQueryComponent(q)}');
  }

  void _searchTerm(SearchProvider provider, String term) {
    _controller.text = term;
    provider.type(term);
    provider.settleNow();
    provider.recordRecent(term);
    _navigate('/catalogue?search=${Uri.encodeQueryComponent(term)}');
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final provider = context.watch<SearchProvider>();
    final hint = config.searchHint.isEmpty
        ? 'Search jewellery…'
        : config.searchHint;

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onClose();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppPalette.divider)),
            ),
            child: Row(
              children: [
                if (widget.compact)
                  IconButton(
                    tooltip: 'Back',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onClose,
                  )
                else
                  const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.search, size: 18, color: AppPalette.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    style: AppTypography.body,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: AppTypography.body.copyWith(
                        color: AppPalette.textHint,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      suffixIcon: SearchActionButtons(
                        onVoiceQuery: (query) {
                          _controller.text = query;
                          provider.type(query);
                        },
                      ),
                    ),
                    onChanged: provider.type,
                    onSubmitted: (_) => _submit(provider),
                  ),
                ),
                if (!widget.compact)
                  IconButton(
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: widget.onClose,
                  ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: _sections(config, provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sections(BusinessConfig config, SearchProvider provider) {
    final children = <Widget>[];

    if (!provider.hasQuery) {
      if (provider.recentSearches.isNotEmpty) {
        children.add(_heading('Recent Searches'));
        for (final term in provider.recentSearches) {
          children.add(
            _row(
              icon: Icons.history,
              label: term,
              onTap: () => _searchTerm(provider, term),
            ),
          );
        }
      }
      // Real demand first (ranked by product count), category names as the
      // fallback for a fresh or empty catalogue (§15).
      final recent = provider.recentSearches
          .map((term) => term.toLowerCase())
          .toSet();
      final popular = provider.popularSearches.isNotEmpty
          ? provider.popularSearches
          : config.categories
                .where((category) => !recent.contains(category.toLowerCase()))
                .take(6)
                .toList();
      if (popular.isNotEmpty) {
        if (children.isNotEmpty) children.add(const SizedBox(height: AppSpacing.md));
        children.add(_heading('Popular Searches'));
        for (final category in popular) {
          children.add(
            _row(
              icon: Icons.trending_up,
              label: category,
              onTap: () => _searchTerm(provider, category),
            ),
          );
        }
      }
      if (children.isEmpty) return _emptyState();
      // §3.16: a visible, labelled photo-search entry at the top of the
      // resting state — the suffix icon alone left it undiscoverable.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: () => showPhotoSearch(context),
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: const Text('Search by photo'),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      );
    }

    final related = provider.relatedSearches;
    children.add(_heading('Related Searches'));
    if (related.isEmpty) {
      children.add(_empty('No matching categories'));
    } else {
      for (final facet in related) {
        children.add(
          _row(
            icon: Icons.trending_up,
            label: facet.label,
            trailing: Icons.north_east,
            onTap: () => _navigate(facet.route),
          ),
        );
      }
    }
    children.add(const SizedBox(height: AppSpacing.lg));
    children.add(_heading('Related Products'));
    final products = provider.productSuggestions;
    if (products.isEmpty) {
      children.add(_empty('No products match “${provider.settledQuery}”'));
    } else {
      for (final product in products) {
        children.add(_productRow(config, product));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// No history and no suggestions yet: a designed resting state with a way
  /// back to shopping, instead of a blank panel (§15).
  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_rounded,
              size: 34,
              color: AppPalette.goldDark,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Start typing to search', style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try a category, metal or design name.',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppPalette.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => showPhotoSearch(context),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Search by photo'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => _navigate('/catalogue'),
              child: const Text('Continue shopping'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.eyebrow.copyWith(color: AppPalette.textSecondary),
      ),
    );
  }

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(text, style: AppTypography.caption),
    );
  }

  Widget _row({
    required IconData icon,
    required String label,
    IconData? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppPalette.copperDark),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(fontSize: 14),
              ),
            ),
            if (trailing != null)
              Icon(trailing, size: 15, color: AppPalette.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _productRow(BusinessConfig config, Product product) {
    final showPrice = config.rules.showPrices;
    return InkWell(
      onTap: () => _navigate('/product/${product.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppRadius.allSm,
              child: SizedBox(
                width: 40,
                height: 40,
                child: product.images.isEmpty
                    ? ColoredBox(
                        color: AppPalette.surfaceMuted,
                        child: Icon(
                          product.icon,
                          size: 20,
                          color: AppPalette.copperDark,
                        ),
                      )
                    : Image.network(
                        product.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: AppPalette.surfaceMuted,
                          child: Icon(
                            product.icon,
                            size: 20,
                            color: AppPalette.copperDark,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              showPrice
                  ? Pricing.money(
                      product.price,
                      currencySymbol: config.currencySymbol,
                    )
                  : 'Contact for Price',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppPalette.copperDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
