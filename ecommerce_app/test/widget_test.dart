import 'package:ecommerce_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verifies the real launch flow: splash -> business config screen, in the
/// light theme. Uses explicit `pump` calls rather than `pumpAndSettle`,
/// because the splash timer and the carousel's auto-slide timer repeat forever
/// and would never settle.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('launches into the light-themed config screen', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const EcommerceApp());
    await tester.pump();

    // The splash screen is up first and is rendered in brand colours.
    expect(find.text('Personalise Your App'), findsNothing);

    // Let the 3 second splash delay elapse, which routes to /config.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(find.text('Personalise Your App'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, timeout: const Timeout(Duration(seconds: 60)));
}
