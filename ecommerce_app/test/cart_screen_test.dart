import 'package:common_widgets/common_widgets.dart';
import 'package:ecommerce_app/core/pricing.dart';
import 'package:ecommerce_app/core/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/shop_harness.dart';

/// The §9.2 bag: a sticky ORDER SUMMARY with a working coupon block at
/// desktop widths, the compact single column with a sticky checkout CTA on a
/// phone, and the per-line controls wired to the store.
void main() {
  Product bigProduct({int price = 96000}) => Product(
    id: 'phase7-$price',
    name: 'Temple Necklace',
    brand: 'Kirtilals',
    category: 'Necklaces',
    sku: 'SKU-$price',
    price: price,
    mrp: price,
    rating: 4.8,
    reviewCount: 32,
    images: const [],
    icon: Icons.diamond,
  );

  // enterText/ensureVisible start a caret scroll (DrivenScrollActivity) in a
  // post-frame callback; while it runs the Scrollable ignores child pointers
  // and tap() would miss. Two short pumps let it start and settle, since the
  // test clock is otherwise frozen.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(finder);
    await tester.pump();
  }

  testWidgets('desktop keeps a sticky summary and applies the coupon', (
    tester,
  ) async {
    final (router, _, store) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );
    store.addToCart(bigProduct());
    router.go('/cart');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('ORDER SUMMARY'), findsOneWidget);
    expect(find.text('COUPON'), findsOneWidget);
    expect(find.text('Temple Necklace'), findsOneWidget);
    expect(find.text('Shopping Cart (1)'), findsOneWidget);
    expect(store.cartSubtotal, 96000);
    expect(tester.takeException(), isNull);

    await tapVisible(tester, find.widgetWithText(AppButton, 'Apply'));

    expect(store.appliedCoupon?.code, 'HOPE500');
    expect(find.text('- ${Pricing.money(500)}'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Remove'), findsOneWidget);
    expect(
      find.text(Pricing.money(store.cartTotals.grandTotal)),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('a phone gets one column, a sticky CTA and can move a line out',
      (tester) async {
    final (router, _, store) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    final product = store.shopProducts.first;
    store.addToCart(product, quantity: 1);
    router.go('/cart');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('ORDER SUMMARY'), findsNothing);
    expect(find.text('COUPON'), findsOneWidget);
    expect(find.text('Sub Total (before tax)'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Proceed to checkout'), findsOneWidget);
    expect(find.text(product.name), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tapVisible(tester, find.byTooltip('Move to wishlist'));

    expect(store.cart, isEmpty);
    expect(store.isWishlisted(product.id), isTrue);
    expect(find.text('Moved to wishlist'), findsOneWidget);
    expect(find.text('Your bag is empty'), findsOneWidget);
    expect(find.text('Recommended for you'), findsOneWidget);

    // Drain the snackbar timer so the test does not end with it pending.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('the coupons rule gates the coupon block on the cart', (
    tester,
  ) async {
    final (router, config, store) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    config.updateSingleRule('coupons', false);
    store.addToCart(store.shopProducts.first);
    router.go('/cart');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('COUPON'), findsNothing);
    expect(find.widgetWithText(AppButton, 'Apply'), findsNothing);
    expect(find.text('Sub Total (before tax)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('gift wrap reveals the note and the pincode answers a date', (
    tester,
  ) async {
    final (router, _, store) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    store.addToCart(store.shopProducts.first);
    router.go('/cart');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Gift wrap this order'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();
    await tapVisible(tester, find.widgetWithText(AppButton, 'Check'));
    expect(find.text('Enter a 6-digit pincode'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '560001');
    await tester.pump();
    await tapVisible(tester, find.widgetWithText(AppButton, 'Check'));
    expect(find.textContaining('Delivery by '), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('the phase-7 screens render cleanly at 390, 768 and 1440', (
    tester,
  ) async {
    final (router, _, store) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    store.addToCart(store.shopProducts.first, quantity: 2);
    final order = store.placeOrder(
      customerId: 'c-render',
      customerName: 'Casey',
      deliveryAddress: '14 MG Road, Bengaluru, Karnataka 560001',
      paymentMethod: 'UPI',
    );
    store.addToCart(store.shopProducts.last, quantity: 1);
    expect(order, isNotNull);
    final orderId = order!.id;

    for (final size in const [
      Size(390, 844),
      Size(768, 1024),
      Size(1440, 900),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      for (final location in [
        '/cart',
        '/checkout',
        '/order-success/$orderId',
      ]) {
        router.go(location);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          tester.takeException(),
          isNull,
          reason: '$location at ${size.width}x${size.height}',
        );
      }
    }
  }, timeout: const Timeout(Duration(seconds: 120)));
}
