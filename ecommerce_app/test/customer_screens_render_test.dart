import 'package:ecommerce_app/core/demo_catalog.dart';
import 'package:ecommerce_app/core/models/notification.dart';
import 'package:ecommerce_app/core/models/user.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/auth/providers/auth_provider.dart';
import 'package:ecommerce_app/features/cart/screens/cart_screen.dart';
import 'package:ecommerce_app/features/checkout/screens/checkout_screen.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:ecommerce_app/features/notifications/screens/notifications_screen.dart';
import 'package:ecommerce_app/features/orders/screens/order_detail_screen.dart';
import 'package:ecommerce_app/features/orders/screens/orders_screen.dart';
import 'package:ecommerce_app/features/product/screens/product_detail_screen.dart';
import 'package:ecommerce_app/features/profile/screens/profile_screen.dart';
import 'package:ecommerce_app/features/wishlist/screens/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders every screen that reads from the shared store at each viewport and
/// records any layout/paint error instead of failing on the first one, so a
/// single run reports all the overflow stripes at once.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewports = <String, Size>{
    'small phone 320x568': Size(320, 568),
    'phone 360x800': Size(360, 800),
    'landscape 640x360': Size(640, 360),
    'tablet 1024x1366': Size(1024, 1366),
  };

  testWidgets('store-backed customer screens render cleanly at every viewport',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final config = BusinessConfigProvider();
    await config.load();

    final auth = AuthProvider();
    final store = CommerceStore()
      ..seedProducts(DemoCatalog.build(config.config.categories));

    // Sign a customer in so the order, notification and profile screens are
    // rendered with the data they key off the session for.
    late String customerId;
    await tester.runAsync(() async {
      auth.signInAsDemo(UserRole.customer);
      await auth.flush();
    });
    customerId = auth.user?.id ?? '';

    // Build a bag and an order from it so the cart, checkout, order list and
    // order detail screens all have real records to lay out.
    final products = store.shopProducts;
    store.addToCart(products.first, quantity: 2);
    store.addToCart(products.last, quantity: 1);
    final order = store.placeOrder(
      customerId: customerId,
      customerName: auth.user?.name ?? 'Guest',
      deliveryAddress: '14 MG Road, Bengaluru, Karnataka 560001',
      paymentMethod: 'UPI',
    );
    store.addToCart(products.first, quantity: 1);
    store.toggleWishlist(products.last.id);
    store.pushNotification(AppNotification(
      id: 'ntf-render-1',
      type: NotificationType.orderStatus,
      title: 'Packed and ready',
      body: 'Order ${order?.id ?? ''} left the warehouse',
      audienceId: customerId,
      createdAt: DateTime(2026, 9, 26),
    ));

    final screens = <String, Widget>{
      'CartScreen': const CartScreen(),
      'CheckoutScreen': const CheckoutScreen(),
      'OrdersScreen': const OrdersScreen(),
      'OrderDetailScreen': OrderDetailScreen(orderId: order?.id ?? ''),
      'NotificationsScreen': const NotificationsScreen(),
      'WishlistScreen': const WishlistScreen(),
      'ProfileScreen': const ProfileScreen(),
      'ProductDetailScreen':
          ProductDetailScreen(productId: products.first.id),
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

      // Unmount so the carousel's auto-slide timers are cancelled.
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

    // The empty variants matter too: they have their own artwork and copy.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    store.clearCart();
    store.toggleWishlist(products.last.id);
    for (final entry in {
      'CartScreen (empty)': const CartScreen(),
      'CheckoutScreen (empty)': const CheckoutScreen(),
      'WishlistScreen (empty)': const WishlistScreen(),
    }.entries) {
      await render('${entry.key} @ phone 360x800', entry.value);
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();

    expect(failures, isEmpty, reason: failures.join('\n'));
  }, timeout: const Timeout(Duration(seconds: 180)));
}
