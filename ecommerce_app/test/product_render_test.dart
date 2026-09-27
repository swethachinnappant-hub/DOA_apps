import 'package:common_widgets/common_widgets.dart';
import 'package:ecommerce_app/core/demo_catalog.dart';
import 'package:ecommerce_app/core/product.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:ecommerce_app/features/product/screens/product_detail_screen.dart';
import 'package:ecommerce_app/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Product _product({
  int images = 4,
  bool discounted = true,
  bool variant = false,
  bool inStock = true,
}) {
  return Product(
    id: 'p1',
    name: 'Classic Oxford Shirt',
    brand: 'Acme',
    category: 'Men',
    sku: 'SKU-0001',
    price: discounted ? 1299 : 1499,
    mrp: discounted ? 2999 : 1499,
    rating: 4.4,
    reviewCount: 1284,
    images: List.generate(images, (i) => 'https://example.com/p1_$i.jpg'),
    badges: const ['Bestseller'],
    icon: Icons.checkroom,
    sizes: variant
        ? const [ProductVariant('S'), ProductVariant('M')]
        : const [],
    shades: variant
        ? const [ProductVariant('Ivory', swatch: Color(0xFFF5F1E6))]
        : const [],
    inStock: inStock,
    deliveryDays: 3,
  );
}

/// Shared with [ProductCard] hosts and the detail screen, which now reads the
/// catalogue and the bag from the same store the app uses.
late CommerceStore store;

Widget _host(Widget child, BusinessConfigProvider provider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BusinessConfigProvider>.value(value: provider),
      ChangeNotifierProvider<CommerceStore>.value(value: store),
    ],
    child: MaterialApp(
      theme: provider.config.getTheme(),
      home: child,
    ),
  );
}

