import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/providers/business_config_provider.dart';
import 'package:common_widgets/common_widgets.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final Set<String> _removedSkus = {};

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final rules = config.rules;
    final items = List.generate(
      4,
      (i) => {
        'name': '${config.categories[i]} Item ${i + 1}',
        'price': '${config.currencySymbol}${(i + 1) * 799}',
        'sku': 'SKU-${(i + 1).toString().padLeft(4, '0')}',
      },
    ).where((item) => !_removedSkus.contains(item['sku'])).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No items in wishlist',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 16),
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Browse catalogue to add items',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 13),
                      color: Colors.grey[400],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: Responsive.padding(context),
              itemCount: items.length,
              separatorBuilder: (_, _) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return AppCard(
                  onTap: () => context.push('/product/$index'),
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
                            color: config.primaryColor.withValues(alpha: 0.5),
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
                              item['name']!,
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
                            Text(
                              item['sku']!,
                              style: TextStyle(
                                fontSize: Responsive.fontSize(
                                  context,
                                  mobile: 11,
                                ),
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          rules.showPrices
                              ? Text(
                                  item['price']!,
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
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red[300],
                            ),
                            tooltip: 'Remove from wishlist',
                            onPressed: () =>
                                setState(() => _removedSkus.add(item['sku']!)),
                          ),
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
