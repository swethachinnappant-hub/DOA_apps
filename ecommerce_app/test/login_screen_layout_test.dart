import 'package:ecommerce_app/features/auth/providers/auth_provider.dart';
import 'package:ecommerce_app/features/auth/screens/login_screen.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'login has one role prompt and Explore is reachable on a small phone',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final config = BusinessConfigProvider();
      await config.load();
      final auth = AuthProvider();
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BusinessConfigProvider>.value(value: config),
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ],
          child: MaterialApp(
            theme: config.config.getTheme(),
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose how you want to use the app'), findsNothing);
      expect(find.text('CONTINUE AS'), findsOneWidget);

      final explore = find.text('Explore as customer');
      await tester.ensureVisible(explore);
      await tester.pumpAndSettle();
      expect(explore, findsOneWidget);
      expect(tester.getBottomLeft(explore).dy, lessThan(568));
      expect(tester.takeException(), isNull);
    },
  );
}
