import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:common_widgets/common_widgets.dart';
import '../core/store/commerce_store.dart';
import 'auth/providers/auth_provider.dart';
import 'config/providers/business_config_provider.dart';
import 'catalogue/screens/catalogue_screen.dart';
import 'home/home_sections.dart';
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

  static const List<String> _titles = [
    'Home',
    'Catalogue',
    'Wishlist',
    'Orders',
    'Account',
  ];

  static const List<IconData> _icons = [
    Icons.home_outlined,
    Icons.storefront_outlined,
    Icons.favorite_border,
    Icons.receipt_long_outlined,
    Icons.person_outline,
  ];

  static const List<IconData> _activeIcons = [
    Icons.home,
    Icons.storefront,
    Icons.favorite,
    Icons.receipt_long,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final user = context.watch<AuthProvider>().user;
    final hasItems = store.cartCount > 0;
    final hasUnread = user != null && store.unreadCount(user.id) > 0;

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        titleSpacing: AppSpacing.screenH,
        title: Row(
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: config.primaryColor,
                borderRadius: AppRadius.allSm,
              ),
              child: Icon(config.icon, size: 18, color: config.onPrimaryColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                config.name,
                style: AppTypography.title.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          _CircleAction(
            icon: Icons.search,
            tooltip: 'Search',
            onTap: () => context.push('/catalogue'),
          ),
          _CircleAction(
            icon: Icons.shopping_bag_outlined,
            tooltip: 'Cart',
            onTap: () => context.push('/cart'),
            badge: hasItems,
          ),
          _CircleAction(
            icon: Icons.notifications_none,
            tooltip: 'Notifications',
            onTap: () => context.push('/notifications'),
            badge: hasUnread,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppPalette.surface,
          border: Border(top: BorderSide(color: AppPalette.divider)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: List.generate(_titles.length, (i) {
                final selected = i == _currentIndex;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _currentIndex = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: AppDurations.fast,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? config.accentColor
                                : Colors.transparent,
                            borderRadius: AppRadius.allPill,
                          ),
                          child: Icon(
                            selected ? _activeIcons[i] : _icons[i],
                            size: 21,
                            color: selected
                                ? config.primaryColor
                                : AppPalette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _titles[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            fontSize: 10.5,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? config.primaryColor
                                : AppPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const _HomeTab();
      case 1:
        return CatalogueScreen(onExit: () => setState(() => _currentIndex = 0));
      case 2:
        return const WishlistScreen();
      case 3:
        return const OrdersScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const _HomeTab();
    }
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool badge;

  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            height: 38,
            width: 38,
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 21, color: AppPalette.textPrimary),
                if (badge)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      height: 7,
                      width: 7,
                      decoration: const BoxDecoration(
                        color: AppPalette.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  String? _photoFor(CommerceStore store, String category) {
    for (final product in store.shopProducts) {
      if (product.category == category && product.images.isNotEmpty) {
        return product.images.first;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final featured = [...store.shopProducts]
      ..sort((a, b) {
        final rating = b.rating.compareTo(a.rating);
        return rating != 0 ? rating : b.reviewCount.compareTo(a.reviewCount);
      });
    final curated = featured.take(10).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE JEWELLERY EDIT',
                  style: AppTypography.overline.copyWith(
                    color: AppPalette.textSecondary,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pieces to treasure, every day.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 15),
                AppSearchField(hint: config.searchHint),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: HeroCarousel(products: curated),
          ),
          const SizedBox(height: AppSpacing.xxl),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: SectionHeader(
              title: 'Shop by Style',
              padding: EdgeInsets.zero,
              trailing: TextButton(
                onPressed: () => context.push(catalogueLocation()),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                ),
                child: const Text('View All'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          CategoryCarousel(
            primaryColor: config.primaryColor,
            accentColor: config.accentColor,
            items: config.categories
                .map(
                  (cat) => CategoryCarouselItem(
                    label: cat,
                    emoji: config.categoryIcons[cat] ?? '\u{1F4E6}',
                    imageUrl: _photoFor(store, cat),
                    onTap: () => context.push(catalogueLocation(category: cat)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xxl),

          const NewArrivalsRail(),
          const SizedBox(height: AppSpacing.xxl),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: SectionHeader(
              title: 'Featured products',
              padding: EdgeInsets.zero,
              trailing: TextButton(
                onPressed: () => context.push(catalogueLocation()),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                ),
                child: const Text('Explore all'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ProductRail(products: curated, autoSlideImages: true),
          const SizedBox(height: AppSpacing.xxl),

          const PriceBands(),
          const SizedBox(height: AppSpacing.xxl),
          const PromiseGrid(),
        ],
      ),
    );
  }
}
