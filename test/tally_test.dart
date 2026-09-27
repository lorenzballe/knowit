import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/tally.dart';

/// A store that will not answer, as Firestore does offline or on rules that
/// have not been published yet.
class _Refusing implements TallyStore {
  @override
  Future<void> add(String day, String pillId) async =>
      throw StateError('permission-denied');

  @override
  Future<Map<String, Map<String, int>>> read(List<String> days) async =>
      throw StateError('permission-denied');

  @override
  Future<void> addTotal(String pillId) async =>
      throw StateError('permission-denied');

  @override
  Future<Map<String, int>> readTotals() async =>
      throw StateError('permission-denied');
}

/// Lets the write that [Tallies.held] sends off land.
Future<void> _landed() => Future<void>.delayed(Duration.zero);

void main() {
  final DateTime now = DateTime.utc(2026, 9, 26, 15);
  String ago(int days) => tallyDay(now.subtract(Duration(days: days)));

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'a day is a UTC day, so every phone files a like under the same one',
    () {
      expect(tallyDay(DateTime.utc(2026, 9, 26, 23, 59)), '2026-09-26');
      expect(
        tallyDay(DateTime.parse('2026-09-27T01:30:00+02:00')),
        '2026-09-26',
      );
      expect(tallyDay(DateTime.utc(2026, 1, 5)), '2026-01-05');
    },
  );

  test('a card counts once per phone, however often it is liked, saved or '
      'said', () async {
    final MemoryTallyStore store = MemoryTallyStore();
    final Tallies tallies = Tallies(storeOverride: store, clock: () => now);

    await tallies.held('science-1');
    await tallies.held('science-1');
    await tallies.held('science-2');
    await _landed();

    expect(store.days[ago(0)], {'science-1': 1, 'science-2': 1});

    // A new session on the same phone remembers what it already counted.
    final Tallies later = Tallies(storeOverride: store, clock: () => now);
    await later.held('science-1');
    await _landed();
    expect(store.days[ago(0)]!['science-1'], 1);
  });

  test('the list: most readers first, then the card counted most recently, '
      'then by id — over the week or the month, narrowed as asked', () async {
    final Tallies tallies = Tallies(
      storeOverride: MemoryTallyStore({
        // Today and yesterday are still open: never on the list.
        ago(0): {'z': 99},
        ago(1): {'z': 99},
        ago(2): {'a': 3, 'b': 1},
        ago(4): {'c': 3, 'b': 1},
        ago(8): {'d': 2},
        ago(9): {'e': 9},
        ago(31): {'f': 1},
        ago(32): {'g': 50},
      }),
      clock: () => now,
    );
    await tallies.refresh();
    expect(tallies.answered, isTrue);

    List<String> ids(List<Ranked> list) => [for (final r in list) r.id];

    // a and c both have three; a was counted on the last closed day, c two
    // days before it.
    expect(ids(tallies.top(7)), ['a', 'c', 'b', 'd']);
    expect(tallies.top(7)[2].readers, 2, reason: 'b over two days');

    // The month reaches e and f; g is a day past it.
    expect(ids(tallies.top(30)), ['e', 'a', 'c', 'b', 'd', 'f']);
    expect(ids(tallies.top(30, limit: 2)), ['e', 'a']);
    expect(ids(tallies.top(30, where: (id) => id != 'e')).first, 'a');
  });

  test('a settled day is read once; the last three days every time', () async {
    final MemoryTallyStore store = MemoryTallyStore({
      ago(10): {'science-1': 4},
    });
    DateTime clock = now;
    final Tallies tallies = Tallies(storeOverride: store, clock: () => clock);

    await tallies.refresh();
    expect(
      store.asked.single,
      hasLength(Tallies.closedAfter + Tallies.monthDays),
    );

    // Ten minutes is fresh: nothing is asked for.
    clock = now.add(const Duration(minutes: 5));
    await tallies.refresh();
    expect(store.asked, hasLength(1));

    clock = now.add(const Duration(minutes: 11));
    await tallies.refresh();
    expect(store.asked.last, [ago(0), ago(1), ago(2)]);
    expect(tallies.top(30).single.readers, 4, reason: 'kept, not re-read');

    // And a fresh phone session reads them from the phone, not the store.
    final Tallies again = Tallies(storeOverride: store, clock: () => now);
    await again.refresh();
    expect(store.asked.last, [ago(0), ago(1), ago(2)]);
    expect(again.top(30).single.id, 'science-1');
  });

  test(
    'counts that cannot be read leave the list unanswered, not empty',
    () async {
      final Tallies refused = Tallies(
        storeOverride: _Refusing(),
        clock: () => now,
      );
      await refused.refresh();
      expect(refused.answered, isFalse);

      // Nor does a write that is refused break anything.
      await refused.held('science-1');
      await _landed();
    },
  );

  test(
    'liking, saving and saying a card count it once, for the reader',
    () async {
      final MemoryTallyStore store = MemoryTallyStore();
      Tallies.useForTest(Tallies(storeOverride: store));
      addTearDown(() => Tallies.useForTest(Tallies()));
      final AppState app = AppState();
      await app.init();
      final String a = PillBank.cards[0].id;
      final String b = PillBank.cards[1].id;
      final String day = tallyDay(DateTime.now());

      await app.toggleLiked(a);
      await app.toggleLiked(a); // unliked: nothing is taken back
      await app.toggleLiked(a); // liked again: nothing is added
      await app.toggleSaved(a);
      await app.markSaid(b);
      await _landed();

      expect(store.days[day], {a: 1, b: 1});
    },
  );

  group('The launch crowd', () {
    final List<String> ids = [for (var i = 0; i < 2000; i++) 'card-$i'];

    test('is the same on every phone, and seeds about one card in seven', () {
      final a = TopSeed(ids: () => ids).on('2026-10-02');
      final b = TopSeed(ids: () => ids).on('2026-10-02');
      expect(a, b);
      final seeded = ids.where((id) => TopSeed.popularity(id) > 0).length;
      expect(seeded, inInclusiveRange(220, 380));
    });

    test('gives the list something to show before any count is read, '
        'and the real readers rank on top of it', () async {
      final Tallies seeded = Tallies(
        storeOverride: MemoryTallyStore({
          ago(Tallies.closedAfter): {'card-real': 500},
        }),
        seed: TopSeed(ids: () => ids),
        clock: () => now,
      );
      expect(seeded.answered, isFalse);
      expect(seeded.ready, isTrue);
      final List<Ranked> before = seeded.top(7);
      expect(before, isNotEmpty);
      expect(before.first.readers, greaterThan(before.last.readers - 1));

      await seeded.refresh();
      expect(seeded.top(7).first.id, 'card-real');
      expect(seeded.top(7).first.readers, greaterThanOrEqualTo(500));
      // The month holds at least what the week does, card for card.
      final Map<String, int> month = {
        for (final r in seeded.top(30, limit: 5000)) r.id: r.readers,
      };
      for (final r in seeded.top(7, limit: 5000)) {
        expect(month[r.id], greaterThanOrEqualTo(r.readers), reason: r.id);
      }
    });

    test('is off unless asked for', () {
      expect(Tallies().ready, isFalse);
      expect(Tallies().top(30), isEmpty);
    });
  });

  test('the list is fixed for the day: a like today moves nothing until '
      'its day has closed', () async {
    DateTime clock = now;
    final MemoryTallyStore store = MemoryTallyStore({
      ago(3): {'science-2': 2},
    });
    final Tallies tallies = Tallies(storeOverride: store, clock: () => clock);
    await tallies.refresh();
    await tallies.held('science-1');
    await tallies.held('science-1');
    await _landed();
    List<String> ids() => [for (final r in tallies.top(7)) r.id];
    expect(ids(), ['science-2'], reason: 'today is still open');

    // Two midnights later the day has closed, on every phone at once.
    clock = now.add(const Duration(days: 2));
    await tallies.refresh(force: true);
    expect(ids(), ['science-2', 'science-1']);
  });

  test('loved since the start: the counts for good, over the launch crowd, '
      'narrowed as asked', () async {
    final MemoryTallyStore store = MemoryTallyStore();
    final Tallies tallies = Tallies(storeOverride: store, clock: () => now);
    await tallies.held('science-1');
    await _landed();
    expect(store.totals, {'science-1': 1});
    store.totals['space-2'] = 40;
    await tallies.refresh(force: true);
    expect([for (final r in tallies.allTime()) r.id], ['space-2', 'science-1']);
    expect(
      [for (final r in tallies.allTime(where: (id) => id != 'space-2')) r.id],
      ['science-1'],
    );
    // With the crowd, cards nobody has held yet are there too, the ones
    // readers did hold ranked by both.
    final Tallies seeded = Tallies(
      storeOverride: store,
      seed: TopSeed(ids: () => [for (var i = 0; i < 400; i++) 'card-$i']),
      clock: () => now,
    );
    await seeded.refresh();
    expect(seeded.allTime(limit: 400).length, greaterThan(2));
  });

  test('a card read in Explore is read: the day never deals it', () async {
    final AppState app = AppState();
    await app.init();
    final String id = PillBank.cards.last.id;
    await app.markReadElsewhere(id);
    expect(app.seenIds, contains(id));
    final AppState again = AppState();
    await again.init();
    expect(again.seenIds, contains(id), reason: 'kept across a restart');
  });
}
