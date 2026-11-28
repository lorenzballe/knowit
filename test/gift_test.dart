// The new reader's gift, behind the server's switch `trial.reverse`, off
// as built (lib/state/gift.dart): Astute+ for fourteen days, held on the
// phone, where the first run would offer the trial; one quiet line in its
// last two days and the thirteenth's nudge; the morning after it, what the
// days came to, then the paywall. Never against the store's plan, and held
// to its first day on every phone the reader signs in on.
//
//   flutter test test/gift_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/models/reminder.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/first_card_screen.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/screens/today_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/gift.dart';
import 'package:astuto/sync/reader_snapshot.dart';
import 'package:astuto/sync/subscription.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

final AppLocalizations _en = lookupAppLocalizations(const Locale('en'));

/// The plans as the owner sets them: the year with two weeks free.
Offering _onSale() {
  const context = PresentedOfferingContext('default', null, null);
  final year = Package(
    r'$rc_annual',
    PackageType.annual,
    const StoreProduct(
      'com.astuto.app.plus.yearly',
      'Astute+',
      'Astute+',
      29.99,
      '€29.99',
      'EUR',
      introductoryPrice: IntroductoryPrice(
        0,
        '€0.00',
        'P2W',
        1,
        PeriodUnit.week,
        2,
      ),
    ),
    context,
  );
  return Offering('default', '', const {}, [year], annual: year);
}

/// Astute+ as RevenueCat describes it, once held: a trial over and never
/// paid for.
EntitlementInfo _once() => EntitlementInfo(
  kPlusEntitlement,
  false,
  false,
  DateTime.now().toUtc().toIso8601String(),
  DateTime.now().toUtc().toIso8601String(),
  'com.astuto.app.plus.yearly',
  true,
  periodType: PeriodType.trial,
  expirationDate: DateTime.now()
      .subtract(const Duration(days: 40))
      .toUtc()
      .toIso8601String(),
);

/// The store, with nothing behind it but what a test says.
class _Store extends Subscription {
  _Store() : super(keyOverride: '');

  int buys = 0;

  @override
  Future<PurchaseOutcome> buy(Package package) async {
    buys += 1;
    return PurchaseOutcome.cancelled;
  }
}

int _docs = 0;

/// The server's word on the two first-run switches.
void _switch({bool reverse = true, bool firstRun = true}) => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'gift-${_docs++}',
      'app': {
        'flags': {'trial.reverse': reverse, 'trial.firstRun': firstRun},
      },
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

/// What the app said, kept.
class _Said implements AnalyticsSink {
  final List<(String, Map<String, Object>)> events = [];

  List<Map<String, Object>> of(String event) => [
    for (final e in events)
      if (e.$1 == event) e.$2,
  ];

  @override
  Future<void> capture(String event, Map<String, Object> properties) async =>
      events.add((event, properties));

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

Future<void> _loadRealFonts() async {
  const faces = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
  };
  for (final face in faces.entries) {
    final loader = FontLoader(face.key);
    final bytes = await File(face.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

Future<void> _settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A fresh install, through the intro, the mix and the genres, each walked
/// past: the onboarding's end.
Future<AppState> _throughTheOnboarding(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues({...prefs});
  await tester.pumpWidget(const AstutoApp());
  await _settle(tester);
  await tester.tap(find.text('Skip'));
  await _settle(tester);
  await tester.tap(find.text('Next'));
  await _settle(tester);
  await tester.tap(find.text('Skip'));
  await _settle(tester);
  return tester.widget<AstutoRoot>(find.byType(AstutoRoot)).app;
}

/// The one card, thrown on as a reader throws a card.
Future<void> _throwTheCard(WidgetTester tester) async {
  final Rect deck = tester.getRect(find.byType(PillCardStack));
  await tester.flingFrom(
    Offset(deck.center.dx, deck.top + 90),
    const Offset(-320, 0),
    900,
  );
  await _settle(tester, 14);
}

/// [day] at ten in the morning.
DateTime _at(DateTime day, {int hour = 10}) =>
    DateTime(day.year, day.month, day.day, hour);

/// The gift's first day in these tests, and the day [n] of it (the first
/// is 1, the fifteenth the free plan's first).
final DateTime _first = DateTime(2026, 11, 2);
DateTime _dayOf(int n) =>
    DateTime(_first.year, _first.month, _first.day + n - 1);

/// The reader on day [n] of a gift begun on [_first], past the first run,
/// with [prefs] besides: an app as the phone keeps it, opened then.
Future<AppState> _onDay(int n, {Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    'knowit.installedOn': dateKey(_first),
    'knowit.giftFrom': dateKey(_first),
    'knowit.giftGiven': true,
    ...prefs,
  });
  return _open(n);
}

/// The app opened on day [n], on what the phone already keeps.
Future<AppState> _open(int n) async {
  final DateTime now = _at(_dayOf(n));
  final AppState app = AppState(
    hasPermission: () async => true,
    askPermission: () async => true,
    arm: (_) async {},
    disarm: () async {},
    pushWidget: (_) async {},
    clock: () => now,
  );
  await app.init();
  return app;
}

void main() {
  late _Store store;
  final Subscription before = Subscription.instance;

  setUpAll(_loadRealFonts);

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(390, 844) * 3;
    view.devicePixelRatio = 3;
    Remote.reset();
    store = _Store();
    store.answerForTest(offering: _onSale());
    store.holdForTest(null);
    Subscription.useForTest(store);
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    Subscription.useForTest(before);
    Analytics.useForTest(null);
    Remote.reset();
  });

