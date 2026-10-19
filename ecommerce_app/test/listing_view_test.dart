import 'package:ecommerce_app/core/demo_catalog.dart';
import 'package:ecommerce_app/core/navigation/menu_data.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/catalogue/listing_view.dart';
import 'package:ecommerce_app/features/catalogue/route_scope.dart';
import 'package:ecommerce_app/features/catalogue/screens/catalogue_screen.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:ecommerce_app/features/shell/site_footer.dart';
import 'package:ecommerce_app/widgets/product_card.dart';
import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/shop_harness.dart';

/// Phase 5 gate (§16.3): the shared listing surface (§7) serves every shop
/// path from the nav registry, pages past the first 24 designs, switches the
/// filter placement across breakpoints and honours the metal deep link.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Every route reachable from the desktop nav, drawer nav and footer —
  /// the same coverage route_map_test walks, restricted here to the paths
  /// that should resolve to the listing surface.
  Set<String> allListingPaths() {
    final paths = <String>{};
    void addMenu(NavMenu menu) {
      paths.add(menu.route);
      for (final tile in menu.tiles) {
        paths.add(tile.route);
      }
      for (final group in menu.groups) {
        for (final link in group.links) {
          paths.add(link.route);
        }
      }
      for (final category in menu.categories) {
        paths.add(category.route);
        for (final group in category.groups) {
          for (final link in group.links) {
            paths.add(link.route);
          }
        }
      }
    }

    for (final menu in StoreNav.desktopOrder) {
      addMenu(menu);
    }
    for (final menu in StoreNav.drawerOrder) {
      addMenu(menu);
    }
    addMenu(StoreNav.aboutUs);

    const nonListing = {
      '/',
      '/cart',
      '/shopping-cart',
      '/profile',
      '/account',
      '/wishlist',
      '/checkout',
    };
    return paths
        .where(
          (path) =>
              !nonListing.contains(path) &&
              !path.startsWith('/product/') &&
              !contentSectionPaths.contains(path) &&
              (isShopSection(path) || path.startsWith('/catalogue')),
        )
        .toSet();
  }

  Future<void> pumpCatalogue(
    WidgetTester tester, {
    required Size viewport,
    BusinessConfigProvider? config,
    CommerceStore? store,
  }) async {
    final provider = config ?? BusinessConfigProvider();
    if (config == null) await provider.load();
    final products = store ?? (CommerceStore()
      ..seedProducts(DemoCatalog.build(provider.config.categories)));

    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BusinessConfigProvider>.value(value: provider),
          ChangeNotifierProvider<CommerceStore>.value(value: products),
        ],
        child: MaterialApp(
          theme: provider.config.getTheme(),
          home: const CatalogueScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('every shop path renders the grid or the empty state', (
    tester,
  ) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );

    final paths = allListingPaths();
    expect(paths, isNotEmpty);

    for (final path in paths) {
      router.go(path);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        tester.takeException(),
        isNull,
        reason: 'rendering $path threw',
      );
      expect(
        find.byType(ListingView, skipOffstage: false),
        findsWidgets,
        reason: '$path did not render the listing surface',
      );
      final hasGrid = find
          .byType(ProductCard, skipOffstage: false)
          .evaluate()
          .isNotEmpty;
      final hasEmpty = find
          .text('No designs match', skipOffstage: false)
          .evaluate()
          .isNotEmpty;
      expect(
        hasGrid || hasEmpty,
        isTrue,
        reason: '$path showed neither the grid nor the empty state',
      );
    }
  });

  testWidgets('content pages keep their landing body without the listing', (
    tester,
  ) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );

    for (final path in contentSectionPaths) {
      router.go(path);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        tester.takeException(),
        isNull,
        reason: 'rendering $path threw',
      );
      expect(
        find.byType(ListingView, skipOffstage: false),
        findsNothing,
        reason: '$path should keep its designed content page',
      );
    }
  });

  testWidgets('the shop page ends with the site footer inside the scroll', (
    tester,
  ) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    router.go('/diamond-earrings/studs');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(ListingView), const Offset(0, -8000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SiteFooter, skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the grid pages with LOAD MORE past the first 24 designs', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final config = BusinessConfigProvider();
    await config.load();
    final store = CommerceStore()
      ..seedProducts(DemoCatalog.build(config.config.categories, count: 60));

    await pumpCatalogue(
      tester,
      viewport: const Size(1440, 900),
      config: config,
      store: store,
    );

    // The paging control lives at the end of the scroll, so bring it into
    // view before asserting.
    final loadMore = find.byKey(const ValueKey('load-more'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -10000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(loadMore, findsOneWidget);

    await tester.tap(loadMore);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    // 60 designs still exceed the 48 now on the grid, so paging continues.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -10000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(loadMore, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide screens keep the FILTERS sidebar; medium drops it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final config = BusinessConfigProvider();
    await config.load();
    final store = CommerceStore()
      ..seedProducts(DemoCatalog.build(config.config.categories));

    await pumpCatalogue(
      tester,
      viewport: const Size(1440, 900),
      config: config,
      store: store,
    );

    expect(find.text('FILTERS'), findsOneWidget);
    expect(find.byKey(const ValueKey('sort-menu')), findsOneWidget);
    expect(find.byKey(const ValueKey('load-more')), findsNothing); // 14 < 24
    expect(find.text('Clear all'), findsWidgets); // Sidebar panel + chips row.

    tester.view.physicalSize = const Size(1024, 800);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('FILTERS'), findsNothing);
    expect(find.byKey(const ValueKey('sort-menu')), findsNothing);
    expect(find.text('Sort by'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a metal with no stock shows the empty state and bestsellers', (
    tester,
  ) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );
    router.go('/catalogue?metal=White%20Gold');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('No designs match'), findsOneWidget);
    expect(find.text('Try removing a filter'), findsOneWidget);
    expect(find.text('White Gold'), findsWidgets); // Active chip + sidebar.

    await tester.tap(find.text('VIEW BESTSELLERS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(router.state.uri.toString(), '/bestsellers');
  });

  testWidgets('the search field narrows the catalogue listing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final config = BusinessConfigProvider();
    await config.load();
    final store = CommerceStore()
      ..seedProducts(DemoCatalog.build(config.config.categories));

    await pumpCatalogue(
      tester,
      viewport: const Size(1024, 800),
      config: config,
      store: store,
    );

    await tester.enterText(
      find.descendant(
        of: find.byType(AppSearchField),
        matching: find.byType(EditableText),
      ),
      'Temple Motif',
    );
    await tester.pumpAndSettle();

    expect(find.text('1 designs'), findsOneWidget);
    expect(find.text('Temple Motif Gold Necklace'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('business category chips narrow the catalogue', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final config = BusinessConfigProvider();
    await config.load();
    final store = CommerceStore()
      ..seedProducts(DemoCatalog.build(config.config.categories));

    await pumpCatalogue(
      tester,
      viewport: const Size(1024, 800),
      config: config,
      store: store,
    );

    final category = config.config.categories.first;
    await tester.tap(find.byKey(ValueKey('category-chip-$category')));
    await tester.pumpAndSettle();

    expect(find.text('Filter (1)'), findsOneWidget);
    expect(find.byKey(ValueKey('category-chip-$category')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the full-bleed grid drops editorial heroes between chunks', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final config = BusinessConfigProvider();
    await config.load();
    final store = CommerceStore()
      ..seedProducts(DemoCatalog.build(config.config.categories, count: 40));

    await pumpCatalogue(
      tester,
      viewport: const Size(390, 800),
      config: config,
      store: store,
    );

    // Two rows of phone (2 columns → chunk of 4) then the multi-image
    // hero banner; scroll past the first rows to reach it.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Explore '), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('list mode is an Instagram-style full-width product feed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final config = BusinessConfigProvider();
    await config.load();
    final store = CommerceStore()
      ..seedProducts(DemoCatalog.build(config.config.categories, count: 12));

    await pumpCatalogue(
      tester,
      viewport: const Size(390, 800),
      config: config,
      store: store,
    );

    // Toggle from grid into the list feed.
    await tester.tap(find.byIcon(Icons.view_list_outlined));
    await tester.pumpAndSettle();

    // No bordered grid tiles remain; every card is a full-width carousel
    // with swipe dots that mark the product's image count.
    expect(find.byType(ProductCard, skipOffstage: false), findsNothing);
    expect(find.byType(ProductImageCarousel), findsWidgets);
    expect(find.byType(CarouselDots), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
