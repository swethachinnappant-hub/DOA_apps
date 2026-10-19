import 'package:ecommerce_app/core/demo_catalog.dart';
import 'package:ecommerce_app/core/models/user.dart';
import 'package:ecommerce_app/core/router/app_router.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/auth/providers/auth_provider.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:ecommerce_app/features/search/search_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Signs in a customer, seeds the catalogue and pumps the shop with the same
/// Ctrl/Cmd+K host the real app installs in `main.dart`.
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
        builder: (context, child) =>
            SearchShortcutHost(child: child ?? const SizedBox.shrink()),
      ),
    ),
  );
  await tester.pump();
  return (router, config, store);
}

Future<void> pressCtrlK(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.keyK);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> pressEscape(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}
