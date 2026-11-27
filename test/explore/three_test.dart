// The day's challenges: Today's five on Explore for every subject, and each
// subject's Today's three at the top of its page. The same cards for
// everyone, dealt from the date alone; played one after another, a pick
// tapped or a share set on the track; scored, kept, sent once to be
// counted; and the result set among today's players, card by card, with
// plain words where there are too few of them yet.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/explore_mix.dart' show subjectKeyOf;
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/explore/blocks/bets/answers.dart';
import 'package:astuto/explore/blocks/bets/bets_day.dart';
import 'package:astuto/explore/blocks/bets/daily_deal.dart';
import 'package:astuto/explore/blocks/bets/deal.dart' show BetSection, answerOf;
import 'package:astuto/explore/blocks/bets/five_challenge.dart';
import 'package:astuto/explore/blocks/bets/three.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/l10n/l10n.dart' show Quoting;
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/daily_crowd.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/utils/share_link.dart' show sendText;
import 'package:astuto/utils/share_text.dart';

import 'bets_host.dart';

// A Sunday.
final DateTime sunday = DateTime(2026, 10, 18, 12);
late DateTime now;
DateTime clock() => now;

final AppLocalizations l = lookupAppLocalizations(const Locale('en'));

const Map<String, Object?> threeSection = {'id': 'three', 'block': 'three'};

/// How the server judges an answer (functions/src/daily.ts): the card's own
/// test, and the points the phone gives it.
({bool right, int points, int? pick, double? guess}) judge(
  String id,
  String said,
) {
  final Pill p = PillBank.byId(id)!;
  final bool pick = p.challenge is PickOne;
  return (
    right: p.challenge.accepts(said),
    points: dailyPoints(p, said),
    pick: pick ? int.parse(said) : null,
    guess: pick ? null : double.parse(said),
  );
}

