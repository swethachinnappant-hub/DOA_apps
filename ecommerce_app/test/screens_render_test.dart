import 'package:common_widgets/common_widgets.dart';
import 'package:ecommerce_app/core/demo_catalog.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/auth/providers/auth_provider.dart';
import 'package:ecommerce_app/features/auth/screens/login_screen.dart';
import 'package:ecommerce_app/features/auth/screens/register_screen.dart';
import 'package:ecommerce_app/features/catalogue/screens/catalogue_screen.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:ecommerce_app/features/config/screens/business_config_screen.dart';
import 'package:ecommerce_app/features/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders each key screen at several viewport sizes in the light theme and
/// fails on any layout/paint error (overflow stripes, missing constraints,
/// unreadable colours).
///
/// Everything runs inside a single test so there is one clean binding lifecycle
/// and the carousel timers are always cancelled by the teardown pump.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewports = <String, Size>{
    'small phone 320x568': Size(320, 568),
    'phone 360x800': Size(360, 800),
    'landscape 640x360': Size(640, 360),
    'tablet 1024x1366': Size(1024, 1366),
  };

  const screens = <String, Widget>{
    'BusinessConfigScreen': BusinessConfigScreen(),
    'MainScreen': MainScreen(),
    'LoginScreen': LoginScreen(),
    'RegisterScreen': RegisterScreen(),
    'CatalogueScreen': CatalogueScreen(),
  };

  testWidgets('key screens render cleanly at every viewport', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = BusinessConfigProvider();
    await provider.load();

    final store = CommerceStore()
      ..seedProducts(DemoCatalog.build(provider.config.categories));
    final auth = AuthProvider();

    final failures = <String>[];

    Widget wrap(Widget home, {BusinessConfigProvider? config}) {
      final configProvider = config ?? provider;
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<BusinessConfigProvider>.value(
            value: configProvider,
          ),
          ChangeNotifierProvider<CommerceStore>.value(value: store),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp(
          theme: configProvider.config.getTheme(),
          home: home,
        ),
      );
    }

    Future<void> render(String label, Widget child) async {
      await tester.pumpWidget(wrap(child));
      await tester.pump();

      final error = tester.takeException();
      if (error != null) failures.add('$label: $error');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    for (final viewport in viewports.entries) {
      tester.view.physicalSize = viewport.value;
      tester.view.devicePixelRatio = 1.0;

      for (final screen in screens.entries) {
        await render('${screen.key} @ ${viewport.key}', screen.value);
      }

      // The home tab must show the auto/manual category carousel.
      await tester.pumpWidget(wrap(const MainScreen()));
      await tester.pump();
      if (find.byType(CategoryCarousel).evaluate().isEmpty) {
        failures.add('no CategoryCarousel @ ${viewport.key}');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    // A very pale brand colour must flip text to dark but keep white surfaces.
    provider.updateColors(
      primaryColor: const Color(0xFFFFF176),
      secondaryColor: const Color(0xFF80CBC4),
      accentColor: const Color(0xFFFFCC80),
    );
    await provider.flush();

    final restored = BusinessConfigProvider();
    await restored.load();
    if (restored.config.onPrimaryColor != Colors.black) {
      failures.add('pale primary did not switch to dark text');
    }

    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpWidget(
      wrap(const BusinessConfigScreen(), config: restored),
    );
    await tester.pump();
    final paleError = tester.takeException();
    if (paleError != null) failures.add('pale palette: $paleError');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();

    expect(failures, isEmpty, reason: failures.join('\n'));
  }, timeout: const Timeout(Duration(seconds: 120)));
}
