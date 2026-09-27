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

/// The three promises the store can actually keep, quoted straight from
/// [Pricing] so the copy can never drift from what checkout charges.
class TrustBar extends StatelessWidget {
  const TrustBar({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final items = <({IconData icon, String label})>[
      (
        icon: Icons.local_shipping_outlined,
        label:
            'Free shipping over ${config.currencySymbol}${Pricing.freeShippingThreshold}',
      ),
      (
        icon: Icons.receipt_long_outlined,
        label: 'GST ${(Pricing.gstRate * 100).round()}% included at checkout',
      ),
      (icon: Icons.explore_outlined, label: 'Live order tracking'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: config.accentColor,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: config.primaryColor.withValues(alpha: 0.16)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 640;
          if (wide) {
            return Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 1,
                      height: 28,
                      color: config.primaryColor.withValues(alpha: 0.18),
                    ),
                  Expanded(
                    child: _TrustItem(
                      item: items[i],
                      color: config.primaryColor,
                    ),
                  ),
                ],
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in items) ...[
                _TrustItem(item: item, color: config.primaryColor),
                if (item != items.last) const SizedBox(height: AppSpacing.xs),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  final ({IconData icon, String label}) item;
  final Color color;

  const _TrustItem({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(item.icon, size: 15, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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

  const ProductRail({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final width = Responsive.isDesktop(context) ? 250.0 : 188.0;

    return SizedBox(
      height: Responsive.isDesktop(context) ? 416 : 326,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: width,
            child: ProductCard(
              product: product,
              primaryColor: config.primaryColor,
              accentColor: config.accentColor,
              currency: config.currencySymbol,
              showRating: !config.rules.showPrices,
              showPrice: config.rules.showPrices,
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
        ProductRail(products: newest),
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

  static String _group(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    if (!config.rules.showPrices) return const SizedBox.shrink();

    final symbol = config.currencySymbol;
    final labels = [
      'Under $symbol${_group(bands[0].max!)}',
      '$symbol${_group(bands[1].min!)} – $symbol${_group(bands[1].max!)}',
      '$symbol${_group(bands[2].min!)} – $symbol${_group(bands[2].max!)}',
      '$symbol${_group(bands[3].min!)} & above',
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

/// "Our Promise" grid: every card is backed by something the app does.
class PromiseGrid extends StatelessWidget {
  const PromiseGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final symbol = config.currencySymbol;

    final items = <({IconData icon, String title, String detail})>[
      (
        icon: Icons.local_shipping_outlined,
        title: 'Free shipping',
        detail: 'On orders over $symbol${Pricing.freeShippingThreshold}',
      ),
      (
        icon: Icons.receipt_long_outlined,
        title: 'GST included',
        detail: '${(Pricing.gstRate * 100).round()}% factored into every total',
      ),
      (
        icon: Icons.explore_outlined,
        title: 'Live tracking',
        detail: 'Follow each status change under Orders',
      ),
      (
        icon: Icons.lock_person_outlined,
        title: 'Verified sign-in',
        detail: 'OTP protected account on this device',
      ),
      (
        icon: Icons.storefront_outlined,
        title: 'Seller direct',
        detail: 'Dispatched by the shop that listed it',
      ),
      config.rules.showPrices
          ? (
              icon: Icons.sell_outlined,
              title: 'Transparent pricing',
              detail: 'The tag price is the checkout price',
            )
          : (
              icon: Icons.chat_outlined,
              title: 'Enquiry pricing',
              detail: 'Ask the shop for your trade rate',
            ),
    ];

    final crossAxis = Responsive.isDesktop(context) ? 3 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: SectionHeader(title: 'Our Promise', padding: EdgeInsets.zero),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: GridView.count(
            crossAxisCount: crossAxis,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: crossAxis == 3 ? 2.4 : 1.55,
            children: [
              for (final item in items)
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(item.icon, size: 18, color: config.primaryColor),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: AppPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