  group('the first run', () {
    testWidgets('with the switch off, it is as built: the trial\'s offer '
        'after the card, and no gift', (tester) async {
      _switch(reverse: false);
      expect(AppState.kReverseTrialFlag.fallback, isFalse);
      final AppState app = await _throughTheOnboarding(tester);
      expect(find.byType(FirstCardScreen), findsOneWidget);
      await _throwTheCard(tester);
      expect(find.byType(TrialOfferScreen), findsOneWidget);
      expect(find.byType(GiftScreen), findsNothing);
      expect(app.giftFrom, isNull);
      expect(app.isPlus, isFalse);
    });

    testWidgets('with it on: one card, then the gift where the offer stood — '
        'no price, no card, nothing to cancel — and the five, all the '
        'reader\'s own', (tester) async {
      final said = _Said();
      Analytics.useForTest(said);
      _switch();
      final AppState app = await _throughTheOnboarding(tester);
      expect(find.byType(FirstCardScreen), findsOneWidget);
      await _throwTheCard(tester);

      expect(find.byType(GiftScreen), findsOneWidget);
      expect(find.byType(TrialOfferScreen), findsNothing);
      expect(find.text(_en.giftTitle(14)), findsOneWidget);
      expect(find.text('Astute+ is yours for 14 days.'), findsOneWidget);
      expect(find.text('No card, nothing to cancel.'), findsOneWidget);
      // The days it goes by: today, and the fifteenth, the free plan again
      // with nothing charged. No price anywhere on it.
      expect(find.text(_en.trialStepToday), findsOneWidget);
      expect(find.text(_en.trialStepDay(15)), findsOneWidget);
      expect(find.text(_en.giftStepEndLine), findsOneWidget);
      expect(find.textContaining('€'), findsNothing);
      expect(find.text(_en.trialOfferFree), findsNothing);
      // Given as it went up: Astute+, and nothing bought.
      expect(app.giftFrom, dateKey(app.today));
      expect(app.onGift, isTrue);
      expect(app.isPlus, isTrue);
      expect(app.paidPlus, isFalse);
      expect(said.of('gift started').single, {
        'days': 14,
        'ends_on': dateKey(app.giftEndsOn!),
      });

      await tester.tap(find.text(_en.giftStart));
      await _settle(tester, 14);
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(app.onboarded, isTrue);
      // The first day dealt as Astute+ deals it: all five the reader's own.
      expect(app.ownIdsToday, hasLength(kPillsPerDay));
      expect(store.buys, 0);
    });

    testWidgets('with both switches on, the gift stands where the offer '
        'would', (tester) async {
      _switch(reverse: true, firstRun: true);
      await _throughTheOnboarding(tester);
      await _throwTheCard(tester);
      expect(find.byType(GiftScreen), findsOneWidget);
      expect(find.byType(TrialOfferScreen), findsNothing);
    });

    testWidgets('never to a reader the store ever held Astute+ for', (
      tester,
    ) async {
      _switch(firstRun: false);
      store.holdForTest(_once());
      final AppState app = await _throughTheOnboarding(tester);
      expect(find.byType(GiftScreen), findsNothing);
      expect(app.giftFrom, isNull);
    });
  });

