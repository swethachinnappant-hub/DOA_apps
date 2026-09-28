import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/material.dart';

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
    this.background = const Color(0xFF111827),
    this.foreground = Colors.white,
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
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            liked ? Icons.favorite : Icons.favorite_border,
            size: 16,
            color: liked ? activeColor : AppPalette.textSecondary,
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

  /// Cards are compact inside dense grids; set false for a roomier rail.
  final bool showRating;
  final bool showDelivery;

  /// Mirrors the business rule. When false the card shows a "Contact for
  /// Price" prompt instead of any figures.
  final bool showPrice;

  /// Starts the product photo carousel after its normal interval. Used on the
  /// Home rails so shoppers can preview the available product views in place.
  final bool autoSlideImages;

  const ProductCard({
    super.key,
    required this.product,
    required this.primaryColor,
    required this.accentColor,
    this.currency = '₹',
    this.onTap,
    this.onWishlist,
    this.liked,
    this.showRating = true,
    this.showDelivery = false,
    this.showPrice = true,
    this.autoSlideImages = true,
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
      placeholderIcon: widget.product.icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final liked = widget.liked ?? _liked;

    return Material(
      color: AppPalette.surface,
      borderRadius: AppRadius.allLg,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: AppRadius.allLg,
        child: Ink(
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: AppRadius.allLg,
            border: Border.all(color: AppPalette.border),
            boxShadow: AppShadows.subtle,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(7, 7, 7, 0),
                  child: ClipRRect(
                    borderRadius: AppRadius.allMd,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ProductImageCarousel(
                          key: _carouselKey,
                          images: p.images,
                          placeholderIcon: p.icon,
                          placeholderColor: widget.accentColor,
                          placeholderAccent: widget.primaryColor,
                          autoSlide: widget.autoSlideImages,
                          showDots: p.hasMultipleImages,
                          showCounter: p.hasMultipleImages,
                          borderRadius: AppRadius.allMd,
                          onImageTap: p.images.isEmpty
                              ? null
                              : _zoomCurrentImage,
                        ),
                        if (p.badges.isNotEmpty)
                          Positioned(
                            left: AppSpacing.sm,
                            top: AppSpacing.sm,
                            child: ProductBadge(
                              label: p.badges.first,
                              background: Colors.white.withValues(alpha: .94),
                              foreground: AppPalette.textPrimary,
                            ),
                          ),
                        if (p.hasDiscount && widget.showPrice)
                          Positioned(
                            left: AppSpacing.sm,
                            bottom: AppSpacing.sm,
                            child: ProductBadge(
                              label: '${p.discountPercent}% off',
                              background: widget.primaryColor,
                              foreground: Colors.white,
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
                            top: 42,
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
                        if (!p.inStock)
                          Positioned.fill(
                            child: ColoredBox(
                              color: Colors.white.withValues(alpha: 0.72),
                              child: const Center(
                                child: ProductBadge(
                                  label: 'Out of stock',
                                  background: AppPalette.textPrimary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
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
                    const SizedBox(height: 2),
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
                            child: Text(
                              Pricing.money(
                                p.price,
                                currencySymbol: widget.currency,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.price.copyWith(fontSize: 16),
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
                    if (widget.showRating || widget.showDelivery) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          if (widget.showRating)
                            RatingChip(
                              rating: p.rating,
                              reviewCount: p.reviewCount,
                              compact: false,
                            ),
                          if (widget.showDelivery) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                p.deliveryLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10.5,
                                  color: AppPalette.textHint,
                                ),
                              ),
                            ),
                          ],
                        ],
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
