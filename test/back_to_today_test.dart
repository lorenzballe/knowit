import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/main.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/screens/saved_screen.dart';
import 'package:astuto/screens/today_screen.dart';

/// "Back to today's five", on an empty shelf, goes to Today. It used to
/// pop the shelf and leave the reader on Profile, where they had come from.
void main() {
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  final Finder profileList = find
      .descendant(
        of: find.byType(ProfileScreen),
        matching: find.byType(Scrollable),
      )
      .first;

  Future<void> openShelf(WidgetTester tester, String key) async {
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await settle(tester);
    final Finder row = find.byKey(ValueKey(key));
    await tester.scrollUntilVisible(row, 200, scrollable: profileList);
    await settle(tester);
    await tester.tap(row);
    await settle(tester);
    expect(find.byType(SavedScreen), findsOneWidget);
  }

  for (final shelf in ['profile-saved', 'profile-liked']) {
    testWidgets('from an empty $shelf, the button lands on Today', (
      tester,
    ) async {
      await openShelf(tester, shelf);
      await tester.tap(find.text("BACK TO TODAY'S FIVE"));
      await settle(tester);

      expect(find.byType(SavedScreen), findsNothing);
      // Today is the page in front: its left edge is the shell's.
      expect(
        tester.getTopLeft(find.byType(TodayScreen)).dx,
        tester.getTopLeft(find.byType(AstutoShell)).dx,
      );
    });
  }

  testWidgets('the shelf\'s own back arrow still goes back to Profile', (
    tester,
  ) async {
    await openShelf(tester, 'profile-saved');
    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);

    expect(find.byType(SavedScreen), findsNothing);
    expect(
      tester.getTopLeft(find.byType(ProfileScreen)).dx,
      tester.getTopLeft(find.byType(AstutoShell)).dx,
    );
  });
}
