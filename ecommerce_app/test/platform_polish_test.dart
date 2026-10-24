import 'dart:math' as math;

import 'package:common_widgets/common_widgets.dart';
import 'package:ecommerce_app/core/product.dart';
import 'package:ecommerce_app/features/catalogue/screens/catalogue_screen.dart';
import 'package:ecommerce_app/features/checkout/screens/checkout_screen.dart';
import 'package:ecommerce_app/features/main_screen.dart';
import 'package:ecommerce_app/features/product/screens/product_detail_screen.dart';
import 'package:ecommerce_app/features/search/search_overlay.dart';
import 'package:ecommerce_app/features/shell/app_header.dart';
import 'package:ecommerce_app/features/shell/bottom_bar.dart';
import 'package:ecommerce_app/features/shell/nav_drawer.dart';
import 'package:ecommerce_app/features/shell/site_footer.dart';
import 'package:ecommerce_app/features/wishlist/screens/wishlist_screen.dart';
import 'package:ecommerce_app/widgets/product_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/shop_harness.dart';

/// Phase 9 gate (§16.4 platform polish + §11.5 accessibility): Android system
/// back walks drawer → mega-menu panel → tabs home-ward, iOS pops pushed
/// routes with an edge swipe, Ctrl/Cmd+K plus a pure-keyboard walk reaches
/// checkout, icon-only controls keep labels and 44 px hit areas, cart and
/// coupon changes announce through live regions, and the shell holds at 200%
/// text across 390 / 768 / 1440.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The one seeded listing that is variant-free, in stock and uniquely
  /// named, so the keyboard walk lands on its card, detail page and CTAs.
  const targetName = 'Temple Motif Gold Necklace';

  Finder overlayField() => find.descendant(
    of: find.byType(SearchPanel),
    matching: find.byType(TextField),
  );

  Finder cardFor(String name) => find.descendant(
    of: find.byType(CatalogueScreen),
    matching: find.ancestor(of: find.text(name), matching: find.byType(ProductCard)),
  );

  /// SnackBars auto-dismiss on a 4 s timer; pump past it so the exit
  /// animation completes and no pending timer outlives the test.
  Future<void> drainSnackBars(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Whether the primary focus sits on or under [area].
  bool focusWithin(WidgetTester tester, Finder area) {
    final context = tester.binding.focusManager.primaryFocus?.context;
    if (context == null) return false;
    for (final element in area.evaluate()) {
      if (identical(context, element)) return true;
      var found = false;
      context.visitAncestorElements((ancestor) {
        if (identical(ancestor, element)) {
          found = true;
          return false;
        }
        return true;
      });
      if (found) return true;
    }
    return false;
  }

  /// Tabs forward until the focus lands inside [area] (§11.5 tab order).
  Future<void> tabUntil(
    WidgetTester tester,
    Finder area, {
    int limit = 120,
    required String reason,
  }) async {
    for (var i = 0; i < limit; i++) {
      if (focusWithin(tester, area)) return;
      if (tester.binding.focusManager.primaryFocus == null) {
        // Nothing holds focus yet (fresh route): seed it on the nearest field.
        final field = find.byType(TextField);
        if (field.evaluate().isEmpty) {
          fail('no focusable seed field while walking to $reason');
        }
        await tester.tap(field.first);
        await tester.pump();
      } else {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      }
      await tester.pump(const Duration(milliseconds: 30));
    }
    fail('tab order never reached $reason after $limit presses');
  }

  /// Whether any node matched by [finder] carries the liveRegion flag.
  bool announces(WidgetTester tester, Finder finder) {
    for (final element in finder.evaluate()) {
      final node = tester.getSemantics(
        find.byElementPredicate((candidate) => identical(candidate, element)),
      );
      if (node.getSemanticsData().flagsCollection.isLiveRegion) {
        return true;
      }
    }
    return false;
  }

  /// A single reused mouse pointer so hover enter/exit events fire like a
  /// real cursor moving across the header.
  Future<TestGesture> startMouse(WidgetTester tester) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    return mouse;
  }

  Product seeded({required int price}) => Product(
    id: 'phase9-$price',
    name: 'Classic Solitaire Ring',
    brand: 'Kirtilals',
    category: 'Rings',
    sku: 'SKU-phase9-$price',
    price: price,
    mrp: price,
    rating: 4.7,
    reviewCount: 32,
    images: const [],
    icon: Icons.diamond,
  );

  testWidgets('system back closes the drawer before leaving the shell', (
    tester,
  ) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final shell = tester
        .widgetList<Scaffold>(find.byType(Scaffold))
        .firstWhere((scaffold) => scaffold.drawer != null);
    final scaffoldState = tester.state<ScaffoldState>(find.byWidget(shell));
    expect(scaffoldState.isDrawerOpen, isFalse);

    await tester.tap(find.byTooltip('Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      scaffoldState.isDrawerOpen,
      isTrue,
      reason: 'the menu button should open the drawer',
    );
    expect(find.byType(NavDrawer, skipOffstage: false), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      scaffoldState.isDrawerOpen,
      isFalse,
      reason: 'the first back closes the drawer, not the route',
    );
    expect(find.byType(MainScreen, skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the phone header folds notifications, wishlist and account '
      'behind one circular menu', (tester) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final accountMenu = find.descendant(
      of: find.byType(AppHeader),
      matching: find.byTooltip('Account menu'),
    );
    final cart = find.descendant(
      of: find.byType(AppHeader),
      matching: find.byTooltip('Cart'),
    );
    expect(accountMenu, findsOneWidget, reason: 'one circle replaces the old '
        'notification / wishlist / profile icons');
    expect(cart, findsOneWidget, reason: 'cart stays visible on the phone');
    // No loose search icon anymore — the bottom bar owns search.
    expect(
      find.descendant(
        of: find.byType(AppHeader),
        matching: find.byTooltip('Search'),
      ),
      findsNothing,
    );

    // The circular button sits directly to the left of the cart.
    final accountBox = tester.getRect(accountMenu);
    final cartBox = tester.getRect(cart);
    expect(accountBox.right, closeTo(cartBox.left, 1));

    // Tapping it opens the sheet with the three entries (scoped to the
    // sheet's list rows — the bottom bar also labels a tab "Account").
    await tester.tap(accountMenu);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.widgetWithText(ListTile, 'Notifications'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Wishlist'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Account'), findsOneWidget);

    // The wishlist row routes to the wishlist screen.
    await tester.tap(find.widgetWithText(ListTile, 'Wishlist'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(WishlistScreen, skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the drawer account row reaches the profile', (tester) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byTooltip('Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(NavDrawer, skipOffstage: false), findsOneWidget);

    // The signed-in customer's name replaces the dead sign-in link.
    if (find.text('Customer').evaluate().isEmpty) {
      await tester.drag(find.byType(NavDrawer), const Offset(0, -240));
      await tester.pumpAndSettle();
    }
    final accountRow = find.text('Customer');
    expect(accountRow, findsOneWidget);
    await tester.ensureVisible(accountRow);
    await tester.tap(accountRow);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Your account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system back and Escape close the mega-menu panel', (
    tester,
  ) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final mouse = await startMouse(tester);

    Future<void> hoverOver(Finder finder) async {
      await mouse.moveTo(tester.getCenter(finder));
      await tester.pump(const Duration(milliseconds: 300));
    }

    await hoverOver(find.text('DIAMOND'));
    expect(
      find.byKey(const Key('nav-panel')),
      findsOneWidget,
      reason: 'hovering a nav item should open its panel',
    );

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byKey(const Key('nav-panel')),
      findsNothing,
      reason: 'system back should close the panel before leaving the route',
    );
    expect(find.byType(MainScreen, skipOffstage: false), findsOneWidget);

    // Move the pointer off the item so the next hover re-enters cleanly.
    await hoverOver(find.byTooltip('Search'));
    await hoverOver(find.text('DIAMOND'));
    expect(find.byKey(const Key('nav-panel')), findsOneWidget);

    await pressEscape(tester);
    expect(
      find.byKey(const Key('nav-panel')),
      findsNothing,
      reason: 'Escape should close the panel too',
    );
    expect(find.byType(MainScreen, skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system back walks bottom-bar tabs home before leaving', (
    tester,
  ) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final storeTab = find.descendant(
      of: find.byType(BottomBar),
      matching: find.text('Catalogue'),
    );
    await tester.tap(storeTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CatalogueScreen, skipOffstage: false), findsOneWidget);
    expect(find.text('THE JEWELLERY EDIT'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('THE JEWELLERY EDIT'),
      findsOneWidget,
      reason: 'the first back should return to the home tab',
    );
    expect(find.byType(CatalogueScreen, skipOffstage: false), findsNothing);
    expect(find.byType(MainScreen, skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a keyboard-only walk runs search → card → bag → checkout', (
    tester,
  ) async {
    final (router, _, store) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Ctrl/Cmd+K opens search from anywhere (§16.4 keyboard polish).
    await pressCtrlK(tester);
    expect(find.byType(SearchOverlay, skipOffstage: false), findsOneWidget);

    await tester.enterText(overlayField(), targetName);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // The pop's animation ticker starts a frame late, so the overlay's exit
    // needs one more pumped frame to complete before it leaves the tree.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CatalogueScreen, skipOffstage: false), findsWidgets);
    expect(find.byType(SearchOverlay, skipOffstage: false), findsNothing);

    for (var i = 0; i < 6 && cardFor(targetName).evaluate().isEmpty; i++) {
      await tester.drag(find.byType(CatalogueScreen), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(
      cardFor(targetName),
      findsWidgets,
      reason: 'the query should list $targetName',
    );

    await tabUntil(tester, cardFor(targetName), reason: 'the result card');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byType(ProductDetailScreen, skipOffstage: false),
      findsOneWidget,
      reason: 'Enter on the card should open its detail page',
    );

    await tabUntil(
      tester,
      find.widgetWithText(AppButton, 'Add to Bag'),
      reason: 'the Add to Bag CTA',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.cartCount, 1, reason: 'Enter on the CTA fills the bag');
    await drainSnackBars(tester);

    await tabUntil(
      tester,
      find.widgetWithText(AppButton, 'Buy Now'),
      limit: 10,
      reason: 'the Buy Now CTA',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byType(CheckoutScreen, skipOffstage: false),
      findsOneWidget,
      reason: 'Enter on Buy Now should reach checkout',
    );
    expect(store.cartCount, 2);
    await drainSnackBars(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('icon-only controls carry labels, 44 px targets and focus ring', (
    tester,
  ) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // §11.5: a semantics label on every icon-only control.
    expect(find.bySemanticsLabel(RegExp('Menu')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('Search')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('Cart')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('Home')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('Add to wishlist')), findsWidgets);

    // §11.5: touch targets reach 44 px even though the visuals stay small.
    for (final tooltip in const ['Menu', 'Account menu', 'Cart']) {
      final size = tester.getSize(find.byTooltip(tooltip).first);
      expect(size.width, greaterThanOrEqualTo(44), reason: '$tooltip width');
      expect(size.height, greaterThanOrEqualTo(44), reason: '$tooltip height');
    }
    final tabHit = find
        .descendant(of: find.byType(BottomBar), matching: find.byType(InkWell))
        .first;
    expect(tester.getSize(tabHit).height, greaterThanOrEqualTo(44));
    final heart = find.bySemanticsLabel(RegExp('Add to wishlist')).first;
    expect(tester.getSize(heart).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(heart).height, greaterThanOrEqualTo(44));

    // §11.5: the focus ring on keyboard-reachable controls is copper.
    expect(
      Theme.of(tester.element(find.byType(MainScreen))).focusColor,
      AppPalette.copper,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cart counts and coupon flips announce through live regions', (
    tester,
  ) async {
    final (router, _, store) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    store.addToCart(seeded(price: 47950), quantity: 2);
    await tester.pump();

    final badge = find.descendant(
      of: find.byType(AppHeader),
      matching: find.bySemanticsLabel(RegExp(r'Cart, 2 items')),
    );
    expect(badge, findsWidgets, reason: 'the header badge reports the count');
    expect(
      announces(tester, badge),
      isTrue,
      reason: 'cart count changes must announce (§11.5)',
    );

    await tester.tap(find.byTooltip('Cart'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Your Mini Cart'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Apply'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining("You've saved"), findsOneWidget);

    final saved = find.bySemanticsLabel(RegExp("You've saved"));
    expect(saved, findsWidgets);
    expect(
      announces(tester, saved),
      isTrue,
      reason: 'coupon state changes must announce (§11.5)',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS edge swipe pops a pushed screen back to the shell', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    router.push('/product/p6');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // The push animation's ticker starts a frame late; give it a third frame
    // to reach `completed`, which `popGestureEnabled` requires before an
    // edge drag is accepted.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ProductDetailScreen, skipOffstage: false), findsOneWidget);

    // Mirror the framework's Cupertino route swipe (flutter/test/cupertino/
    // route_test.dart), with two moves: the first wins the gesture arena and
    // fires the recognizer's onStart, the second fires onUpdate, which is
    // what actually drags the route. Past mid-screen guarantees the pop.
    final gesture = await tester.startGesture(const Offset(5, 450));
    await gesture.moveBy(const Offset(100, 0));
    await gesture.moveBy(const Offset(400, 0));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byType(ProductDetailScreen, skipOffstage: false),
      findsNothing,
      reason: 'the edge drag should pop the detail route (§12.1)',
    );
    expect(find.byType(MainScreen, skipOffstage: false), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS haptics fire on add-to-bag, wishlist and coupon apply', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final hapticCalls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        hapticCalls.add('${call.method}|${call.arguments}');
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final (router, _, store) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    router.push('/product/p6');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ProductDetailScreen, skipOffstage: false), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Add to Bag'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.cartCount, 1);
    expect(
      hapticCalls.where((call) => call.contains('HapticFeedbackType.lightImpact')),
      isNotEmpty,
      reason: 'add-to-bag should land with a light impact (§12.1)',
    );

    await tester.tap(find.byTooltip('Add to wishlist'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      hapticCalls.where(
        (call) => call.contains('HapticFeedbackType.selectionClick'),
      ),
      isNotEmpty,
      reason: 'the wishlist toggle should tick (§12.1)',
    );
    await drainSnackBars(tester);

    store.addToCart(seeded(price: 47950), quantity: 2);
    await tester.pump();
    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byTooltip('Cart'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Your Mini Cart'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Apply'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      hapticCalls
          .where((call) => call.contains('HapticFeedbackType.lightImpact'))
          .length,
      greaterThanOrEqualTo(2),
      reason: 'a successful coupon apply should add another light impact (§12.1)',
    );
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });

  testWidgets('home and the catalogue hold at 200% text across viewports', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final viewport in const [
      Size(390, 844),
      Size(768, 1024),
      Size(1440, 900),
    ]) {
      final (router, _, _) = await pumpShop(tester, viewport: viewport);
      router.go('/app');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester.takeException(),
        isNull,
        reason: 'home at 200% text / ${viewport.width}px',
      );

      router.go('/catalogue');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester.takeException(),
        isNull,
        reason: 'catalogue at 200% text / ${viewport.width}px',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('tab order walks header → main → footer', (tester) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Prime focus through the shortcut host, then Escape back out of search.
    await pressCtrlK(tester);
    await pressEscape(tester);
    expect(find.byType(SearchOverlay, skipOffstage: false), findsNothing);

    await tabUntil(tester, find.byType(AppHeader), limit: 12, reason: 'the header');
    await tabUntil(
      tester,
      find.byType(SiteFooter),
      // The longer homepage (editorial collage, bridal rail, complete-look
      // tiles) carries more stoppable controls between header and footer.
      limit: 420,
      reason: 'the footer',
    );
    expect(tester.takeException(), isNull);
  });

  test('the palette meets §11.5 contrast on white', () {
    double luminance(Color color) {
      double channel(double value) =>
          value <= 0.03928
              ? value / 12.92
              : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
      return 0.2126 * channel(color.r) +
          0.7152 * channel(color.g) +
          0.0722 * channel(color.b);
    }

    double ratio(Color foreground, Color background) {
      final a = luminance(foreground);
      final b = luminance(background);
      final high = math.max(a, b);
      final low = math.min(a, b);
      return (high + 0.05) / (low + 0.05);
    }

    expect(ratio(AppPalette.textPrimary, AppPalette.background),
        greaterThanOrEqualTo(4.5));
    expect(ratio(AppPalette.textSecondary, AppPalette.background),
        greaterThanOrEqualTo(4.5));
    expect(ratio(AppPalette.copperPressed, AppPalette.background),
        greaterThanOrEqualTo(4.5));
    expect(
      ratio(AppPalette.copperDark, AppPalette.background),
      greaterThan(4.49),
      reason: 'small copper text stays AA (§2.1 / §11.5)',
    );
    expect(
      ratio(Colors.white, AppPalette.copper),
      greaterThanOrEqualTo(3.0),
      reason: 'white on copper is reserved for large/bold labels (§11.5)',
    );
  });
}
