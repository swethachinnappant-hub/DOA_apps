import 'package:ecommerce_app/core/models/user.dart';
import 'package:ecommerce_app/features/auth/providers/auth_provider.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:ecommerce_app/features/profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('account preferences only shows notifications', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final config = BusinessConfigProvider();
    await config.load();
    final auth = AuthProvider()..signInAsDemo(UserRole.customer);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BusinessConfigProvider>.value(value: config),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp(
          theme: config.config.getTheme(),
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Business rules'), findsNothing);
    expect(find.text('Shop preferences'), findsNothing);
    expect(find.text('Shop settings'), findsNothing);
  });

  for (final role in UserRole.values) {
    testWidgets('${role.label} can confirm sign out from account settings', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final config = BusinessConfigProvider();
      await config.load();
      final auth = AuthProvider()..signInAsDemo(role);
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(showAppBar: true),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Signed out successfully')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BusinessConfigProvider>.value(value: config),
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ],
          child: MaterialApp.router(
            theme: config.config.getTheme(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.text('Sign out'), findsOneWidget);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out?'), findsOneWidget);
      await tester.tap(find.text('Sign out').last);
      await tester.pumpAndSettle();
      expect(find.text('Signed out successfully'), findsOneWidget);
      expect(auth.isSignedIn, isFalse);
      expect(tester.takeException(), isNull);

      router.dispose();
    });
  }
}
