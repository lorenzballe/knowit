import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/reminder.dart';
import 'package:astuto/models/trial.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/account.dart';
import 'package:astuto/sync/board.dart';
import 'package:astuto/sync/push.dart';
import 'package:astuto/sync/subscription.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/reminder_ask.dart';

/// The question about notifications, asked the app's way: a sheet that asks
/// when, at a quiet moment, before the system's one prompt asks whether —
/// and the warning before a free trial charges, which the sheet can promise.

/// Stands in for the system's prompt: counts the times it is put, and
/// answers yes, with a token.
class _Asker extends Push {
  int asked = 0;

  @override
  bool get canAsk => true;

  @override
  Future<String?> ask() async {
    asked++;
    return 'token-a';
  }

  @override
  Future<String?> refresh() async => null;
}

/// The store, with nothing behind it but what a test says it holds, and its
/// screen for managing a plan counted rather than opened.
class _Store extends Subscription {
  _Store() : super(keyOverride: '');

  int managed = 0;

  @override
  Future<void> presentCustomerCenter() async => managed++;
}

/// What the app said, kept, so a test can read its measurement back.
class _Said implements AnalyticsSink {
  final List<(String, Map<String, Object>)> events = [];

  Iterable<Map<String, Object>> of(String event) =>
      events.where((e) => e.$1 == event).map((e) => e.$2);

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

/// The year on sale, as the store would hand it over: €29,99 and two weeks
/// free.
const String _yearId = 'com.astuto.app.plus.yearly';

Offering _yearOnSale() {
  const context = PresentedOfferingContext('default', null, null);
  final year = Package(
    r'$rc_annual',
    PackageType.annual,
    const StoreProduct(
      _yearId,
      'Astute+',
      'Astute+',
      29.99,
      '€29,99',
      'EUR',
      introductoryPrice: IntroductoryPrice(
        0,
        '€0,00',
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

/// Astute+ as RevenueCat describes it: in its free trial by default,
/// ending [ends], set to renew.
EntitlementInfo _plus({
  required DateTime ends,
  bool willRenew = true,
  PeriodType period = PeriodType.trial,
  String product = _yearId,
}) => EntitlementInfo(
  kPlusEntitlement,
  true,
  willRenew,
  DateTime.now().toUtc().toIso8601String(),
  DateTime.now().toUtc().toIso8601String(),
  product,
  true,
  periodType: period,
  expirationDate: ends.toUtc().toIso8601String(),
);

final Finder _sheet = find.byKey(const ValueKey('reminder-ask'));

String _key(DateTime d) => dateKey(d);

DateTime _daysFromToday(int days) {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day + days);
}

/// An install past the first run, on the free plan.
Map<String, Object> _installed() => {
  'knowit.onboarded': true,
  'knowit.plus': false,
};

/// Today's five, already read: the app opens on the finished day.
Map<String, Object> _todayRead() => {
  'knowit.todayDate': _key(DateTime.now()),
  'knowit.todayDeckIds': dealDay(date: DateTime.now()).cards
      .map((p) => p.id)
      .toList(),
  'knowit.todayIndex': 5,
};

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Throws the card on top of the deck, from its question.
Future<void> _throw(WidgetTester tester) async {
  final Rect deck = tester.getRect(find.byType(PillCardStack));
  await tester.flingFrom(
    Offset(deck.center.dx, deck.top + 90),
    const Offset(-320, 0),
    900,
  );
  await _settle(tester);
}

/// Long enough for the sheet's beat and its rise, frame by frame: what
/// starts the beat — a route closing, the shelf coming up — happens in a
/// frame, and one long jump of the clock would start it only at the end.
Future<void> _wait(WidgetTester tester, {int seconds = 3}) async {
  for (var i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await _settle(tester);
}

/// The home-screen widgets' channel, answered as a phone with none placed.
/// The app listens to the store only once it has asked about them, and a
/// channel nobody answers is a question that never comes back under test.
void _noWidgets(WidgetTester tester) {
  const channel = MethodChannel('astut/widget');
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    channel,
    (call) async => call.method == 'installed' ? const <Object?>[] : null,
  );
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
}

/// The app's state, read off the tabs — which may be under a pushed screen.
AppState _appOf(WidgetTester tester) => tester
    .widget<AstutoShell>(find.byType(AstutoShell, skipOffstage: false))
    .app;

/// An app with the platform stood in for: what it was asked to arm, and
/// whether the system lets it notify.
({AppState app, List<List<Reminder>> armed}) _bare({
  bool granted = true,
  Map<String, Object> prefs = const {},
}) {
  SharedPreferences.setMockInitialValues({..._installed(), ...prefs});
  final armed = <List<Reminder>>[];
  final app = AppState(
    hasPermission: () async => granted,
    askPermission: () async => granted,
    arm: (plan) async => armed.add(plan),
    disarm: () async => armed.add(const []),
  );
  return (app: app, armed: armed);
}

Reminder? _warningIn(List<Reminder> plan) =>
    plan.where((r) => r.id == AppState.kTrialWarningId).firstOrNull;

void main() {
  late _Asker asker;
  late _Said said;

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(402, 874) * 3;
    view.devicePixelRatio = 3;
    asker = _Asker();
    Push.useForTest(asker);
    said = _Said();
    Analytics.useForTest(said);
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    Push.useForTest(Push());
    Analytics.useForTest(null);
    Subscription.useForTest(Subscription());
  });

  group('after the first finished day', () {
    testWidgets('the sheet comes instead of the system\'s prompt, once the '
        'card after the fifth is off the table', (tester) async {
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);

      for (var i = 0; i < 5; i++) {
        await _throw(tester);
      }
      // The day is finished, and the evening's offer is on the table: no
      // question over it, and nothing of the system's spent.
      expect(_appOf(tester).dayClosed, isTrue);
      expect(find.byKey(const ValueKey('magic-card')), findsOneWidget);
      await _wait(tester);
      expect(_sheet, findsNothing);
      expect(asker.asked, 0);

      // Thrown, the shelf comes up — and a beat later, the sheet.
      await _throw(tester);
      expect(find.byType(PillCardStack), findsNothing);
      await _wait(tester);
      expect(_sheet, findsOneWidget);
      expect(find.text('When should we remind you?'), findsOneWidget);
      expect(
        find.text('One notification a day, with a question from your cards.'),
        findsOneWidget,
      );
      // No trial, so no word of one.
      expect(find.byKey(const ValueKey('reminder-ask-trial')), findsNothing);
      expect(asker.asked, 0, reason: 'the system is not asked yet');
      expect(said.of('push preprompt shown'), [
        {'reason': 'day done'},
      ]);
      expect(said.of('push permission asked'), isEmpty);
    });

    testWidgets('not over the paywall that card opens either, nor until the '
        'card is thrown', (tester) async {
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      for (var i = 0; i < 5; i++) {
        await _throw(tester);
      }

      // The card after the fifth, taken up on its offer.
      await tester.tap(find.text('Try 14 days free'));
      await _settle(tester);
      expect(find.byType(PaywallScreen), findsOneWidget);
      await _wait(tester);
      expect(_sheet, findsNothing);

      // Closed without the trial: the card is back on the table, so still
      // nothing, until it is thrown.
      await tester.tap(
        find.descendant(
          of: find.byType(PaywallScreen),
          matching: find.byIcon(Icons.close_rounded),
        ),
      );
      await _wait(tester);
      expect(find.byType(PaywallScreen), findsNothing);
      expect(_sheet, findsNothing);

      await _throw(tester);
      await _wait(tester);
      expect(_sheet, findsOneWidget);
    });

    testWidgets('a time chosen is kept, and then the system is asked, once', (
      tester,
    ) async {
      // The day was read on an earlier launch: this one opens on the shelf,
      // which is the day's moment too.
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        ..._todayRead(),
        'knowit.streak': 1,
        'knowit.lastCompletionDate': _key(DateTime.now()),
        'knowit.completedDates': [_key(DateTime.now())],
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _wait(tester);
      expect(_sheet, findsOneWidget);

      // The time the reminder is already set to is the one chosen.
      final Semantics morning = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byKey(const ValueKey('reminder-at-08:30')),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(morning.properties.selected, isTrue);
      expect(find.text('8:30 AM'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('reminder-at-19:00')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('reminder-yes')));
      await _settle(tester);

      expect(_sheet, findsNothing);
      expect(asker.asked, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('knowit.notifyHour'), '19:00');
      expect(prefs.getBool('knowit.pushAsked'), isTrue);
      expect(prefs.getStringList('knowit.pushTokens'), ['token-a']);
      expect(said.of('push preprompt answered'), [
        {'choice': '19:00'},
      ]);
      expect(said.of('push permission asked'), hasLength(1));
      expect(said.of('push permission answered'), [
        {'granted': true},
      ]);

      // Asked is asked: the sheet does not come again.
      await _wait(tester);
      expect(_sheet, findsNothing);
      expect(asker.asked, 1);
    });

    testWidgets('a time of the reader\'s own is shown, and kept', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        ..._todayRead(),
        'knowit.notifyHour': '07:15',
        'knowit.lastCompletionDate': _key(DateTime.now()),
        'knowit.completedDates': [_key(DateTime.now())],
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _wait(tester);

      expect(find.text('Another time'), findsOneWidget);
      expect(find.text('7:15 AM'), findsOneWidget);
      // Away to the morning and back: the reader's own time is still there.
      await tester.tap(find.byKey(const ValueKey('reminder-at-08:30')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('reminder-at-own')));
      await _settle(tester);
      // Chosen again, a tap opens the phone's clock on it.
      await tester.tap(find.byKey(const ValueKey('reminder-at-own')));
      await _settle(tester);
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await _settle(tester);

      await tester.tap(find.byKey(const ValueKey('reminder-yes')));
      await _settle(tester);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('knowit.notifyHour'), '07:15');
      expect(said.of('push preprompt answered'), [
        {'choice': '07:15'},
      ]);
      expect(asker.asked, 1);
    });
  });

  group('"Not now"', () {
    testWidgets('spends nothing of the system\'s', (tester) async {
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        ..._todayRead(),
        'knowit.lastCompletionDate': _key(DateTime.now()),
        'knowit.completedDates': [_key(DateTime.now())],
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _wait(tester);
      await tester.tap(find.byKey(const ValueKey('reminder-not-now')));
      await _settle(tester);

      expect(_sheet, findsNothing);
      expect(asker.asked, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('knowit.pushAsked'), isNot(isTrue));
      expect(prefs.getInt('knowit.pushDeferrals'), 1);
      expect(prefs.getString('knowit.pushDeferredAfter'), _key(DateTime.now()));
      expect(said.of('push preprompt answered'), [
        {'choice': 'not now'},
      ]);

      // Not again today, however long the shelf is looked at.
      await _wait(tester, seconds: 6);
      expect(_sheet, findsNothing);
    });

    testWidgets('it comes back after the next finished day', (tester) async {
      // Said yesterday; today has been read since.
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        ..._todayRead(),
        'knowit.lastCompletionDate': _key(DateTime.now()),
        'knowit.completedDates': [
          _key(_daysFromToday(-1)),
          _key(DateTime.now()),
        ],
        'knowit.pushDeferrals': 1,
        'knowit.pushDeferredAfter': _key(_daysFromToday(-1)),
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _wait(tester);
      expect(_sheet, findsOneWidget);
      expect(asker.asked, 0);
    });

    testWidgets('and stops after the third', (tester) async {
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        ..._todayRead(),
        'knowit.lastCompletionDate': _key(DateTime.now()),
        'knowit.completedDates': [
          _key(_daysFromToday(-1)),
          _key(DateTime.now()),
        ],
        'knowit.pushDeferrals': 3,
        'knowit.pushDeferredAfter': _key(_daysFromToday(-1)),
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _wait(tester, seconds: 6);
      expect(_sheet, findsNothing);
      expect(asker.asked, 0);
    });

    test('waits for a day finished after it, three times at most', () async {
      final String today = _key(DateTime.now());
      final String yesterday = _key(_daysFromToday(-1));
      Future<AppState> app(Map<String, Object> prefs) async {
        final state = _bare(prefs: prefs).app;
        await state.init();
        return state;
      }

      final AppState fresh = await app({
        'knowit.lastCompletionDate': today,
        'knowit.completedDates': [today],
      });
      expect(fresh.shouldAskForPush, isTrue);
      await fresh.notedPushDeferred();
      expect(fresh.pushDeferrals, 1);
      expect(fresh.pushDeferredAfter, today);
      expect(fresh.shouldAskForPush, isFalse, reason: 'not the same day');

      // The first, and twice more.
      for (final (int said, bool again) in [(1, true), (2, true), (3, false)]) {
        final AppState later = await app({
          'knowit.lastCompletionDate': today,
          'knowit.completedDates': [yesterday, today],
          'knowit.pushDeferrals': said,
          'knowit.pushDeferredAfter': yesterday,
        });
        expect(later.shouldAskForPush, again, reason: '$said said');
      }

      // Said before any day was finished — on the sheet a trial brings —
      // it waits for the first.
      final AppState early = await app({'knowit.pushDeferrals': 1});
      expect(early.shouldAskForPush, isFalse);
      final AppState thenRead = await app({
        'knowit.pushDeferrals': 1,
        'knowit.lastCompletionDate': today,
        'knowit.completedDates': [today],
      });
      expect(thenRead.shouldAskForPush, isTrue);

      // A reader who switched the nudge off has answered already.
      final AppState off = await app({
        'knowit.notifications': false,
        'knowit.lastCompletionDate': today,
        'knowit.completedDates': [today],
      });
      expect(off.shouldAskForPush, isFalse);
    });

    test('is forgotten on signing out, like the prompt itself', () async {
      final state = _bare(
        prefs: {
          'knowit.pushDeferrals': 2,
          'knowit.pushDeferredAfter': '2026-10-01',
        },
      ).app;
      await state.init();
      await state.signOut();
      expect(state.pushDeferrals, 0);
      expect(state.pushDeferredAfter, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('knowit.pushDeferrals'), isNull);
    });
  });

  testWidgets('no rating prompt in the session the sheet rose', (tester) async {
    // A seventh day in a row about to be read, by a reader who said "Not
    // now" two days ago: the sheet is due tonight, and so, by the streak,
    // would the stars be.
    final List<String> six = [
      for (var i = 6; i >= 1; i--) _key(_daysFromToday(-i)),
    ];
    SharedPreferences.setMockInitialValues({
      ..._installed(),
      'knowit.streak': 6,
      'knowit.lastCompletionDate': six.last,
      'knowit.completedDates': six,
      'knowit.pushDeferrals': 1,
      'knowit.pushDeferredAfter': _key(_daysFromToday(-2)),
    });
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);
    for (var i = 0; i < 6; i++) {
      await _throw(tester);
    }
    await _wait(tester);
    expect(_appOf(tester).liveStreak, 7);
    expect(_sheet, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reminder-not-now')));
    await _wait(tester);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('knowit.reviewAsked'), isNot(isTrue));

    // The next session may ask: the question about notifications has had
    // its say, on an earlier one.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);
    await _wait(tester);
    expect(_sheet, findsNothing);
    expect(prefs.getBool('knowit.reviewAsked'), isTrue);
  });

  group('the warning before a trial charges', () {
    test('two days before the end, at the reader\'s hour, at the store\'s '
        'price', () async {
      final t = _bare(granted: false, prefs: {'knowit.notifyHour': '19:00'});
      await t.app.init();
      final DateTime now = DateTime.now();
      final DateTime ends = DateTime(now.year, now.month, now.day + 10, 14, 23);
      await t.app.applyTrial(FreeTrial(endsAt: ends, price: '€29,99'));

      final Reminder warning = _warningIn(t.app.reminderPlan(now: now))!;
      expect(warning.when, DateTime(ends.year, ends.month, ends.day - 2, 19));
      expect(warning.title, 'Your Astute+ trial ends in 2 days.');
      expect(
        warning.body,
        'On ${DateFormat.MMMMd('en').format(ends)} your year starts at '
        '€29,99. To keep going, do nothing. To stop: Profile → Manage '
        'subscription.',
      );
      // The daily nudge is still all there beside it.
      expect(t.app.reminderPlan(now: now).where((r) => r.id <= 15), isNotEmpty);
    });

    test('a minute from now when that hour has passed and the trial has '
        'not', () async {
      final t = _bare();
      await t.app.init();
      final DateTime now = DateTime.now();
      final DateTime ends = now.add(const Duration(hours: 30));
      await t.app.applyTrial(FreeTrial(endsAt: ends, price: '€29,99'));

      // Armed the moment the trial was heard of: late, but before the
      // charge, and saying how late.
      final Reminder armed = _warningIn(t.armed.last)!;
      expect(armed.when.difference(now).inSeconds, closeTo(60, 5));
      expect(armed.when.isBefore(ends), isTrue);
      final int left = DateTime.utc(ends.year, ends.month, ends.day)
          .difference(
            DateTime.utc(armed.when.year, armed.when.month, armed.when.day),
          )
          .inDays;
      expect(
        armed.title,
        left == 1
            ? 'Your Astute+ trial ends tomorrow.'
            : 'Your Astute+ trial ends in $left days.',
      );
    });

    test('once given, never again: not at the next launch, nor for a time '
        'changed after it', () async {
      final DateTime now = DateTime.now();
      final DateTime ends = now.add(const Duration(hours: 40));
      String at(DateTime d) => d.toUtc().toIso8601String();
      // Armed an hour ago, for this trial: it has been given.
      final t = _bare(
        prefs: {
          'knowit.trialEnds': at(ends),
          'knowit.trialPrice': '€29,99',
          'knowit.trialWarnedFor': at(ends),
          'knowit.trialWarnedAt': at(now.subtract(const Duration(hours: 1))),
        },
      );
      await t.app.init();
      await Future<void>.delayed(Duration.zero);
      expect(t.app.trial, FreeTrial(endsAt: ends, price: '€29,99'));
      expect(_warningIn(t.armed.last), isNull, reason: 're-armed without it');
      await t.app.setNotifyTime('23:59');
      expect(_warningIn(t.armed.last), isNull);

      // A trial of its own is a warning of its own.
      final DateTime next = now.add(const Duration(days: 20));
      await t.app.applyTrial(FreeTrial(endsAt: next, price: '€29,99'));
      expect(_warningIn(t.armed.last), isNotNull);
    });

    test('absent with no trial, with one that will not renew, one turned '
        'into the year, and one the store has not priced', () async {
      final DateTime ends = DateTime.now().add(const Duration(days: 9));
      final store = _Store()..answerForTest(offering: _yearOnSale());

      final t = _bare(granted: false);
      await t.app.init();
      expect(_warningIn(t.app.reminderPlan()), isNull, reason: 'no trial');

      store.holdForTest(_plus(ends: ends));
      expect(store.trial?.price, '€29,99');
      await t.app.applyTrial(store.trial);
      expect(_warningIn(t.app.reminderPlan()), isNotNull);

      // Cancelled: it runs to its end and charges nothing.
      store.holdForTest(_plus(ends: ends, willRenew: false));
      expect(store.trial, isNull);
      await t.app.applyTrial(store.trial);
      expect(_warningIn(t.app.reminderPlan()), isNull);

      // Turned into the year: nothing left to warn about.
      store.holdForTest(_plus(ends: ends, period: PeriodType.normal));
      expect(store.trial, isNull);

      // A trial of something that is not the year on sale: the warning
      // names the year, so it says nothing rather than something untrue.
      store.holdForTest(_plus(ends: ends, product: 'something.else'));
      expect(store.trial, isNotNull);
      expect(store.trial!.price, isNull);
      await t.app.applyTrial(store.trial);
      expect(_warningIn(t.app.reminderPlan()), isNull);
    });

    test('re-armed whenever the trial moves, kept when the store is slow, '
        'and kept with the nudge off', () async {
      final t = _bare(prefs: {'knowit.notifications': false});
      await t.app.init();
      final DateTime ends = DateTime.now().add(const Duration(days: 9));

      await t.app.applyTrial(FreeTrial(endsAt: ends, price: '€29,99'));
      // The switch is the nudge's: what is armed is the warning, alone.
      expect(t.armed.last.map((r) => r.id), [AppState.kTrialWarningId]);

      // The same trial described before the offering arrived keeps its
      // price, and with it the warning.
      await t.app.applyTrial(FreeTrial(endsAt: ends));
      expect(t.app.trial?.price, '€29,99');

      // Kept on the phone, so a launch with no answer from the store still
      // warns.
      final again = AppState(
        hasPermission: () async => true,
        arm: (_) async {},
        disarm: () async {},
      );
      await again.init();
      expect(again.trial, FreeTrial(endsAt: ends, price: '€29,99'));
      expect(_warningIn(again.reminderPlan()), isNotNull);

      // Cancelled: re-armed without it.
      await t.app.applyTrial(null);
      expect(_warningIn(t.armed.last), isNull);
    });
  });

  group('after a trial starts', () {
    testWidgets('the sheet is offered once the purchase\'s screens close, '
        'with the warning on it', (tester) async {
      final store = _Store()..answerForTest(offering: _yearOnSale());
      Subscription.useForTest(store);
      _noWidgets(tester);
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);

      // The plans, from the profile, and the store confirming a trial while
      // they are still on screen — as it does under a purchase.
      await tester.tap(find.byKey(const ValueKey('tab-Profile')));
      await _settle(tester);
      await tester.tap(find.text('SEE THE PLANS'));
      await _settle(tester);
      expect(find.byType(PaywallScreen), findsOneWidget);
      store.holdForTest(
        _plus(ends: DateTime.now().add(const Duration(days: 14))),
      );
      await _wait(tester);
      expect(_appOf(tester).trial, isNotNull);
      expect(_sheet, findsNothing, reason: 'never over the paywall');

      await tester.tap(
        find.descendant(
          of: find.byType(PaywallScreen),
          matching: find.byIcon(Icons.close_rounded),
        ),
      );
      await _wait(tester);
      expect(_sheet, findsOneWidget);
      expect(
        find.text('We’ll remind you two days before your trial ends.'),
        findsOneWidget,
      );
      expect(said.of('push preprompt shown'), [
        {'reason': 'trial'},
      ]);

      await tester.tap(find.byKey(const ValueKey('reminder-yes')));
      await _settle(tester);
      expect(asker.asked, 1);
    });
  });

  group('the line on the profile', () {
    Future<AppState> inTrial(Duration left, {bool granted = false}) async {
      final t = _bare(granted: granted);
      await t.app.init();
      await t.app.applyTrial(
        FreeTrial(endsAt: DateTime.now().add(left), price: '€29,99'),
      );
      return t.app;
    }

    test('only in the last two days, and only for a reader no warning '
        'reaches', () async {
      expect(
        (await inTrial(const Duration(days: 5))).trialNoticeDays(),
        isNull,
      );
      expect(
        (await inTrial(const Duration(hours: 47))).trialNoticeDays(),
        isNotNull,
      );
      expect(
        (await inTrial(
          const Duration(hours: 47),
          granted: true,
        )).trialNoticeDays(),
        isNull,
        reason: 'the notification is armed for them',
      );
      final AppState ended = await inTrial(const Duration(hours: -1));
      expect(ended.trialNoticeDays(), isNull);
    });

    Widget host(AppState app) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: Scaffold(
        body: ProfileScreen(
          app: app,
          account: Account(
            uidOverride: 'me',
            boardsOverride: MemoryBoardStore(),
          ),
          onSignedOut: () {},
        ),
      ),
    );

    testWidgets('says when, and opens the store\'s own screen', (tester) async {
      final store = _Store();
      Subscription.useForTest(store);
      final DateTime now = DateTime.now();
      final AppState app = await inTrial(
        DateTime(now.year, now.month, now.day + 1, 18).difference(now),
      );
      await tester.pumpWidget(host(app));
      await _settle(tester);

      final Finder notice = find.byKey(const ValueKey('trial-notice'));
      expect(notice, findsOneWidget);
      expect(
        find.text('Your trial ends tomorrow  ·  Manage', findRichText: true),
        findsOneWidget,
      );
      await tester.tap(notice);
      await _settle(tester);
      expect(store.managed, 1);
      expect(
        said.of('manage subscription opened').single['from'],
        'trial notice',
      );
    });

    testWidgets('and is not there earlier in the trial', (tester) async {
      final AppState app = await inTrial(const Duration(days: 6));
      await tester.pumpWidget(host(app));
      await _settle(tester);
      expect(find.byKey(const ValueKey('trial-notice')), findsNothing);
    });
  });

  testWidgets('the sheet and the line fit in every language', (tester) async {
    await tester.runAsync(_loadRealFonts);
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Every line the sheet can show: a trial just started, and a time of
    // the reader's own.
    Future<AppState> inTrial(DateTime ends, {String at = '08:30'}) async {
      final AppState app = _bare(
        granted: false,
        prefs: {'knowit.notifyHour': at},
      ).app;
      await app.init();
      await app.applyTrial(FreeTrial(endsAt: ends, price: '€29,99'));
      await app.applyEntitlement(true);
      return app;
    }

    final AppState started = await inTrial(
      DateTime.now().add(const Duration(days: 14)),
      at: '07:15',
    );
    expect(started.warnsBeforeTrialEnds, isTrue);
    // And every line the profile can: a trial ending tomorrow, with no
    // notifications. Its warning can only come late now, so the sheet no
    // longer promises one two days ahead.
    final DateTime now = DateTime.now();
    final AppState ending = await inTrial(
      DateTime(now.year, now.month, now.day + 1, 18),
    );
    expect(ending.warnsBeforeTrialEnds, isFalse);
    expect(ending.trialWarning(), isNotNull, reason: 'given late, still');

    final findings = <String>[];
    for (final Locale locale in AppLocalizations.supportedLocales) {
      Widget host(Widget child) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: child,
      );
      await tester.pumpWidget(
        host(
          Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ReminderAsk(app: started),
            ),
          ),
        ),
      );
      await _settle(tester);
      findings.addAll(_cut(tester).map((s) => '[$locale] sheet: $s'));
      expect(find.byKey(const ValueKey('reminder-ask-trial')), findsOneWidget);

      await tester.pumpWidget(
        host(
          Scaffold(
            body: ProfileScreen(
              app: ending,
              account: Account(
                uidOverride: 'me',
                boardsOverride: MemoryBoardStore(),
              ),
              onSignedOut: () {},
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byKey(const ValueKey('trial-notice')), findsOneWidget);
      findings.addAll(_cut(tester).map((s) => '[$locale] profile: $s'));
    }
    expect(findings, isEmpty, reason: findings.join('\n'));
  });
}

