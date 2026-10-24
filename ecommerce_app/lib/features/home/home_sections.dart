import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../core/business_config.dart';
import '../../core/demo_catalog.dart';
import '../../core/models/cms.dart';
import '../../core/models/order.dart';
import '../../core/navigation/menu_data.dart';
import '../../core/navigation/nav_helpers.dart';
import '../../core/pricing.dart';
import '../../core/product.dart';
import '../../core/store/commerce_store.dart';
import '../../widgets/product_card.dart';
import '../../widgets/quick_add_sheet.dart';
import '../config/providers/business_config_provider.dart';

/// Builds a `/catalogue` location carrying the filters a home tile promises,
/// so every call to action on the home screen lands on a real result set.
String catalogueLocation({
  String? category,
  int? min,
  int? max,
  String? metal,
}) {
  final params = <String, String>{};
  if (category != null && category.isNotEmpty) params['category'] = category;
  if (min != null) params['min'] = '$min';
  if (max != null) params['max'] = '$max';
  if (metal != null && metal.isNotEmpty) params['metal'] = metal;
  if (params.isEmpty) return '/catalogue';
  final query = params.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');
  return '/catalogue?$query';
}

/// Key for every navigable home tile (§6 gate: each tile carries the route it
/// opens so the layout test can walk the stack and prove every one lands).
ValueKey<String> homeTileKey(String section, String label, String route) =>
    ValueKey('home-tile:$section|$label|$route');

/// The config-derived default hero slides (§6 hero), also the seed list the
/// Home Builder opens with before an owner takes over (SPEC-18).
List<HeroSlide> defaultHeroSlides(BusinessConfig config) {
  return <HeroSlide>[
    HeroSlide(
      title: 'Fresh designs for your store',
      subtitle: 'Explore newly listed jewellery, ready for wholesale orders.',
      cta: 'Shop new arrivals',
      location: '/catalogue?sort=Newest',
    ),
    HeroSlide(
      title: 'Retailer favourites',
      subtitle: 'Discover popular designs from the jewellery collection.',
      cta: 'Shop best sellers',
      location: '/bestsellers',
    ),
    if (config.rules.showPrices)
      HeroSlide(
        title: 'Better value on bulk orders',
        subtitle: 'Explore wholesale prices and available offers.',
        cta: 'Explore wholesale deals',
        location: '/catalogue?sort=Discount',
      )
    else
      HeroSlide(
        title: 'Enquiry pricing',
        subtitle: 'Ask the shop for your trade rate',
        cta: 'Browse stock',
        location: catalogueLocation(),
      ),
  ];
}

/// Section header in the §6.3 mould: serif title plus an optional "View all"
/// text link that navigates to the full result set.
class _SectionLinkHeader extends StatelessWidget {
  const _SectionLinkHeader({
    required this.section,
    required this.title,
    this.actionLabel,
    this.route,
  });

  /// Layout section id (§6.1) — carried in the tile key so the gate test can
  /// scroll the owning section into view before tapping.
  final String section;
  final String title;
  final String? actionLabel;
  final String? route;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: SectionHeader(
        title: title,
        padding: EdgeInsets.zero,
        trailing: actionLabel == null
            ? null
            : TextButton(
                key: homeTileKey(section, actionLabel!, route!),
                onPressed: () => navTo(context, route!),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                ),
                child: Text(actionLabel!),
              ),
      ),
    );
  }
}

/// Swapping hero banners in the Kirtilals mould, built only from the store's
/// own configuration and routed to screens that exist.
class HeroCarousel extends StatefulWidget {
  final List<Product> products;

