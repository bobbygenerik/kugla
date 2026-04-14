// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kugla/app/app_shell.dart';

void main() {
  testWidgets('app shell renders landing UI', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding_v1': true,
    });
    await tester.pumpWidget(const KuglaApp());
    await tester.pumpAndSettle();

    expect(find.text('Mission Briefing'), findsNothing);
    expect(find.textContaining('You see the ground.'), findsOneWidget);
  });
}