/// The faces the app ships, so a layout is measured in the text a reader
/// sees.
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

/// Every paragraph on screen that did not get all of its text out, and any
/// overflow the layout reported.
List<String> _cut(WidgetTester tester) {
  final out = <String>[];
  final Object? error = tester.takeException();
  if (error != null) out.add('overflow — ${'$error'.split('\n').first}');
  for (final element in find.byType(RichText).evaluate()) {
    final ro = element.renderObject;
    if (ro is! RenderParagraph || !ro.attached || !ro.hasSize) continue;
    final String plain = ro.text.toPlainText();
    if (plain.trim().isEmpty) continue;
    final Color? colour = ro.text.style?.color;
    if (colour != null && colour.a == 0) continue;
    String? how;
    if (ro.didExceedMaxLines) how = 'lines';
    final painter = TextPainter(
      text: ro.text,
      textDirection: ro.textDirection,
      textScaler: ro.textScaler,
      textAlign: ro.textAlign,
      maxLines: ro.maxLines,
    )..layout(maxWidth: ro.softWrap ? ro.size.width : double.infinity);
    if (how == null && painter.height > ro.size.height + 0.5) how = 'height';
    if (how == null && !ro.softWrap && painter.width > ro.size.width + 0.5) {
      how = 'width';
    }
    painter.dispose();
    if (how != null) out.add('"$plain" ($how)');
  }
  return out;
}
