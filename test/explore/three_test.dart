// Today's three: the same three shares for everyone, guessed one at a time,
// scored, kept as the day's, counted once among today's readers, placed
// among them as they come in, and sent on without the answers.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/explore/blocks/bets/answers.dart';
import 'package:astuto/explore/blocks/bets/bets_day.dart';
import 'package:astuto/explore/blocks/bets/deal.dart' show BetSection, answerOf;
import 'package:astuto/explore/blocks/bets/three.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/crowd.dart';
import 'package:astuto/utils/share_link.dart' show sendText;
import 'package:astuto/utils/share_text.dart';

import 'bets_host.dart';

// Three shares from the bank: 28, 21.5 and 55 percent.
const List<String> three = [
  'art-detection-9',
  'psychology-streaks-6',
  'maths-percentages-4',
];

// A Sunday.
final DateTime sunday = DateTime(2026, 10, 18, 12);
late DateTime now;
DateTime clock() => now;

final AppLocalizations l = lookupAppLocalizations(const Locale('en'));

Map<String, Object?> get threeSection => const {
  'id': 'three',
  'block': 'three',
};

Future<BetsTestHost> start(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  List<String> cards = three,
}) async {
  now = sunday;
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true, ...prefs});
  // ignore: invalid_use_of_visible_for_testing_member
  BetsDay.resetForTest(clock: clock);
  // ignore: invalid_use_of_visible_for_testing_member
  ThreeDays.resetForTest();
  final AppState app = AppState(clock: clock);
  await tester.runAsync(app.init);
  await tester.runAsync(BetsDay.instance.load);
  await tester.runAsync(ThreeDays.instance.load);
  final BetsTestHost host = BetsTestHost(app, records: true);
  host.cards['three'] = [for (final id in cards) PillBank.byId(id)!];
  return host;
}

Future<void> settle(WidgetTester tester) async {
  for (int f = 0; f < 8; f++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<void> show(
  WidgetTester tester,
  BetsTestHost host, {
  Brightness brightness = Brightness.dark,
  double text = 1,
  double width = 375,
}) async {
  tester.view.physicalSize = Size(width * 2, 4000 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    betsApp(
      BetsPage(host: host, sections: [ExploreSection.fromJson(threeSection)]),
      brightness: brightness,
      phone: Size(width, 4000),
      text: text,
    ),
  );
  await settle(tester);
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final Finder f = find.byKey(ValueKey(key));
  expect(f, findsOneWidget, reason: key);
  await tester.ensureVisible(f);
  await tester.tap(f, warnIfMissed: false);
  await settle(tester);
}

String textOf(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key))).data ?? '';

/// The card in front of the reader: the one whose guess is to be locked in.
String onScreen(WidgetTester tester) {
  final Finder lock = find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('three-lock-'),
  );
  expect(lock, findsOneWidget);
  return (tester.widget(lock).key! as ValueKey<String>).value.substring(
    'three-lock-'.length,
  );
}

/// Plays the three, each guess [off] points above its answer, each locked
/// in and moved on from; the cards in the order they came.
Future<List<String>> play(WidgetTester tester, {double off = 0}) async {
  final List<String> ids = [];
  for (int i = 0; i < 3; i++) {
    expect(find.byKey(ValueKey('three-step-$i')), findsOneWidget);
    final String id = onScreen(tester);
    ids.add(id);
    final double truth = answerOf(PillBank.byId(id)!)!.value;
    BetsDay.instance.keepDraft(BetsDay.draftKey('three', id), {
      'g': (truth + off).clamp(0, 100),
    });
    await settle(tester);
    await tapKey(tester, 'three-lock-$id');
    expect(find.byKey(ValueKey('three-points-$id')), findsOneWidget);
    await tapKey(tester, 'three-next');
  }
  return ids;
}

