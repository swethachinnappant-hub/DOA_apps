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
    this.initialMetal,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final title = config.type == BusinessType.jewellery
        ? 'Jewellery'
        : 'Catalogue';

    return Scaffold(
      // One AppBar shape at every layout class: the back affordance and the
      // title sit on the same metrics as every other pushed screen, whether
      // the listing is a tab (onExit) or a pushed route.
      appBar: AppBar(
        title: Text(
          title,
          style: AppTypography.title.copyWith(letterSpacing: 0.2),
        ),
        leading: onExit != null
            ? IconButton(
                tooltip: 'Back to home',
                onPressed: onExit,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: ListingView(
        categoryChips: ['All', ...config.categories],
        showSearchField: true,
        initialCategory: initialCategory,
        initialQuery: initialQuery,
        initialPriceMin: priceMin,
        initialPriceMax: priceMax,
        initialMetal: initialMetal,
      ),
    );
  }
}
