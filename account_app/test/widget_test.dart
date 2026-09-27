import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:account_app/main.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(const AccountApp());
    // MainScreen keeps all tabs alive in an IndexedStack. Let their initial
    // loading states finish before ending the test so their timers are drained.
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(AccountApp), findsOneWidget);
  });

  testWidgets('valid account credentials open the dashboard', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AccountApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Login'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('Dashboard'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