  const HeroCarousel({super.key, this.products = const []});

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _page = 0;
  int _count = 0;
  // §5.31: pause the autoplay while the shopper is dragging, so the banner
  // never fights the gesture.
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _dragging || _count <= 1) return;
      _controller.animateToPage(
        (_page + 1) % _count,
        duration: AppDurations.slow,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Owner-edited slides (SPEC-18) win over the config-derived defaults;
  /// disabled slides never reach the carousel.
  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final slides =
        (context.watch<CommerceStore>().heroSlides ?? defaultHeroSlides(config))
            .where((slide) => slide.enabled)
            .toList();
    _count = slides.length;
    if (slides.isEmpty) return const SizedBox.shrink();
    // §6.1: desktop keeps the wide band; phones get a taller portrait
    // rectangle; tablets sit in between instead of shrinking below both.
    final mobile = Responsive.isMobile(context);
    final height = Responsive.isDesktop(context)
        ? 320.0
        : mobile
        ? 400.0
        : 288.0;
    final images = widget.products
        .where((product) => product.images.isNotEmpty)
        .map((product) => product.images.first)
        .toSet()
        .toList();

    final carousel = SizedBox(
      height: height,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification &&
              notification.dragDetails != null) {
            _dragging = true;
          } else if (notification is ScrollEndNotification) {
            _dragging = false;
          }
          return false;
        },
        child: PageView.builder(
          controller: _controller,
          itemCount: slides.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, index) {
            final slide = slides[index];
            final imageUrl = slide.imageUrl.isNotEmpty
                ? slide.imageUrl
                : (images.isEmpty ? null : images[index % images.length]);
            return _HeroSlide(
              key: homeTileKey('hero', slide.cta, slide.location),
              title: slide.title,
              subtitle: slide.subtitle,
              cta: slide.cta,
              icon: config.icon,
              imageUrl: imageUrl,
              gradient: LinearGradient(
                colors: [
                  config.primaryColor,
                  Color.lerp(config.primaryColor, config.secondaryColor, 0.5)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onPrimary: Colors.white,
              primaryColor: config.primaryColor,
              onTap: () => navTo(context, slide.location),
            );
          },
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        carousel,
        if (slides.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(slides.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: AppDurations.fast,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: active ? 18 : 6,
                decoration: BoxDecoration(
                  color: active
                      ? config.primaryColor
                      : config.primaryColor.withValues(alpha: 0.25),
                  borderRadius: AppRadius.allPill,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _HeroSlide extends StatelessWidget {
  final String title;
  final String subtitle;
  final String cta;
  final IconData icon;
  final String? imageUrl;
  final Gradient gradient;
  final Color onPrimary;
  final Color primaryColor;
  final VoidCallback onTap;

  const _HeroSlide({
    super.key,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.icon,
    this.imageUrl,
    required this.gradient,
    required this.onPrimary,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadius.allLg,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.allLg,
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null)
                ProductImageTile(
                  url: imageUrl!,
                  fit: BoxFit.cover,
                  placeholderIcon: icon,
                  placeholderColor: primaryColor.withValues(alpha: 0.12),
                  placeholderAccent: primaryColor,
                ),
              if (imageUrl != null)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0x99000000),
                        Color(0x4D000000),
                        Color(0x00000000),
                      ],
                      stops: [0, 0.48, 1],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title.copyWith(color: onPrimary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: onPrimary.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text(
                        cta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: onPrimary,
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        textStyle: AppTypography.label,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal product rail shared by the "Just In" and featured sections.
class ProductRail extends StatelessWidget {
  final List<Product> products;
  final bool autoSlideImages;
  final bool compact;
  final String? badgeOverride;
  final Set<String>? bestsellerIds;

  const ProductRail({
    super.key,
    required this.products,
    this.autoSlideImages = false,
    this.compact = false,
    this.badgeOverride,
    this.bestsellerIds,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final width = compact && Responsive.isMobile(context)
        ? 164.0
        : Responsive.isDesktop(context)
        ? 288.0
        : Responsive.isTablet(context)
        ? 248.0
        : 216.0;

    return SizedBox(
      height: compact && Responsive.isMobile(context)
          ? 350
          : Responsive.isDesktop(context)
          ? 560
          : Responsive.isTablet(context)
          ? 510
          : 420,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: width,
            child: ProductCard(
              product: product,
              primaryColor: config.primaryColor,
              accentColor: config.accentColor,
              currency: config.currencySymbol,
              badgeOverride:
                  badgeOverride ??
                  (bestsellerIds?.contains(product.id) == true
                      ? 'Best seller'
                      : null),
              showRating: !compact,
              showPrice: config.rules.showPrices,
              autoSlideImages: autoSlideImages,
              liked: store.isWishlisted(product.id),
              onWishlist: () => store.toggleWishlist(product.id),
              onTap: () => navTo(context, '/product/${product.id}'),
              onQuickAdd: !product.isAvailable
                  ? null
                  : () => showQuickAddSheet(context, product, store),
            ),
          );
        },
      ),
    );
  }
}

/// "Just In" rail: the newest stock first, straight from the live store so an
/// owner's fresh listing shows up without a restart.
class NewArrivalsRail extends StatelessWidget {
  const NewArrivalsRail({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CommerceStore>();
    final products = [...store.shopProducts]
      ..sort((a, b) {
        final aTime = a.createdAt;
        final bTime = b.createdAt;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
    final newest = products.take(10).toList();
    if (newest.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLinkHeader(
          section: 'newArrivals',
          title: 'New Arrivals',
          actionLabel: 'View All',
          route: '/catalogue?sort=Newest',
        ),
        const SizedBox(height: AppSpacing.md),
        ProductRail(
          products: newest,
          autoSlideImages: true,
          badgeOverride: 'New arrival',
        ),
      ],
    );
  }
}

/// Ranks recent order activity first, then review volume, for a live trending
/// rail. Cancelled and returned orders do not contribute to the ranking.
class TrendingRail extends StatelessWidget {
  const TrendingRail({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CommerceStore>();
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recentSales = <String, int>{};
    for (final order in store.allOrders) {
      if (order.placedAt.isBefore(cutoff) ||
          order.status == OrderStatus.cancelled ||
          order.status == OrderStatus.returned) {
        continue;
      }
      for (final item in order.items) {
        recentSales.update(
          item.productId,
          (quantity) => quantity + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }
    }
    final products = [...store.shopProducts]
      ..sort((a, b) {
        final sales = (recentSales[b.id] ?? 0).compareTo(recentSales[a.id] ?? 0);
        if (sales != 0) return sales;
        // Homepage spec §1.03: with sales even, occasion-tagged designs
        // (wedding, festive, party) surface as the trending picks.
        final occasion = b.occasions.length.compareTo(a.occasions.length);
        if (occasion != 0) return occasion;
        final reviews = b.reviewCount.compareTo(a.reviewCount);
        return reviews != 0 ? reviews : b.rating.compareTo(a.rating);
      });
    final trending = products.take(10).toList();
    if (trending.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLinkHeader(
          section: 'trending',
          title: 'Trending Jewellery',
          actionLabel: 'View All',
          route: '/catalogue',
        ),
        const SizedBox(height: AppSpacing.md),
        ProductRail(products: trending, badgeOverride: 'Trending now'),
      ],
    );
  }
}

/// Products a buyer has recently opened, surfaced again from shared store
/// history so returning retailers can get back to a design quickly.
class RecentlyViewedRail extends StatelessWidget {
  const RecentlyViewedRail({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<CommerceStore>().recentlyViewed;
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLinkHeader(
          section: 'recentlyViewed',
          title: 'Recently Viewed',
          actionLabel: 'View All',
          route: '/catalogue',
        ),
        const SizedBox(height: AppSpacing.md),
        ProductRail(products: products),
      ],
    );
  }
}

/// Price bands, mirroring Kirtilals' "Curated by Price". Only shown when the
/// business actually publishes prices.
class PriceBands extends StatelessWidget {
  const PriceBands({super.key});

  static const List<({int? min, int? max})> bands = [
    (min: null, max: 500),
    (min: 501, max: 1500),
    (min: 1501, max: 3000),
    (min: 3001, max: 6000),
    (min: 6001, max: null),
  ];

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    if (!config.rules.showPrices) return const SizedBox.shrink();

    final symbol = config.currencySymbol;
    final labels = [
      'Under ${Pricing.money(bands[0].max!, currencySymbol: symbol)}',
      '${Pricing.money(bands[1].min!, currencySymbol: symbol)} – ${Pricing.money(bands[1].max!, currencySymbol: symbol)}',
      '${Pricing.money(bands[2].min!, currencySymbol: symbol)} – ${Pricing.money(bands[2].max!, currencySymbol: symbol)}',
      '${Pricing.money(bands[3].min!, currencySymbol: symbol)} – ${Pricing.money(bands[3].max!, currencySymbol: symbol)}',
      '${Pricing.money(bands[4].min!, currencySymbol: symbol)} & above',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: SectionHeader(
            title: 'Wholesale Deals by Price',
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < bands.length; i++)
                InkWell(
                  key: homeTileKey(
                    'price',
                    labels[i],
                    catalogueLocation(min: bands[i].min, max: bands[i].max),
                  ),
                  borderRadius: AppRadius.allPill,
                  onTap: () => navTo(
                    context,
                    catalogueLocation(min: bands[i].min, max: bands[i].max),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.surface,
                      borderRadius: AppRadius.allPill,
                      border: Border.all(color: AppPalette.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sell_outlined,
                          size: 14,
                          color: config.primaryColor,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        // §11.5: the pill must stay inside the section width
                        // at 200% text instead of overflowing.
                        Flexible(
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.label.copyWith(
                              color: AppPalette.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Discounted, available listings collected in one wholesale offer rail.
class WholesaleDealsRail extends StatelessWidget {
  const WholesaleDealsRail({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    if (!config.rules.showPrices) return const SizedBox.shrink();
    final products = context
        .watch<CommerceStore>()
        .shopProducts
        .where((product) => product.isAvailable && product.hasDiscount)
        .toList()
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    final deals = products.take(10).toList();
    if (deals.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLinkHeader(
          section: 'deals',
          title: 'Wholesale Deals',
          actionLabel: 'View All',
          route: '/catalogue?sort=Discount',
        ),
        const SizedBox(height: AppSpacing.md),
        ProductRail(products: deals, badgeOverride: 'Wholesale deal'),
      ],
    );
  }
}

/// Hero band spanning the full page width, sourced straight from the live
/// store.
class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CommerceStore>();
    final featured = [...store.shopProducts]
      ..sort((a, b) {
        final rating = b.rating.compareTo(a.rating);
        return rating != 0 ? rating : b.reviewCount.compareTo(a.reviewCount);
      });
    return HeroCarousel(products: featured.take(10).toList());
  }
}

/// "Shop by Category": the store's own categories as the §6.1 circle rail.
class ShopByCategory extends StatelessWidget {
  const ShopByCategory({super.key});

  /// The rail shows photographs, never emoji: prefer an available listing's
  /// shot, then any listing (a sold-out design still has its photo), and as a
  /// last resort the catalogue's category→photo map — every configured
  /// category has a real shot there.
  String _photoFor(CommerceStore store, String category) {
    for (final product in store.shopProducts) {
      if (product.category == category && product.images.isNotEmpty) {
        return product.images.first;
      }
    }
    for (final product in store.allProducts) {
      if (product.category == category && product.images.isNotEmpty) {
        return product.images.first;
      }
    }
    return DemoCatalog.imageForCategory(category);
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLinkHeader(
          section: 'categories',
          title: 'Shop by Category',
          actionLabel: 'View All',
          route: '/catalogue',
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
                  onTap: () => navTo(
                    context,
                    '/catalogue?category=${Uri.encodeQueryComponent(cat)}',
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

/// "Shop by Metal": three shade tiles landing on a metal-filtered listing.
class ShopByMetal extends StatelessWidget {
  const ShopByMetal({super.key});

  static const List<(String, Color)> metals = [
    ('Yellow Gold', Color(0xFFD4A843)),
    ('White Gold', Color(0xFFD9DDE3)),
    ('Rose Gold', Color(0xFFB76E79)),
  ];

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    if (config.type != BusinessType.jewellery) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLinkHeader(section: 'metal', title: 'Shop by Metal'),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (name, swatch) in metals)
                InkWell(
                  key: homeTileKey(
                    'metal',
                    name,
                    catalogueLocation(metal: name),
                  ),
                  borderRadius: AppRadius.allPill,
                  onTap: () => navTo(context, catalogueLocation(metal: name)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.surface,
                      borderRadius: AppRadius.allPill,
                      border: Border.all(color: AppPalette.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: swatch,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppPalette.border),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          name,
                          style: AppTypography.label.copyWith(
                            color: AppPalette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Collections" rail built from the verified collection tiles (§4.2), so the
/// home page and the mega-menu cannot drift apart. Each tile is a photo card
/// (owner-set image, else a catalogue shot that matches the collection name),
/// with the label on a slim black bar — image first, minimal gutters.
class CollectionsRail extends StatelessWidget {
  const CollectionsRail({super.key});

  String? _photoFor(CommerceStore store, ShopCollection tile) {
    if (tile.imageUrl.isNotEmpty) return tile.imageUrl;
    final products = store.shopProducts;
    if (products.isEmpty) return null;
    final needle = tile.name.toLowerCase();
    for (final product in products) {
      if (product.images.isNotEmpty &&
          needle.contains(product.category.toLowerCase())) {
        return product.images.first;
      }
    }
    final pick = products[tile.name.hashCode.abs() % products.length];
    return pick.images.isNotEmpty ? pick.images.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    // §4.2 tiles, minus the owner's hidden ones and with their renames and
    // images applied (SPEC-18) — defaults render exactly as before.
    final store = context.watch<CommerceStore>();
    final tiles = store.visibleCollections;
    if (tiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLinkHeader(section: 'collections', title: 'Collections'),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            itemCount: tiles.length,
            separatorBuilder: (_, _) => const SizedBox(width: 3),
            itemBuilder: (context, index) {
              final tile = tiles[index];
              final photo = _photoFor(store, tile);
              return Material(
                color: AppPalette.surface,
                borderRadius: AppRadius.allSm,
                child: InkWell(
                  key: homeTileKey('collections', tile.name, tile.route),
                  borderRadius: AppRadius.allSm,
                  onTap: () => navTo(context, tile.route),
                  child: Container(
                    width: 196,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.allSm,
                      border: Border.all(color: AppPalette.border),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (photo != null)
                          ProductImageTile(
                            url: photo,
                            fit: BoxFit.cover,
                            placeholderIcon: StoreNav.categoryIcon(tile.name),
                          )
                        else
                          ColoredBox(
                            color: AppPalette.warm,
                            child: Icon(
                              StoreNav.categoryIcon(tile.name),
                              size: 40,
                              color: config.primaryColor,
                            ),
                          ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            color: AppPalette.textPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 7,
                            ),
                            child: Text(
                              tile.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Matching-product recommendations (UI spec §1.06): necklace + earrings,
/// chain + pendant, bangle + ring, and complete sets — a retailer can buy the
/// pieces together. Each tile shows the piece with its wholesale price.
class CompleteLookRail extends StatelessWidget {
  const CompleteLookRail({super.key});

  /// Title -> the pair of category needles that make a look.
  static const List<(String, String, String)> pairings = [
    ('Necklace + Earrings', 'necklace', 'earring'),
    ('Chain + Pendant', 'chain', 'pendant'),
    ('Bangle + Ring', 'bangle', 'ring'),
    ('Complete Bridal Set', 'bridal', 'necklace'),
  ];

  static bool _matches(Product product, String needle) =>
      product.category.toLowerCase().contains(needle);

  List<Product> _candidates(List<Product> products, String needle) {
    final candidates = products
        .where(
          (product) =>
              _matches(product, needle) &&
              product.images.isNotEmpty &&
              product.isAvailable,
        )
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return candidates;
  }

  (Product, Product)? _bestPair(
    List<Product> products,
    String firstNeedle,
    String secondNeedle,
  ) {
    final first = _candidates(products, firstNeedle);
    final second = _candidates(products, secondNeedle);
    (Product, Product)? best;
    var bestScore = -1.0;
    for (final a in first) {
      for (final b in second) {
        if (a.id == b.id) continue;
        final sharesOccasion = a.occasions.any(
          (occasion) => b.occasions.any(
            (other) => other.toLowerCase() == occasion.toLowerCase(),
          ),
        );
        // Only recommend a set together when both pieces suit at least one
        // of the same occasions; missing seller metadata should not invent a
        // match.
        if (!sharesOccasion) continue;
        final score = a.rating + b.rating;
        if (score > bestScore) {
          best = (a, b);
          bestScore = score;
        }
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<CommerceStore>().shopProducts;
    final looks = <({String title, List<Product> products})>[];
    final used = <String>{};
    for (final (title, first, second) in pairings) {
      final pair = _bestPair(products, first, second);
      if (pair == null) continue;
      final (a, b) = pair;
      // One shared piece (e.g. a bridal necklace) can complete two looks;
      // keep each piece in a single look so the rail stays varied.
      if (used.contains(a.id) || used.contains(b.id)) continue;
      used
        ..add(a.id)
        ..add(b.id);
      looks.add((title: title, products: [a, b]));
    }
    if (looks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLinkHeader(section: 'completeLook', title: 'Complete the Look'),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            itemCount: looks.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final look = looks[index];
              return Container(
                width: 300,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppPalette.surface,
                  borderRadius: AppRadius.allMd,
                  border: Border.all(color: AppPalette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(look.title, style: AppTypography.label),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: Row(
                        children: [
                          for (var i = 0; i < look.products.length; i++) ...[
                            if (i > 0) const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _LookProduct(product: look.products[i]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LookProduct extends StatelessWidget {
  const _LookProduct({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    return InkWell(
      onTap: () => navTo(context, '/product/${product.id}'),
      borderRadius: AppRadius.allSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.allSm,
              child: ProductImageTile(
                url: product.images.first,
                fit: BoxFit.cover,
                placeholderIcon: product.icon,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (config.rules.showPrices)
            Text(
              '${Pricing.money(product.price, currencySymbol: config.currencySymbol)} / unit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontSize: 10.5,
                color: AppPalette.goldDark,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

/// "Bestsellers" rail: badge holders first, then the best rated pieces, with a
/// `View all` hop to the `/bestsellers` collection route.
class BestsellersRail extends StatelessWidget {
  const BestsellersRail({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CommerceStore>();
    final soldUnits = <String, int>{};
    for (final order in store.allOrders) {
      if (order.status == OrderStatus.cancelled ||
          order.status == OrderStatus.returned) {
        continue;
      }
      for (final item in order.items) {
        soldUnits.update(
          item.productId,
          (quantity) => quantity + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }
    }
    final products = [...store.shopProducts]
      ..sort((a, b) {
        final sales = (soldUnits[b.id] ?? 0).compareTo(soldUnits[a.id] ?? 0);
        if (sales != 0) return sales;
        final aBest = a.badges.contains('Bestseller') ? 1 : 0;
        final bBest = b.badges.contains('Bestseller') ? 1 : 0;
        if (aBest != bBest) return bBest - aBest;
        final rating = b.rating.compareTo(a.rating);
        return rating != 0 ? rating : b.reviewCount.compareTo(a.reviewCount);
      });
    final best = products.take(10).toList();
    if (best.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLinkHeader(
          section: 'bestsellers',
          title: 'Bestsellers',
          actionLabel: 'View all',
          route: '/bestsellers',
        ),
        const SizedBox(height: AppSpacing.md),
        ProductRail(
          products: best,
          bestsellerIds: {
            for (final entry in soldUnits.entries)
              if (entry.value > 0) entry.key,
            // Merchandised bestsellers keep the badge even before real sales
            // data exists (UI spec §1.01).
            for (final product in products)
              if (product.badges.any(
                (badge) => badge.toLowerCase().contains('best'),
              ))
                product.id,
          },
        ),
      ],
    );
  }
}

/// "Shop by Occasion": the five verified wear facets (§4.2) as quick tiles.
class ShopByOccasion extends StatelessWidget {
  const ShopByOccasion({super.key});

  static const List<(String, IconData, String)> occasions = [
    ('Daily', Icons.wb_sunny_outlined, '/diamond-earring/daily-wear'),
    ('Casual', Icons.weekend_outlined, '/diamond-earring/casual-wear'),
    ('Office', Icons.business_center_outlined, '/diamond-earring/office-wear'),
    ('Party', Icons.celebration_outlined, '/diamond-earring/party-wear'),
    (
      'Festive & Bridal',
      Icons.favorite_outline,
      '/diamond-earring/festive-bridal-wear',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    if (config.type != BusinessType.jewellery) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLinkHeader(
          section: 'occasion',
          title: 'Shop by Occasion',
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (label, icon, route) in occasions)
                InkWell(
                  key: homeTileKey('occasion', label, route),
                  borderRadius: AppRadius.allPill,
                  onTap: () => navTo(context, route),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.surface,
                      borderRadius: AppRadius.allPill,
                      border: Border.all(color: AppPalette.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 15, color: config.primaryColor),
                        const SizedBox(width: AppSpacing.xs),
                        // §11.5: keep the chip pill within the section at
                        // 200% text.
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.label.copyWith(
                              color: AppPalette.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Bridal & Festive Collection": the full-width Bandhan editorial band plus a
/// rail of wedding/festive stock so the section sells product, not just mood
/// (homepage spec §1.04).
class BridalBanner extends StatelessWidget {
  const BridalBanner({super.key});

  /// Bridal, temple and matching-set stock, plus anything tagged for a
  /// wedding or festival (homepage spec §1.04).
  bool _isBridalOrFestive(Product product) {
    final category = product.category.toLowerCase();
    return category.contains('bridal') ||
        category.contains('temple') ||
        category.contains('set') ||
        product.occasions.any((occasion) =>
            occasion.toLowerCase().contains('wedding') ||
            occasion.toLowerCase().contains('festive'));
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    if (config.type != BusinessType.jewellery) return const SizedBox.shrink();

    final bridal = [...context.watch<CommerceStore>().shopProducts]
        .where((product) => product.isAvailable && _isBridalOrFestive(product))
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final picks = bridal.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: homeTileKey('bridal', 'Bandhan', '/realbrides'),
              borderRadius: AppRadius.allLg,
              onTap: () => navTo(context, '/realbrides'),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      config.primaryColor,
                      Color.lerp(config.primaryColor, config.secondaryColor, 0.6)!,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: AppRadius.allLg,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'BANDHAN',
                              style: AppTypography.eyebrow.copyWith(
                                color: AppPalette.goldLight,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'The bridal collection',
                              style: AppTypography.title.copyWith(
                                color: config.onPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Temple sets, polki and kundan designs for the big day.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: config.onPrimaryColor.withValues(
                                  alpha: 0.88,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // UI spec §5.28: a clear call-to-action button,
                            // never a plain text pill.
                            FilledButton.icon(
                              onPressed: () => navTo(context, '/realbrides'),
                              icon: const Icon(Icons.arrow_forward, size: 15),
                              label: const Text('EXPLORE BRIDAL'),
                              style: FilledButton.styleFrom(
                                backgroundColor: config.onPrimaryColor,
                                foregroundColor: config.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                textStyle: AppTypography.label,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(
                        Icons.favorite_outline,
                        size: 54,
                        color: config.onPrimaryColor.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (picks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          const _SectionLinkHeader(
            section: 'bridal',
            title: 'Bridal & Festive',
            actionLabel: 'View All',
            route: '/catalogue',
          ),
          const SizedBox(height: AppSpacing.md),
          ProductRail(products: picks, badgeOverride: 'Bridal & festive'),
        ],
      ],
    );
  }
}

/// "Gift for Her / Him": stacked banners on compact, split banners on desktop.
class GiftSplit extends StatelessWidget {
  const GiftSplit({super.key});

  static const List<(String, String, IconData)> gifts = [
    ('Gifts for Her', '/gift-for-her', Icons.card_giftcard),
    ('Gifts for him', '/gift-for-him', Icons.shopping_bag_outlined),
  ];

  Widget _banner(
    BuildContext context, {
    required String label,
    required String route,
    required IconData icon,
    required BusinessConfig config,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: homeTileKey('gifts', label, route),
        borderRadius: AppRadius.allLg,
        onTap: () => navTo(context, route),
        child: Ink(
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: AppRadius.allLg,
            border: Border.all(color: AppPalette.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(icon, size: 30, color: config.primaryColor),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: AppTypography.subtitle),
                      const SizedBox(height: 2),
                      Text(
                        'Curated picks, ready to gift',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppPalette.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppPalette.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    if (config.type != BusinessType.jewellery) return const SizedBox.shrink();

    final banners = [
      for (final (label, route, icon) in gifts)
        _banner(
          context,
          label: label,
          route: route,
          icon: icon,
          config: config,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Responsive.isMobile(context)
          ? Column(
              children: [
                for (var i = 0; i < banners.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  banners[i],
                ],
              ],
            )
          : Row(
              children: [
                Expanded(child: banners[0]),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: banners[1]),
              ],
            ),
    );
  }
}

/// Optional social strip (§6.1 #13) — decorative by design: no outbound
/// launcher ships in the app, so the strip shows presence without dead taps.
class SocialStrip extends StatelessWidget {
  const SocialStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    const icons = [
      Icons.camera_alt_outlined,
      Icons.chat_bubble_outline,
      Icons.play_circle_outline,
      Icons.public,
    ];
    return Column(
      children: [
        const _SectionLinkHeader(section: 'social', title: 'In the spotlight'),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            for (final icon in icons)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppPalette.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: config.primaryColor),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tag us for a chance to be featured.',
          style: AppTypography.caption.copyWith(color: AppPalette.textHint),
        ),
      ],
    );
  }
}

/// SEO about block (§6.1 #14): H1 "Online Diamond Jewellery Store" plus the
/// five H3 category links, collapsed behind an accordion on compact widths.
class AboutCollection extends StatelessWidget {
  const AboutCollection({super.key});

  static const List<(String, String)> links = [
    ('Diamond Pendants', '/diamond-pendant'),
    ('Diamond Rings', '/diamond-ring'),
    ('Diamond Necklaces', '/diamond-necklace'),
    ('Diamond Earrings', '/diamond-earrings'),
    ('Diamond Bracelets', '/diamond-bracelet'),
  ];

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    if (config.type != BusinessType.jewellery) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Container(
        decoration: BoxDecoration(
          color: AppPalette.surfaceMuted,
          borderRadius: AppRadius.allMd,
        ),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            'Online Diamond Jewellery Store',
            style: AppTypography.subtitle,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shop certified diamond jewellery online — designs in '
                    'hallmarked gold, crafted for everyday wear and shipped '
                    'with lifetime support.',
                    style: AppTypography.bodyMuted.copyWith(fontSize: 13.5),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final (label, route) in links)
                    InkWell(
                      key: homeTileKey('about', label, route),
                      onTap: () => navTo(context, route),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: config.primaryColor,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                label,
                                style: AppTypography.label.copyWith(
                                  color: AppPalette.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
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
