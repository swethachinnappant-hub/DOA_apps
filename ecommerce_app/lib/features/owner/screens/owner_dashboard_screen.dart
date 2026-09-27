import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/models/order.dart';
import '../../../core/models/user.dart';
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
    final lowStock = products.where((p) => p.isLowStock || !p.isAvailable).toList();
    final revenue = orders
        .where((o) => o.status != OrderStatus.cancelled)
        .fold<int>(0, (sum, o) => sum + o.subtotal);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(user.displayName),
            actions: [
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
                _Welcome(user: user),
                SizedBox(height: Responsive.spacing(context, mobile: 20)),
                _StatGrid(
                  revenue: revenue,
                  listed: products.length,
                  open: openOrders.length,
                  low: lowStock.length,
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 24)),
                _SectionHeader(
                  title: 'Quick actions',
                  onSeeAll: null,
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 12)),
                _QuickActions(lowStock: lowStock.length),
                SizedBox(height: Responsive.spacing(context, mobile: 24)),
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
                    body: 'Orders the moment a customer buys will land here, '
                        'with the status one tap away.',
                  )
                else
                  ...orders.take(4).map(
                        (o) => Padding(
                          padding: EdgeInsets.only(
                            bottom: Responsive.spacing(context, mobile: 10),
                          ),
                          child: _OrderRow(order: o),
                        ),
                      ),
                SizedBox(height: Responsive.spacing(context, mobile: 24)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, ${user.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, mobile: 22),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.role == UserRole.owner
              ? 'Here is how your shop is doing today'
              : 'Welcome back',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, mobile: 13),
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.revenue,
    required this.listed,
    required this.open,
    required this.low,
  });

  final int revenue;
  final int listed;
  final int open;
  final int low;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        icon: Icons.currency_rupee,
        label: 'Revenue',
        value: revenue == 0 ? '₹0' : '₹$revenue',
      ),
      (icon: Icons.inventory_2_outlined, label: 'Listed', value: '$listed'),
      (
        icon: Icons.pending_actions_outlined,
        label: 'To fulfil',
        value: '$open',
      ),
      (
        icon: Icons.warning_amber_outlined,
        label: 'Low stock',
        value: '$low',
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
            onPressed: () => context.go(
              lowStock > 0 ? '/owner/products' : '/owner/orders',
            ),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
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
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey[500]),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
          ),
        ],
      ),
    );
  }
}
