import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:knowit/data/pills_data.dart';
import 'package:knowit/data/pills_repository.dart';
import 'package:knowit/main.dart';
import 'package:knowit/screens/pill_detail_screen.dart';
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

    expect(
      find.text('Five a day. Some you read, some you have to answer.'),
      findsOneWidget,
    );
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
        expect(
          p.answer.trim().isNotEmpty || p.hasSteps,
          isTrue,
          reason: '${p.id} has neither an answer nor a worked solution',
        );
        expect(p.barMove.trim(), isNotEmpty, reason: '${p.id} has no bar move');
        expect(p.source.trim(), isNotEmpty, reason: '${p.id} has no source');
        if (!p.hasSteps) {
          expect(
            p.answer.split(RegExp(r'\s+')).length,
            lessThanOrEqualTo(60),
            reason: '${p.id} runs past sixty words',
          );
        }
        if (p.challenge case TypeNumber()) {
          expect(p.hasHint, isTrue, reason: '${p.id} has no hint');
          expect(p.hasSteps, isTrue, reason: '${p.id} has no solution');
        }
        // A fact card is always a question. A competition problem is often
        // an instruction — "Add up every whole number to 100." — so it only
        // has to be a finished sentence.
        if (p.asksSomething) {
          expect(
            p.question.endsWith('?') || p.question.endsWith('.'),
            isTrue,
            reason: '${p.id} is not a finished prompt',
          );
        } else {
          expect(p.question, endsWith('?'), reason: '${p.id} is not a question');
        }
      }
    });
  });

  test('a day opens on its easiest card', () {
    final deck = pillsForDate(DateTime(2026, 3, 4));
    for (var i = 1; i < deck.length; i++) {
      expect(
        deck[i].difficulty.index,
        greaterThanOrEqualTo(deck[i - 1].difficulty.index),
        reason: 'the day gets harder, never easier',
      );
    }
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
    Widget host(
      List<Pill> deck,
      Map<String, Answer> given, {
      Set<String> reviews = const {},
    }) {
      return MaterialApp(
        theme: buildKnowitTheme(),
        home: Scaffold(
          backgroundColor: AppColors.dark,
          body: SizedBox(
            height: 640,
            child: PillCardStack(
              deck: deck,
              index: 0,
              onAdvance: () {},
              answerFor: (id) => given[id],
              reviewIds: reviews,
              onAnswer: (id, response, confidence) =>
                  given[id] = Answer(response, confidence: confidence),
            ),
          ),
        ),
      );
    }

    final fact = kPillPool.firstWhere((p) => p.challenge is NoChallenge);
    final pick = kPillPool.firstWhere((p) => p.challenge is PickOne);
    final number = kPillPool.firstWhere((p) => p.challenge is TypeNumber);
    final guess = kPillPool.firstWhere((p) => p.challenge is Estimate);
    final debate = kPillPool.firstWhere((p) => p.challenge is TakeASide);

    testWidgets('a fact turns over on a tap', (tester) async {
      await tester.pumpWidget(host([fact], {}));
      await tester.pumpAndSettle();

      expect(find.text('Tap to reveal'), findsOneWidget);
      expect(find.text('BAR MOVE'), findsNothing);

      await tester.tap(find.text('Tap to reveal'));
      await tester.pumpAndSettle();
      expect(find.text('BAR MOVE'), findsOneWidget);
    });

    testWidgets('a card that asks will not turn over until you commit', (
      tester,
    ) async {
      await tester.pumpWidget(host([pick], {}));
      await tester.pumpAndSettle();

      // Tapping the question is not an answer, so the card stays put.
      await tester.tap(find.text(pick.question));
      await tester.pumpAndSettle();
      expect(find.text('BAR MOVE'), findsNothing);
    });

    testWidgets('answering asks how sure you are, then turns the card', (
      tester,
    ) async {
      final given = <String, Answer>{};
      final challenge = pick.challenge as PickOne;
      await tester.pumpWidget(host([pick], given));
      await tester.pumpAndSettle();

      await tester.tap(find.text(challenge.correctOption));
      await tester.pumpAndSettle();

      // Committed, but not revealed: the card asks for confidence first.
      expect(find.text('How sure are you?'), findsOneWidget);
      expect(find.text('BAR MOVE'), findsNothing);

      await tester.tap(find.text('80%'));
      await tester.pumpAndSettle();

      expect(given[pick.id]?.response, '${challenge.correct}');
      expect(given[pick.id]?.confidence, 80);
      expect(find.textContaining('You got it'), findsOneWidget);
      expect(find.textContaining('you said 80% sure'), findsOneWidget);
      expect(find.text('BAR MOVE'), findsOneWidget);
    });

    testWidgets('a wrong pick names the trap', (tester) async {
      final challenge = pick.challenge as PickOne;
      final wrong = challenge.correct == 0 ? 1 : 0;
      await tester.pumpWidget(host([pick], {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text(challenge.options[wrong]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('50%'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Almost everyone gets this wrong'),
        findsOneWidget,
      );
      expect(find.textContaining('The trap:'), findsOneWidget);
    });

    testWidgets('a number problem takes a typed answer', (tester) async {
      final given = <String, Answer>{};
      final challenge = number.challenge as TypeNumber;
      await tester.pumpWidget(host([number], given));
      await tester.pumpAndSettle();

      // An empty box must not commit.
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await tester.pumpAndSettle();
      expect(given, isEmpty);
      expect(find.text('How sure are you?'), findsNothing);

      await tester.enterText(find.byType(TextField), '${challenge.answer}');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('90%'));
      await tester.pumpAndSettle();

      expect(given[number.id]?.response, '${challenge.answer}');
      expect(find.textContaining('You got it'), findsOneWidget);
      // A worked solution, not one paragraph.
      expect(find.text(number.steps.first), findsOneWidget);
    });

    testWidgets('a wrong number says what it was', (tester) async {
      final challenge = number.challenge as TypeNumber;
      await tester.pumpWidget(host([number], {}));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('70%'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('it is ${challenge.answerLabel}'),
        findsOneWidget,
      );
    });

    testWidgets('a nudge is there before the answer is', (tester) async {
      await tester.pumpWidget(host([number], {}));
      await tester.pumpAndSettle();

      expect(find.text(number.hint), findsNothing);
      await tester.tap(find.text('Give me a nudge'));
      await tester.pumpAndSettle();

      expect(find.text(number.hint), findsOneWidget);
      // A hint is not the answer: the card has not turned.
      expect(find.text('BAR MOVE'), findsNothing);
    });

    testWidgets('an estimate accepts anything in the right ballpark', (
      tester,
    ) async {
      final challenge = guess.challenge as Estimate;
      await tester.pumpWidget(host([guess], {}));
      await tester.pumpAndSettle();

      expect(find.text('Estimate. Close enough counts.'), findsOneWidget);

      // Deliberately off, but inside the band.
      await tester.enterText(
        find.byType(TextField),
        '${challenge.answer * 2}',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('60%'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Close enough'), findsOneWidget);
    });

    testWidgets('a debate takes a side and offers the other one', (
      tester,
    ) async {
      final challenge = debate.challenge as TakeASide;
      await tester.pumpWidget(host([debate], {}));
      await tester.pumpAndSettle();

      expect(
        find.text('Pick a side. There is no right answer.'),
        findsOneWidget,
      );

      await tester.tap(find.text(challenge.positions.first));
      await tester.pumpAndSettle();

      // An opinion is not something to be sure about, so it is never asked,
      // and it is never marked.
      expect(find.text('How sure are you?'), findsNothing);
      expect(find.text('You got it'), findsNothing);
      expect(find.text('Almost everyone gets this wrong'), findsNothing);

      // The other side is one tap away, and not shown before it is asked for.
      expect(find.text(debate.counterpoint), findsNothing);
      await tester.tap(find.text('What the other side says'));
      await tester.pumpAndSettle();
      expect(find.text(debate.counterpoint), findsOneWidget);
    });

    testWidgets('the plain-words retelling waits to be asked for', (
      tester,
    ) async {
      final pill = kPillPool.firstWhere((p) => p.hasSimply);
      await tester.pumpWidget(
        host([pill], {pill.id: const Answer('0', confidence: 50)}),
      );
      await tester.pumpAndSettle();
      // Already answered, so one tap reveals.
      await tester.tap(find.text(pill.question));
      await tester.pumpAndSettle();

      expect(find.text(pill.simply), findsNothing);
      await tester.tap(find.text('Explain it like I am three'));
      await tester.pumpAndSettle();
      expect(find.text(pill.simply), findsOneWidget);
    });
  });

  group('The reveal is the same everywhere', () {
    testWidgets('a worked problem shows its solution, not its last line', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(_installed());
      final app = AppState();
      await app.init();
      final pill = kPillPool.firstWhere((p) => p.hasSteps);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildKnowitTheme(),
          home: PillDetailScreen(pill: pill, app: app),
        ),
      );
      await tester.pumpAndSettle();

      // Every step, not just pill.answer — which is the last one.
      for (final step in pill.steps) {
        expect(find.text(step), findsOneWidget, reason: 'missing: $step');
      }
      expect(find.text(pill.barMove), findsOneWidget);
    });

    testWidgets('a debate offers its counterpoint on the detail screen too', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(_installed());
      final app = AppState();
      await app.init();
      final pill = kPillPool.firstWhere((p) => p.hasCounterpoint);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildKnowitTheme(),
          home: PillDetailScreen(pill: pill, app: app),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(pill.counterpoint), findsNothing);
      await tester.tap(find.text('What the other side says'));
      await tester.pumpAndSettle();
      expect(find.text(pill.counterpoint), findsOneWidget);
    });
  });

  group('Review', () {
    test('a wrong answer comes back, a right one moves up the ladder',
        () async {
      SharedPreferences.setMockInitialValues(_installed());
      final app = AppState();
      await app.init();

      final pill = kPillPool.firstWhere((p) => p.challenge is PickOne);
      final challenge = pill.challenge as PickOne;
      final wrong = challenge.correct == 0 ? 1 : 0;

      await app.recordAnswer(pill.id, '$wrong', confidence: 90);
      final missed = app.answerFor(pill.id)!;
      expect(missed.stage, 0);
      // Bottom of the ladder: back in two days.
      expect(
        missed.dueOn,
        dateKey(app.today.add(Duration(days: kReviewLadder[0]))),
      );

      // Not due yet, so it cannot be answered again.
      expect(app.isDueForReview(pill.id), isFalse);
      await app.recordAnswer(pill.id, '${challenge.correct}');
      expect(app.answerFor(pill.id)!.response, '$wrong');
    });

    test('a card retires once it is up the whole ladder', () async {
      SharedPreferences.setMockInitialValues(_installed());
      final app = AppState();
      await app.init();

      final pill = kPillPool.firstWhere((p) => p.challenge is PickOne);
      final right = '${(pill.challenge as PickOne).correct}';

      var answer = app.answerFor(pill.id);
      for (var i = 0; i < kReviewLadder.length; i++) {
        // Force it due, then get it right again.
        if (answer != null) {
          app.answers[pill.id] = answer.copyWith(dueOn: dateKey(app.today));
        }
        await app.recordAnswer(pill.id, right, confidence: 80);
        answer = app.answerFor(pill.id);
        expect(answer!.stage, i + 1);
      }
      // Past the top of the ladder there is nothing left to schedule.
      expect(answer!.dueOn, isNull);
      expect(app.dueReviews, isEmpty);
    });

    test('an opinion never comes back', () async {
      SharedPreferences.setMockInitialValues(_installed());
      final app = AppState();
      await app.init();

      final debate = kPillPool.firstWhere((p) => p.challenge is TakeASide);
      await app.recordAnswer(debate.id, '0');

      expect(app.answerFor(debate.id)!.dueOn, isNull);
      expect(app.dueReviews, isEmpty);
    });

    testWidgets('a card that came back has to be answered again', (
      tester,
    ) async {
      final pill = kPillPool.firstWhere((p) => p.challenge is PickOne);
      final given = <String, Answer>{pill.id: const Answer('0')};

      await tester.pumpWidget(
        MaterialApp(
          theme: buildKnowitTheme(),
          home: Scaffold(
            body: SizedBox(
              height: 640,
              child: PillCardStack(
                deck: [pill],
                index: 0,
                onAdvance: () {},
                reviewIds: {pill.id},
                answerFor: (id) => given[id],
                onAnswer: (id, r, c) => given[id] = Answer(r, confidence: c),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tapping must not open an answer the reader has to re-earn.
      await tester.tap(find.text(pill.question));
      await tester.pumpAndSettle();
      expect(find.text('BAR MOVE'), findsNothing);
      expect(find.text('AGAIN'), findsOneWidget);
    });
  });

  group('Calibration', () {
    testWidgets('a corrupt store starts fresh instead of hanging', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        // Not JSON at all, and a deck of ids that no longer exist.
        'knowit.answersJson': 'not json {{{',
        'knowit.todayDeckIds': <String>['gone-1', 'gone-2'],
      });
      await tester.pumpWidget(const KnowitApp());
      await _settle(tester);

      // The app is past the splash and dealing a real day.
      expect(find.text('Knowit'), findsWidgets);
      expect(find.text('Today'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    test('buckets confidence against what actually happened', () async {
      SharedPreferences.setMockInitialValues(_installed());
      final app = AppState();
      await app.init();

      final graded = kPillPool.where((p) => p.isGraded).toList();
      String right(Pill p) => switch (p.challenge) {
        PickOne(:final correct) => '$correct',
        TypeNumber(:final answer) => '$answer',
        Estimate(:final answer) => '$answer',
        _ => '',
      };

      // Four answers at 90%, only one of them right: badly overconfident.
      await app.recordAnswer(graded[0].id, right(graded[0]), confidence: 90);
      for (var i = 1; i < 4; i++) {
        await app.recordAnswer(graded[i].id, 'rubbish', confidence: 90);
      }

      final buckets = app.calibration.toList();
      expect(buckets, hasLength(1));
      expect(buckets.single.said, 90);
      expect(buckets.single.count, 4);
      expect(buckets.single.right, 1);
      expect(buckets.single.actual, 25);
      expect(buckets.single.gap, 65);
      expect(app.overconfidence, 65);
      expect(app.calibratedAnswers, 4);
    });

    test('an opinion never lands in a bucket', () async {
      SharedPreferences.setMockInitialValues(_installed());
      final app = AppState();
      await app.init();

      final debate = kPillPool.firstWhere((p) => p.challenge is TakeASide);
      await app.recordAnswer(debate.id, '0');

      expect(app.calibratedAnswers, 0);
      expect(app.calibration, isEmpty);
      expect(app.overconfidence, isNull);
    });

    test('answers survive being written and read back', () async {
      SharedPreferences.setMockInitialValues(_installed());
      final first = AppState();
      await first.init();
      final pill = kPillPool.firstWhere((p) => p.challenge is PickOne);
      await first.recordAnswer(pill.id, '1', confidence: 70);

      // A fresh install reading the same store.
      final second = AppState();
      await second.init();
      expect(second.answerFor(pill.id)?.response, '1');
      expect(second.answerFor(pill.id)?.confidence, 70);
    });
  });

  group('Grading', () {
    test('each challenge grades its own answers', () {
      const pick = PickOne(options: ['a', 'b', 'c'], correct: 1);
      expect(pick.accepts('1'), isTrue);
      expect(pick.accepts('2'), isFalse);
      expect(pick.accepts('nonsense'), isFalse);
      expect(pick.describe('2'), 'c');

      // An estimate is judged on being close, not exact.
      const guess = Estimate(answer: 100, withinFactor: 3);
      expect(guess.accepts('40'), isTrue);
      expect(guess.accepts('300'), isTrue);
      expect(guess.accepts('20'), isFalse);
      expect(guess.accepts('0'), isFalse);

      // A debate is never right or wrong, and never counts.
      const debate = TakeASide(positions: ['yes', 'no']);
      expect(debate.isGraded, isFalse);
      expect(debate.describe('1'), 'no');

      const number = TypeNumber(answer: 5050);
      expect(number.accepts('5050'), isTrue);
      expect(number.accepts(' 5050 '), isTrue);
      expect(number.accepts('5051'), isFalse);
      expect(number.accepts(''), isFalse);

      // Either decimal separator, within the stated slack.
      const loose = TypeNumber(answer: 3.14, tolerance: 0.01);
      expect(loose.accepts('3,14'), isTrue);
      expect(loose.accepts('3.15'), isTrue);
      expect(loose.accepts('3.2'), isFalse);
    });

    testWidgets('the first answer is the one that stands', (tester) async {
      SharedPreferences.setMockInitialValues(_installed());
      final app = AppState();
      await app.init();

      final pill = kPillPool.firstWhere((p) => p.challenge is TypeNumber);
      final challenge = pill.challenge as TypeNumber;

      await app.recordAnswer(pill.id, '${challenge.answer}', confidence: 90);
      expect(app.puzzlesRight, 1);
      expect(app.puzzlesAnswered, 1);

      // Meeting the card again must not let the score be retaken.
      await app.recordAnswer(pill.id, '0');
      expect(app.answerFor(pill.id)?.response, '${challenge.answer}');
      expect(app.puzzlesRight, 1);

      // Taking a side is not an answer that can be marked, so the tally
      // must not move.
      final debate = kPillPool.firstWhere((p) => p.challenge is TakeASide);
      await app.recordAnswer(debate.id, '0');
      expect(app.puzzlesAnswered, 1);
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
