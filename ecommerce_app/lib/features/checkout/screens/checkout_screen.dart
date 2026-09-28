import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/pricing.dart';
import '../../../core/store/commerce_store.dart';
import '../../auth/providers/auth_provider.dart';
import '../../config/providers/business_config_provider.dart';

/// Turns the shopper's bag into a real [Order] in the store.
///
/// Everything shown here is read from the cart, so the totals can never drift
/// from what checkout actually charges, and the address chosen is the one
/// written onto the order.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'UPI';
  int _selectedAddress = 0;

  static const List<({String label, String value})> _addresses = [
    (label: 'Home', value: '14 MG Road, Bengaluru, Karnataka 560001'),
    (label: 'Office', value: 'Tower B, Tech Park, Hyderabad, Telangana 500081'),
  ];

  static const List<({String name, IconData icon, String note})> _payments = [
    (name: 'UPI', icon: Icons.payment, note: 'PhonePe, GPay, Paytm'),
    (
      name: 'Credit/Debit Card',
      icon: Icons.credit_card,
      note: 'Visa, Mastercard, RuPay',
    ),
    (name: 'Net Banking', icon: Icons.account_balance, note: 'All banks'),
    (name: 'Cash on Delivery', icon: Icons.money, note: 'Pay when it arrives'),
  ];

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final rules = config.rules;
    final store = context.watch<CommerceStore>();
    final user = context.watch<AuthProvider>().user;

    final lines = store.cart;
    final subtotal = store.cartSubtotal;
    final tax = Pricing.tax(subtotal);
    final shipping = Pricing.shipping(subtotal);
    final total = Pricing.total(subtotal);
    final showPrice = rules.showPrices;

    if (lines.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 58,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                const Text('Nothing to check out'),
                const SizedBox(height: 8),
                Text(
                  'Add a product to your bag first.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const SizedBox(height: 20),
                AppButton(
                  text: 'Browse products',
                  color: config.primaryColor,
                  onPressed: () => context.go('/app'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: Responsive.padding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SectionHeader(
              title: 'Delivery address',
              padding: EdgeInsets.only(top: 16),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12)),
            RadioGroup<int>(
              groupValue: _selectedAddress,
              onChanged: (v) => setState(() => _selectedAddress = v ?? 0),
              child: Column(
                children: [
                  for (var i = 0; i < _addresses.length; i++)
                    _AddressCard(
                      label: _addresses[i].label,
                      address: _addresses[i].value,
                      selected: i == _selectedAddress,
                      accent: config.primaryColor,
                      value: i,
                    ),
                ],
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 20)),

            SectionHeader(
              title: 'Order summary',
              padding: EdgeInsets.only(top: 16),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12)),
            AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final line in lines)
                    _LineSummary(
                      name: line.name,
                      qty: line.quantity,
                      amount: line.lineTotal,
                      showPrice: showPrice,
                      currency: config.currencySymbol,
                    ),
                  const Divider(height: 20),
                  _row(
                    context,
                    'Subtotal',
                    Pricing.money(
                      subtotal,
                      currencySymbol: config.currencySymbol,
                    ),
                    showPrice: showPrice,
                  ),
                  _row(
                    context,
                    'GST (${(Pricing.gstRate * 100).round()}%)',
                    Pricing.money(tax, currencySymbol: config.currencySymbol),
                    showPrice: showPrice,
                  ),
                  _row(
                    context,
                    'Delivery',
                    shipping == 0
                        ? 'Free'
                        : Pricing.money(
                            shipping,
                            currencySymbol: config.currencySymbol,
                          ),
                    showPrice: showPrice,
                  ),
                  const Divider(height: 20),
                  _row(
                    context,
                    'Total',
                    Pricing.money(total, currencySymbol: config.currencySymbol),
                    showPrice: showPrice,
                    bold: true,
                    brand: config.primaryColor,
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 20)),

            SectionHeader(
              title: 'Payment method',
              padding: EdgeInsets.only(top: 16),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12)),
            RadioGroup<String>(
              groupValue: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v ?? 'UPI'),
              child: Column(
                children: [
                  for (final option in _payments)
                    _PaymentCard(
                      name: option.name,
                      icon: option.icon,
                      note: option.note,
                      selected: option.name == _paymentMethod,
                    ),
                ],
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 24)),

            AppButton(
              text: showPrice
                  ? 'Place order · ${Pricing.money(total, currencySymbol: config.currencySymbol)}'
                  : 'Place order',
              isExpanded: true,
              onPressed: () => _placeOrder(
                context,
                store: store,
                address: _addresses[_selectedAddress].value,
                userLabel: user?.displayName ?? 'Guest',
                customerId: user?.id ?? 'guest',
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 24)),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder(
    BuildContext context, {
    required CommerceStore store,
    required String address,
    required String userLabel,
    required String customerId,
  }) async {
    final order = store.placeOrder(
      customerId: customerId,
      customerName: userLabel,
      deliveryAddress: address,
      paymentMethod: _paymentMethod,
    );

    if (order == null || !mounted) return;

    // AppDialog does not close itself from an action, and showDialog mounts
    // the dialog on the root navigator, so aim there rather than at whatever
    // shell navigator happens to own this screen.
    void dismiss() => Navigator.of(context, rootNavigator: true).maybePop();
    var next = 'shop';

    await AppDialog.show<void>(
      context,
      title: 'Order placed!',
      content: Text(
        '${order.id} for ${order.itemCount} item(s) is on its way. '
        'You will get updates as the seller moves it along.',
      ),
      actions: [
        DialogAction(
          label: 'Track order',
          onPressed: () {
            next = 'track';
            dismiss();
          },
        ),
        DialogAction(
          label: 'Continue shopping',
          onPressed: () {
            next = 'shop';
            dismiss();
          },
        ),
      ],
    );

    if (!context.mounted) return;
    if (next == 'track') {
      context.push('/order/${order.id}');
    } else {
      context.go('/app');
    }
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool showPrice = true,
    bool bold = false,
    Color? brand,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, mobile: bold ? 15 : 13),
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Flexible(
            child: Text(
              showPrice ? value : 'Contact for Price',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, mobile: bold ? 15 : 13),
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: bold ? brand : (showPrice ? null : Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.label,
    required this.address,
    required this.selected,
    required this.accent,
    required this.value,
  });

  final String label;
  final String address;
  final bool selected;
  final Color accent;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Radio<int>(value: value, activeColor: accent),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    address,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 12.5),
                      color: selected ? null : Colors.grey[600],
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.name,
    required this.icon,
    required this.note,
    required this.selected,
  });

  final String name;
  final IconData icon;
  final String note;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: RadioListTile<String>(
          value: name,
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Icon(icon, size: 19),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          subtitle: Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}

class _LineSummary extends StatelessWidget {
  const _LineSummary({
    required this.name,
    required this.qty,
    required this.amount,
    required this.showPrice,
    required this.currency,
  });

  final String name;
  final int qty;
  final int amount;
  final bool showPrice;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$name × $qty',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, mobile: 13),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            showPrice
                ? Pricing.money(amount, currencySymbol: currency)
                : 'Contact',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, mobile: 13),
              fontWeight: FontWeight.w600,
              color: showPrice ? null : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
