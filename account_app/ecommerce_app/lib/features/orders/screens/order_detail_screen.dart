import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/providers/business_config_provider.dart';
import '../../../core/business_config.dart';
import 'package:common_widgets/common_widgets.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final rules = config.rules;
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: SingleChildScrollView(
        padding: Responsive.padding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppCard(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text('ORD-2024-001', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 16), fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(context, mobile: 8), vertical: Responsive.spacing(context, mobile: 4)),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                      child: Text('Delivered', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 11), color: Colors.white, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text('Dec 15, 2024', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12), color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )),
            SizedBox(height: Responsive.spacing(context, mobile: 16)),
            SectionHeader(title: 'Items', padding: EdgeInsets.only(top: 16)),
            SizedBox(height: Responsive.spacing(context, mobile: 12)),
            ...List.generate(3, (i) => Padding(
              padding: EdgeInsets.only(bottom: Responsive.spacing(context, mobile: 8)),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: config.accentColor, borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Icon(config.icon, size: 24, color: config.primaryColor.withValues(alpha: 0.5))),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${config.categories[i]} Set', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13), fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text('Qty: ${i + 1}', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 11), color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    rules.showPrices
                        ? Text('₹${(i + 1) * 4999}', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13), fontWeight: FontWeight.bold, color: config.primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis)
                        : Text('Contact for Price', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12), fontWeight: FontWeight.bold, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            )),
            SizedBox(height: Responsive.spacing(context, mobile: 16)),
            SectionHeader(title: 'Timeline', padding: EdgeInsets.only(top: 16)),
            SizedBox(height: Responsive.spacing(context, mobile: 12)),
            AppCard(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _timelineTile(context, 'Order Placed', 'Dec 15, 10:30 AM', true, config),
                _timelineTile(context, 'Confirmed', 'Dec 15, 11:00 AM', true, config),
                _timelineTile(context, 'Shipped', 'Dec 16, 09:15 AM', true, config),
                _timelineTile(context, 'Delivered', 'Dec 18, 02:45 PM', true, config),
              ],
            )),
            SizedBox(height: Responsive.spacing(context, mobile: 16)),
            SectionHeader(title: 'Payment', padding: EdgeInsets.only(top: 16)),
            SizedBox(height: Responsive.spacing(context, mobile: 12)),
            AppCard(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _summaryRow(context, 'Subtotal', '₹12,497', showPrice: rules.showPrices),
                _summaryRow(context, 'GST (18%)', '₹2,250', showPrice: rules.showPrices),
                _summaryRow(context, 'Shipping', 'Free'),
                Divider(),
                _summaryRow(context, 'Total Paid', '₹14,747', showPrice: rules.showPrices),
                SizedBox(height: 8),
                Text('Paid via UPI', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12), color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _timelineTile(BuildContext context, String title, String time, bool completed, BusinessConfig config) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.spacing(context, mobile: 16)),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(shape: BoxShape.circle, color: completed ? config.primaryColor : Colors.grey[300]),
              ),
              Container(width: 2, height: 20, color: completed ? config.primaryColor.withValues(alpha: 0.3) : Colors.grey[200]),
            ],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(time, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 11), color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value, {bool showPrice = true}) {
    final displayValue = showPrice ? value : 'Contact for Price';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Responsive.spacing(context, mobile: 4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Flexible(child: Text(displayValue, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13), fontWeight: FontWeight.bold, color: showPrice ? null : Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
