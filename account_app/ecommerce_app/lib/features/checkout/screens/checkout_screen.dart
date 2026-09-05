import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/providers/business_config_provider.dart';
import '../../../core/business_config.dart';
import 'package:common_widgets/common_widgets.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'UPI';
  int _selectedAddress = 0;

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final rules = config.rules;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: Responsive.padding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Delivery Address
            SectionHeader(title: 'Delivery Address', padding: EdgeInsets.only(top: Responsive.spacing(context, mobile: 16))),
            SizedBox(height: Responsive.spacing(context, mobile: 12)),
            _addressCard(context, 'Chirag Associates, Main Road, Rajkot, Gujarat 360001', 0, config),
            _addressCard(context, 'Warehouse, Industrial Area, Ahmedabad, Gujarat 380001', 1, config),
            SizedBox(height: Responsive.spacing(context, mobile: 20)),

            // Order Summary
            SectionHeader(title: 'Order Summary', padding: EdgeInsets.only(top: Responsive.spacing(context, mobile: 16))),
            SizedBox(height: Responsive.spacing(context, mobile: 12)),
            AppCard(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _summaryRow('Gold Chain Set (2)', '₹9,998', config, showPrice: rules.showPrices),
                _summaryRow('Gold Ring Set (1)', '₹2,499', config, showPrice: rules.showPrices),
                Divider(),
                _summaryRow('Subtotal', '₹12,497', config, showPrice: rules.showPrices),
                _summaryRow('GST (18%)', '₹2,250', config, showPrice: rules.showPrices),
                _summaryRow('Shipping', 'Free', config),
                Divider(),
                _summaryRow('Total', '₹14,747', config, isBold: true, showPrice: rules.showPrices),
              ],
            )),
            SizedBox(height: Responsive.spacing(context, mobile: 20)),

            // Payment Method
            SectionHeader(title: 'Payment Method', padding: EdgeInsets.only(top: Responsive.spacing(context, mobile: 16))),
            SizedBox(height: Responsive.spacing(context, mobile: 12)),
            _paymentOption('UPI', Icons.payment, 'PhonePe, GPay, Paytm'),
            _paymentOption('Credit/Debit Card', Icons.credit_card, 'Visa, Mastercard, RuPay'),
            _paymentOption('Net Banking', Icons.account_balance, 'All banks'),
            _paymentOption('Cash on Delivery', Icons.money, 'Pay on delivery'),
            SizedBox(height: Responsive.spacing(context, mobile: 20)),

            // Place Order
            AppButton(
              text: rules.showPrices ? 'Place Order - ₹14,747' : 'Place Order',
              onPressed: () {
                AppDialog.show(
                  context,
                  title: 'Order Placed!',
                  content: const Text('Your order has been placed successfully. You will receive confirmation shortly.'),
                  actions: [
                    DialogAction(label: 'View Orders', onPressed: () => context.push('/orders')),
                    DialogAction(label: 'Continue Shopping', onPressed: () => context.go('/app')),
                  ],
                );
              },
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 24)),
          ],
        ),
      ),
    );
  }

  Widget _addressCard(BuildContext context, String address, int index, BusinessConfig config) {
    final selected = index == _selectedAddress;
    return GestureDetector(
      onTap: () => setState(() => _selectedAddress = index),
      child: AppCard(
        child: Row(
          children: [
            Radio<int>(
              value: index,
              groupValue: _selectedAddress,
              onChanged: (v) => setState(() => _selectedAddress = v ?? 0),
              activeColor: config.primaryColor,
            ),
            Expanded(
              child: Text(address, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13), color: selected ? null : Colors.grey[600]), maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption(String title, IconData icon, String subtitle) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.spacing(context, mobile: 8)),
      child: AppCard(
        child: RadioListTile<String>(
          value: title,
          groupValue: _paymentMethod,
          onChanged: (v) => setState(() => _paymentMethod = v ?? 'UPI'),
          title: Row(
            children: [
              Icon(icon, size: 20),
              SizedBox(width: 8),
              Flexible(child: Text(title, style: TextStyle(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, BusinessConfig config, {bool isBold = false, bool showPrice = true}) {
    final displayValue = showPrice ? value : 'Contact for Price';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Responsive.spacing(context, mobile: 4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: isBold ? 16 : 13), fontWeight: isBold ? FontWeight.bold : FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text(displayValue, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: isBold ? 16 : 13), fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: isBold ? config.primaryColor : (showPrice ? null : Colors.grey)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
