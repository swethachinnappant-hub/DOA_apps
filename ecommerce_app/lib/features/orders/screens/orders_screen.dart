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
                );
              },
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
  });

  final Order order;
  final Color brand;
  final bool showPrice;
  final String currency;

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
                    color: Colors.grey[600],
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
                    color: showPrice ? brand : Colors.grey,
                  ),
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
        padding: const EdgeInsets.all(32),
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
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When you place an order it appears here with live status updates.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
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
