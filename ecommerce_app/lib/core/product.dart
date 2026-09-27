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

  /// When the listing was last changed, used to order "recently added".
  final DateTime? createdAt;

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
    this.createdAt,
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

  /// True when the seller has run out. Seeded listings carry no stock count,
  /// so they fall back to the explicit [inStock] flag.
  bool get isAvailable => inStock && (ownerId.isEmpty || stock > 0);

  /// Low-stock threshold used for the "only N left" nudge on cards.
  bool get isLowStock => ownerId.isNotEmpty && stock > 0 && stock <= 5;

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
    DateTime? createdAt,
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
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
