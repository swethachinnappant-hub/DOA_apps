import 'package:flutter_test/flutter_test.dart';
import 'package:account_app/main.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(const AccountApp());
    expect(find.byType(AccountApp), findsOneWidget);
  });
}
