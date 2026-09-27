import 'package:ecommerce_app/core/demo_catalog.dart';
import 'package:ecommerce_app/core/models/notification.dart';
import 'package:ecommerce_app/core/models/user.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/auth/providers/auth_provider.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:ecommerce_app/features/owner/screens/owner_dashboard_screen.dart';
import 'package:ecommerce_app/features/owner/screens/owner_order_detail_screen.dart';
import 'package:ecommerce_app/features/owner/screens/owner_orders_screen.dart';
import 'package:ecommerce_app/features/owner/screens/owner_product_form_screen.dart';
import 'package:ecommerce_app/features/owner/screens/owner_products_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Same viewport sweep for the seller console: the dashboard, inventory,
/// listing form and fulfilment queue all have to fit from a 320px phone up to
/// a tablet without a single overflow stripe.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewports = <String, Size>{
    'small phone 320x568': Size(320, 568),
    'phone 360x800': Size(360, 800),
    'landscape 640x360': Size(640, 360),
    'tablet 1024x1366': Size(1024, 1366),
  };

  testWidgets('store-backed owner screens render cleanly at every viewport',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final config = BusinessConfigProvider();
    await config.load();

    final auth = AuthProvider();
    late String ownerId;
    await tester.runAsync(() async {
      auth.signInAsDemo(UserRole.owner);
      await auth.flush();
    });
    ownerId = auth.user?.id ?? '';

    final store = CommerceStore()
      ..seedProducts(DemoCatalog.build(config.config.categories));

    // One listing the signed-in seller owns, and one order against it, so the
    // inventory and fulfilment screens are not rendered empty.
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
    store.pushNotification(AppNotification(
      id: 'ntf-owner-render-1',
      type: NotificationType.orderPlaced,
      title: 'New order',
      body: 'Order ${order?.id ?? ''} needs packing',
      audienceId: ownerId,
      createdAt: DateTime(2026, 9, 26),
    ));

    final screens = <String, Widget>{
      'OwnerDashboardScreen': const OwnerDashboardScreen(),
      'OwnerProductsScreen': const OwnerProductsScreen(),
      'OwnerProductFormScreen (new)': const OwnerProductFormScreen(
        productId: null,
      ),
      'OwnerProductFormScreen (edit)':
          OwnerProductFormScreen(productId: listing.id),
      'OwnerOrdersScreen': const OwnerOrdersScreen(),
      'OwnerOrderDetailScreen':
          OwnerOrderDetailScreen(orderId: order?.id ?? ''),
    };

    final failures = <String>[];

    Future<void> render(String label, Widget child) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BusinessConfigProvider>.value(value: config),
            ChangeNotifierProvider<CommerceStore>.value(value: store),
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ],
          child: MaterialApp(
            theme: config.config.getTheme(),
            home: child,
          ),
        ),
      );
      await tester.pump();

      final error = tester.takeException();
      if (error != null) failures.add('$label: $error');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    for (final viewport in viewports.entries) {
      tester.view.physicalSize = viewport.value;
      tester.view.devicePixelRatio = 1.0;

      for (final screen in screens.entries) {
        await render('${screen.key} @ ${viewport.key}', screen.value);
      }
    }

    // The zero-state artwork is its own layout, so render it too.
    final blank = CommerceStore();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    for (final entry in {
      'OwnerDashboardScreen (empty)': const OwnerDashboardScreen(),
      'OwnerProductsScreen (empty)': const OwnerProductsScreen(),
      'OwnerOrdersScreen (empty)': const OwnerOrdersScreen(),
    }.entries) {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BusinessConfigProvider>.value(value: config),
            ChangeNotifierProvider<CommerceStore>.value(value: blank),
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ],
          child: MaterialApp(
            theme: config.config.getTheme(),
            home: entry.value,
          ),
        ),
      );
      await tester.pump();
      final error = tester.takeException();
      if (error != null) failures.add('${entry.key}: $error');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();

    expect(failures, isEmpty, reason: failures.join('\n'));
  }, timeout: const Timeout(Duration(seconds: 180)));
}
