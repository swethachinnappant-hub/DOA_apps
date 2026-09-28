import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/business_config.dart';
import '../../../core/product.dart';
import '../../../core/pricing.dart';
import '../../../core/store/commerce_store.dart';
import '../../config/providers/business_config_provider.dart';

/// The shopper's saved products, backed by the shared store so a heart
/// toggled on a card or the detail page is reflected here instantly.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final products = store.wishlistProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: [
          if (products.isNotEmpty)
            IconButton(
              tooltip: 'Remove all',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, store, products.length),
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: products.isEmpty
          ? _empty(context)
          : ListView.separated(
              padding: Responsive.padding(context),
              itemCount: products.length,
              separatorBuilder: (_, _) =>
                  SizedBox(height: Responsive.spacing(context, mobile: 8)),
              itemBuilder: (context, index) =>
                  _tile(context, config, store, products[index]),
            ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No items in wishlist',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, mobile: 16),
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the heart on any product to save it here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, mobile: 13),
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    BusinessConfig config,
    CommerceStore store,
    Product product,
  ) {
    final showPrice = config.rules.showPrices;
    final accent = config.accentColor;
    final primary = config.primaryColor;

    return AppCard(
      onTap: () => context.push('/product/${product.id}'),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 60,
              child: product.images.isEmpty
                  ? ColoredBox(
                      color: accent,
                      child: Icon(
                        config.icon,
                        size: 28,
                        color: primary.withValues(alpha: 0.5),
                      ),
                    )
                  : ProductImageTile(
                      url: product.images.first,
                      fit: BoxFit.cover,
                      placeholderIcon: config.icon,
                      placeholderColor: accent,
                      placeholderAccent: primary,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.brand.toUpperCase()} · ${product.sku}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 11),
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              showPrice
                  ? Text(
                      Pricing.money(
                        product.price,
                        currencySymbol: config.currencySymbol,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, mobile: 14),
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    )
                  : Text(
                      'Contact for Price',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, mobile: 12),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
              const SizedBox(height: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Remove from wishlist',
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red[300],
                ),
                onPressed: () => store.toggleWishlist(product.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    CommerceStore store,
    int count,
  ) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Clear wishlist?',
      message: 'This removes all $count saved item(s).',
      confirmText: 'Clear all',
      confirmColor: Colors.red,
    );
    if (confirmed != true) return;

    // Snapshot first: every toggle notifies and rebuilds the list.
    final saved = List.of(store.wishlistProducts);
    for (final product in saved) {
      store.toggleWishlist(product.id);
    }
  }
}
