import 'package:ecommerce_app/core/demo_catalog.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:ecommerce_app/features/wishlist/screens/wishlist_screen.dart';
import 'package:ecommerce_app/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The heart on a card, the heart on the detail page and this screen all read
/// the same set in [CommerceStore], so saving in one place has to show up in
/// the other two without a reload.
void main() {
  late BusinessConfigProvider config;
  late CommerceStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    config = BusinessConfigProvider();
    await config.load();
    store = CommerceStore()
      ..seedProducts(DemoCatalog.build(config.config.categories));
  });

  Widget host(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BusinessConfigProvider>.value(value: config),
        ChangeNotifierProvider<CommerceStore>.value(value: store),
      ],
      child: MaterialApp(
        theme: config.config.getTheme(),
        home: child,
      ),
    );
  }

  testWidgets('the wishlist screen mirrors what the store has saved',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final saved = store.shopProducts.first;
    store.toggleWishlist(saved.id);

    await tester.pumpWidget(host(const WishlistScreen()));
    await tester.pump();

    expect(find.text(saved.name), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The trailing delete control removes it and drops to the empty state.
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();

    expect(store.wishlistCount, 0);
    expect(find.text('No items in wishlist'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty wishlist explains how to fill it', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(const WishlistScreen()));
    await tester.pump();

    expect(find.text('No items in wishlist'), findsOneWidget);
    expect(find.textContaining('Tap the heart'), findsOneWidget);
    expect(find.byIcon(Icons.delete_sweep_outlined), findsNothing);
  });

  testWidgets('a card heart driven by the store flips in place',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final product = store.shopProducts.first;
    expect(store.isWishlisted(product.id), isFalse);

    await tester.pumpWidget(
      host(
        SizedBox(
          width: 180,
          height: 320,
          child: Consumer<CommerceStore>(
            builder: (context, value, _) => ProductCard(
              product: product,
              primaryColor: config.config.primaryColor,
              accentColor: config.config.accentColor,
              liked: value.isWishlisted(product.id),
              onWishlist: () => value.toggleWishlist(product.id),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);

    await tester.tap(find.byType(WishlistButton));
    await tester.pump();

    expect(store.isWishlisted(product.id), isTrue);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
