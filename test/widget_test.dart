import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:knowit/data/pills_data.dart';
import 'package:knowit/data/pills_repository.dart';
import 'package:knowit/main.dart';
import 'package:knowit/models/pill.dart';
import 'package:knowit/state/app_state.dart';
import 'package:knowit/theme.dart';
import 'package:knowit/widgets/pill_card_stack.dart';
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
      await tester.scrollUntilVisible(find.text('Edit'), 200);
      await _settle(tester);
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

  testWidgets('sharing is free — it is how the app spreads', (tester) async {
    SharedPreferences.setMockInitialValues(_installed());
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    await tester.tap(find.byIcon(Icons.ios_share_rounded));
    await _settle(tester);

    // The share sheet, not the paywall.
    expect(find.text('Share this pill'), findsOneWidget);
    expect(find.text('Ten pills a day, and nothing gets lost.'), findsNothing);
  });

  testWidgets('the paywall sells only what it delivers', (tester) async {
    SharedPreferences.setMockInitialValues(_installed());
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    await _openProfile(tester);
    await tester.scrollUntilVisible(find.text('Upgrade'), 200);
    await _settle(tester);
    await tester.tap(find.text('Upgrade'));
    await _settle(tester);

    expect(find.text('5 extra pills every day'), findsOneWidget);
    expect(find.text('The full archive'), findsOneWidget);
    expect(find.text('Pick your own topics'), findsOneWidget);
    // Sharing left the paywall when it became free.
    expect(find.text('Share as image'), findsNothing);
  });

  testWidgets('the paywall plan choice rewrites the call to action', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(_installed());
    await tester.pumpWidget(const KnowitApp());
    await _settle(tester);

    await _openProfile(tester);
    await tester.scrollUntilVisible(find.text('Upgrade'), 200);
    await _settle(tester);
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
    await tester.scrollUntilVisible(find.text('Every day at 08:30'), 200);
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

  group('The content pool', () {
    test('has unique ids and a full set per topic', () {
      final ids = kPillPool.map((p) => p.id).toList();
      expect(ids.toSet(), hasLength(ids.length), reason: 'duplicate pill id');

      final perTopic = <String, int>{};
      for (final p in kPillPool) {
        perTopic[p.topic] = (perTopic[p.topic] ?? 0) + 1;
      }
      expect(perTopic, hasLength(13));
      // Every topic carries enough that a single-topic mix still fills a day.
      for (final entry in perTopic.entries) {
        expect(
          entry.value,
          greaterThanOrEqualTo(kPillsPerDay),
          reason: '${entry.key} cannot fill a day on its own',
        );
      }
    });

    test('every pill is complete and the answer stays short', () {
      for (final p in kPillPool) {
        expect(p.question.trim(), isNotEmpty, reason: '${p.id} has no question');
        expect(p.answer.trim(), isNotEmpty, reason: '${p.id} has no answer');
        expect(p.barMove.trim(), isNotEmpty, reason: '${p.id} has no bar move');
        expect(p.source.trim(), isNotEmpty, reason: '${p.id} has no source');
        expect(
          p.answer.split(RegExp(r'\s+')).length,
          lessThanOrEqualTo(60),
          reason: '${p.id} runs past sixty words',
        );
        expect(p.question, endsWith('?'), reason: '${p.id} is not a question');
      }
    });
  });

  test('a day never deals a pill already read', () {
    // Four mornings in a row, each dealt with the history so far.
    final seen = <String>{};
    for (var day = 1; day <= 8; day++) {
      final deck = pillsForDate(DateTime(2026, 1, day), exclude: seen);
      expect(deck, hasLength(5));
      expect(
        deck.map((p) => p.id).where(seen.contains),
        isEmpty,
        reason: 'day $day re-dealt a pill already read',
      );
      seen.addAll(deck.map((p) => p.id));
    }
    expect(seen, hasLength(40));
  });

  test('the dealer falls back to read pills once the pool runs dry', () {
    final everything = kPillPool.map((p) => p.id).toSet();
    final deck = pillsForDate(DateTime(2026, 1, 1), exclude: everything);
    // Still a full day rather than an empty one.
    expect(deck, hasLength(5));
  });

  group('Saved list', () {
    testWidgets('keeps the most recently saved pill first', (tester) async {
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const KnowitApp());
      await _settle(tester);

      // Save the first two pills of the day.
      final first = find.byIcon(Icons.favorite_border_rounded);
      await tester.tap(first.first);
      await _settle(tester);
      await tester.tap(find.text('Next pill'));
      await _settle(tester);
      await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
      await _settle(tester);

      final prefs = await SharedPreferences.getInstance();
      final order = prefs.getStringList('knowit.savedIds')!;
      expect(order, hasLength(2));

      await tester.tap(find.text('Saved').last);
      await _settle(tester);

      // The list follows that order, newest at the top.
      final rows = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .toList();
      expect(rows, contains('2 pills'));
    });

    testWidgets('removing a pill can be undone', (tester) async {
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const KnowitApp());
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
      await _settle(tester);

      await tester.tap(find.text('Saved').last);
      await _settle(tester);
      expect(find.text('1 pill'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite_rounded).first);
      await _settle(tester);
      expect(find.text('Removed from saved.'), findsOneWidget);
      expect(find.text("Keep the ones you'll actually use"), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await _settle(tester);
      expect(find.text('1 pill'), findsOneWidget);
    });
  });

  group('The card', () {
    Widget host(List<Pill> deck, Map<String, int> chosen) {
      return MaterialApp(
        theme: buildKnowitTheme(),
        home: Scaffold(
          backgroundColor: AppColors.dark,
          body: SizedBox(
            height: 600,
            child: PillCardStack(
              deck: deck,
              index: 0,
              onAdvance: () {},
              chosenFor: (id) => chosen[id],
              onChoose: (id, choice) => chosen[id] = choice,
            ),
          ),
        ),
      );
    }

    final fact = kPillPool.firstWhere((p) => !p.isPuzzle);
    final puzzle = kPillPool.firstWhere((p) => p.isPuzzle);

    testWidgets('a fact turns over on a tap', (tester) async {
      await tester.pumpWidget(host([fact], {}));
      await tester.pumpAndSettle();

      expect(find.text('Tap to reveal'), findsOneWidget);
      expect(find.text('BAR MOVE'), findsNothing);

      await tester.tap(find.text('Tap to reveal'));
      await tester.pumpAndSettle();

      expect(find.text('BAR MOVE'), findsOneWidget);
    });

    testWidgets('a puzzle will not turn over until you commit', (
      tester,
    ) async {
      await tester.pumpWidget(host([puzzle], {}));
      await tester.pumpAndSettle();

      expect(find.text('Commit before you turn it over.'), findsOneWidget);
      for (final choice in puzzle.choices) {
        expect(find.text(choice), findsOneWidget);
      }

      // Tapping the question is not an answer, so the card stays put.
      await tester.tap(find.text(puzzle.question));
      await tester.pumpAndSettle();
      expect(find.text('BAR MOVE'), findsNothing);
    });

    testWidgets('choosing turns the card and reports the outcome', (
      tester,
    ) async {
      final chosen = <String, int>{};
      await tester.pumpWidget(host([puzzle], chosen));
      await tester.pumpAndSettle();

      await tester.tap(find.text(puzzle.correctChoice));
      await tester.pumpAndSettle();

      expect(chosen[puzzle.id], puzzle.correctIndex);
      expect(find.text('You got it'), findsOneWidget);
      expect(find.text('BAR MOVE'), findsOneWidget);
    });

    testWidgets('a wrong answer names the trap', (tester) async {
      final wrong = puzzle.correctIndex == 0 ? 1 : 0;
      final chosen = <String, int>{};
      await tester.pumpWidget(host([puzzle], chosen));
      await tester.pumpAndSettle();

      await tester.tap(find.text(puzzle.choices[wrong]));
      await tester.pumpAndSettle();

      expect(find.text('Almost everyone gets this wrong'), findsOneWidget);
      expect(find.textContaining('The trap:'), findsOneWidget);
    });
  });

  group('Puzzle scoring', () {
    testWidgets('the first answer is the one that stands', (tester) async {
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const KnowitApp());
      await _settle(tester);

      final puzzle = kPillPool.firstWhere((p) => p.isPuzzle);
      final app = AppState();
      await app.init();

      await app.recordPuzzleChoice(puzzle.id, puzzle.correctIndex);
      expect(app.puzzlesRight, 1);
      expect(app.puzzlesAnswered, 1);

      // Meeting the card again must not let the score be retaken.
      final wrong = puzzle.correctIndex == 0 ? 1 : 0;
      await app.recordPuzzleChoice(puzzle.id, wrong);
      expect(app.puzzleChoice(puzzle.id), puzzle.correctIndex);
      expect(app.puzzlesRight, 1);
    });
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
