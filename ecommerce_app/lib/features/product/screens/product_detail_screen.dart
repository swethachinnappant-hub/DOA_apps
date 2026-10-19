import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/business_config.dart';
import '../../../core/models/notification.dart';
import '../../../core/pricing.dart';
import '../../../core/product.dart';
import '../../../core/store/commerce_store.dart';
import '../../config/providers/business_config_provider.dart';
import '../../home/home_sections.dart';
import '../../mini_cart/mini_cart_drawer.dart';
import '../../../widgets/product_card.dart';

/// Product detail page in the Tamannaah mould: gallery with a thumbnail rail,
/// a category breadcrumb, a Product Code plus ship-status line, a short
/// description, expandable Product Details / Delivery sections and a related
/// products rail. The buy bar carries Add to Bag and Buy Now, and gains an
/// "Enquire with the seller" action for listings owned by a real shop.
class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _carouselKey = GlobalKey<ProductImageCarouselState>();
  String? _selectedSize;
  String? _selectedShade;
  int? _selectedKarat;
  int _activeImage = 0;

  @override
  void initState() {
    super.initState();
    final store = context.read<CommerceStore>();
    store.recordView(widget.productId);
    final product = store.productById(widget.productId);
    final baseKarat = Pricing.karatOf(product?.specs['Gold Purity'] ?? '');
    if (baseKarat != null) _selectedKarat = baseKarat;
  }

  int? _baseKarat(Product product) =>
      Pricing.karatOf(product.specs['Gold Purity'] ?? '');

  double _factor(Product product) => Pricing.variantFactor(
    shade: _selectedShade,
    baseKarat: _baseKarat(product),
    purity: _selectedKarat,
  );

  int _priceOf(Product product) =>
      Pricing.scaled(product.price, _factor(product));

  int _mrpOf(Product product) => Pricing.scaled(product.mrp, _factor(product));

  PriceBreakup _breakupOf(Product product) =>
      Pricing.computeBreakup(_priceOf(product), specs: product.specs);

  /// The CTA names whatever is still missing, and only offers "Add to Bag"
  /// once every required variant has been chosen.
  String _ctaLabel(Product product) {
    if (product.shades.isNotEmpty && _selectedShade == null) {
      return 'Select Shade';
    }
    if (product.sizes.isNotEmpty && _selectedSize == null) {
      return 'Select Size';
    }
    return 'Add to Bag';
  }

  /// The listing's SKU with the chosen variant appended, so the code on the
  /// page follows the metal and purity the shopper selects.
  String _variantSku(Product product) {
    final parts = <String>[product.sku];
    if (_selectedShade != null) {
      final initials = _selectedShade!
          .split(RegExp(r'\s+'))
          .map((word) => word.isEmpty ? '' : word[0].toUpperCase())
          .join();
      if (initials.isNotEmpty) parts.add(initials);
    }
    final base = _baseKarat(product);
    if (_selectedKarat != null && base != null && _selectedKarat != base) {
      parts.add('${_selectedKarat}K');
    }
    return parts.join('-');
  }

  /// Demo listings carry one photo set, so the selected metal tone cycles the
  /// available angles: picking a different tone lands on a different lead
  /// image the way a photographed variant would.
  List<String> _galleryImages(Product product) {
    final images = product.images;
    if (images.length < 2) return images;
    final offset = product.shades.indexWhere(
      (shade) => shade.name == _selectedShade,
    );
    if (offset <= 0) return images;
    final cut = offset % images.length;
    return [...images.sublist(cut), ...images.sublist(0, cut)];
  }

  List<int> _purityOptions(int baseKarat) =>
      (Pricing.purityKarats.toSet()..add(baseKarat)).toList()..sort();

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final product = store.productById(widget.productId);

    if (product == null) return _notFound(context, config);

    final liked = store.isWishlisted(product.id);
    final ctaLabel = _ctaLabel(product);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.brand, style: AppTypography.subtitle),
        actions: [
          IconButton(
            tooltip: liked ? 'Remove from wishlist' : 'Add to wishlist',
            icon: Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              color: liked ? AppPalette.error : null,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              store.toggleWishlist(product.id);
            },
          ),
        ],
      ),
      // The wireframe keeps the sticky bar on compact layouts and moves the
      // CTAs into the right-hand column on desktop.
      bottomNavigationBar: Responsive.isDesktop(context)
          ? null
          : _BuyBar(
              primaryColor: config.primaryColor,
              onPrimaryColor: config.onPrimaryColor,
              ctaLabel: ctaLabel,
              enabled: product.inStock,
              // Enquiries are a real seller channel, so only listings that
              // belong to an account on this device get the button.
              onEnquire: product.ownerId.isEmpty
                  ? null
                  : () => _enquire(config, product),
              onAddToBag: () => _add(context, buyNow: false),
              onBuyNow: () => _add(context, buyNow: true),
            ),
      body: Responsive.isDesktop(context)
          ? _wideLayout(context, config, product)
          : _mobileLayout(context, config, product),
    );
  }

  /// Puts the configured product in the shared bag and moves the shopper on,
  /// so the count in the header and the cart screen agree immediately.
  void _add(BuildContext context, {required bool buyNow}) {
    final store = context.read<CommerceStore>();
    final product = store.productById(widget.productId);
    if (product == null) return;

    if (product.shades.isNotEmpty && _selectedShade == null) {
      _requireVariant(context, 'Select a shade');
      return;
    }
    if (product.sizes.isNotEmpty && _selectedSize == null) {
      _requireVariant(context, 'Select a size');
      return;
    }

    final added = store.addToCart(
      product,
      selectedSize: _selectedSize,
      selectedShade: _selectedShade,
    );

    if (added <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the stock on hand can be added to the bag'),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();

    if (buyNow) {
      context.push('/checkout');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checkout ready'),
            duration: Duration(milliseconds: 1400),
          ),
        );
      }
      return;
    }

    if (Responsive.isMobile(context)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to bag'),
            duration: Duration(milliseconds: 1400),
          ),
        );
      }
    } else {
      showMiniCart(context);
    }
  }

  /// Surfaces which variant is still missing when the CTA is tapped early.
  void _requireVariant(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }

  /// Opens the enquiry sheet and, on send, drops a notification straight into
  /// the inbox of the account that listed the product. The message is written
  /// by the shopper, so the shop sees the question and the piece together.
  Future<void> _enquire(BusinessConfig config, Product product) async {
    if (product.ownerId.isEmpty) return;
    final store = context.read<CommerceStore>();
    final controller = TextEditingController();

    await AppDialog.show<void>(
      context,
      title: 'Enquire about ${product.name}',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your message goes straight to the shop listing this piece.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            minLines: 3,
            decoration: const InputDecoration(
              hintText: 'Ask about size, finish, delivery or price',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        DialogAction(
          label: 'Cancel',
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).maybePop(),
        ),
        DialogAction(
          label: 'Send Enquiry',
          color: config.primaryColor,
          onPressed: () {
            final message = controller.text.trim();
            if (message.isEmpty) return;
            store.pushNotification(
              AppNotification(
                id: 'ntf-enq-${DateTime.now().microsecondsSinceEpoch}',
                type: NotificationType.enquiry,
                title: 'Enquiry: ${product.name}',
                body: message,
                audienceId: product.ownerId,
                route: '/owner/products/${product.id}',
                createdAt: DateTime.now(),
              ),
            );
            Navigator.of(context, rootNavigator: true).maybePop();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enquiry sent to the shop'),
                  duration: Duration(milliseconds: 1600),
                ),
              );
            }
          },
        ),
      ],
    );
    controller.dispose();
  }

  /// Fills the configured spec labels with values the listing actually
  /// carries. Labels nothing can be resolved for are dropped rather than
  /// filled with a placeholder, and if nothing resolves the section falls
  /// back to the facts every product has.
  ///
  /// The jewellery weight and purity rows are skipped: they are shown by the
  /// dedicated Gold / Diamond / Price Breakup accordions further down.
  static List<(String, String)> _detailRows(
    BusinessConfig config,
    Product product,
  ) {
    const dedicatedToOtherAccordions = {
      'Gold Purity',
      'Gross Weight',
      'Net Weight',
      'Stone Weight',
      'Making Charge',
      'Wastage',
    };

    final shades = product.shades.map((s) => s.name).join(', ');
    final sizes = product.sizes.map((s) => s.name).join(', ');

    String? resolve(String field) {
      // The seller's own specification rows win over anything derived.
      final provided = product.specs[field];
      if (provided != null && provided.trim().isNotEmpty) {
        return provided.trim();
      }
      switch (field) {
        case 'Brand':
          return product.brand;
        case 'Color':
        case 'Shade':
          return shades.isEmpty ? null : shades;
        case 'Size':
          return sizes.isEmpty ? null : sizes;
        case 'SKU':
        case 'Model':
          return product.sku;
        case 'Category':
        case 'Type':
          return product.category;
        case 'MRP':
          return Pricing.money(
            product.mrp,
            currencySymbol: config.currencySymbol,
          );
        case 'Pattern':
        case 'Style':
          return product.badges.isEmpty ? null : product.badges.first;
        default:
          return null;
      }
    }

    final rows = <(String, String)>[];
    for (final field in config.productFields) {
      if (dedicatedToOtherAccordions.contains(field)) continue;
      final value = resolve(field);
      if (value != null && value.isNotEmpty) rows.add((field, value));
    }

    if (rows.isNotEmpty) return rows;
    return [
      ('Brand', product.brand),
      ('SKU', product.sku),
      ('Category', product.category),
      ('Delivery', product.deliveryLabel),
    ];
  }

  Widget _notFound(BuildContext context, BusinessConfig config) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 44,
                color: AppPalette.textHint,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Product unavailable', style: AppTypography.subtitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'This item may have been removed or is no longer stocked.',
                textAlign: TextAlign.center,
                style: AppTypography.caption,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: 'Browse catalogue',
                type: AppButtonType.outlined,
                onPressed: () => context.push('/catalogue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gallery(
    BuildContext context,
    BusinessConfig config,
    Product product, {
    double? height,
  }) {
    final images = _galleryImages(product);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height ?? 380,
          width: double.infinity,
          child: ProductImageCarousel(
            key: _carouselKey,
            images: images,
            placeholderIcon: product.icon,
            placeholderColor: config.accentColor,
            placeholderAccent: config.primaryColor,
            autoSlide: true,
            showDots: product.hasMultipleImages,
            showCounter: product.hasMultipleImages,
            onImageTap: () => showImageViewer(
              context,
              url: images.isEmpty ? '' : images[_activeImage],
              images: images,
              initialIndex: _activeImage,
              placeholderIcon: product.icon,
            ),
            // Keep the thumbnail rail in sync when the shopper swipes
            // directly on the main gallery.
            onPageChanged: (i) => setState(() => _activeImage = i),
            onZoomRequested: () => showImageViewer(
              context,
              url: images.isEmpty ? '' : images[_activeImage],
              images: images,
              initialIndex: _activeImage,
              placeholderIcon: product.icon,
            ),
          ),
        ),
        if (product.hasMultipleImages) ...[
          const SizedBox(height: AppSpacing.sm),
          ProductThumbnailRail(
            images: images,
            activeIndex: _activeImage,
            placeholderIcon: product.icon,
            placeholderAccent: config.primaryColor,
            onSelected: (i) {
              setState(() => _activeImage = i);
              _carouselKey.currentState?.goTo(i);
            },
          ),
        ],
      ],
    );
  }

  Widget _mobileLayout(
    BuildContext context,
    BusinessConfig config,
    Product product,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _gallery(context, config, product, height: 420),
          _info(context, config, product),
          _rails(context, product),
        ],
      ),
    );
  }

  Widget _wideLayout(
    BuildContext context,
    BusinessConfig config,
    Product product,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _gallery(context, config, product, height: 460),
                if (config.rules.showWatermark)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenH),
                    child: Text(
                      config.name.toUpperCase(),
                      style: AppTypography.overline.copyWith(
                        color: AppPalette.textHint,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info(context, config, product),
                _rails(context, product),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Today's board line under the price — the same gold/silver per-gram
  /// numbers the shell's rate strip boards, so the shopper sees what the
  /// price is linked to (SPEC-19 dynamic pricing). Only shows when the
  /// owner has turned on the `showMetalRates` business rule.
  Widget _rateUnderPrice(BuildContext context) {
    final showRates = context
        .watch<BusinessConfigProvider>()
        .config
        .rules
        .showMetalRates;
    if (!showRates) return const SizedBox.shrink();
    final store = context.watch<CommerceStore>();
    final parts = <String>[
      if (store.goldRateInrPerGram != null)
        'Gold ${Pricing.money(store.goldRateInrPerGram!)}/g',
      if (store.silverRateInrPerGram != null)
        'Silver ${Pricing.money(store.silverRateInrPerGram!)}/g',
      if (store.platinumRateInrPerGram != null)
        'Platinum ${Pricing.money(store.platinumRateInrPerGram!)}/g',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        'Today\u2019s rate: ${parts.join(' · ')}',
        style: AppTypography.caption.copyWith(color: AppPalette.textSecondary),
      ),
    );
  }

  Widget _info(BuildContext context, BusinessConfig config, Product product) {
    final rules = config.rules;

    return Padding(
      padding: Responsive.padding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _breadcrumb(context, product),
          const SizedBox(height: AppSpacing.xs),
          Text(
            product.brand.toUpperCase(),
            style: AppTypography.overline.copyWith(
              letterSpacing: 0.8,
              color: AppPalette.textHint,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(product.name, style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              RatingChip(
                rating: product.rating,
                reviewCount: product.reviewCount,
                compact: false,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${product.reviewCount} ratings',
                style: AppTypography.caption.copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (rules.showPrices)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wrap rather than Row so a long price plus the discount
                // badge flows onto a second line instead of overflowing at
                // 320px.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Text(
                      Pricing.money(
                        _priceOf(product),
                        currencySymbol: config.currencySymbol,
                      ),
                      style: AppTypography.display.copyWith(fontSize: 26),
                    ),
                    if (_mrpOf(product) > _priceOf(product)) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          Pricing.money(
                            _mrpOf(product),
                            currencySymbol: config.currencySymbol,
                          ),
                          style: AppTypography.priceStrike.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: ProductBadge(
                          label: '${product.discountPercent}% off',
                          background: AppPalette.goldLight,
                          foreground: AppPalette.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '(Inclusive of all taxes)',
                  style: AppTypography.caption.copyWith(
                    color: AppPalette.textMuted,
                  ),
                ),
                _rateUnderPrice(context),
              ],
            )
          else
            Text(
              'Contact for Price',
              style: AppTypography.title.copyWith(color: config.primaryColor),
            ),
          const SizedBox(height: AppSpacing.sm),
          // Tamannaah's product code + ship status line. The code carries the
          // chosen variant so it changes with the selections.
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                'Product Code: ${_variantSku(product)}',
                style: AppTypography.caption.copyWith(
                  color: AppPalette.textSecondary,
                ),
              ),
              ProductBadge(
                label: _shipStatus(product),
                background: product.inStock
                    ? AppPalette.success
                    : AppPalette.error,
              ),
            ],
          ),
          if (product.hasDescription) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              product.description.trim(),
              style: AppTypography.body.copyWith(fontSize: 14),
            ),
          ],
          if (product.shades.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(
              'Metal',
              trailing: _selectedShade ?? 'Select a shade',
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: product.shades
                  .map(
                    (s) => _ShadeSwatch(
                      shade: s,
                      selected: _selectedShade == s.name,
                      onTap: () {
                        setState(() {
                          _selectedShade = s.name;
                          _activeImage = 0;
                        });
                        _carouselKey.currentState?.goTo(0);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
          if (_baseKarat(product) != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(
              'Purity',
              trailing: '${_selectedKarat ?? _baseKarat(product)}K',
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _purityOptions(_baseKarat(product)!)
                  .map(
                    (karat) => _SizeChip(
                      label: '${karat}K',
                      selected: _selectedKarat == karat,
                      onTap: () => setState(() => _selectedKarat = karat),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (product.sizes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel('Size', trailing: _selectedSize ?? 'Select a size'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: product.sizes
                  .map(
                    (s) => _SizeChip(
                      label: s.name,
                      selected: _selectedSize == s.name,
                      onTap: () => setState(() => _selectedSize = s.name),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (!product.inStock)
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppPalette.error.withValues(alpha: 0.08),
                borderRadius: AppRadius.allSm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                    color: AppPalette.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Out of stock. Notify me when available',
                      style: AppTypography.caption.copyWith(
                        color: AppPalette.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          _PincodeCheck(
            deliveryDays: product.deliveryDays,
            accent: config.primaryColor,
          ),
          if (Responsive.isDesktop(context)) ...[
            const SizedBox(height: AppSpacing.lg),
            if (product.ownerId.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Enquire with the seller',
                  type: AppButtonType.outlined,
                  onPressed: () => _enquire(config, product),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: _ctaLabel(product),
                color: config.primaryColor,
                textColor: config.onPrimaryColor,
                onPressed: product.inStock
                    ? () => _add(context, buyNow: false)
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Buy Now',
                type: AppButtonType.outlined,
                onPressed: product.inStock
                    ? () => _add(context, buyNow: true)
                    : null,
              ),
            ),
            if (config.rules.coupons) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'OFFERS',
                style: AppTypography.eyebrow.copyWith(
                  color: AppPalette.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _offerChips(context, config),
            ],
            const SizedBox(height: AppSpacing.lg),
            _trustRow(config),
          ],
          const SizedBox(height: AppSpacing.xl),
          _SectionAccordion(
            title: 'Product Details',
            accent: config.primaryColor,
            initiallyExpanded: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final row in _detailRows(config, product))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(row.$1, style: AppTypography.caption),
                        ),
                        Expanded(
                          child: Text(
                            row.$2,
                            style: AppTypography.body.copyWith(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (rules.showPrices)
            _SectionAccordion(
              title: 'Price Breakup',
              accent: config.primaryColor,
              child: _breakupTable(config, product),
            ),
          if (_diamondRows(product).isNotEmpty)
            _SectionAccordion(
              title: 'Diamond Details',
              accent: config.primaryColor,
              child: _specTable(_diamondRows(product)),
            ),
          if (_specRows(product, _goldSpecFields).isNotEmpty)
            _SectionAccordion(
              title: 'Gold Details',
              accent: config.primaryColor,
              child: _specTable(_specRows(product, _goldSpecFields)),
            ),
          _SectionAccordion(
            title: 'Shipping & Returns',
            accent: config.primaryColor,
            child: _deliveryDetails(config, rules, product),
          ),
          _SectionAccordion(
            title: 'Care',
            accent: config.primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final line in const [
                  'Store it in the supplied box, away from moisture',
                  'Remove it before perfume, lotion and swimming',
                  'Wipe with a soft dry cloth after every wear',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5, right: 6),
                          child: Icon(
                            Icons.check,
                            size: 13,
                            color: config.primaryColor,
                          ),
                        ),
                        Expanded(child: Text(line, style: AppTypography.bodyMuted)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (product.highlights.isNotEmpty)
            _SectionAccordion(
              title: 'Highlights',
              accent: config.primaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: product.highlights
                    .map(
                      (h) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 5, right: 6),
                              child: Icon(
                                Icons.check,
                                size: 13,
                                color: config.primaryColor,
                              ),
                            ),
                            Expanded(
                              child: Text(h, style: AppTypography.bodyMuted),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (rules.showContactInfo)
            _SectionAccordion(
              title: 'Contact Seller',
              accent: config.primaryColor,
              child: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ContactRow(
                      icon: Icons.store_outlined,
                      text: config.name,
                      color: config.primaryColor,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ContactRow(
                      icon: Icons.chat_bubble_outline,
                      text: product.ownerId.isEmpty
                          ? 'Chat with support'
                          : 'Chat with the seller',
                      color: config.primaryColor,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ContactRow(
                      icon: Icons.local_shipping_outlined,
                      text: product.deliveryLabel,
                      color: config.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          if (!rules.allowDownload)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 15,
                    color: AppPalette.textHint,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Download protected', style: AppTypography.caption),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Tamannaah-style ship status that answers "when does this leave?".
  static String _shipStatus(Product product) {
    if (!product.inStock) return 'Out of stock';
    if (product.deliveryDays <= 0) return 'Ready to ship';
    return 'Ships in ${product.deliveryDays} days';
  }

  /// The Delivery accordion: timing, the shipping threshold the checkout
  /// actually charges, GST and the real minimum order quantity.
  Widget _deliveryDetails(
    BusinessConfig config,
    BusinessRules rules,
    Product product,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _factRow(
          icon: Icons.local_shipping_outlined,
          text: product.deliveryLabel,
          color: config.primaryColor,
        ),
        const SizedBox(height: AppSpacing.sm),
        _factRow(
          icon: Icons.local_mall_outlined,
          text:
              'Free shipping on orders of ${Pricing.money(Pricing.freeShippingThreshold, currencySymbol: config.currencySymbol)} or more, otherwise ${Pricing.money(Pricing.standardShipping, currencySymbol: config.currencySymbol)}',
          color: config.primaryColor,
        ),
        const SizedBox(height: AppSpacing.sm),
        _factRow(
          icon: Icons.receipt_long_outlined,
          text: 'GST of ${Pricing.gstRate * 100}% is included at checkout',
          color: config.primaryColor,
        ),
        const SizedBox(height: AppSpacing.sm),
        _factRow(
          icon: Icons.swap_horiz_outlined,
          text: 'Returns and exchanges run through the Ease Returns policy',
          color: config.primaryColor,
        ),
        if (rules.showMOQ) ...[
          const SizedBox(height: AppSpacing.sm),
          _factRow(
            icon: Icons.numbers_outlined,
            text: 'MOQ 1 unit',
            color: config.primaryColor,
          ),
        ],
      ],
    );
  }

  static const List<String> _goldSpecFields = [
    'Gold Purity',
    'Gross Weight',
    'Net Weight',
    'Making Charge',
    'Wastage',
  ];

  static List<(String, String)> _specRows(
    Product product,
    List<String> fields,
  ) {
    final rows = <(String, String)>[];
    for (final field in fields) {
      final value = (product.specs[field] ?? '').trim();
      if (value.isNotEmpty) rows.add((field, value));
    }
    return rows;
  }

  /// Diamond facts only appear for pieces that actually carry stones, with
  /// the carat figure derived from the declared stone weight.
  static List<(String, String)> _diamondRows(Product product) {
    final rows = _specRows(product, const ['Stone Weight']);
    final stoneGrams = Pricing.gramsOf(product.specs['Stone Weight']);
    if (rows.isEmpty || stoneGrams <= 0) return const [];
    final carats = stoneGrams * 5;
    return [...rows, ('Carat (approx)', '${carats.toStringAsFixed(2)} ct')];
  }

  Widget _specTable(List<(String, String)> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(row.$1, style: AppTypography.caption),
                ),
                Expanded(
                  child: Text(
                    row.$2,
                    style: AppTypography.body.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// The breakup table: every row derives from the price the selected
  /// variant currently shows, and the rows add back up to it exactly.
  Widget _breakupTable(BusinessConfig config, Product product) {
    final breakup = _breakupOf(product);

    Widget row(String label, int value, {bool emphasised = false}) {
      final labelStyle = emphasised
          ? AppTypography.sectionTitle
          : AppTypography.body.copyWith(fontSize: 13.5);
      final valueStyle = emphasised
          ? AppTypography.subtitle
          : AppTypography.body.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            );
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(child: Text(label, style: labelStyle)),
            Text(
              Pricing.money(value, currencySymbol: config.currencySymbol),
              style: valueStyle,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        row('Gold value', breakup.gold),
        row('Diamond value', breakup.diamond),
        row('Making charges', breakup.making),
        row('GST (${(Pricing.gstRate * 100).round()}%)', breakup.gst),
        const Divider(height: AppSpacing.lg),
        row('Total', breakup.total, emphasised: true),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Calculated for the selected variant.',
          style: AppTypography.caption.copyWith(color: AppPalette.textMuted),
        ),
      ],
    );
  }

  /// Offer chips for every live coupon; tapping one opens the mini cart
  /// where the code can actually be applied.
  Widget _offerChips(BuildContext context, BusinessConfig config) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final coupon in context.watch<CommerceStore>().coupons)
          if (coupon.isLive)
            InkWell(
              onTap: () => showMiniCart(context),
              borderRadius: AppRadius.allPill,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.surfaceMuted,
                  borderRadius: AppRadius.allPill,
                  border: Border.all(color: AppPalette.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_offer_outlined,
                      size: 13,
                      color: AppPalette.copperDark,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Flat ${Pricing.money(coupon.flatOffInr, currencySymbol: config.currencySymbol)} off above ${Pricing.money(coupon.minSubtotal, currencySymbol: config.currencySymbol)}',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  /// The three promises the top strip makes, repeated beside the CTAs.
  Widget _trustRow(BusinessConfig config) {
    Widget item(IconData icon, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: config.primaryColor),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.caption),
      ],
    );

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: [
        item(Icons.local_shipping_outlined, 'Free Shipping'),
        item(Icons.swap_horiz, 'Ease Returns'),
        item(Icons.history, 'Lifetime Buyback'),
      ],
    );
  }

  Widget _factRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.caption.copyWith(
              color: AppPalette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  /// Category breadcrumb: Home, then the product's own category.
  Widget _breadcrumb(BuildContext context, Product product) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: AppSpacing.xxs,
      children: [
        InkWell(
          onTap: () => context.go('/app'),
          child: Text('Home', style: AppTypography.caption),
        ),
        Text(
          '/',
          style: AppTypography.caption.copyWith(color: AppPalette.textHint),
        ),
        InkWell(
          onTap: () =>
              context.push(catalogueLocation(category: product.category)),
          child: Text(
            product.category,
            style: AppTypography.caption.copyWith(
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  /// The three rails under the detail page: related pieces first, then what
  /// the shopper looked at before, then other categories that complete the
  /// outfit. Rails with nothing to show are dropped.
  Widget _rails(BuildContext context, Product product) {
    final store = context.watch<CommerceStore>();
    final all = store.shopProducts;
    final sameCategory = all
        .where((p) => p.id != product.id && p.category == product.category)
        .take(8)
        .toList();
    final related = sameCategory.isNotEmpty
        ? sameCategory
        : all.where((p) => p.id != product.id).take(8).toList();
    final viewed = store.recentlyViewed
        .where((p) => p.id != product.id)
        .take(8)
        .toList();
    final complete = all
        .where((p) => p.id != product.id && p.category != product.category)
        .take(8)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (related.isNotEmpty) _rail('You may also like', related),
        if (viewed.isNotEmpty) _rail('Recently viewed', viewed),
        if (complete.isNotEmpty) _rail('Complete the look', complete),
      ],
    );
  }

  Widget _rail(String title, List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: SectionHeader(title: title, padding: EdgeInsets.zero),
        ),
        const SizedBox(height: AppSpacing.md),
        ProductRail(products: products),
      ],
    );
  }
}

/// Tap-to-expand section used for Product Details, Delivery, Highlights and
/// Contact Seller, matching the reference page's accordion stack.
class _SectionAccordion extends StatefulWidget {
  final String title;
  final Color accent;
  final bool initiallyExpanded;
  final Widget child;

  const _SectionAccordion({
    required this.title,
    required this.accent,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<_SectionAccordion> createState() => _SectionAccordionState();
}

class _SectionAccordionState extends State<_SectionAccordion> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.title, style: AppTypography.sectionTitle),
                ),
                Icon(
                  _open ? Icons.remove : Icons.add,
                  size: 18,
                  color: widget.accent,
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: widget.child,
          ),
      ],
    );
  }
}

class _BuyBar extends StatelessWidget {
  final Color primaryColor;
  final Color onPrimaryColor;
  final String ctaLabel;
  final bool enabled;
  final VoidCallback? onEnquire;
  final VoidCallback onAddToBag;
  final VoidCallback onBuyNow;

  const _BuyBar({
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.ctaLabel,
    required this.enabled,
    this.onEnquire,
    required this.onAddToBag,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppPalette.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEnquire != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Enquire with the seller',
                    type: AppButtonType.outlined,
                    onPressed: onEnquire,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: ctaLabel,
                      color: primaryColor,
                      textColor: onPrimaryColor,
                      onPressed: enabled ? onAddToBag : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      text: 'Buy Now',
                      type: AppButtonType.outlined,
                      onPressed: enabled ? onBuyNow : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String trailing;

  const _SectionLabel(this.title, {required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.subtitle),
        Text(trailing, style: AppTypography.caption),
      ],
    );
  }
}

class _ShadeSwatch extends StatelessWidget {
  final ProductVariant shade;
  final bool selected;
  final VoidCallback onTap;

  const _ShadeSwatch({
    required this.shade,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: AppDurations.fast,
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: shade.swatch,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : AppPalette.border,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, size: 15, color: Colors.white)
                : null,
          ),
          const SizedBox(height: AppSpacing.xxs),
          SizedBox(
            width: 62,
            child: Text(
              shade.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SizeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          borderRadius: AppRadius.allPill,
          border: Border.all(color: selected ? primary : AppPalette.border),
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color: selected ? Colors.white : AppPalette.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _ContactRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body.copyWith(fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Pincode delivery check: a six-digit answer gives the date the piece
/// arrives; anything else is called out inline.
class _PincodeCheck extends StatefulWidget {
  final int deliveryDays;
  final Color accent;

  const _PincodeCheck({required this.deliveryDays, required this.accent});

  @override
  State<_PincodeCheck> createState() => _PincodeCheckState();
}

class _PincodeCheckState extends State<_PincodeCheck> {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final _controller = TextEditingController();
  String? _error;
  String? _deliveryBy;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    final value = _controller.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      setState(() {
        _error = 'Enter a 6-digit pincode';
        _deliveryBy = null;
      });
      return;
    }
    final eta = DateTime.now().add(Duration(days: widget.deliveryDays));
    setState(() {
      _error = null;
      _deliveryBy =
          'Delivery by ${_weekdays[eta.weekday - 1]}, ${eta.day} ${_months[eta.month - 1]}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Check delivery', style: AppTypography.subtitle),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _check(),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Enter 6-digit pincode',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton(text: 'Check', onPressed: _check),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _error!,
            style: AppTypography.caption.copyWith(color: AppPalette.error),
          ),
        ],
        if (_deliveryBy != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 15,
                color: widget.accent,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  _deliveryBy!,
                  style: AppTypography.caption.copyWith(
                    color: AppPalette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
