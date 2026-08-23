import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carebridge_ai/main.dart';

void main() {
  testWidgets('CareBridgeApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CareBridgeApp());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CareBridgeApp), findsOneWidget);
  });
}