  group('who', () {
    test('a new reader, once a phone, never on the web', () async {
      _switch();
      SharedPreferences.setMockInitialValues({});
      final AppState app = AppState(
        hasPermission: () async => false,
        askPermission: () async => false,
        arm: (_) async {},
        disarm: () async {},
        pushWidget: (_) async {},
      );
      await app.init();
      expect(giftDue(app, store: store, web: false), isTrue);
      expect(giftDue(app, store: store, web: true), isFalse);

      // A reader with a plan already has nothing to be given.
      await app.applyEntitlement(true);
      expect(giftDue(app, store: store, web: false), isFalse);
      await app.applyEntitlement(false);

      await app.startGift();
      expect(giftDue(app, store: store, web: false), isFalse);

      // Signed out and begun again, the phone remembers it gave one: the
      // gift went with the reader, and no second one comes.
      await app.signOut();
      expect(app.giftFrom, isNull);
      expect(app.isPlus, isFalse);
      expect(app.giftGiven, isTrue);
      expect(giftDue(app, store: store, web: false), isFalse);
    });

    test(
      'a reinstall keeps nothing on the phone, and the store\'s word is '
      'the only memory left: a reader it ever held Astute+ for gets none',
      () async {
        _switch();
        SharedPreferences.setMockInitialValues({});
        final AppState app = AppState(
          hasPermission: () async => false,
          askPermission: () async => false,
          arm: (_) async {},
          disarm: () async {},
          pushWidget: (_) async {},
        );
        await app.init();
        expect(giftDue(app, store: store, web: false), isTrue);
        store.holdForTest(_once());
        expect(store.everHeldPlus, isTrue);
        expect(giftDue(app, store: store, web: false), isFalse);
      },
    );

    test('off as built', () async {
      _switch(reverse: false);
      SharedPreferences.setMockInitialValues({});
      final AppState app = AppState(
        hasPermission: () async => false,
        askPermission: () async => false,
        arm: (_) async {},
        disarm: () async {},
        pushWidget: (_) async {},
      );
      await app.init();
      expect(giftDue(app, store: store, web: false), isFalse);
      Remote.reset();
      expect(giftDue(app, store: store, web: false), isFalse);
    });
  });

  group('its fourteen days', () {
    test('Astute+ from the first to the fourteenth, the free plan on the '
        'fifteenth', () async {
      for (final int n in [1, 7, 13, 14]) {
        final AppState app = await _onDay(n);
        expect(app.onGift, isTrue, reason: 'day $n');
        expect(app.isPlus, isTrue, reason: 'day $n');
        expect(app.paidPlus, isFalse, reason: 'day $n');
        expect(app.ownCardsToday, kPillsPerDay, reason: 'day $n');
      }
      final AppState fifteenth = await _onDay(15);
      expect(fifteenth.onGift, isFalse);
      expect(fifteenth.isPlus, isFalse);
      expect(fifteenth.ownCardsToday, lessThan(kPillsPerDay));
      expect(fifteenth.ownIdsToday.length, lessThan(kPillsPerDay));
      expect(fifteenth.giftEndsOn, _dayOf(15));
      expect(fifteenth.giftLastDay, _dayOf(14));
    });

    test(
      'the fourteenth deals the morning after it as the free plan will',
      () async {
        final AppState app = await _onDay(14);
        expect(app.plusOn(_dayOf(14)), isTrue);
        expect(app.plusOn(_dayOf(15)), isFalse);
        expect(app.ownCardsOn(_dayOf(15)), lessThan(kPillsPerDay));
        expect(app.randomTomorrow, greaterThan(0));
      },
    );

    test(
      'one quiet line in its last two days, and none before or after',
      () async {
        expect((await _onDay(12)).giftDaysLeft, isNull);
        expect((await _onDay(13)).giftDaysLeft, 2);
        expect((await _onDay(14)).giftDaysLeft, 1);
        expect((await _onDay(15)).giftDaysLeft, isNull);
        expect(_en.giftEndsSoon(2), 'Astute+ is yours for 2 more days.');
        expect(_en.giftEndsSoon(1), 'Last day of Astute+.');
      },
    );

    test('the thirteenth\'s nudge says it, to a reader with the nudge on, '
        'and is the gift\'s one notification', () async {
      final AppState app = await _onDay(11);
      String? titleOn(List<Reminder> plan, int n) {
        for (final Reminder r in plan) {
          if (dateKey(r.when) == dateKey(_dayOf(n))) return r.title;
        }
        return null;
      }

      final List<Reminder> plan = app.reminderPlan(now: _at(_dayOf(11)));
      expect(titleOn(plan, 13), _en.giftEndsSoon(2));
      final int notes = plan
          .where((r) => r.title == _en.giftEndsSoon(2))
          .length;
      expect(notes, 1);
      expect(titleOn(plan, 12), isNot(_en.giftEndsSoon(2)));
      expect(titleOn(plan, 14), isNot(_en.giftEndsSoon(2)));

      // The nudge off: nothing at all, the gift's note included.
      await app.setNotifications(false);
      expect(
        app
            .reminderPlan(now: _at(_dayOf(11)))
            .where((r) => r.title == _en.giftEndsSoon(2)),
        isEmpty,
      );
    });

    test('a gift given is not taken back by the switch', () async {
      _switch(reverse: true);
      final AppState app = await _onDay(5);
      _switch(reverse: false);
      expect(app.onGift, isTrue);
      expect(app.isPlus, isTrue);
    });
  });

