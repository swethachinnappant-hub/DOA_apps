import 'package:ecommerce_app/features/catalogue/screens/catalogue_screen.dart';
import 'package:ecommerce_app/features/search/search_overlay.dart';
import 'package:ecommerce_app/features/search/search_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/shop_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(SearchProvider.resetRecents);

  Finder overlayField() => find.descendant(
    of: find.byType(SearchPanel),
    matching: find.byType(TextField),
  );

  testWidgets('Ctrl/Cmd+K opens search and Esc closes it', (tester) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await pressCtrlK(tester);
    expect(find.byType(SearchOverlay, skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pressEscape(tester);
    expect(find.byType(SearchOverlay, skipOffstage: false), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SearchOverlay, skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pressEscape(tester);
    expect(find.byType(SearchOverlay, skipOffstage: false), findsNothing);
  });

  testWidgets('the empty query opens clean with no popular searches', (
    tester,
  ) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await pressCtrlK(tester);
    expect(find.byType(SearchOverlay, skipOffstage: false), findsOneWidget);
    expect(find.text('POPULAR SEARCHES'), findsNothing);
    expect(find.text('RECENT SEARCHES'), findsNothing);
    expect(find.byType(TextField), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('typing debounces into related searches and products', (
    tester,
  ) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await pressCtrlK(tester);
    await tester.enterText(overlayField(), 'gold');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('RELATED SEARCHES'), findsNothing);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('RELATED SEARCHES'), findsOneWidget);
    expect(find.text('Yellow Gold'), findsWidgets);
    expect(find.text('RELATED PRODUCTS'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final provider = tester
        .element(find.byType(SearchPanel))
        .read<SearchProvider>();
    if (provider.productSuggestions.isNotEmpty) {
      expect(
        find.descendant(
          of: find.byType(SearchPanel),
          matching: find.text(provider.productSuggestions.first.name),
        ),
        findsWidgets,
      );
    }
  });

  testWidgets('Enter opens the listing with the query string', (tester) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await pressCtrlK(tester);
    await tester.enterText(overlayField(), 'gold');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CatalogueScreen, skipOffstage: false), findsWidgets);
    expect(find.byType(SearchOverlay, skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('submitted terms reappear under recent searches', (
    tester,
  ) async {
    final (router, _, _) = await pumpShop(
      tester,
      viewport: const Size(1440, 900),
    );
    router.go('/app');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await pressCtrlK(tester);
    await tester.enterText(overlayField(), 'gold');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CatalogueScreen, skipOffstage: false), findsWidgets);

    await pressCtrlK(tester);
    expect(find.text('RECENT SEARCHES'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SearchPanel),
        matching: find.text('gold'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await pressEscape(tester);
    expect(find.byType(SearchOverlay, skipOffstage: false), findsNothing);
  });

  testWidgets('the search overlay renders clean at 390 / 768 / 1440', (
    tester,
  ) async {
    for (final viewport in const [
      Size(390, 844),
      Size(768, 1024),
      Size(1440, 900),
    ]) {
      final (router, _, _) = await pumpShop(tester, viewport: viewport);
      router.go('/app');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await pressCtrlK(tester);
      expect(find.byType(SearchOverlay, skipOffstage: false), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'search at ${viewport.width}x${viewport.height}',
      );

      await pressEscape(tester);
      expect(
        find.byType(SearchOverlay, skipOffstage: false),
        findsNothing,
        reason: 'escape at ${viewport.width}x${viewport.height}',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}
