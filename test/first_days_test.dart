// The first three days: the cards a new reader opens on, chosen by hand
// (lib/data/first_days.dart), for whatever they answered in the first run —
// and nothing of it for a reader who was past the first run before. Then the
// rest of the first week, still mostly drawn.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/daily.dart';
import 'package:astuto/data/drawn_ranks.dart';
import 'package:astuto/data/first_days.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/data/reader_profile.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/served.dart';

/// The answers a first run can give: the wheel, by topic key, and what was
/// turned off under it. Null is the wheel skipped.
typedef _Choice = ({Map<String, double>? mix, Set<String> genresOff});

Map<String, double> _only(List<String> keys) => {for (final k in keys) k: 1};

/// Every subject on the wheel, as it starts.
final Map<String, double> _everything = {
  for (final String key in kTopicOrder)
    if (key != 'thinking') key: 1,
};

final Map<String, _Choice> _choices = {
  'skipped': (mix: null, genresOff: const {}),
  'left as it starts': (mix: _everything, genresOff: const {}),
  'everything but sport and pop culture': (
    mix: {..._everything}
      ..remove('sport')
      ..remove('pop_culture'),
    genresOff: const {},
  ),
  'science, space and nature': (
    mix: _only(['science', 'space', 'nature']),
    genresOff: const {},
  ),
  'the mind and people': (
    mix: _only(['psychology', 'life', 'philosophy']),
    genresOff: const {},
  ),
  'money and work': (
    mix: _only(['economics', 'technology']),
    genresOff: const {},
  ),
  'the body and health': (
    mix: _only(['human_body', 'medicine', 'food']),
    genresOff: const {},
  ),
  'history and the arts': (
    mix: _only(['history', 'art', 'cinema', 'music']),
    genresOff: const {},
  ),
  'space alone': (mix: _only(['space']), genresOff: const {}),
  'space and history above the rest': (
    mix: {
      for (final key in _everything.keys)
        key: key == 'space' || key == 'history' ? 1.0 : 0.5,
    },
    genresOff: const {},
  ),
};

final DateTime _start = DateTime(2026, 11, 26, 9);

List<String> _ids(Iterable<Pill> cards) => [for (final p in cards) p.id];

Set<String> _subjectsOf(Map<String, double>? mix) =>
    mix == null ? kTopicOrder.toSet() : {...mix.keys, 'thinking'};

/// A reader's day of the opening, dealt as the app deals it, three of the
/// five asking (with the opening's own shape off, [asking] null: two); null
/// once the opening has nothing left for them.
Deal? _openingDay(
  _Choice c, {
  required int day,
  Set<String> read = const {},
  int? asking = kOpeningAsks,
}) {
  final ReaderProfile profile = ReaderProfile.read(
    weights: c.mix ?? const {},
    genresOff: c.genresOff,
  );
  return dealOpening(
    date: DateTime(_start.year, _start.month, _start.day + day),
    topics: _subjectsOf(c.mix),
    claimed: profile.claimed,
    mix: c.mix ?? const {},
    weights: profile.weightsOn(day, c.mix ?? const {}),
    levels: profile.levelsUnder(const {}),
    taste: profile.lean,
    genresOff: c.genresOff,
    exclude: read,
    asking: asking,
  );
}

/// A reader's day of the rest of the first week ([day] 3 to 6), dealt as
/// the app deals it.
Deal? _weekDay(_Choice c, {required int day, Set<String> read = const {}}) {
  final ReaderProfile profile = ReaderProfile.read(
    weights: c.mix ?? const {},
    genresOff: c.genresOff,
  );
  return dealFirstWeek(
    date: DateTime(_start.year, _start.month, _start.day + day),
    day: day,
    topics: _subjectsOf(c.mix),
    claimed: profile.claimed,
    mix: c.mix ?? const {},
    weights: profile.weightsOn(day, c.mix ?? const {}),
    levels: profile.levelsUnder(const {}),
    taste: profile.lean,
    genresOff: c.genresOff,
    exclude: read,
  );
}

/// Takes up a remote document whose switches are [flags].
void _flags(Map<String, Object?> flags) => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'first-days-${flags.hashCode}',
      'app': {'flags': flags},
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

class _Said implements AnalyticsSink {
  final List<String> names = [];

  @override
  Future<void> capture(String event, Map<String, Object> properties) async =>
      names.add(event);

