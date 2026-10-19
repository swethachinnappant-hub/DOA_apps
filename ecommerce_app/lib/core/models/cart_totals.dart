import 'package:flutter/foundation.dart';

import '../pricing.dart';
import 'coupon.dart';

@immutable
class CartTotals {
  const CartTotals({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.shipping,
    required this.grandTotal,
  });

  final int subtotal;
  final int discount;
  final int tax;
  final int shipping;
  final int grandTotal;

  int get net => subtotal - discount;

  factory CartTotals.compute({
    required int subtotal,
    Coupon? coupon,
  }) {
    final discount = (coupon != null && coupon.isSatisfiedBy(subtotal))
        ? coupon.flatOffInr
        : 0;
    final net = subtotal - discount;
    final tax = Pricing.tax(net);
    final shipping = Pricing.shipping(net);
    return CartTotals(
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      shipping: shipping,
      grandTotal: net + tax + shipping,
    );
  }
}
