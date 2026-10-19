import 'package:common_widgets/common_widgets.dart';
import 'package:ecommerce_app/core/demo_catalog.dart';
import 'package:ecommerce_app/core/pricing.dart';
import 'package:ecommerce_app/core/product.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:ecommerce_app/features/product/screens/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/shop_harness.dart';

late CommerceStore store;

Widget _host(Widget child, BusinessConfigProvider provider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BusinessConfigProvider>.value(value: provider),
      ChangeNotifierProvider<CommerceStore>.value(value: store),
    ],
    child: MaterialApp(theme: provider.config.getTheme(), home: child),
  );
}

  /// The headline price is the only 26 px text on the detail page, which keeps
  /// the finder exact even when a rail below repeats the same amount.
  Finder headlinePrice() =>
      find.byWidgetPredicate((widget) => widget is Text && widget.style?.fontSize == 26);

  /// The rails below reuse [ProductImageCarousel] inside every card; only the
  /// detail page gallery wires up the zoom/tap handlers.
  Finder galleryCarousel() => find.byWidgetPredicate(
        (widget) => widget is ProductImageCarousel && widget.onImageTap != null,
      );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BusinessConfigProvider provider;
  late List<Product> catalog;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = BusinessConfigProvider();
    await provider.load();
    catalog = DemoCatalog.build(provider.config.categories);
    store = CommerceStore()..seedProducts(catalog);
  });

  Future<void> pumpDetail(WidgetTester tester, String id) async {
    await tester.pumpWidget(
      _host(ProductDetailScreen(productId: id), provider),
    );
    await tester.pump();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    // enterText/ensureVisible start a caret scroll (DrivenScrollActivity) in a
    // post-frame callback; while it runs the Scrollable ignores child pointers
    // and tap() would miss. Two short pumps let it start and settle, since the
    // test clock is otherwise frozen.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(finder);
    await tester.pump();
  }

  /// Reads the value cell of a breakup row by walking up to the row that
  /// pairs the label with its amount.
  String breakupValue(WidgetTester tester, String label) {
    final texts = tester
        .widgetList<Text>(
          find.descendant(
            of: find.ancestor(of: find.text(label), matching: find.byType(Row)),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data ?? '')
        .toList();
    expect(texts, hasLength(2), reason: 'row for "$label" should be label+value');
    return texts.last;
  }

  testWidgets('variant change updates price, sku and gallery', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final target = catalog.firstWhere(
      (p) => p.inStock && p.shades.length > 1 && p.images.length > 1,
    );
    final baseKarat = Pricing.karatOf(target.specs['Gold Purity'] ?? '')!;
    final shade = target.shades.firstWhere((s) {
      final index = target.shades.indexWhere((x) => x.name == s.name);
      return index > 0 && (Pricing.metalFactors[s.name] ?? 1.0) != 1.0;
    });
    final shadeOffset = target.shades.indexWhere((x) => x.name == shade.name);

    await pumpDetail(tester, target.id);

    expect(tester.widget<Text>(headlinePrice()).data, Pricing.money(target.price));
    expect(
      tester.widget<ProductImageCarousel>(galleryCarousel()).images,
      target.images,
    );

    await tapVisible(tester, find.text(shade.name));

    final shadeFactor = Pricing.metalFactors[shade.name]!;
    final afterShade = Pricing.scaled(target.price, shadeFactor);
    expect(tester.widget<Text>(headlinePrice()).data, Pricing.money(afterShade));
    expect(
      tester.widget<Text>(headlinePrice()).data,
      isNot(Pricing.money(target.price)),
    );
    expect(
      find.textContaining('Product Code: ${target.sku}-'),
      findsOneWidget,
      reason: 'the SKU picks up the chosen metal tone',
    );

    final cut = shadeOffset % target.images.length;
    final rotated = [
      ...target.images.sublist(cut),
      ...target.images.sublist(0, cut),
    ];
    expect(
      tester.widget<ProductImageCarousel>(galleryCarousel()).images,
      rotated,
      reason: 'the gallery lead image follows the selected tone',
    );

    await tapVisible(tester, find.text('14K'));

    final bothFactors = shadeFactor * 14 / baseKarat;
    final afterPurity = Pricing.scaled(target.price, bothFactors);
    expect(tester.widget<Text>(headlinePrice()).data, Pricing.money(afterPurity));
    final shadeInitials = shade.name
        .split(RegExp(r'\s+'))
        .map((word) => word[0].toUpperCase())
        .join();
    expect(
      find.textContaining('Product Code: ${target.sku}-$shadeInitials-14K'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('price breakup follows the selected variant', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final target = catalog.firstWhere(
      (p) => p.inStock && p.shades.length > 1,
    );
    await pumpDetail(tester, target.id);

    await tapVisible(tester, find.text('Price Breakup'));
    expect(find.text('Price Breakup'), findsOneWidget);

    final baseBreakup = Pricing.computeBreakup(
      target.price,
      specs: target.specs,
    );
    expect(
      breakupValue(tester, 'Gold value'),
      Pricing.money(baseBreakup.gold),
    );
    expect(breakupValue(tester, 'GST (18%)'), Pricing.money(baseBreakup.gst));
    expect(breakupValue(tester, 'Total'), Pricing.money(target.price));
    expect(
      baseBreakup.gold + baseBreakup.diamond + baseBreakup.making + baseBreakup.gst,
      target.price,
      reason: 'the table reconciles to the headline price',
    );

    final shade = target.shades.firstWhere((s) {
      final index = target.shades.indexWhere((x) => x.name == s.name);
      return index > 0 && (Pricing.metalFactors[s.name] ?? 1.0) != 1.0;
    });
    await tapVisible(tester, find.text(shade.name));

    final variantBreakup = Pricing.computeBreakup(
      Pricing.scaled(target.price, Pricing.metalFactors[shade.name]!),
      specs: target.specs,
    );
    expect(
      breakupValue(tester, 'Gold value'),
      Pricing.money(variantBreakup.gold),
    );
    expect(
      breakupValue(tester, 'Gold value'),
      isNot(Pricing.money(baseBreakup.gold)),
    );
    expect(
      breakupValue(tester, 'Total'),
      Pricing.money(Pricing.scaled(target.price, Pricing.metalFactors[shade.name]!)),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('tapping the CTA before picking a size only asks for it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final target = catalog.firstWhere(
      (p) => p.inStock && p.shades.isEmpty && p.sizes.isNotEmpty,
    );
    await pumpDetail(tester, target.id);

    expect(find.text('Select Size'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.text('Select Size'));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('Select a size'),
      ),
      findsOneWidget,
    );
    expect(store.cartCount, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('purity defaults to the listing karat and offers the rest', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final target = catalog.first;
    final baseKarat = Pricing.karatOf(target.specs['Gold Purity'] ?? '');
    expect(baseKarat, isNotNull);

    await pumpDetail(tester, target.id);

    final labelRow = tester
        .widgetList<Text>(
          find.descendant(
            of: find.ancestor(of: find.text('Purity'), matching: find.byType(Row)),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data ?? '')
        .toList();
    expect(labelRow.last, '${baseKarat}K');
    expect(find.text('14K'), findsOneWidget);

    await tapVisible(tester, find.text('14K'));
    final afterPurity = Pricing.scaled(
      target.price,
      Pricing.variantFactor(baseKarat: baseKarat, purity: 14),
    );
    expect(tester.widget<Text>(headlinePrice()).data, Pricing.money(afterPurity));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('pincode check answers a date and rejects short codes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpDetail(tester, catalog.first.id);

    final field = find.byType(TextField);
    await tester.enterText(field, '560001');
    await tester.pump();
    await tapVisible(tester, find.text('Check'));
    expect(find.textContaining('Delivery by '), findsOneWidget);

    await tester.enterText(field, '123');
    await tester.pump();
    await tapVisible(tester, find.text('Check'));
    expect(find.text('Enter a 6-digit pincode'), findsOneWidget);
    expect(find.textContaining('Delivery by '), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('rails fill in as more products are viewed', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final first = catalog.first;
    final second = catalog[1];

    await pumpDetail(tester, first.id);
    expect(find.text('You may also like'), findsOneWidget);
    expect(find.text('Recently viewed'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await pumpDetail(tester, second.id);
    expect(find.text('You may also like'), findsOneWidget);
    expect(find.text('Recently viewed'), findsOneWidget);
    expect(find.text(first.name), findsWidgets);
    if (catalog.any((p) => p.category != second.category)) {
      expect(find.text('Complete the look'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('sticky buy bar on compact, inline CTAs on desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final simple = catalog.firstWhere(
      (p) => !p.needsVariantSelection && p.inStock,
    );

    await pumpDetail(tester, simple.id);
    expect(find.text('Add to Bag'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).bottomNavigationBar,
      isNotNull,
      reason: 'compact keeps the sticky bar',
    );

    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    await pumpDetail(tester, simple.id);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).bottomNavigationBar,
      isNull,
      reason: 'desktop moves the CTAs into the page',
    );
    expect(find.text('Add to Bag'), findsOneWidget);
    expect(find.text('Buy Now'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('the detail page renders clean at 320 / 390 / 768 / 1440', (
    tester,
  ) async {
    for (final viewport in const [
      Size(320, 568),
      Size(390, 844),
      Size(768, 1024),
      Size(1440, 900),
    ]) {
      final (router, _, store) = await pumpShop(tester, viewport: viewport);
      final target = store.shopProducts.first;
      router.go('/product/${target.id}');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        tester.takeException(),
        isNull,
        reason: 'pdp at ${viewport.width}x${viewport.height}',
      );

      for (final section in const ['Price Breakup', 'Gold Details']) {
        final title = find.text(section);
        await tester.ensureVisible(title);
        await tester.pump();
        await tester.tap(title);
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: '$section open at ${viewport.width}x${viewport.height}',
        );
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}