Future<BetsTestHost> start(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  String? subject,
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
  return BetsTestHost(app, records: true, subject: subject);
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
  tester.view.physicalSize = Size(width * 2, 6000 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    betsApp(
      BetsPage(host: host, sections: [ExploreSection.fromJson(threeSection)]),
      brightness: brightness,
      phone: Size(width, 6000),
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

/// The card in front of the reader: the one whose answer is to be locked in.
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

/// Plays every card in front of the reader: a pick right where [right]
/// says, wrong otherwise; a share [off] points above its answer. Each locked
/// in and moved on from; the cards in the order they came.
Future<List<String>> play(
  WidgetTester tester, {
  int count = 5,
  bool Function(int i) right = _always,
  double off = 0,
}) async {
  final List<String> ids = [];
  for (int i = 0; i < count; i++) {
    expect(find.byKey(ValueKey('three-step-$i')), findsOneWidget);
    final String id = onScreen(tester);
    ids.add(id);
    final Pill p = PillBank.byId(id)!;
    switch (p.challenge) {
      case PickOne(:final correct, :final options):
        final int pick = right(i) ? correct : (correct + 1) % options.length;
        await tapKey(tester, 'three-option-$id-$pick');
      default:
        final double truth = answerOf(p)!.value;
        BetsDay.instance.keepDraft(BetsDay.draftKey(kDailyBet, id), {
          'g': (truth + off).clamp(0, 100),
        });
        await settle(tester);
    }
    await tapKey(tester, 'three-lock-$id');
    expect(find.byKey(ValueKey('three-points-$id')), findsOneWidget);
    await tapKey(tester, 'three-next');
  }
  return ids;
}

bool _always(int i) => true;

void main() {
  setUp(() {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    DailyCrowd.useForTest(null);
  });
  tearDown(() {
    DailyCrowd.useForTest(null, on: false);
    // ignore: invalid_use_of_visible_for_testing_member
    Served.useForTest(Served());
  });

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

    test('a pick is a hundred when right, nothing when not', () {
      final Pill pick = PillBank.cards.firstWhere(
        (p) => dailyKindOf(p) == DailyKind.pick,
      );
      final int right = (pick.challenge as PickOne).correct;
      expect(dailyPoints(pick, '$right'), 100);
      expect(dailyPoints(pick, '${(right + 1) % 2}'), 0);
      final Pill share = PillBank.byId('maths-percentages-4')!;
      expect(dailyKindOf(share), DailyKind.share);
      expect(dailyPoints(share, '55'), 100);
      expect(dailyPoints(share, '65'), 70);
    });
  });

  group('the deal', () {
    test('five cards a day, each of another subject, every one playable, the '
        'same for the same day', () {
      for (int d = 0; d < 40; d++) {
        final DateTime day = DateTime(2026, 11, 1 + d, 8);
        final List<Pill> five = DailyDeal.five(day);
        expect(five, hasLength(5), reason: dateKey(day));
        expect({for (final p in five) p.topic}, hasLength(5));
        expect(five.every((p) => dailyKindOf(p) != null), isTrue);
        // The hour does not matter, nor does asking again.
        expect(
          [for (final p in DailyDeal.five(DateTime(2026, 11, 1 + d, 23))) p.id],
          [for (final p in five) p.id],
        );
      }
      expect(
        DailyDeal.five(sunday).map((p) => p.id),
        isNot(
          DailyDeal.five(sunday.add(const Duration(days: 1))).map((p) => p.id),
        ),
      );
    });

    test('every subject comes round, and none two days running', () {
      final Map<String, int> turns = {};
      Set<String> before = {};
      for (int d = 0; d < 42; d++) {
        final Set<String> today = {
          for (final p in DailyDeal.five(DateTime(2026, 11, 1 + d)))
            subjectKeyOf(p),
        };
        expect(today.intersection(before), isEmpty);
        for (final s in today) {
          turns[s] = (turns[s] ?? 0) + 1;
        }
        before = today;
      }
      // Twenty-one subjects, five a day: ten turns each in six weeks.
      expect(turns.values.toSet(), {10});
    });

    test('a subject\'s three are its own, never the five\'s card of it', () {
      for (int d = 0; d < 30; d++) {
        final DateTime day = DateTime(2026, 11, 1 + d);
        final List<Pill> five = DailyDeal.five(day);
        for (final Pill card in five) {
          final String subject = subjectKeyOf(card);
          final List<Pill> three = DailyDeal.three(day, subject);
          expect(three, hasLength(3));
          expect(three.every((p) => subjectKeyOf(p) == subject), isTrue);
          expect(three.map((p) => p.id), isNot(contains(card.id)));
        }
      }
    });

    test('a card back only after days, never the next one', () {
      for (final String subject in ['history', 'maths', 'weird_facts']) {
        Set<String> yesterday = {};
        for (int d = 0; d < 60; d++) {
          final Set<String> today = {
            for (final p in DailyDeal.run(
              subject,
              DateTime(2026, 11, 1 + d),
              4,
            ))
              p.id,
          };
          expect(today.intersection(yesterday), isEmpty, reason: '$subject $d');
          yesterday = today;
        }
      }
    });

    test('a bank a card short deals the same day, unless the card was in '
        'it', () {
      final List<Pill> five = DailyDeal.five(sunday);
      final Set<String> dealt = {
        for (final s in five.map(subjectKeyOf))
          for (final p in DailyDeal.run(s, sunday, 4)) p.id,
      };
      final Pill gone = PillBank.cards.firstWhere(
        (p) => dailyKindOf(p) != null && !dealt.contains(p.id),
      );
      final List<Pill> fewer = [
        for (final p in PillBank.cards)
          if (p.id != gone.id) p,
      ];
      expect(
        DailyDeal.five(sunday, bank: fewer).map((p) => p.id),
        five.map((p) => p.id),
      );
    });

    test('a game\'s counts are kept under the day, the game and its cards, '
        'in any order', () {
      final DailyGame five = DailyGame.five('2026-10-18');
      expect(five.keyFor(['b-2', 'a-1']), '2026-10-18~five~a-1,b-2');
      expect(
        DailyGame.three('2026-10-18', 'art').keyFor(['art-2', 'art-1']),
        '2026-10-18~three~art-1,art-2',
      );
      expect(five.max, 500);
      expect(DailyGame.three('2026-10-18', 'art').max, 300);
      expect(DailyGame.three('2026-10-18', 'art').id, 'three-art');
    });

    test('the counts as the server keeps them (functions/src/daily.ts): '
        'by place, in maps, and nothing else read', () {
      final DailyCounts c = DailyCounts.parse({
        'players': 3,
        'scores': {'37': 1, '50': 2, 'x': 4, '-1': 1},
        'items': {
          'art-1': {
            'n': 3,
            'right': 2,
            'picks': {'1': 2, '0': 1},
          },
          'maths-1': {
            'n': 3,
            'right': 1,
            'guesses': {'6': 1, '5': 2},
            'sum': 175,
          },
          'bad': 'x',
        },
        'day': '2026-10-18',
        'cards': ['art-1', 'maths-1'],
      })!;
      expect(c.players, 3);
      expect(c.scores, [...List.filled(37, 0), 1, ...List.filled(12, 0), 2]);
      expect(c.place(500), (players: 3, beaten: 33));
      expect(c.items['art-1']!.picks, [1, 2]);
      expect(c.items['art-1']!.rightShare, closeTo(2 / 3, 1e-9));
      expect(c.items['maths-1']!.guesses, [0, 0, 0, 0, 0, 2, 1]);
      expect(c.items['maths-1']!.meanGuess, closeTo(175 / 3, 1e-9));
      expect(c.items.containsKey('bad'), isFalse);
      expect(DailyCounts.parse({'scores': const {}}), isNull);
    });

    testWidgets('cards a section names: on a subject\'s page only its own, '
        'and the deal when it names too few of them', (tester) async {
      final List<Pill> science = [
        for (final p in PillBank.cards)
          if (subjectKeyOf(p) == 'science' && dailyKindOf(p) != null) p,
      ].take(3).toList();
      final Pill art = PillBank.cards.firstWhere(
        (p) => subjectKeyOf(p) == 'art' && dailyKindOf(p) != null,
      );
      final BetsTestHost host = await start(tester, subject: 'Science');
      const ThreeBlock block = ThreeBlock();
      final DailyGame game = block.gameOf(host)!;
      List<String> dealt(List<Pill> named) => [
        for (final p in block.cardsOf(
          host,
          BetSection(
            ExploreSection.fromJson({
              'id': 'three-${named.length}',
              'block': 'three',
              'source': {
                'ids': [for (final p in named) p.id],
              },
            }),
          ),
          game,
        ))
          p.id,
      ];
      expect(dealt([science[0], art, science[1], science[2]]), [
        for (final p in science) p.id,
      ]);
      expect(dealt([science[0], art, science[1]]), [
        for (final p in DailyDeal.three(sunday, 'science')) p.id,
      ]);
    });

    testWidgets('the five whatever the reader has read or answered', (
      tester,
    ) async {
      final BetsTestHost host = await start(tester);
      final BetSection shelf = BetSection(
        ExploreSection.fromJson(threeSection),
      );
      const ThreeBlock block = ThreeBlock();
      final DailyGame game = block.gameOf(host)!;
      final List<String> before = [
        for (final p in block.cardsOf(host, shelf, game)) p.id,
      ];
      expect(before, [for (final p in DailyDeal.five(sunday)) p.id]);
      // ignore: invalid_use_of_visible_for_testing_member
      BetsDay.resetForTest(clock: clock);
      await tester.runAsync(BetsDay.instance.load);
      await tester.runAsync(() => host.app.recordAnswer(before.first, '0'));
      await tester.runAsync(() => host.app.markReadElsewhere(before[1]));
      expect([for (final p in block.cardsOf(host, shelf, game)) p.id], before);
    });
  });

  testWidgets('played through: scored, kept, and sent once to be counted', (
    tester,
  ) async {
    final MemoryDailyStore store = MemoryDailyStore(judge: judge);
    DailyCrowd.useForTest(store);
    final BetsTestHost host = await start(tester);
    await show(tester, host);
    expect(find.text(l.fiveTitle.toUpperCase()), findsOneWidget);
    final List<String> ids = await play(tester, right: (i) => i != 1, off: 5);
    expect(ids, [for (final p in DailyDeal.five(sunday)) p.id]);

    expect(find.byKey(const ValueKey('three-result')), findsOneWidget);
    final int expected = [
      for (final (int i, String id) in ids.indexed)
        switch (PillBank.byId(id)!.challenge) {
          PickOne() => i == 1 ? 0 : 100,
          _ => 90,
        },
    ].fold(0, (a, b) => a + b);
    expect(textOf(tester, 'three-score'), '$expected');
    final DailyGame game = DailyGame.five(dateKey(sunday));
    expect(ThreeDays.instance.scoreOf(game), expected);
    expect(ThreeDays.instance.counted(game), isTrue);
    expect(find.text(l.dailyOf(500)), findsOneWidget);
    // Sent once, the cards in the order played, as the card keeps answers.
    expect(store.sent, hasLength(1));
    final DailyPlay sent = store.sent.single;
    expect(sent.day, dateKey(sunday));
    expect(sent.game, 'five');
    expect([for (final (id, _) in sent.said) id], ids);
    // Answered as each card is answered anywhere.
    expect({for (final a in host.answered) a.$1}, ids.toSet());
    // The first to play: no share of a handful, card by card too few.
    expect(textOf(tester, 'three-crowd'), l.dailyFirst(1));
    expect(find.byKey(const ValueKey('three-spread')), findsNothing);
    for (final String id in ids) {
      expect(textOf(tester, 'three-row-crowd-$id'), l.dailyItemFew);
    }
    // Under each question, what was said against the answer: a wrong pick
    // as two lines, the reader's and the right one; a right pick, the
    // right one; a share, both numbers. The card's words quoted, whole.
    final BetNumbers numbers = BetNumbers('en');
    for (final (int i, String id) in ids.indexed) {
      final Pill p = PillBank.byId(id)!;
      final String said = switch (p.challenge) {
        PickOne(:final correct, :final options, :final correctOption) =>
          i == 1
              ? '${l.dailyYourPick(l.quoted(options[(correct + 1) % options.length]))}'
                    '\n${l.dailyPickRight(l.quoted(correctOption))}'
              : l.dailyPickRight(l.quoted(correctOption)),
        _ =>
          '${l.dailyYourPick(numbers.percent((answerOf(p)!.value + 5).clamp(0, 100).toDouble()))}'
              '\n${l.dailyPickRight(numbers.percent(answerOf(p)!.value))}',
      };
      final Finder line = find.descendant(
        of: find.byKey(ValueKey('three-row-$id')),
        matching: find.text(said),
      );
      expect(line, findsOneWidget, reason: id);
      expect(tester.widget<Text>(line).maxLines, isNull, reason: id);
      expect(tester.widget<Text>(line).overflow, isNull, reason: id);
    }

    // Back on the page, the result, sent no more.
    await show(tester, host);
    expect(find.byKey(const ValueKey('three-result')), findsOneWidget);
    expect(store.sent, hasLength(1));

    // And on the phone for tomorrow.
    // ignore: invalid_use_of_visible_for_testing_member
    ThreeDays.resetForTest();
    await tester.runAsync(ThreeDays.instance.load);
    expect(ThreeDays.instance.scoreOf(game), expected);
    expect(ThreeDays.instance.counted(game), isTrue);
  });

  testWidgets('placed among today\'s players, card by card, and moving as '
      'they come in', (tester) async {
    final List<String> ids = [for (final p in DailyDeal.five(sunday)) p.id];
    final String key = DailyGame.five(dateKey(sunday)).keyFor(ids);
    final MemoryDailyStore store = MemoryDailyStore(judge: judge);
    // Nine players before, all on nothing; each answered every card, right
    // on none, and on a share guessed nought.
    store.put(
      key,
      DailyCounts(
        players: 9,
        scores: [9, ...List.filled(50, 0)],
        items: {
          for (final String id in ids)
            id: DailyItemCounts(
              n: 9,
              right: 0,
              picks: PillBank.byId(id)!.challenge is PickOne ? [9] : const [],
              guesses: PillBank.byId(id)!.challenge is PickOne ? const [] : [9],
            ),
        },
      ),
    );
    DailyCrowd.useForTest(store);
    final BetsTestHost host = await start(tester);
    await show(tester, host);
    await play(tester);
    expect(textOf(tester, 'three-score'), '500');
    expect(textOf(tester, 'three-crowd'), l.dailyBetter(90, 10));
    expect(find.byKey(const ValueKey('three-spread')), findsOneWidget);
    expect(find.byKey(const ValueKey('three-you')), findsOneWidget);
    for (final String id in ids) {
      final bool pick = PillBank.byId(id)!.challenge is PickOne;
      final BetNumbers n = BetNumbers('en');
      expect(
        textOf(tester, 'three-row-crowd-$id'),
        pick
            ? l.dailyItemRight(10)
            : l.dailyItemGuess(
                n.percent(answerOf(PillBank.byId(id)!)!.value / 10),
              ),
        reason: id,
      );
    }

    // Another player comes in, on everything.
    store.put(
      key,
      DailyCounts(
        players: 11,
        scores: [9, ...List.filled(49, 0), 2],
        items: const {},
      ),
    );
    await settle(tester);
    expect(textOf(tester, 'three-crowd'), l.dailyBetter(82, 11));
  });

  testWidgets('in the lower half, how many played, never how few it beat', (
    tester,
  ) async {
    final List<String> ids = [for (final p in DailyDeal.five(sunday)) p.id];
    final MemoryDailyStore store = MemoryDailyStore(judge: judge);
    store.put(
      DailyGame.five(dateKey(sunday)).keyFor(ids),
      DailyCounts(
        players: 9,
        scores: [...List.filled(50, 0), 9],
        items: const {},
      ),
    );
    DailyCrowd.useForTest(store);
    final BetsTestHost host = await start(tester);
    await show(tester, host);
    await play(tester, right: (i) => false, off: 40);
    expect(textOf(tester, 'three-crowd'), l.dailyPlayers(10));
    expect(find.byKey(const ValueKey('three-spread')), findsOneWidget);
  });

  testWidgets('with no count of today, the readers\' own rates where the '
      'server publishes them, and plain words where it does not', (
    tester,
  ) async {
    final List<Pill> five = DailyDeal.five(sunday);
    // ignore: invalid_use_of_visible_for_testing_member
    Served.useForTest(
      Served(
        storeOverride: MemoryServedStore()
          ..shelves = ServedExplore(
            day: dateKey(sunday),
            today: const [],
            asking: const [],
            topWeek: const [],
            topMonth: const [],
            loved: const [],
            bySubject: const {},
            crowd: {for (final Pill p in five) p.id: (answers: 40, right: 28)},
          ),
        uidOverride: 'reader',
      ),
    );
    await Served.instance.explore();
    final BetsTestHost host = await start(tester);
    await show(tester, host);
    await play(tester, right: (i) => i < 3);
    final int right = [
      for (final (int i, Pill p) in five.indexed)
        if (p.challenge is PickOne ? i < 3 : true) p,
    ].length;
    expect(textOf(tester, 'three-crowd'), l.dailyAverage(right, 5, '3.5'));
    for (final Pill p in five) {
      expect(textOf(tester, 'three-row-crowd-${p.id}'), l.crowdGotRight(70));
    }
    expect(find.byKey(const ValueKey('three-spread')), findsNothing);
  });

  testWidgets('with nothing counted anywhere, it says so', (tester) async {
    final BetsTestHost host = await start(tester);
    await show(tester, host);
    await play(tester);
    expect(textOf(tester, 'three-score'), '500');
    expect(textOf(tester, 'three-crowd'), l.dailyUncounted);
    expect(
      ThreeDays.instance.counted(DailyGame.five(dateKey(sunday))),
      isFalse,
    );
  });

  testWidgets('a play the server could not take is sent again, once a run', (
    tester,
  ) async {
    final MemoryDailyStore store = MemoryDailyStore(judge: judge)
      ..failing = true;
    DailyCrowd.useForTest(store);
    final BetsTestHost host = await start(tester);
    await show(tester, host);
    await play(tester);
    final DailyGame game = DailyGame.five(dateKey(sunday));
    expect(ThreeDays.instance.counted(game), isFalse);
    expect(textOf(tester, 'three-crowd'), l.dailyUncounted);
    // The next run: the server is back.
    store.failing = false;
    DailyCrowd.useForTest(store);
    await show(tester, host);
    await tester.pumpWidget(const SizedBox());
    await show(tester, host);
    expect(store.sent, hasLength(1));
    expect(ThreeDays.instance.counted(game), isTrue);
    expect(textOf(tester, 'three-crowd'), l.dailyFirst(1));
  });

  testWidgets('a subject\'s page: its own three, out of three hundred', (
    tester,
  ) async {
    final MemoryDailyStore store = MemoryDailyStore(judge: judge);
    DailyCrowd.useForTest(store);
    final BetsTestHost host = await start(tester, subject: 'Science');
    await show(tester, host);
    expect(find.text(l.threeTitle.toUpperCase()), findsOneWidget);
    final List<String> ids = await play(tester, count: 3);
    expect(ids, [for (final p in DailyDeal.three(sunday, 'science')) p.id]);
    expect(ids.every((id) => PillBank.byId(id)!.topic == 'Science'), isTrue);
    expect(textOf(tester, 'three-score'), '300');
    expect(find.text(l.dailyOf(300)), findsOneWidget);
    expect(store.sent.single.game, 'three');
    expect(
      ThreeDays.instance.scoreOf(DailyGame.three(dateKey(sunday), 'science')),
      300,
    );
    // The five is another game, not played.
    expect(ThreeDays.instance.scoreOf(DailyGame.five(dateKey(sunday))), isNull);
  });

  testWidgets('a pick: nothing to lock in until an answer is chosen, then '
      'the right one lit and a wrong pick ringed', (tester) async {
    final BetsTestHost host = await start(tester);
    await show(tester, host);
    final String id = onScreen(tester);
    final Pill pill = PillBank.byId(id)!;
    if (pill.challenge case PickOne(:final correct, :final correctOption)) {
      expect(find.text(l.betsPickFirst), findsOneWidget);
      await tapKey(tester, 'three-lock-$id');
      expect(BetsDay.instance.betOn(kDailyBet, id), isNull);
      final int wrong = (correct + 1) % 2;
      await tapKey(tester, 'three-option-$id-$wrong');
      expect(find.text(l.betsLockIn), findsOneWidget);
      await tapKey(tester, 'three-lock-$id');
      // The card's words quoted in the app's sentence.
      expect(
        textOf(tester, 'three-said-$id'),
        l.dailyPickWrong(l.quoted(correctOption)),
      );
      expect(textOf(tester, 'three-points-$id'), l.threePoints(0));
      expect(
        find.bySemanticsLabel('$correctOption. ${l.betsRight}'),
        findsOneWidget,
      );
    } else {
      fail('the five open on a pick on this day');
    }
  });

  testWidgets('a card answered before is played all the same; only its '
      'first answer is the card\'s', (tester) async {
    final List<Pill> five = DailyDeal.five(sunday);
    final BetsTestHost host = await start(tester);
    await tester.runAsync(() => host.app.recordAnswer(five.first.id, '9'));
    await show(tester, host);
    await play(tester);
    expect(BetsDay.instance.betOn(kDailyBet, five.first.id), isNotNull);
    expect(
      {for (final a in host.answered) a.$1},
      {for (final p in five.skip(1)) p.id},
    );
    expect(host.app.answerFor(five.first.id)?.response, '9');
  });

  testWidgets('the days in a row, the three before the five among them, and '
      'yesterday\'s five under today\'s', (tester) async {
    final BetsTestHost host = await start(
      tester,
      prefs: {
        'knowit.three': jsonEncode({
          's': {
            // The three Explore opened on before, two days ago.
            dateKey(DateTime(2026, 10, 16)): 90,
            '${dateKey(DateTime(2026, 10, 17))}|five': 300,
          },
          'c': <String>[],
        }),
      },
    );
    await show(tester, host);
    await play(tester);
    expect(ThreeDays.instance.streak(sunday), 3);
    expect(textOf(tester, 'three-yesterday'), l.fiveYesterday(300));
    expect(ThreeDays.instance.week(sunday), [
      false,
      false,
      false,
      false,
      true,
      true,
      true,
    ]);
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
    await play(tester, right: (i) => false, off: 40);
    await tapKey(tester, 'three-send');
    expect(sent, hasLength(1));
    final List<String> lines = sent.single.split('\n');
    expect(lines[0], startsWith('Astute · ${l.fiveTitle}'));
    expect(lines[1], l.dailyShareScore(0, 500, 1));
    expect(lines[2], '⬜⬜⬜⬜⬜');
    for (final Pill p in DailyDeal.five(sunday)) {
      if (p.challenge case PickOne(:final correctOption)) {
        expect(sent.single.contains(correctOption), isFalse);
      }
    }
  });

  testWidgets('the why opens the cards, from the first; a row opens its own', (
    tester,
  ) async {
    final BetsTestHost host = await start(tester);
    await show(tester, host);
    final List<String> ids = await play(tester);
    await tapKey(tester, 'three-why');
    expect(host.opened.last, ('three', ids.first));
    await tapKey(tester, 'three-row-${ids[2]}');
    expect(host.opened.last, ('three', ids[2]));
  });

  testWidgets('every step and the result fit at twice the text size on the '
      'smallest phone, dark and light', (tester) async {
    for (final Brightness b in Brightness.values) {
      final List<String> ids = [for (final p in DailyDeal.five(sunday)) p.id];
      final MemoryDailyStore store = MemoryDailyStore(judge: judge);
      store.put(
        DailyGame.five(dateKey(sunday)).keyFor(ids),
        DailyCounts(
          players: 12,
          scores: [4, 0, 0, 0, 0, 0, 0, 0, 0, 6, ...List.filled(40, 0), 2],
          items: const {},
        ),
      );
      DailyCrowd.useForTest(store);
      final BetsTestHost host = await start(tester);
      await show(tester, host, brightness: b, text: 2, width: 320);
      expect(tester.takeException(), isNull);
      await play(tester, right: (i) => i.isEven, off: 5);
      expect(tester.takeException(), isNull, reason: '$b');
      expect(find.byKey(const ValueKey('three-spread')), findsOneWidget);
    }
  });

  group('challenge a friend, while the server says so (share.challenge)', () {
    int docs = 0;
    void challengesOn() => Remote.adopt(
      RemoteConfig.parse(
        jsonEncode({
          'schema': 1,
          'hash': 'three-challenge-${docs++}',
          'app': {
            'flags': {'share.challenge': true},
          },
          'strings': <String, Object?>{},
          'explore': null,
          'looks': null,
        }),
      ),
    );

    tearDown(() {
      Remote.reset();
      sendText = shareText;
    });

    testWidgets('the five go on as a challenge: how many were right, the '
        'site\'s page for the day, never the answers', (tester) async {
      challengesOn();
      final List<String> sent = [];
      sendText = (text) async {
        sent.add(text);
        return true;
      };
      final BetsTestHost host = await start(tester);
      await show(tester, host);
      final List<String> ids = await play(tester, right: (i) => i != 1);
      // Right as the game kept each card: the card's own test.
      final int right = [
        for (final String id in ids)
          if (BetsDay.instance.betOn(kDailyBet, id)!.right) id,
      ].length;
      expect(fiveRightToday(), right);
      expect(find.byKey(const ValueKey('three-send')), findsNothing);
      expect(find.byKey(const ValueKey('three-why')), findsOneWidget);
      // The challenge first, the why under it, each the card's width.
      final Rect challenge = tester.getRect(
        find.byKey(const ValueKey('three-challenge')),
      );
      final Rect why = tester.getRect(find.byKey(const ValueKey('three-why')));
      expect(why.top, greaterThan(challenge.bottom));
      expect(challenge.width, why.width);
      await tapKey(tester, 'three-challenge');
      expect(sent, [
        fiveChallengeText(l, day: dateKey(sunday), right: right),
      ]);
      expect(sent.single, endsWith('/sfida?d=2026-10-18&s=$right'));
      for (final Pill p in DailyDeal.five(sunday)) {
        if (p.challenge case PickOne(:final correctOption)) {
          expect(sent.single.contains(correctOption), isFalse);
        }
      }
    });

    testWidgets('a subject\'s three, which the site does not have, goes as '
        'squares still; and so does the five without the server', (
      tester,
    ) async {
      challengesOn();
      BetsTestHost host = await start(tester, subject: 'Science');
      await show(tester, host);
      await play(tester, count: 3);
      expect(find.byKey(const ValueKey('three-send')), findsOneWidget);
      expect(find.byKey(const ValueKey('three-challenge')), findsNothing);

      Remote.reset();
      host = await start(tester);
      await show(tester, host);
      await play(tester);
      expect(find.byKey(const ValueKey('three-send')), findsOneWidget);
      expect(find.byKey(const ValueKey('three-challenge')), findsNothing);
    });

    testWidgets('its words go onto a second line rather than be cut, at '
        'twice the text size on the smallest phone', (tester) async {
      challengesOn();
      final BetsTestHost host = await start(tester);
      await show(tester, host, text: 2, width: 320);
      await play(tester);
      expect(tester.takeException(), isNull);
      final Finder words = find.descendant(
        of: find.byKey(const ValueKey('three-challenge')),
        matching: find.text(l.challengeFriend),
      );
      expect(words, findsOneWidget);
      final RenderParagraph paragraph = tester.renderObject(words);
      expect(paragraph.didExceedMaxLines, isFalse);
    });
  });
}
