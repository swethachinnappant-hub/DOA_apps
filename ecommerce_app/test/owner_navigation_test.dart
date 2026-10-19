import 'package:ecommerce_app/core/demo_catalog.dart';
import 'package:ecommerce_app/core/models/user.dart';
import 'package:ecommerce_app/core/router/app_router.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/auth/providers/auth_provider.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:ecommerce_app/features/owner/screens/owner_categories_screen.dart';
import 'package:ecommerce_app/features/owner/screens/owner_collections_screen.dart';
import 'package:ecommerce_app/features/owner/screens/owner_coupons_screen.dart';
import 'package:ecommerce_app/features/owner/screens/owner_customers_screen.dart';
import 'package:ecommerce_app/features/owner/screens/owner_gold_rate_screen.dart';
import 'package:ecommerce_app/features/owner/screens/owner_home_builder_screen.dart';
import 'package:ecommerce_app/features/owner/screens/owner_order_detail_screen.dart';
import 'package:ecommerce_app/features/owner/screens/owner_product_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The seller console's paths, walked end to end rather than only rendered:
/// the quick action opens the form, the tabs move between branches, a listing
/// opens its edit screen, an order opens its detail, and the wide sidebar
/// reaches settings and the sign-out confirmation — every option navigates.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({GoRouter router, String productName, String orderId})> pumpOwner(
    WidgetTester tester, {
    required Size viewport,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final config = BusinessConfigProvider();
    await config.load();
    final auth = AuthProvider()..signInAsDemo(UserRole.owner);
    final ownerId = auth.user!.id;

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
      paymentMethod: 'Cash on Delivery',
    );

    final router = buildAppRouter(auth: auth);
    addTearDown(router.dispose);
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

    return (
      router: router,
      productName: listing.name,
      orderId: order?.id ?? '',
    );
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('the mobile console walks dashboard, form, lists and detail', (
    tester,
  ) async {
    final seeded = await pumpOwner(
      tester,
      viewport: const Size(390, 844),
    );
    final productName = seeded.productName;
    final orderId = seeded.orderId;
    expect(find.text('Shop studio'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);

    // Dashboard quick action opens the new-listing form.
    await tester.ensureVisible(find.text('Add product').first);
    await tester.pump();
    await tester.tap(find.text('Add product').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(OwnerProductFormScreen), findsOneWidget);
    expect(find.text('New product'), findsOneWidget);

    // Re-tapping the active branch tab resets it to the products list.
    await tapTab(tester, 'Products');
    expect(find.text('Products'), findsWidgets);
    expect(find.text(productName), findsOneWidget);

    // The seeded listing opens its edit form.
    await tester.ensureVisible(find.text(productName));
    await tester.tap(find.text(productName));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(OwnerProductFormScreen), findsOneWidget);
    expect(find.text('Edit product'), findsOneWidget);

    // The orders branch shows the seeded order; its row opens the detail.
    await tapTab(tester, 'Orders');
    expect(find.text('Asha Patel'), findsWidgets);
    await tester.ensureVisible(find.text('Details'));
    await tester.tap(find.text('Details'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(OwnerOrderDetailScreen), findsOneWidget);
    expect(find.text(orderId), findsWidgets);

    // And back to the dashboard through the first tab.
    await tapTab(tester, 'Dashboard');
    expect(find.text('Shop studio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the wide sidebar reaches settings and sign out', (
    tester,
  ) async {
    await pumpOwner(tester, viewport: const Size(1024, 1366));
    expect(find.text('Shop studio'), findsOneWidget);
    expect(find.text('WORKSPACE'), findsOneWidget);
    expect(
      find.byType(NavigationBar),
      findsNothing,
      reason: 'the sidebar replaces the bar at >= 600',
    );

    await tester.tap(find.text('Shop settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Your account'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('Your account'),
      findsNothing,
      reason: 'system back should leave the pushed profile',
    );
    expect(find.text('Shop studio'), findsOneWidget);

    await tester.tap(
      find.ancestor(
        of: find.text('Leave seller studio'),
        matching: find.byType(InkWell),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.text('Stay signed in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Sign out?'), findsNothing);
    expect(find.text('Shop studio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the mobile More sheet reaches every storefront screen', (
    tester,
  ) async {
    await pumpOwner(tester, viewport: const Size(390, 844));

    const screens = <(String, Type)>[
      ('Categories & Menu', OwnerCategoriesScreen),
      ('Collections', OwnerCollectionsScreen),
      ('Home Builder', OwnerHomeBuilderScreen),
      ('Coupons', OwnerCouponsScreen),
      ('Gold rate', OwnerGoldRateScreen),
      ('Customers', OwnerCustomersScreen),
    ];

    for (final (label, type) in screens) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('More'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text(label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(type), findsOneWidget, reason: label);
      expect(tester.takeException(), isNull, reason: label);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(type), findsNothing, reason: '$label should pop');
      expect(find.text('Shop studio'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
