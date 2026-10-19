import 'package:ecommerce_app/features/orders/screens/order_detail_screen.dart';
import 'package:ecommerce_app/features/profile/screens/addresses_screen.dart';
import 'package:ecommerce_app/features/profile/screens/coupons_screen.dart';
import 'package:ecommerce_app/features/profile/screens/loyalty_screen.dart';
import 'package:ecommerce_app/features/profile/screens/profile_screen.dart';
import 'package:ecommerce_app/features/shell/section_screen.dart';
import 'package:ecommerce_app/features/shell/site_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/shop_harness.dart';

/// Phase 8 gate (§16.3): every §5.8 footer link opens a real designed page —
/// never the 404 body — at 390 and 1440, the account menu reaches the wallet,
/// loyalty and address screens, and an order's four actions (invoice,
/// reorder, return, support) all work against the live store.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// One signature string per footer link (§5.8): the page's own heading,
  /// chosen so it proves the designed body rendered, not just the chrome.
  const signatures = <String, String>{
    '/world-of-kirtilals': 'World of Kirtilals',
    '/blog/country/kirtilals-india': 'The Kirtilals Blog',
    '/faq': 'Frequently Asked Questions',
    '/feedback': 'Tell us how we did',
    '/contactusform': 'Contact us',
    '/privacy-policy': 'Privacy Policy',
    '/shipping-and-return-policy': 'Shipping & Returns',
    '/investors': 'Investors',
    '/terms-and-conditions': 'Terms of Service',
    '/clp-terms': 'CLP Terms & Conditions',
    '/bespoke': 'MADE FOR YOU',
    '/tryinstore': 'FIND A STORE',
  };

  /// Screen children mount lazily as a ListView scrolls, so a target below
  /// the fold has to be dragged in before ensureVisible/tap can see it.
  Future<void> revealAndTap(
    WidgetTester tester,
    Finder target, {
    Finder? within,
  }) async {
    final scrollable = within == null
        ? find.byType(Scrollable)
        : find.descendant(of: within, matching: find.byType(Scrollable));
    expect(scrollable, findsWidgets, reason: 'no scrollable to drag');

    for (var i = 0; i < 10 && target.evaluate().isEmpty; i++) {
      await tester.drag(scrollable.first, const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(
      target.evaluate(),
      isNotEmpty,
      reason: '$target never mounted while scrolling',
    );

    await tester.ensureVisible(target);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(target);
    await tester.pump();
  }

  /// SnackBars auto-dismiss on a 4 s timer; pump past it so the exit
  /// animation completes and no pending timer outlives the test.
  Future<void> drainSnackBars(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('every footer link opens its designed page at 390 and 1440',
      (tester) async {
    final footerPaths = <String>{
      for (final column in SiteFooter.linkColumns.values)
        for (final link in column) link[1],
    };
    expect(
      signatures.keys,
      containsAll(footerPaths),
      reason: 'a footer link was added without a signature assertion',
    );

    for (final viewport in const [Size(390, 844), Size(1440, 900)]) {
      final (router, _, _) = await pumpShop(tester, viewport: viewport);

      for (final path in footerPaths) {
        router.go(path);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          tester.takeException(),
          isNull,
          reason: 'rendering $path threw at ${viewport.width}px',
        );
        expect(
          find.textContaining('does not exist', skipOffstage: false),
          findsNothing,
          reason: '$path fell through to the router error fallback',
        );
        expect(
          find.text("We couldn't find that page", skipOffstage: false),
          findsNothing,
          reason: '$path rendered the designed 404 body',
        );
        expect(
          find.byType(SectionScreen, skipOffstage: false),
          findsWidgets,
          reason: '$path did not resolve to SectionScreen',
        );
        expect(
          find.text(signatures[path]!, skipOffstage: false),
          findsWidgets,
          reason: '$path lost its designed body (${signatures[path]})',
        );
      }

      // Detach before the next viewport keeps a clean tree.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('the virtual showrooms render their coming-soon heroes',
      (tester) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );

    const virtual = <String, String>{
      '/virtual-tryon': 'Virtual Try-On',
      '/virtualstoreproduct': 'Virtual Store',
      '/co-shopping-products': 'Decide With Friends',
    };
    for (final entry in virtual.entries) {
      router.go(entry.key);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull, reason: '${entry.key} threw');
      expect(
        find.byType(SectionScreen, skipOffstage: false),
        findsWidgets,
        reason: '${entry.key} did not resolve to SectionScreen',
      );
      expect(
        find.text(entry.value, skipOffstage: false),
        findsWidgets,
        reason: '${entry.key} lost its hero title',
      );
      expect(
        find.text('Coming soon', skipOffstage: false),
        findsOneWidget,
        reason: '${entry.key} lost its coming-soon card',
      );
      expect(
        find.text('BROWSE THE CATALOGUE', skipOffstage: false),
        findsOneWidget,
        reason: '${entry.key} lost its catalogue CTA',
      );
    }
  });

  testWidgets('the account wallet routes render their designed bodies',
      (tester) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );

    final cases = <String, (Type, String)>{
      '/addresses': (AddressesScreen, 'Add address'),
      '/loyalty': (LoyaltyScreen, '1250 points'),
      '/coupons': (CouponsScreen, 'HOPE500'),
    };
    for (final entry in cases.entries) {
      router.go(entry.key);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull, reason: '${entry.key} threw');
      expect(
        find.byType(entry.value.$1, skipOffstage: false),
        findsOneWidget,
        reason: '${entry.key} did not open ${entry.value.$1}',
      );
      expect(
        find.text(entry.value.$2, skipOffstage: false),
        findsWidgets,
        reason: '${entry.key} lost its body text (${entry.value.$2})',
      );
      expect(
        find.byType(SectionScreen, skipOffstage: false),
        findsNothing,
        reason: '${entry.key} should be a direct screen, not a section page',
      );
    }
  });

  testWidgets('the account menu reaches addresses, loyalty and coupons',
      (tester) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );

    Future<void> openMenu(String label, Type screen, String body) async {
      router.go('/account');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byType(ProfileScreen, skipOffstage: false),
        findsOneWidget,
      );

      await revealAndTap(
        tester,
        find.text(label),
        within: find.byType(ProfileScreen),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byType(screen, skipOffstage: false),
        findsOneWidget,
        reason: "menu item '$label' did not open $screen",
      );
      expect(
        find.text(body, skipOffstage: false),
        findsWidgets,
        reason: "$screen lost its body text ($body)",
      );
      expect(tester.takeException(), isNull);
    }

    await openMenu('Addresses', AddressesScreen, 'Add address');
    await openMenu('Loyalty Points', LoyaltyScreen, '1250 points');
    await openMenu('Coupons', CouponsScreen, 'HOPE500');
  });

  testWidgets('an order downloads, reorders, returns and calls support',
      (tester) async {
    final (router, _, store) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );

    store.addToCart(store.shopProducts.first, quantity: 2);
    final placed = store.placeOrder(
      customerId: 'u-phase8-gate',
      customerName: 'Phase Eight',
      deliveryAddress: '14 MG Road, Bengaluru, Karnataka 560001',
    );
    expect(placed, isNotNull, reason: 'the seeded cart should place an order');

    router.go('/order/${placed!.id}');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(OrderDetailScreen, skipOffstage: false), findsOneWidget);
    expect(store.cartCount, 0, reason: 'placing the order empties the bag');

    // Download invoice → confirmation dialog → saved snackbar.
    await revealAndTap(
      tester,
      find.text('Download invoice'),
      within: find.byType(OrderDetailScreen),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.text('Invoice for ${placed.id} is ready.'),
      findsOneWidget,
      reason: 'the invoice dialog should name the order',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Download'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('Invoice for ${placed.id} saved'),
      findsOneWidget,
      reason: 'downloading should confirm with a snackbar',
    );
    await drainSnackBars(tester);

    // Reorder → both line quantities are back in the live bag.
    await revealAndTap(
      tester,
      find.text('Reorder'),
      within: find.byType(OrderDetailScreen),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('2 items added to your bag'),
      findsOneWidget,
      reason: 'reorder should report the quantity it restored',
    );
    expect(
      store.cartCount,
      2,
      reason: 'reorder should put the order lines back into the cart',
    );
    await drainSnackBars(tester);

    // Return / Exchange only exists once the seller delivers the order.
    expect(find.text('Return / Exchange'), findsNothing);
    for (var i = 0; i < 5; i++) {
      expect(store.advanceOrder(placed.id), isTrue, reason: 'step $i of delivery');
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.orderById(placed.id)!.status.name, 'delivered');

    await revealAndTap(
      tester,
      find.text('Return / Exchange'),
      within: find.byType(OrderDetailScreen),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Return or exchange'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Raise request'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.textContaining('Request raised'),
      findsOneWidget,
      reason: 'raising a return should confirm with a snackbar',
    );
    await drainSnackBars(tester);

    // Contact customer delight → the verified support numbers.
    await revealAndTap(
      tester,
      find.text('Contact customer delight'),
      within: find.byType(OrderDetailScreen),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('Call 1800 120 0411 or WhatsApp +91 98948 40711'),
      findsOneWidget,
      reason: 'support should surface the footer contact numbers',
    );
    await drainSnackBars(tester);

    expect(tester.takeException(), isNull);
  });
}
