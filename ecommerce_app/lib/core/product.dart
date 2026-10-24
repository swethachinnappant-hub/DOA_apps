import 'package:flutter/material.dart';

/// A selectable variant such as a size or a shade.
@immutable
class ProductVariant {
  final String name;

  /// When set, the variant is rendered as a colour swatch instead of a chip.
  final Color? swatch;

  const ProductVariant(this.name, {this.swatch});

  bool get isShade => swatch != null;
}

/// Unit price that applies when a wholesale buyer reaches a quantity break.
@immutable
class WholesalePriceTier {
  final int minimumQuantity;
  final int unitPrice;

  const WholesalePriceTier({
    required this.minimumQuantity,
    required this.unitPrice,
  });
}

/// A catalogue product.
///
/// [images] holds every uploaded angle of the product. A single image renders
/// as a plain thumbnail; multiple images drive the auto-advancing carousel in
/// listing cards and the zoomable gallery on the detail page.
@immutable
class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String sku;

  final int price;
  final int mrp;
  final double rating;
  final int reviewCount;

  final List<String> images;
  final List<ProductVariant> sizes;
  final List<ProductVariant> shades;
  final List<String> highlights;
  final List<String> badges;

  /// One-line selling copy shown under the title on the detail page. Empty
  /// means the listing has nothing to say, so nothing is rendered.
  final String description;

  /// Label -> value specification rows, keyed by the business's own
  /// `productFields` (Gold Purity, Gross Weight, ... ). Values the seller
  /// never filled in are simply absent and are never rendered.
  final Map<String, String> specs;

  final bool inStock;
  final int deliveryDays;
  final IconData icon;

  /// Owner who listed this product. Empty means it is seeded platform stock
  /// rather than a seller listing.
  final String ownerId;

  /// Units on hand. Owners edit this; customers never see it directly.
  final int stock;

  /// Smallest quantity a buyer can order. Wholesale listings default to one
  /// until the seller sets a larger pack quantity.
  final int minimumOrderQuantity;
  final List<WholesalePriceTier> wholesalePriceTiers;

  /// When the listing was last changed, used to order "recently added".
  final DateTime? createdAt;

  // -------------------------------------------------- merchandising (SPEC-18)
  // Empty values mean "the seller never chose one" and are never rendered.

  /// URL-friendly identifier for shareable links; falls back to the name.
  final String slug;

  /// Search-engine title; falls back to the name when empty.
  final String seoTitle;

  /// USD price for the dual-currency display, 0 when not set.
  final int priceUsd;

  final String family;
  final String style;
  final String metal;
  final String purity;
  final String audience;
  final List<String> occasions;
  final List<String> collectionIds;

  /// Supplier verification badge (§6.40). Demo platform stock is verified;
  /// owner listings start unverified until the platform vetts them.
  final bool isVerifiedSupplier;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.sku,
    required this.price,
    required this.mrp,
    required this.rating,
    required this.reviewCount,
    required this.images,
    required this.icon,
    this.sizes = const [],
    this.shades = const [],
    this.highlights = const [],
    this.badges = const [],
    this.description = '',
    this.specs = const {},
    this.inStock = true,
    this.deliveryDays = 3,
    this.ownerId = '',
    this.stock = 0,
    this.minimumOrderQuantity = 1,
    this.wholesalePriceTiers = const [],
    this.createdAt,
    this.slug = '',
    this.seoTitle = '',
    this.priceUsd = 0,
    this.family = '',
    this.style = '',
    this.metal = '',
    this.purity = '',
    this.audience = '',
    this.occasions = const [],
    this.collectionIds = const [],
    this.isVerifiedSupplier = false,
  });

  /// Percentage saved off the MRP, e.g. 42 for "42% OFF".
  int get discountPercent =>
      mrp <= 0 ? 0 : (((mrp - price) / mrp) * 100).round();

  bool get hasDiscount => mrp > price;

  bool get hasDescription => description.trim().isNotEmpty;

  bool get hasMultipleImages => images.length > 1;

  /// True when the shopper still has to pick a size or shade, which is when
  /// Nykaa-style listings show "SELECT SHADE" rather than "ADD TO BAG".
  bool get needsVariantSelection => sizes.isNotEmpty || shades.isNotEmpty;

  String get deliveryLabel =>
      deliveryDays <= 0 ? 'Same day delivery' : 'Delivery in $deliveryDays days';

  /// Myntra-style trust line.
  String get priceNote => hasDiscount ? '$discountPercent% OFF' : 'Best price ever';

  /// Shareable path segment: the explicit slug when set, else the name
  /// slugified (lowercase, runs of non-letters collapsed to single dashes).
  String get effectiveSlug {
    if (slug.trim().isNotEmpty) return slug.trim();
    final source = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return source.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  String get effectiveSeoTitle => seoTitle.trim().isNotEmpty ? seoTitle : name;

  /// True when the seller has run out. Seeded listings carry no stock count,
  /// so they fall back to the explicit [inStock] flag.
  bool get isAvailable =>
      inStock &&
      (ownerId.isEmpty || stock >= minimumOrderQuantity);

  /// Low-stock threshold used for the "only N left" nudge on cards.
  bool get isLowStock => ownerId.isNotEmpty && stock > 0 && stock <= 5;

  int unitPriceForQuantity(int quantity) {
    final eligible = wholesalePriceTiers
        .where((tier) => tier.minimumQuantity <= quantity)
        .toList()
      ..sort((a, b) => b.minimumQuantity.compareTo(a.minimumQuantity));
    return eligible.isEmpty ? price : eligible.first.unitPrice;
  }

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    String? category,
    String? sku,
    int? price,
    int? mrp,
    double? rating,
    int? reviewCount,
    List<String>? images,
    IconData? icon,
    List<ProductVariant>? sizes,
    List<ProductVariant>? shades,
    List<String>? highlights,
    List<String>? badges,
    String? description,
    Map<String, String>? specs,
    bool? inStock,
    int? deliveryDays,
    String? ownerId,
    int? stock,
    int? minimumOrderQuantity,
    List<WholesalePriceTier>? wholesalePriceTiers,
    DateTime? createdAt,
    String? slug,
    String? seoTitle,
    int? priceUsd,
    String? family,
    String? style,
    String? metal,
    String? purity,
    String? audience,
    List<String>? occasions,
    List<String>? collectionIds,
    bool? isVerifiedSupplier,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      images: images ?? this.images,
      icon: icon ?? this.icon,
      sizes: sizes ?? this.sizes,
      shades: shades ?? this.shades,
      highlights: highlights ?? this.highlights,
      badges: badges ?? this.badges,
      description: description ?? this.description,
      specs: specs ?? this.specs,
      inStock: inStock ?? this.inStock,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      ownerId: ownerId ?? this.ownerId,
      stock: stock ?? this.stock,
      minimumOrderQuantity: minimumOrderQuantity ?? this.minimumOrderQuantity,
      wholesalePriceTiers: wholesalePriceTiers ?? this.wholesalePriceTiers,
      createdAt: createdAt ?? this.createdAt,
      slug: slug ?? this.slug,
      seoTitle: seoTitle ?? this.seoTitle,
      priceUsd: priceUsd ?? this.priceUsd,
      family: family ?? this.family,
      style: style ?? this.style,
      metal: metal ?? this.metal,
      purity: purity ?? this.purity,
      audience: audience ?? this.audience,
      occasions: occasions ?? this.occasions,
      collectionIds: collectionIds ?? this.collectionIds,
      isVerifiedSupplier: isVerifiedSupplier ?? this.isVerifiedSupplier,
    );
  }
}
