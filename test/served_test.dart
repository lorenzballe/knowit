import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/served.dart';

/// A day the server might deal: five cards of the bank, four the reader's own.
ServedDay _aDay(String date, {bool fromCache = false}) {
  final List<Pill> cards =
      PillBank.cards.where((p) => !p.asksSomething).take(3).toList()..addAll(
        PillBank.cards.where((p) => p.asksSomething && p.isGraded).take(2),
      );
  return ServedDay(
    date: date,
    cards: cards,
    own: cards.skip(1).map((p) => p.id).toSet(),
    reviews: const {},
    welcome: true,
    fromCache: fromCache,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(
    () => SharedPreferences.setMockInitialValues({'knowit.onboarded': true}),
  );
  tearDown(() => Served.useForTest(Served()));

  final String today = dateKey(DateTime.now());

  test('a served day survives JSON, and a card the app cannot draw refuses the whole day', () {
    final ServedDay day = _aDay(today);
    final ServedDay? back = ServedDay.parse(day.toJson());
    expect(back, isNotNull);
    expect(back!.cards.map((p) => p.id), day.cards.map((p) => p.id));
    expect(back.own, day.own);
    expect(back.reviews, day.reviews);
    expect(back.welcome, isTrue);
    final Map<String, Object?> broken = day.toJson();
    (broken['cards'] as List)[0] = {
      ...cardToJson(day.cards.first),
      'kind': 'hologram',
    };
    expect(ServedDay.parse(broken), isNull);
    expect(ServedDay.parse({'date': today, 'cards': []}), isNull);
  });

  test(
    'the morning takes the server\'s day, keeps it, and a restart resumes it',
    () async {
      final MemoryServedStore store = MemoryServedStore();
      final ServedDay day = _aDay(today);
      store.days['me:$today'] = day;
      Served.useForTest(Served(storeOverride: store, uidOverride: 'me'));

      final AppState app = AppState();
      await app.init();
      expect(app.todaysDeck.map((p) => p.id), day.cards.map((p) => p.id));
      expect(app.ownIdsToday, day.own);
      expect(app.dealtBy, 'server');
      expect(store.asked, 0, reason: 'the document was there');

      // The phone kept it: a second launch reads the phone, not the server.
      store.refusing = true;
      final AppState again = AppState();
      await again.init();
      expect(again.todaysDeck.map((p) => p.id), day.cards.map((p) => p.id));
    },
  );

  test(
    'no document yet: the server is asked to deal; no server: the phone deals',
    () async {
      final MemoryServedStore store = MemoryServedStore();
      store.onAsk[today] = _aDay(today);
      Served.useForTest(Served(storeOverride: store, uidOverride: 'me'));
      final AppState asked = AppState();
      await asked.init();
      expect(store.asked, 1);
      expect(asked.dealtBy, 'server');

      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      Served.useForTest(
        Served(
          storeOverride: MemoryServedStore()..refusing = true,
          uidOverride: 'me',
        ),
      );
      final AppState alone = AppState();
      await alone.init();
      expect(alone.dealtBy, 'phone');
      expect(alone.todaysDeck, hasLength(kPillsPerDay));
      // A first day: the welcome's four of the reader's own, one at random.
      expect(alone.ownIdsToday, hasLength(kOwnCardsWelcome));
      for (final p in alone.todaysDeck) {
        expect(PillBank.byId(p.id), isNotNull, reason: 'dealt from the bank');
      }
    },
  );

  test('a day read from the phone\'s copy of the store says so', () async {
    final MemoryServedStore store = MemoryServedStore();
    store.days['me:$today'] = _aDay(today, fromCache: true);
    Served.useForTest(Served(storeOverride: store, uidOverride: 'me'));
    final AppState app = AppState();
    await app.init();
    expect(app.dealtBy, 'server-cached');
  });

  test(
    'the evening asks for tomorrow, and the finished day names it',
    () async {
      final MemoryServedStore store = MemoryServedStore();
      final String tomorrow = dateKey(
        DateTime.now().add(const Duration(days: 1)),
      );
      store.onAsk[tomorrow] = _aDay(tomorrow);
      Served.useForTest(Served(storeOverride: store, uidOverride: 'me'));
      final AppState app = AppState();
      await app.init();
      expect(app.dealtBy, 'phone');
      for (var i = 0; i < kPillsPerDay; i++) {
        await app.advance();
      }
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      // Once for today (no document, the phone dealt), once for tomorrow.
      expect(store.asked, 2);
      expect(app.servedTomorrow?.date, tomorrow);
      expect(
        app.tomorrowsDeck.map((p) => p.id),
        _aDay(tomorrow).cards.map((p) => p.id),
      );
      // And the morning finds it kept on the phone without asking.
      expect(
        (await Served.instance.keptDay(
          DateTime.now().add(const Duration(days: 1)),
        ))?.date,
        tomorrow,
      );
    },
  );

  test(
    'Explore as served: shelves whole, the reader\'s own, and offline said',
    () async {
      final List<Pill> some = PillBank.cards.take(12).toList();
      final ServedExplore shelves = ServedExplore(
        day: today,
        today: some.take(8).toList(),
        asking: some.skip(8).toList(),
        topWeek: [ServedRank(some[0], 40), ServedRank(some[1], 30)],
        topMonth: [ServedRank(some[1], 300)],
        loved: [ServedRank(some[2], 4000)],
        bySubject: {},
        because: 'space',
        mine: some.where((p) => p.topic == 'Space').toList(),
        forYou: some.skip(3).take(8).toList(),
        fromCache: true,
      );
      final MemoryServedStore store = MemoryServedStore()..shelves = shelves;
      final Served served = Served(storeOverride: store, uidOverride: 'me');
      Served.useForTest(served);
      expect(await served.explore(), same(shelves));
      expect(served.lastExplore?.forYou, hasLength(8));
      expect(served.lastExplore?.fromCache, isTrue);
      // A second read within ten minutes is the same reading.
      store.shelves = null;
      expect(await served.explore(), same(shelves));
      expect(
        await served.explore(force: true),
        same(shelves),
        reason: 'nothing newer keeps the last',
      );
    },
  );

  test(
    'the search: the server\'s answer when it has one, the phone\'s otherwise',
    () async {
      final MemoryServedStore store = MemoryServedStore()
        ..hits = PillBank.cards.take(2).toList();
      final Served served = Served(storeOverride: store, uidOverride: 'me');
      expect((await served.search('why'))?.length, 2);
      store.refusing = true;
      expect(await served.search('why'), isNull);
      expect(
        await Served().search('why'),
        isNull,
        reason: 'no account, no server',
      );
    },
  );
}
