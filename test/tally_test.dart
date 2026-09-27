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
        ago(0): {'a': 3, 'b': 1},
        ago(2): {'c': 3, 'b': 1},
        ago(6): {'d': 2},
        ago(7): {'e': 9},
        ago(29): {'f': 1},
        ago(30): {'g': 50},
      }),
      clock: () => now,
    );
    await tallies.refresh();
    expect(tallies.answered, isTrue);

    List<String> ids(List<Ranked> list) => [for (final r in list) r.id];

    // a and c both have three; a was counted today, c two days ago.
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
    expect(store.asked.single, hasLength(Tallies.monthDays));

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
}
