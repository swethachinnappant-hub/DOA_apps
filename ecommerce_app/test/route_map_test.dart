import 'package:ecommerce_app/core/demo_catalog.dart';
import 'package:ecommerce_app/core/models/user.dart';
import 'package:ecommerce_app/core/navigation/menu_data.dart';
import 'package:ecommerce_app/core/router/app_router.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/auth/providers/auth_provider.dart';
import 'package:ecommerce_app/features/cart/screens/cart_screen.dart';
import 'package:ecommerce_app/features/catalogue/screens/catalogue_screen.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:ecommerce_app/features/product/screens/product_detail_screen.dart';
import 'package:ecommerce_app/features/profile/screens/profile_screen.dart';
import 'package:ecommerce_app/features/shell/section_screen.dart';
import 'package:ecommerce_app/features/shell/site_footer.dart';
import 'package:ecommerce_app/features/wishlist/screens/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 2 gate (§16.3): every §4.2 nav/footer link and §4.3 route pattern
/// resolves to a real screen — never the generic error fallback.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Type expectedScreen(String path) {
    if (path == '/cart' || path == '/shopping-cart') return CartScreen;
    if (path == '/profile' || path == '/account') return ProfileScreen;
    if (path == '/wishlist') return WishlistScreen;
    if (path.startsWith('/catalogue')) return CatalogueScreen;
    const bands = {
      '/20k-products',
      '/30k-products',
      '/50k-products',
      '/above-50k',
      '/500-dollar-products',
      '/1000-dollar-products',
      '/2000-dollar-products',
      '/above-2000-dollar-products',
      '/product-list',
    };
    if (bands.contains(path)) return CatalogueScreen;
    return SectionScreen;
  }

  /// Every route reachable from the desktop nav, drawer nav and footer.
  Set<String> allLinks() {
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

    for (final column in SiteFooter.linkColumns.values) {
      for (final link in column) {
        paths.add(link[1]);
      }
    }
    return paths;
  }

  /// Hand-picked §4.3 patterns beyond the menus (aliases, legacy, blog,
  /// virtual, gifts), plus the live PLP/carts themselves.
  const curated = <String>{
    '/catalogue',
    '/cart',
    '/profile',
    '/diamond-earrings/studs',
    '/women-diamond-ring',
    '/gemstone/diamond-earrings/studs',
    '/nose-pin/nose-screw',
    '/watch-jewellery/charms',
    '/hair-deco',
    '/hair-deco/maang-tikka',
    '/solitaire-product-list/ring',
    '/solitaire-product-list',
    '/gift-by-occasion',
    '/gift-for-special',
    '/virtual-tryon',
    '/virtualstoreproduct',
    '/co-shopping-products',
    '/shopping-cart',
    '/account',
    '/product-list',
    '/blog/country/kirtilals-india',
    '/500-dollar-products',
    '/1000-dollar-products',
    '/2000-dollar-products',
    '/above-2000-dollar-products',
    '/goldjewellerypromotion',
    '/gold-coin',
    '/gold-accessories',
    '/giftcardsforms',
    '/clip-on-earrings',
    '/definitely-not-a-page',
  };

  Future<(GoRouter, BusinessConfigProvider, CommerceStore)> pumpShop(
    WidgetTester tester, {
    required Size viewport,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final config = BusinessConfigProvider();
    await config.load();
    final store = CommerceStore()
      ..seedProducts(DemoCatalog.build(config.config.categories));
    final auth = AuthProvider()..signInAsDemo(UserRole.customer);
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
    return (router, config, store);
  }

  testWidgets('every §4.2 link and §4.3 path opens a real screen', (
    tester,
  ) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );

    final paths = {...allLinks(), ...curated}..remove('/');
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
        find.textContaining('does not exist', skipOffstage: false),
        findsNothing,
        reason: '$path fell through to the error fallback',
      );
      final expected = expectedScreen(path);
      expect(
        find.byType(expected, skipOffstage: false),
        findsWidgets,
        reason: '$path did not resolve to $expected',
      );
    }
  });

  testWidgets('an unknown root slug resolves to its product page', (
    tester,
  ) async {
    final (router, _, store) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );

    final product = store.shopProducts.first;
    final slug = product.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    for (final path in ['/product/${product.id}', '/$slug']) {
      router.go(path);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull, reason: 'rendering $path threw');
      expect(
        find.byType(ProductDetailScreen, skipOffstage: false),
        findsWidgets,
        reason: '$path should open the product detail screen',
      );
    }
  });

  testWidgets('shell and deep links render clean at 390 / 768 / 1440', (
    tester,
  ) async {
    for (final viewport in const [
      Size(390, 844),
      Size(768, 1024),
      Size(1440, 900),
    ]) {
      final (router, _, _) = await pumpShop(tester, viewport: viewport);
      for (final path in [
        '/app',
        '/diamond-earrings/studs',
        '/20k-products',
        '/definitely-not-a-page',
      ]) {
        router.go(path);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          tester.takeException(),
          isNull,
          reason: '$path at ${viewport.width}x${viewport.height}',
        );
      }
      // Detach the app before the next viewport keeps a clean tree.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}
