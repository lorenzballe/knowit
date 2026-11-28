// The first week's page, and the first month's (lib/state/first_offers.dart,
// lib/screens/first_offer.dart), behind the server's switches
// `offer.firstWeek` and `offer.firstMonth`, off as built.
//
// When: the seventh day the five are finished, not in a row, up to the
// tenth; a month after the install, with a week of reading; on the free
// plan, to a reader the store never held Astute+ for and will still give
// the free days to; once each; one full-screen moment a day, the level
// winning; never on the evening of the reminder sheet or the rating
// prompt; right after the five, never during them. What: the reader's own
// numbers. And "Not now" closes it for good.
//
//   flutter test test/first_offer_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/daily.dart' show dealDay;
import 'package:astuto/data/levels.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/screens/purchase_success_screen.dart';
import 'package:astuto/screens/today_done_view.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/first_offers.dart';
import 'package:astuto/sync/subscription.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/level_up.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

import 'explore/core_harness.dart' show loadFonts, readyApp;

final AppLocalizations _en = lookupAppLocalizations(const Locale('en'));

/// The plans as the owner sets them: a year at €29.99 with two weeks free,
/// a month at €3.99.
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
  final month = Package(
    r'$rc_monthly',
    PackageType.monthly,
    const StoreProduct(
      'com.astuto.app.plus.monthly',
      'Astute+',
      'Astute+',
      3.99,
      '€3.99',
      'EUR',
    ),
    context,
  );
  return Offering(
    'default',
    '',
    const {},
    [year, month],
    annual: year,
    monthly: month,
  );
}

/// Astute+ as RevenueCat describes it: the year's trial, running, or over
/// and never paid for.
EntitlementInfo _trial({bool running = true}) => EntitlementInfo(
  kPlusEntitlement,
  running,
  running,
  DateTime.now().toUtc().toIso8601String(),
  DateTime.now().toUtc().toIso8601String(),
  'com.astuto.app.plus.yearly',
  true,
  periodType: PeriodType.trial,
  expirationDate: DateTime.now()
      .add(Duration(days: running ? 14 : -20))
      .toUtc()
      .toIso8601String(),
);

/// The store, with nothing behind it but what a test says: a purchase
/// starts the trial, as the store's sheet would.
class _Store extends Subscription {
  _Store() : super(keyOverride: '');

  int buys = 0;

  @override
  Future<PurchaseOutcome> buy(Package package) async {
    buys += 1;
    holdForTest(_trial());
    return PurchaseOutcome.bought;
  }
}

/// A store that has answered: the plans on sale, and nothing held for this
/// reader, ever.
_Store _answered({IntroEligibilityStatus? eligibility}) => _Store()
  ..answerForTest(offering: _onSale(), yearlyEligibility: eligibility)
  ..holdForTest(null);

int _docs = 0;

/// The server's word on the two switches.
void _switch({bool week = true, bool month = true}) => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'first-offer-${_docs++}',
      'app': {
        'flags': {'offer.firstWeek': week, 'offer.firstMonth': month},
      },
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

/// The date key [back] days before today, on the calendar.
String _day(int back) {
  final DateTime now = DateTime.now();
  return dateKey(DateTime(now.year, now.month, now.day - back));
}

/// Today's five, as the day deals them.
List<String> _deck() =>
    dealDay(date: DateTime.now()).cards
        .take(kPillsPerDay)
        .map((p) => p.id)
        .toList();

