import 'package:ecommerce_app/core/store/commerce_store.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:ecommerce_app/features/owner/screens/owner_gold_rate_screen.dart';
import 'package:ecommerce_app/features/shell/rate_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/shop_harness.dart';

/// The Thangamayil-style rate board: a warm gold box on the left and a cool
/// silver box on the right under the header, on every shell page at every
/// layout class, collapsing cleanly when no rate is set, with the owner's
/// silver entry and last-updated stamp flowing straight onto it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewports = <String, Size>{
    'small phone': Size(320, 568),
    'phone': Size(390, 844),
    'phone landscape': Size(640, 360),
    'tablet': Size(768, 1024),
    'medium': Size(1024, 1366),
    'expanded': Size(1440, 900),
    'wide': Size(1680, 1050),
  };

  testWidgets('every layout class boards gold left and silver right', (
    tester,
  ) async {
    for (final entry in viewports.entries) {
      // Detach the previous viewport so only one shell tree is mounted.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final (router, config, _) = await pumpShop(tester, viewport: entry.value);
      config.updateSingleRule('showMetalRates', true);
      router.go('/app');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final why = ' (${entry.key})';
      final strip = find.byType(RateStrip);
      expect(strip, findsOneWidget, reason: 'rate board$why');
      for (final label in const ['GOLD RATE', 'SILVER RATE']) {
        expect(
          find.descendant(of: strip, matching: find.text(label)),
          findsOneWidget,
          reason: '$label label$why',
        );
      }
      expect(
        find.descendant(of: strip, matching: find.text('₹7,250')),
        findsOneWidget,
        reason: 'gold value$why',
      );
      expect(
        find.descendant(of: strip, matching: find.text('₹89')),
        findsOneWidget,
        reason: 'silver value$why',
      );
      expect(
        find.descendant(of: strip, matching: find.text('/ gram')),
        findsNWidgets(2),
        reason: 'both boxes say / gram$why',
      );

      // The gold box sits left of the silver box, both boxed and sized.
      final goldBox = find.byKey(const Key('rate-box-gold'));
      final silverBox = find.byKey(const Key('rate-box-silver'));
      expect(goldBox, findsOneWidget, reason: 'gold box$why');
      expect(silverBox, findsOneWidget, reason: 'silver box$why');
      final goldRect = tester.getRect(goldBox);
      final silverRect = tester.getRect(silverBox);
      expect(
        goldRect.center.dx,
        lessThan(silverRect.center.dx),
        reason: 'gold left, silver right$why',
      );
      expect(
        goldRect.size.width,
        greaterThan(60),
        reason: 'gold box has real width$why',
      );
      expect(tester.takeException(), isNull, reason: 'no overflow$why');
    }
  });

  testWidgets('the board is hidden by default and appears with the rule', (
    tester,
  ) async {
    final (router, config, _) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('GOLD RATE'), findsNothing, reason: 'rule off by default');
    expect(tester.takeException(), isNull);

    config.updateSingleRule('showMetalRates', true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('GOLD RATE'), findsOneWidget, reason: 'rule turns it on');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the board collapses when every rate is cleared', (
    tester,
  ) async {
    final (router, config, store) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    config.updateSingleRule('showMetalRates', true);
    store.setRates(goldPerGram: 0, silverPerGram: 0, platinumPerGram: 0);
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(RateStrip), findsOneWidget);
    expect(find.text('GOLD RATE'), findsNothing, reason: 'no rates, no board');
    expect(tester.getSize(find.byType(RateStrip)).height, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the owner\u2019s silver entry boards on the strip', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final config = BusinessConfigProvider();
    await config.load();
    config.updateSingleRule('showMetalRates', true);
    final store = CommerceStore();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BusinessConfigProvider>.value(value: config),
          ChangeNotifierProvider<CommerceStore>.value(value: store),
        ],
        child: MaterialApp(
          theme: config.config.getTheme(),
          home: const OwnerGoldRateScreen(),
        ),
      ),
    );
    await tester.pump();

    // The silver field starts on the demo board value and is editable.
    await tester.enterText(find.widgetWithText(TextField, '89'), '105');
    await tester.tap(find.text('Save today\u2019s rate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(store.silverRateInrPerGram, 105);
    expect(store.goldRateInrPerGram, CommerceStore.defaultGoldRateInrPerGram);
    expect(store.ratesUpdatedAt, isNotNull);
    expect(find.text('Rates saved for today.'), findsOneWidget);

    // The saved number is exactly what the storefront boards, with the
    // last-updated stamp under the boxes.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BusinessConfigProvider>.value(value: config),
          ChangeNotifierProvider<CommerceStore>.value(value: store),
        ],
        child: const MaterialApp(home: RateStrip()),
      ),
    );
    await tester.pump();
    expect(find.text('₹105'), findsOneWidget);
    expect(
      find.textContaining('Last updated'),
      findsOneWidget,
      reason: 'the owner\u2019s save stamps the board',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the product page boards the same rates under the price', (
    tester,
  ) async {
    final (router, config, store) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    config.updateSingleRule('showMetalRates', true);
    router.go('/product/${store.allProducts.first.id}');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.textContaining('Gold ₹7,250/g · Silver ₹89/g'),
      findsOneWidget,
      reason: 'the PDP boards today\u2019s rates under the price',
    );
    expect(tester.takeException(), isNull);
  });
}
