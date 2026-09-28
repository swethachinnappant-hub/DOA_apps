import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:common_widgets/common_widgets.dart';
import '../../config/providers/business_config_provider.dart';
import '../../../core/business_config.dart';
import '../../../core/product.dart';
import '../../../core/store/commerce_store.dart';
import '../../../widgets/product_card.dart';

class CatalogueScreen extends StatefulWidget {
  /// Category and price band handed in from a deep link, e.g. a home tile
  /// that promises to open this category or price range.
  final String? initialCategory;
  final int? priceMin;
  final int? priceMax;

  const CatalogueScreen({
    super.key,
    this.initialCategory,
    this.priceMin,
    this.priceMax,
  });

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  late String _selectedCategory;
  late int? _priceMin;
  late int? _priceMax;
  String _sortBy = 'Newest';
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
      return '$symbol$_priceMin – $symbol$_priceMax';
    }
    if (_priceMax != null) return 'Under $symbol$_priceMax';
    return '$symbol$_priceMin & above';
  }

  Future<void> _showPriceFilters(BusinessConfig config) async {
    final minController = TextEditingController(
      text: _priceMin?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: _priceMax?.toString() ?? '',
    );
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final keyboardInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + keyboardInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filter pieces',
                        style: AppTypography.headline,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close filters',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Price range', style: AppTypography.subtitle),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Minimum price',
                          prefixText: '${config.currencySymbol} ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextField(
                        controller: maxController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Maximum price',
                          prefixText: '${config.currencySymbol} ',
                          border: OutlineInputBorder(),
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
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _priceMin = null;
                            _priceMax = null;
                          });
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Clear price'),
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
                          final min = int.tryParse(minController.text.trim());
                          final max = int.tryParse(maxController.text.trim());
                          if (min != null && max != null && min > max) {
                            setSheetState(
                              () => error =
                                  'Minimum price must be below maximum price',
                            );
                            return;
                          }
                          setState(() {
                            _priceMin = min;
                            _priceMax = max;
                          });
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Show pieces'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    minController.dispose();
    maxController.dispose();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          config.type == BusinessType.jewellery ? 'Jewellery' : 'Catalogue',
          style: AppTypography.title.copyWith(letterSpacing: 0.2),
        ),
        actions: [
          IconButton(
            tooltip: _isGrid ? 'List view' : 'Grid view',
            icon: Icon(_isGrid ? Icons.view_list_outlined : Icons.grid_view),
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        Icon(Icons.close, size: 15, color: config.primaryColor),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 14, 12),
            child: Row(
              children: [
                Text(
                  '${sorted.length} PIECES',
                  style: AppTypography.overline.copyWith(
                    color: AppPalette.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _showPriceFilters(config),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.textPrimary,
                    side: const BorderSide(color: AppPalette.border),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                  icon: const Icon(Icons.tune, size: 16),
                  label: Text(_hasPriceBand ? 'Filter 1' : 'Filter'),
                ),
                const Spacer(),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isDense: true,
                    borderRadius: AppRadius.allMd,
                    icon: const Icon(Icons.expand_more, size: 20),
                    style: AppTypography.label,
                    items:
                        const ['Newest', 'Price: Low', 'Price: High', 'Rating']
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s, style: AppTypography.label),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _sortBy = v ?? 'Newest'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: sorted.isEmpty
                ? _EmptyState(
                    onReset: () => setState(() {
                      _selectedCategory = 'All';
                      _priceMin = null;
                      _priceMax = null;
                    }),
                  )
                : _isGrid
                ? GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Responsive.gridColumns(context),
                      childAspectRatio: Responsive.cardAspectRatio(context),
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 28,
                    ),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) => ProductCard(
                      product: sorted[index],
                      primaryColor: config.primaryColor,
                      accentColor: config.accentColor,
                      currency: config.currencySymbol,
                      showRating: !config.rules.showPrices,
                      showPrice: config.rules.showPrices,
                      liked: store.isWishlisted(sorted[index].id),
                      onWishlist: () => store.toggleWishlist(sorted[index].id),
                      onTap: () => context.push('/product/${sorted[index].id}'),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH,
                      AppSpacing.xs,
                      AppSpacing.screenH,
                      AppSpacing.screenV,
                    ),
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.listGap),
                    itemBuilder: (context, index) => _ProductListTile(
                      product: sorted[index],
                      config: config,
                      liked: store.isWishlisted(sorted[index].id),
                      onWishlist: () => store.toggleWishlist(sorted[index].id),
                      onTap: () => context.push('/product/${sorted[index].id}'),
                    ),
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
      case 'Price: Low':
        return [...items]..sort((a, b) => a.price.compareTo(b.price));
      case 'Price: High':
        return [...items]..sort((a, b) => b.price.compareTo(a.price));
      case 'Rating':
        return [...items]..sort((a, b) => b.rating.compareTo(a.rating));
      default:
        return items;
    }
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
                              '${config.currencySymbol}${product.price}',
                              style: AppTypography.price.copyWith(
                                fontSize: 14.5,
                              ),
                            ),
                            if (product.hasDiscount) ...[
                              const SizedBox(width: 5),
                              Text(
                                '${config.currencySymbol}${product.mrp}',
                                style: AppTypography.priceStrike.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${product.discountPercent}% off',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11,
                                  color: AppPalette.success,
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
