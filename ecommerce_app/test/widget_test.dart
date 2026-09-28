import 'package:ecommerce_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verifies the real launch flow: splash -> sign-in screen, in the
/// light theme. Uses explicit `pump` calls rather than `pumpAndSettle`,
/// because the splash timer and the carousel's auto-slide timer repeat forever
/// and would never settle.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'launches into the light-themed sign-in screen',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const EcommerceApp());
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'splash layout');

      // The splash screen is up first; business selection is no longer an
      // onboarding gate for jewellery shoppers.
      expect(find.text('Welcome back'), findsNothing);

      // Let the splash delay elapse, which routes a signed-out user to /login.
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      final loginError = tester.takeException();
      expect(loginError, isNull, reason: 'login layout');

      expect(find.text('Welcome back'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
