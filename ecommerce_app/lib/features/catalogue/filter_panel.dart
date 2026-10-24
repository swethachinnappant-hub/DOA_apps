import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

/// Sort choices for every listing surface (§7.1).
const List<String> kSortOptions = [
  'Featured',
  'Newest',
  'Price: Low to High',
  'Price: High to Low',
  'Best sellers',
  'Discount',
];

/// Metal swatches offered by the filter (§7.1).
const List<String> kMetalOptions = [
  'Yellow Gold',
  'Rose Gold',
  'White Gold',
  'Platinum',
];

/// Immutable filter/sort state shared by the toolbar, chips, sidebar and the
/// refine panel of one listing.
class ListingFilters {
  final String category;
  final int? priceMin;
  final int? priceMax;
  final bool inStockOnly;
  final String? purity;
  final String? metal;
  final String sort;

  const ListingFilters({
    this.category = 'All',
    this.priceMin,
    this.priceMax,
    this.inStockOnly = false,
    this.purity,
    this.metal,
    this.sort = 'Featured',
  });

  bool get hasPriceBand => priceMin != null || priceMax != null;

  int get activeCount =>
      (category == 'All' ? 0 : 1) +
      (hasPriceBand ? 1 : 0) +
      (inStockOnly ? 1 : 0) +
      (purity == null ? 0 : 1) +
      (metal == null ? 0 : 1);

  bool get isEmpty => activeCount == 0;

  ListingFilters copyWith({
    String? category,
    int? priceMin,
    int? priceMax,
    bool? inStockOnly,
    String? purity,
    String? metal,
    String? sort,
    bool clearPrice = false,
    bool clearPurity = false,
    bool clearMetal = false,
  }) {
    return ListingFilters(
      category: category ?? this.category,
      priceMin: clearPrice ? null : (priceMin ?? this.priceMin),
      priceMax: clearPrice ? null : (priceMax ?? this.priceMax),
      inStockOnly: inStockOnly ?? this.inStockOnly,
      purity: clearPurity ? null : (purity ?? this.purity),
      metal: clearMetal ? null : (metal ?? this.metal),
      sort: sort ?? this.sort,
    );
  }
}

/// The shared "Refine collection" panel (§7.1): Filter / Sort tabs with the
/// apply-footer used by the compact bottom sheet and the medium right drawer.
///
/// With [live] it renders as the always-visible Expanded sidebar: no tabs, no
/// footer, every change reaches the listing immediately.
class FilterPanel extends StatefulWidget {
  const FilterPanel({
    super.key,
    required this.filters,
    required this.currencySymbol,
    required this.purityOptions,
    required this.onApply,
    required this.onClear,
    this.metalOptions = kMetalOptions,
    this.showPriceRange = true,
    this.live = false,
    this.openSort = false,
  });

  final ListingFilters filters;
  final String currencySymbol;
  final List<String> purityOptions;

  /// Metal facets that actually match at least one product in the current
  /// result set — the caller derives this from the catalogue so listings
  /// without metal-bearing stock show no Metal block at all.
  final List<String> metalOptions;

  /// False when the business hides prices (the price range would filter on
  /// figures the shopper cannot see).
  final bool showPriceRange;

  final ValueChanged<ListingFilters> onApply;
  final VoidCallback onClear;

