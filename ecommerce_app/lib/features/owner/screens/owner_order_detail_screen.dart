import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/models/order.dart';
import '../../../core/pricing.dart';
import '../../../core/store/commerce_store.dart';
import '../../config/providers/business_config_provider.dart';
import '../../orders/widgets/order_status_chip.dart';

/// One order from the seller's side: what was bought, who for, and the one
/// button that moves it along.
class OwnerOrderDetailScreen extends StatelessWidget {
  const OwnerOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CommerceStore>();
    final currency = context
        .watch<BusinessConfigProvider>()
        .config
        .currencySymbol;
    final order = store.orderById(orderId);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_outlined, size: 52),
                const SizedBox(height: 16),
                const Text('That order is no longer available'),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => context.go('/owner/orders'),
                  child: const Text('Back to orders'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final next = order.status.next;
    final canCancel = order.status.isActive;
    final padding = Responsive.padding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(order.id),
        actions: [OrderStatusChip(status: order.status, dense: true)],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(padding.left, 16, padding.right, 24),
        children: [
          if (order.status == OrderStatus.cancelled ||
              order.status == OrderStatus.returned)
            _Notice(status: order.status),
          _SectionCard(
            title: 'Progress',
            child: _Timeline(status: order.status),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 14)),
          _SectionCard(
            title: 'Customer',
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Name',
                  value: order.customerName,
                ),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Ship to',
                  value: order.deliveryAddress.isEmpty
                      ? 'No address supplied'
                      : order.deliveryAddress,
                ),
                _InfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Payment',
                  value: order.paymentMethod,
                  last: true,
                ),
              ],
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 14)),
          _SectionCard(
            title: '${order.itemCount} item(s)',
            child: Column(
              children: [
                for (var i = 0; i < order.items.length; i++)
                  _ItemRow(
                    item: order.items[i],
                    last: i == order.items.length - 1,
                    currency: currency,
                  ),
              ],
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 14)),
          _SectionCard(
            title: 'Payment summary',
            child: Column(
              children: [
                _MoneyRow(
                  label: 'Item total',
                  value: Pricing.money(
                    order.subtotal,
                    currencySymbol: currency,
                  ),
                ),
                _MoneyRow(
                  label: 'GST (18%)',
                  value: Pricing.money(order.tax, currencySymbol: currency),
                ),
                _MoneyRow(
                  label: 'Delivery',
                  value: order.shipping == 0
                      ? 'Free'
                      : Pricing.money(order.shipping, currencySymbol: currency),
                  last: true,
                ),
                const Divider(height: 20),
                _MoneyRow(
                  label: 'Total',
                  value: Pricing.money(order.total, currencySymbol: currency),
                  bold: true,
                ),
              ],
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 20)),
          if (next != null)
            AppButton(
              text: 'Mark as ${next.label.toLowerCase()}',
              icon: Icons.touch_app_outlined,
              isExpanded: true,
              onPressed: () {
                store.advanceOrder(order.id);
                _toast(context, '${order.id} · ${next.label}');
              },
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: order.status.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order.status.isClosed
                    ? '${order.status.label} · no further action needed'
                    : 'This order has reached the end of the flow',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: order.status.color,
                ),
              ),
            ),
          if (canCancel) ...[
            SizedBox(height: Responsive.spacing(context, mobile: 10)),
            OutlinedButton.icon(
              onPressed: () => _confirmCancel(context, store, order),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Cancel order'),
            ),
          ],
        ],
      ),
    );
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    CommerceStore store,
    Order order,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
          'The customer will be notified straight away. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    store.advanceOrderStatus(order.id, OrderStatus.cancelled);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('${order.id} cancelled'),
        ),
      );
    }
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(status.icon, color: status.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This order was ${status.label.toLowerCase()}',
              style: TextStyle(
                color: status.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Vertical timeline of the whole fulfilment flow.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.status});

  final OrderStatus status;

  static const List<OrderStatus> _flow = [
    OrderStatus.placed,
    OrderStatus.confirmed,
    OrderStatus.packed,
    OrderStatus.shipped,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final reached =
        status == OrderStatus.cancelled || status == OrderStatus.returned;

    // For a cancelled order, show the path as it stood when it stopped.
    final currentIndex = reached ? _flow.length - 1 : _flow.indexOf(status);

    return Column(
      children: [
        for (var i = 0; i < _flow.length; i++)
          _TimelineRow(
            status: _flow[i],
            done: reached ? false : i <= currentIndex,
            current: !reached && i == currentIndex,
            last: i == _flow.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.status,
    required this.done,
    required this.current,
    required this.last,
  });

  final OrderStatus status;
  final bool done;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = current
        ? status.color
        : (done ? Colors.green : Colors.grey[300]!);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: done || current
                      ? color
                      : Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.6),
                ),
                child: done
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : (current
                          ? Icon(status.icon, size: 14, color: Colors.white)
                          : null),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? Colors.green : Colors.grey[300]!,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: TextStyle(
                      fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                      color: done || current
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.grey[500],
                    ),
                  ),
                  if (current)
                    Text(
                      status.hint,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: Colors.grey[600]),
          const SizedBox(width: 10),
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.last,
    required this.currency,
  });

  final OrderItem item;
  final bool last;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 42,
              height: 52,
              child: item.images.isEmpty
                  ? ColoredBox(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: const Icon(
                        Icons.image_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                    )
                  : ProductImageTile(
                      url: item.images.first,
                      fit: BoxFit.contain,
                      placeholderIcon: Icons.broken_image_outlined,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.variantLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.variantLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Pricing.money(item.lineTotal, currencySymbol: currency),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '×${item.quantity}',
                style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.last = false,
  });

  final String label;
  final String value;
  final bool bold;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
