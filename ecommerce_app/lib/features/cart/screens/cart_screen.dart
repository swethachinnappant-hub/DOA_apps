import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/models/cart.dart';
import '../../../core/product.dart';
import '../../../core/store/commerce_store.dart';
import '../../config/providers/business_config_provider.dart';

/// The shopper's bag, backed by [CommerceStore].
///
/// Quantity controls are wired rather than decorative: the plus/minus buttons
/// change real state, the totals recompute, and removing the last unit drops
/// the line.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final rules = config.rules;

    final lines = store.cart;
    final subtotal = store.cartSubtotal;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart${lines.isEmpty ? '' : ' (${store.cartCount})'}'),
        actions: [
          if (lines.isNotEmpty)
            IconButton(
              tooltip: 'Clear cart',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, store),
            ),
        ],
      ),
      body: lines.isEmpty
          ? _EmptyCart(brand: config.primaryColor, icon: config.icon)
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: Responsive.padding(context),
                    itemCount: lines.length,
                    separatorBuilder: (_, _) => SizedBox(
                      height: Responsive.spacing(context, mobile: 10),
                    ),
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      final product = store.productFor(line);
                      final available = product?.stock ?? 0;
                      final atLimit =
                          product != null &&
                          product.ownerId.isNotEmpty &&
                          line.quantity >= available;

                      return _CartLine(
                        line: line,
                        product: product,
                        accent: config.accentColor,
                        brandColor: config.primaryColor,
                        fallbackIcon: config.icon,
                        showPrice: rules.showPrices,
                        atLimit: atLimit,
                        onIncrement: atLimit
                            ? null
                            : () => store.incrementCart(line.lineKey),
                        onDecrement: () => store.decrementCart(line.lineKey),
                        onRemove: () => store.removeFromCart(line.lineKey),
                      );
                    },
                  ),
                ),
                _CartSummary(
                  subtotal: subtotal,
                  showPrice: rules.showPrices,
                  primary: config.primaryColor,
                  onCheckout: () => context.push('/checkout'),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context, CommerceStore store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty the cart?'),
        content: const Text('Everything in your bag will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep items'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Empty cart'),
          ),
        ],
      ),
    );
    if (confirmed == true) store.clearCart();
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.line,
    required this.product,
    required this.accent,
    required this.brandColor,
    required this.fallbackIcon,
    required this.showPrice,
    required this.atLimit,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem line;
  final Product? product;
  final Color accent;
  final Color brandColor;
  final IconData fallbackIcon;
  final bool showPrice;
  final bool atLimit;
  final VoidCallback? onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final images = product?.images ?? const <String>[];
    final name = line.name;
    final qty = line.quantity;
    final lineTotal = line.lineTotal;
    final variant = line.variantLabel;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 62,
              height: 78,
              child: images.isEmpty
                  ? ColoredBox(
                      color: accent,
                      child: Icon(
                        fallbackIcon,
                        size: 26,
                        color: brandColor.withValues(alpha: 0.5),
                      ),
                    )
                  : ProductImageTile(
                      url: images.first,
                      fit: BoxFit.cover,
                      placeholderIcon: fallbackIcon,
                      placeholderColor: accent,
                      placeholderAccent: brandColor,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, mobile: 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      showPrice ? '₹$lineTotal' : 'Contact',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, mobile: 14),
                        fontWeight: FontWeight.bold,
                        color: brandColor,
                      ),
                    ),
                  ],
                ),
                if (variant.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    variant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 11.5),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Stepper(
                      qty: qty,
                      atLimit: atLimit,
                      onIncrement: onIncrement,
                      onDecrement: onDecrement,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Remove',
                      visualDensity: VisualDensity.compact,
                      onPressed: onRemove,
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                if (atLimit) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Only $qty left in stock',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 11),
                      color: Colors.orange[800],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.qty,
    required this.atLimit,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int qty;
  final bool atLimit;
  final VoidCallback? onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, VoidCallback? onTap, String tooltip) {
      final enabled = onTap != null;
      return SizedBox(
        width: 30,
        height: 30,
        child: IconButton(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          iconSize: 16,
          onPressed: onTap,
          icon: Icon(icon, color: enabled ? null : Colors.grey[400]),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.remove, onDecrement, 'Decrease quantity'),
          SizedBox(
            width: 34,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          button(
            Icons.add,
            atLimit ? null : onIncrement,
            atLimit ? 'Maximum in stock' : 'Increase quantity',
          ),
        ],
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({
    required this.subtotal,
    required this.showPrice,
    required this.primary,
    required this.onCheckout,
  });

  final int subtotal;
  final bool showPrice;
  final Color primary;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final tax = (subtotal * 0.18).round();
    final shipping = subtotal >= 999 ? 0 : 79;
    final total = subtotal + tax + shipping;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row(context, 'Subtotal', showPrice ? '₹$subtotal' : 'Contact'),
            const SizedBox(height: 6),
            _row(context, 'GST (18%)', showPrice ? '₹$tax' : 'Contact'),
            const SizedBox(height: 6),
            _row(
              context,
              'Delivery',
              !showPrice ? 'Contact' : (shipping == 0 ? 'Free' : '₹$shipping'),
            ),
            if (showPrice && shipping > 0) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Free delivery on orders above ₹999',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                ),
              ),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Total',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 17),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    showPrice ? '₹$total' : 'Contact for Price',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 17),
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Proceed to checkout',
              isExpanded: true,
              onPressed: onCheckout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, mobile: 13.5),
              color: Colors.grey[600],
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, mobile: 13.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.brand, required this.icon});

  final Color brand;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Your bag is empty',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, mobile: 16),
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add something you love and it will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            AppButton(
              text: 'Start shopping',
              icon: Icons.shopping_bag_outlined,
              color: brand,
              onPressed: () => context.go('/app'),
            ),
          ],
        ),
      ),
    );
  }
}