void main() {
  setUp(() {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => Crowd.useForTest(null));

  group('points', () {
    test('a hundred on the answer, three fewer a point off, in tens', () {
      expect(threePoints(28, 28), 100);
      expect(threePoints(29.5, 28), 100); // 95.5
      expect(threePoints(30, 28), 90); // 94
      expect(threePoints(38, 28), 70);
      expect(threePoints(18, 28), 70);
      expect(threePoints(61, 28), 0);
      expect(threePoints(100, 0), 0);
    });
  });

  group('the crowd', () {
    test('a score stands above the readers of every lower ten', () {
      expect(Crowd.place({5: 2, 10: 3, 20: 5}, 150), (readers: 10, beaten: 50));
      expect(Crowd.place({15: 4}, 150), (readers: 4, beaten: 0));
      expect(Crowd.place({0: 9, 30: 1}, 300), (readers: 10, beaten: 90));
      expect(Crowd.place(const {}, 120), (readers: 0, beaten: 0));
    });

    test('only counts of buckets are read from the server', () {
      expect(bucketsOf({'b0': 2, 'b30': 1.0, 'b31': 4, 'x': 3, 'b7': -1}), {
        0: 2,
        30: 1,
      });
      expect(bucketsOf(null), isEmpty);
      expect(bucketsOf('b3'), isEmpty);
    });
  });

  group('the days', () {
    test('a run counts back from today, or from yesterday until today is '
        'played', () {
      // ignore: invalid_use_of_visible_for_testing_member
      ThreeDays.resetForTest();
      final ThreeDays days = ThreeDays.instance;
      String day(int d) => dateKey(DateTime(2026, 10, d));
      days.put(day(14), 90);
      days.put(day(16), 120);
      days.put(day(17), 150);
      expect(days.streak(sunday), 2);
      days.put(day(18), 300);
      expect(days.streak(sunday), 3);
      // Two days missed and it is gone.
      expect(days.streak(DateTime(2026, 10, 20, 9)), 0);
    });

    test('the week runs Monday to Sunday', () {
      // ignore: invalid_use_of_visible_for_testing_member
      ThreeDays.resetForTest();
      final ThreeDays days = ThreeDays.instance;
      days.put(dateKey(DateTime(2026, 10, 11)), 60); // the Sunday before
      days.put(dateKey(DateTime(2026, 10, 12)), 60);
      days.put(dateKey(DateTime(2026, 10, 14)), 60);
      days.put(dateKey(DateTime(2026, 10, 18)), 60);
      expect(days.week(sunday), [true, false, true, false, false, false, true]);
    });
  });

  testWidgets('the same three for everyone, whatever each has read', (
    tester,
  ) async {
    final List<String> pool = [
      for (final Pill p in PillBank.cards)
        if (BetAnswer.of(p) case final BetAnswer a
            when const ThreeBlock().fits(a))
          p.id,
    ].take(12).toList();
    expect(pool.length, 12);
    final BetsTestHost host = await start(tester, cards: pool);
    final BetSection shelf = BetSection(ExploreSection.fromJson(threeSection));
    List<String> dealt() => [
      for (final a in const ThreeBlock().deal(host, shelf)) a.pill.id,
    ];
    final List<String> before = dealt();
    expect(before, hasLength(3));
    await tester.runAsync(() => host.app.recordAnswer(before.first, '50'));
    expect(dealt(), before);
  });

  testWidgets('played through: scored, kept, and counted once', (tester) async {
    final MemoryCrowdStore crowd = MemoryCrowdStore();
    Crowd.useForTest(crowd);
    final BetsTestHost host = await start(tester);
    await show(tester, host);
    // No run yet, and nothing says "0 days".
    expect(find.byKey(const ValueKey('three-week')), findsOneWidget);
    expect(find.byKey(const ValueKey('three-streak')), findsNothing);
    final List<String> ids = await play(tester, off: 10);
    expect(ids.toSet(), three.toSet());

    expect(find.byKey(const ValueKey('three-result')), findsOneWidget);
    expect(textOf(tester, 'three-score'), '210');
    final String today = dateKey(sunday);
    expect(ThreeDays.instance.score(today), 210);
    expect(crowd.added, [(today, 21)]);
    expect(ThreeDays.instance.counted(today), isTrue);
    for (final String id in three) {
      expect(BetsDay.instance.betOn('three', id)?.facts['pts'], 70);
    }
    // Answered as each card is answered anywhere.
    expect({for (final a in host.answered) a.$1}, three.toSet());
    // The first to play: no share of a handful.
    expect(textOf(tester, 'three-crowd'), l.threeFirst(1));
    expect(find.byKey(const ValueKey('three-spread')), findsNothing);

    // Back on the page, the score, counted no more.
    await show(tester, host);
    expect(find.byKey(const ValueKey('three-result')), findsOneWidget);
    expect(crowd.added, hasLength(1));

    // And on the phone for tomorrow.
    // ignore: invalid_use_of_visible_for_testing_member
    ThreeDays.resetForTest();
    await tester.runAsync(ThreeDays.instance.load);
    expect(ThreeDays.instance.score(today), 210);
    expect(ThreeDays.instance.counted(today), isTrue);
  });

  testWidgets('placed among today\'s readers, and moving as they come in', (
    tester,
  ) async {
    final String today = dateKey(sunday);
    final MemoryCrowdStore crowd = MemoryCrowdStore({
      today: {0: 9},
    });
    Crowd.useForTest(crowd);
    final BetsTestHost host = await start(tester);
    await show(tester, host);
    await play(tester);
    expect(textOf(tester, 'three-score'), '300');
    expect(textOf(tester, 'three-crowd'), l.threeCloser(90));
    expect(find.byKey(const ValueKey('three-spread')), findsOneWidget);
    expect(find.byKey(const ValueKey('three-you')), findsOneWidget);

    await crowd.add(today, 30);
    await settle(tester);
    expect(textOf(tester, 'three-crowd'), l.threeCloser(82));
  });

  testWidgets('in the lower half, how many played, never how few it beat', (
    tester,
  ) async {
    final String today = dateKey(sunday);
    Crowd.useForTest(
      MemoryCrowdStore({
        today: {30: 9},
      }),
    );
    final BetsTestHost host = await start(tester);
    await show(tester, host);
    await play(tester, off: 20);
    expect(textOf(tester, 'three-score'), '120');
    expect(textOf(tester, 'three-crowd'), l.threeReaders(10));
    expect(find.byKey(const ValueKey('three-spread')), findsOneWidget);
  });

  testWidgets('with nobody to count among, the score alone', (tester) async {
    final BetsTestHost host = await start(tester);
    await show(tester, host);
    await play(tester);
    expect(textOf(tester, 'three-score'), '300');
    expect(find.byKey(const ValueKey('three-crowd')), findsNothing);
    expect(find.byKey(const ValueKey('three-spread')), findsNothing);
    expect(ThreeDays.instance.counted(dateKey(sunday)), isFalse);
  });

  testWidgets('a card answered before is played all the same; only its first '
      'answer is the card\'s', (tester) async {
    final BetsTestHost host = await start(tester);
    await tester.runAsync(() => host.app.recordAnswer(three.first, '50'));
    await show(tester, host);
    await play(tester);
    expect(BetsDay.instance.betOn('three', three.first), isNotNull);
    expect({for (final a in host.answered) a.$1}, three.skip(1).toSet());
    expect(host.app.answerFor(three.first)?.response, '50');
  });

  testWidgets('a run of days, and yesterday\'s score under today\'s', (
    tester,
  ) async {
    final BetsTestHost host = await start(
      tester,
      prefs: {
        'knowit.three': jsonEncode({
          's': {
            dateKey(DateTime(2026, 10, 16)): 90,
            dateKey(DateTime(2026, 10, 17)): 150,
          },
          'c': <String>[],
        }),
      },
    );
    await show(tester, host);
    expect(find.byKey(const ValueKey('three-week')), findsOneWidget);
    expect(textOf(tester, 'three-streak'), l.threeStreak(2));
    await play(tester);
    expect(find.text(l.threeDay(3).toUpperCase()), findsOneWidget);
    expect(textOf(tester, 'three-yesterday'), l.threeYesterday(150));
  });

  testWidgets('sent on: the day, the score, a square for each, never the '
      'answers', (tester) async {
    final List<String> sent = [];
    sendText = (text) async {
      sent.add(text);
      return true;
    };
    addTearDown(() => sendText = shareText);
    final BetsTestHost host = await start(tester);
    await show(tester, host);
    await play(tester, off: 10);
    await tapKey(tester, 'three-send');
    expect(sent, hasLength(1));
    final List<String> lines = sent.single.split('\n');
    expect(lines[1], l.threeShareScore(210, 1));
    expect(lines[2], '🟨🟨🟨');
    expect(sent.single.contains('%'), isFalse);
  });

  testWidgets('the why opens the three cards, from the first', (tester) async {
    final BetsTestHost host = await start(tester);
    await show(tester, host);
    final List<String> ids = await play(tester);
    await tapKey(tester, 'three-why');
    expect(host.opened.last, ('three', ids.first));
  });

  testWidgets('every step and the score fit at twice the text size on the '
      'smallest phone, dark and light', (tester) async {
    for (final Brightness b in Brightness.values) {
      final String today = dateKey(sunday);
      Crowd.useForTest(
        MemoryCrowdStore({
          today: {0: 4, 9: 6, 30: 2},
        }),
      );
      final BetsTestHost host = await start(tester);
      await show(tester, host, brightness: b, text: 2, width: 320);
      expect(tester.takeException(), isNull);
      await play(tester, off: 5);
      expect(tester.takeException(), isNull, reason: '$b');
      expect(find.byKey(const ValueKey('three-spread')), findsOneWidget);
    }
  });
}
