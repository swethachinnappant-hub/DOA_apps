import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:common_widgets/common_widgets.dart';
import '../../config/providers/business_config_provider.dart';
import '../../../core/business_config.dart';
import '../../../core/pricing.dart';
import '../../../core/product.dart';
import '../../../core/store/commerce_store.dart';
import '../../../widgets/product_card.dart';

class CatalogueScreen extends StatefulWidget {
  /// Category and price band handed in from a deep link, e.g. a home tile
  /// that promises to open this category or price range.
  final String? initialCategory;
  final int? priceMin;
  final int? priceMax;

  /// Exit action used when the catalogue is embedded in the customer tab shell.
  /// Standalone catalogue routes continue to use normal route back navigation.
  final VoidCallback? onExit;

  const CatalogueScreen({
    super.key,
    this.initialCategory,
    this.priceMin,
    this.priceMax,
    this.onExit,
  });

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  late String _selectedCategory;
  late int? _priceMin;
  late int? _priceMax;
  bool _inStockOnly = false;
  String? _selectedPurity;
  String _sortBy = 'Recommended';
  bool _isGrid = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
    _priceMin = widget.priceMin;
    _priceMax = widget.priceMax;
  }

  bool get _hasPriceBand => _priceMin != null || _priceMax != null;

  String get _priceBandLabel {
    final symbol = context.read<BusinessConfigProvider>().config.currencySymbol;
    if (_priceMin != null && _priceMax != null) {
      return '${Pricing.money(_priceMin!, currencySymbol: symbol)} – ${Pricing.money(_priceMax!, currencySymbol: symbol)}';
    }
    if (_priceMax != null) {
      return 'Under ${Pricing.money(_priceMax!, currencySymbol: symbol)}';
    }
    return '${Pricing.money(_priceMin!, currencySymbol: symbol)} & above';
  }

  Future<void> _showCollectionOptions(
    BusinessConfig config,
    List<Product> products, {
    bool openSort = false,
  }) async {
    var minText = _priceMin?.toString() ?? '';
    var maxText = _priceMax?.toString() ?? '';
    String? error;
    var onlyAvailable = _inStockOnly;
    var selectedPurity = _selectedPurity;
    var selectedSort = _sortBy;
    const sortOptions = [
      'Recommended',
      'Newest',
      'Price: Low to High',
      'Price: High to Low',
      'Top Rated',
    ];
    final purityOptions =
        products
            .expand(
              (product) => product.specs.entries
                  .where((entry) => entry.key.toLowerCase().contains('purity'))
                  .map((entry) => entry.value.trim()),
            )
            .where((purity) => purity.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final filterPanel = DefaultTabController(
      length: 2,
      initialIndex: openSort ? 1 : 0,
      child: StatefulBuilder(
        builder: (panelContext, setPanelState) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Refine collection',
                      style: AppTypography.headline,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close filters and sort',
                    onPressed: () => Navigator.pop(panelContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.tune_rounded), text: 'Filter'),
                Tab(icon: Icon(Icons.swap_vert_rounded), text: 'Sort by'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Availability', style: AppTypography.subtitle),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: onlyAvailable,
                          onChanged: (value) => setPanelState(
                            () => onlyAvailable = value ?? false,
                          ),
                          title: const Text('Available now'),
                          subtitle: const Text('Ready to order'),
                        ),
                        if (purityOptions.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text('Gold purity', style: AppTypography.subtitle),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final purity in purityOptions)
                                ChoiceChip(
                                  label: Text(purity),
                                  selected: selectedPurity == purity,
                                  onSelected: (selected) => setPanelState(
                                    () => selectedPurity = selected
                                        ? purity
                                        : null,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        Text('Price range', style: AppTypography.subtitle),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: minText,
                                keyboardType: TextInputType.number,
                                onChanged: (value) => minText = value,
                                decoration: InputDecoration(
                                  labelText: 'Minimum',
                                  prefixText: '${config.currencySymbol} ',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: TextFormField(
                                initialValue: maxText,
                                keyboardType: TextInputType.number,
                                onChanged: (value) => maxText = value,
                                decoration: InputDecoration(
                                  labelText: 'Maximum',
                                  prefixText: '${config.currencySymbol} ',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (error != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            error!,
                            style: AppTypography.caption.copyWith(
                              color: AppPalette.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      for (final option in sortOptions)
                        ListTile(
                          title: Text(option, style: AppTypography.body),
                          leading: Icon(
                            selectedSort == option
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selectedSort == option
                                ? AppPalette.textPrimary
                                : AppPalette.textHint,
                          ),
                          onTap: () =>
                              setPanelState(() => selectedSort = option),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _priceMin = null;
                            _priceMax = null;
                            _inStockOnly = false;
                            _selectedPurity = null;
                            _selectedCategory = 'All';
                          });
                          Navigator.pop(panelContext);
                        },
                        child: const Text('Clear filters'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: config.primaryColor,
                          foregroundColor: config.onPrimaryColor,
                        ),
                        onPressed: () {
                          final min = int.tryParse(minText.trim());
                          final max = int.tryParse(maxText.trim());
                          if (min != null && max != null && min > max) {
                            setPanelState(
                              () => error =
                                  'Minimum price must be below maximum price',
                            );
                            return;
                          }
                          setState(() {
                            _priceMin = min;
                            _priceMax = max;
                            _inStockOnly = onlyAvailable;
                            _selectedPurity = selectedPurity;
                            _sortBy = selectedSort;
                          });
                          Navigator.pop(panelContext);
                        },
                        child: const Text('Show pieces'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
                child: filterPanel,
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
            FractionallySizedBox(heightFactor: 0.88, child: filterPanel),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final allCategories = ['All', ...config.categories];
    final products = store.shopProducts;
    final visible = _selectedCategory == 'All'
        ? products
        : products.where((p) => p.category == _selectedCategory).toList();
    final inBand = _hasPriceBand
        ? visible
              .where(
                (p) =>
                    (_priceMin == null || p.price >= _priceMin!) &&
                    (_priceMax == null || p.price <= _priceMax!),
              )
              .toList()
        : visible;
    final sorted = _sort(inBand);
    final available = _inStockOnly
        ? sorted.where((product) => product.isAvailable).toList()
        : sorted;
    final purityFiltered = _selectedPurity == null
        ? available
        : available
              .where(
                (product) => product.specs.entries.any(
                  (entry) =>
                      entry.key.toLowerCase().contains('purity') &&
                      entry.value.trim() == _selectedPurity,
                ),
              )
              .toList();
    final activeFilterCount =
        (_selectedCategory == 'All' ? 0 : 1) +
        (_hasPriceBand ? 1 : 0) +
        (_inStockOnly ? 1 : 0) +
        (_selectedPurity == null ? 0 : 1);

    return Scaffold(
      appBar: widget.onExit != null
          ? null
          : AppBar(
              title: Text(
                config.type == BusinessType.jewellery
                    ? 'Jewellery'
                    : 'Catalogue',
                style: AppTypography.title.copyWith(letterSpacing: 0.2),
              ),
              actions: [
                IconButton(
                  tooltip: _isGrid ? 'List view' : 'Grid view',
                  icon: Icon(
                    _isGrid ? Icons.view_list_outlined : Icons.grid_view,
                  ),
                  onPressed: () => setState(() => _isGrid = !_isGrid),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.onExit != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Back to home',
                          onPressed: widget.onExit,
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            config.type == BusinessType.jewellery
                                ? 'Jewellery'
                                : 'Catalogue',
                            style: AppTypography.title.copyWith(
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: _isGrid ? 'List view' : 'Grid view',
                          icon: Icon(
                            _isGrid
                                ? Icons.view_list_outlined
                                : Icons.grid_view,
                          ),
                          onPressed: () => setState(() => _isGrid = !_isGrid),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppSearchField(hint: config.searchHint),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: allCategories.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.chipGap),
                    itemBuilder: (context, index) {
                      final cat = allCategories[index];
                      final selected = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: AppDurations.fast,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? config.primaryColor
                                : AppPalette.surface,
                            borderRadius: AppRadius.allPill,
                            border: Border.all(
                              color: selected
                                  ? config.primaryColor
                                  : AppPalette.border,
                            ),
                          ),
                          child: Text(
                            cat,
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
                if (_hasPriceBand)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH,
                      AppSpacing.sm,
                      AppSpacing.screenH,
                      0,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: _clearPriceBand,
                        borderRadius: AppRadius.allPill,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: config.accentColor,
                            borderRadius: AppRadius.allPill,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _priceBandLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.label.copyWith(
                                    color: config.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Icon(
                                Icons.close,
                                size: 15,
                                color: config.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_selectedPurity != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: InputChip(
                        label: Text(_selectedPurity!),
                        onDeleted: () => setState(() => _selectedPurity = null),
                        deleteIconColor: AppPalette.textSecondary,
                        backgroundColor: AppPalette.surfaceMuted,
                        side: const BorderSide(color: AppPalette.border),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.allSm,
                        ),
                      ),
                    ),
                  ),
                if (_inStockOnly)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: InputChip(
                        label: const Text('Available now'),
                        onDeleted: () => setState(() => _inStockOnly = false),
                        deleteIconColor: AppPalette.textSecondary,
                        backgroundColor: AppPalette.surfaceMuted,
                        side: const BorderSide(color: AppPalette.border),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.allSm,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '${purityFiltered.length} ${purityFiltered.length == 1 ? 'PIECE' : 'PIECES'}',
                            style: AppTypography.overline.copyWith(
                              color: AppPalette.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          if (activeFilterCount > 0)
                            TextButton(
                              onPressed: () => setState(() {
                                _selectedCategory = 'All';
                                _priceMin = null;
                                _priceMax = null;
                                _inStockOnly = false;
                                _selectedPurity = null;
                              }),
                              child: const Text('Clear all'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _CollectionControl(
                              icon: Icons.tune_rounded,
                              label: activeFilterCount == 0
                                  ? 'Filter'
                                  : 'Filter ($activeFilterCount)',
                              onTap: () =>
                                  _showCollectionOptions(config, products),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _CollectionControl(
                              icon: Icons.swap_vert_rounded,
                              label: 'Sort by',
                              onTap: () => _showCollectionOptions(
                                config,
                                products,
                                openSort: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (purityFiltered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                onReset: () => setState(() {
                  _selectedCategory = 'All';
                  _priceMin = null;
                  _priceMax = null;
                  _inStockOnly = false;
                  _selectedPurity = null;
                }),
              ),
            )
          else if (_isGrid)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: Responsive.gridColumns(context),
                  childAspectRatio: Responsive.cardAspectRatio(context),
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 28,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ProductCard(
                    product: purityFiltered[index],
                    primaryColor: config.primaryColor,
                    accentColor: config.accentColor,
                    currency: config.currencySymbol,
                    showRating: !config.rules.showPrices,
                    showPrice: config.rules.showPrices,
                    liked: store.isWishlisted(purityFiltered[index].id),
                    onWishlist: () =>
                        store.toggleWishlist(purityFiltered[index].id),
                    onTap: () =>
                        context.push('/product/${purityFiltered[index].id}'),
                  ),
                  childCount: purityFiltered.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.xs,
                AppSpacing.screenH,
                AppSpacing.screenV,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index.isOdd) {
                    return const SizedBox(height: AppSpacing.listGap);
                  }
                  final product = purityFiltered[index ~/ 2];
                  return _ProductListTile(
                    product: product,
                    config: config,
                    liked: store.isWishlisted(product.id),
                    onWishlist: () => store.toggleWishlist(product.id),
                    onTap: () => context.push('/product/${product.id}'),
                  );
                }, childCount: purityFiltered.length * 2 - 1),
              ),
            ),
        ],
      ),
    );
  }

  void _clearPriceBand() {
    setState(() {
      _priceMin = null;
      _priceMax = null;
    });
  }

  List<Product> _sort(List<Product> items) {
    switch (_sortBy) {
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
      case 'Top Rated':
        return [...items]..sort((a, b) => b.rating.compareTo(a.rating));
      default:
        return items;
    }
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onReset;

  const _EmptyState({required this.onReset});

  @override
  Widget build(BuildContext context) {
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
          Text('Nothing here yet', style: AppTypography.subtitle),
          const SizedBox(height: AppSpacing.xs),
          Text('Try a different category', style: AppTypography.caption),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'View all products',
            type: AppButtonType.outlined,
            onPressed: onReset,
          ),
        ],
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
      borderRadius: AppRadius.allMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allMd,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.allMd,
            border: Border.all(color: AppPalette.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  height: 92,
                  width: 72,
                  child: ProductImageCarousel(
                    images: product.images,
                    placeholderIcon: product.icon,
                    placeholderColor: config.accentColor,
                    placeholderAccent: config.primaryColor,
                    showDots: false,
                    showCounter: product.hasMultipleImages,
                    borderRadius: AppRadius.allSm,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.brand.toUpperCase(),
                        style: AppTypography.overline.copyWith(
                          fontSize: 9.5,
                          color: AppPalette.textHint,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.subtitle.copyWith(fontSize: 13.5),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          RatingChip(rating: product.rating),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              product.deliveryLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                color: AppPalette.textHint,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (showPrice)
                        Row(
                          children: [
                            Text(
                              Pricing.money(
                                product.price,
                                currencySymbol: config.currencySymbol,
                              ),
                              style: AppTypography.price.copyWith(
                                fontSize: 14.5,
                              ),
                            ),
                            if (product.hasDiscount) ...[
                              const SizedBox(width: 5),
                              Text(
                                Pricing.money(
                                  product.mrp,
                                  currencySymbol: config.currencySymbol,
                                ),
                                style: AppTypography.priceStrike.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${product.discountPercent}% off',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11,
                                  color: AppPalette.goldDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        )
                      else
                        Text(
                          'Contact for Price',
                          style: AppTypography.subtitle.copyWith(
                            fontSize: 13,
                            color: AppPalette.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                WishlistButton(liked: liked, onTap: onWishlist),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