/// A reader on the free plan, nothing else asked of them tonight: [read]
/// days with the five finished, every [gap] days, the last of them today
/// (with [left] cards of today's five still to read, yesterday); installed
/// [installed] days ago.
Map<String, Object> _reader({
  int read = 7,
  int gap = 1,
  int left = 0,
  int installed = 9,
  Map<String, Object> more = const {},
}) {
  final List<String> deck = _deck();
  final bool done = left == 0;
  // The days finished, oldest first: today's last when it is done, and
  // otherwise those before it, today to be the [read]th.
  final List<String> days = [
    for (int i = read - 1; i >= (done ? 0 : 1); i--) _day(i * gap),
  ];
  return {
    'knowit.onboarded': true,
    'knowit.pushAsked': true,
    'knowit.widgetAsked': true,
    'knowit.accountOffered': true,
    'knowit.reviewAsked': true,
    'knowit.goalAsked': true,
    'knowit.placeAsks': 9,
    'knowit.installedOn': _day(installed),
    'knowit.todayDate': _day(0),
    'knowit.todayDeckIds': deck,
    'knowit.todayIndex': deck.length - left,
    'knowit.streak': gap == 1 ? days.length : 1,
    'knowit.bestStreak': gap == 1 ? days.length : 1,
    'knowit.lastCompletionDate': days.last,
    'knowit.completedDates': days,
    // Five a day: today's read so far, and five for each day before.
    'knowit.seenIds': [
      ...deck.take(deck.length - left),
      ...PillBank.cards
          .where((p) => !deck.contains(p.id))
          .skip(40)
          .take(5 * (read - 1))
          .map((p) => p.id),
    ],
    ...more,
  };
}

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

Future<void> _settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Throws the card on top of the deck, from the question at its top.
Future<void> _throwTop(WidgetTester tester) async {
  final Rect deck = tester.getRect(find.byType(PillCardStack));
  await tester.flingFrom(
    Offset(deck.center.dx, deck.top + 90),
    const Offset(-320, 0),
    900,
  );
  await _settle(tester);
}

/// Reads the rest of the day: what is left of the five, and on the free
/// plan the card after them that offers the rest, thrown like the rest.
Future<void> _finishDay(WidgetTester tester) async {
  for (var i = 0; i < 7; i++) {
    if (find.byType(PillCardStack).evaluate().isEmpty) break;
    await _throwTop(tester);
  }
}

final Finder _page = find.byKey(const ValueKey('first-offer'));

/// Graded cards of the bank in [topic], [n] of them.
List<Pill> _graded(String topic, int n) => PillBank.cards
    .where((p) => p.isGraded && p.topic == topic)
    .take(n)
    .toList();

/// Judgements as kept: on each of [cards], right as [right] says, said
/// [sure] sure when given, today.
List<Map<String, Object?>> _said(
  List<Pill> cards,
  List<bool> right, {
  int? sure,
}) => [
  for (var i = 0; i < cards.length; i++)
    {'c': sure, 'k': right[i], 'p': cards[i].id, 'd': _day(0)},
];

/// [child] in the app's own theme and language, on a phone of [size].
Widget _host(Widget child, {String language = 'en', bool dark = true}) =>
    MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(dark ? Brightness.dark : Brightness.light),
      debugShowCheckedModeBanner: false,
      home: child,
    );

