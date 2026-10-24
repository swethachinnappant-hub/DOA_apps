import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';
import 'package:provider/provider.dart';

import '../../config/providers/business_config_provider.dart';
import '../../../core/business_config.dart';
import '../listing_view.dart';

/// The canonical PLP (§7): a thin shell around [ListingView] that supplies
/// the app bar, the business category chips and any deep-link filters.
class CatalogueScreen extends StatelessWidget {
  /// Category and price band handed in from a deep link, e.g. a home tile
  /// that promises to open this category or price range.
  final String? initialCategory;
  final int? priceMin;
  final int? priceMax;
  final String? initialQuery;
  final String? initialSort;

  /// Metal shade from a home hero or nav link, e.g. `/catalogue?metal=Rose%20Gold`.
  final String? initialMetal;

  /// Exit action used when the catalogue is embedded in the customer tab shell.
  /// Standalone catalogue routes continue to use normal route back navigation.
  final VoidCallback? onExit;

  const CatalogueScreen({
    super.key,
    this.initialCategory,
    this.priceMin,
    this.priceMax,
    this.initialQuery,
    this.initialSort,
    this.initialMetal,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final title = config.type == BusinessType.jewellery
        ? 'Jewellery'
        : 'Catalogue';

    // Keep the back control and title on a shared compact baseline.
    final canBack = onExit != null || Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: canBack ? 48 : null,
        titleSpacing: canBack ? 0 : null,
        title: Text(
          title,
          style: AppTypography.title.copyWith(
            fontSize: 18,
            letterSpacing: 0,
          ),
        ),
        leading: canBack
            ? IconButton(
                tooltip: onExit != null ? 'Back to home' : 'Back',
                onPressed: onExit ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: ListingView(
        categoryChips: config.categories,
        showSearchField: true,
        initialCategory: initialCategory,
        initialQuery: initialQuery,
        initialSort: initialSort,
        initialPriceMin: priceMin,
        initialPriceMax: priceMax,
        initialMetal: initialMetal,
      ),
    );
  }
}
