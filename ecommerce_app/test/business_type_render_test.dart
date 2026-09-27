import 'package:ecommerce_app/core/business_config.dart';
import 'package:ecommerce_app/core/demo_catalog.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/auth/providers/auth_provider.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:ecommerce_app/features/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders the home tab once per business type and fails if any of them throws
/// a layout/paint error (overflow stripes, bad contrast, missing constraints).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every business type renders its home tab cleanly', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = BusinessConfigProvider();
    await provider.load();

    final store = CommerceStore();
    final auth = AuthProvider();

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;

    final failures = <String>[];

    for (final type in BusinessConfig.configs.keys) {
      provider.setBusinessType(type);
      await provider.flush();
      store.seedProducts(DemoCatalog.build(provider.config.categories));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BusinessConfigProvider>.value(
              value: provider,
            ),
            ChangeNotifierProvider<CommerceStore>.value(value: store),
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ],
          child: MaterialApp(
            theme: provider.config.getTheme(),
            home: const MainScreen(),
          ),
        ),
      );
      await tester.pump();

      final error = tester.takeException();
      if (error != null) {
        failures.add('${type.name}: $error');
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();

    expect(failures, isEmpty, reason: failures.join('\n'));
  }, timeout: const Timeout(Duration(seconds: 90)));
}
