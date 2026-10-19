import 'package:common_widgets/common_widgets.dart';
import 'package:ecommerce_app/core/pricing.dart';
import 'package:ecommerce_app/core/product.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/cart/screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/shop_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Product seeded({required int price}) =>
      Product(
        id: 'mini-$price',
        name: 'Classic Solitaire Ring',
        brand: 'Kirtilals',
        category: 'Rings',
        sku: 'SKU-$price',
        price: price,
        mrp: price,
        rating: 4.7,
        reviewCount: 32,
        images: const [],
        icon: Icons.diamond,
      );

  Future<void> openMiniCart(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Cart'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('the header cart icon opens the mini-cart with line, coupon and totals', (
    tester,
  ) async {
    final (router, _, store) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );
    final product = seeded(price: 46000);
    store.addToCart(product);
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await openMiniCart(tester);

    expect(find.text('Your Mini Cart'), findsOneWidget);
    expect(find.text('( 1 Item )'), findsOneWidget);
    expect(find.text('Classic Solitaire Ring'), findsOneWidget);
    expect(find.text('Qty : 1'), findsOneWidget);
    expect(find.text('Price ₹46,000'), findsOneWidget);

    expect(find.text('COUPON'), findsOneWidget);
    expect(find.text('HOPE500'), findsOneWidget);
    expect(
      find.text(
        'Add ₹49,900 more to get a flat ₹500 off on this order.',
      ),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final apply = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Apply'),
    );
    expect(apply.onPressed, isNull);

    expect(find.text('View all coupons'), findsOneWidget);
    expect(find.text('Sub Total (before tax)'), findsOneWidget);
    expect(find.text('₹46,000'), findsOneWidget);
    expect(find.text('Grand Total'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'View Cart'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Quick Checkout'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the coupon walks needsMore → eligible → applied → back', (
    tester,
  ) async {
    final (router, _, store) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );
    final product = seeded(price: 47950);
    store.addToCart(product, quantity: 2);
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await openMiniCart(tester);
    expect(
      find.text("You've unlocked a flat ₹500 off on this order!"),
      findsOneWidget,
    );
    var apply = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Apply'),
    );
    expect(apply.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(AppButton, 'Apply'));
    await tester.pump();
    expect(store.appliedCoupon?.code, 'HOPE500');
    expect(
      find.text("You've saved ₹500 on this order."),
      findsOneWidget,
    );
    expect(find.widgetWithText(AppButton, 'Remove'), findsOneWidget);
    expect(find.text('- ₹500'), findsOneWidget);
    expect(find.text(Pricing.money(Pricing.tax(95400))), findsOneWidget);
    expect(
      find.text(Pricing.money(95400 + Pricing.tax(95400))),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    store.setCartQuantity(store.cart.first.lineKey, 1);
    await tester.pump();
    expect(store.appliedCoupon, isNull);
    expect(
      find.text('Add ₹47,950 more to get a flat ₹500 off on this order.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(AppButton, 'Remove'), findsNothing);

    store.setCartQuantity(store.cart.first.lineKey, 2);
    await tester.pump();
    apply = tester.widget<AppButton>(find.widgetWithText(AppButton, 'Apply'));
    expect(apply.onPressed, isNotNull);
    await tester.tap(find.widgetWithText(AppButton, 'Apply'));
    await tester.pump();
    expect(
      find.text("You've saved ₹500 on this order."),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(AppButton, 'Remove'));
    await tester.pump();
    expect(store.appliedCoupon, isNull);
    expect(
      find.text("You've unlocked a flat ₹500 off on this order!"),
      findsOneWidget,
    );
  });

  testWidgets('view all coupons reveals the other codes', (tester) async {
    final (router, _, store) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );
    store.addToCart(seeded(price: 46000));
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await openMiniCart(tester);
    expect(find.text('DIAMOND200'), findsNothing);

    await tester.tap(find.text('View all coupons'));
    await tester.pump();

    expect(find.text('DIAMOND200'), findsOneWidget);
    expect(find.text('GIFT1000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('View Cart leaves the drawer and shows the cart screen', (
    tester,
  ) async {
    final (router, _, store) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );
    store.addToCart(seeded(price: 46000));
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await openMiniCart(tester);
    await tester.tap(find.widgetWithText(AppButton, 'View Cart'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CartScreen), findsOneWidget);
    expect(find.text('Your Mini Cart'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the coupons rule hides the coupon block', (tester) async {
    final (router, config, store) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );
    config.updateSingleRule('coupons', false);
    store.addToCart(seeded(price: 46000));
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await openMiniCart(tester);

    expect(find.text('COUPON'), findsNothing);
    expect(find.widgetWithText(AppButton, 'Apply'), findsNothing);
    expect(find.text('Grand Total'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the mini-cart renders clean at 390 / 768 / 1440', (
    tester,
  ) async {
    for (final viewport in const [
      Size(390, 844),
      Size(768, 1024),
      Size(1440, 900),
    ]) {
      final (router, _, store) = await pumpShop(tester, viewport: viewport);
      store.addToCart(seeded(price: 46000));
      router.go('/app');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await openMiniCart(tester);

      expect(find.text('Your Mini Cart'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'mini-cart at ${viewport.width}x${viewport.height}',
      );

      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Your Mini Cart'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('the empty bag shows the browse fallback', (tester) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await openMiniCart(tester);

    expect(find.text('Your bag is empty'), findsOneWidget);
    expect(find.text('Browse the catalogue'), findsOneWidget);
    expect(find.text('Grand Total'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('the featured coupon carries the verified HOPE500 terms', () {
    final coupon = CommerceStore.defaultCoupons.first;
    expect(coupon.code, 'HOPE500');
    expect(coupon.flatOffInr, 500);
    expect(coupon.minSubtotal, 95900);
    expect(coupon.missingFor(91800), 4100);
  });
}
