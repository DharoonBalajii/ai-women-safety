import 'package:flutter_test/flutter_test.dart';

import 'package:ai_women_safety/main.dart';

void main() {
  testWidgets('App boots to the home screen with the SOS beacon', (WidgetTester tester) async {
    await tester.pumpWidget(const AiWomenSafetyApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('AI WOMEN SAFETY'), findsOneWidget);
    expect(find.text('HOLD TO ALERT'), findsOneWidget);
  });
}
