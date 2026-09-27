import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/providers/business_config_provider.dart';
import 'package:common_widgets/common_widgets.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Map<int, int> _quantities = {};

  void _changeQuantity(int index, int delta) {
    setState(() {
      final next = (_quantities[index] ?? (index + 1)) + delta;
      if (next < 1) return;
      _quantities[index] = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final rules = config.rules;
    final items = List.generate(
      3,
      (i) => {
        'name': '${config.categories[i]} Set ${i + 1}',
        'price': (i + 1) * 2499,
        'qty': _quantities[i] ?? (i + 1),
        'sku': 'SKU-${(i + 1).toString().padLeft(4, '0')}',
      },
    );
    final total = items.fold<int>(
      0,
      (sum, item) => sum + (item['price'] as int) * (item['qty'] as int),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cart is empty',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 16),
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.go('/app'),
                    child: Text('Browse Catalogue'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: Responsive.padding(context),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return AppCard(
                        child: Row(
                          children: [
                            Container(
                              width: Responsive.spacing(context, mobile: 60),
                              height: Responsive.spacing(context, mobile: 60),
                              decoration: BoxDecoration(
                                color: config.accentColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  config.icon,
                                  size: 28,
                                  color: config.primaryColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item['name'] as String,
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(
                                        context,
                                        mobile: 14,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  rules.showPrices
                                      ? Text(
                                          '₹${item['price']} × ${item['qty']}',
                                          style: TextStyle(
                                            fontSize: Responsive.fontSize(
                                              context,
                                              mobile: 12,
                                            ),
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : Text(
                                          'Contact for Price × ${item['qty']}',
                                          style: TextStyle(
                                            fontSize: Responsive.fontSize(
                                              context,
                                              mobile: 12,
                                            ),
                                            color: Colors.grey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                rules.showPrices
                                    ? Text(
                                        '₹${(item['price'] as int) * (item['qty'] as int)}',
                                        style: TextStyle(
                                          fontSize: Responsive.fontSize(
                                            context,
                                            mobile: 14,
                                          ),
                                          fontWeight: FontWeight.bold,
                                          color: config.primaryColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : Text(
                                        'Contact for Price',
                                        style: TextStyle(
                                          fontSize: Responsive.fontSize(
                                            context,
                                            mobile: 12,
                                          ),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _qtyButton(
                                      Icons.remove,
                                      () => _changeQuantity(index, -1),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        '${item['qty']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    _qtyButton(
                                      Icons.add,
                                      () => _changeQuantity(index, 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(
                    Responsive.spacing(context, mobile: 16),
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(
                                  context,
                                  mobile: 14,
                                ),
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            rules.showPrices
                                ? Text(
                                    '₹$total',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(
                                        context,
                                        mobile: 16,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : Text(
                                    'Contact for Price',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(
                                        context,
                                        mobile: 14,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'GST (18%)',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(
                                  context,
                                  mobile: 14,
                                ),
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            rules.showPrices
                                ? Text(
                                    '₹${(total * 0.18).round()}',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(
                                        context,
                                        mobile: 14,
                                      ),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : Text(
                                    'Contact for Price',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(
                                        context,
                                        mobile: 12,
                                      ),
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ],
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(
                                  context,
                                  mobile: 18,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            rules.showPrices
                                ? Text(
                                    '₹${total + (total * 0.18).round()}',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(
                                        context,
                                        mobile: 18,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      color: config.primaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : Text(
                                    'Contact for Price',
                                    style: TextStyle(
                                      fontSize: Responsive.fontSize(
                                        context,
                                        mobile: 14,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ],
                        ),
                        SizedBox(height: 12),
                        AppButton(
                          text: 'Proceed to Checkout',
                          onPressed: () => context.push('/checkout'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
