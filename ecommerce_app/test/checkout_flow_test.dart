import 'package:common_widgets/common_widgets.dart';
import 'package:ecommerce_app/core/demo_catalog.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/auth/providers/auth_provider.dart';
import 'package:ecommerce_app/features/cart/screens/cart_screen.dart';
import 'package:ecommerce_app/features/checkout/order_success_screen.dart';
import 'package:ecommerce_app/features/checkout/screens/checkout_screen.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Checkout is the seam between the buyer's bag and the seller's queue: this
/// drives the §9.3 five-step screen end to end and checks that pressing the
/// button produces an order both roles can then see.
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

  Future<void> pumpHost(WidgetTester tester, GoRouter router) async {
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
  }

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

  GoRouter buildRouter({String initialLocation = '/checkout'}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/checkout',
          builder: (_, _) => const CheckoutScreen(),
        ),
        GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
        GoRoute(
          path: '/order-success/:id',
          builder: (_, state) => OrderSuccessScreen(
            orderId: state.pathParameters['id'] ?? '',
          ),
        ),
        GoRoute(
          path: '/order/:id',
          builder: (_, state) =>
              Scaffold(body: Text('ORDER ${state.pathParameters['id']}')),
        ),
        GoRoute(path: '/app', builder: (_, _) => const Scaffold(body: Text('HOME'))),
      ],
    );
  }

  testWidgets('walking the five steps places the order and reaches success', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final a = store.shopProducts.first;
    final b = store.shopProducts.last;
    store.addToCart(a, quantity: 1);
    store.addToCart(b, quantity: 2);
    expect(store.cartCount, 3);

    final router = buildRouter();
    addTearDown(router.dispose);
    await pumpHost(tester, router);

    // Step 1 — sign in or guest.
    expect(find.text('Continue as guest'), findsOneWidget);
    expect(find.text('Order summary'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tapVisible(tester, find.widgetWithText(AppButton, 'Continue'));

    // Step 2 — address.
    expect(find.text('Delivery address'), findsOneWidget);
    expect(find.text('14 MG Road, Bengaluru, Karnataka 560001'), findsOneWidget);
    await tapVisible(tester, find.widgetWithText(AppButton, 'Continue'));

    // Step 3 — delivery.
    expect(find.text('Standard delivery'), findsOneWidget);
    expect(find.text('Priority delivery'), findsOneWidget);
    await tapVisible(tester, find.widgetWithText(AppButton, 'Continue'));

    // Step 4 — payment, and a different method than the default.
    expect(find.text('Credit/Debit Card'), findsOneWidget);
    await tester.tap(find.text('Credit/Debit Card'));
    await tester.pump();
    await tapVisible(tester, find.widgetWithText(AppButton, 'Continue'));

    // Step 5 — review quotes the bag, the address and the choices.
    expect(find.text('${a.name} × 1'), findsWidgets);
    expect(find.text('${b.name} × 2'), findsWidgets);
    expect(find.text('Ship to'), findsOneWidget);
    expect(find.text('14 MG Road, Bengaluru, Karnataka 560001'), findsOneWidget);
    expect(find.text('Credit/Debit Card'), findsOneWidget);
    expect(find.text('Sub Total (before tax)'), findsWidgets);
    expect(find.text('Grand Total'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tapVisible(tester, find.textContaining('Place order'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The success page takes over and the bag is empty.
    expect(store.cart, isEmpty);
    expect(store.allOrders, hasLength(1));
    final order = store.allOrders.single;
    expect(order.itemCount, 3);
    expect(order.deliveryAddress, contains('Bengaluru'));
    expect(order.paymentMethod, 'Credit/Debit Card');
    expect(find.text('Order placed!'), findsOneWidget);
    expect(find.textContaining(order.id), findsWidgets);
    expect(tester.takeException(), isNull);

    await tapVisible(tester, find.widgetWithText(AppButton, 'Track order'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(router.state.uri.toString(), '/order/${order.id}');
    expect(find.text('ORDER ${order.id}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 90)));

  testWidgets('desktop keeps a sticky summary beside the steps', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    store.addToCart(store.shopProducts.first, quantity: 2);

    final router = buildRouter();
    addTearDown(router.dispose);
    await pumpHost(tester, router);

    expect(find.text('ORDER SUMMARY'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tapVisible(tester, find.widgetWithText(AppButton, 'Continue'));
    expect(find.text('Delivery address'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    await tapVisible(tester, find.widgetWithText(AppButton, 'Continue'));
    expect(find.text('Delivery option'), findsOneWidget);
    await tapVisible(tester, find.widgetWithText(AppButton, 'Continue'));
    expect(find.text('Payment method'), findsOneWidget);
    await tapVisible(tester, find.widgetWithText(AppButton, 'Continue'));
    expect(find.text('Ship to'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tapVisible(tester, find.textContaining('Place order'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(store.cart, isEmpty);
    expect(store.allOrders, hasLength(1));
    expect(find.text('Order placed!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 90)));

  testWidgets('an empty bag is bounced to the cart', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = buildRouter();
    addTearDown(router.dispose);
    await pumpHost(tester, router);

    // The redirect fires from a post-frame callback, so pump until the cart
    // route has actually replaced the checkout page.
    var settled = 0;
    while (find.byType(CheckoutScreen).evaluate().isNotEmpty && settled < 20) {
      await tester.pump(const Duration(milliseconds: 200));
      settled++;
    }
    await tester.pump();

    expect(router.state.uri.toString(), '/cart');
    expect(find.byType(CartScreen), findsOneWidget);
    expect(find.text('Your bag is empty'), findsOneWidget);
    expect(find.text('Nothing to check out'), findsNothing);
    expect(store.allOrders, isEmpty);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
