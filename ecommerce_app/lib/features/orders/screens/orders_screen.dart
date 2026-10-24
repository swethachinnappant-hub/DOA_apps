import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/models/order.dart';
import '../../../core/pricing.dart';
import '../../../core/store/commerce_store.dart';
import '../../auth/providers/auth_provider.dart';
import '../../config/providers/business_config_provider.dart';
import '../widgets/order_status_chip.dart';

/// The buyer's order history, read from the live store.
///
/// A seller advancing the status elsewhere is reflected here immediately,
/// since both roles observe the same records.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final user = context.watch<AuthProvider>().user;
    final rules = config.rules;

    final orders = user == null
        ? const <Order>[]
        : store.ordersForCustomer(user.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: orders.isEmpty
          ? _EmptyOrders(brand: config.primaryColor)
          : ListView.separated(
              padding: Responsive.padding(context),
              itemCount: orders.length,
              separatorBuilder: (_, _) =>
                  SizedBox(height: Responsive.spacing(context, mobile: 10)),
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderCard(
                  order: order,
                  brand: config.primaryColor,
                  showPrice: rules.showPrices,
                  currency: config.currencySymbol,
                  // §6.41: one-tap reorder straight from the history list.
                  onReorder: () => _reorder(context, store, order),
                );
              },
            ),
    );
  }

  /// Re-adds every line of [order] to the bag (§6.41), mirroring the
  /// order-detail action so a returning retailer can restock in one tap.
  void _reorder(BuildContext context, CommerceStore store, Order order) {
    var added = 0;
    for (final item in order.items) {
      final product = store.productById(item.productId);
      if (product == null) continue;
      store.addToCart(
        product,
        quantity: item.quantity,
        selectedSize: item.selectedSize,
        selectedShade: item.selectedShade,
      );
      added += item.quantity;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added == 0
                ? 'Those designs are no longer available'
                : '$added item${added == 1 ? '' : 's'} added to your bag',
          ),
          action: SnackBarAction(
            label: 'View bag',
            onPressed: () => context.go('/cart'),
          ),
        ),
      );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.brand,
    required this.showPrice,
    required this.currency,
    this.onReorder,
  });

  final Order order;
  final Color brand;
  final bool showPrice;
  final String currency;
  final VoidCallback? onReorder;

  @override
  Widget build(BuildContext context) {
    final date =
        '${order.placedAt.day} ${_month(order.placedAt.month)} '
        '${order.placedAt.year}';

    return AppCard(
      onTap: () => context.push('/order/${order.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  order.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OrderStatusChip(status: order.status, dense: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$date • ${order.itemCount} item(s)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 12),
                    color: AppPalette.textSecondary,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  showPrice
                      ? Pricing.money(order.total, currencySymbol: currency)
                      : 'Contact for Price',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 14),
                    fontWeight: FontWeight.bold,
                    color: showPrice ? brand : AppPalette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < order.items.length && i < 4; i++) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 40,
                    height: 50,
                    child: order.items[i].images.isEmpty
                        ? ColoredBox(
                            color: brand.withValues(alpha: 0.08),
                            child: Icon(
                              Icons.image_outlined,
                              size: 17,
                              color: brand.withValues(alpha: 0.45),
                            ),
                          )
                        : ProductImageTile(
                            url: order.items[i].images.first,
                            fit: BoxFit.cover,
                            placeholderIcon: Icons.image_outlined,
                            placeholderColor: brand,
                            placeholderAccent: brand,
                          ),
                  ),
                ),
                if (i < 3 && i != order.items.length - 1)
                  const SizedBox(width: 6),
              ],
              if (order.items.length > 4)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    '+${order.items.length - 4}',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 12),
                      fontWeight: FontWeight.w600,
                      color: AppPalette.textSecondary,
                    ),
                  ),
                ),
              const Spacer(),
              // §6.41: quick reorder from the history list itself.
              if (onReorder != null)
                TextButton.icon(
                  onPressed: onReorder,
                  icon: const Icon(Icons.replay, size: 16),
                  label: const Text('Reorder'),
                  style: TextButton.styleFrom(
                    foregroundColor: brand,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 36),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _month(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month < 1 || month > 12 ? 0 : month - 1];
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.brand});

  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 60,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No orders yet',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, mobile: 16),
                fontWeight: FontWeight.w600,
                color: AppPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When you place an order it appears here with live status updates.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppPalette.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              text: 'Browse products',
              icon: Icons.shopping_bag_outlined,
              color: brand,
              onPressed: () => context.go('/catalogue'),
            ),
          ],
        ),
      ),
    );
  }
}
