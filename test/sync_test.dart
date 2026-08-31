import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/account.dart';
import 'package:astuto/sync/reader_snapshot.dart';
import 'package:astuto/sync/reader_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('merging a phone into an account', () {
    test('nothing is lost when the account is empty', () {
      const local = ReaderSnapshot(
        streak: 6,
        bestStreak: 6,
        pillsRead: 30,
        savedIds: ['a', 'b'],
        completedDates: ['2026-08-01'],
        judgements: [Judgement(70, correct: true)],
      );

      final merged = mergeSnapshots(local, const ReaderSnapshot());

      expect(merged.streak, 6);
      expect(merged.pillsRead, 30);
      expect(merged.savedIds, ['a', 'b']);
      expect(merged.judgements, hasLength(1));
    });

    test('the better streak wins, and days are the union of both', () {
      const local = ReaderSnapshot(
        streak: 3,
        bestStreak: 4,
        completedDates: ['2026-08-01', '2026-08-02'],
        lastCompletionDate: '2026-08-02',
      );
      const remote = ReaderSnapshot(
        streak: 9,
        bestStreak: 9,
        completedDates: ['2026-08-02', '2026-08-03'],
        lastCompletionDate: '2026-08-03',
      );

      final merged = mergeSnapshots(local, remote);

      expect(merged.streak, 9);
      expect(merged.bestStreak, 9);
      expect(merged.lastCompletionDate, '2026-08-03');
      expect(merged.completedDates, hasLength(3));
    });

    test('a card keeps the answer that has climbed further', () {
      const local = ReaderSnapshot(
        answers: {'p1': Answer('a', stage: 2), 'p2': Answer('b')},
      );
      const remote = ReaderSnapshot(answers: {'p1': Answer('z', stage: 0)});

      final merged = mergeSnapshots(local, remote);

      expect(merged.answers['p1']!.response, 'a');
      expect(merged.answers['p1']!.stage, 2);
      expect(merged.answers['p2'], isNotNull);
    });

    test('the longer judgement record survives, and is never cut', () {
      const local = ReaderSnapshot(judgements: [Judgement(50, correct: false)]);
      const remote = ReaderSnapshot(
        judgements: [
          Judgement(60, correct: true),
          Judgement(70, correct: true),
          Judgement(80, correct: false),
        ],
      );

      expect(mergeSnapshots(local, remote).judgements, hasLength(3));
      expect(mergeSnapshots(remote, local).judgements, hasLength(3));
    });

    test('a mix chosen on this phone beats the one on the account', () {
      const local = ReaderSnapshot(
        topicWeights: {'space': 2},
        pickedTopics: ['space', 'thinking'],
      );
      const remote = ReaderSnapshot(
        topicWeights: {'history': 1},
        pickedTopics: ['history', 'thinking'],
      );

      expect(mergeSnapshots(local, remote).topicWeights, {'space': 2.0});
      // And with nothing chosen here, the account's answer stands.
      expect(mergeSnapshots(const ReaderSnapshot(), remote).topicWeights, {
        'history': 1.0,
      });
    });

    test('survives a round trip through JSON', () {
      const before = ReaderSnapshot(
        name: 'Marco',
        streak: 4,
        savedIds: ['x'],
        answers: {'p1': Answer('a', confidence: 70, stage: 1)},
        judgements: [Judgement(70, correct: true)],
        topicWeights: {'space': 2},
      );

      final after = ReaderSnapshot.fromJson(before.toJson());

      expect(after.name, 'Marco');
      expect(after.streak, 4);
      expect(after.savedIds, ['x']);
      expect(after.answers['p1']!.confidence, 70);
      expect(after.judgements.single.confidence, 70);
      expect(after.topicWeights, {'space': 2.0});
    });
  });

  group('signing in after a week of use', () {
    test('the week goes up to the account, and nothing is dropped', () async {
      SharedPreferences.setMockInitialValues({
        'knowit.onboarded': true,
        'knowit.streak': 5,
        'knowit.bestStreak': 5,
        'knowit.pillsRead': 25,
        'knowit.savedIds': <String>['p1'],
      });
      final app = AppState();
      await app.init();

      final store = MemoryReaderStore();
      final account = Account(storeOverride: store);

      final merged = await account.foldInto(app, 'reader-1');

      expect(merged, isNotNull);
      expect(store.writes, 1);
      expect(await store.read('reader-1'), isNotNull);
      expect((await store.read('reader-1'))!.streak, 5);
      expect((await store.read('reader-1'))!.savedIds, contains('p1'));
      // And the phone keeps what it had.
      expect(app.streak, 5);
      expect(app.savedIds, contains('p1'));
    });

    test('a richer account is adopted onto the phone', () async {
      SharedPreferences.setMockInitialValues({
        'knowit.onboarded': true,
        'knowit.streak': 1,
      });
      final app = AppState();
      await app.init();

      final store = MemoryReaderStore({
        'reader-1': const ReaderSnapshot(
          name: 'Marco',
          streak: 12,
          bestStreak: 12,
          pillsRead: 60,
          savedIds: ['old'],
          judgements: [Judgement(80, correct: true)],
        ),
      });
      final account = Account(storeOverride: store);

      await account.foldInto(app, 'reader-1');

      expect(app.streak, 12);
      expect(app.pillsRead, 60);
      expect(app.name, 'Marco');
      expect(app.savedIds, contains('old'));
      expect(app.judgements, hasLength(1));

      // Stored, not only held in memory.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('knowit.streak'), 12);
    });

    test('does nothing at all when there is no cloud', () async {
      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      final app = AppState();
      await app.init();

      // No override and no Firebase: the account has nowhere to write.
      expect(await Account().foldInto(app, 'reader-1'), isNull);
    });
  });

  group('keeping the account up to date', () {
    Future<AppState> installed() async {
      SharedPreferences.setMockInitialValues({
        'knowit.onboarded': true,
        'knowit.streak': 2,
      });
      final app = AppState();
      await app.init();
      return app;
    }

    test('a change is backed up once the app settles', () async {
      final app = await installed();
      final store = MemoryReaderStore();
      Account(storeOverride: store, uidOverride: 'reader-1').watch(app);

      fakeAsync((async) {
        app.toggleSaved('p1');
        // Nothing yet: five answers in a row should be one write, not five.
        expect(store.writes, 0);
        async.elapse(const Duration(seconds: 5));
      });
      await Future<void>.delayed(Duration.zero);

      expect(store.writes, 1);
      expect((await store.read('reader-1'))!.savedIds, contains('p1'));
    });

    test('several changes in a row are one write', () async {
      final app = await installed();
      final store = MemoryReaderStore();
      final account = Account(storeOverride: store, uidOverride: 'reader-1')
        ..watch(app);

      fakeAsync((async) {
        app.toggleSaved('p1');
        async.elapse(const Duration(seconds: 1));
        app.toggleSaved('p2');
        async.elapse(const Duration(seconds: 1));
        app.toggleSaved('p3');
        async.elapse(const Duration(seconds: 6));
      });
      await Future<void>.delayed(Duration.zero);

      expect(store.writes, 1);
      account.dispose();
    });

    test('signed out, a change schedules nothing at all', () async {
      final app = await installed();
      final store = MemoryReaderStore();
      // No uid: nobody to back up to.
      Account(storeOverride: store).watch(app);

      fakeAsync((async) {
        app.toggleSaved('p1');
        async.elapse(const Duration(minutes: 1));
      });
      await Future<void>.delayed(Duration.zero);

      expect(store.writes, 0);
    });
  });

  group('when the app asks about notifications', () {
    Future<AppState> withPrefs(Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues(prefs);
      final app = AppState();
      await app.init();
      return app;
    }

    test('not on a fresh install: there is nothing to protect yet', () async {
      final app = await withPrefs({'knowit.onboarded': true});
      expect(app.shouldAskForPush, isFalse);
    });

    test('once a day is behind the reader', () async {
      final app = await withPrefs({
        'knowit.onboarded': true,
        'knowit.completedDates': <String>['2026-08-30'],
      });
      expect(app.shouldAskForPush, isTrue);
    });

    test('a refusal is remembered as firmly as a yes', () async {
      final app = await withPrefs({
        'knowit.onboarded': true,
        'knowit.completedDates': <String>['2026-08-30'],
      });

      // No token came back: the reader said no.
      await app.notedPushAnswer();

      expect(app.shouldAskForPush, isFalse);
      expect(app.pushTokens, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('knowit.pushAsked'), isTrue);
    });

    test('a yes is stored and travels with the account', () async {
      final app = await withPrefs({
        'knowit.onboarded': true,
        'knowit.completedDates': <String>['2026-08-30'],
      });

      await app.notedPushAnswer(token: 'token-a');

      expect(app.shouldAskForPush, isFalse);
      expect(app.snapshot().pushTokens, ['token-a']);
    });

    test('the other phone is not unsubscribed by this one', () {
      const local = ReaderSnapshot(pushTokens: ['this-phone']);
      const remote = ReaderSnapshot(pushTokens: ['other-phone']);

      expect(
        mergeSnapshots(local, remote).pushTokens,
        containsAll(<String>['this-phone', 'other-phone']),
      );
    });
  });
}
