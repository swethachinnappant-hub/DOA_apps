import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/models/order.dart';
import '../../../core/store/commerce_store.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/widgets/order_status_chip.dart';

/// The seller's order queue.
///
/// Every row carries the next status button, because "confirm it and move on"
/// is the single most repeated action a seller performs.
class OwnerOrdersScreen extends StatefulWidget {
  const OwnerOrdersScreen({super.key});

  @override
  State<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends State<OwnerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final store = context.watch<CommerceStore>();
    if (user == null) return const SizedBox.shrink();

    final all = store.ordersForOwner(user.id);
    final active = all.where((o) => o.status.isActive).toList();
    final closed = all.where((o) => o.status.isClosed).toList();

    return Scaffold(
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabs,
              labelColor: Theme.of(context).colorScheme.primary,
              tabs: [
                Tab(text: 'Active (${active.length})'),
                Tab(text: 'Completed (${closed.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _OrderList(orders: active, empty: _EmptyQueue()),
                _OrderList(orders: closed, empty: _EmptyQueue(completed: true)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders, required this.empty});

  final List<Order> orders;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return empty;

    final store = context.watch<CommerceStore>();
    final padding = Responsive.padding(context);

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(padding.left, 16, padding.right, 96),
      itemCount: orders.length,
      separatorBuilder: (_, _) =>
          SizedBox(height: Responsive.spacing(context, mobile: 12)),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(order: order, store: store);
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.store});

  final Order order;
  final CommerceStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final next = order.status.next;
    final radius = Responsive.borderRadius(context);

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => context.go('/owner/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      order.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[700]),
                    ),
                  ),
                  Text(
                    '₹${order.subtotal}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${order.itemCount} item(s) · ${order.status.hint}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (next != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Mark ${next.label.toLowerCase()}',
                        icon: Icons.touch_app_outlined,
                        height: 38,
                        isExpanded: true,
                        onPressed: () {
                          store.advanceOrder(order.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text('${order.id} · ${next.label}'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () =>
                          context.go('/owner/orders/${order.id}'),
                      child: const Text('Details'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue({this.completed = false});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              completed ? Icons.task_alt_outlined : Icons.pending_actions_outlined,
              size: 54,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              completed ? 'Nothing finished yet' : 'All caught up',
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              completed
                  ? 'Orders you have fulfilled end up here.'
                  : 'New orders land here the second a customer checks out. '
                      'You will get a notification too.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, height: 1.5, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
