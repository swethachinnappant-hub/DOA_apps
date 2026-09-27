import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/business_config.dart';
import 'config/providers/business_config_provider.dart';
import 'package:common_widgets/common_widgets.dart';
import 'catalogue/screens/catalogue_screen.dart';
import 'wishlist/screens/wishlist_screen.dart';
import 'orders/screens/orders_screen.dart';
import 'profile/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Home',
    'Catalogue',
    'Wishlist',
    'Orders',
    'Account',
  ];
  final List<IconData> _icons = [
    Icons.home,
    Icons.storefront,
    Icons.favorite_border,
    Icons.receipt_long,
    Icons.person_outline,
  ];

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/catalogue'),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: config.primaryColor,
        unselectedItemColor: Colors.grey,
        items: List.generate(
          5,
          (i) =>
              BottomNavigationBarItem(icon: Icon(_icons[i]), label: _titles[i]),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _HomeTab();
      case 1:
        return _CatalogueTab();
      case 2:
        return _WishlistTab();
      case 3:
        return _OrdersTab();
      case 4:
        return _AccountTab();
      default:
        return _HomeTab();
    }
  }
}

class _HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    return SingleChildScrollView(
      padding: Responsive.padding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          AppSearchField(
            hint: config.searchHint,
            onFilterPressed: () => context.push('/catalogue'),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),

          // Banner
          GradientCard(
            gradient: LinearGradient(
              colors: [config.primaryColor, config.secondaryColor],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome to ${config.name}',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(
                            context,
                            mobile: 18,
                            tablet: 22,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        config.tagline,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(
                            context,
                            mobile: 12,
                            tablet: 14,
                          ),
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  config.icon,
                  size: Responsive.fontSize(context, mobile: 60),
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 20)),

          // Categories
          SectionHeader(title: 'Categories', padding: EdgeInsets.only(top: 16)),
          SizedBox(height: Responsive.spacing(context, mobile: 12)),
          SizedBox(
            height: Responsive.spacing(context, mobile: 100),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: config.categories.length,
              separatorBuilder: (_, _) => SizedBox(width: 12),
              itemBuilder: (context, index) {
                final cat = config.categories[index];
                final icon = config.categoryIcons[cat] ?? '📦';
                return GestureDetector(
                  onTap: () => context.push('/catalogue'),
                  child: Container(
                    width: Responsive.spacing(context, mobile: 80),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(
                          cat,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, mobile: 10),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 20)),

          // Featured Products
          SectionHeader(
            title: 'Featured Products',
            padding: EdgeInsets.only(top: 16),
            trailing: TextButton(
              onPressed: () => context.push('/catalogue'),
              child: Text('View All'),
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 12)),
          _buildProductGrid(context, config),
        ],
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, BusinessConfig config) {
    final rules = config.rules;
    final products = List.generate(
      6,
      (i) => {
        'name':
            '${config.categories[i % config.categories.length]} Item ${i + 1}',
        'price': '${config.currencySymbol}${(i + 1) * 999}',
        'sku': 'SKU-${(i + 1).toString().padLeft(4, '0')}',
      },
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.crossAxisCount(context),
        childAspectRatio: Responsive.childAspectRatio(context),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return AppCard(
          onTap: () => context.push('/product/$index'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: config.accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      config.icon,
                      size: 40,
                      color: config.primaryColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                p['name']!,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, mobile: 12),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: rules.showPrices
                        ? Text(
                            p['price']!,
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
                  ),
                  Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CatalogueTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CatalogueScreen();
  }
}

class _WishlistTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const WishlistScreen();
  }
}

class _OrdersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const OrdersScreen();
  }
}

class _AccountTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}
