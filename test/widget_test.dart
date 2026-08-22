import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:knowit/data/pills_data.dart';
import 'package:knowit/data/pills_repository.dart';
import 'package:knowit/main.dart';
import 'package:knowit/widgets/ui.dart';

/// Pumps a few frames so the async `SharedPreferences` load settles.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// An install that is past the first run, on the free plan unless told
/// otherwise.
Map<String, Object> _installed({bool plus = false}) => {
  'knowit.onboarded': true,
  'knowit.plus': plus,
};

Future<void> _openProfile(WidgetTester tester) async {
  await tester.tap(find.text('Profile').last);
  await _settle(tester);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // Run against a real handset surface rather than the 800x600 default, so
  // layouts are exercised at the size they actually ship at.
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views
        .first;
    view.physicalSize = const Size(402, 874) * 3;
    view.devicePixelRatio = 3;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views
        .first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('a fresh install opens on the welcome screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    expect(find.text('Five things worth saying out loud.'), findsOneWidget);
    expect(find.text('Get my first five'), findsOneWidget);
  });

  testWidgets('the first run goes straight to today on the default mix', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    await tester.tap(find.text('Get my first five'));
    await _settle(tester);

    // No topic step and no notification step: picking a mix is a Knowit+ perk.
    expect(find.text('What should we talk about?'), findsNothing);
    expect(find.text('Today'), findsWidgets);
  });

  testWidgets('signing in keeps the name and lands on the tab bar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    await tester.tap(find.text('I already have an account'));
    await _settle(tester);
    expect(find.text('Welcome back.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'marco@studio.it');
    await _settle(tester);
    await tester.tap(find.text('Send me a login link'));
    await _settle(tester);

    expect(find.text('Today'), findsWidgets);
    await _openProfile(tester);
    expect(find.text('Marco'), findsOneWidget);
  });

  testWidgets('an onboarded install opens straight on the tab bar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(_installed());
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Saved'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('Saved shows the empty state', (tester) async {
    SharedPreferences.setMockInitialValues(_installed());
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    await tester.tap(find.text('Saved').last);
    await _settle(tester);
    expect(find.text("Keep the ones you'll actually use"), findsOneWidget);
  });

  group('Knowit+ gates the three perks', () {
    testWidgets('the archive opens the paywall on the free plan', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const KnowitApp());
      await _settle(tester);

      await tester.tap(find.text('Saved').last);
      await _settle(tester);
      await tester.tap(find.text('Archive').first);
      await _settle(tester);

      expect(find.text('Ten pills a day, and nothing gets lost.'), findsOneWidget);
      expect(find.text('Archive'), findsNothing);
    });

    testWidgets('the topic picker opens the paywall on the free plan', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const KnowitApp());
      await _settle(tester);

      await _openProfile(tester);
      await tester.tap(find.text('Edit'));
      await _settle(tester);

      expect(find.text('Ten pills a day, and nothing gets lost.'), findsOneWidget);
      expect(find.text('What should we talk about?'), findsNothing);
    });

    testWidgets('the archive opens for real on Knowit+', (tester) async {
      SharedPreferences.setMockInitialValues(_installed(plus: true));
      await tester.pumpWidget(const KnowitApp());
      await _settle(tester);

      await tester.tap(find.text('Saved').last);
      await _settle(tester);
      await tester.tap(find.text('Archive').first);
      await _settle(tester);

      expect(find.textContaining('RESULTS'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzzzznotathing');
      await _settle(tester);
      expect(find.text('0 RESULTS'), findsOneWidget);
    });

    testWidgets('starting the trial unlocks what was gated', (tester) async {
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const KnowitApp());
      await _settle(tester);

      await tester.tap(find.text('Saved').last);
      await _settle(tester);
      await tester.tap(find.text('Archive').first);
      await _settle(tester);

      // The paywall stands in for the archive; taking the trial should carry
      // the reader through to what they reached for.
      await tester.scrollUntilVisible(find.text('Monthly'), 260);
      await _settle(tester);
      await tester.tap(find.textContaining('Try 7 days free'));
      await _settle(tester);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('knowit.plus'), isTrue);
      expect(find.textContaining('RESULTS'), findsOneWidget);
    });
  });

  testWidgets('the paywall plan choice rewrites the call to action', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(_installed());
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    await _openProfile(tester);
    await tester.tap(find.text('Upgrade'));
    await _settle(tester);

    await tester.scrollUntilVisible(find.text('Monthly'), 260);
    await _settle(tester);
    expect(find.text('Try 7 days free, then €24,99/yr'), findsOneWidget);

    await tester.tap(find.text('Monthly'));
    await _settle(tester);
    expect(find.text('Try 7 days free, then €3,99/mo'), findsOneWidget);
  });

  testWidgets('the daily nudge toggle flips and persists', (tester) async {
    SharedPreferences.setMockInitialValues(_installed());
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    await _openProfile(tester);
    expect(find.text('Every day at 08:30'), findsOneWidget);

    await tester.tap(find.byType(NudgeSwitch));
    await _settle(tester);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('knowit.notifications'), isFalse);

    await tester.tap(find.byType(NudgeSwitch));
    await _settle(tester);
    expect(prefs.getBool('knowit.notifications'), isTrue);
  });

  testWidgets('Knowit+ hands over the second set once the day is done', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(_installed(plus: true));
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Next pill'));
      await _settle(tester);
    }

    expect(find.text('Your second set is ready'), findsOneWidget);
    // The recap scrolls; the button sits below the fold.
    await tester.ensureVisible(find.text('Read 5 more'));
    await _settle(tester);
    await tester.tap(find.text('Read 5 more'));
    await _settle(tester);

    // Back to reading, on pill six of ten.
    expect(find.text('Next pill'), findsOneWidget);
    expect(find.text('06 / 10'), findsOneWidget);
  });

  testWidgets('the free plan is offered the upsell instead', (tester) async {
    SharedPreferences.setMockInitialValues(_installed());
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Next pill'));
      await _settle(tester);
    }

    await tester.ensureVisible(find.text('Want 5 more?'));
    await _settle(tester);
    expect(find.text('Want 5 more?'), findsOneWidget);
    expect(find.text('Read 5 more'), findsNothing);
  });

  test('a day never deals a pill already read', () {
    // Four mornings in a row, each dealt with the history so far.
    final seen = <String>{};
    for (var day = 1; day <= 4; day++) {
      final deck = pillsForDate(DateTime(2026, 1, day), exclude: seen);
      expect(deck, hasLength(5));
      expect(
        deck.map((p) => p.id).where(seen.contains),
        isEmpty,
        reason: 'day $day re-dealt a pill already read',
      );
      seen.addAll(deck.map((p) => p.id));
    }
    expect(seen, hasLength(20));
  });

  test('the dealer falls back to read pills once the pool runs dry', () {
    final everything = kPillPool.map((p) => p.id).toSet();
    final deck = pillsForDate(DateTime(2026, 1, 1), exclude: everything);
    // Still a full day rather than an empty one.
    expect(deck, hasLength(5));
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
      ..._installed(),
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
