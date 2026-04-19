import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kugla/app/theme.dart';
import 'package:kugla/models/app_state.dart';
import 'package:kugla/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen paints hero copy', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildKuglaTheme(),
        home: Scaffold(
          body: HomeScreen(
            snapshot: AppSnapshot.empty(),
            onStartMission: (_) {},
            onOpenVault: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Daily pulse is ready'), findsOneWidget);
    expect(find.text('ROUTES'), findsOneWidget);
  });
}
