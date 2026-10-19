import 'package:ecommerce_app/features/services/try_in_store_screen.dart';
import 'package:ecommerce_app/features/shell/section_screen.dart';
import 'package:ecommerce_app/features/virtual/co_shopping_screen.dart';
import 'package:ecommerce_app/features/virtual/virtual_store_screen.dart';
import 'package:ecommerce_app/features/virtual/virtual_tryon_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/shop_harness.dart';

/// Phase 10 gate (§16.3): the virtual try-on, virtual store and co-shopping
/// screens live behind the virtualTryOn business rule — off they show the
/// designed "Coming soon" heroes, on they run their local demo flows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const routes = <String, String>{
    '/virtual-tryon': 'Virtual Try-On',
    '/virtualstoreproduct': 'Virtual Store',
    '/co-shopping-products': 'Decide With Friends',
  };

  testWidgets('the virtual routes render coming-soon heroes while off',
      (tester) async {
    final (router, config, _) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    expect(config.config.rules.virtualTryOn, isFalse);

    for (final entry in routes.entries) {
      router.go(entry.key);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull, reason: '${entry.key} threw');
      expect(
        find.text(entry.value, skipOffstage: false),
        findsWidgets,
        reason: '${entry.key} lost its hero title',
      );
      expect(
        find.text('Coming soon', skipOffstage: false),
        findsOneWidget,
        reason: '${entry.key} lost its coming-soon card',
      );
      expect(
        find.text('BROWSE THE CATALOGUE', skipOffstage: false),
        findsOneWidget,
        reason: '${entry.key} lost its catalogue CTA',
      );
    }
  });

  testWidgets('the registry points the virtual routes at the gated screens',
      (tester) async {
    final (router, config, _) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    config.updateSingleRule('virtualTryOn', true);

    final expected = <String, Type>{
      '/virtual-tryon': VirtualTryOnScreen,
      '/virtualstoreproduct': VirtualStoreScreen,
      '/co-shopping-products': CoShoppingScreen,
    };
    for (final entry in expected.entries) {
      router.go(entry.key);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull, reason: '${entry.key} threw');
      expect(
        find.byType(SectionScreen, skipOffstage: false),
        findsWidgets,
        reason: '${entry.key} did not resolve to SectionScreen',
      );
      expect(
        find.byType(entry.value, skipOffstage: false),
        findsOneWidget,
        reason: '${entry.key} did not open ${entry.value}',
      );
      expect(
        find.text('Coming soon', skipOffstage: false),
        findsNothing,
        reason: '${entry.key} still shows coming-soon with the switch on',
      );
    }
  });

  testWidgets('the try-on demo selects a piece, captures and shares',
      (tester) async {
    final (router, config, _) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    config
      ..updateSingleRule('virtualTryOn', true)
      // §11.3: the jewellery preset ships allowShare off; turn it on so the
      // share action is part of the flow under test.
      ..updateSingleRule('allowShare', true);
    router.go('/virtual-tryon');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(VirtualTryOnScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('tryon-overlay')), findsNothing);
    expect(find.text('CAPTURE'), findsOneWidget);

    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pump();

    expect(find.byKey(const ValueKey('tryon-overlay')), findsOneWidget);

    final capture = find.byKey(const ValueKey('tryon-capture'));
    await tester.ensureVisible(capture);
    await tester.pump();
    await tester.tap(capture);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Look captured'), findsOneWidget);
    expect(find.text('Look captured — demo capture only'), findsOneWidget);

    // The capture toast has to fully exit before the queued share toast can
    // appear; several medium pumps give the exit ticker its frames.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byType(SnackBar), findsNothing);

    final share = find.byKey(const ValueKey('tryon-share'));
    expect(share, findsOneWidget);
    await tester.ensureVisible(share);
    await tester.pump();
    await tester.tap(share);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Share sheet would open here'), findsOneWidget);

    // §11.3: allowShare off hides the share action like everywhere else.
    config.updateSingleRule('allowShare', false);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('SHARE LOOK'), findsNothing);

    await tester.pump(const Duration(milliseconds: 4000));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the store panorama opens hotspot notes and books a visit',
      (tester) async {
    final (router, config, _) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    config.updateSingleRule('virtualTryOn', true);
    router.go('/virtualstoreproduct');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(VirtualStoreScreen), findsOneWidget);
    expect(find.text('360° FLAGSHIP WALKTHROUGH'), findsOneWidget);
    expect(
      find.text(
        'Greeted by a bridal stylist, with the day’s metal rate on display.',
      ),
      findsOneWidget,
      reason: 'the welcome-desk note should open by default',
    );

    final chip = find.byKey(const ValueKey('store-chip-1'));
    await tester.ensureVisible(chip);
    await tester.pump();
    await tester.tap(chip);
    await tester.pump();

    expect(
      find.text(
        'The Bandhan and real-bride collections, shown by appointment.',
      ),
      findsOneWidget,
      reason: 'tapping the bridal-vault chip should swap the note',
    );

    final book = find.byKey(const ValueKey('store-book'));
    await tester.ensureVisible(book);
    await tester.pump();
    await tester.tap(book);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TryInStoreScreen), findsOneWidget);
    expect(find.text('FIND A STORE'), findsWidgets);

    expect(tester.takeException(), isNull);
  });

  testWidgets('co-shopping copies the link, votes and toggles the shortlist',
      (tester) async {
    final log = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        log.add(call);
        return null;
      },
    );

    final (router, config, _) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    // §11.3: jewellery ships allowShare off; the invite-link copy is a share
    // action, so turn the rule on for this flow.
    config
      ..updateSingleRule('virtualTryOn', true)
      ..updateSingleRule('allowShare', true);
    router.go('/co-shopping-products');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CoShoppingScreen), findsOneWidget);
    expect(find.text('THE GROUP SAYS'), findsOneWidget);

    final copyLink = find.byKey(const ValueKey('co-copy-link'));
    await tester.ensureVisible(copyLink);
    await tester.pump();
    await tester.tap(copyLink);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Shortlist link copied'), findsOneWidget);
    expect(
      log.where((call) => call.method == 'Clipboard.setData'),
      isNotEmpty,
      reason: 'copying the shortlist link should hit the clipboard',
    );

    final loveKey = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return widget is InkWell &&
          key is ValueKey<String> &&
          key.value.startsWith('co-vote-') &&
          key.value.endsWith('-0');
    });
    await tester.ensureVisible(loveKey.first);
    await tester.pump();
    await tester.tap(loveKey.first);
    await tester.pump();
    expect(find.text('❤️ 1'), findsOneWidget);

    final add = find.text('ADD TO SHORTLIST').first;
    await tester.ensureVisible(add);
    await tester.pump();
    await tester.tap(add);
    await tester.pump();
    expect(find.text('ON SHORTLIST'), findsOneWidget);

    final onList = find.text('ON SHORTLIST').first;
    await tester.ensureVisible(onList);
    await tester.pump();
    await tester.tap(onList);
    await tester.pump();
    expect(find.text('ADD TO SHORTLIST'), findsNWidgets(4));

    await tester.pump(const Duration(milliseconds: 4000));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the live virtual screens render cleanly at every viewport',
      (tester) async {
    final (router, config, _) = await pumpShop(
      tester,
      viewport: const Size(390, 844),
    );
    config.updateSingleRule('virtualTryOn', true);

    const viewports = <String, Size>{
      'phone 390x844': Size(390, 844),
      'tablet 768x1024': Size(768, 1024),
      'desktop 1440x900': Size(1440, 900),
    };
    final failures = <String>[];

    for (final viewport in viewports.entries) {
      tester.view.physicalSize = viewport.value;
      tester.view.devicePixelRatio = 1.0;

      for (final route in routes.keys) {
        router.go(route);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final error = tester.takeException();
        if (error != null) failures.add('$route @ ${viewport.key}: $error');
      }
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();

    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
