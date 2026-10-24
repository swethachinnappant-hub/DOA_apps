import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/navigation/nav_helpers.dart';
import '../core/pricing.dart';
import '../core/product.dart';
import '../core/store/commerce_store.dart';
import '../features/config/providers/business_config_provider.dart';

/// Opens the MOQ / bulk-tier quantity picker and adds the chosen amount to
/// the cart. Shared by the home rails and the catalogue grid so every quick
/// add behaves identically (UI spec §6.37).
Future<void> showQuickAddSheet(
  BuildContext context,
  Product product,
  CommerceStore store,
) async {
  if (product.needsVariantSelection) {
    navTo(context, '/product/${product.id}');
    return;
  }
  final quantities = <int>{
    product.minimumOrderQuantity,
    for (final tier in product.wholesalePriceTiers) tier.minimumQuantity,
  }.where((quantity) {
    return product.ownerId.isEmpty || quantity <= product.stock;
  }).toList()..sort();
  if (quantities.isEmpty) return;

  final quantity = quantities.length == 1
      ? quantities.single
      : await showModalBottomSheet<int>(
          context: context,
          showDragHandle: true,
          builder: (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text('Choose order quantity', style: AppTypography.subtitle),
                ),
                for (final amount in quantities)
                  ListTile(
                    title: Text('$amount units'),
                    subtitle: Text(
                      '${Pricing.money(product.unitPriceForQuantity(amount), currencySymbol: context.read<BusinessConfigProvider>().config.currencySymbol)} per unit',
                    ),
                    onTap: () => Navigator.pop(sheetContext, amount),
                  ),
              ],
            ),
          ),
        );
  if (quantity == null || !context.mounted) return;
  final added = store.addToCart(product, quantity: quantity);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          added <= 0
              ? 'Available stock cannot cover that order quantity'
              : 'Added $quantity × ${product.name} to cart',
        ),
        duration: const Duration(milliseconds: 1500),
      ),
    );
}
