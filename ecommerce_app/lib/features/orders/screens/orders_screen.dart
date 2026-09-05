import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/providers/business_config_provider.dart';
import 'package:common_widgets/common_widgets.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final rules = config.rules;
    final orders = [
      {'id': 'ORD-2024-001', 'date': 'Dec 15, 2024', 'status': 'Delivered', 'statusColor': Colors.green, 'items': '3 items', 'total': '₹14,747'},
      {'id': 'ORD-2024-002', 'date': 'Dec 12, 2024', 'status': 'Shipped', 'statusColor': Colors.blue, 'items': '2 items', 'total': '₹8,999'},
      {'id': 'ORD-2024-003', 'date': 'Dec 10, 2024', 'status': 'Processing', 'statusColor': Colors.orange, 'items': '5 items', 'total': '₹22,500'},
      {'id': 'ORD-2024-004', 'date': 'Dec 8, 2024', 'status': 'Pending', 'statusColor': Colors.grey, 'items': '1 item', 'total': '₹3,499'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ListView.separated(
        padding: Responsive.padding(context),
        itemCount: orders.length,
        separatorBuilder: (_, _) => SizedBox(height: 8),
        itemBuilder: (context, index) {
          final order = orders[index];
          return AppCard(
            onTap: () => context.push('/order/$index'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(order['id'] as String, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 14), fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (order['statusColor'] as Color?) ?? Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(order['status'] as String, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 10), color: Colors.white, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text('${order['date']} • ${order['items']}', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12), color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    rules.showPrices
                        ? Text(order['total'] as String, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 14), fontWeight: FontWeight.bold, color: config.primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis)
                        : Text('Contact for Price', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12), fontWeight: FontWeight.bold, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
