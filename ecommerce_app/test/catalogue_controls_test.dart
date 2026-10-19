import 'package:ecommerce_app/core/demo_catalog.dart';
import 'package:ecommerce_app/core/pricing.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/catalogue/screens/catalogue_screen.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:ecommerce_app/features/auth/providers/auth_provider.dart';
import 'package:ecommerce_app/features/main_screen.dart';
import 'package:ecommerce_app/features/profile/screens/profile_screen.dart';
import 'package:ecommerce_app/features/shell/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('jewellery prices use consistent Indian digit grouping', () {
    expect(Pricing.money(2499), '₹2,499');
    expect(Pricing.money(1250000), '₹12,50,000');
    expect(Pricing.money(2499, currencySymbol: '\$'), '\$2,499');
  });

  testWidgets('purity filters and sort choices update the collection', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final config = BusinessConfigProvider();
    await config.load();
    final store = CommerceStore()
      ..seedProducts(DemoCatalog.build(config.config.categories));

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BusinessConfigProvider>.value(value: config),
          ChangeNotifierProvider<CommerceStore>.value(value: store),
        ],
        child: MaterialApp(
          theme: config.config.getTheme(),
          home: const CatalogueScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('Sort by'), findsOneWidget);

    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    expect(find.text('Gold purity'), findsOneWidget);
    expect(find.text('Available now'), findsOneWidget);
    await tester.tap(find.text('Available now'));
    await tester.tap(find.text('22K Yellow Gold'));
    await tester.tap(find.text('Show pieces'));
    await tester.pumpAndSettle();
    expect(find.text('22K Yellow Gold'), findsOneWidget);
    expect(find.text('Filter (2)'), findsOneWidget);
    expect(find.text('Available now'), findsOneWidget);

    await tester.tap(find.text('Filter (2)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Filter'), findsOneWidget);

    await tester.tap(find.text('Sort by'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price: Low to High'));
    await tester.pumpAndSettle();
    expect(find.text('Price: Low to High'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop filter and sort share one side panel', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final config = BusinessConfigProvider();
    await config.load();
    final store = CommerceStore()
      ..seedProducts(DemoCatalog.build(config.config.categories));

    tester.view.physicalSize = const Size(1024, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BusinessConfigProvider>.value(value: config),
          ChangeNotifierProvider<CommerceStore>.value(value: store),
        ],
        child: MaterialApp(
          theme: config.config.getTheme(),
          home: const CatalogueScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    expect(find.text('Refine collection'), findsOneWidget);
    expect(find.text('Gold purity'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Sort by'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price: High to Low').last);
    await tester.tap(find.text('Show pieces'));
    await tester.pumpAndSettle();

    expect(find.text('Refine collection'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom bar switches tabs and keeps a route home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final config = BusinessConfigProvider();
    await config.load();
    final store = CommerceStore()
      ..seedProducts(DemoCatalog.build(config.config.categories));
    final auth = AuthProvider();

    // Compact phone viewport: the four-destination bottom bar only shows
    // below 768px (architecture §5.5).
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BusinessConfigProvider>.value(value: config),
          ChangeNotifierProvider<CommerceStore>.value(value: store),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp(
          theme: config.config.getTheme(),
          home: const MainScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The four verified destinations: Home · Catalogue · Cart · Account.
    expect(find.byType(BottomBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Catalogue'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('THE JEWELLERY EDIT'), findsOneWidget);

    await tester.tap(find.text('Catalogue'));
    await tester.pumpAndSettle();
    expect(
      find.byType(CatalogueScreen),
      findsOneWidget,
      reason: 'the tab shows the listing with its grid/list view toggle',
    );
    expect(find.text('Catalogue'), findsOneWidget); // The bar label stays.
    expect(find.text('FIND A STORE'), findsNothing);
    expect(find.text('THE JEWELLERY EDIT'), findsNothing);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('THE JEWELLERY EDIT'), findsOneWidget);
    expect(find.byType(CatalogueScreen), findsNothing);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(
      find.byType(ProfileScreen),
      findsOneWidget,
      reason: 'the Account tab must show the profile, not fall back home',
    );
    expect(find.text('THE JEWELLERY EDIT'), findsNothing);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('THE JEWELLERY EDIT'), findsOneWidget);

    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -420));
    await tester.pumpAndSettle();
    final homeScroll = find
        .descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    expect(
      tester.state<ScrollableState>(homeScroll).position.pixels,
      greaterThan(0),
    );
    expect(find.byType(BottomBar), findsOneWidget); // The bar stays fixed.

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
