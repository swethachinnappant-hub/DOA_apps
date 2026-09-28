import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../core/business_config.dart';
import '../../core/pricing.dart';
import '../../core/product.dart';
import '../../core/store/commerce_store.dart';
import '../../widgets/product_card.dart';
import '../config/providers/business_config_provider.dart';

/// Builds a `/catalogue` location carrying the filters a home tile promises,
/// so every call to action on the home screen lands on a real result set.
String catalogueLocation({String? category, int? min, int? max}) {
  final params = <String, String>{};
  if (category != null && category.isNotEmpty) params['category'] = category;
  if (min != null) params['min'] = '$min';
  if (max != null) params['max'] = '$max';
  if (params.isEmpty) return '/catalogue';
  final query = params.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');
  return '/catalogue?$query';
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

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _count <= 1) return;
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

  List<({String title, String subtitle, String cta, String location})> _slides(
    BusinessConfig config,
  ) {
    final categories = config.categories;
    final lead = categories.isEmpty ? '' : categories.first;
    return <({String title, String subtitle, String cta, String location})>[
      (
        title: config.name,
        subtitle: config.tagline,
        cta: 'Browse catalogue',
        location: catalogueLocation(),
      ),
      if (lead.isNotEmpty)
        (
          title: 'Shop by category',
          subtitle: '${categories.length} collections to explore',
          cta: lead,
          location: catalogueLocation(category: lead),
        ),
      if (config.rules.showPrices)
        (
          title: 'Curated by price',
          subtitle: 'Find your sparkle for less',
          cta: 'Under ${config.currencySymbol}1,500',
          location: catalogueLocation(max: 1500),
        )
      else
        (
          title: 'Enquiry pricing',
          subtitle: 'Ask the shop for your trade rate',
          cta: 'Browse stock',
          location: catalogueLocation(),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final slides = _slides(config);
    _count = slides.length;
    final height = Responsive.isDesktop(context) ? 300.0 : 224.0;
    final images = widget.products
        .where((product) => product.images.isNotEmpty)
        .map((product) => product.images.first)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              final slide = slides[index];
              return _HeroSlide(
                title: slide.title,
                subtitle: slide.subtitle,
                cta: slide.cta,
                icon: config.icon,
                imageUrl: images.isEmpty ? null : images[index % images.length],
                gradient: LinearGradient(
                  colors: [
                    config.primaryColor,
                    Color.lerp(
                      config.primaryColor,
                      config.secondaryColor,
                      0.5,
                    )!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onPrimary: Colors.white,
                primaryColor: config.primaryColor,
                onTap: () => context.push(slide.location),
              );
            },
          ),
        ),
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
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(Colors.black, Colors.black, 0.68)!,
                      Colors.black.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.title.copyWith(
                              color: onPrimary,
                            ),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: onPrimary,
                              borderRadius: AppRadius.allPill,
                            ),
                            child: Text(
                              cta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label.copyWith(
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Icon(
                      icon,
                      size: 54,
                      color: onPrimary.withValues(alpha: 0.28),
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

  const ProductRail({
    super.key,
    required this.products,
    this.autoSlideImages = true,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final width = Responsive.isDesktop(context)
        ? 272.0
        : Responsive.isTablet(context)
        ? 232.0
        : 202.0;

    return SizedBox(
      height: Responsive.isDesktop(context)
          ? 468
          : Responsive.isTablet(context)
          ? 420
          : 388,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: width,
            child: ProductCard(
              product: product,
              primaryColor: config.primaryColor,
              accentColor: config.accentColor,
              currency: config.currencySymbol,
              showRating: true,
              showPrice: config.rules.showPrices,
              autoSlideImages: autoSlideImages,
              liked: store.isWishlisted(product.id),
              onWishlist: () => store.toggleWishlist(product.id),
              onTap: () => context.push('/product/${product.id}'),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: SectionHeader(
            title: 'Just In',
            padding: EdgeInsets.zero,
            trailing: TextButton(
              onPressed: () => context.push(catalogueLocation()),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              child: const Text('View All'),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ProductRail(products: newest, autoSlideImages: true),
      ],
    );
  }
}

/// Price bands, mirroring Kirtilals' "Curated by Price". Only shown when the
/// business actually publishes prices.
class PriceBands extends StatelessWidget {
  const PriceBands({super.key});

  static const List<({int? min, int? max})> bands = [
    (min: null, max: 1500),
    (min: 1500, max: 3000),
    (min: 3000, max: 6000),
    (min: 6000, max: null),
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
      '${Pricing.money(bands[3].min!, currencySymbol: symbol)} & above',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: SectionHeader(
            title: 'Curated by price',
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
                  borderRadius: AppRadius.allPill,
                  onTap: () => context.push(
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
                        Text(
                          labels[i],
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

/// Compact shopping assurances backed by real checkout and order behavior.
class PromiseGrid extends StatelessWidget {
  const PromiseGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final symbol = config.currencySymbol;

    final items = <({IconData icon, String title, String detail})>[
      (
        icon: Icons.local_shipping_outlined,
        title: 'Complimentary delivery',
        detail: 'On orders over $symbol${Pricing.freeShippingThreshold}',
      ),
      (
        icon: Icons.receipt_long_outlined,
        title: 'Clear checkout totals',
        detail:
            'GST ${(Pricing.gstRate * 100).round()}% is included in your total',
      ),
      (
        icon: Icons.explore_outlined,
        title: 'Order updates',
        detail: 'Follow your jewellery from order to delivery',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: SectionHeader(
            title: 'A thoughtful shopping experience',
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Container(
            decoration: BoxDecoration(
              color: AppPalette.surfaceMuted,
              borderRadius: AppRadius.allMd,
            ),
            child: Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  if (index > 0)
                    const Divider(height: 1, indent: 58, endIndent: 16),
                  ListTile(
                    minVerticalPadding: 13,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        items[index].icon,
                        size: 18,
                        color: config.primaryColor,
                      ),
                    ),
                    title: Text(
                      items[index].title,
                      style: AppTypography.label.copyWith(
                        fontSize: 12.5,
                        letterSpacing: 0,
                      ),
                    ),
                    subtitle: Text(
                      items[index].detail,
                      style: AppTypography.caption.copyWith(fontSize: 11.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
