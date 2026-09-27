import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../product.dart';

/// Lifecycle of an order, mirroring the marketplace convention: a customer
/// places it, the seller confirms, packs and ships, then it is delivered.
///
/// [next] and [canTransitionTo] make this a real state machine rather than a
/// free-text field, so a seller cannot jump an order straight to "Delivered"
/// and the customer's timeline is always derived, never hand-written.
enum OrderStatus {
  placed('Placed', 'We have your order', Icons.receipt_long_outlined),
  confirmed('Confirmed', 'Seller accepted your order', Icons.check_circle_outline),
  packed('Packed', 'Your items are being packed', Icons.inventory_2_outlined),
  shipped('Shipped', 'On the way to you', Icons.local_shipping_outlined),
  outForDelivery('Out for delivery', 'Arriving today', Icons.moving_outlined),
  delivered('Delivered', 'Delivered', Icons.done_all),
  cancelled('Cancelled', 'This order was cancelled', Icons.cancel_outlined),
  returned('Returned', 'This order was returned', Icons.undo);

  const OrderStatus(this.label, this.hint, this.icon);

  final String label;
  final String hint;
  final IconData icon;

  /// Statuses that mean the order is still moving forward.
  bool get isActive =>
      this != delivered && this != cancelled && this != returned;

  bool get isClosed => !isActive;

  /// The status a seller should advance to next, or null when closed.
  OrderStatus? get next {
    switch (this) {
      case OrderStatus.placed:
        return OrderStatus.confirmed;
      case OrderStatus.confirmed:
        return OrderStatus.packed;
      case OrderStatus.packed:
        return OrderStatus.shipped;
      case OrderStatus.shipped:
        return OrderStatus.outForDelivery;
      case OrderStatus.outForDelivery:
        return OrderStatus.delivered;
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
      case OrderStatus.returned:
        return null;
    }
  }

  /// Sellers may only walk forward one step at a time, or cancel while the
  /// order is still active. Returns false for backwards or illegal jumps.
  bool canTransitionTo(OrderStatus target) {
    if (target == this) return false;
    if (isClosed) return false;
    return target == OrderStatus.cancelled || target == next;
  }

  Color get color {
    switch (this) {
      case OrderStatus.placed:
        return AppPalette.textSecondary;
      case OrderStatus.confirmed:
        return AppPalette.info;
      case OrderStatus.packed:
        return const Color(0xFF7C3AED);
      case OrderStatus.shipped:
        return AppPalette.info;
      case OrderStatus.outForDelivery:
        return AppPalette.warning;
      case OrderStatus.delivered:
        return AppPalette.success;
      case OrderStatus.cancelled:
        return AppPalette.error;
      case OrderStatus.returned:
        return AppPalette.error;
    }
  }

  /// Customer-facing timeline, derived from the current status so it can never
  /// disagree with the order's real state.
  static List<OrderStatus> get timeline => const [
        OrderStatus.placed,
        OrderStatus.confirmed,
        OrderStatus.packed,
        OrderStatus.shipped,
        OrderStatus.outForDelivery,
        OrderStatus.delivered,
      ];

  static OrderStatus fromName(String? name) {
    for (final status in OrderStatus.values) {
      if (status.name == name) return status;
    }
    return OrderStatus.placed;
  }
}

