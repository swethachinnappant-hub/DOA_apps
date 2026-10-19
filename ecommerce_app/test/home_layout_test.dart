import 'package:common_widgets/common_widgets.dart';
import 'package:ecommerce_app/core/demo_catalog.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/auth/providers/auth_provider.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:ecommerce_app/features/home/home_layout.dart';
import 'package:ecommerce_app/features/main_screen.dart';
import 'package:ecommerce_app/features/shell/site_footer.dart';
import 'package:ecommerce_app/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/shop_harness.dart';

/// Phase 4 gate (§16.3): the home page is an ordered `home_layout` list whose
/// skeleton hands over to content, and every tile in the stack navigates to a
/// real §4.3 route.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sectionOrder = <String>[
    'categories',
    'hero',
    'metal',
    'collections',
    'bestsellers',
    'newArrivals',
    'occasion',
    'price',
    'bridal',
    'gifts',
    'social',
    'about',
    'footer',
  ];

  Future<BusinessConfigProvider> loadConfig() async {
    SharedPreferences.setMockInitialValues({});
    final provider = BusinessConfigProvider();
    await provider.load();
    return provider;
  }

  Widget wrap(
    Widget home,
    BusinessConfigProvider config,
    CommerceStore store,
    AuthProvider auth,
  ) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BusinessConfigProvider>.value(value: config),
        ChangeNotifierProvider<CommerceStore>.value(value: store),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ],
      child: MaterialApp(
        theme: config.config.getTheme(),
        home: home,
      ),
    );
  }

  testWidgets('skeleton hands over to every §6.1 section, in order', (
    tester,
  ) async {
    final config = await loadConfig();
    final store = CommerceStore()
      ..seedProducts(DemoCatalog.build(config.config.categories));
    final auth = AuthProvider();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const MainScreen(), config, store, auth));
    await tester.pump();

    expect(
      find.byKey(const Key('home-skeleton')),
      findsOneWidget,
      reason: '§6.3: the skeleton must paint before content',
    );
    expect(find.byType(CategoryCarousel), findsNothing);
    expect(find.text('THE JEWELLERY EDIT'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('home-skeleton')), findsNothing);
    expect(find.byType(CategoryCarousel), findsOneWidget);
    expect(find.byType(SiteFooter), findsOneWidget);

    double? previousTop;
    for (final id in sectionOrder) {
      final section = find.byKey(Key('home-section-$id'));
      expect(section, findsOneWidget, reason: 'missing section $id');
      final top = tester.getTopLeft(section).dy;
      if (previousTop != null) {
        expect(
          top,
          greaterThan(previousTop),
          reason: 'section $id is out of §6.1 order',
        );
      }
      previousTop = top;
    }

    final extraSections = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key as ValueKey<String>).value.startsWith('home-section-'),
    );
    expect(
      extraSections.evaluate(),
      hasLength(sectionOrder.length),
      reason: 'the standard layout is exactly the 13 §6.1 sections',
    );
  });

  testWidgets('a custom HomeLayout reorders sections', (tester) async {
    final config = await loadConfig();
    final store = CommerceStore()
      ..seedProducts(DemoCatalog.build(config.config.categories));
    final auth = AuthProvider();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final layout = HomeLayout.standard().reorder(['about', 'price']);
    expect(
      layout.sections.take(2).map((section) => section.id),
      ['about', 'price'],
    );

    await tester.pumpWidget(
      wrap(MainScreen(layout: layout), config, store, auth),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final about = find.byKey(const Key('home-section-about'));
    final price = find.byKey(const Key('home-section-price'));
    final hero = find.byKey(const Key('home-section-hero'));
    expect(about, findsOneWidget);
    expect(price, findsOneWidget);
    expect(hero, findsOneWidget);
    expect(
      tester.getTopLeft(about).dy,
      lessThan(tester.getTopLeft(price).dy),
      reason: 'reorder() must honour the requested leading order',
    );
    expect(
      tester.getTopLeft(about).dy,
      lessThan(tester.getTopLeft(hero).dy),
      reason: 'reordered sections lead the stack',
    );
  });

  testWidgets('every home tile navigates to a real route', (tester) async {
    final (router, config, _) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );

    Future<void> openHome() async {
      router.go('/app');
      // Router → Navigator page swap needs a frame before the popped route
      // starts its exit, and the exit needs its own timed frame to finish.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await openHome();
    expect(find.byKey(const Key('home-skeleton')), findsNothing);

    // Expand the SEO accordion up front so its five H3 links are in the tree.
    final aboutSection = find.byKey(const Key('home-section-about'));
    await tester.ensureVisible(aboutSection);
    await tester.pump();
    await tester.ensureVisible(aboutSection);
    final aboutToggle = find.text('Online Diamond Jewellery Store');
    if (aboutToggle.evaluate().isNotEmpty) {
      await tester.tap(aboutToggle);
      await tester.pump(const Duration(milliseconds: 400));
    }

    bool isTileKey(String value) => value.startsWith('home-tile:');

    final processed = <String>{};
    var guard = 0;
    while (guard++ < 120) {
      await openHome();

      final keys = tester
          .widgetList(
            find.byWidgetPredicate(
              (widget) =>
                  widget.key is ValueKey<String> &&
                  isTileKey((widget.key as ValueKey<String>).value),
            ),
          )
          .map((widget) => (widget.key as ValueKey<String>).value)
          .toList();
      final pending = keys.where((key) => !processed.contains(key)).toList();
      if (pending.isEmpty) break;

      final key = pending.first;
      final tile = find.byKey(ValueKey<String>(key));
      if (tile.evaluate().isEmpty) {
        // A carousel page swapped underneath us — it is re-collected on the
        // next round when its page comes back around.
        continue;
      }

      final parts = key.substring('home-tile:'.length).split('|');
      final sectionId = parts[0];
      final route = parts.sublist(2).join('|');

      final section = find.byKey(Key('home-section-$sectionId'));
      expect(section, findsOneWidget, reason: 'tile $key has no section');
      await tester.ensureVisible(section);
      await tester.pump();
      await tester.ensureVisible(tile);
      await tester.pump();

      // A previous route's exit (or a carousel page change) can still be
      // covering the tile; give in-flight animations timed frames to settle
      // until the hit test actually reaches it.
      for (var attempt = 0; attempt < 4; attempt++) {
        if (tile.evaluate().isEmpty) break;
        final target = tester.renderObject(tile);
        final hit = tester.hitTestOnBinding(tester.getCenter(tile));
        if (hit.path.any((entry) => entry.target == target)) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 500));
        await tester.ensureVisible(tile);
        await tester.pump();
      }
      if (tile.evaluate().isEmpty) continue;

      await tester.tap(tile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull, reason: 'tapping $key threw');
      expect(
        router.state.uri.toString(),
        route,
        reason: 'tile $key did not open $route',
      );
      processed.add(key);
    }
    expect(processed, isNotEmpty);
    expect(processed.length, greaterThanOrEqualTo(20));

    // The category circles carry their own carousel keys, so they are walked
    // by label: whichever page of the rail is on screen must navigate.
    var categoryTaps = 0;
    for (final category in config.config.categories) {
      await openHome();
      final section = find.byKey(const Key('home-section-categories'));
      await tester.ensureVisible(section);
      await tester.pump();

      final circle = find.descendant(
        of: section,
        matching: find.text(category),
      );
      if (circle.evaluate().isEmpty) continue;
      await tester.ensureVisible(circle);
      await tester.pump();

      await tester.tap(circle, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull, reason: 'tapping $category');
      expect(
        router.state.uri.toString(),
        '/catalogue?category=${Uri.encodeQueryComponent(category)}',
        reason: 'category $category opened the wrong listing',
      );
      categoryTaps++;
    }
    expect(categoryTaps, greaterThan(0));

    // A product card deep in the bestsellers rail lands on its PDP.
    await openHome();
    final bestsellers = find.byKey(const Key('home-section-bestsellers'));
    await tester.ensureVisible(bestsellers);
    await tester.pump();
    final cards = find.descendant(
      of: bestsellers,
      matching: find.byType(ProductCard),
    );
    expect(cards, findsWidgets);
    await tester.ensureVisible(cards.first);
    await tester.pump();
    await tester.tap(cards.first, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(router.state.uri.toString(), startsWith('/product/'));
  });
}
