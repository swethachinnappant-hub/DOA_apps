import 'package:common_widgets/common_widgets.dart';
import 'package:ecommerce_app/core/demo_catalog.dart';
import 'package:ecommerce_app/core/models/user.dart';
import 'package:ecommerce_app/core/router/app_router.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/auth/providers/auth_provider.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:ecommerce_app/features/mini_cart/mini_cart_drawer.dart';
import 'package:ecommerce_app/features/owner/screens/owner_categories_screen.dart';
import 'package:ecommerce_app/features/shell/app_header.dart';
import 'package:ecommerce_app/features/shell/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/shop_harness.dart';

/// §3.1 layout parity: from a 320 px phone to a 1680 px wide desktop the
/// shell keeps every header action, the bottom-bar rule, a working path hop
/// and the hero geometry — with no overflow exceptions at any class.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewports = <String, Size>{
    'small phone': Size(320, 568),
    'phone': Size(390, 844),
    'phone landscape': Size(640, 360),
    'tablet': Size(768, 1024),
    'medium': Size(1024, 1366),
    'expanded': Size(1440, 900),
    'wide': Size(1680, 1050),
  };

  testWidgets('every layout class keeps the shell intact and reachable', (
    tester,
  ) async {
    for (final entry in viewports.entries) {
      SharedPreferences.setMockInitialValues({});
      final config = BusinessConfigProvider();
      await config.load();
      final store = CommerceStore()
        ..seedProducts(DemoCatalog.build(config.config.categories));
      final auth = AuthProvider()..signInAsDemo(UserRole.customer);
      final router = buildAppRouter(auth: auth);
      addTearDown(router.dispose);
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BusinessConfigProvider>.value(value: config),
            ChangeNotifierProvider<CommerceStore>.value(value: store),
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ],
          child: MaterialApp.router(
            theme: config.config.getTheme(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      router.go('/app');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final width = entry.value.width;
      final why = ' (${entry.key})';

      // Header actions survive at every class (search lives in the home
      // field below 1200; the desktop header keeps its own icon).
      expect(find.byType(AppHeader), findsOneWidget, reason: 'app bar$why');
      for (final tooltip in const ['Wishlist', 'Cart']) {
        expect(
          find.descendant(
            of: find.byType(AppHeader),
            matching: find.byTooltip(tooltip),
          ),
          findsOneWidget,
          reason: '$tooltip header action$why',
        );
      }
      expect(
        find.descendant(
          of: find.byType(AppHeader),
          matching: find.byTooltip('Search'),
        ),
        width >= Responsive.tabletMax ? findsOneWidget : findsNothing,
        reason: 'header search only above 1200$why',
      );
      if (width >= Responsive.tabletMax) {
        expect(
          find.text(store.headerMenus.first.label.toUpperCase()),
          findsOneWidget,
          reason: 'the horizontal nav replaces the menu button$why',
        );
      } else {
        expect(
          find.byTooltip('Menu'),
          findsOneWidget,
          reason: 'the menu button opens the drawer$why',
        );
      }

      // §5.5: the bottom bar only exists below 768.
      if (width < 768) {
        expect(find.byType(BottomBar), findsOneWidget, reason: 'tab bar$why');
      } else {
        expect(find.byType(BottomBar), findsNothing, reason: 'no tab bar$why');
      }

      // A path hop works the same way at every width: the header cart opens.
      await tester.tap(
        find.descendant(
          of: find.byType(AppHeader),
          matching: find.byTooltip('Cart'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(MiniCartBody), findsOneWidget, reason: 'cart$why');
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull, reason: 'no overflow$why');

      // Detach before the next viewport keeps a clean tree.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('the hero is a portrait rectangle on phones and a band above', (
    tester,
  ) async {
    Future<Rect> heroRect(Size viewport) async {
      // Detach the previous viewport so only one hero tree is mounted.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final (router, _, _) = await pumpShop(tester, viewport: viewport);
      router.go('/app');
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final hero = find.descendant(
        of: find.byKey(const Key('home-section-hero')),
        matching: find.byType(PageView),
      );
      expect(hero, findsOneWidget, reason: '$viewport keeps the hero');
      return tester.getRect(hero);
    }

    // Phone: the 390 × 400 hero spans the full width edge to edge.
    final phone = await heroRect(const Size(390, 844));
    expect(phone.width, closeTo(390, 0.5), reason: 'full width on phones');
    expect(phone.height, closeTo(400, 0.5), reason: 'tall on phones');
    expect(phone.width, lessThan(phone.height), reason: 'portrait rectangle');
    expect(phone.center.dx, closeTo(195, 1), reason: 'centred on the page');

    // Tablet: back to the full-width 224 band.
    final tablet = await heroRect(const Size(768, 1024));
    expect(tablet.height, closeTo(224, 0.5));
    expect(tablet.width, greaterThan(tablet.height));
    expect(tablet.width, closeTo(768, 0.5), reason: 'edge to edge');

    // Desktop: the wide 300 band across the full page width.
    final desktop = await heroRect(const Size(1440, 900));
    expect(desktop.height, closeTo(300, 0.5));
    expect(desktop.width, closeTo(1440, 0.5), reason: 'full width band');
    expect(desktop.width, greaterThan(desktop.height * 2));
  });

  testWidgets('the wide seller studio sidebar reaches its screens', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final config = BusinessConfigProvider();
    await config.load();
    final auth = AuthProvider()..signInAsDemo(UserRole.owner);
    final store = CommerceStore()
      ..seedProducts(DemoCatalog.build(config.config.categories));
    final router = buildAppRouter(auth: auth);
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(1680, 1050);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BusinessConfigProvider>.value(value: config),
          ChangeNotifierProvider<CommerceStore>.value(value: store),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp.router(
          theme: config.config.getTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    router.go('/owner');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // ≥ 600: the labelled sidebar replaces the NavigationBar + More sheet.
    expect(find.text('WORKSPACE'), findsOneWidget);
    expect(find.text('STOREFRONT'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Categories & Menu').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(OwnerCategoriesScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
