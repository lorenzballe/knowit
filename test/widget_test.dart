import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:knowit/main.dart';
import 'package:knowit/widgets/ui.dart';

/// Pumps a few frames so the async `SharedPreferences` load settles.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('a fresh install opens on the welcome screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    expect(find.text('Five things worth saying out loud.'), findsOneWidget);
    expect(find.text('Get my first five'), findsOneWidget);
  });

  testWidgets('onboarding runs welcome to topics to nudge to shell', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    await tester.tap(find.text('Get my first five'));
    await _settle(tester);
    expect(find.text('What should we talk about?'), findsOneWidget);

    // All twelve topics start selected, so the CTA is already live.
    await tester.tap(find.textContaining('Start with'));
    await _settle(tester);
    expect(find.text('Your 5 pills are ready'), findsOneWidget);

    await tester.tap(find.text('Turn the nudge on'));
    await _settle(tester);
    expect(find.text('Today'), findsWidgets);
  });

  testWidgets('the topic picker blocks fewer than three topics', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    await tester.tap(find.text('Get my first five'));
    await _settle(tester);

    // Turn off ten of the twelve, leaving two selected.
    for (final name in const [
      'Science',
      'Space',
      'Psychology',
      'Economics',
      'Technology',
      'History',
      'Human body',
      'Philosophy',
      'Pop culture',
      'Nature',
    ]) {
      await tester.tap(find.text(name));
      await tester.pump();
    }

    expect(find.text('Pick at least 3'), findsOneWidget);
    expect(find.text('2 of 12 selected'), findsOneWidget);
  });

  testWidgets('an onboarded install opens straight on the tab bar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Saved'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('Saved shows the empty state, then the archive', (tester) async {
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    await tester.tap(find.text('Saved').last);
    await _settle(tester);
    expect(find.text("Keep the ones you'll actually use"), findsOneWidget);

    // Both Saved and Profile live in the IndexedStack, and each has an
    // "Archive" label — the first is the one on the visible tab.
    await tester.tap(find.text('Archive').first);
    await _settle(tester);
    expect(find.textContaining('RESULTS'), findsOneWidget);
  });

  testWidgets('search filters the archive down', (tester) async {
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    await tester.tap(find.text('Saved').last);
    await _settle(tester);
    await tester.tap(find.text('Archive').first);
    await _settle(tester);

    await tester.enterText(find.byType(TextField), 'zzzzznotathing');
    await _settle(tester);
    expect(find.text('0 RESULTS'), findsOneWidget);
  });

  testWidgets('the profile reaches the Knowit+ paywall', (tester) async {
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    await tester.tap(find.text('Profile').last);
    await _settle(tester);

    await tester.tap(find.text('Upgrade'));
    await _settle(tester);

    expect(find.text('Ten pills a day, and nothing gets lost.'), findsOneWidget);

    // The plans and the CTA sit below the fold of a lazy ListView.
    await tester.scrollUntilVisible(find.text('Monthly'), 260);
    await _settle(tester);
    expect(find.textContaining('Try 7 days free'), findsOneWidget);

    // Switching plan rewrites the call to action.
    await tester.tap(find.text('Monthly'));
    await _settle(tester);
    expect(find.text('Try 7 days free, then €3,99/mo'), findsOneWidget);
  });

  testWidgets('the daily nudge toggle flips and persists', (tester) async {
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    await tester.tap(find.text('Profile').last);
    await _settle(tester);
    expect(find.text('Every day at 08:30'), findsOneWidget);

    await tester.tap(find.byType(NudgeSwitch));
    await _settle(tester);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('knowit.notifications'), isFalse);

    await tester.tap(find.byType(NudgeSwitch));
    await _settle(tester);
    expect(prefs.getBool('knowit.notifications'), isTrue);
  });

  testWidgets('the come-back screen appears after a lapsed streak', (
    tester,
  ) async {
    final lapsed = DateTime.now().subtract(const Duration(days: 3));
    String key(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      'knowit.streak': 13,
      'knowit.bestStreak': 13,
      'knowit.lastCompletionDate': key(lapsed),
    });
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    expect(find.text('STREAK RESET'), findsOneWidget);
    expect(find.textContaining('You missed'), findsOneWidget);

    await tester.tap(find.text("Start again with today's five"));
    await _settle(tester);
    expect(find.text('Today'), findsWidgets);
  });
}
