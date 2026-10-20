// Where a section's cards come from (ExploreHost.cardsFor): a shelf of the
// server's Explore, cards by id, a query of the bank worked out on the phone
// and the same for everybody for the same seed, and the reader's own — every
// one narrowed to the subject chip in view, and nothing at all from a source
// this build does not know.
//
//   flutter test test/explore/sources_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/explore_mix.dart' show subjectKeyOf;
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/core/shelves.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/served.dart';

import 'core_harness.dart';

ExploreSection _section(Object? source, {String id = 's', int? limit}) =>
    ExploreSection.fromJson({
      'id': id,
      'block': 'carousel',
      'source': source,
      'limit': ?limit,
    });

List<String> _ids(List<Pill> cards) => [for (final p in cards) p.id];

void main() {
  setUp(() => Served.useForTest(Served()));

  ExploreShelves shelvesFor(AppState app, {String? subject, DateTime? on}) =>
      ExploreShelves(app, clock: on == null ? null : () => on)
        ..begin(subject: subject);

  group('a query of the bank', () {
    test('is the same pick on every phone for the same seed and section, '
        'another for another section, another the next day', () async {
      final AppState app = await readyApp();
      final DateTime monday = DateTime(2026, 10, 19, 9);
      final DateTime tuesday = DateTime(2026, 10, 20, 9);
      final Map<String, Object?> query = {
        'query': {
          'subjects': ['space', 'history'],
        },
      };
      final List<Pill> a = shelvesFor(
        app,
        on: monday,
      ).cardsFor(_section(query, id: 'a'));
      final List<Pill> again = shelvesFor(
        app,
        on: monday,
      ).cardsFor(_section(query, id: 'a'));
      final List<Pill> other = shelvesFor(
        app,
        on: monday,
      ).cardsFor(_section(query, id: 'b'));
      final List<Pill> tomorrow = shelvesFor(
        app,
        on: tuesday,
      ).cardsFor(_section(query, id: 'a'));
      expect(a, hasLength(12));
      expect(_ids(again), _ids(a));
      expect(_ids(other), isNot(_ids(a)));
      expect(_ids(tomorrow), isNot(_ids(a)));
      for (final Pill p in a) {
        expect(subjectKeyOf(p), anyOf('space', 'history'));
      }
    });

    test('a week seed holds for the week, a fixed one for good', () async {
      final AppState app = await readyApp();
      List<String> on(DateTime day, String seed) => _ids(
        shelvesFor(app, on: day).cardsFor(
          _section({
            'query': {'seed': seed},
          }),
        ),
      );
      final DateTime monday = DateTime(2026, 10, 19, 9);
      final DateTime wednesday = DateTime(2026, 10, 21, 9);
      final DateTime nextMonth = DateTime(2026, 11, 25, 9);
      expect(on(wednesday, 'week'), on(monday, 'week'));
      expect(on(nextMonth, 'fixed'), on(monday, 'fixed'));
      expect(on(wednesday, 'day'), isNot(on(monday, 'day')));
    });

    test('formats, difficulty, and at most so many from a subject', () async {
      final AppState app = await readyApp();
      final ExploreShelves shelves = shelvesFor(app);
      final List<Pill> claims = shelves.cardsFor(
        _section({
          'query': {
            'formats': ['trueOrFalse'],
            'perSubject': 1,
          },
        }, limit: 10),
      );
      expect(claims, hasLength(10));
      expect(claims.every((p) => isFormat(p, 'trueOrFalse')), isTrue);
      expect({for (final p in claims) p.topic}, hasLength(10));
      final List<Pill> hard = shelves.cardsFor(
        _section({
          'query': {
            'formats': ['debate', 'estimate'],
            'difficulty': ['hard'],
          },
        }),
      );
      expect(hard, isNotEmpty);
      for (final Pill p in hard) {
        expect(p.difficulty, Difficulty.hard);
        expect(p.challenge, anyOf(isA<TakeASide>(), isA<Estimate>()));
      }
      final List<Pill> scenes = shelves.cardsFor(
        _section({
          'query': {
            'formats': ['slider'],
          },
        }),
      );
      expect(scenes, isNotEmpty);
      expect(scenes.every((p) => p.scene?.raw['type'] == 'slider'), isTrue);
    });

    test('unread leaves out what the reader had read when the shelves were '
        'dealt; the query\'s own limit holds over a larger ask', () async {
      final List<Pill> space = PillBank.cards
          .where((p) => subjectKeyOf(p) == 'space')
          .toList();
      final Set<String> read = {for (final p in space.take(30)) p.id};
      final AppState app = await readyApp({'knowit.seenIds': read.toList()});
      final ExploreShelves shelves = shelvesFor(app);
      final List<Pill> unread = shelves.cardsFor(
        _section({
          'query': {
            'subjects': ['space'],
            'unread': true,
            'limit': 5,
          },
        }),
        limit: 40,
      );
      expect(unread, hasLength(5));
      expect(unread.any((p) => read.contains(p.id)), isFalse);
    });
  });

  group('cards by id', () {
    test('in their order, once each, the ones this phone has', () async {
      final AppState app = await readyApp();
      final List<Pill> bank = PillBank.cards;
      final List<Pill> cards = shelvesFor(app).cardsFor(
        _section({
          'ids': [bank[5].id, 'not-a-card', bank[2].id, bank[5].id, 7],
        }),
      );
      expect(_ids(cards), [bank[5].id, bank[2].id]);
    });

    test('a card about a place only for a reader who lives there', () async {
      final Pill local = PillBank.placeCards.firstWhere(
        (p) => p.place?.city == 'Bologna',
      );
      final Map<String, Object?> source = {
        'ids': [local.id],
      };
      expect(shelvesFor(await readyApp()).cardsFor(_section(source)), isEmpty);
      final AppState there = await readyApp({
        'knowit.place':
            '{"country":"IT","region":"IT-45","city":"Bologna",'
            '"lat":44.494,"lon":11.343}',
      });
      expect(_ids(shelvesFor(there).cardsFor(_section(source))), [local.id]);
    });

    test(
      'a card the bank has not got yet, from the server\'s Explore',
      () async {
        final Pill known = PillBank.cards.first;
        final Pill fresh = Pill(
          id: 'server-only-1',
          topic: known.topic,
          color: known.color,
          ink: known.ink,
          tint: known.tint,
          question: 'A card the bank on this phone does not hold yet?',
          answer: 'It came with the server\'s Explore.',
          barMove: '',
          source: 'A test',
        );
        Served.useForTest(
          Served(
            storeOverride: MemoryServedStore()
              ..shelves = ServedExplore(
                day: '2026-10-19',
                today: [fresh],
                asking: const [],
                topWeek: const [],
                topMonth: const [],
                loved: const [],
                bySubject: const {},
              ),
            uidOverride: 'reader',
          ),
        );
        await Served.instance.explore(force: true);
        final List<Pill> cards = shelvesFor(await readyApp()).cardsFor(
          _section({
            'ids': ['server-only-1'],
          }),
        );
        expect(_ids(cards), ['server-only-1']);
      },
    );
  });

  group('the reader\'s own', () {
    test('saved and liked, newest first, and what came back', () async {
      final List<Pill> bank = PillBank.cards;
      final AppState app = await readyApp({
        'knowit.savedIds': [bank[3].id, bank[1].id],
        'knowit.likedIds': [bank[8].id],
      });
      final ExploreShelves shelves = shelvesFor(app);
      expect(_ids(shelves.cardsFor(_section({'mine': 'saved'}))), [
        bank[3].id,
        bank[1].id,
      ]);
      expect(_ids(shelves.cardsFor(_section({'mine': 'liked'}))), [bank[8].id]);
      expect(shelves.cardsFor(_section({'mine': 'due'})), isEmpty);
      expect(shelves.cardsFor(_section({'mine': 'starred'})), isEmpty);
    });
  });

  group('a shelf of the server\'s Explore', () {
    test('the phone\'s own before the server has answered, the server\'s '
        'after, and for you only from the server', () async {
      final AppState app = await readyApp();
      final ExploreShelves shelves = shelvesFor(app);
      expect(
        _ids(shelves.cardsFor(_section({'shelf': 'today'}))),
        _ids(shelves.today),
      );
      expect(
        _ids(shelves.cardsFor(_section({'shelf': 'asking'}))),
        _ids(shelves.asking),
      );
      expect(shelves.cardsFor(_section({'shelf': 'forYou'})), isEmpty);
      expect(shelves.cardsFor(_section({'shelf': 'everything'})), isEmpty);

      final List<Pill> bank = PillBank.cards;
      Served.useForTest(
        Served(
          storeOverride: MemoryServedStore()
            ..shelves = ServedExplore(
              day: '2026-10-19',
              today: bank.sublist(0, 10),
              asking: const [],
              topWeek: [
                for (final p in bank.sublist(20, 23)) ServedRank(p, 40),
              ],
              topMonth: const [],
              loved: const [],
              bySubject: const {},
              forYou: bank.sublist(30, 34),
            ),
          uidOverride: 'reader',
        ),
      );
      await Served.instance.explore(force: true);
      final ExploreShelves served = shelvesFor(app);
      expect(
        _ids(served.cardsFor(_section({'shelf': 'today'}, limit: 10))),
        _ids(bank.sublist(0, 10)),
      );
      expect(
        _ids(served.cardsFor(_section({'shelf': 'topWeek'}))),
        _ids(bank.sublist(20, 23)),
      );
      expect(
        _ids(served.cardsFor(_section({'shelf': 'forYou'}))),
        _ids(bank.sublist(30, 34)),
      );
    });
  });

  test('no source, an unknown one, or two at once give no cards', () async {
    final ExploreShelves shelves = shelvesFor(await readyApp());
    expect(shelves.cardsFor(_section(null)), isEmpty);
    expect(shelves.cardsFor(_section('today')), isEmpty);
    expect(shelves.cardsFor(_section({'feed': 'everything'})), isEmpty);
    expect(
      shelves.cardsFor(
        _section({
          'query': {
            'subjects': ['astrology'],
          },
        }),
      ),
      isEmpty,
    );
  });

  test('every source is narrowed to the subject chip in view', () async {
    final List<Pill> bank = PillBank.cards;
    final Pill art = bank.firstWhere((p) => p.topic == 'Art');
    final Pill space = bank.firstWhere((p) => p.topic == 'Space');
    final AppState app = await readyApp({
      'knowit.savedIds': [art.id, space.id],
    });
    final ExploreShelves shelves = shelvesFor(app, subject: 'Space');
    for (final Object source in [
      {'mine': 'saved'},
      {
        'ids': [art.id, space.id],
      },
      {'query': <String, Object?>{}},
      {'shelf': 'today'},
    ]) {
      final List<Pill> cards = shelves.cardsFor(_section(source));
      expect(cards, isNotEmpty, reason: '$source');
      expect(cards.every((p) => p.topic == 'Space'), isTrue, reason: '$source');
    }
  });
}
