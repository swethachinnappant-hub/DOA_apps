import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Color _primary = Color(0xFF1E3A5F);

List<String> _images(int count) {
  return List.generate(count, (i) => 'https://example.com/img_$i.jpg');
}

Widget _host(
  List<String> images, {
  bool autoSlide = true,
  bool showDots = true,
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme(),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 200,
          height: 260,
          child: ProductImageCarousel(
            images: images,
            autoSlide: autoSlide,
            showDots: showDots,
            interval: const Duration(milliseconds: 100),
            placeholderIcon: Icons.checkroom,
            placeholderColor: const Color(0xFFF1F3F6),
            placeholderAccent: _primary,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('auto advances to the next image after the interval', (tester) async {
    await tester.pumpWidget(_host(_images(4)));

    final state = tester.state<ProductImageCarouselState>(
      find.byType(ProductImageCarousel),
    );
    expect(state.currentIndex, 0);

    // Fire the interval, then run the page transition to completion.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(AppDurations.slow);
    await tester.pump();

    expect(state.currentIndex, 1);
  });

  testWidgets('keeps advancing when the interval is shorter than the transition',
      (tester) async {
    await tester.pumpWidget(_host(_images(4)));

    final state = tester.state<ProductImageCarouselState>(
      find.byType(ProductImageCarousel),
    );

    // Ticks land mid-transition; the carousel must still commit the page
    // rather than restarting the animation forever.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(state.currentIndex, 1);
  });

  testWidgets('holds position when autoSlide is disabled', (tester) async {
    await tester.pumpWidget(_host(_images(4), autoSlide: false));

    final state = tester.state<ProductImageCarouselState>(
      find.byType(ProductImageCarousel),
    );

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(AppDurations.slow);

    expect(state.currentIndex, 0);
  });

  testWidgets('goTo jumps to the requested image', (tester) async {
    await tester.pumpWidget(_host(_images(5), autoSlide: false));

    final state = tester.state<ProductImageCarouselState>(
      find.byType(ProductImageCarousel),
    );
    state.goTo(3);
    await tester.pumpAndSettle();

    expect(state.currentIndex, 3);
  });

  testWidgets('lays out with no overflow on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(_images(3)));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders nothing when images are empty', (tester) async {
    await tester.pumpWidget(_host(const []));

    expect(tester.takeException(), isNull);
  });
}
