import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/material.dart';

import '../core/product.dart';

/// Compact "N out of 5" trust signal, styled the way Amazon and Myntra show it.
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
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: AppPalette.success,
            borderRadius: AppRadius.allXs,
          ),
          child: Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
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

/// Myntra / Ajio style grid card: dominant auto-rotating image, then brand,
/// name, price with strike-through MRP, discount and rating.
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
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final _carouselKey = GlobalKey<ProductImageCarouselState>();
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final liked = widget.liked ?? _liked;

    return Material(
      color: AppPalette.surface,
      borderRadius: AppRadius.allMd,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: AppRadius.allMd,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.allMd,
            border: Border.all(color: AppPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImageCarousel(
                      key: _carouselKey,
                      images: p.images,
                      placeholderIcon: p.icon,
                      placeholderColor: widget.accentColor,
                      placeholderAccent: widget.primaryColor,
                      autoSlide: true,
                      showDots: p.hasMultipleImages,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.md),
                      ),
                    ),
                    if (p.badges.isNotEmpty)
                      Positioned(
                        left: AppSpacing.xs,
                        top: AppSpacing.xs,
                        child: ProductBadge(
                          label: p.badges.first,
                          background: widget.primaryColor,
                          foreground: Colors.white,
                        ),
                      ),
                    if (p.hasDiscount && widget.showPrice)
                      Positioned(
                        left: AppSpacing.xs,
                        bottom: AppSpacing.xs,
                        child: ProductBadge(
                          label: '${p.discountPercent}% off',
                          background: Colors.white,
                          foreground: widget.primaryColor,
                        ),
                      ),
                    Positioned(
                      right: AppSpacing.xs,
                      top: AppSpacing.xs,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
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
                        color: AppPalette.textHint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontSize: 12.5,
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
                              '${widget.currency}${p.price}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.price.copyWith(fontSize: 14.5),
                            ),
                          ),
                          if (p.hasDiscount) ...[
                            const SizedBox(width: 5),
                            Text(
                              '${widget.currency}${p.mrp}',
                              style: AppTypography.priceStrike.copyWith(fontSize: 11),
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
