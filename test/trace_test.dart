import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/sync/trace.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final DateTime now = DateTime.utc(2026, 10, 3, 9, 30);

  test('keeps the gestures that matter, short, and drops the rest', () {
    final MemoryTraceStore store = MemoryTraceStore();
    final Trace trace = Trace(
      storeOverride: store,
      uidOverride: 'me',
      clock: () => now,
    );
    trace.note('card advanced', {
      'pill_id': 'science-1',
      'ms_on_card': 4200,
      'topic': 'Science',
      'genre': 'science.physics',
      'review': false,
      'nothing': null,
    });
    trace.note('theme set', {'theme': 'dark'});
    trace.note('card answered', {
      'pill_id': 'thinking-4',
      'correct': true,
      'confidence': 80,
      'gave_reason': true,
      'reason': 'because of the base rate', // prose never goes
    });
    expect(trace.waiting, 2);
    trace.note('explore searched', {'length': 5, 'found': 3, 'query': 'why'});
    expect(trace.waiting, 3);
    // The finer gestures: the turn timed, the hint asked for, the answer's
    // shape, how far down Explore went, how long the app was open.
    trace.note('card flipped', {'pill_id': 'space-2', 'ms_to_flip': 3100});
    trace.note('hint shown', {'pill_id': 'space-2'});
    trace.note('explore scrolled', {'depth': 70});
    trace.note('app paused', {'ms_in_app': 91000});
    expect(trace.waiting, 7);
  });

  test('flushes after the batch, or when the app leaves, by UTC day, and '
      'notes the reader was here', () {
    fakeAsync((async) {
      final MemoryTraceStore store = MemoryTraceStore();
      DateTime clock = now;
      final Trace trace = Trace(
        storeOverride: store,
        uidOverride: 'me',
        clock: () => clock,
      );
      for (var i = 0; i < Trace.batch - 1; i++) {
        trace.note('card viewed', {'pill_id': 'science-$i'});
      }
      async.flushMicrotasks();
      expect(store.appends, 0, reason: 'one short of the batch');
      trace.note('card viewed', {'pill_id': 'science-x'});
      async.flushMicrotasks();
      expect(store.appends, 1);
      expect(store.days['me']!['2026-10-03'], hasLength(Trace.batch));
      expect(store.presences['me']!['tz'], now.timeZoneOffset.inMinutes);
      expect(trace.waiting, 0);

      // One event, left alone: it goes after the settle.
      clock = DateTime.utc(2026, 10, 4, 0, 5);
      trace.note('pill liked', {'pill_id': 'space-2'});
      async.elapse(const Duration(seconds: 5));
      expect(store.appends, 1);
      async.elapse(Trace.settle);
      expect(store.appends, 2);
      expect(store.days['me']!['2026-10-04']!.single['e'], 'like');
      expect(store.days['me']!['2026-10-04']!.single['c'], 'space-2');
    });
  });

  test('offline the queue waits, and goes with the next flush', () async {
    final MemoryTraceStore store = MemoryTraceStore()..refusing = true;
    final Trace trace = Trace(
      storeOverride: store,
      uidOverride: 'me',
      clock: () => now,
    );
    trace.note('day started', {'own': 2, 'reviews': 1});
    await trace.flush();
    expect(trace.waiting, 1);
    expect(store.appends, 0);
    store.refusing = false;
    await trace.flush();
    expect(trace.waiting, 0);
    expect(store.days['me']!['2026-10-03']!.single['own'], 2);
    // And what is waiting survives a launch.
    final MemoryTraceStore later = MemoryTraceStore()..refusing = true;
    final Trace before = Trace(
      storeOverride: later,
      uidOverride: 'me',
      clock: () => now,
    );
    before.note('card viewed', {'pill_id': 'a'});
    await before.flush();
    later.refusing = false;
    final Trace after = Trace(
      storeOverride: later,
      uidOverride: 'me',
      clock: () => now,
    );
    await after.flush();
    expect(later.days['me']!['2026-10-03']!.single['c'], 'a');
  });

  test('nobody signed in: nothing is written, and nothing breaks', () async {
    final MemoryTraceStore store = MemoryTraceStore();
    final Trace trace = Trace(storeOverride: store, clock: () => now);
    trace.note('card viewed', {'pill_id': 'a'});
    await trace.flush();
    expect(store.appends, 0);
    expect(trace.waiting, 1);
    await trace.reset();
    expect(trace.waiting, 0);
  });
}
