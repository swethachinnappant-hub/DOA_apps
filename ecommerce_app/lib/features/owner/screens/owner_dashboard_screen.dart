import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/models/order.dart';
import '../../../core/models/user.dart';
import '../../../core/pricing.dart';
import '../../../core/product.dart';
import '../../../core/store/commerce_store.dart';
import '../../auth/providers/auth_provider.dart';
import '../../config/providers/business_config_provider.dart';
import '../../orders/widgets/order_status_chip.dart';
import '../widgets/stat_card.dart';

/// Seller home: the numbers that matter, then the work that is waiting.
class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final store = context.watch<CommerceStore>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    final products = store.productsForOwner(user.id);
    final orders = store.ordersForOwner(user.id);
    final openOrders = orders.where((o) => o.status.isActive).toList();
    final lowStock = products
        .where((p) => p.isLowStock || !p.isAvailable)
        .toList();
    final revenue = orders
        .where((o) => o.status != OrderStatus.cancelled)
        .fold<int>(0, (sum, o) => sum + o.subtotal);
    final config = context.watch<BusinessConfigProvider>().config;

    // SPEC-18 dashboard additions: today's activity, coupon redemptions and
    // the pieces actually selling.
    final now = DateTime.now();
    final todayOrders = orders
        .where((o) =>
            o.placedAt.year == now.year &&
            o.placedAt.month == now.month &&
            o.placedAt.day == now.day)
        .length;
    final redemptions =
        orders.where((o) => o.couponCode != null).length;

    final unitsByName = <String, int>{};
    final revenueByName = <String, int>{};
    for (final order in orders) {
      if (order.status == OrderStatus.cancelled) continue;
      for (final item in order.items) {
        unitsByName[item.name] = (unitsByName[item.name] ?? 0) + item.quantity;
        revenueByName[item.name] =
            (revenueByName[item.name] ?? 0) + item.lineTotal;
      }
    }
    final topNames = unitsByName.keys.toList()
      ..sort((a, b) => unitsByName[b]!.compareTo(unitsByName[a]!));
    final topProducts = [
      for (final name in topNames.take(5))
        (name: name, units: unitsByName[name]!, revenue: revenueByName[name]!),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('Shop studio'),
            actions: [
              IconButton(
                tooltip: 'Shop settings',
                icon: const Icon(Icons.manage_accounts_outlined),
                onPressed: () => context.push('/profile'),
              ),
              IconButton(
                tooltip: 'Notifications',
                icon: Badge(
                  isLabelVisible: store.unreadCount(user.id) > 0,
                  label: Text('${store.unreadCount(user.id)}'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),
          SliverPadding(
            padding: Responsive.padding(context),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ShopOverview(
                  user: user,
                  shopName: config.name,
                  revenue: revenue,
                  currency: config.currencySymbol,
                  orderCount: orders.length,
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 12)),
                _StatGrid(
                  revenue: revenue,
                  orderCount: orders.length,
                  currency: config.currencySymbol,
                  listed: products.length,
                  open: openOrders.length,
                  low: lowStock.length,
                  today: todayOrders,
                  redemptions: redemptions,
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 12)),
                _SectionHeader(title: 'Quick actions', onSeeAll: null),
                SizedBox(height: Responsive.spacing(context, mobile: 12)),
                _QuickActions(lowStock: lowStock.length),
                if (topProducts.isNotEmpty) ...[
                  SizedBox(height: Responsive.spacing(context, mobile: 12)),
                  _SectionHeader(title: 'Top products', onSeeAll: null),
                  SizedBox(height: Responsive.spacing(context, mobile: 12)),
                  for (final item in topProducts)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: Responsive.spacing(context, mobile: 10),
                      ),
                      child: _TopProductRow(
                        name: item.name,
                        units: item.units,
                        revenue: item.revenue,
                        currency: config.currencySymbol,
                      ),
                    ),
                ],
                if (lowStock.isNotEmpty) ...[
                  SizedBox(height: Responsive.spacing(context, mobile: 12)),
                  _SectionHeader(
                    title: 'Low stock',
                    onSeeAll: () => context.go('/owner/products'),
                  ),
                  SizedBox(height: Responsive.spacing(context, mobile: 12)),
                  for (final product in lowStock.take(4))
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: Responsive.spacing(context, mobile: 10),
                      ),
                      child: _LowStockRow(product: product),
                    ),
                ],
                SizedBox(height: Responsive.spacing(context, mobile: 12)),
                _SectionHeader(
                  title: 'Recent orders',
                  onSeeAll: orders.isEmpty
                      ? null
                      : () => context.go('/owner/orders'),
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 12)),
                if (orders.isEmpty)
                  const _EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No orders yet',
                  )
                else
                  ...orders
                      .take(4)
                      .map(
                        (o) => Padding(
                          padding: EdgeInsets.only(
                            bottom: Responsive.spacing(context, mobile: 10),
                          ),
                          child: _OrderRow(order: o),
                        ),
                      ),
                SizedBox(height: Responsive.spacing(context, mobile: 12)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopOverview extends StatelessWidget {
  const _ShopOverview({
    required this.user,
    required this.shopName,
    required this.revenue,
    required this.currency,
    required this.orderCount,
  });

  final AppUser user;
  final String shopName;
  final int revenue;
  final String currency;
  final int orderCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.spacing(context, mobile: 14)),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.diamond_outlined,
                  color: Color(0xFFD9C9A3),
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'SHOP OVERVIEW  ·  ${user.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .62),
                        fontSize: 11,
                        letterSpacing: .35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Sales at a glance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .72),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  Pricing.money(revenue, currencySymbol: currency),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    height: 1.1,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -.7,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$orderCount orders',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.revenue,
    required this.orderCount,
    required this.currency,
    required this.listed,
    required this.open,
    required this.low,
    required this.today,
    required this.redemptions,
  });

  final int revenue;
  final int orderCount;
  final String currency;
  final int listed;
  final int open;
  final int low;
  final int today;
  final int redemptions;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        icon: Icons.currency_rupee,
        label: 'Avg. order',
        value: Pricing.money(
          orderCount == 0 ? 0 : revenue ~/ orderCount,
          currencySymbol: currency,
        ),
      ),
      (icon: Icons.inventory_2_outlined, label: 'Listed', value: '$listed'),
      (
        icon: Icons.pending_actions_outlined,
        label: 'To fulfil',
        value: '$open',
      ),
      (icon: Icons.warning_amber_outlined, label: 'Low stock', value: '$low'),
      (
        icon: Icons.today_outlined,
        label: "Today's orders",
        value: '$today',
      ),
      (
        icon: Icons.local_offer_outlined,
        label: 'Coupon redemptions',
        value: '$redemptions',
      ),
    ];

    // 2 columns keeps the numbers readable on a phone; 4 on a wide screen.
    final raw = Responsive.gridColumns(context);
    final columns = raw < 2 ? 2 : (raw > 4 ? 4 : raw);

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: columns >= 4 ? 1.6 : 1.4,
      children: [
        for (final s in stats)
          DashboardStatCard(icon: s.icon, label: s.label, value: s.value),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.lowStock});

  final int lowStock;

  @override
  Widget build(BuildContext context) {
    final config = context.read<BusinessConfigProvider>().config;

    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: 'Add product',
            icon: Icons.add,
            color: config.primaryColor,
            isExpanded: true,
            onPressed: () => context.go('/owner/products/new'),
          ),
        ),
        SizedBox(width: Responsive.spacing(context, mobile: 12)),
        Expanded(
          child: AppButton(
            text: lowStock > 0 ? 'Restock ($lowStock)' : 'Orders',
            type: AppButtonType.outlined,
            icon: lowStock > 0
                ? Icons.warning_amber_outlined
                : Icons.receipt_long_outlined,
            isExpanded: true,
            onPressed: () =>
                context.go(lowStock > 0 ? '/owner/products' : '/owner/orders'),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, mobile: 16),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onSeeAll != null) ...[
          const SizedBox(width: AppSpacing.sm),
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ],
    );
  }
}

