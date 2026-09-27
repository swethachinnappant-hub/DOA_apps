import 'package:ecommerce_app/core/demo_catalog.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/auth/providers/auth_provider.dart';
import 'package:ecommerce_app/features/checkout/screens/checkout_screen.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Checkout is the seam between the buyer's bag and the seller's queue: this
/// drives the real screen end to end and checks that pressing the button
/// produces an order both roles can then see.
void main() {
  late BusinessConfigProvider config;
  late CommerceStore store;
  late AuthProvider auth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    config = BusinessConfigProvider();
    await config.load();
    auth = AuthProvider();
    store = CommerceStore()
      ..seedProducts(DemoCatalog.build(config.config.categories));
  });

  testWidgets('placing an order empties the bag and opens the order page',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final a = store.shopProducts.first;
    final b = store.shopProducts.last;
    store.addToCart(a, quantity: 1);
    store.addToCart(b, quantity: 2);
    expect(store.cartCount, 3);

    final router = GoRouter(
      initialLocation: '/checkout',
      routes: [
        GoRoute(
          path: '/checkout',
          builder: (_, _) => const CheckoutScreen(),
        ),
        GoRoute(
          path: '/order/:id',
          builder: (_, state) =>
              Scaffold(body: Text('ORDER ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/app',
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BusinessConfigProvider>.value(value: config),
          ChangeNotifierProvider<CommerceStore>.value(value: store),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    // The summary has to be derived from the bag, not typed in.
    expect(find.text('Order summary'), findsOneWidget);
    expect(find.text('${a.name} × 1'), findsOneWidget);
    expect(find.text('${b.name} × 2'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final place = find.textContaining('Place order');
    await tester.ensureVisible(place);
    await tester.pump();
    await tester.tap(place);
    await tester.pumpAndSettle();

    expect(store.cart, isEmpty);
    expect(store.allOrders, hasLength(1));
    final order = store.allOrders.single;
    expect(order.itemCount, 3);
    expect(order.deliveryAddress, contains('Bengaluru'));
    expect(order.paymentMethod, 'UPI');
    expect(find.text('Order placed!'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Track order'));
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/order/${order.id}');
    expect(find.text('ORDER ${order.id}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('an empty bag cannot place an order', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/checkout',
      routes: [
        GoRoute(
          path: '/checkout',
          builder: (_, _) => const CheckoutScreen(),
        ),
        GoRoute(
          path: '/app',
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BusinessConfigProvider>.value(value: config),
          ChangeNotifierProvider<CommerceStore>.value(value: store),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(find.text('Nothing to check out'), findsOneWidget);
    expect(find.textContaining('Place order'), findsNothing);
    expect(store.allOrders, isEmpty);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
