import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EcommerceApp());
    await tester.pumpAndSettle();
    expect(find.text('Select Your Business'), findsOneWidget);
  });
}