/// One line on an order.
///
/// A snapshot of name/price/image is stored rather than a [Product] reference
/// so that later edits by the seller cannot rewrite the customer's history.
@immutable
class OrderItem {
  final String productId;
  final String name;
  final String brand;
  final int unitPrice;
  final int quantity;
  final List<String> images;
  final String? selectedSize;
  final String? selectedShade;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.brand,
    required this.unitPrice,
    required this.quantity,
    this.images = const [],
    this.selectedSize,
    this.selectedShade,
  });

  int get lineTotal => unitPrice * quantity;

  /// Size and shade the buyer picked, ready to print on a row.
  String get variantLabel {
    final parts = [
      if (selectedSize != null && selectedSize!.isNotEmpty) selectedSize!,
      if (selectedShade != null && selectedShade!.isNotEmpty) selectedShade!,
    ];
    return parts.join(' · ');
  }

  factory OrderItem.fromProduct(
    Product product, {
    int quantity = 1,
    String? selectedSize,
    String? selectedShade,
  }) {
    return OrderItem(
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

  OrderItem copyWith({int? quantity, int? unitPrice}) => OrderItem(
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

  factory OrderItem.fromJson(Map<String, Object?> json) => OrderItem(
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
      other is OrderItem &&
          other.productId == productId &&
          other.unitPrice == unitPrice &&
          other.quantity == quantity &&
          other.selectedSize == selectedSize &&
          other.selectedShade == selectedShade &&
          listEquals(other.images, images);

  @override
  int get hashCode => Object.hash(
        productId,
        unitPrice,
        quantity,
        selectedSize,
        selectedShade,
        Object.hashAll(images),
      );
}

/// A customer order, visible to the buyer and to the seller who owns the items.
@immutable
class Order {
  final String id;
  final String customerId;
  final String customerName;

  /// Owner whose shop fulfilled this order. Empty means platform stock.
  final String ownerId;
  final String ownerName;

  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime placedAt;
  final DateTime? updatedAt;
  final String paymentMethod;
  final String deliveryAddress;

  /// GST at 18%, the rate the rest of the app already assumes.
  static const double taxRate = 0.18;

  const Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.ownerId,
    required this.ownerName,
    required this.items,
    required this.placedAt,
    this.status = OrderStatus.placed,
    this.updatedAt,
    this.paymentMethod = 'UPI',
    this.deliveryAddress = '',
  });

  int get subtotal =>
      items.fold<int>(0, (sum, item) => sum + item.lineTotal);

  int get tax => (subtotal * taxRate).round();

  int get shipping => subtotal >= 999 ? 0 : 79;

  int get total => subtotal + tax + shipping;

  int get itemCount => items.fold<int>(0, (sum, item) => sum + item.quantity);

  bool get isFreeShipping => shipping == 0;

  /// Amount still needed to unlock free delivery, 0 once it is met.
  int get amountToFreeShipping {
    if (isFreeShipping) return 0;
    const threshold = 999;
    final gap = threshold - subtotal;
    return gap <= 0 ? 0 : gap;
  }

  Order copyWith({
    OrderStatus? status,
    DateTime? updatedAt,
    List<OrderItem>? items,
    String? deliveryAddress,
    String? paymentMethod,
  }) {
    final nextStatus = status ?? this.status;
    // A status change is what the customer timeline reports, so stamp it here
    // rather than trusting every caller to remember.
    final stamped = nextStatus != this.status
        ? (updatedAt ?? DateTime.now())
        : (updatedAt ?? this.updatedAt);

    return Order(
      id: id,
      customerId: customerId,
      customerName: customerName,
      ownerId: ownerId,
      ownerName: ownerName,
      items: items ?? this.items,
      placedAt: placedAt,
      status: nextStatus,
      updatedAt: stamped,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order &&
          other.id == id &&
          other.customerId == customerId &&
          other.ownerId == ownerId &&
          other.status == status &&
          other.paymentMethod == paymentMethod &&
          other.deliveryAddress == deliveryAddress &&
          listEquals(other.items, items);

  @override
  int get hashCode => Object.hash(
        id,
        customerId,
        ownerId,
        status,
        paymentMethod,
        deliveryAddress,
        Object.hashAll(items),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'items': items.map((i) => i.toJson()).toList(),
        'status': status.name,
        'placedAt': placedAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'paymentMethod': paymentMethod,
        'deliveryAddress': deliveryAddress,
      };

  factory Order.fromJson(Map<String, Object?> json) => Order(
        id: json['id'] as String? ?? '',
        customerId: json['customerId'] as String? ?? '',
        customerName: json['customerName'] as String? ?? '',
        ownerId: json['ownerId'] as String? ?? '',
        ownerName: json['ownerName'] as String? ?? '',
        items: (json['items'] as List? ?? const [])
            .map((e) => OrderItem.fromJson((e as Map).cast<String, Object?>()))
            .toList(),
        status: OrderStatus.fromName(json['status'] as String?),
        placedAt:
            DateTime.tryParse(json['placedAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
        paymentMethod: json['paymentMethod'] as String? ?? 'UPI',
        deliveryAddress: json['deliveryAddress'] as String? ?? '',
      );
}
