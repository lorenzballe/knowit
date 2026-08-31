import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pills_data.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/main.dart';
import 'package:astuto/screens/pill_detail_screen.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/widgets/brand_mark.dart';
import 'package:astuto/widgets/record_share_sheet.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/chunky.dart';
import 'package:astuto/widgets/scaled_text.dart';
import 'package:astuto/widgets/motion.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/ui.dart';

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
  await tester.tap(find.byKey(const ValueKey('tab-Profile')));
  await _settle(tester);
}

void main() {
  // Run against a real handset surface rather than the 800x600 default, so
  // layouts are exercised at the size they actually ship at.
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(402, 874) * 3;
    view.devicePixelRatio = 3;
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('a fresh install opens on the welcome screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);

    expect(find.text('Astuto'), findsOneWidget);
    expect(
      find.text('Five smart things a day, ready to use in conversation'),
      findsOneWidget,
    );
    expect(find.text('Continue with Apple'), findsOneWidget);
  });

  testWidgets('the first run runs the subjects, then deals', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);

    await tester.tap(find.text('Continue with Apple'));
    await _settle(tester);
    // With no Firebase in a test, sign-in reports itself unavailable and says
    // so. Let the snackbar go before touching anything underneath it.
    await tester.pump(const Duration(seconds: 5));
    await _settle(tester);

    // The run opens on the first subject, one card at a time.
    expect(find.text('01'), findsOneWidget);
    expect(find.text('of 12'), findsOneWidget);
    expect(find.text('Science'), findsOneWidget);

    await tester.tap(find.text('Favourite'));
    await _settle(tester);
    expect(find.text('02'), findsOneWidget);

    // Skip keeps whatever is left rather than dropping it, so the deck is
    // never empty because somebody stopped answering.
    await tester.tap(find.text('Skip'));
    await _settle(tester);
    expect(find.text('Deal my first five'), findsOneWidget);

    await tester.tap(find.text('Deal my first five'));
    await _settle(tester);

    // And the answer is kept, not just used once.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('knowit.topicWeights'), isNotNull);
    expect(prefs.getBool('knowit.onboarded'), isTrue);
  });

  testWidgets('an onboarded install opens straight on the tab bar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(_installed());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);

    expect(find.byKey(const ValueKey('tab-Today')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab-Saved')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab-Profile')), findsOneWidget);
  });

  testWidgets('Saved shows the empty state', (tester) async {
    SharedPreferences.setMockInitialValues(_installed());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('tab-Saved')));
    await _settle(tester);
    expect(find.text("Keep the ones you'll actually use"), findsOneWidget);
  });

  group('Astuto+ gates the three perks', () {
    testWidgets('the archive opens the paywall on the free plan', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);

      await tester.tap(find.byKey(const ValueKey('tab-Saved')));
      await _settle(tester);
      await tester.tap(find.text('Archive').first);
      await _settle(tester);

      expect(
        find.text('Find out if you are actually getting better.'),
        findsOneWidget,
      );
      expect(find.text('Archive'), findsNothing);
    });

    testWidgets('the topic picker opens the paywall on the free plan', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);

      await _openProfile(tester);
      await tester.scrollUntilVisible(find.text('Edit'), 200);
      await _settle(tester);
      await tester.tap(find.text('Edit'));
      await _settle(tester);

      expect(
        find.text('Find out if you are actually getting better.'),
        findsOneWidget,
      );
      expect(find.text('What should we talk about?'), findsNothing);
    });

    testWidgets('the archive opens for real on Astuto+', (tester) async {
      SharedPreferences.setMockInitialValues(_installed(plus: true));
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);

      await tester.tap(find.byKey(const ValueKey('tab-Saved')));
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
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);

      await tester.tap(find.byKey(const ValueKey('tab-Saved')));
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
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);

    await tester.tap(find.byIcon(Icons.ios_share_rounded));
    await _settle(tester);

    // The share sheet, not the paywall.
    expect(find.text('Share this pill'), findsOneWidget);
    expect(
      find.text('Find out if you are actually getting better.'),
      findsNothing,
    );
  });

  test('the mix the reader dragged governs every card it can', () {
    // Worth stating plainly, because it bounds what the radar can promise:
    // four cards in five have to ask something, and everything that asks
    // lives under Thinking. So the mix governs the reading card, and the
    // reading card only — but it governs it completely.
    const weights = {'space': 1.0, 'history': 1.0};
    final seen = <String>{};

    // Two subjects hold ten facts between them, and a day reads one. So ten
    // days is exactly the supply.
    for (var d = 0; d < 10; d++) {
      final deck = pillsForDate(
        DateTime(2026, 3, 1).add(Duration(days: d)),
        topics: weights.keys.toSet(),
        weights: weights,
        exclude: seen,
      );
      for (final pill in deck.where((p) => !p.asksSomething)) {
        expect(
          pill.topic,
          anyOf('Space', 'History'),
          reason: 'day ${d + 1} dealt a subject nobody asked for',
        );
      }
      seen.addAll(deck.map((p) => p.id));
    }

    // Past that the chosen subjects are spent, and the dealer reaches outside
    // them rather than handing over a short day.
    final eleventh = pillsForDate(
      DateTime(2026, 3, 11),
      topics: weights.keys.toSet(),
      weights: weights,
      exclude: seen,
    );
    expect(eleventh, hasLength(kPillsPerDay));
  });

  test('a narrow mix still fills a whole day', () {
    // Pushing everything in but one subject must not leave short days: the
    // dealer falls back rather than handing over three cards.
    const weights = {'space': 1.0};
    final deck = pillsForDate(
      DateTime(2026, 3, 1),
      topics: {'space'},
      weights: weights,
    );
    expect(deck, hasLength(kPillsPerDay));
  });

  group('Streak freezes', () {
    Future<AppState> appWith(Map<String, Object> extra) async {
      SharedPreferences.setMockInitialValues({..._installed(), ...extra});
      final app = AppState();
      await app.init();
      return app;
    }

    String key(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    test('one missed day is covered, and the streak lives', () async {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final app = await appWith({
        'knowit.streak': 9,
        'knowit.lastCompletionDate': key(twoDaysAgo),
        'knowit.freezes': 1,
      });

      expect(app.liveStreak, 9, reason: 'the freeze should have covered it');
      expect(app.freezes, 0);
      expect(app.streakWasFrozen, isTrue);
    });

    test('a gap too wide to cover keeps the freezes and breaks', () async {
      final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));
      final app = await appWith({
        'knowit.streak': 9,
        'knowit.lastCompletionDate': key(fiveDaysAgo),
        'knowit.freezes': 1,
      });

      // Spending them and breaking anyway would be the worst of both.
      expect(app.liveStreak, 0);
      expect(app.freezes, 1);
      expect(app.streakWasFrozen, isFalse);
    });

    test('the free plan holds one, Astuto+ holds three', () async {
      final free = await appWith({});
      expect(free.freezeCapacity, 1);

      final plus = await appWith({'knowit.plus': true});
      expect(plus.freezeCapacity, 3);
    });
  });

  test('the very first day is the chosen one', () async {
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    final app = AppState();
    await app.init();

    // A generated first day is a gamble on the worst possible occasion.
    expect(app.todaysDeck.map((p) => p.id).toList(), kOpeningDeck);

    // And it is only the first: once anything has been read, the dealer takes
    // over again.
    expect(kOpeningDeck, hasLength(kPillsPerDay));
    expect(
      kOpeningDeck.every((id) => kPillPool.any((p) => p.id == id)),
      isTrue,
      reason: 'the opening deck names a card that does not exist',
    );
  });

  test('a day never fills up with opinions', () {
    // Debates are ungraded, so a deck of them measures nothing. With twenty
    // in the pool a random day could otherwise come out as four in a row.
    final seen = <String>{};
    for (var d = 0; d < 40; d++) {
      final deck = arrangeDay(
        pillsForDate(
          DateTime(2026, 1, 1).add(Duration(days: d)),
          exclude: seen,
        ),
      );
      final debates = deck.where((p) => p.challenge is TakeASide).length;
      expect(
        debates,
        lessThanOrEqualTo(1),
        reason: 'day ${d + 1} held $debates debates',
      );
      final graded = deck.where((p) => p.isGraded && p.asksSomething).length;
      expect(
        graded,
        greaterThanOrEqualTo(2),
        reason: 'day ${d + 1} had only $graded gradeable cards',
      );
      seen.addAll(deck.map((p) => p.id));
    }
  });

  testWidgets('every primary action is the same button', (tester) async {
    // Screens written before the lesson existed called PrimaryButton and the
    // lesson calls ChunkyButton, so the app pressed two different kinds of
    // button depending on which week a screen was written in. PrimaryButton
    // is now built on the chunky one, which is what keeps that from coming
    // back one screen at a time.
    final lapsed = DateTime.now().subtract(const Duration(days: 3));
    SharedPreferences.setMockInitialValues({
      ..._installed(),
      'knowit.streak': 13,
      'knowit.lastCompletionDate':
          '${lapsed.year.toString().padLeft(4, '0')}-'
          '${lapsed.month.toString().padLeft(2, '0')}-'
          '${lapsed.day.toString().padLeft(2, '0')}',
    });
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);

    const label = "Start again with today's five";
    expect(find.text(label), findsOneWidget);
    expect(
      find.ancestor(of: find.text(label), matching: find.byType(ChunkyButton)),
      findsOneWidget,
    );
  });

  testWidgets('opening the app lands straight on the cards', (tester) async {
    SharedPreferences.setMockInitialValues(_installed());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);

    expect(find.text('Next pill'), findsOneWidget);
    expect(find.byKey(const ValueKey('tab-Today')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab-Saved')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab-Profile')), findsOneWidget);
  });

  testWidgets('the onboarding is two screens and then the cards', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'knowit.onboarded': false});
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);

    // One: the intro. Skip takes the same road as the buttons do.
    await tester.tap(find.text('Skip'));
    await _settle(tester);

    // Two: the subject run.
    expect(find.text('Science'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await _settle(tester);
    await tester.tap(find.text('Deal my first five'));
    await _settle(tester);

    expect(find.text('Next pill'), findsOneWidget);
  });

  testWidgets('the paywall sells only what it delivers', (tester) async {
    SharedPreferences.setMockInitialValues(_installed());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);

    await _openProfile(tester);
    await tester.scrollUntilVisible(find.text('Upgrade'), 200);
    await _settle(tester);
    await tester.tap(find.text('Upgrade'));
    await _settle(tester);

    // The perks scroll now, so each is reached the way a reader reaches it.
    // The two the pivot added have to exist as screens before they may be
    // sold — both are on the profile, so naming them here is a promise this
    // test holds the paywall to.
    for (final perk in const [
      'Your record over time',
      'Every principle you have met',
      'Three streak freezes, not one',
      '5 extra pills every day',
      'The full archive',
      'Pick your own topics',
    ]) {
      await tester.scrollUntilVisible(find.text(perk), 200);
      await _settle(tester);
      expect(find.text(perk), findsOneWidget);
    }
    // Sharing left the paywall when it became free.
    expect(find.text('Share as image'), findsNothing);
  });

  testWidgets('the paywall plan choice rewrites the call to action', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(_installed());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);

    await _openProfile(tester);
    await tester.scrollUntilVisible(find.text('Upgrade'), 200);
    await _settle(tester);
    await tester.tap(find.text('Upgrade'));
    await _settle(tester);

    // Yearly leads and is preselected, so the call to action opens on it —
    // and the call to action is pinned, so it never scrolls away.
    expect(find.text('Try 7 days free, then €24,99/yr'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Monthly'), 260);
    await _settle(tester);
    // The saving is worked out from the two prices rather than asserted.
    expect(find.text('SAVE 48%'), findsOneWidget);
    await tester.tap(find.text('Monthly'));
    await _settle(tester);
    expect(find.text('Try 7 days free, then €3,99/mo'), findsOneWidget);
  });

  testWidgets('the daily nudge toggle flips and persists', (tester) async {
    SharedPreferences.setMockInitialValues(_installed());
    await tester.pumpWidget(const AstutoApp());
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

  testWidgets('Astuto+ hands over the second set once the day is done', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(_installed(plus: true));
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Next pill'));
      await _settle(tester);
    }

    expect(find.text('Your second set is ready'), findsOneWidget);
    // The recap scrolls; the offer sits below the way back into the cards.
    await tester.ensureVisible(find.text('READ 5 MORE'));
    await _settle(tester);
    await tester.tap(find.text('READ 5 MORE'));
    await _settle(tester);

    // Back to reading, on pill six of ten.
    expect(find.text('Next pill'), findsOneWidget);
    expect(find.text('06 / 10'), findsOneWidget);
  });

  testWidgets('finishing the day gives a short summary and a way back', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(_installed());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Next pill'));
      await _settle(tester);
    }

    // Short: it says it is done and how it went, and nothing else has to be
    // scrolled past to get back to the cards.
    expect(find.text('Done for today.'), findsOneWidget);
    expect(find.text('CARDS'), findsOneWidget);
    expect(find.text('RIGHT'), findsOneWidget);

    final again = find.text("SHOW TODAY'S CARDS AGAIN");
    expect(again, findsOneWidget);
    await tester.tap(again);
    await _settle(tester);

    // And it lands on the five, face down.
    expect(find.text("Today's five"), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);
  });

  testWidgets('the free plan is offered the upsell instead', (tester) async {
    SharedPreferences.setMockInitialValues(_installed());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Next pill'));
      await _settle(tester);
    }

    await tester.ensureVisible(find.text('Want 5 more?'));
    await _settle(tester);
    expect(find.text('Want 5 more?'), findsOneWidget);
    expect(find.text('READ 5 MORE'), findsNothing);
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

    test('no two cards are the same card', () {
      // The pool once held the Mpemba effect twice and the trailer horn
      // twice, under questions worded just differently enough to miss. This
      // compares content words rather than strings.
      const noise = {
        'the',
        'a',
        'an',
        'is',
        'are',
        'was',
        'were',
        'do',
        'does',
        'did',
        'you',
        'your',
        'we',
        'it',
        'its',
        'of',
        'in',
        'on',
        'to',
        'for',
        'why',
        'how',
        'what',
        'when',
        'where',
        'which',
        'who',
        'and',
        'or',
        'but',
        'so',
        'that',
        'this',
        'than',
        'then',
        'from',
        'at',
        'by',
        'with',
        'as',
        'be',
        'can',
        'could',
        'would',
        'should',
        'have',
        'has',
        'not',
        'no',
        'if',
        'there',
        'their',
        'they',
        'one',
        'about',
        'up',
        'out',
        'get',
        'got',
        'make',
        'made',
        'much',
        'many',
        'more',
        'most',
        'actually',
        'really',
        'ever',
        'still',
        'own',
      };
      Set<String> words(String q) => q
          .toLowerCase()
          .replaceAll(RegExp(r"[^a-z0-9 ]"), ' ')
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 2 && !noise.contains(w))
          .toSet();

      final byId = {for (final p in kPillPool) p.id: words(p.question)};
      final ids = byId.keys.toList();
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          final a = byId[ids[i]]!;
          final b = byId[ids[j]]!;
          // Two very short questions can collide on ordinary words without
          // being the same card, so only compare ones with enough substance
          // to mean something.
          if (a.length < 4 || b.length < 4) continue;
          final shared = a.intersection(b).length;
          final overlap = shared / (a.union(b).length);
          expect(
            overlap,
            lessThan(0.5),
            reason: '${ids[i]} and ${ids[j]} are asking the same thing',
          );
        }
      }
    });

    test('the pool stays off the listicle', () {
      // Everything here was in the pool and had to go: it is the material
      // every "did you know" account has already run, so a reader has met it
      // before and learns nothing. A card has to earn its place against the
      // stuff people scroll past for free.
      const tired = [
        'honey never',
        'cleopatra',
        'sharks or trees',
        'bananas are radioactive',
        'jumping the shark',
        'ship of theseus',
        'tickle yourself',
        'goosebumps',
        'shortest war',
        'turning it off and on',
        'freeze faster',
        'braaam',
      ];
      for (final pill in kPillPool) {
        final hay = '${pill.question} ${pill.answer}'.toLowerCase();
        for (final phrase in tired) {
          expect(
            hay.contains(phrase),
            isFalse,
            reason: '${pill.id} is back on the listicle: "$phrase"',
          );
        }
      }
    });

    test('every pill is complete and the answer stays short', () {
      for (final p in kPillPool) {
        expect(
          p.question.trim(),
          isNotEmpty,
          reason: '${p.id} has no question',
        );
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
          expect(
            p.question,
            endsWith('?'),
            reason: '${p.id} is not a question',
          );
        }
      }
    });
  });

  testWidgets('the theme is one choice for the whole app', (tester) async {
    SharedPreferences.setMockInitialValues(_installed());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);

    Palette paletteOn(String tabLabel) {
      final context = tester.element(find.text(tabLabel).last);
      return Theme.of(context).extension<Palette>()!;
    }

    // Whatever the tab, the same ground.
    final onToday = paletteOn('Today');
    await tester.tap(find.byKey(const ValueKey('tab-Saved')));
    await _settle(tester);
    expect(paletteOn('Saved').surface, onToday.surface);

    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await _settle(tester);
    expect(paletteOn('Profile').surface, onToday.surface);

    // And it can be changed, once, for all of it.
    await tester.scrollUntilVisible(find.text('Light'), 200);
    await _settle(tester);
    await tester.tap(find.text('Light'));
    await _settle(tester);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('knowit.theme'), 'light');
    expect(paletteOn('Profile').surface, Palette.light.surface);
    expect(paletteOn('Profile').surface, isNot(onToday.surface));
  });

  group('Motion', () {
    testWidgets('entrances leave no timer behind', (tester) async {
      // A delay built on Future.delayed outlives a disposed widget and hangs
      // pumpAndSettle. Anything that only works outside tests is a thing
      // nobody can check, so the delays are animation intervals instead.
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAstutoTheme(Brightness.dark),
          home: Scaffold(
            body: Column(
              children: [
                const RiseIn(
                  delay: Duration(milliseconds: 400),
                  child: Text('one'),
                ),
                RiseIn.staggered(3, child: const Text('two')),
                const PopIn(
                  delay: Duration(milliseconds: 300),
                  child: Text('three'),
                ),
                CountUp(value: 12, style: AppText.display(size: 20)),
              ],
            ),
          ),
        ),
      );
      // Settles, rather than throwing on a pending timer.
      await tester.pumpAndSettle();

      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
      expect(find.text('three'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);

      // Tearing down mid-flight must not leave anything running either.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('the day ends by saying when the next one starts', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('Next pill'));
        await _settle(tester);
      }

      await tester.scrollUntilVisible(find.textContaining('Five more in'), 200);
      await _settle(tester);
      expect(find.textContaining('Five more in'), findsOneWidget);
    });
  });

  group('The shape of a day', () {
    Pill fact(String id, Difficulty d) => Pill(
      id: id,
      topicKey: 'science',
      topic: 'Test',
      color: const Color(0xFF000000),
      ink: const Color(0xFFFFFFFF),
      tint: const Color(0xFFFFFFFF),
      question: 'q?',
      answer: 'a',
      barMove: 'b',
      source: 's',
      difficulty: d,
    );

    Pill asks(String id, Difficulty d, Challenge c) => Pill(
      id: id,
      topicKey: 'science',
      topic: 'Test',
      color: const Color(0xFF000000),
      ink: const Color(0xFFFFFFFF),
      tint: const Color(0xFFFFFFFF),
      question: 'q?',
      answer: 'a',
      barMove: 'b',
      source: 's',
      challenge: c,
      difficulty: d,
    );

    const pick = PickOne(options: ['a', 'b'], correct: 0);
    const side = TakeASide(positions: ['yes', 'no']);

    test('reading and answering alternate', () {
      final day = arrangeDay([
        fact('f1', Difficulty.easy),
        fact('f2', Difficulty.easy),
        fact('f3', Difficulty.easy),
        asks('p1', Difficulty.medium, pick),
        asks('p2', Difficulty.medium, pick),
      ]);

      expect(day.first.asksSomething, isFalse, reason: 'opens on a read');
      for (var i = 1; i < day.length; i++) {
        expect(
          day[i].asksSomething == day[i - 1].asksSomething,
          isFalse,
          reason: 'two of the same kind in a row at $i',
        );
      }
    });

    test('the hardest card is not saved for last', () {
      final day = arrangeDay([
        fact('f1', Difficulty.easy),
        fact('f2', Difficulty.easy),
        fact('f3', Difficulty.easy),
        asks('easy', Difficulty.easy, pick),
        asks('hard', Difficulty.hard, pick),
      ]);

      expect(day.last.id, isNot('hard'));
      // It lands early, while there is attention to spend on it.
      expect(day.indexWhere((p) => p.id == 'hard'), lessThan(3));
    });

    test('a debate closes the day', () {
      final day = arrangeDay([
        fact('f1', Difficulty.easy),
        fact('f2', Difficulty.easy),
        asks('p1', Difficulty.medium, pick),
        asks('hard', Difficulty.hard, pick),
        asks('debate', Difficulty.medium, side),
      ]);

      expect(day.last.id, 'debate');
    });

    test('it copes when a day is all of one kind', () {
      final allReads = arrangeDay([
        fact('f1', Difficulty.easy),
        fact('f2', Difficulty.easy),
        fact('f3', Difficulty.easy),
      ]);
      expect(allReads, hasLength(3));

      final allAsks = arrangeDay([
        asks('p1', Difficulty.easy, pick),
        asks('p2', Difficulty.medium, pick),
        asks('p3', Difficulty.hard, pick),
      ]);
      expect(allAsks, hasLength(3));
      expect(allAsks.map((p) => p.id), containsAll(['p1', 'p2', 'p3']));
    });

    test('a real day keeps every card it was dealt', () {
      final deck = pillsForDate(DateTime(2026, 3, 4));
      expect(deck, hasLength(5));
      expect(deck.map((p) => p.id).toSet(), hasLength(5));
    });

    test('a real day always asks something, not just tells', () {
      // Everything that asks lives under one topic, and a deck that takes
      // one card per topic used to deal four facts and a single puzzle.
      final seen = <String>{};
      for (var day = 1; day <= 8; day++) {
        final deck = pillsForDate(DateTime(2026, 3, day), exclude: seen);
        final asking = deck.where((p) => p.asksSomething).length;
        expect(
          asking,
          greaterThanOrEqualTo(2),
          reason: 'day $day only asked $asking times',
        );
        seen.addAll(deck.map((p) => p.id));
      }
    });

    test('a reader with no asking topics still gets a full day', () {
      final deck = pillsForDate(DateTime(2026, 3, 4), topics: {'space'});
      expect(deck, hasLength(5));
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
      await tester.pumpWidget(const AstutoApp());
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

      await tester.tap(find.byKey(const ValueKey('tab-Saved')));
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
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
      await _settle(tester);

      await tester.tap(find.byKey(const ValueKey('tab-Saved')));
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

  group('Type set to the space', () {
    Widget box(String text, {double width = 300, double height = 500}) =>
        MaterialApp(
          theme: buildAstutoTheme(Brightness.dark),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                height: height,
                child: ScaledText(
                  text: text,
                  min: 20,
                  max: 64,
                  styleFor: (size) => AppText.display(size: size),
                ),
              ),
            ),
          ),
        );

    double sizeOf(WidgetTester tester) =>
        tester.widget<Text>(find.byType(Text)).style!.fontSize!;

    testWidgets('a short question is set larger than a long one', (
      tester,
    ) async {
      await tester.pumpWidget(box('Why do we yawn?'));
      await tester.pumpAndSettle();
      final short = sizeOf(tester);

      await tester.pumpWidget(
        box(
          'A camera that identifies faces with 99% accuracy scans 100,000 '
          'travellers to find one wanted person. Roughly how many alarms '
          'will be wrong?',
        ),
      );
      await tester.pumpAndSettle();
      final long = sizeOf(tester);

      // The whole point: a fixed size is either too small for the short one
      // or too big for the long one, and the card looked empty because it
      // was tuned for the long one.
      expect(short, greaterThan(long));
      expect(short, lessThanOrEqualTo(64));
      expect(long, greaterThanOrEqualTo(20));
    });

    testWidgets('a taller box takes larger type for the same words', (
      tester,
    ) async {
      await tester.pumpWidget(box('Why do we yawn?', height: 200));
      await tester.pumpAndSettle();
      final small = sizeOf(tester);

      await tester.pumpWidget(box('Why do we yawn?', height: 500));
      await tester.pumpAndSettle();
      expect(sizeOf(tester), greaterThan(small));
    });

    testWidgets('text too long for the box stays reachable', (tester) async {
      final wall = List.filled(90, 'unavoidably long wording').join(' ');
      await tester.pumpWidget(box(wall, height: 160));
      await tester.pumpAndSettle();

      // Nothing clipped away: it bottoms out at min and scrolls instead.
      expect(tester.takeException(), isNull);
      expect(sizeOf(tester), 20);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });

  group('Reading the five again', () {
    Future<AppState> freshApp() async {
      SharedPreferences.setMockInitialValues(_installed());
      final app = AppState();
      await app.init();
      return app;
    }

    Widget viewer(AppState app, List<Pill> deck) => MaterialApp(
      theme: buildAstutoTheme(Brightness.dark),
      home: DeckViewerScreen(app: app, deck: deck, title: "Today's five"),
    );

    testWidgets('a card already answered still opens face down', (
      tester,
    ) async {
      final app = await freshApp();
      final pick = kPillPool.firstWhere((p) => p.challenge is PickOne);
      final correct = (pick.challenge as PickOne).correct;
      await app.recordAnswer(pick.id, '$correct', confidence: 70);

      await tester.pumpWidget(viewer(app, [pick]));
      await tester.pumpAndSettle();

      // The point of coming back is to read it again, not to be handed the
      // answer the moment the screen opens.
      expect(find.text(pick.question), findsWidgets);
      expect(find.text('Tap for the answer'), findsOneWidget);
      expect(find.text(pick.answer), findsNothing);

      await tester.tap(find.text(pick.question).first);
      await tester.pumpAndSettle();
      expect(find.text(pick.answer), findsWidgets);
      expect(find.text('That was the last one'), findsOneWidget);
    });

    testWidgets('the re-read shows which option you took', (tester) async {
      final app = await freshApp();
      final pick = kPillPool.firstWhere((p) => p.challenge is PickOne);
      final options = (pick.challenge as PickOne).options;
      await app.recordAnswer(pick.id, '1', confidence: 70);

      await tester.pumpWidget(viewer(app, [pick]));
      await tester.pumpAndSettle();

      // Coming back to a question and not being shown your own answer is
      // what makes a re-read feel broken.
      expect(find.text('YOURS'), findsOneWidget);
      expect(find.text('You answered this one.'), findsOneWidget);
      expect(
        find.text('${pick.difficulty.label} · commit before you turn it over.'),
        findsNothing,
        reason: 'it was committed days ago',
      );

      // And the mark sits on the option that was actually taken.
      final row = find.ancestor(
        of: find.text(options[1]),
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: row.first, matching: find.text('YOURS')),
        findsOneWidget,
      );
    });

    testWidgets('a card that was skipped still opens', (tester) async {
      final app = await freshApp();
      final pick = kPillPool.firstWhere((p) => p.challenge is PickOne);

      await tester.pumpWidget(viewer(app, [pick]));
      await tester.pumpAndSettle();

      // Withholding these made the re-read useless: most of a deck somebody
      // clicked through is unanswered. Commitment is enforced on the card the
      // first time it is dealt, which is where it means something.
      expect(find.text('Answer this one on Today first'), findsNothing);
      await tester.tap(find.text(pick.question).first);
      await tester.pumpAndSettle();
      expect(find.text(pick.answer), findsWidgets);
    });

    testWidgets('a fact opens without ever having been answered', (
      tester,
    ) async {
      final app = await freshApp();
      final fact = kPillPool.firstWhere((p) => p.challenge is NoChallenge);

      await tester.pumpWidget(viewer(app, [fact]));
      await tester.pumpAndSettle();
      await tester.tap(find.text(fact.question).first);
      await tester.pumpAndSettle();

      expect(find.text(fact.answer), findsWidgets);
    });

    testWidgets('swiping moves to the next card, and it is face down', (
      tester,
    ) async {
      final app = await freshApp();
      final facts = kPillPool
          .where((p) => p.challenge is NoChallenge)
          .take(2)
          .toList();

      await tester.pumpWidget(viewer(app, facts));
      await tester.pumpAndSettle();

      await tester.tap(find.text(facts[0].question).first);
      await tester.pumpAndSettle();
      expect(find.text('Swipe for the next one'), findsOneWidget);

      await tester.fling(
        find.text(facts[0].answer).first,
        const Offset(-400, 0),
        1200,
      );
      await tester.pumpAndSettle();

      expect(find.text(facts[1].question), findsWidgets);
      expect(find.text('Tap for the answer'), findsOneWidget);
      expect(find.text(facts[1].answer), findsNothing);
    });

    testWidgets('the heart keeps the card, and both actions are there', (
      tester,
    ) async {
      final app = await freshApp();
      final fact = kPillPool.firstWhere((p) => p.challenge is NoChallenge);

      await tester.pumpWidget(viewer(app, [fact]));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Share this pill'), findsOneWidget);
      expect(app.isSaved(fact.id), isFalse);

      await tester.tap(find.bySemanticsLabel('Save this pill'));
      await tester.pumpAndSettle();
      expect(app.isSaved(fact.id), isTrue);
      expect(find.bySemanticsLabel('Remove from saved'), findsOneWidget);
    });
  });

  group('The card', () {
    Widget host(
      List<Pill> deck,
      Map<String, Answer> given, {
      Set<String> reviews = const {},
    }) {
      return MaterialApp(
        theme: buildAstutoTheme(Brightness.dark),
        home: Scaffold(
          backgroundColor: Palette.dark.surface,
          body: SizedBox(
            height: 640,
            child: PillCardStack(
              deck: deck,
              index: 0,
              onAdvance: () {},
              answerFor: (id) => given[id],
              onSignal: (_, _) {},
              reviewIds: reviews,
              onAnswer: (id, response, confidence, reason) => given[id] =
                  Answer(response, confidence: confidence, reason: reason),
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
      await tester.enterText(find.byType(TextField), '${challenge.answer * 2}');
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

      // What is asked for instead is a reason, before the other side is
      // readable at all.
      expect(find.text('In one line — why?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Because of the cost.');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Now show me the other side'));
      await tester.pumpAndSettle();

      // The line written a moment ago is still on screen while the other
      // side makes its case — that is the whole point of asking for it.
      expect(find.text('"Because of the cost."'), findsOneWidget);

      // The other side is one tap away, and not shown before it is asked for.
      expect(find.text(debate.counterpoint), findsNothing);
      await tester.tap(find.text('What the other side says'));
      await tester.pumpAndSettle();
      expect(find.text(debate.counterpoint), findsOneWidget);
    });

    testWidgets('the reason step still fits on a small handset', (
      tester,
    ) async {
      // The write-why step adds a two-line field and a button to a face that
      // was already full. A 4.7-inch phone is where that runs out of room.
      tester.view.physicalSize = const Size(320, 568) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final challenge = debate.challenge as TakeASide;
      await tester.pumpWidget(host([debate], {}));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(challenge.positions.first));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('In one line — why?'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Because of the cost.');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a debate can be turned over without writing anything', (
      tester,
    ) async {
      final challenge = debate.challenge as TakeASide;
      await tester.pumpWidget(host([debate], {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text(challenge.positions.first));
      await tester.pumpAndSettle();

      // Made to type before they may read on, a reader stops reading on.
      await tester.tap(find.text('Skip — show me anyway'));
      await tester.pumpAndSettle();

      expect(find.text('YOU TOOK'), findsOneWidget);
      expect(find.text('What the other side says'), findsOneWidget);
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
      // A full reveal — verdict, answer, trap, bar move, source — is taller
      // than the card, so the offer sits below the fold and is reached the
      // way a reader reaches it.
      final offer = find.text('Explain it like I am three');
      await tester.ensureVisible(offer);
      await tester.pumpAndSettle();
      await tester.tap(offer);
      await tester.pumpAndSettle();
      expect(find.text(pill.simply), findsWidgets);
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
          theme: buildAstutoTheme(Brightness.dark),
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
          theme: buildAstutoTheme(Brightness.dark),
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

  test('being righter than you claimed is not flagged as a problem', () {
    // Underconfidence is the good direction, and a single answer in a
    // bucket says nothing either way.
    const lucky = CalibrationBucket(60, 1, 1);
    expect(lucky.gap, lessThan(0));

    const overconfident = CalibrationBucket(90, 4, 1);
    expect(overconfident.gap, 65);
  });

  group('Principles', () {
    test('the day is mostly asking, not reading', () {
      final seen = <String>{};
      for (var day = 1; day <= 6; day++) {
        final deck = pillsForDate(DateTime(2026, 4, day), exclude: seen);
        final asking = deck.where((p) => p.asksSomething).length;
        expect(
          asking,
          greaterThanOrEqualTo(4),
          reason: 'day $day only asked $asking times',
        );
        seen.addAll(deck.map((p) => p.id));
      }
    });

    test('the principles that matter have more than one context', () {
      // One instance teaches that instance. Transfer needs the same move in
      // clothes you have not seen.
      const wanted = [
        Principle.baseRate,
        Principle.survivorship,
        Principle.anchoring,
        Principle.sampling,
        Principle.confounding,
        Principle.multipleComparisons,
      ];
      for (final principle in wanted) {
        final contexts = kPillPool.where((p) => p.principle == principle);
        expect(
          contexts.length,
          greaterThanOrEqualTo(2),
          reason: '${principle.name} has only ${contexts.length} context',
        );
      }
    });

    test('a review is a new context, not the same card again', () async {
      SharedPreferences.setMockInitialValues(_installed());
      final app = AppState();
      await app.init();

      // Get a base-rate card wrong, then force it due.
      final card = kPillPool.firstWhere(
        (p) => p.principle == Principle.baseRate,
      );
      await app.recordAnswer(card.id, 'rubbish', confidence: 90);
      app.answers[card.id] = app.answers[card.id]!.copyWith(
        dueOn: dateKey(app.today),
      );

      final back = app.dueReviews;
      expect(back, hasLength(1));
      expect(back.single.principle, Principle.baseRate);
      expect(
        back.single.id,
        isNot(card.id),
        reason: 'the review repeated the card instead of the principle',
      );
    });

    test('mastery is counted per principle across contexts', () async {
      SharedPreferences.setMockInitialValues(_installed());
      final app = AppState();
      await app.init();

      final cards = kPillPool
          .where((p) => p.principle == Principle.baseRate)
          .toList();
      expect(cards.length, greaterThanOrEqualTo(2));

      final right = (cards.first.challenge as PickOne).correct;
      await app.recordAnswer(cards[0].id, '$right', confidence: 80);
      await app.recordAnswer(cards[1].id, 'rubbish', confidence: 80);

      final m = app.masteryOf(Principle.baseRate);
      expect(m.met, 2);
      expect(m.right, 1);
      expect(m.contexts, cards.length);
      expect(m.isSettled, isTrue);
    });
  });

  group('Review', () {
    test(
      'a wrong answer comes back, a right one moves up the ladder',
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
      },
    );

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
          theme: buildAstutoTheme(Brightness.dark),
          home: Scaffold(
            body: SizedBox(
              height: 640,
              child: PillCardStack(
                deck: [pill],
                index: 0,
                onAdvance: () {},
                reviewIds: {pill.id},
                answerFor: (id) => given[id],
              onSignal: (_, _) {},
                onAnswer: (id, r, c, w) =>
                    given[id] = Answer(r, confidence: c, reason: w),
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
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);

      // The app is past the splash and dealing a real day.
      expect(find.text('Astuto'), findsWidgets);
      expect(find.byKey(const ValueKey('tab-Today')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // And the deck it could not restore was re-dealt rather than left empty.
      expect(find.text('Next pill'), findsOneWidget);
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

    test('a trend needs two full windows before it says anything', () async {
      SharedPreferences.setMockInitialValues(_installed());
      final app = AppState();
      await app.init();

      // Nineteen judgements is one short of two windows of ten.
      for (var i = 0; i < 19; i++) {
        app.judgements.add(const Judgement(80, correct: true));
      }
      expect(app.trend, isNull, reason: 'not enough run to call it a trend');

      app.judgements.add(const Judgement(80, correct: true));
      expect(app.trend, isNotNull);
    });

    test('a trend reads the gap closing, not the accuracy rising', () async {
      SharedPreferences.setMockInitialValues(_installed());
      final app = AppState();
      await app.init();

      // First ten: said 90, right 5 of 10 — forty points overconfident.
      for (var i = 0; i < 10; i++) {
        app.judgements.add(Judgement(90, correct: i < 5));
      }
      // Last ten: said 60, right 6 of 10 — spot on.
      for (var i = 0; i < 10; i++) {
        app.judgements.add(Judgement(60, correct: i < 6));
      }

      final t = app.trend!;
      expect(t.early, 40);
      expect(t.recent, 0);
      expect(t.closedBy, 40);
      expect(t.isImproving, isTrue);
    });

    test('a gap that opens the other way is not an improvement', () async {
      SharedPreferences.setMockInitialValues(_installed());
      final app = AppState();
      await app.init();

      // Starts spot on, ends badly underconfident: the distance grew even
      // though the sign flipped, so this must not read as progress.
      for (var i = 0; i < 10; i++) {
        app.judgements.add(Judgement(60, correct: i < 6));
      }
      for (var i = 0; i < 10; i++) {
        app.judgements.add(Judgement(50, correct: i < 9));
      }

      final t = app.trend!;
      expect(t.recent, -40);
      expect(t.isMoving, isTrue);
      expect(t.isImproving, isFalse);
    });

    test('the shared record names the direction it is out by', () async {
      SharedPreferences.setMockInitialValues(_installed());
      final app = AppState();
      await app.init();

      for (var i = 0; i < 10; i++) {
        app.judgements.add(Judgement(90, correct: i < 5));
      }
      expect(RecordSummary.of(app).verdict, '40 points overconfident');

      app.judgements.clear();
      for (var i = 0; i < 10; i++) {
        app.judgements.add(Judgement(50, correct: i < 9));
      }
      expect(RecordSummary.of(app).verdict, '40 points underconfident');

      // Inside the band it is noise, and the card should not scold.
      app.judgements.clear();
      for (var i = 0; i < 10; i++) {
        app.judgements.add(Judgement(60, correct: i < 6));
      }
      final calibrated = RecordSummary.of(app);
      expect(calibrated.isCalibrated, isTrue);
      expect(calibrated.verdict, startsWith('Calibrated within'));
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
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);

    expect(find.text('STREAK RESET'), findsOneWidget);
    expect(find.textContaining('You missed'), findsOneWidget);

    await tester.tap(find.text("Start again with today's five"));
    await _settle(tester);
    expect(find.byKey(const ValueKey('tab-Today')), findsOneWidget);
  });

  group('BrandMark', () {
    Future<String> assetUnder(
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          // MaterialApp crossfades between themes, so without this the second
          // pump still reads the previous one.
          themeAnimationDuration: Duration.zero,
          home: const Scaffold(body: BrandMark()),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      return (image.image as AssetImage).assetName;
    }

    testWidgets('carries its own ground, so it follows the theme', (
      tester,
    ) async {
      // The mark is not a transparent glyph: showing the light one in dark
      // mode puts a cream tile on a near-black screen.
      expect(
        await assetUnder(tester, Brightness.light),
        'assets/brand/mark-light.png',
      );
      expect(
        await assetUnder(tester, Brightness.dark),
        'assets/brand/mark-dark.png',
      );
    });
  });

  group('debug tools', () {
    testWidgets('wiping puts the app back at the onboarding', (tester) async {
      SharedPreferences.setMockInitialValues({
        ..._installed(plus: true),
        'knowit.streak': 9,
        'knowit.saved': <String>['x'],
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _openProfile(tester);

      final wipe = find.text('Wipe everything and restart');
      final list = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(wipe, 400, scrollable: list);
      // scrollUntilVisible stops the moment the row appears, which can leave
      // it under the floating tab bar, where the tap would land on the bar.
      await tester.drag(list, const Offset(0, -160));
      await _settle(tester);
      await tester.tap(wipe);
      await _settle(tester);

      await tester.tap(find.text('Wipe it'));
      await _settle(tester);

      // The intro, not the tab shell.
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.byKey(const ValueKey('tab-Today')), findsNothing);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('knowit.streak'), isNull);
      expect(prefs.getBool('knowit.onboarded'), isNot(true));
    });

    testWidgets('the plan toggle turns Astuto+ on and off', (tester) async {
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _openProfile(tester);

      // Turning the plan on adds panels above this row, so it has to be
      // scrolled back into view each time rather than tapped where it was.
      Future<void> tapToggle(String label) async {
        final row = find.text(label);
        final list = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(row, 300, scrollable: list);
        await tester.drag(list, const Offset(0, -160));
        await _settle(tester);
        await tester.tap(row);
        await _settle(tester);
      }

      final prefs = await SharedPreferences.getInstance();

      await tapToggle('Turn Astuto+ on');
      expect(prefs.getBool('knowit.plus'), isTrue);

      await tapToggle('Turn Astuto+ off');
      expect(prefs.getBool('knowit.plus'), isFalse);
    });
  });
}
