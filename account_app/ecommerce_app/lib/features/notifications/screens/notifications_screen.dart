import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/providers/business_config_provider.dart';
import 'package:common_widgets/common_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final notifications = [
      {'title': 'Order Shipped', 'body': 'Your order ORD-2024-002 has been shipped', 'time': '2 hours ago', 'icon': Icons.local_shipping_outlined},
      {'title': 'New Arrival', 'body': 'New ${config.categories.first} collection is now available', 'time': '5 hours ago', 'icon': Icons.new_releases_outlined},
      {'title': 'Price Drop', 'body': 'Prices reduced on selected ${config.categories[1]} items', 'time': '1 day ago', 'icon': Icons.trending_down},
      {'title': 'Order Confirmed', 'body': 'Your order ORD-2024-003 has been confirmed', 'time': '2 days ago', 'icon': Icons.check_circle_outline},
      {'title': 'Welcome!', 'body': 'Welcome to ${config.name}. Start browsing our catalogue', 'time': '3 days ago', 'icon': Icons.waving_hand},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.separated(
        padding: Responsive.padding(context),
        itemCount: notifications.length,
        separatorBuilder: (_, _) => SizedBox(height: 8),
        itemBuilder: (context, index) {
          final n = notifications[index];
          return AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.spacing(context, mobile: 8)),
                  decoration: BoxDecoration(
                    color: config.accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(n['icon'] as IconData, color: config.primaryColor, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(n['title'] as String, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 14), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 4),
                      Text(n['body'] as String, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12), color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 4),
                      Text(n['time'] as String, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 11), color: Colors.grey[400]), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
