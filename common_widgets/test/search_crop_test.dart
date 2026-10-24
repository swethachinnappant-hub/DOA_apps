import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Regression: the theme's InputDecorationTheme paints filled rounded rects.
  // AppSearchField nests a TextField inside a bordered Container pill, so the
  // inner field must be fully transparent (no fill, no border) — otherwise a
  // second "inner box" appears inside the search pill.
  testWidgets('AppSearchField renders a single box (inner field is transparent)',
      (tester) async {
    tester.view.physicalSize = const Size(390, 120);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFFEEEEEE),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFFCCCCCC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFFCCCCCC)),
            ),
          ),
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchField(
              hint: 'Search jewellery, SKU, category...',
              trailing: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt_outlined),
                  Icon(Icons.mic_none),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    final dec = field.decoration!;

    // No nested fill that would paint a second box inside the pill.
    expect(dec.filled, isFalse);
    expect(dec.fillColor, Colors.transparent);

    // No border on the inner field — the outer Container supplies the box.
    expect(dec.border, InputBorder.none);
    expect(dec.enabledBorder, InputBorder.none);
    expect(dec.focusedBorder, InputBorder.none);
  });
}