  group('bought in its days', () {
    test(
      'the plan is the reader\'s, and nothing of the gift is said again',
      () async {
        final AppState app = await _onDay(10);
        await app.applyEntitlement(true);
        expect(app.paidPlus, isTrue);
        expect(app.isPlus, isTrue);

        final AppState thirteenth = await _open(13);
        expect(thirteenth.paidPlus, isTrue);
        expect(thirteenth.giftDaysLeft, isNull);
        expect(
          thirteenth
              .reminderPlan(now: _at(_dayOf(13), hour: 6))
              .where((r) => r.title == _en.giftEndsSoon(2)),
          isEmpty,
        );

        final AppState fifteenth = await _open(15);
        expect(fifteenth.isPlus, isTrue);
        expect(giftEndDue(fifteenth, store: store), isFalse);
      },
    );

    testWidgets('the paywall sells to a reader in their gift', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final AppState app = await _onDay(6);
      expect(app.isPlus, isTrue);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          home: PaywallScreen(app: app, source: 'gift'),
        ),
      );
      await _settle(tester);
      expect(find.text(_en.plusIsActive), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('paywall-buy')),
          matching: find.textContaining('€29.99'),
        ),
        findsOneWidget,
      );
    });
  });

  group('held to its first day on every phone', () {
    test('the backup carries it, and a merge keeps the earlier', () {
      const ReaderSnapshot here = ReaderSnapshot(giftFrom: '2026-11-20');
      const ReaderSnapshot account = ReaderSnapshot(giftFrom: '2026-11-02');
      expect(mergeSnapshots(here, account).giftFrom, '2026-11-02');
      expect(mergeSnapshots(account, here).giftFrom, '2026-11-02');
      expect(
        mergeSnapshots(const ReaderSnapshot(), account).giftFrom,
        '2026-11-02',
      );
      final ReaderSnapshot back = ReaderSnapshot.fromJson(
        account.toJson().cast<String, dynamic>(),
      );
      expect(back.giftFrom, '2026-11-02');
      expect(ReaderSnapshot.fromJson({'giftFrom': 'soon'}).giftFrom, isNull);
      expect(const ReaderSnapshot().toJson().containsKey('giftFrom'), isFalse);
    });

    test('signing in on a new phone keeps the first phone\'s days: a gift '
        'over there is over here', () async {
      // A second phone that gave its own gift today, the reader's account
      // holding one begun three weeks ago.
      final AppState phone = await _onDay(
        22,
        prefs: {'knowit.giftFrom': dateKey(_dayOf(22))},
      );
      expect(phone.onGift, isTrue);
      await phone.adopt(
        mergeSnapshots(
          phone.snapshot(),
          ReaderSnapshot(giftFrom: dateKey(_first)),
        ),
      );
      expect(phone.giftFrom, dateKey(_first));
      expect(phone.onGift, isFalse);
      expect(phone.isPlus, isFalse);
      expect(phone.giftGiven, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('knowit.giftFrom'), dateKey(_first));
    });
  });

  group('the morning after it', () {
    test('due once, before the five, within two weeks of the end', () async {
      final AppState thirteenth = await _onDay(13);
      expect(giftEndDue(thirteenth, store: store), isFalse);
      final AppState fifteenth = await _onDay(15);
      expect(giftEndDue(fifteenth, store: store), isTrue);
      await fifteenth.notedGiftEnd();
      expect(giftEndDue(fifteenth, store: store), isFalse);
      // Not once the five are begun: the next morning, then.
      final AppState reading = await _onDay(16, prefs: {});
      reading.todayIndex = 2;
      expect(giftEndDue(reading, store: store), isFalse);
      reading.todayIndex = 0;
      expect(giftEndDue(reading, store: store), isTrue);
      // A reader back a month later is not told.
      expect(giftEndDue(await _onDay(29), store: store), isFalse);
      expect(giftEndDue(await _onDay(28), store: store), isTrue);
    });

    test(
      'its numbers are the reader\'s own, from what the app keeps',
      () async {
        final List<Pill> cards = PillBank.cards
            .where((p) => p.isGraded)
            .take(90)
            .toList();
        // 62 cards first read over twelve of its days, and one the day after
        // it, which is not the gift's.
        final Map<String, List<String>> readDays = {};
        for (int i = 0; i < 62; i++) {
          readDays
              .putIfAbsent(dateKey(_dayOf(1 + i % 12)), () => [])
              .add(cards[i].id);
        }
        readDays[dateKey(_dayOf(15))] = [cards[80].id];
        // How sure: twelve answers on the third day at 90%, half of them
        // right, which is the first measure; twelve on the tenth at 70%, nine
        // of them right, which brings it down. A card missed on the third
        // and got right on the tenth came back.
        final List<Map<String, Object?>> said = [
          for (int i = 0; i < 12; i++)
            {'c': 90, 'k': i < 6, 'p': cards[i].id, 'd': dateKey(_dayOf(3))},
          for (int i = 0; i < 12; i++)
            {
              'c': 70,
              'k': i < 9,
              'p': cards[20 + i].id,
              'd': dateKey(_dayOf(10)),
            },
          {'c': null, 'k': true, 'p': cards[6].id, 'd': dateKey(_dayOf(10))},
        ];
        final AppState app = await _onDay(
          15,
          prefs: {
            'knowit.readDays': jsonEncode(readDays),
            'knowit.completedDates': [
              for (int n = 1; n <= 12; n++) dateKey(_dayOf(n)),
            ],
            'knowit.judgements': jsonEncode(said),
          },
        );
        final GiftNumbers n = GiftNumbers.of(app);
        expect(n.cards, 62);
        expect(n.days, 12);
        expect(n.of, 14);
        expect(n.gapWas, app.confidenceGapOn(dateKey(_dayOf(3))));
        expect(n.gap, app.confidenceGapOn(dateKey(_dayOf(14))));
        expect(n.gapWas, isNotNull);
        expect(n.gapMoved, isTrue);
        expect(n.gap!, lessThan(n.gapWas!));
        // Counted by the move, as backRightIn counts it below.
        expect(
          n.backRight,
          GiftNumbers.backRightIn(app.judgements, {
            for (int d = 1; d <= 14; d++) dateKey(_dayOf(d)),
          }),
        );
        expect(n.backRight, greaterThan(0));
        // The free plan's five today: two of the reader's own.
        expect(n.random, kPillsPerDay - app.ownCardsToday);
        expect(n.random, greaterThan(0));
        // A miss got right only on a later day counts.
        expect(
          GiftNumbers.backRightIn(
            [
              Judgement(
                80,
                correct: false,
                pillId: cards[0].id,
                on: '2026-11-05',
              ),
              Judgement(
                80,
                correct: true,
                pillId: cards[0].id,
                on: '2026-11-05',
              ),
            ],
            {'2026-11-05'},
          ),
          0,
        );
      },
    );

    test('a move missed and got right when it came back counts once, '
        'whichever card of it came back', () {
      final List<Pill> move = PillBank.cards
          .where((p) => p.principle == Principle.baseRate)
          .take(3)
          .toList();
      // A card the bank knows no move of (here, one it does not know at
      // all) is counted as itself.
      const String fact = 'a-card-of-no-move';
      expect(PillBank.byId(fact), isNull);
      expect(move, hasLength(3));
      expect(
        GiftNumbers.backRightIn(
          [
            // Missed in one card of the move, got right in another, and in a
            // third: one move.
            Judgement(80, correct: false, pillId: move[0].id, on: '2026-11-03'),
            Judgement(70, correct: true, pillId: move[1].id, on: '2026-11-05'),
            Judgement(90, correct: true, pillId: move[2].id, on: '2026-11-08'),
            // A card that trains no move counts by itself.
            Judgement(60, correct: false, pillId: fact, on: '2026-11-03'),
            Judgement(60, correct: true, pillId: fact, on: '2026-11-08'),
            // Outside the gift's days: nothing.
            Judgement(60, correct: false, pillId: fact, on: '2026-12-01'),
          ],
          {'2026-11-03', '2026-11-05', '2026-11-08'},
        ),
        2,
      );
    });

    testWidgets('rises over Today before the five, once, and "Keep Astute+" '
        'is the paywall in its place', (tester) async {
      final said = _Said();
      Analytics.useForTest(said);
      final DateTime now = DateTime.now();
      final DateTime start = DateTime(now.year, now.month, now.day - 14);
      // Eleven days read, the last of them yesterday, the gift's last.
      final List<String> read = [
        for (int i = 3; i < 14; i++)
          dateKey(DateTime(start.year, start.month, start.day + i)),
      ];
      SharedPreferences.setMockInitialValues({
        'knowit.onboarded': true,
        'knowit.installedOn': dateKey(start),
        'knowit.giftFrom': dateKey(start),
        'knowit.giftGiven': true,
        'knowit.completedDates': read,
        'knowit.lastCompletionDate': read.last,
        'knowit.streak': read.length,
        'knowit.bestStreak': read.length,
        'knowit.pushAsked': true,
        'knowit.accountOffered': true,
        'knowit.widgetAsked': true,
        'knowit.reviewAsked': true,
        'knowit.placeAsks': 9,
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester, 30);

      expect(find.byType(GiftEndScreen), findsOneWidget);
      expect(find.text(_en.giftEndTitle(14)), findsOneWidget);
      expect(find.text('11/14'), findsOneWidget);
      expect(find.text(_en.giftLossMisses), findsOneWidget);
      expect(said.of('gift end shown'), hasLength(1));
      final AppState app = tester
          .widget<AstutoRoot>(find.byType(AstutoRoot, skipOffstage: false))
          .app;
      expect(app.giftEndShownOn, dateKey(app.today));

      await tester.tap(find.byKey(const ValueKey('gift-end-keep')));
      await _settle(tester, 14);
      expect(find.byType(GiftEndScreen), findsNothing);
      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(said.of('paywall shown').last['source'], 'gift end');
      expect(said.of('gift end closed').single['left_by'], 'keep');

      // Back from the paywall: the five, and the page never again.
      Navigator.of(tester.element(find.byType(PaywallScreen))).pop();
      await _settle(tester, 14);
      expect(find.byType(TodayScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester, 30);
      expect(find.byType(GiftEndScreen), findsNothing);
    });
  });

  group('the profile', () {
    testWidgets('says the gift and until when, and opens the paywall, not the '
        'store\'s screen', (tester) async {
      final DateTime now = DateTime.now();
      final DateTime start = DateTime(now.year, now.month, now.day - 3);
      SharedPreferences.setMockInitialValues({
        'knowit.onboarded': true,
        'knowit.giftFrom': dateKey(start),
        'knowit.giftGiven': true,
        'knowit.pushAsked': true,
        'knowit.accountOffered': true,
        'knowit.widgetAsked': true,
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester, 20);
      await tester.tap(find.byKey(const ValueKey('tab-Profile')));
      await _settle(tester);
      final Finder row = find.byKey(const ValueKey('profile-plan'));
      await tester.scrollUntilVisible(
        row,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ProfileScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await _settle(tester);
      expect(
        find.descendant(
          of: row,
          matching: find.textContaining('Astute+ · a gift until'),
        ),
        findsOneWidget,
      );
      await tester.tap(row);
      await _settle(tester);
      expect(find.byType(PaywallScreen), findsOneWidget);
    });
  });
}
