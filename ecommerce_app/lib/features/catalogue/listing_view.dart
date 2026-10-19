import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';
import 'package:provider/provider.dart';

import '../../core/business_config.dart';
import '../../core/navigation/nav_helpers.dart';
import '../../core/pricing.dart';
import '../../core/product.dart';
import '../../core/store/commerce_store.dart';
import '../../widgets/product_card.dart';
import '../config/providers/business_config_provider.dart';
import 'filter_panel.dart';
import 'route_scope.dart';

/// The shared listing surface (§7): one body serves `/catalogue`, the price
/// bands and every §4.3 catch-all path through [RouteScope].
///
/// Placement follows §7.1: persistent FILTERS sidebar on Expanded (≥1200),
/// the "Refine collection" right drawer on Medium (600–1199), the bottom
/// sheet with "Show pieces" / "Clear filters" on Compact (<600).
class ListingView extends StatefulWidget {
  const ListingView({
    super.key,
    this.scope,
    this.categoryChips,
    this.showSearchField = false,
    this.initialCategory,
    this.initialQuery,
    this.initialPriceMin,
    this.initialPriceMax,
    this.initialMetal,
    this.footer,
  });

  /// Resolved §7.3 scope for a catch-all path; null on the plain catalogue.
  final RouteScope? scope;

  /// Business category chips (catalogue mode); null renders the scope's
  /// sub-category facet chips instead.
  final List<String>? categoryChips;

  final bool showSearchField;
  final String? initialCategory;
  final String? initialQuery;
  final int? initialPriceMin;
  final int? initialPriceMax;
  final String? initialMetal;

  /// Trailing block rendered as the last sliver of the listing scroll, e.g.
  /// the site footer on catch-all shop pages (§7).
  final Widget? footer;

  @override
  State<ListingView> createState() => _ListingViewState();
}

class _ListingViewState extends State<ListingView> {
  static const int _pageSize = 24;

  late ListingFilters _filters;
  late String _query;
  late final TextEditingController _searchController;
  bool _isGrid = true;
  int? _density;
  int _shown = _pageSize;

