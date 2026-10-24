import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/product.dart';
import '../core/pricing.dart';

/// A restrained rating mark that suits a jewellery product tile.
class RatingChip extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final bool compact;

  const RatingChip({
    super.key,
    required this.rating,
    this.reviewCount = 0,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppPalette.surfaceMuted,
            border: Border.all(color: AppPalette.border),
            borderRadius: AppRadius.allSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 12,
                color: AppPalette.goldDark,
              ),
              const SizedBox(width: 2),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (!compact && reviewCount > 0) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            '($reviewCount)',
            style: AppTypography.caption.copyWith(
              fontSize: 10.5,
              color: AppPalette.textHint,
            ),
          ),
        ],
      ],
    );
  }
}

/// Small pill used for Bestseller / New In / discount, as on Ajio and Myntra.
class ProductBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const ProductBadge({
    super.key,
    required this.label,
    this.background = AppPalette.gold,
    this.foreground = AppPalette.onGold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.allXs,
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Wishlist heart that toggles in place.
///
/// §11.5: the icon-only control carries a semantics label and a 44×44 hit
/// area (the visible disc stays small); the toggle ticks haptically (§16.4).
class WishlistButton extends StatelessWidget {
  final bool liked;
  final VoidCallback? onTap;
  final Color activeColor;

  const WishlistButton({
    super.key,
    required this.liked,
    this.onTap,
    this.activeColor = AppPalette.error,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: liked ? 'Remove from wishlist' : 'Add to wishlist',
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 44,
          width: 44,
          child: Center(
            child: Material(
              color: Colors.white.withValues(alpha: 0.94),
              shape: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: liked ? activeColor : AppPalette.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Jewellery tile with a clear product photograph, restrained details and price.
class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onWishlist;

  /// When set the heart is driven entirely by the caller (the shared store),
  /// so a save made here shows up on the wishlist screen and the detail page.
  /// Leave it null for a standalone card that keeps its own state.
  final bool? liked;
  final Color primaryColor;
  final Color accentColor;

  /// Currency symbol from the business config, so every price respects it.
  final String currency;
  final String? badgeOverride;

  /// Cards are compact inside dense grids; set false for a roomier rail.
  /// The card keeps only identity + price + rating — SKU, MOQ, bulk tiers,
  /// stock and added-date lines live on the detail page so the photograph
  /// owns as much of the tile as possible.
  final bool showRating;

  /// Mirrors the business rule. When false the card shows a "Contact for
  /// Price" prompt instead of any figures.
  final bool showPrice;

  /// Starts the product photo carousel after its normal interval. Used on the
  /// Home rails so shoppers can preview the available product views in place.
  final bool autoSlideImages;

  final VoidCallback? onQuickAdd;

  /// Tanishq-style flush tile for the full-bleed catalogue grid: no border,
  /// radius or inset — the photograph runs edge to edge and owns the cell.
  final bool flush;

  const ProductCard({
    super.key,
    required this.product,
    required this.primaryColor,
    required this.accentColor,
    this.currency = '₹',
    this.badgeOverride,
    this.onTap,
    this.onWishlist,
    this.liked,
    this.showRating = true,
    this.showPrice = true,
    this.autoSlideImages = false,
    this.onQuickAdd,
    this.flush = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final _carouselKey = GlobalKey<ProductImageCarouselState>();
  bool _liked = false;

  void _zoomCurrentImage() {
    final images = widget.product.images;
    if (images.isEmpty) return;
    final index = _carouselKey.currentState?.currentIndex ?? 0;
    showImageViewer(
      context,
      url: images[index.clamp(0, images.length - 1).toInt()],
      images: images,
      initialIndex: index.clamp(0, images.length - 1).toInt(),
      placeholderIcon: widget.product.icon,
    );
  }

  /// Photograph, badges, wishlist and stock veil — shared by the flush grid
  /// cell and the bordered/rail card.
  Widget _imageWell() {
    final p = widget.product;
    final liked = widget.liked ?? _liked;
    // The photo runs edge-to-edge: flush cells are square-cornered, bordered
    // cards clip to the card's own rounded top so there is no inset ring of
    // card background between the border and the image.
    final clipRadius = widget.flush
        ? BorderRadius.zero
        : const BorderRadius.vertical(top: Radius.circular(AppRadius.lg));
    return ClipRRect(
      borderRadius: clipRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ProductImageCarousel(
            key: _carouselKey,
            images: p.images,
            placeholderIcon: p.icon,
            placeholderColor: widget.accentColor,
            placeholderAccent: widget.primaryColor,
            // Every layout frame paints edge-to-edge: the card's aspect owns
            // the crop so no letterbox bars of background show between photos.
            fit: BoxFit.cover,
            autoSlide: widget.autoSlideImages,
            showDots: p.hasMultipleImages,
            showCounter: p.hasMultipleImages,
            borderRadius: clipRadius,
          ),
          // §7.48: New Arrival / Best Seller / Sale — a discount with no
          // merchandising badge still earns a "Sale" pill.
          if (widget.badgeOverride != null ||
              p.badges.isNotEmpty ||
              (p.hasDiscount && widget.showPrice))
            Positioned(
              left: AppSpacing.sm,
              top: AppSpacing.sm,
              child: ProductBadge(
                label:
                    widget.badgeOverride ??
                    (p.badges.isNotEmpty ? p.badges.first : 'Sale'),
                background: Colors.white.withValues(alpha: .94),
                foreground: AppPalette.goldDark,
              ),
            ),
          if (p.hasDiscount && widget.showPrice)
            Positioned(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: ProductBadge(
                label: '${p.discountPercent}% off',
                background: AppPalette.gold,
                foreground: AppPalette.onGold,
              ),
            ),
          Positioned(
            right: AppSpacing.sm,
            top: AppSpacing.sm,
            child: WishlistButton(
              liked: liked,
              onTap: () {
                if (widget.liked == null) {
                  setState(() => _liked = !_liked);
                }
                widget.onWishlist?.call();
              },
            ),
          ),
          if (p.images.isNotEmpty)
            Positioned(
              right: AppSpacing.sm,
              top: 56,
              child: Tooltip(
                message: 'Zoom product image',
                child: Material(
                  color: Colors.white.withValues(alpha: .94),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _zoomCurrentImage,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.zoom_in,
                        size: 16,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (!p.isAvailable)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: 0.72),
                child: Center(
                  child: ProductBadge(
                    label: p.inStock ? 'Below minimum order' : 'Out of stock',
                    background: AppPalette.textPrimary,
                    foreground: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Material(
      color: AppPalette.surface,
      borderRadius: widget.flush ? BorderRadius.zero : AppRadius.allLg,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: widget.flush ? BorderRadius.zero : AppRadius.allLg,
        child: Ink(
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: widget.flush ? BorderRadius.zero : AppRadius.allLg,
            border: widget.flush ? null : Border.all(color: AppPalette.border),
            boxShadow: widget.flush ? const [] : AppShadows.subtle,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Edge-to-edge photograph: no inset padding and no letterboxed
              // 3:4 frame — the image consumes the whole card above the copy.
              Expanded(child: _imageWell()),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.brand.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.overline.copyWith(
                        fontSize: 9.5,
                        letterSpacing: 0.7,
                        color: AppPalette.goldDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.subtitle.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppPalette.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (widget.showPrice)
                      Row(
                        children: [
                          Flexible(
                            // §11.5: at 200% text the price line scales down
                            // instead of overflowing the card.
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    Pricing.money(
                                      p.price,
                                      currencySymbol: widget.currency,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.price.copyWith(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (p.hasDiscount) ...[
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                Pricing.money(
                                  p.mrp,
                                  currencySymbol: widget.currency,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.priceStrike.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    else
                      Text(
                        'Contact for Price',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.primaryColor,
                        ),
                      ),
                    if (widget.showRating) ...[
                      const SizedBox(height: AppSpacing.xs),
                      // §11.5: at 200% text the chip scales down instead of
                      // overflowing the card.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: RatingChip(
                          rating: p.rating,
                          reviewCount: p.reviewCount,
                          compact: false,
                        ),
                      ),
                    ],
                    if (widget.onQuickAdd != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: OutlinedButton.icon(
                          onPressed: p.isAvailable ? widget.onQuickAdd : null,
                          icon: Icon(
                            p.needsVariantSelection
                                ? Icons.tune
                                : Icons.add_shopping_cart_outlined,
                            size: 15,
                          ),
                          label: Text(
                            p.needsVariantSelection
                                ? 'Choose options'
                                : 'Quick add',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
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
