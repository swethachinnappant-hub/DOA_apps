import 'package:ecommerce_app/core/demo_catalog.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/auth/providers/auth_provider.dart';
import 'package:ecommerce_app/features/catalogue/screens/catalogue_screen.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:ecommerce_app/features/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression coverage for the three field reports:
///  * the category row must show exactly one 'All' tag,
///  * the editorial collage hero must actually render (it silently collapsed
///    to nothing when its product slice came up empty), and
///  * the search box must stay a single pill (no nested filled box).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(BusinessConfigProvider, CommerceStore)> loadConfig() async {
    SharedPreferences.setMockInitialValues({});
    final config = BusinessConfigProvider();
    await config.load();
    final store = CommerceStore()
      ..seedProducts(DemoCatalog.build(config.config.categories));
    return (config, store);
  }

  Widget wrap(BusinessConfigProvider config, CommerceStore store, Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BusinessConfigProvider>.value(value: config),
        ChangeNotifierProvider<CommerceStore>.value(value: store),
        // The header reads the signed-in user for the notification badge.
        ChangeNotifierProvider<AuthProvider>.value(value: AuthProvider()),
      ],
      child: MaterialApp(
        theme: config.config.getTheme(),
        home: child,
      ),
    );
  }

  testWidgets('catalogue: one All tag, single search pill, collage shows', (
    tester,
  ) async {
    final (config, store) = await loadConfig();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(config, store, const CatalogueScreen()));
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget, reason: 'exactly one All tag');

    final search = tester.widget<TextField>(find.byType(TextField).first);
    expect(
      search.decoration?.filled,
      isFalse,
      reason: 'the search input must not paint a nested filled box',
    );

    // The collage sits between grid chunks — scroll it into view.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    if (find.text('Made to be noticed').evaluate().isEmpty) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
      await tester.pumpAndSettle();
    }
    expect(
      find.text('Made to be noticed'),
      findsOneWidget,
      reason: 'the catalogue collage hero renders between grid chunks',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('home: collage hero renders and the search box is one pill', (
    tester,
  ) async {
    final (config, store) = await loadConfig();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(config, store, const MainScreen()));
    await tester.pumpAndSettle();

    expect(
      find.text('Made to be noticed'),
      findsOneWidget,
      reason: 'the dashboard collage must not collapse to an empty slice',
    );
    expect(find.text('All'), findsNothing);

    final search = tester.widget<TextField>(find.byType(TextField).first);
    expect(search.decoration?.hintText, contains('Search'));
    expect(search.decoration?.filled, isFalse);
    expect(tester.takeException(), isNull);
  });
}