void main() {
  late BusinessConfigProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = BusinessConfigProvider();
    await provider.load();
    store = CommerceStore()
      ..seedProducts(DemoCatalog.build(provider.config.categories));
  });

  group('Product model', () {
    test('computes discount metadata', () {
      final product = _product();
      expect(product.hasDiscount, isTrue);
      expect(product.discountPercent, greaterThan(0));
      expect(product.priceNote, contains('OFF'));
      expect(product.deliveryLabel, contains('3'));
    });

    test('reports no discount when price equals MRP', () {
      expect(_product(discounted: false).hasDiscount, isFalse);
    });

    test('detects required variant selection', () {
      expect(_product(variant: true).needsVariantSelection, isTrue);
      expect(_product().needsVariantSelection, isFalse);
    });

    test('catalog gives every product multiple images', () {
      final products = DemoCatalog.build(const ['Men', 'Women']);
      expect(products, isNotEmpty);
      for (final product in products) {
        expect(product.images.length, greaterThanOrEqualTo(3),
            reason: '${product.name} needs multiple angles');
      }
    });

    test('catalog resolves products by id', () {
      final products = DemoCatalog.build(const ['Men']);
      expect(DemoCatalog.byId(products, products.first.id)?.name,
          products.first.name);
      expect(DemoCatalog.byId(products, 'does-not-exist'), isNull);
      expect(DemoCatalog.byId(const [], 'p0'), isNull);
    });
  });

  group('ProductCard', () {
    testWidgets('shows brand, price, MRP and discount', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(
        Scaffold(
          body: SizedBox(
            width: 180,
            height: 320,
            child: ProductCard(
              product: _product(),
              primaryColor: const Color(0xFF1E3A5F),
              accentColor: const Color(0xFFE8EFF9),
              currency: '₹',
              showRating: true,
            ),
          ),
        ),
        provider,
      ));
      await tester.pump();

      expect(find.text('ACME'), findsOneWidget);
      expect(find.text('Classic Oxford Shirt'), findsOneWidget);
      expect(find.text('₹1299'), findsOneWidget);
      expect(find.text('₹2999'), findsOneWidget);
      expect(find.text('(1284)'), findsOneWidget);
      expect(find.text('57% OFF'), findsOneWidget);
      expect(find.text('BESTSELLER'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hides prices when the business requires enquiry',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // `flush()` touches the platform channel, which never completes under
      // the fake-async test zone, so run it on the real async loop.
      await tester.runAsync(() async {
        provider.updateSingleRule('showPrices', false);
        await provider.flush();
      });
      expect(provider.config.rules.showPrices, isFalse);

      await tester.pumpWidget(_host(
        Scaffold(
          body: SizedBox(
            width: 180,
            height: 320,
            child: ProductCard(
              product: _product(),
              primaryColor: const Color(0xFF1E3A5F),
              accentColor: const Color(0xFFE8EFF9),
              currency: '₹',
              // Same wiring the catalogue and home rail use.
              showPrice: provider.config.rules.showPrices,
            ),
          ),
        ),
        provider,
      ));
      await tester.pump();

      expect(find.text('Contact for Price'), findsOneWidget);
      expect(find.text('₹1299'), findsNothing);
      expect(find.text('₹2999'), findsNothing);
      expect(find.text('57% OFF'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('invokes the tap and wishlist callbacks', (tester) async {
      var taps = 0;
      var wishlists = 0;

      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(
        Scaffold(
          body: SizedBox(
            width: 180,
            height: 320,
            child: ProductCard(
              product: _product(),
              primaryColor: const Color(0xFF1E3A5F),
              accentColor: const Color(0xFFE8EFF9),
              onTap: () => taps++,
              onWishlist: () => wishlists++,
            ),
          ),
        ),
        provider,
      ));
      await tester.pump();

      await tester.tap(find.byType(ProductCard));
      await tester.pump();
      expect(taps, 1);

      await tester.tap(find.byType(WishlistButton));
      await tester.pump();
      expect(wishlists, 1);
    });

    testWidgets('lays out without overflow on a small phone', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(
        Scaffold(
          body: SizedBox(
            width: 150,
            height: 300,
            child: ProductCard(
              product: _product(),
              primaryColor: const Color(0xFF1E3A5F),
              accentColor: const Color(0xFFE8EFF9),
            ),
          ),
        ),
        provider,
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('ProductDetailScreen', () {
    // The detail page resolves its product from the shared store, so these
    // tests drive the real catalogue entries seeded into it.
    late List<Product> catalog;

    setUp(() {
      catalog = DemoCatalog.build(provider.config.categories);
      store.seedProducts(catalog);
    });

    Future<void> pumpDetail(WidgetTester tester, String id) async {
      await tester.pumpWidget(_host(
        ProductDetailScreen(productId: id),
        provider,
      ));
      await tester.pump();
    }

    testWidgets('asks for a variant before allowing add to bag',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final variantProduct = catalog.firstWhere((p) => p.needsVariantSelection);
      await pumpDetail(tester, variantProduct.id);

      // Shade + size are both required before the CTA unlocks. The selectors
      // sit below the gallery, so bring each one into view before tapping.
      if (variantProduct.shades.isNotEmpty) {
        expect(find.text('Select Shade'), findsOneWidget);
        final shade = find.text(variantProduct.shades.first.name);
        await tester.ensureVisible(shade);
        await tester.pump();
        await tester.tap(shade);
        await tester.pump();
      }
      if (variantProduct.sizes.isNotEmpty) {
        expect(find.text('Select Size'), findsOneWidget);
        final size = find.text(variantProduct.sizes.first.name);
        await tester.ensureVisible(size);
        await tester.pump();
        await tester.tap(size);
        await tester.pump();
      }
      expect(find.text('Add to Bag'), findsOneWidget);
    });

    testWidgets('enables add to bag when no variant is needed', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final simple = catalog.firstWhere(
        (p) => !p.needsVariantSelection && p.inStock,
      );
      await pumpDetail(tester, simple.id);
      expect(find.text('Add to Bag'), findsOneWidget);
    });

    testWidgets('renders the gallery and trust metadata', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final target = catalog.firstWhere((p) => p.images.length > 1);
      await pumpDetail(tester, target.id);

      // The gallery plus every related card in the rail carries a carousel.
      expect(find.byType(ProductImageCarousel), findsWidgets);
      expect(find.byType(ProductThumbnailRail), findsOneWidget);
      expect(find.text(target.name), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('marks out-of-stock products', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final soldOut = catalog.firstWhere((p) => !p.inStock);
      await pumpDetail(tester, soldOut.id);
      expect(find.textContaining('Out of stock'), findsWidgets);
    });

    testWidgets('shows a not-found state for an unknown id', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpDetail(tester, 'no-such-product');
      expect(find.text('Product unavailable'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
