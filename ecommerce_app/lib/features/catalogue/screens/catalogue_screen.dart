import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:common_widgets/common_widgets.dart';
import '../../config/providers/business_config_provider.dart';
import '../../../core/business_config.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  String _selectedCategory = 'All';
  String _sortBy = 'Newest';
  bool _isGrid = true;

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final allCategories = ['All', ...config.categories];
    final products = List.generate(12, (i) => {
      'name': '${config.categories[i % config.categories.length]} Product ${i + 1}',
      'price': '${config.currencySymbol}${(i + 1) * 499}',
      'sku': 'SKU-${(i + 1).toString().padLeft(4, '0')}',
      'category': config.categories[i % config.categories.length],
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue'),
        actions: [
          IconButton(
            icon: Icon(_isGrid ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: Responsive.padding(context),
            child: AppSearchField(hint: config.searchHint, onFilterPressed: () {}),
          ),
          // Categories
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: allCategories.length,
              separatorBuilder: (_, _) => SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = allCategories[index];
                final selected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat, maxLines: 1, overflow: TextOverflow.ellipsis),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  selectedColor: config.primaryColor,
                  labelStyle: TextStyle(color: selected ? Colors.white : null, fontSize: Responsive.fontSize(context, mobile: 12)),
                );
              },
            ),
          ),
          SizedBox(height: 8),
          // Sort
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${products.length} items', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12), color: Colors.grey[600])),
                Spacer(),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: SizedBox(),
                  isDense: true,
                  items: ['Newest', 'Price: Low', 'Price: High', 'Name'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12))))).toList(),
                  onChanged: (v) => setState(() => _sortBy = v ?? 'Newest'),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          // Products
          Expanded(
            child: _isGrid
                ? GridView.builder(
                    padding: Responsive.padding(context),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Responsive.crossAxisCount(context),
                      childAspectRatio: Responsive.childAspectRatio(context),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) => _ProductCard(product: products[index], config: config),
                  )
                : ListView.separated(
                    padding: Responsive.padding(context),
                    itemCount: products.length,
                    separatorBuilder: (_, _) => SizedBox(height: 8),
                    itemBuilder: (context, index) => _ProductListTile(product: products[index], config: config),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, String> product;
  final BusinessConfig config;
  const _ProductCard({required this.product, required this.config});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/product/0'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: config.accentColor, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Icon(config.icon, size: 36, color: config.primaryColor.withValues(alpha: 0.5))),
            ),
          ),
          const SizedBox(height: 8),
          Text(product['name']!, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12), fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(product['sku']!, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 10), color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          config.rules.showPrices
              ? Text(product['price']!, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 14), fontWeight: FontWeight.bold, color: config.primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis)
              : Text('Contact for Price', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12), fontWeight: FontWeight.bold, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final Map<String, String> product;
  final BusinessConfig config;
  const _ProductListTile({required this.product, required this.config});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/product/0'),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: config.accentColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Icon(config.icon, size: 28, color: config.primaryColor.withValues(alpha: 0.5))),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(product['name']!, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 14), fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Text(product['sku']!, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 11), color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              config.rules.showPrices
                  ? Text(product['price']!, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 14), fontWeight: FontWeight.bold, color: config.primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis)
                  : Text('Contact for Price', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12), fontWeight: FontWeight.bold, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 4),
              Icon(Icons.favorite_border, size: 18, color: Colors.grey[400]),
            ],
          ),
        ],
      ),
    );
  }
}
