import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Color _primary = Color(0xFF1E3A5F);

List<CategoryCarouselItem> _items(int count) {
  return List.generate(
    count,
    (i) => CategoryCarouselItem(label: 'Item $i', emoji: '\u{1F4E6}'),
  );
}

Widget _host(List<CategoryCarouselItem> items, {bool autoSlide = false}) {
  return MaterialApp(
    theme: AppTheme.lightTheme(),
    home: Scaffold(
      body: Center(
        child: CategoryCarousel(
          items: items,
          primaryColor: _primary,
          autoSlide: autoSlide,
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 1920);
    binding.platformDispatcher.views.first.devicePixelRatio = 3.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets('renders 4 items per page on a 360dp screen', (tester) async {
    await tester.pumpWidget(_host(_items(10)));

    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 3'), findsOneWidget);
    expect(find.text('Item 4'), findsNothing);
  });

  testWidgets('lays out with no overflow on a 360dp screen', (tester) async {
    await tester.pumpWidget(_host(_items(10)));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out with no overflow for single-line labels', (tester) async {
    await tester.pumpWidget(
      _host([
        const CategoryCarouselItem(label: 'Sarees', emoji: '\u{1F9E3}'),
        const CategoryCarouselItem(label: 'Kurtis', emoji: '\u{1F457}'),
        const CategoryCarouselItem(label: 'Lehengas', emoji: '\u{1F458}'),
        const CategoryCarouselItem(label: 'Suits', emoji: '\u{1F935}'),
        const CategoryCarouselItem(label: 'Fabrics', emoji: '\u{1F9F5}'),
      ]),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out with no overflow for two-line labels', (tester) async {
    await tester.pumpWidget(
      _host([
        const CategoryCarouselItem(
          label: "Children's Jewellery",
          emoji: '\u{1F476}',
        ),
        const CategoryCarouselItem(
          label: 'Bridal Jewellery',
          emoji: '\u{1F470}',
        ),
        const CategoryCarouselItem(
          label: 'Ethnic Footwear',
          emoji: '\u{1FA7F}',
        ),
        const CategoryCarouselItem(
          label: 'Home Appliances',
          emoji: '\u{1F3E0}',
        ),
        const CategoryCarouselItem(label: 'Grains & Pulses', emoji: '\u{1F33E}'),
      ]),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('auto advances to the next page after the interval', (tester) async {
    await tester.pumpWidget(_host(_items(10), autoSlide: true));
    await tester.pump();

    expect(find.text('Item 0'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Item 0'), findsNothing);
    expect(find.text('Item 4'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('supports manual swipe to the next page', (tester) async {
    await tester.pumpWidget(_host(_items(10)));
    await tester.pump();

    expect(find.text('Item 0'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-180, 0), 1200);
    await tester.pumpAndSettle();

    // Page 1 (items 4-7) is now shown; page 0 has been scrolled away.
    expect(find.text('Item 4'), findsOneWidget);
    expect(find.text('Item 7'), findsOneWidget);
    expect(find.text('Item 0'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipe back returns to the first page', (tester) async {
    await tester.pumpWidget(_host(_items(10)));
    await tester.pump();

    await tester.fling(find.byType(PageView), const Offset(-180, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('Item 4'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(180, 0), 1200);
    await tester.pumpAndSettle();

    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 4'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders nothing when items are empty', (tester) async {
    await tester.pumpWidget(_host(const []));

    expect(find.byType(PageView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CategoryGrid lays out with no overflow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: CategoryGrid(items: _items(8), primaryColor: _primary),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