  @override
  Future<void> screen(String name) async {}

  @override
  Future<void> identify(String id, Map<String, Object> properties) async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> register(String key, Object value) async {}

  @override
  Future<void> setCollecting(bool on) async {}

  @override
  Future<void> setPerson(
    Map<String, Object> set,
    Map<String, Object> setOnce,
  ) async {}

  @override
  Future<void> error(
    Object error,
    StackTrace? stack,
    Map<String, Object> properties,
  ) async {}
}

Future<AppState> _open(
  DateTime Function() clock, [
  Map<String, Object> prefs = const {},
]) async {
  SharedPreferences.setMockInitialValues(prefs);
  return _launch(clock);
}

/// The app started again on what the phone already holds.
Future<AppState> _launch(DateTime Function() clock) async {
  final AppState app = AppState(
    clock: clock,
    hasPermission: () async => false,
    askPermission: () async => false,
    arm: (_) async {},
    disarm: () async {},
    pushWidget: (_) async {},
  );
  await app.init();
  return app;
}

Future<void> _finish(AppState app) async {
  for (var i = 0; i < 12 && !app.todayCompleted; i++) {
    await app.advance();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PillBank.reset();
    resetCalendar();
  });

  group('the opening, as data', () {
    test('is fifteen to thirty cards of the bank, each dealt to '
        'everybody, drawn, nothing dark, and each says why', () {
      expect(kFirstDays.length, inInclusiveRange(15, 30));
      expect(
        kFirstDays.map((c) => c.id).toSet(),
        hasLength(kFirstDays.length),
        reason: 'no card twice',
      );
      final Set<String> dealt = _ids(PillBank.cards).toSet();
      for (final FirstCard c in kFirstDays) {
        final Pill? p = PillBank.byId(c.id);
        expect(p, isNotNull, reason: '${c.id} is not in the bank');
        expect(dealt, contains(c.id), reason: '${c.id} is not dealt');
        expect(p!.hasPage, isTrue, reason: '${c.id} has no drawing');
        expect(p.mature, isFalse, reason: c.id);
        expect(p.mood, isNot('dark'), reason: c.id);
        expect(p.challenge, isNot(isA<TakeASide>()), reason: c.id);
        expect(c.why.trim(), isNotEmpty, reason: c.id);
        expect(c.day, inInclusiveRange(0, kOpeningDays), reason: c.id);
        if (c.twin case final String twin) {
          expect(
            kFirstDays.map((e) => e.id),
            contains(twin),
            reason: '${c.id}\'s twin',
          );
        }
      }
    });

    test('each of its days is five subjects, two cards to read and three '
        'that ask, two of those with a right answer, a read first', () {
      for (var day = 1; day <= kOpeningDays; day++) {
        final List<Pill> five = [
          for (final c in kFirstDays)
            if (c.day == day) PillBank.byId(c.id)!,
        ];
        expect(five, hasLength(kPillsPerDay), reason: 'day $day');
        expect(five.map((p) => p.topic).toSet(), hasLength(kPillsPerDay));
        expect(
          five.where((p) => p.asksSomething),
          hasLength(kOpeningAsks),
          reason: 'day $day',
        );
        expect(
          five.where((p) => p.asksSomething && p.isGraded),
          hasLength(greaterThanOrEqualTo(2)),
          reason: 'day $day',
        );
        expect(five.first.asksSomething, isFalse, reason: 'day $day');
        expect(arrangeOpening(five), five, reason: 'listed as read');
      }
    });

    test('every card of it with a right answer asks how sure, every time, '
        'whatever its odds', () {
      for (final FirstCard c in kFirstDays) {
        final Pill p = PillBank.byId(c.id)!;
        if (!p.asksSomething || !p.isGraded) continue;
        expect(p.sureOdds, isNull, reason: '${c.id} asks how sure by odds');
      }
    });
  });

  group('a reader who leaned nowhere', () {
    test('opens on the opening, day by day, in its order', () {
      for (final String name in ['skipped', 'left as it starts']) {
        final Set<String> read = {};
        for (var day = 0; day < kOpeningDays; day++) {
          final Deal deal = _openingDay(_choices[name]!, day: day, read: read)!;
          expect(_ids(deal.cards), [
            for (final c in kFirstDays)
              if (c.day == day + 1) c.id,
          ], reason: '$name, day ${day + 1}');
          // Two of the three questions are the reader's own, as on any
          // free day.
          expect(deal.own, hasLength(kOwnCardsFree));
          expect(
            deal.cards.where((p) => deal.own.contains(p.id)),
            everyElement(
              predicate<Pill>((p) => p.asksSomething, 'asks something'),
            ),
          );
          read.addAll(_ids(deal.cards));
        }
      }
    });

    test('with the opening\'s own shape off, its days ask two, as any day '
        'does, from the same cards in the same order', () {
      final Set<String> read = {};
      for (var day = 0; day < kOpeningDays; day++) {
        final Deal deal = _openingDay(
          _choices['skipped']!,
          day: day,
          read: read,
          asking: null,
        )!;
        expect(deal.cards, hasLength(kPillsPerDay));
        expect(
          deal.cards.where((p) => p.asksSomething),
          hasLength(asksInADay(kPillsPerDay)),
        );
        expect(deal.cards.first.id, isIn(_ids(PillBank.cards)));
        read.addAll(_ids(deal.cards));
      }
      expect(
        read.difference({for (final c in kFirstDays) c.id}),
        isEmpty,
        reason: 'all from the opening',
      );
    });

    test(
      'a card left unread comes the next morning, before the next day\'s',
      () {
        final _Choice skipped = _choices['skipped']!;
        final List<Pill> first = _openingDay(skipped, day: 0)!.cards;
        // Three read, then the app closed: the day was never finished.
        final Deal again = _openingDay(
          skipped,
          day: 0,
          read: _ids(first.take(3)).toSet(),
        )!;
        expect(_ids(again.cards), containsAll(_ids(first.skip(3))));
        expect(again.cards, hasLength(kPillsPerDay));
      },
    );
  });

  group('every first-run answer', () {
    for (final MapEntry<String, _Choice> e in _choices.entries) {
      test('${e.key}: three days of five, on the mix, varied, the opening '
          'first, nothing read twice', () {
        final Set<String> subjects = {
          for (final key in _subjectsOf(e.value.mix)) ?kTopics[key]?.name,
        };
        final Set<String> read = {};
        for (var day = 0; day < kOpeningDays; day++) {
          final Deal? opening = _openingDay(e.value, day: day, read: read);
          final String at = '${e.key}, day ${day + 1}';
          // A mix that keeps few of the opening's subjects runs out of it
          // after the first morning, and is dealt as any day is.
          if (opening == null && day > 0) break;
          expect(opening, isNotNull, reason: at);
          final Deal deal = opening!;
          final List<Pill> five = deal.cards;
          expect(five, hasLength(kPillsPerDay), reason: at);
          expect(_ids(five).toSet(), hasLength(kPillsPerDay), reason: at);
          expect(read.intersection(_ids(five).toSet()), isEmpty, reason: at);
          expect(
            five.map((p) => p.topic).toSet().difference(subjects),
            isEmpty,
            reason: '$at: a subject the reader turned off',
          );
          expect(
            five.where((p) => p.asksSomething),
            hasLength(kOpeningAsks),
            reason: at,
          );
          expect(five.first.asksSomething, isFalse, reason: at);
          expect(deal.own, hasLength(kOwnCardsFree), reason: at);
          expect(
            five.where((p) => p.mature || p.mood == 'dark'),
            isEmpty,
            reason: at,
          );
          read.addAll(_ids(five));
          if (day > 0) continue;
          // The first morning above all: it opens on one of the opening's
          // drawings, holds at least three of them, and no subject twice
          // where the mix has room for five.
          final Set<String> chosen = {for (final c in kFirstDays) c.id};
          expect(chosen, contains(five.first.id), reason: at);
          expect(
            five.where((p) => chosen.contains(p.id)),
            hasLength(greaterThanOrEqualTo(3)),
            reason: at,
          );
          if (subjects.length >= kPillsPerDay + 1) {
            expect(
              five.map((p) => p.topic).toSet(),
              hasLength(kPillsPerDay),
              reason: at,
            );
          }
        }
      });
    }

    test('a subject held above the rest comes first on the first morning', () {
      final List<Pill> five = _openingDay(
        _choices['space and history above the rest']!,
        day: 0,
      )!.cards;
      expect(
        five.first.topic,
        anyOf(kTopics['space']!.name, kTopics['history']!.name),
      );
      expect(
        five.map((p) => p.topic),
        containsAll([kTopics['space']!.name, kTopics['history']!.name]),
      );
      final List<Pill> alone = _openingDay(
        _choices['space alone']!,
        day: 0,
      )!.cards;
      expect(alone.first.topic, kTopics['space']!.name);
    });

    test('two cards telling one story never both reach a reader', () {
      final _Choice both = (
        mix: _only(['history', 'science']),
        genresOff: const <String>{},
      );
      final Set<String> read = {};
      for (var day = 0; day < kOpeningDays; day++) {
        final Deal? opening = _openingDay(both, day: day, read: read);
        if (opening == null) break;
        read.addAll(_ids(opening.cards));
      }
      // One of the two, never both: the reader met the story once.
      expect(
        read.intersection({
          'history-baia-sunken-city',
          'science-bradyseism-breathing-ground',
        }),
        hasLength(1),
      );
    });

    test('a review due on Astute+ keeps its asking slot, and all five are '
        'the reader\'s own', () {
      final Pill due = PillBank.cards.firstWhere(
        (p) => p.isGraded && p.topic == kTopics['thinking']!.name,
      );
      final Deal deal = dealOpening(
        date: _start,
        topics: kTopicOrder.toSet(),
        reviews: [due],
        own: kPillsPerDay,
      )!;
      expect(_ids(deal.cards), contains(due.id));
      expect(deal.cards.where((p) => p.asksSomething), hasLength(2));
      expect(deal.own, _ids(deal.cards).toSet());
    });

    test('a bank that has none of the opening deals the day as before', () {
      expect(
        dealOpening(
          date: _start,
          topics: kTopicOrder.toSet(),
          exclude: {for (final c in kFirstDays) c.id},
        ),
        isNull,
      );
    });
  });

  group('the rest of the first week', () {
    for (final MapEntry<String, _Choice> e in _choices.entries) {
      test('${e.key}: days four to seven mostly drawn, from the strong '
          'drawings first, the cards of words let in one at a time', () {
        final Set<String> subjects = {
          for (final key in _subjectsOf(e.value.mix)) ?kTopics[key]?.name,
        };
        final Set<String> ranked = {...kStrongDrawings, ...kFairDrawings};
        // The opening read first, as a reader does.
        final Set<String> read = {};
        for (var day = 0; day < kOpeningDays; day++) {
          final Deal? opening = _openingDay(e.value, day: day, read: read);
          if (opening == null) break;
          read.addAll(_ids(opening.cards));
        }
        for (var day = kOpeningDays; day < kShowcaseDays; day++) {
          final String at = '${e.key}, day ${day + 1}';
          // What this reader can still be dealt from the drawings ranked,
          // and how many of them one day can hold: two of a subject at most,
          // two that ask and three to read.
          final List<Pill> pool = firstWeekFor(
            DateTime(_start.year, _start.month, _start.day + day),
            topics: _subjectsOf(e.value.mix),
            exclude: read,
          );
          final int left = pool.length;
          final Map<String, int> bySubject = {};
          int roomAsks = 0, roomReads = 0;
          for (final Pill p in pool) {
            if ((bySubject[p.topic] ?? 0) >= 2) continue;
            if (p.asksSomething ? roomAsks >= 2 : roomReads >= 3) continue;
            bySubject[p.topic] = (bySubject[p.topic] ?? 0) + 1;
            p.asksSomething ? roomAsks++ : roomReads++;
          }
          final int room = roomAsks + roomReads;
          final Deal? deal = _weekDay(e.value, day: day, read: read);
          if (left == 0) {
            expect(deal, isNull, reason: '$at: nothing left to lean on');
            continue;
          }
          expect(deal, isNotNull, reason: at);
          final List<Pill> five = deal!.cards;
          expect(five, hasLength(kPillsPerDay), reason: at);
          expect(read.intersection(_ids(five).toSet()), isEmpty, reason: at);
          expect(
            five.map((p) => p.topic).toSet().difference(subjects),
            isEmpty,
            reason: '$at: a subject the reader turned off',
          );
          expect(
            five.where((p) => p.asksSomething),
            hasLength(asksInADay(kPillsPerDay)),
            reason: at,
          );
          final int wanted = firstWeekDrawnOn(day);
          final List<Pill> fromRank = [
            for (final p in five)
              if (ranked.contains(p.id)) p,
          ];
          // As many drawn as the day leans to, where the reader's subjects
          // still have that many for one day; never a weak drawing for it.
          expect(
            fromRank.length,
            greaterThanOrEqualTo(wanted < room ? wanted : room),
            reason: at,
          );
          expect(
            five.where((p) => p.hasPage).length,
            greaterThanOrEqualTo(fromRank.length),
            reason: at,
          );
          expect(
            fromRank.where((p) => p.mature || p.mood == 'dark'),
            isEmpty,
            reason: at,
          );
          read.addAll(_ids(five));
        }
      });
    }

    test('four, four, three and three of the five drawn, and none on any '
        'other day', () {
      expect(
        [for (var day = 0; day < 9; day++) firstWeekDrawnOn(day)],
        [0, 0, 0, 4, 4, 3, 3, 0, 0],
      );
    });

    test('a reader who leaned nowhere meets the strong drawings before the '
        'fair ones', () {
      final Set<String> read = {for (final c in kFirstDays) c.id};
      final Deal deal = _weekDay(_choices['skipped']!, day: 3, read: read)!;
      final List<Pill> drawn = [
        for (final p in deal.cards)
          if (kStrongDrawings.contains(p.id)) p,
      ];
      expect(drawn, hasLength(greaterThanOrEqualTo(firstWeekDrawnOn(3))));
    });
  });

  group('the app', () {
    setUp(() {
      Remote.reset();
      Remote.fetch = (url) async => null;
    });

    tearDown(() {
      Served.useForTest(Served());
      Analytics.useForTest(null);
      Remote.reset();
    });

    test(
      'a new reader\'s first morning is dealt again from their answers, '
      'the opening for three days, then the days as they always were',
      () async {
        DateTime now = _start;
        final AppState app = await _open(() => now);
        expect(app.firstDays, isTrue);
        // Before the first run has asked anything: the opening as it is.
        expect(_ids(app.todaysDeck), [
          for (final c in kFirstDays)
            if (c.day == 1) c.id,
        ]);

        final _Choice c = _choices['space and history above the rest']!;
        await app.setTopicMix(c.mix!);
        await app.completeOnboarding();
        final List<String> first = _ids(app.todaysDeck);
        expect(first, _ids(_openingDay(c, day: 0)!.cards));
        expect(app.ownIdsToday, _openingDay(c, day: 0)!.own);
        expect(
          first,
          isNot(_ids(_openingDay(_choices['skipped']!, day: 0)!.cards)),
        );
        // Kept, so a restart opens on the same five.
        expect(_ids((await _launch(() => now)).todaysDeck), first);

        final Set<String> read = {...first};
        for (var day = 1; day < kOpeningDays; day++) {
          await _finish(app);
          now = DateTime(now.year, now.month, now.day + 1, 9);
          expect(await app.turnDayIfDue(), isTrue);
          expect(app.opensOn(now), isTrue);
          expect(
            _ids(app.todaysDeck),
            _ids(_openingDay(c, day: day, read: read)!.cards),
            reason: 'day ${day + 1}',
          );
          read.addAll(_ids(app.todaysDeck));
        }
        await _finish(app);
        now = DateTime(now.year, now.month, now.day + 1, 9);
        expect(await app.turnDayIfDue(), isTrue);
        expect(app.opensOn(now), isFalse, reason: 'the fourth day');
        // The rest of the first week, on the phone and mostly drawn.
        expect(app.dealtHere(now), isTrue, reason: 'the fourth day');
        expect(
          _ids(app.todaysDeck),
          _ids(_weekDay(c, day: kOpeningDays, read: read)!.cards),
        );
      },
    );

    test('on the opening\'s days every card with a right answer asks how '
        'sure, even one whose odds say never; off, by its odds', () async {
      final AppState app = await _open(() => _start);
      await app.completeOnboarding();
      for (final Pill p in app.todaysDeck.where((p) => p.isGraded)) {
        expect(SureAsk.of(p), isTrue, reason: p.id);
      }
      // A card that would never ask by its odds, dealt into the day.
      final Pill never = cardFromJson({
        'id': 'never-asks',
        'topic': 'thinking',
        'kind': 'pickOne',
        'difficulty': 'medium',
        'principle': 'baseRate',
        'question': 'Which?',
        'options': ['A', 'B', 'C'],
        'correct': 1,
        'answer': 'B.',
        'move': 'Ask the base rate.',
        'source': 'A source',
        'sure': 0,
      });
      expect(SureAsk.of(never), isFalse, reason: 'not today\'s');
      app.todaysDeck = [...app.todaysDeck.take(4), never];
      expect(SureAsk.of(never), isTrue);
      _flags({
        'opening.asks': {'on': false},
      });
      expect(SureAsk.of(never), isFalse);
    });

    test('with the first week\'s drawings off, the fourth day is dealt as '
        'any day, by the server first', () async {
      _flags({
        'firstWeek.drawn': {'on': false},
      });
      final DateTime fourth = DateTime(2026, 11, 29, 9);
      final AppState app = await _open(() => fourth, {
        'knowit.onboarded': true,
        'knowit.firstDays': true,
        'knowit.completedDates': ['2026-11-26', '2026-11-27', '2026-11-28'],
      });
      expect(app.dealtHere(fourth), isFalse);
    });

    test('a reader past the first run before the opening is dealt as '
        'before', () async {
      final AppState app = await _open(() => _start, {
        'knowit.onboarded': true,
      });
      expect(app.firstDays, isFalse);
      expect(app.opensOn(_start), isFalse);
      final ReaderProfile untold = ReaderProfile.read(weights: const {});
      expect(
        _ids(app.todaysDeck),
        _ids(
          dealDay(
            date: _start,
            topics: kTopicOrder.toSet(),
            weights: untold.weightsOn(0, const {}),
            mix: const {},
            levels: untold.levelsUnder(const {}),
            own: ownCardsFor(plus: false, streak: 0, sunday: isSunday(_start)),
            day: 0,
          ).cards,
        ),
      );
    });

    test('the first week is the phone\'s, whatever the server holds; the '
        'eighth day is the server\'s again', () async {
      final MemoryServedStore store = MemoryServedStore();
      Served.useForTest(Served(storeOverride: store, uidOverride: 'me'));
      final ServedDay theirs = ServedDay(
        date: dateKey(_start),
        cards: PillBank.cards.take(kPillsPerDay).toList(),
        own: const {},
        reviews: const {},
      );
      store.days['me:${dateKey(_start)}'] = theirs;
      final AppState app = await _open(() => _start);
      expect(app.dealtBy, 'phone');
      expect(store.asked, 0);
      expect(_ids(app.todaysDeck), isNot(_ids(theirs.cards)));

      // A reader three days in is past the opening, and the phone deals
      // the rest of their first week, mostly drawn.
      final DateTime fourth = DateTime(2026, 11, 29, 9);
      store.days['me:${dateKey(fourth)}'] = ServedDay(
        date: dateKey(fourth),
        cards: theirs.cards,
        own: const {},
        reviews: const {},
      );
      final AppState later = await _open(() => fourth, {
        'knowit.onboarded': true,
        'knowit.firstDays': true,
        'knowit.completedDates': ['2026-11-26', '2026-11-27', '2026-11-28'],
      });
      expect(later.opensOn(fourth), isFalse);
      expect(later.dealtHere(fourth), isTrue);
      expect(later.dealtBy, 'phone');
      expect(store.asked, 0);

      // A reader seven days in is past the first week, and the server deals.
      final DateTime eighth = DateTime(2026, 12, 3, 9);
      store.days['me:${dateKey(eighth)}'] = ServedDay(
        date: dateKey(eighth),
        cards: theirs.cards,
        own: const {},
        reviews: const {},
      );
      final AppState past = await _open(() => eighth, {
        'knowit.onboarded': true,
        'knowit.firstDays': true,
        'knowit.completedDates': [
          for (var d = 26; d <= 30; d++) '2026-11-$d',
          '2026-12-01',
          '2026-12-02',
        ],
      });
      expect(past.dealtHere(eighth), isFalse);
      expect(past.dealtBy, 'server');
    });

    test('the first day is said once, when the reader reaches it', () async {
      final _Said said = _Said();
      Analytics.useForTest(said);
      final AppState app = await _open(() => _start);
      expect(said.names, isNot(contains('day started')));
      await app.setTopicMix(_only(['science', 'space', 'nature']));
      await app.completeOnboarding();
      expect(said.names.where((n) => n == 'day started'), hasLength(1));
      expect(
        said.names.indexOf('day started'),
        greaterThan(said.names.indexOf('onboarding completed')),
      );
    });
  });
}
