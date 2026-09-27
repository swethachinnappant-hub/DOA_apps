import 'package:flutter/material.dart';

import '../product.dart';
import 'order.dart';

/// A product sitting in the cart, with the variant the shopper chose.
@immutable
class CartItem {
  final String productId;
  final String name;
  final String brand;
  final int unitPrice;
  final int quantity;
  final List<String> images;
  final String? selectedSize;
  final String? selectedShade;

  const CartItem({
    required this.productId,
    required this.name,
    required this.brand,
    required this.unitPrice,
    required this.quantity,
    this.images = const [],
    this.selectedSize,
    this.selectedShade,
  });

  factory CartItem.fromProduct(
    Product product, {
    int quantity = 1,
    String? selectedSize,
    String? selectedShade,
  }) {
    return CartItem(
      productId: product.id,
      name: product.name,
      brand: product.brand,
      unitPrice: product.price,
      quantity: quantity,
      images: product.images,
      selectedSize: selectedSize,
      selectedShade: selectedShade,
    );
  }

  int get lineTotal => unitPrice * quantity;

  /// Identity of a cart line. The same product in two sizes is two lines, so
  /// the variant is part of the key.
  String get lineKey =>
      '$productId|${selectedSize ?? '-'}|${selectedShade ?? '-'}';

  String get variantLabel {
    final parts = [
      if (selectedSize != null && selectedSize!.isNotEmpty) selectedSize!,
      if (selectedShade != null && selectedShade!.isNotEmpty) selectedShade!,
    ];
    return parts.join(' · ');
  }

  OrderItem toOrderItem() => OrderItem(
        productId: productId,
        name: name,
        brand: brand,
        unitPrice: unitPrice,
        quantity: quantity,
        images: images,
        selectedSize: selectedSize,
        selectedShade: selectedShade,
      );

  CartItem copyWith({int? quantity, int? unitPrice}) => CartItem(
        productId: productId,
        name: name,
        brand: brand,
        unitPrice: unitPrice ?? this.unitPrice,
        quantity: quantity ?? this.quantity,
        images: images,
        selectedSize: selectedSize,
        selectedShade: selectedShade,
      );

  Map<String, Object?> toJson() => {
        'productId': productId,
        'name': name,
        'brand': brand,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'images': images,
        'selectedSize': selectedSize,
        'selectedShade': selectedShade,
      };

  factory CartItem.fromJson(Map<String, Object?> json) => CartItem(
        productId: json['productId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        brand: json['brand'] as String? ?? '',
        unitPrice: (json['unitPrice'] as num?)?.toInt() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        images: (json['images'] as List?)?.cast<String>() ?? const [],
        selectedSize: json['selectedSize'] as String?,
        selectedShade: json['selectedShade'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem && other.lineKey == lineKey && other.quantity == quantity;

  @override
  int get hashCode => Object.hash(lineKey, quantity);
}
