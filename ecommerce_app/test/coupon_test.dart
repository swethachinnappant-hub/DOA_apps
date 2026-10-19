import 'package:ecommerce_app/core/models/cart_totals.dart';
import 'package:ecommerce_app/core/models/coupon.dart';
import 'package:ecommerce_app/core/pricing.dart';
import 'package:ecommerce_app/core/product.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Product product({required int price, String id = 'p1'}) =>
      Product(
        id: id,
        name: 'Test Ring',
        brand: 'Kirtilals',
        category: 'Rings',
        sku: id,
        price: price,
        mrp: price,
        rating: 4.5,
        reviewCount: 12,
        images: const [],
        icon: Icons.diamond,
      );

  group('coupon state on the store', () {
    test('applyCoupon refuses below the threshold and accepts above', () {
      final store = CommerceStore();
      store.addToCart(product(price: 40000, id: 'a'));
      expect(store.applyCoupon('HOPE500'), isFalse);
      expect(store.appliedCoupon, isNull);

      store.addToCart(product(price: 60000, id: 'b'));
      expect(store.cartSubtotal, 100000);
      expect(store.applyCoupon('hope500'), isTrue);
      expect(store.appliedCoupon?.code, 'HOPE500');
      expect(store.couponDiscount, 500);
    });

    test('an unknown code never applies', () {
      final store = CommerceStore();
      store.addToCart(product(price: 999999, id: 'a'));
      expect(store.applyCoupon('NOPE999'), isFalse);
      expect(store.appliedCoupon, isNull);
    });

    test('needsMore becomes eligible when quantity grows past the bar', () {
      final store = CommerceStore();
      store.addToCart(product(price: 47950, id: 'a'));
      final lineKey = store.cart.first.lineKey;
      expect(store.cartSubtotal, 47950);
      expect(
        couponStatusOf(
          coupon: CommerceStore.defaultCoupons.first,
          subtotal: store.cartSubtotal,
          isApplied: false,
        ),
        CouponStatus.needsMore,
      );
      expect(store.applyCoupon('HOPE500'), isFalse);

      store.setCartQuantity(lineKey, 2);
      expect(store.cartSubtotal, 95900);
      expect(
        couponStatusOf(
          coupon: CommerceStore.defaultCoupons.first,
          subtotal: store.cartSubtotal,
          isApplied: false,
        ),
        CouponStatus.eligible,
      );
      expect(store.applyCoupon('HOPE500'), isTrue);
    });

    test('an applied coupon drops when the cart falls back under the bar', () {
      final store = CommerceStore();
      store.addToCart(product(price: 47950, id: 'a'), quantity: 2);
      final lineKey = store.cart.first.lineKey;
      expect(store.applyCoupon('HOPE500'), isTrue);

      store.setCartQuantity(lineKey, 1);
      expect(store.appliedCoupon, isNull);
      expect(store.couponDiscount, 0);
    });

    test('removeCoupon and clearCart reset the discount', () {
      final store = CommerceStore();
      store.addToCart(product(price: 95900, id: 'a'));
      expect(store.applyCoupon('HOPE500'), isTrue);

      store.removeCoupon();
      expect(store.appliedCoupon, isNull);
      expect(store.couponDiscount, 0);

      expect(store.applyCoupon('HOPE500'), isTrue);
      store.clearCart();
      expect(store.appliedCoupon, isNull);
      expect(store.couponDiscount, 0);
    });

    test('cartTotals applies the discount before tax', () {
      final totals = CartTotals.compute(
        subtotal: 95900,
        coupon: CommerceStore.defaultCoupons.first,
      );
      expect(totals.discount, 500);
      expect(totals.net, 95400);
      expect(totals.tax, Pricing.tax(95400));
      expect(totals.tax, 17172);
      expect(totals.shipping, 0);
      expect(totals.grandTotal, 95400 + Pricing.tax(95400));
    });

    test('cartTotals ignores a coupon that is not satisfied', () {
      final totals = CartTotals.compute(
        subtotal: 40000,
        coupon: CommerceStore.defaultCoupons.first,
      );
      expect(totals.discount, 0);
      expect(totals.grandTotal, Pricing.total(40000));
    });
  });

  group('coupon status helper', () {
    const coupon = Coupon(
      code: 'X',
      flatOffInr: 500,
      minSubtotal: 1000,
    );

    test('covers needsMore, eligible and applied', () {
      expect(
        couponStatusOf(coupon: coupon, subtotal: 999, isApplied: false),
        CouponStatus.needsMore,
      );
      expect(
        couponStatusOf(coupon: coupon, subtotal: 1000, isApplied: false),
        CouponStatus.eligible,
      );
      expect(
        couponStatusOf(coupon: coupon, subtotal: 2000, isApplied: true),
        CouponStatus.applied,
      );
      expect(coupon.missingFor(400), 600);
      expect(coupon.missingFor(1000), 0);
    });
  });

  group('CommerceStore.search', () {
    test('matches name, brand and category and ignores blanks', () {
      final store = CommerceStore();
      store.seedProducts([
        product(price: 1000, id: 'a'),
        product(price: 1000, id: 'b')
            .copyWith(name: 'Gold Chain', category: 'Chains'),
      ]);

      expect(store.search(''), isEmpty);
      expect(store.search('   '), isEmpty);
      expect(store.search('gold').map((p) => p.id), contains('b'));
      expect(store.search('kirtilals'), hasLength(2));
      expect(store.search('chains').map((p) => p.id), contains('b'));
      expect(store.search('zzz'), isEmpty);
    });
  });
}