  @override
  void initState() {
    super.initState();
    _filters = ListingFilters(
      category: widget.initialCategory ?? 'All',
      priceMin: widget.initialPriceMin,
      priceMax: widget.initialPriceMax,
      metal: widget.initialMetal,
    );
    _query = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _apply(ListingFilters next) {
    setState(() {
      _filters = next;
      _shown = _pageSize;
    });
  }

  void _resetFilters() {
    _apply(ListingFilters(sort: _filters.sort));
  }

  String _priceBandLabel(BusinessConfig config) {
    final symbol = config.currencySymbol;
    if (_filters.priceMin != null && _filters.priceMax != null) {
      return '${Pricing.money(_filters.priceMin!, currencySymbol: symbol)} – ${Pricing.money(_filters.priceMax!, currencySymbol: symbol)}';
    }
    if (_filters.priceMax != null) {
      return 'Under ${Pricing.money(_filters.priceMax!, currencySymbol: symbol)}';
    }
    return '${Pricing.money(_filters.priceMin!, currencySymbol: symbol)} & above';
  }

  static bool _matchesMetal(Product product, String metal) {
    final needle = metal.toLowerCase();
    return product.name.toLowerCase().contains(needle) ||
        product.category.toLowerCase().contains(needle) ||
        product.description.toLowerCase().contains(needle) ||
        product.specs.values.any(
          (value) => value.toLowerCase().contains(needle),
        ) ||
        product.shades.any(
          (shade) => shade.name.toLowerCase().contains(needle),
        );
  }

  List<Product> _sorted(List<Product> items) {
    switch (_filters.sort) {
      case 'Newest':
        return [...items]..sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
      case 'Price: Low to High':
        return [...items]..sort((a, b) => a.price.compareTo(b.price));
      case 'Price: High to Low':
        return [...items]..sort((a, b) => b.price.compareTo(a.price));
      case 'Best sellers':
        return [...items]..sort(
          (a, b) => b.reviewCount.compareTo(a.reviewCount),
        );
      case 'Discount':
        return [...items]..sort(
          (a, b) => b.discountPercent.compareTo(a.discountPercent),
        );
      default:
        return items;
    }
  }

  List<String> _purityOptions(List<Product> products) {
    return products
        .expand(
          (product) => product.specs.entries
              .where((entry) => entry.key.toLowerCase().contains('purity'))
              .map((entry) => entry.value.trim()),
        )
        .where((purity) => purity.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _openPanel(
    BusinessConfig config,
    List<String> purityOptions, {
    List<String> metalOptions = const [],
    bool openSort = false,
  }) async {
    final panel = FilterPanel(
      filters: _filters,
      currencySymbol: config.currencySymbol,
      primaryColor: config.primaryColor,
      onPrimaryColor: config.onPrimaryColor,
      purityOptions: purityOptions,
      metalOptions: metalOptions,
      showPriceRange: config.rules.showPrices,
      openSort: openSort,
      onApply: _apply,
      onClear: _resetFilters,
    );

    if (Responsive.shouldShowSideNav(context)) {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Close filter and sort panel',
        barrierColor: Colors.black54,
        pageBuilder: (dialogContext, _, _) => SafeArea(
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: AppPalette.surface,
              elevation: 16,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
              child: SizedBox(
                width: 420,
                height: double.infinity,
                child: panel,
              ),
            ),
          ),
        ),
        transitionBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: AppPalette.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) =>
            FractionallySizedBox(heightFactor: 0.88, child: panel),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final scope = widget.scope;
    final showSidebar = Responsive.width(context) >= 1200;

    var base = store.shopProducts;
    if (scope != null) base = narrowToScope(base, scope);

    final needle = _query.trim().toLowerCase();
    if (needle.isNotEmpty) {
      base =
          base
              .where(
                (product) => <String>[
                  product.name,
                  product.brand,
                  product.sku,
                  product.category,
                  product.description,
                  ...product.specs.values,
                ].any((value) => value.toLowerCase().contains(needle)),
              )
              .toList();
    }

    var visible = base;
    if (_filters.category != 'All') {
      visible = visible.where((p) => p.category == _filters.category).toList();
    }
    if (_filters.hasPriceBand) {
      visible =
          visible
              .where(
                (p) =>
                    (_filters.priceMin == null ||
                        p.price >= _filters.priceMin!) &&
                    (_filters.priceMax == null ||
                        p.price <= _filters.priceMax!),
              )
              .toList();
    }
    if (_filters.inStockOnly) {
      visible = visible.where((product) => product.isAvailable).toList();
    }
    if (_filters.purity != null) {
      visible =
          visible
              .where(
                (product) => product.specs.entries.any(
                  (entry) =>
                      entry.key.toLowerCase().contains('purity') &&
                      entry.value.trim() == _filters.purity,
                ),
              )
              .toList();
    }
    if (_filters.metal != null) {
      visible =
          visible
              .where((product) => _matchesMetal(product, _filters.metal!))
              .toList();
    }

    final sorted = _sorted(visible);
    final total = sorted.length;
    final page = sorted.take(_shown).toList();
    final purityOptions = _purityOptions(base);
    // Only facets the current result set can actually satisfy: a metal chip
    // that matches nothing (or a business with no metal-bearing stock) would
    // be an irrelevant dead end in the panel.
    final metalOptions = [
      for (final metal in kMetalOptions)
        if (base.any((product) => _matchesMetal(product, metal))) metal,
    ];

    final slivers = <Widget>[
      if (scope != null) ..._headerSlivers(scope, total),
      if (widget.showSearchField) _searchSliver(config),
      if (widget.categoryChips != null)
        _categoryChipSliver(config)
      else if (scope != null && scope.subChips.isNotEmpty)
        _subChipSliver(scope),
      if (_filters.activeCount > 0) _activeChipsSliver(config),
      _controlsSliver(
        config,
        purityOptions,
        metalOptions,
        total,
        showSidebar,
      ),
      if (total == 0)
        SliverFillRemaining(hasScrollBody: false, child: _emptyState())
      else if (_isGrid)
        _gridSliver(page, config, store)
      else
        _listSliver(page, config, store),
      if (total > _shown)
        SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
              child: FilledButton(
                key: const ValueKey('load-more'),
                style: FilledButton.styleFrom(
                  backgroundColor: config.primaryColor,
                  foregroundColor: config.onPrimaryColor,
                  minimumSize: const Size(220, 48),
                ),
                onPressed: () => setState(() => _shown += _pageSize),
                child: const Text('LOAD MORE'),
              ),
            ),
          ),
        ),
      if (scope != null) _aboutSliver(scope),
      if (widget.footer != null)
        SliverToBoxAdapter(child: widget.footer!),
    ];

    final scroll = CustomScrollView(slivers: slivers);

    if (!showSidebar) return scroll;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 300,
          child: Material(
            color: AppPalette.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('FILTERS', style: AppTypography.overline),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: FilterPanel(
                      filters: _filters,
                      currencySymbol: config.currencySymbol,
                      primaryColor: config.primaryColor,
                      onPrimaryColor: config.onPrimaryColor,
                      purityOptions: purityOptions,
                      metalOptions: metalOptions,
                      showPriceRange: config.rules.showPrices,
                      live: true,
                      onApply: _apply,
                      onClear: _resetFilters,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: scroll),
      ],
    );
  }

  // ----------------------------------------------------------------- header

  List<Widget> _headerSlivers(RouteScope scope, int total) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.lg,
            AppSpacing.screenH,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.xs,
                children: [
                  for (final crumb in scope.crumbs) ...[
                    if (crumb != scope.crumbs.first)
                      const Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: AppPalette.textHint,
                      ),
                    GestureDetector(
                      onTap: () => navTo(context, crumb.route),
                      child: Text(
                        crumb.label,
                        style: AppTypography.caption.copyWith(
                          color: AppPalette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      scope.title,
                      style: AppTypography.display.copyWith(fontSize: 30),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '$total designs',
                    style: AppTypography.overline.copyWith(
                      color: AppPalette.textSecondary,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _viewToggle(),
                ],
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _searchSliver(BusinessConfig config) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.lg,
          AppSpacing.screenH,
          0,
        ),
        child: AppSearchField(
          hint: config.searchHint,
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
        ),
      ),
    );
  }

  Widget _categoryChipSliver(BusinessConfig config) {
    final chips = ['All', ...widget.categoryChips!];
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.sm,
          ),
          itemCount: chips.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.chipGap),
          itemBuilder: (context, index) {
            final chip = chips[index];
            final selected = chip == _filters.category;
            return GestureDetector(
              key: ValueKey('category-chip-$chip'),
              onTap: () => _apply(_filters.copyWith(category: chip)),
              child: AnimatedContainer(
                duration: AppDurations.fast,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? config.primaryColor : AppPalette.surface,
                  borderRadius: AppRadius.allPill,
                  border: Border.all(
                    color: selected ? config.primaryColor : AppPalette.border,
                  ),
                ),
                child: Text(
                  chip,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    color: selected
                        ? config.onPrimaryColor
                        : AppPalette.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _subChipSliver(RouteScope scope) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.sm,
          ),
          itemCount: scope.subChips.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.chipGap),
          itemBuilder: (context, index) {
            final chip = scope.subChips[index];
            final selected = chip.route == scope.path;
            return GestureDetector(
              onTap: () => navTo(context, chip.route),
              child: AnimatedContainer(
                duration: AppDurations.fast,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppPalette.copper : AppPalette.surface,
                  borderRadius: AppRadius.allPill,
                  border: Border.all(
                    color: selected ? AppPalette.copper : AppPalette.border,
                  ),
                ),
                child: Text(
                  chip.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    color: selected ? Colors.white : AppPalette.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _activeChipsSliver(BusinessConfig config) {
    final chips = <Widget>[];
    if (_filters.hasPriceBand) {
      chips.add(
        _removableChip(
          label: _priceBandLabel(config),
          color: config.accentColor,
          textColor: config.primaryColor,
          onDeleted: () => _apply(_filters.copyWith(clearPrice: true)),
        ),
      );
    }
    if (_filters.metal != null) {
      chips.add(
        _removableChip(
          label: _filters.metal!,
          onDeleted: () => _apply(_filters.copyWith(clearMetal: true)),
        ),
      );
    }
    if (_filters.purity != null) {
      chips.add(
        _removableChip(
          label: _filters.purity!,
          onDeleted: () => _apply(_filters.copyWith(clearPurity: true)),
        ),
      );
    }
    if (_filters.inStockOnly) {
      chips.add(
        _removableChip(
          label: 'Available now',
          onDeleted: () => _apply(_filters.copyWith(inStockOnly: false)),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.sm,
          AppSpacing.screenH,
          0,
        ),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final chip in chips) chip,
            TextButton(
              onPressed: _resetFilters,
              child: const Text('Clear all'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _removableChip({
    required String label,
    required VoidCallback onDeleted,
    Color? color,
    Color? textColor,
  }) {
    return InputChip(
      label: Text(
        label,
        style: textColor == null ? null : TextStyle(color: textColor),
      ),
      onDeleted: onDeleted,
      deleteIconColor: AppPalette.textSecondary,
      backgroundColor: color ?? AppPalette.surfaceMuted,
      side: const BorderSide(color: AppPalette.border),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
    );
  }

  Widget _controlsSliver(
    BusinessConfig config,
    List<String> purityOptions,
    List<String> metalOptions,
    int total,
    bool showSidebar,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.sm,
          AppSpacing.screenH,
          0,
        ),
        child: Column(
          children: [
            if (widget.scope == null)
              Row(
                children: [
                  Text(
                    '$total designs',
                    style: AppTypography.overline.copyWith(
                      color: AppPalette.textSecondary,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  _viewToggle(),
                ],
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (!showSidebar) ...[
                  Expanded(
                    child: _CollectionControl(
                      icon: Icons.tune_rounded,
                      label: _filters.activeCount == 0
                          ? 'Filter'
                          : 'Filter (${_filters.activeCount})',
                      onTap: () =>
                          _openPanel(config, purityOptions, metalOptions: metalOptions),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CollectionControl(
                      icon: Icons.swap_vert_rounded,
                      label: 'Sort by',
                      onTap: () => _openPanel(
                        config,
                        purityOptions,
                        metalOptions: metalOptions,
                        openSort: true,
                      ),
                    ),
                  ),
                ] else ...[
                  const Spacer(),
                  _sortMenu(),
                  const SizedBox(width: AppSpacing.sm),
                  _densityToggles(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewToggle() {
    return IconButton(
      key: const ValueKey('view-toggle'),
      tooltip: _isGrid ? 'List view' : 'Grid view',
      visualDensity: VisualDensity.compact,
      icon: Icon(_isGrid ? Icons.view_list_outlined : Icons.grid_view),
      onPressed: () => setState(() => _isGrid = !_isGrid),
    );
  }

  Widget _sortMenu() {
    return PopupMenuButton<String>(
      key: const ValueKey('sort-menu'),
      tooltip: 'Sort by',
      onSelected: (value) => _apply(_filters.copyWith(sort: value)),
      itemBuilder: (_) => [
        for (final option in kSortOptions)
          PopupMenuItem(value: option, child: Text(option)),
      ],
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppPalette.border),
          borderRadius: AppRadius.allSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert_rounded, size: 17),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Sort: ${_filters.sort}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(letterSpacing: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _densityToggles() {
    final selected = _density ?? Responsive.gridColumns(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('View', style: AppTypography.label),
        const SizedBox(width: AppSpacing.xs),
        for (final columns in const [3, 4, 5])
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: TextButton(
              key: ValueKey('density-$columns'),
              style: TextButton.styleFrom(
                minimumSize: const Size(36, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                backgroundColor: selected == columns
                    ? AppPalette.copper
                    : Colors.transparent,
                foregroundColor: selected == columns
                    ? Colors.white
                    : AppPalette.textSecondary,
              ),
              onPressed: () => setState(() => _density = columns),
              child: Text('$columns'),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------ grid & co.

  /// Products per grid chunk: two rows at the active column count. After
  /// each chunk a full-width multi-image hero banner drops in before the
  /// grid resumes — the Tanishq rhythm of collage rows, story hero, rows.
  int get _heroChunk {
    final columns = _density ?? Responsive.gridColumns(context);
    return columns * 2;
  }

  Widget _gridSliver(
    List<Product> page,
    BusinessConfig config,
    CommerceStore store,
  ) {
    final chunk = _heroChunk;
    return SliverMainAxisGroup(
      slivers: [
        for (var start = 0; start < page.length; start += chunk) ...[
          // Full-bleed: the grid runs to both screen edges — no gutters —
          // with hairline gaps so photography, not whitespace, owns the row.
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _density ?? Responsive.gridColumns(context),
                childAspectRatio: Responsive.cardAspectRatio(context),
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final product = page[start + i];
                  return ProductCard(
                    product: product,
                    primaryColor: config.primaryColor,
                    accentColor: config.accentColor,
                    currency: config.currencySymbol,
                    showRating: !config.rules.showPrices,
                    showPrice: config.rules.showPrices,
                    autoSlideImages: true,
                    flush: true,
                    liked: store.isWishlisted(product.id),
                    onWishlist: () => store.toggleWishlist(product.id),
                    onTap: () => navTo(context, '/product/${product.id}'),
                  );
                },
                childCount:
                    (start + chunk).clamp(0, page.length) - start,
              ),
            ),
          ),
          if (start + chunk < page.length)
            SliverToBoxAdapter(
              child: _GridHeroTile(
                key: ValueKey('grid-hero-${page[start + chunk].id}'),
                product: page[start + chunk],
                primaryColor: config.primaryColor,
                onTap: () =>
                    navTo(context, '/product/${page[start + chunk].id}'),
              ),
            ),
        ],
      ],
    );
  }

  Widget _listSliver(
    List<Product> page,
    BusinessConfig config,
    CommerceStore store,
  ) {
    // Instagram-style feed: each product owns the full width, its photograph
    // at a portrait ratio with swipeable images + dots underneath, separated
    // by a hairline — no side gutters, no wasted space.
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index.isOdd) return const Divider(height: 2, thickness: 2);
          final product = page[index ~/ 2];
          return _ProductListTile(
            product: product,
            config: config,
            liked: store.isWishlisted(product.id),
            onWishlist: () => store.toggleWishlist(product.id),
            onTap: () => navTo(context, '/product/${product.id}'),
          );
        }, childCount: page.length * 2 - 1),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 42,
            color: AppPalette.textHint,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No designs match', style: AppTypography.subtitle),
          const SizedBox(height: AppSpacing.xs),
          Text('Try removing a filter', style: AppTypography.caption),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'VIEW BESTSELLERS',
            type: AppButtonType.filled,
            onPressed: () => navTo(context, '/bestsellers'),
          ),
        ],
      ),
    );
  }

  Widget _aboutSliver(RouteScope scope) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Responsive.pageInset(context),
          0,
          Responsive.pageInset(context),
          AppSpacing.xxl,
        ),
        child: ExpansionTile(
          title: Text('About this collection', style: AppTypography.subtitle),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(scope.description, style: AppTypography.bodyMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionControl extends StatelessWidget {
  const _CollectionControl({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.textPrimary,
        side: const BorderSide(color: AppPalette.border),
        minimumSize: const Size.fromHeight(46),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
        textStyle: AppTypography.label.copyWith(letterSpacing: 0),
      ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final Product product;
  final BusinessConfig config;
  final bool liked;
  final VoidCallback onWishlist;
  final VoidCallback onTap;

  const _ProductListTile({
    required this.product,
    required this.config,
    required this.liked,
    required this.onWishlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showPrice = config.rules.showPrices;

    return Material(
      color: AppPalette.surface,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          // Hero geometry: the photograph is the whole card — a tall
          // full-width frame you swipe through, not a tile with a caption
          // block eating the space underneath.
          aspectRatio: 0.8,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProductImageCarousel(
                images: product.images,
                placeholderIcon: product.icon,
                placeholderColor: config.accentColor,
                placeholderAccent: config.primaryColor,
                autoSlide: false,
                showDots: product.hasMultipleImages,
                showCounter: product.hasMultipleImages,
                borderRadius: BorderRadius.zero,
              ),
              if (product.badges.isNotEmpty)
                Positioned(
                  left: AppSpacing.md,
                  top: AppSpacing.md,
                  child: ProductBadge(
                    label: product.badges.first,
                    background: Colors.white.withValues(alpha: .94),
                    foreground: AppPalette.textPrimary,
                  ),
                ),
              if (product.hasDiscount && showPrice)
                Positioned(
                  left: AppSpacing.md,
                  bottom: AppSpacing.lg + 18,
                  child: ProductBadge(
                    label: '${product.discountPercent}% off',
                    background: config.primaryColor,
                    foreground: Colors.white,
                  ),
                ),
              Positioned(
                right: AppSpacing.xs,
                top: AppSpacing.xs,
                child: WishlistButton(liked: liked, onTap: onWishlist),
              ),
              // Hero-style caption strip: brand, name and price ride the
              // gradient at the bottom of the photograph itself. Extra
              // bottom padding keeps the swipe dots visible below it.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.68),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.lg + 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.brand.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.overline.copyWith(
                        color: Colors.white.withValues(alpha: .85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.subtitle.copyWith(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (showPrice)
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    Pricing.money(
                                      product.price,
                                      currencySymbol: config.currencySymbol,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.price.copyWith(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (product.hasDiscount) ...[
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      Pricing.money(
                                        product.mrp,
                                        currencySymbol: config.currencySymbol,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.priceStrike
                                          .copyWith(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        else
                          Text(
                            'Contact for Price',
                            style: AppTypography.subtitle.copyWith(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        const Spacer(),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: RatingChip(
                            rating: product.rating,
                            reviewCount: product.reviewCount,
                            compact: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!product.inStock)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.72),
                    child: const Center(
                      child: ProductBadge(
                        label: 'Out of stock',
                        background: AppPalette.textPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-bleed editorial banner dropped between grid chunks — the multi-layout
/// hero that breaks the product rows like the Tanishq catalogue.
class _GridHeroTile extends StatelessWidget {
  const _GridHeroTile({
    super.key,
    required this.product,
    required this.primaryColor,
    required this.onTap,
  });

  final Product product;
  final Color primaryColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.surface,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 2.05,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Multi-image hero: the product's angles swipe in place with
              // dots and a counter — a collage you scroll through, not a
              // single frozen banner.
              ProductImageCarousel(
                images: product.images,
                placeholderIcon: product.icon,
                placeholderColor: primaryColor.withValues(alpha: 0.12),
                placeholderAccent: primaryColor,
                autoSlide: true,
                showDots: true,
                showCounter: true,
                borderRadius: BorderRadius.zero,
              ),
              // Readable label strip; the photos stay the hero.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.62),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.screenH,
                right: AppSpacing.screenH,
                bottom: AppSpacing.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.category.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.overline.copyWith(
                        color: Colors.white.withValues(alpha: .85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Explore ${product.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
