import 'package:ecommerce_app/core/catalog_repository.dart';
import 'package:ecommerce_app/core/demo_catalog.dart';
import 'package:ecommerce_app/core/models/cms.dart';
import 'package:ecommerce_app/core/models/coupon.dart';
import 'package:ecommerce_app/core/models/user.dart';
import 'package:ecommerce_app/core/router/app_router.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/auth/providers/auth_provider.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:ecommerce_app/features/home/home_sections.dart';
import 'package:ecommerce_app/features/owner/screens/owner_dashboard_screen.dart';
import 'package:ecommerce_app/features/owner/screens/owner_orders_screen.dart';
import 'package:ecommerce_app/features/owner/screens/owner_product_form_screen.dart';
import 'package:ecommerce_app/features/owner/screens/owner_products_screen.dart';
import 'package:ecommerce_app/features/profile/screens/coupons_screen.dart';
import 'package:ecommerce_app/features/shell/app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SPEC-18/21: the seller console's new edits persist through
/// [CatalogRepository] and land in the customer app with no restart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Hosts [home] with the same providers the app installs.
  Future<AuthProvider> pumpHost(
    WidgetTester tester, {
    required Widget Function() home,
    required CommerceStore store,
    Size viewport = const Size(800, 600),
    bool signInOwner = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final config = BusinessConfigProvider();
    await config.load();
    final auth = AuthProvider();
    if (signInOwner) auth.signInAsDemo(UserRole.owner);

    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BusinessConfigProvider>.value(value: config),
          ChangeNotifierProvider<CommerceStore>.value(value: store),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp(
          theme: config.config.getTheme(),
          home: home(),
        ),
      ),
    );
    await tester.pump();
    return auth;
  }

  group('owner edits reflect for customers (SPEC-21)', () {
    testWidgets('a renamed and a hidden desktop menu swap without a restart', (
      tester,
    ) async {
      final store = CommerceStore();
      final route = store.navHeaderKeys.first;
      final hiddenRoute = store.navHeaderKeys[1];
      final originalFirst = store.headerMenus.first.label;
      final hiddenLabel = store.headerMenus[1].label;

      await pumpHost(
        tester,
        store: store,
        viewport: const Size(1440, 600),
        home: () => Scaffold(body: AppHeader(onMenu: () {})),
      );
      expect(find.text(originalFirst.toUpperCase()), findsWidgets);

      store.setNavLabel(route, 'Rare Finds');
      await tester.pump();
      expect(find.text('RARE FINDS'), findsOneWidget);
      expect(find.text(originalFirst.toUpperCase()), findsNothing);

      store.setNavVisible(hiddenRoute, false);
      await tester.pump();
      expect(find.text(hiddenLabel.toUpperCase()), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a coupon published in the studio shows in the wallet', (
      tester,
    ) async {
      final store = CommerceStore();
      await pumpHost(
        tester,
        store: store,
        home: () => const CouponsScreen(),
      );
      expect(find.text('FESTIVE50'), findsNothing);

      store.upsertCoupon(
        const Coupon(
          code: 'FESTIVE50',
          flatOffInr: 2500,
          minSubtotal: 15000,
          description: 'Festival savings',
        ),
      );
      await tester.pump();
      expect(find.text('FESTIVE50'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('collection renames and additions show on the home rail', (
      tester,
    ) async {
      final store = CommerceStore();
      await pumpHost(
        tester,
        store: store,
        home: () => Scaffold(
          body: Center(
            child: SizedBox(width: 520, child: CollectionsRail()),
          ),
        ),
      );
      final first = store.visibleCollections.first;
      expect(find.text(first.name), findsOneWidget);

      store.upsertCollection(
        ShopCollection(id: first.id, name: 'Rare Hearts', route: first.route),
      );
      await tester.pump();
      expect(find.text('Rare Hearts'), findsOneWidget);
      expect(find.text(first.name), findsNothing);

      store.upsertCollection(
        ShopCollection(
          id: 'midnight-edit',
          name: 'Midnight Edit',
          route: '/collections/midnight-edit',
        ),
      );
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Midnight Edit'), 140);
      expect(find.text('Midnight Edit'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('dashboard additions (SPEC-18)', () {
    testWidgets("today's orders, coupon redemptions, top sellers and low stock", (
      tester,
    ) async {
      final auth = AuthProvider()..signInAsDemo(UserRole.owner);
      final ownerId = auth.user!.id;
      final config = BusinessConfigProvider();
      await config.load();
      final store = CommerceStore()
        ..seedProducts(DemoCatalog.build(config.config.categories));
      final listing = store.shopProducts.first.copyWith(
        ownerId: ownerId,
        stock: 2,
        createdAt: DateTime(2026, 9, 25),
      );
      store.publishProduct(listing);
      store.addToCart(listing, quantity: 2);
      store.placeOrder(
        customerId: 'cust-1',
        customerName: 'Asha Patel',
        deliveryAddress: '14 MG Road, Bengaluru, Karnataka 560001',
        paymentMethod: 'Cash on Delivery',
      );

      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(600, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BusinessConfigProvider>.value(
              value: config,
            ),
            ChangeNotifierProvider<CommerceStore>.value(value: store),
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ],
          child: MaterialApp(
            theme: config.config.getTheme(),
            home: const OwnerDashboardScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text("Today's orders"), findsOneWidget);
      expect(find.text('Coupon redemptions'), findsOneWidget);
      expect(find.text('Top products'), findsOneWidget);
      expect(find.text('Low stock'), findsWidgets);
      expect(find.text(listing.name), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('orders filter and CSV export (SPEC-18)', () {
    testWidgets('search narrows both tabs and the export carries the set', (
      tester,
    ) async {
      final auth = AuthProvider()..signInAsDemo(UserRole.owner);
      final ownerId = auth.user!.id;
      final config = BusinessConfigProvider();
      await config.load();
      final store = CommerceStore()
        ..seedProducts(DemoCatalog.build(config.config.categories));
      final listing = store.shopProducts.first.copyWith(
        ownerId: ownerId,
        stock: 8,
        createdAt: DateTime(2026, 9, 25),
      );
      store.publishProduct(listing);
      store.addToCart(listing, quantity: 2);
      final order = store.placeOrder(
        customerId: 'cust-1',
        customerName: 'Asha Patel',
        deliveryAddress: '14 MG Road, Bengaluru, Karnataka 560001',
        paymentMethod: 'UPI',
      );

      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BusinessConfigProvider>.value(
              value: config,
            ),
            ChangeNotifierProvider<CommerceStore>.value(value: store),
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ],
          child: MaterialApp(
            theme: config.config.getTheme(),
            home: const OwnerOrdersScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final orderId = order?.id ?? '';
      expect(orderId, isNotEmpty);
      expect(find.text(orderId), findsOneWidget);
      expect(find.text('Asha Patel'), findsOneWidget);

      final filter = find.byType(TextField);
      await tester.enterText(filter, 'zzz');
      await tester.pump();
      expect(find.text('All caught up'), findsOneWidget);
      expect(find.text(orderId), findsNothing);

      await tester.enterText(filter, 'asha');
      await tester.pump();
      expect(find.text(orderId), findsOneWidget);

      await tester.enterText(filter, '');
      await tester.pump();
      await tester.tap(find.byTooltip('Export CSV'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Export CSV (1 order(s))'), findsOneWidget);
      final csvView = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(csvView.data, contains('Order ID,Customer'));
      expect(csvView.data, contains(orderId));
      expect(csvView.data, contains('Asha Patel'));
      expect(find.text('Copy CSV'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Export CSV (1 order(s))'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('product form gains (SPEC-18)', () {
    testWidgets('family, occasions, slug and SEO title survive a save', (
      tester,
    ) async {
      final auth = AuthProvider()..signInAsDemo(UserRole.owner);
      final ownerId = auth.user!.id;
      final config = BusinessConfigProvider();
      await config.load();
      final store = CommerceStore()
        ..seedProducts(DemoCatalog.build(config.config.categories));
      final listing = store.shopProducts.first.copyWith(
        ownerId: ownerId,
        stock: 8,
        createdAt: DateTime(2026, 9, 25),
      );
      store.publishProduct(listing);

      final router = buildAppRouter(auth: auth);
      addTearDown(router.dispose);
      // Tall viewport: the whole form fits on screen, so every section is
      // built and the save button is hit-testable without scrolling.
      tester.view.physicalSize = const Size(1440, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BusinessConfigProvider>.value(
              value: config,
            ),
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
      router.go('/owner/products/${listing.id}/edit');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(OwnerProductFormScreen), findsOneWidget);
      expect(find.text('Edit product'), findsOneWidget);
      expect(find.text('Merchandising'), findsOneWidget);
      expect(find.text('Search & SEO'), findsOneWidget);

      // Category then Family/Style/Metal/Purity/Audience/Badge.
      final dropdowns = find.byType(DropdownButtonFormField<String>);
      expect(dropdowns, findsNWidgets(7));
      await tester.tap(dropdowns.at(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Rings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Wedding'));
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey('product-slug')),
        'ruby-solitaire-ring',
      );
      await tester.enterText(
        find.byKey(const ValueKey('product-seo-title')),
        'Ruby Solitaire Ring',
      );

      await tester.tap(find.text('Save changes').hitTestable());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(OwnerProductsScreen), findsOneWidget);
      final saved = store.productById(listing.id)!;
      expect(saved.family, 'Rings');
      expect(saved.occasions, contains('Wedding'));
      expect(saved.slug, 'ruby-solitaire-ring');
      expect(saved.seoTitle, 'Ruby Solitaire Ring');
      expect(tester.takeException(), isNull);
    });
  });

  group('CMS persistence (CatalogRepository)', () {
    test('every edit class round-trips through the repository', () async {
      final repo = _MemoryRepository();
      final store = CommerceStore(repository: repo);

      final firstRoute = store.navHeaderKeys.first;
      final swappedRoute = store.navHeaderKeys[1];
      final drawerCount = store.drawerMenus.length;
      // Nav patches are keyed by route and shared across views, so hiding
      // must target a route the desktop header does not render.
      final drawerOnlyKeys = [
        for (final route in store.navDrawerKeys)
          if (!store.navHeaderKeys.contains(route)) route,
      ];
      expect(drawerOnlyKeys, isNotEmpty);

      store.setNavLabel(firstRoute, 'Rare Finds');
      store.moveNavEntry('header', 1, -1);
      store.setNavVisible(drawerOnlyKeys.first, false);
      store.upsertCoupon(
        const Coupon(
          code: 'FESTIVE50',
          flatOffInr: 2500,
          minSubtotal: 15000,
        ),
      );
      store.upsertCollection(
        ShopCollection(
          id: 'midnight-edit',
          name: 'Midnight Edit',
          route: '/collections/midnight-edit',
        ),
      );
      store.setRates(
        goldPerGram: 7250,
        silverPerGram: 89,
        platinumPerGram: 3100,
        at: DateTime(2026, 10, 11, 9, 30),
      );
      store.adjustLoyalty('cus-asha', 100, 'Festive bonus');
      await store.flushCms();
      expect(repo.saved, isNotNull);

      final reloaded = CommerceStore(repository: repo);
      await reloaded.loadCms();

      expect(reloaded.navHeaderKeys.first, swappedRoute);
      expect(reloaded.navHeaderKeys[1], firstRoute);
      expect(reloaded.headerMenus[1].label, 'Rare Finds');
      expect(reloaded.drawerMenus.length, drawerCount - 1);
      expect(
        reloaded.coupons.map((c) => c.code),
        contains('FESTIVE50'),
      );
      expect(
        reloaded.collections.any((c) => c.id == 'midnight-edit'),
        isTrue,
      );
      expect(reloaded.hasRates, isTrue);
      expect(reloaded.goldRateInrPerGram, 7250);
      expect(reloaded.silverRateInrPerGram, 89);
      expect(reloaded.platinumRateInrPerGram, 3100);
      expect(reloaded.ratesUpdatedAt, DateTime(2026, 10, 11, 9, 30));
      expect(reloaded.loyaltyLedgerFor('cus-asha'), hasLength(1));
      expect(reloaded.loyaltyLedgerFor('cus-asha').single.delta, 100);
    });

    test('a store without a saved payload keeps the verified defaults', () async {
      final repo = _MemoryRepository();
      final store = CommerceStore(repository: repo);
      await store.loadCms();

      expect(store.navHeaderKeys, isNotEmpty);
      expect(store.drawerMenus, isNotEmpty);
      expect(store.coupons, isNotEmpty);
      // The demo-start board keeps the rate strip populated from first
      // launch until the owner saves today's numbers.
      expect(store.hasRates, isTrue);
      expect(store.goldRateInrPerGram, CommerceStore.defaultGoldRateInrPerGram);
      expect(store.silverRateInrPerGram, CommerceStore.defaultSilverRateInrPerGram);
      expect(
        store.platinumRateInrPerGram,
        CommerceStore.defaultPlatinumRateInrPerGram,
      );
      expect(store.ratesUpdatedAt, isNull);
    });

    test('the local repository keeps one JSON blob in shared preferences', () async {
      SharedPreferences.setMockInitialValues({});
      const repo = LocalCatalogRepository();
      expect(await repo.read(), isNull);

      await repo.write({
        'v': 1,
        'navHeaderKeys': ['/diamond-jewellery'],
        'coupons': [
          const Coupon(code: 'FESTIVE50', flatOffInr: 2500, minSubtotal: 15000)
              .toJson(),
        ],
      });
      final back = await repo.read();
      expect(back?['v'], 1);
      expect(back?['navHeaderKeys'], ['/diamond-jewellery']);

      await repo.clear();
      expect(await repo.read(), isNull);
    });
  });
}

/// In-memory stand-in for [CatalogRepository] so the round trip is observable
/// without touching SharedPreferences.
class _MemoryRepository implements CatalogRepository {
  Map<String, Object?>? saved;

  @override
  Future<Map<String, Object?>?> read() async => saved;

  @override
  Future<void> write(Map<String, Object?> payload) async {
    saved = payload;
  }

  @override
  Future<void> clear() async {
    saved = null;
  }
}
