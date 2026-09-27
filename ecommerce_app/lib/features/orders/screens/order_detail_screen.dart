import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/models/order.dart';
import '../../../core/store/commerce_store.dart';
import '../../config/providers/business_config_provider.dart';
import '../widgets/order_status_chip.dart';

/// A single order from the buyer's point of view.
///
/// The timeline is derived from the live status, so it moves on its own when
/// the seller advances the order.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final rules = config.rules;
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
                const Text('We could not find that order'),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => context.go('/orders'),
                  child: const Text('Back to orders'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final padding = Responsive.padding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(order.id),
        actions: [OrderStatusChip(status: order.status, dense: true)],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(padding.left, 16, padding.right, 24),
        children: [
          _StatusBanner(order: order),
          SizedBox(height: Responsive.spacing(context, mobile: 14)),
          _Card(
            title: 'Timeline',
            child: _Timeline(status: order.status),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 14)),
          _Card(
            title: '${order.itemCount} item(s)',
            child: Column(
              children: [
                for (var i = 0; i < order.items.length; i++)
                  _ItemRow(
                    item: order.items[i],
                    showPrice: rules.showPrices,
                    accent: config.accentColor,
                    brand: config.primaryColor,
                    last: i == order.items.length - 1,
                  ),
              ],
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 14)),
          _Card(
            title: 'Delivery',
            child: Column(
              children: [
                _kv(
                  context,
                  'Ship to',
                  order.deliveryAddress.isEmpty
                      ? 'No address supplied'
                      : order.deliveryAddress,
                ),
                _kv(context, 'From', order.ownerName),
                _kv(context, 'Placed on', _date(order.placedAt), last: true),
              ],
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 14)),
          _Card(
            title: 'Payment',
            child: Column(
              children: [
                _money(
                  context,
                  'Item total',
                  '₹${order.subtotal}',
                  showPrice: rules.showPrices,
                ),
                _money(
                  context,
                  'GST (18%)',
                  '₹${order.tax}',
                  showPrice: rules.showPrices,
                ),
                _money(
                  context,
                  'Delivery',
                  order.shipping == 0 ? 'Free' : '₹${order.shipping}',
                  showPrice: rules.showPrices,
                ),
                const Divider(height: 20),
                _money(
                  context,
                  'Total',
                  '₹${order.total}',
                  showPrice: rules.showPrices,
                  bold: true,
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Paid via ${order.paymentMethod}',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 12),
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          OutlinedButton.icon(
            onPressed: () => context.go('/orders'),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back to orders'),
          ),
        ],
      ),
    );
  }

  Widget _kv(
    BuildContext context,
    String label,
    String value, {
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, mobile: 12),
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, mobile: 13),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _money(
    BuildContext context,
    String label,
    String value, {
    bool showPrice = true,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, mobile: 13),
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Flexible(
            child: Text(
              showPrice ? value : 'Contact for Price',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, mobile: 13),
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: showPrice ? null : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _date(DateTime time) {
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
    final month = names[time.month < 1 || time.month > 12 ? 0 : time.month - 1];
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final meridiem = time.hour < 12 ? 'AM' : 'PM';
    return '${time.day} $month ${time.year}, $hour:$minute $meridiem';
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final status = order.status;
    final text = status == OrderStatus.delivered
        ? 'Delivered — thanks for shopping with us'
        : '${status.label} · ${status.hint}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(status.icon, color: status.color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: status.color,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
    final halted =
        status == OrderStatus.cancelled || status == OrderStatus.returned;
    final current = halted ? -1 : _flow.indexOf(status);

    return Column(
      children: [
        for (var i = 0; i < _flow.length; i++)
          _TimelineRow(
            status: _flow[i],
            done: !halted && i <= current,
            current: !halted && i == current,
            last: i == _flow.length - 1,
          ),
        if (halted)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(status.icon, size: 16, color: status.color),
                const SizedBox(width: 6),
                Text(
                  'This order was ${status.label.toLowerCase()}',
                  style: TextStyle(
                    color: status.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
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
    final base = done || current ? status.color : Colors.grey[300]!;

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
                      ? base
                      : Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: base, width: 1.6),
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

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.showPrice,
    required this.accent,
    required this.brand,
    required this.last,
  });

  final OrderItem item;
  final bool showPrice;
  final Color accent;
  final Color brand;
  final bool last;

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
              width: 46,
              height: 58,
              child: item.images.isEmpty
                  ? ColoredBox(
                      color: accent,
                      child: Icon(
                        Icons.image_outlined,
                        size: 20,
                        color: brand.withValues(alpha: 0.5),
                      ),
                    )
                  : ProductImageTile(
                      url: item.images.first,
                      fit: BoxFit.cover,
                      placeholderIcon: Icons.broken_image_outlined,
                      placeholderColor: accent,
                      placeholderAccent: brand,
                    ),
            ),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
                Text(
                  'Qty ${item.quantity}',
                  maxLines: 1,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            showPrice ? '₹${item.lineTotal}' : 'Contact',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: showPrice ? brand : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
