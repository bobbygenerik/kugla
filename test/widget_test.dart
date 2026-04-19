// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kugla/app/app_shell.dart';
import 'package:kugla/app/theme.dart';

void main() {
  testWidgets('app shell renders landing UI', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding_v1': true,
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: buildKuglaTheme(),
        home: const AppShell(),
      ),
    );
    var waited = Duration.zero;
    const timeout = Duration(seconds: 10);
    while (waited < timeout &&
        find.textContaining('Daily pulse is ready').evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 250));
      waited += const Duration(milliseconds: 250);
    }

    expect(find.text('Mission Briefing'), findsNothing);
    expect(find.textContaining('Daily pulse is ready'), findsOneWidget);

    await tester.tap(find.text('Records'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Hall of Navigators'), findsOneWidget);
    expect(find.textContaining('Daily pulse is ready'), findsNothing);

    await tester.tap(find.text('Explore'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Daily pulse is ready'), findsOneWidget);
  });
}
