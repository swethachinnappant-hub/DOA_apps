import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/business_config.dart';
import '../../../core/models/notification.dart';
import '../../../core/pricing.dart';
import '../../../core/product.dart';
import '../../../core/store/commerce_store.dart';
import '../../config/providers/business_config_provider.dart';
import '../../home/home_sections.dart';
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
  int _activeImage = 0;

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final product = store.productById(widget.productId);

    if (product == null) return _notFound(context, config);

    final liked = store.isWishlisted(product.id);

    // Keep the CTA honest: name whatever is still missing, and only offer
    // "Add to Bag" once every required variant has been chosen.
    final sizeMissing = product.sizes.isNotEmpty && _selectedSize == null;
    final shadeMissing = product.shades.isNotEmpty && _selectedShade == null;
    final ctaLabel = shadeMissing
        ? 'Select Shade'
        : sizeMissing
        ? 'Select Size'
        : 'Add to Bag';

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
            onPressed: () => store.toggleWishlist(product.id),
          ),
        ],
      ),
      bottomNavigationBar: _BuyBar(
        primaryColor: config.primaryColor,
        onPrimaryColor: config.onPrimaryColor,
        ctaLabel: ctaLabel,
        enabled: product.inStock,
        // Enquiries are a real seller channel, so only listings that belong
        // to an account on this device get the button.
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

    context.push(buyNow ? '/checkout' : '/cart');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(buyNow ? 'Checkout ready' : 'Added to bag'),
          duration: const Duration(milliseconds: 1400),
        ),
      );
    }
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
  static List<(String, String)> _detailRows(
    BusinessConfig config,
    Product product,
  ) {
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height ?? 380,
          width: double.infinity,
          child: ProductImageCarousel(
            key: _carouselKey,
            images: product.images,
            placeholderIcon: product.icon,
            placeholderColor: config.accentColor,
            placeholderAccent: config.primaryColor,
            autoSlide: true,
            showDots: product.hasMultipleImages,
            showCounter: product.hasMultipleImages,
            // Keep the thumbnail rail in sync when the shopper swipes
            // directly on the main gallery.
            onPageChanged: (i) => setState(() => _activeImage = i),
            onImageTap: () => showImageViewer(
              context,
              url: product.images.isEmpty ? '' : product.images[_activeImage],
              placeholderIcon: product.icon,
            ),
          ),
        ),
        if (product.hasMultipleImages) ...[
          const SizedBox(height: AppSpacing.sm),
          ProductThumbnailRail(
            images: product.images,
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
          _gallery(context, config, product, height: 360),
          _info(context, config, product),
          _related(context, product),
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
                _related(context, product),
              ],
            ),
          ),
        ),
      ],
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
            // Wrap rather than Row so a long price plus the discount badge
            // flows onto a second line instead of overflowing at 320px.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                Text(
                  Pricing.money(
                    product.price,
                    currencySymbol: config.currencySymbol,
                  ),
                  style: AppTypography.display.copyWith(fontSize: 26),
                ),
                if (product.hasDiscount) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      Pricing.money(
                        product.mrp,
                        currencySymbol: config.currencySymbol,
                      ),
                      style: AppTypography.priceStrike.copyWith(fontSize: 13),
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
            )
          else
            Text(
              'Contact for Price',
              style: AppTypography.title.copyWith(color: config.primaryColor),
            ),
          const SizedBox(height: AppSpacing.sm),
          // Tamannaah's product code + ship status line.
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                'Product Code: ${product.sku}',
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
              'Shades',
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
                      onTap: () => setState(() => _selectedShade = s.name),
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
          _SectionAccordion(
            title: 'Delivery',
            accent: config.primaryColor,
            child: _deliveryDetails(config, rules, product),
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

  /// Related rail: same category first, then the rest of the shop so a
  /// category with a single piece still shows suggestions.
  Widget _related(BuildContext context, Product product) {
    final store = context.watch<CommerceStore>();
    final all = store.shopProducts;
    final sameCategory = all
        .where((p) => p.id != product.id && p.category == product.category)
        .take(8)
        .toList();
    final related = sameCategory.isNotEmpty
        ? sameCategory
        : all.where((p) => p.id != product.id).take(8).toList();
    if (related.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: SectionHeader(
            title: 'You may also like',
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ProductRail(products: related),
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
                      type: AppButtonType.outlined,
                      onPressed: enabled ? onAddToBag : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      text: 'Buy Now',
                      color: primaryColor,
                      textColor: onPrimaryColor,
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