void main() {
  setUpAll(loadFonts);

  final Subscription before = Subscription.instance;
  late _Store store;
  late _Said said;

  setUp(() {
    Remote.reset();
    Remote.fetch = (url) async => null;
    store = _answered();
    Subscription.useForTest(store);
    said = _Said();
    Analytics.useForTest(said);
  });

  tearDown(() {
    Subscription.useForTest(before);
    Remote.reset();
    Analytics.useForTest(null);
  });

  group('when', () {
    test('the seventh day the five are finished, counted in days and not in '
        'a row, up to the tenth; never on the sixth, never after', () async {
      _switch();
      for (final (int read, int gap, FirstOffer? due) in [
        (6, 1, null),
        (7, 1, FirstOffer.week),
        // A week read with a day missed between each is still a week.
        (7, 2, FirstOffer.week),
        (10, 1, FirstOffer.week),
        (11, 1, null),
      ]) {
        final AppState app = await readyApp(
          _reader(read: read, gap: gap, installed: read * gap + 1),
        );
        expect(
          firstOfferDue(app, store: store),
          due,
          reason: '$read days, one every $gap',
        );
      }
      // A day counted twice is one day.
      final AppState twice = await readyApp(
        _reader(
          read: 6,
          more: {
            'knowit.completedDates': [
              for (int i = 5; i >= 0; i--) _day(i),
              _day(0),
            ],
          },
        ),
      );
      expect(twice.completedDates, hasLength(7));
      expect(firstOfferDue(twice, store: store), isNull);
    });

    test('the month: thirty days after the install to forty-four, with a '
        'week of reading, two weeks after the week\'s page at least', () async {
      _switch();
      Future<FirstOffer?> at({
        required int installed,
        int read = 12,
        String? week,
      }) async => firstOfferDue(
        await readyApp(
          _reader(
            read: read,
            gap: 2,
            installed: installed,
            more: {'knowit.firstWeekOfferedOn': ?week},
          ),
        ),
        store: store,
      );
      expect(await at(installed: 29), isNull, reason: 'not yet a month');
      expect(await at(installed: 30), FirstOffer.month);
      expect(await at(installed: 44), FirstOffer.month);
      expect(await at(installed: 45), isNull, reason: 'past its days');
      expect(await at(installed: 33, read: 6), isNull, reason: 'six days read');
      // The week's page past the first month is the month's, never late.
      expect(await at(installed: 33, read: 7), FirstOffer.month);
      expect(await at(installed: 33, week: _day(10)), isNull);
      expect(await at(installed: 33, week: _day(14)), FirstOffer.month);
    });

    test('only on the free plan, to a reader the store never held Astute+ '
        'for, and only with the store\'s year and its free days for this '
        'reader', () async {
      _switch();
      final Map<String, Object> week = _reader();
      expect(
        firstOfferDue(await readyApp(week), store: store),
        FirstOffer.week,
      );
      // Astute+, on the phone or in the store.
      expect(
        firstOfferDue(
          await readyApp({...week, 'knowit.plus': true}),
          store: store,
        ),
        isNull,
      );
      final AppState app = await readyApp(week);
      expect(
        firstOfferDue(app, store: _answered()..holdForTest(_trial())),
        isNull,
      );
      // A trial that ran out, never paid for: never trialed is never.
      expect(
        firstOfferDue(
          app,
          store: _answered()..holdForTest(_trial(running: false)),
        ),
        isNull,
      );
      // The store says the reader has had the free days: no page at all.
      expect(
        firstOfferDue(
          app,
          store: _answered(
            eligibility:
                IntroEligibilityStatus.introEligibilityStatusIneligible,
          ),
        ),
        isNull,
      );
      // Nothing on sale, or the store not heard from yet.
      expect(firstOfferDue(app, store: _Store()..holdForTest(null)), isNull);
      expect(
        firstOfferDue(app, store: _Store()..answerForTest(offering: _onSale())),
        isNull,
      );
      // Eligible, said or not yet known: the store's own offer.
      expect(
        firstOfferDue(
          app,
          store: _answered(
            eligibility: IntroEligibilityStatus.introEligibilityStatusEligible,
          ),
        ),
        FirstOffer.week,
      );
    });

    test('once: a page put on an earlier day is never put again', () async {
      _switch();
      expect(
        firstOfferDue(
          await readyApp(
            _reader(read: 8, more: {'knowit.firstWeekOfferedOn': _day(1)}),
          ),
          store: store,
        ),
        isNull,
      );
      expect(
        firstOfferDue(
          await readyApp(
            _reader(
              read: 12,
              gap: 3,
              installed: 40,
              more: {'knowit.firstMonthOfferedOn': _day(3)},
            ),
          ),
          store: store,
        ),
        isNull,
      );
    });

    test('one full-screen moment a day: not on the day the first run '
        'offered the trial, a level rose, or a page already rose', () async {
      _switch();
      final AppState app = await readyApp(_reader());
      expect(firstOfferDue(app, store: store), FirstOffer.week);
      expect(firstOfferDue(app, store: store, levelRoseToday: true), isNull);
      for (final String key in [
        'knowit.trialOfferedOn',
        'knowit.firstMonthOfferedOn',
      ]) {
        expect(
          firstOfferDue(
            await readyApp(_reader(more: {key: _day(0)})),
            store: store,
          ),
          isNull,
          reason: key,
        );
      }
    });

    test('one question an evening: not when the reminder sheet is due, nor '
        'on the evening of the store\'s rating prompt', () async {
      _switch();
      for (final (String why, Map<String, Object> more) in [
        ('the reminder sheet is due', {'knowit.pushAsked': false}),
        (
          'the rating prompt was put tonight',
          {'knowit.reviewAskedOn': _day(0), 'knowit.reviewAsks': 1},
        ),
        // A week in a row, never rated: the rating prompt's evening.
        ('the rating prompt is due', {'knowit.reviewAsked': false}),
      ]) {
        final AppState app = await readyApp(_reader(more: more));
        expect(firstOfferDue(app, store: store), isNull, reason: why);
      }
    });

    test('never during the five: only once today\'s are finished', () async {
      _switch();
      final AppState reading = await readyApp(_reader(left: 2));
      expect(reading.dayClosed, isFalse);
      expect(firstOfferDue(reading, store: store), isNull);
    });

    test('the switches: off as built, each page only where the server has '
        'it on', () async {
      final AppState week = await readyApp(_reader());
      final AppState month = await readyApp(
        _reader(read: 12, gap: 2, installed: 31),
      );
      expect(AppState.kFirstWeekOfferFlag.fallback, isFalse);
      expect(AppState.kFirstMonthOfferFlag.fallback, isFalse);
      expect(firstOfferDue(week, store: store), isNull);
      expect(firstOfferDue(month, store: store), isNull);
      _switch(week: true, month: false);
      expect(firstOfferDue(week, store: store), FirstOffer.week);
      expect(firstOfferDue(month, store: store), isNull);
      _switch(week: false, month: true);
      expect(firstOfferDue(week, store: store), isNull);
      expect(firstOfferDue(month, store: store), FirstOffer.month);
    });

    test('the evening a page rises asks nothing more: the account\'s, the '
        'place\'s and the widget\'s sheets wait for another', () async {
      final Map<String, Object> asks = {
        'knowit.widgetAsked': false,
        'knowit.accountOffered': false,
        'knowit.placeAsks': 0,
      };
      final AppState other = await readyApp(
        _reader(more: {...asks, 'knowit.firstWeekOfferedOn': _day(1)}),
      );
      expect(other.shouldAskForWidget, isTrue);
      expect(other.shouldOfferAccount, isTrue);
      expect(other.shouldAskForPlace, isTrue);
      final AppState tonight = await readyApp(
        _reader(more: {...asks, 'knowit.firstWeekOfferedOn': _day(0)}),
      );
      expect(tonight.firstOfferRoseToday, isTrue);
      expect(tonight.shouldAskForWidget, isFalse);
      expect(tonight.shouldOfferAccount, isFalse);
      expect(tonight.shouldAskForPlace, isFalse);
    });

    test('kept for the phone through a sign-out', () async {
      final AppState app = await readyApp(_reader());
      await app.notedFirstWeekOffered();
      await app.signOut();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('knowit.firstWeekOfferedOn'), _day(0));
      expect(prefs.getBool('knowit.onboarded'), isNull);
    });
  });

  group('the evening', () {
    setUp(() {
      final view =
          TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(390, 844);
      view.devicePixelRatio = 1;
    });

    tearDown(() {
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset();
    });

    testWidgets('the seventh day: right after the five and the offer after '
        'them, the page rises once, with the reader\'s numbers; "Not now" '
        'closes it for good', (tester) async {
      _switch();
      SharedPreferences.setMockInitialValues(_reader(left: 1));
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      expect(_page, findsNothing);
      // The fifth thrown: the offer after it is on the table, and nothing
      // rises over it.
      await _throwTop(tester);
      await _settle(tester, 20);
      expect(find.byKey(const ValueKey('magic-card')), findsOneWidget);
      expect(_page, findsNothing);
      await _finishDay(tester);
      await _settle(tester, 25);

      expect(_page, findsOneWidget);
      expect(find.text(_en.firstWeekTitle), findsOneWidget);
      expect(find.text('7 DAYS OF READING'), findsOneWidget);
      expect(find.text('35'), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('€29.99'), findsOneWidget);
      expect(find.text(_en.firstOfferTrialTitle(14)), findsOneWidget);
      // The price on the button itself, as the paywall's says it.
      expect(
        find.text(_en.tryFreeThen(14, '€29.99', _en.perYearShort)),
        findsOneWidget,
      );
      expect(find.text(_en.firstOfferNotNow), findsOneWidget);
      final AppState app = tester
          .widget<AstutoRoot>(find.byType(AstutoRoot, skipOffstage: false))
          .app;
      expect(app.firstWeekOfferedOn, dateKey(app.today));
      final Map<String, Object> shown = said.of('first offer shown').single;
      expect(shown['source'], 'first week');
      expect(shown['days_read'], 7);
      expect(shown['cards_read'], 35);
      expect(shown['trial_days'], 14);

      await tester.tap(find.byKey(const ValueKey('first-offer-not-now')));
      await _settle(tester);
      expect(_page, findsNothing);
      expect(find.byType(TodayDoneView), findsOneWidget);
      expect(said.of('first offer closed').single, {
        'source': 'first week',
        'left_by': 'not now',
        'ms_open': isA<int>(),
        'is_plus': false,
      });
      expect(store.buys, 0);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('knowit.firstWeekOfferedOn'), dateKey(app.today));
      // For good: the next evening in the week's days says nothing.
      expect(firstOfferDue(app, store: store), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('on Astute+, and while the five are read, nothing rises', (
      tester,
    ) async {
      _switch();
      SharedPreferences.setMockInitialValues(
        // The week's own moment (lib/widgets/streak_moment.dart) told
        // already: what is watched here is the first week's page alone.
        _reader(
          left: 2,
          more: {
            'knowit.plus': true,
            'knowit.streakTold': ['7'],
          },
        ),
      );
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _throwTop(tester);
      await _settle(tester, 20);
      expect(_page, findsNothing, reason: 'during the five');
      await _finishDay(tester);
      await _settle(tester, 25);
      expect(find.byType(TodayDoneView), findsOneWidget);
      expect(_page, findsNothing, reason: 'on Astute+');
      expect(said.of('first offer shown'), isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a level reached the same evening wins it: the level rises, '
        'the page waits for another day', (tester) async {
      _switch();
      // Twelve right today: past the first level, nothing told yet.
      SharedPreferences.setMockInitialValues(
        _reader(
          left: 1,
          more: {
            'knowit.judgements': jsonEncode(
              _said(
                PillBank.cards
                    .where(
                      (p) => p.isGraded && p.difficulty == Difficulty.medium,
                    )
                    .take(12)
                    .toList(),
                List.filled(12, true),
              ),
            ),
          },
        ),
      );
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _finishDay(tester);
      await _settle(tester, 25);
      expect(find.byKey(const ValueKey('level-up')), findsOneWidget);
      expect(_page, findsNothing);
      expect(await LevelMemory.roseOn(), _day(0));
      final AppState app = tester
          .widget<AstutoRoot>(find.byType(AstutoRoot, skipOffstage: false))
          .app;
      expect(app.firstWeekOfferedOn, isNull);
      // Not today; due again on the next day finished.
      expect(firstOfferDue(app, store: store, levelRoseToday: true), isNull);
      expect(firstOfferDue(app, store: store), FirstOffer.week);
      await tester.pump(LevelUpScreen.take);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('and a level waits on the day a page rose', (tester) async {
      final AppState app = await readyApp(
        _reader(
          more: {
            'knowit.plus': true,
            'knowit.judgements': jsonEncode(
              _said(
                PillBank.cards
                    .where(
                      (p) => p.isGraded && p.difficulty == Difficulty.medium,
                    )
                    .take(12)
                    .toList(),
                List.filled(12, true),
              ),
            ),
            'knowit.firstWeekOfferedOn': _day(0),
          },
        ),
      );
      late BuildContext context;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (c) {
              context = c;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      expect(await showLevelUpIfDue(context, app), isFalse);
      expect(await LevelMemory.roseOn(), isNull);
      app.firstWeekOfferedOn = _day(1);
      final Future<bool> rose = showLevelUpIfDue(context, app);
      await tester.pump();
      expect(await rose, isTrue);
      await tester.pump(LevelUpScreen.take);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the page', () {
    setUp(() {
      final view =
          TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(390, 844);
      view.devicePixelRatio = 1;
    });

    tearDown(() {
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset();
    });

    /// A reader with numbers to say: seven days, 35 cards, sure ten times
    /// and right on eight, History five of six, a card said to somebody.
    Future<(AppState, Pill)> numbered() async {
      final List<Pill> history = _graded('History', 6);
      final List<Pill> space = _graded('Space', 10);
      final Pill told = PillBank.cards.firstWhere(
        (p) => p.question.isNotEmpty && !space.contains(p),
      );
      final AppState app = await readyApp(
        _reader(
          more: {
            'knowit.judgements': jsonEncode([
              ..._said(history, [true, true, false, true, true, true]),
              ..._said(space, [
                true, true, true, false, true, //
                true, false, true, true, true,
              ], sure: 90),
            ]),
            'knowit.saidIds': [told.id],
          },
        ),
      );
      return (app, told);
    }

    testWidgets('says the reader\'s own numbers: cards read, right when '
        'sure, the strongest subject, the days in a row, the best card', (
      tester,
    ) async {
      final (AppState app, Pill told) = await numbered();
      final FirstOfferNumbers n = FirstOfferNumbers.of(app, FirstOffer.week);
      expect(n.days, 7);
      expect(n.cards, 35);
      expect(n.streak, 7);
      expect((n.sure!.right, n.sure!.of), (8, 10));
      expect(n.strongest!.key, 'history');
      expect((n.strongest!.tally.right, n.strongest!.tally.of), (5, 6));
      expect(n.best, told);
      expect(n.bestWhy, BestCardWhy.said);

      await tester.pumpWidget(
        _host(FirstOfferScreen(app: app, which: FirstOffer.week)),
      );
      await _settle(tester);
      expect(find.text('7 DAYS OF READING'), findsOneWidget);
      expect(find.text('Your first week'), findsOneWidget);
      expect(find.text('35'), findsOneWidget);
      expect(find.text('CARDS READ'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('RIGHT WHEN SURE'), findsOneWidget);
      expect(find.text('8 of 10 right'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('STRONGEST'), findsOneWidget);
      expect(find.text('5 of 6 right'), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('IN A ROW'), findsOneWidget);
      expect(find.text('THE WEEK\'S BEST CARD'), findsOneWidget);
      expect(find.text(told.question), findsOneWidget);
      expect(find.text('You told someone about it.'), findsOneWidget);
      // The trial as its days, at the store's price.
      expect(find.text('Astute+, free for 14 days'), findsOneWidget);
      expect(find.text(_en.trialStepToday), findsOneWidget);
      expect(find.text(_en.trialStepDay(14)), findsOneWidget);
      expect(find.text('€29.99'), findsOneWidget);
      // Shown to the numbers, said in counts and kinds only.
      expect(said.of('first offer shown').single, {
        'source': 'first week',
        'days_read': 7,
        'cards_read': 35,
        'streak_days': 7,
        'has_sure': true,
        'has_strongest': true,
        'best_card': 'said',
        'trial_days': 14,
        'remind': isA<bool>(),
      });
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('what it cannot say yet it leaves out: no sure answers, no '
        'subject with enough, no card done more with than read', (
      tester,
    ) async {
      final AppState app = await readyApp(_reader(read: 12, installed: 31));
      await tester.pumpWidget(
        _host(FirstOfferScreen(app: app, which: FirstOffer.month)),
      );
      await _settle(tester);
      expect(find.text('Your first month'), findsOneWidget);
      expect(find.text('12 DAYS OF READING'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('first-offer-figure-cards')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('first-offer-figure-streak')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('first-offer-figure-sure')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('first-offer-figure-strongest')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('first-offer-best')), findsNothing);
      expect(find.text('—'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Start the free trial": the store\'s sheet, the trial\'s own '
        'screen, then the page goes; counted as the first week\'s', (
      tester,
    ) async {
      final (AppState app, _) = await numbered();
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context)
                        .push(FirstOfferScreen.route(app, FirstOffer.week)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await _settle(tester);
      expect(_page, findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('first-offer-start')));
      await _settle(tester, 40);
      expect(store.buys, 1);
      expect(find.byType(PurchaseSuccessScreen), findsOneWidget);
      expect(said.of('purchase ended').single['source'], 'first week');
      expect(said.of('purchase ended').single['outcome'], 'bought');
      expect(said.of('purchase success shown').single['source'], 'first week');
      expect(said.of('first offer trial started').single, {
        'source': 'first week',
        'product': 'com.astuto.app.plus.yearly',
        'trial': true,
        'trial_days': 14,
        'ms_open': isA<int>(),
      });
      await tester.tap(find.text(_en.letsStart));
      await _settle(tester, 20);
      expect(_page, findsNothing);
      expect(app.isPlus, isTrue);
      expect(said.of('first offer closed').single['left_by'], 'trial');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('whole on the smallest phone, in long languages and at a '
        'large text size, "Not now" always in reach', (tester) async {
      final (AppState app, _) = await numbered();
      for (final (String language, double text) in [
        ('de', 1.0),
        ('it', 1.0),
        ('ru', 1.0),
        ('en', 1.6),
      ]) {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.padding = const FakeViewPadding(top: 20);
        tester.view.viewPadding = const FakeViewPadding(top: 20);
        await tester.pumpWidget(
          _host(
            Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(text)),
                child: FirstOfferScreen(app: app, which: FirstOffer.week),
              ),
            ),
            language: language,
          ),
        );
        await _settle(tester);
        expect(tester.takeException(), isNull, reason: '$language at $text');
        final AppLocalizations l = lookupAppLocalizations(Locale(language));
        // Both buttons on screen and in reach, whatever scrolls above them.
        for (final String key in ['first-offer-start', 'first-offer-not-now']) {
          expect(
            find.byKey(ValueKey(key)).hitTestable(),
            findsOneWidget,
            reason: '$key, $language at $text',
          );
        }
        expect(find.text(l.firstOfferNotNow).hitTestable(), findsOneWidget);
        expect(
          tester
              .getSize(find.byKey(const ValueKey('first-offer-not-now')))
              .height,
          greaterThanOrEqualTo(48),
        );
        // The title whole, never cut.
        expect(find.text(l.firstWeekTitle), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('a preview, from the developer tools: sample numbers, '
        'nothing kept, nothing counted', (tester) async {
      final AppState app = await readyApp({'knowit.plus': true});
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  FirstOfferScreen.route(app, FirstOffer.month, preview: true),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await _settle(tester);
      // Up on a phone with Astute+ too: it is only looked at.
      expect(_page, findsOneWidget);
      expect(find.text('Your first month'), findsOneWidget);
      expect(find.text('22 DAYS OF READING'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('first-offer-not-now')));
      await _settle(tester);
      expect(_page, findsNothing);
      expect(app.firstMonthOfferedOn, isNull);
      expect(said.of('first offer shown'), isEmpty);
      expect(said.of('first offer closed'), isEmpty);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