  /// Sidebar mode: changes apply as they are made.
  final bool live;
  final bool openSort;

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late int? _priceMin;
  late int? _priceMax;
  late bool _inStockOnly;
  late String? _purity;
  late String? _metal;
  late String _sort;

  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _priceMin = widget.filters.priceMin;
    _priceMax = widget.filters.priceMax;
    _inStockOnly = widget.filters.inStockOnly;
    _purity = widget.filters.purity;
    _metal = widget.filters.metal;
    _sort = widget.filters.sort;
    _minController.text = _priceMin?.toString() ?? '';
    _maxController.text = _priceMax?.toString() ?? '';
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FilterPanel old) {
    super.didUpdateWidget(old);
    final next = widget.filters;
    if (next.priceMin != _priceMin) {
      _priceMin = next.priceMin;
      _minController.text = next.priceMin?.toString() ?? '';
    }
    if (next.priceMax != _priceMax) {
      _priceMax = next.priceMax;
      _maxController.text = next.priceMax?.toString() ?? '';
    }
    if (next.inStockOnly != _inStockOnly) _inStockOnly = next.inStockOnly;
    if (next.purity != _purity) _purity = next.purity;
    if (next.metal != _metal) _metal = next.metal;
    if (next.sort != _sort) _sort = next.sort;
  }

  ListingFilters get _current => ListingFilters(
    category: widget.filters.category,
    priceMin: _priceMin,
    priceMax: _priceMax,
    inStockOnly: _inStockOnly,
    purity: _purity,
    metal: _metal,
    sort: _sort,
  );

  void _commit() {
    if (widget.live) {
      widget.onApply(_current);
    } else {
      setState(() {});
    }
  }

  void _readPrice() {
    _priceMin = int.tryParse(_minController.text.trim());
    _priceMax = int.tryParse(_maxController.text.trim());
  }

  void _validateAndApply() {
    _readPrice();
    if (_priceMin != null && _priceMax != null && _priceMin! > _priceMax!) {
      setState(() => _error = 'Minimum price must be below maximum price');
      return;
    }
    _error = null;
    widget.onApply(_current);
    Navigator.pop(context);
  }

  void _clearAll() {
    widget.onClear();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // One shared left/right edge (16 = screenH) for every surface of the
    // panel: header, sort radios, filter fields and footer buttons all
    // start and end on the same line.
    final filtersTab = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: _filterFields(),
    );

    if (widget.live) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: filtersTab),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () {
                widget.onClear();
              },
              child: const Text('Clear all'),
            ),
          ),
        ],
      );
    }

    return DefaultTabController(
      length: 2,
      initialIndex: widget.openSort ? 1 : 0,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text('Filters & sort', style: AppTypography.headline),
                ),
                IconButton(
                  tooltip: 'Close filters and sort',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const TabBar(
            indicatorColor: AppPalette.textPrimary,
            labelColor: AppPalette.textPrimary,
            unselectedLabelColor: AppPalette.textSecondary,
            labelStyle: AppTypography.label,
            dividerColor: AppPalette.divider,
            tabs: [
              Tab(text: 'FILTER'),
              Tab(text: 'SORT BY'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                filtersTab,
                ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  children: [
                    for (final option in kSortOptions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: _sort == option
                              ? AppPalette.surfaceMuted
                              : Colors.transparent,
                          borderRadius: AppRadius.allSm,
                          child: InkWell(
                            borderRadius: AppRadius.allSm,
                            onTap: () => setState(() => _sort = option),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 13,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: AppTypography.body.copyWith(
                                        fontSize: 14,
                                        fontWeight: _sort == option
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  if (_sort == option)
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: AppPalette.textPrimary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: _clearAll,
                      child: const Text('Clear filters'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPalette.textPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: _validateAndApply,
                      child: const Text('Show pieces'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Availability', style: AppTypography.subtitle),
        CheckboxListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _inStockOnly,
          onChanged: (value) {
            _inStockOnly = value ?? false;
            _commit();
          },
          title: const Text('Available now'),
        ),
        if (widget.purityOptions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Gold purity', style: AppTypography.subtitle),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final purity in widget.purityOptions)
                _facetChip(
                  label: purity,
                  selected: _purity == purity,
                  onSelected: (selected) {
                    _purity = selected ? purity : null;
                    _commit();
                  },
                ),
            ],
          ),
        ],
        if (widget.metalOptions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Metal', style: AppTypography.subtitle),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final metal in widget.metalOptions)
                _facetChip(
                  label: metal,
                  selected: _metal == metal,
                  onSelected: (selected) {
                    _metal = selected ? metal : null;
                    _commit();
                  },
                ),
            ],
          ),
        ],
        if (widget.showPriceRange) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Price range', style: AppTypography.subtitle),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _minController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    _readPrice();
                    _commit();
                  },
                  decoration: InputDecoration(
                    labelText: 'From',
                    prefixText: '${widget.currencySymbol} ',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextFormField(
                  controller: _maxController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    _readPrice();
                    _commit();
                  },
                  decoration: InputDecoration(
                    labelText: 'To',
                    prefixText: '${widget.currencySymbol} ',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: AppTypography.caption.copyWith(color: AppPalette.error),
            ),
          ],
        ],
      ],
    );
  }

  Widget _facetChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      selectedColor: AppPalette.textPrimary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppPalette.textPrimary : AppPalette.border,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allPill),
      labelStyle: AppTypography.label.copyWith(
        color: selected ? Colors.white : AppPalette.textPrimary,
        fontSize: 12,
      ),
    );
  }
}