/// One line of the "Top products" ranking: units sold and revenue across
/// the seller's own orders (SPEC-18).
class _TopProductRow extends StatelessWidget {
  const _TopProductRow({
    required this.name,
    required this.units,
    required this.revenue,
    required this.currency,
  });

  final String name;
  final int units;
  final int revenue;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: Responsive.borderRadius(context),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.trending_up, size: 20, color: AppPalette.goldDark),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$units sold',
              style: TextStyle(fontSize: 12.5, color: AppPalette.textSecondary),
            ),
            const SizedBox(width: 12),
            Text(
              Pricing.money(revenue, currencySymbol: currency),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A listing running out (SPEC-18): the piece, what is left, and a hop to
/// the form where the seller restocks it.
class _LowStockRow extends StatelessWidget {
  const _LowStockRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final label = product.isAvailable ? '${product.stock} left' : 'Out of stock';
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: Responsive.borderRadius(context),
      child: InkWell(
        borderRadius: Responsive.borderRadius(context),
        onTap: () => context.go('/owner/products/${product.id}/edit'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                product.isAvailable
                    ? Icons.warning_amber_outlined
                    : Icons.remove_shopping_cart_outlined,
                size: 20,
                color: product.isAvailable
                    ? AppPalette.goldDark
                    : const Color(0xFF8A4943),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12.5, color: AppPalette.textSecondary),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: Responsive.borderRadius(context),
      child: InkWell(
        borderRadius: Responsive.borderRadius(context),
        onTap: () => context.go('/owner/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(order.status.icon, color: order.status.color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.customerName} · ${order.itemCount} item(s)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: AppPalette.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OrderStatusChip(status: order.status, dense: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppPalette.textMuted),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
