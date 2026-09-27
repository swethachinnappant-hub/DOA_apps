import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/product.dart';
import '../../../core/store/commerce_store.dart';
import '../../auth/providers/auth_provider.dart';
import '../../config/providers/business_config_provider.dart';

/// The seller's inventory list with inline stock control.
///
/// Stock is the number sellers change most often, so it gets a stepper right
/// on the row instead of forcing a trip through the edit form.
class OwnerProductsScreen extends StatelessWidget {
  const OwnerProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final store = context.watch<CommerceStore>();
    if (user == null) return const SizedBox.shrink();

    final products = store.productsForOwner(user.id);
    final config = context.read<BusinessConfigProvider>().config;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('Products'),
            actions: [
              Text(
                '${products.length} listed',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, mobile: 13),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          if (products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyInventory(brand: config.primaryColor),
            )
          else
            SliverPadding(
              padding: Responsive.padding(context),
              sliver: SliverList.separated(
                itemCount: products.length,
                separatorBuilder: (_, _) =>
                    SizedBox(height: Responsive.spacing(context, mobile: 12)),
                itemBuilder: (context, index) => _ProductRow(
                  product: products[index],
                  onChanged: (value) =>
                      store.setStock(products[index].id, value),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/owner/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.onChanged});

  final Product product;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final available = product.isAvailable;
    final low = product.isLowStock;

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: Responsive.borderRadius(context),
      child: InkWell(
        borderRadius: Responsive.borderRadius(context),
        onTap: () => context.go('/owner/products/${product.id}/edit'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Thumb(
                    url: product.images.isEmpty ? null : product.images.first,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          product.sku,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '₹${product.price}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: _Flag(
                                text: available
                                    ? (low
                                          ? 'Only ${product.stock} left'
                                          : 'Live')
                                    : 'Out of stock',
                                color: available
                                    ? (low ? Colors.orange : Colors.green)
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit listing',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        context.go('/owner/products/${product.id}/edit'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Stock',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _StockStepper(value: product.stock, onChanged: onChanged),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockStepper extends StatelessWidget {
  const _StockStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, int delta, String tooltip) {
      return SizedBox(
        width: 34,
        height: 34,
        child: IconButton(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          iconSize: 18,
          onPressed: value + delta < 0 ? null : () => onChanged(value + delta),
          icon: Icon(icon),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.remove, -1, 'Reduce stock'),
          SizedBox(
            width: 44,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          button(Icons.add, 1, 'Add stock'),
        ],
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 56,
        height: 70,
        child: url == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(Icons.image_outlined, size: 22, color: Colors.grey),
              )
            : ProductImageTile(
                url: url!,
                fit: BoxFit.cover,
                placeholderIcon: Icons.broken_image_outlined,
              ),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({required this.brand});

  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Your shelf is empty',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first product with photos, price and stock. It appears '
              'in the shop the moment you publish.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Add your first product',
              icon: Icons.add,
              color: brand,
              onPressed: () => context.go('/owner/products/new'),
            ),
          ],
        ),
      ),
    );
  }
}
