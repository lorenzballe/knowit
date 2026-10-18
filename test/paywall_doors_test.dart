import 'dart:async';
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
import 'package:astuto/legal.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/screens/purchase_success_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/subscription.dart';
import 'package:astuto/theme.dart';

/// [n] answers said [sure]% sure, the first [right] of them right.
Map<String, Object> _judged(int n, {required int sure, required int right}) => {
  'knowit.judgements': jsonEncode([
    for (var i = 0; i < n; i++)
      {
        'c': sure,
        'k': i < right,
        'p': PillBank.cards[i].id,
        'd': dateKey(DateTime.now()),
      },
  ]),
};

/// A year on sale as the store hands it over, at a price the app never
/// writes itself, with its introductory offer if it has one.
Offering _yearAt(String price, {IntroductoryPrice? intro}) {
  const context = PresentedOfferingContext('default', null, null);
  final year = Package(
    '\$rc_annual',
    PackageType.annual,
    StoreProduct(
      'astuto_pro_year',
      'Astute+',
      'Astute+',
      29.99,
      price,
      'USD',
      introductoryPrice: intro,
    ),
    context,
  );
  return Offering('default', '', const {}, [year], annual: year);
}

IntroductoryPrice _freeFor(PeriodUnit unit, int units) =>
    IntroductoryPrice(0, '\$0.00', 'P$units', 1, unit, units);

/// The faces the app ships, so what fits on a small phone is measured in
/// the type a reader sees rather than the test's square stand-in.
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

/// Keeps what the paywall measures, to be read back.
class _Recorder implements AnalyticsSink {
  final List<(String, Map<String, Object>)> events = [];

  Map<String, Object>? last(String event) {
    for (final e in events.reversed) {
      if (e.$1 == event) return e.$2;
    }
    return null;
  }

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

/// The paywall opens on what the reader reached for: the record from the
/// journey, the whole day from the card after the fifth, the days from the
/// archive, and what the habit adds up to from everywhere else. Under the
/// button, a trial is told as the days it will go by.
void main() {
  late _Recorder sink;
  late Subscription store;
  final Subscription before = Subscription.instance;

  setUpAll(_loadRealFonts);

  setUp(() {
    sink = _Recorder();
    Analytics.useForTest(sink);
    // No store unless a test answers for one: the plans as sold.
    store = Subscription(keyOverride: '');
    Subscription.useForTest(store);
  });

  tearDown(() {
    Analytics.useForTest(null);
    Subscription.useForTest(before);
  });

  /// The paywall as [source] opens it, on a phone, for a reader on the free
  /// plan unless told otherwise, and one whose phone lets the app notify
  /// them only when [notifies] says so. Pushed over a screen of its own, as
  /// every door pushes it, so that it can be left. [app] stands in for the
  /// reader's state where a test needs its own.
  Future<void> open(
    WidgetTester tester,
    String source, {
    Map<String, Object> prefs = const {},
    bool plus = false,
    Size phone = const Size(390, 844),
    double notch = 47,
    Locale locale = const Locale('en'),
    bool notifies = false,
    AppState? app,
  }) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = FakeViewPadding(top: notch);
    tester.view.viewPadding = FakeViewPadding(top: notch);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      'knowit.plus': plus,
      ...prefs,
    });
    final AppState reader = app ?? AppState();
    await reader.init();
    reader.notificationsAllowed = notifies;
    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        // A tree of its own each time: one paywall opened over another in
        // the same test would keep the first one's state.
        key: UniqueKey(),
        navigatorKey: navigator,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: const Scaffold(body: Text('Under the paywall')),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => PaywallScreen(app: reader, source: source),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// The words under the headline.
  String line(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('paywall-line')),
          matching: find.byType(Text),
        ),
      )
      .single
      .data!;

  group('each door opens on what it was reached for', () {
    const String record = 'See how much you really know.';
    const String outcome = 'Be the one nobody fools.';
    for (final (String source, String headline, String letter) in const [
      ('journey', record, 'A'),
      ('calibration', record, 'A'),
      ('see the plans', outcome, 'B'),
      ('manage plan', outcome, 'B'),
      ('site preview', outcome, 'B'),
      ('debug', outcome, 'B'),
      ('a door nobody has named yet', outcome, 'B'),
      ('sixth card', 'All five, yours.', 'C'),
      ('archive', "What you've read, day by day.", 'D'),
    ]) {
      testWidgets('$source: "$headline"', (tester) async {
        await open(tester, source);
        expect(find.text(headline), findsOneWidget);
        // The word it leans on is painted, and only that.
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('paywall-headline')),
            matching: find.byType(ShaderMask),
          ),
          findsOneWidget,
        );
        expect(PaywallVariant.of(source).letter, letter);
        expect(sink.last('paywall shown'), {
          'source': source,
          'variant': letter,
          'has_number': false,
          'plan_shown': 'year',
          // No store behind the test: a debug build's plans as sold, and
          // measured as a paywall that could not sell.
          'store_answered': false,
          'store': 'unreachable',
        });
      });
    }

    testWidgets('the line under each says what that door is about', (
      tester,
    ) async {
      await open(tester, 'journey');
      expect(
        line(tester),
        'Every day you say how sure you are. Astute+ shows whether the gap '
        'between sure and right is closing, and the moves you keep missing.',
      );
      await open(tester, 'see the plans');
      expect(
        line(tester),
        'Five cards a day at your level. The ones you miss come back until '
        'they stick. And you see yourself change, week by week.',
      );
      // The free day as dealDay deals it: two of the reader's own, three the
      // morning after a week in a row.
      await open(tester, 'sixth card');
      expect(
        line(tester),
        'Free days pick two of the five for you, three after a week in a '
        'row. Astute+ picks all five from your strands, at your level, and '
        'brings back the ones you miss.',
      );
      await open(tester, 'archive');
      expect(line(tester), contains('newest first'));
    });

    testWidgets('the perks lead with the record', (tester) async {
      await open(tester, 'see the plans');
      final double gap = tester.getTopLeft(find.text('Watch the gap close')).dy;
      final double own = tester
          .getTopLeft(find.text('Five of your own cards'))
          .dy;
      final double read = tester.getTopLeft(find.text("What you've read")).dy;
      expect(gap, lessThan(own));
      expect(own, lessThan(read));
      // Nothing the free plan already has, and nothing never delivered.
      expect(find.textContaining('freeze'), findsNothing);
      expect(find.byType(Scrollable), findsNothing);
    });
  });

  group('the record door tells a reader their own numbers', () {
    testWidgets('with twelve answers said how sure, and not with eleven', (
      tester,
    ) async {
      await open(tester, 'journey', prefs: _judged(12, sure: 80, right: 7));
      expect(
        line(tester),
        "You say 80% sure and you're right 58% of the time. Astute+ shows "
        'whether that gap is closing, and the moves you keep missing.',
      );
      expect(sink.last('paywall shown')!['has_number'], isTrue);

      await open(tester, 'journey', prefs: _judged(11, sure: 80, right: 7));
      expect(line(tester), startsWith('Every day you say how sure you are.'));
      expect(find.textContaining('80%'), findsNothing);
      expect(sink.last('paywall shown')!['has_number'], isFalse);
    });

    testWidgets('a reader more often right than sure is told so', (
      tester,
    ) async {
      await open(tester, 'journey', prefs: _judged(12, sure: 60, right: 10));
      expect(
        line(tester),
        "You say 60% sure and you're right 83% of the time: you know more "
        'than you think. Astute+ shows whether that gap is closing.',
      );
    });

    testWidgets('within five points is a match, as the profile says', (
      tester,
    ) async {
      await open(tester, 'journey', prefs: _judged(12, sure: 70, right: 8));
      expect(
        line(tester),
        "You say 70% sure and you're right 67% of the time: a close match. "
        'Astute+ shows whether it holds, and the moves you keep missing.',
      );
    });

    testWidgets('the numbers belong to the record door alone', (tester) async {
      await open(tester, 'sixth card', prefs: _judged(12, sure: 80, right: 7));
      expect(find.textContaining('80%'), findsNothing);
      expect(sink.last('paywall shown')!['variant'], 'C');
      // Measured all the same: who could have been told.
      expect(sink.last('paywall shown')!['has_number'], isTrue);
    });
  });

  group('an iPhone SE holds every door whole', () {
    // The door's line and the trial's days take room the perks used to
    // have: on a short phone the perks go down a size rather than away, and
    // the screen still does not scroll. German is the longest of the
    // languages whose letters the test's fonts carry.
    for (final Locale locale in const [Locale('en'), Locale('de')]) {
      testWidgets(locale.languageCode, (tester) async {
        final l = lookupAppLocalizations(locale);
        for (final (String source, Map<String, Object> prefs) in [
          ('journey', const <String, Object>{}),
          ('journey', _judged(12, sure: 80, right: 7)),
          ('sixth card', const <String, Object>{}),
          ('archive', const <String, Object>{}),
          ('see the plans', const <String, Object>{}),
        ]) {
          // The longest the small print gets: the trial's three days, the
          // reminder among them, and how to cancel under them.
          await open(
            tester,
            source,
            prefs: prefs,
            phone: const Size(375, 667),
            notch: 20,
            locale: locale,
            notifies: true,
          );
          expect(tester.takeException(), isNull, reason: source);
          for (final String perk in [
            l.perkGapTitle,
            l.perkOwnFiveTitle,
            l.perkReadTitle,
          ]) {
            expect(find.text(perk), findsOneWidget, reason: '$source $perk');
          }
          expect(find.byKey(const ValueKey('paywall-trial')), findsOneWidget);
          expect(find.byKey(const ValueKey('paywall-cancel')), findsOneWidget);
          expect(find.text(l.restorePurchases), findsOneWidget);
          expect(find.byType(Scrollable), findsNothing);
        }
      });
    }
  });

  group('a trial is told as its days', () {
    final Finder timeline = find.byKey(const ValueKey('paywall-trial'));

    testWidgets('a debug build with no store: the plan as sold, two weeks', (
      tester,
    ) async {
      await open(tester, 'see the plans', notifies: true);
      expect(timeline, findsOneWidget);
      for (final String step in const [
        'Today · all of Astute+, free',
        'Day 12 · we remind you',
        'Day 14 · €29,99 a year, renewing automatically until you cancel',
      ]) {
        expect(
          find.descendant(of: timeline, matching: find.text(step)),
          findsOneWidget,
        );
      }
      // Said once: the days say what "no charge today" used to.
      expect(find.textContaining('No charge today'), findsNothing);
      // And how to stop it, before anything has started.
      expect(
        find.text(
          'Cancel any time in Google Play › Payments & subscriptions › '
          'Subscriptions, at least 24 hours before it renews.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the reminder is promised only where it can reach the reader', (
      tester,
    ) async {
      // A phone that has not let the app notify: the reminder would be a
      // notification nobody sees, so the days do not promise one.
      await open(tester, 'see the plans');
      expect(timeline, findsOneWidget);
      expect(find.textContaining('we remind you'), findsNothing);
      expect(
        find.text(
          'Day 14 · €29,99 a year, renewing automatically until you cancel',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the store\'s own days and its own price', (tester) async {
      store.answerForTest(
        offering: _yearAt('\$29.99', intro: _freeFor(PeriodUnit.week, 1)),
      );
      await open(tester, 'journey', notifies: true);
      expect(find.text('Day 5 · we remind you'), findsOneWidget);
      expect(
        find.text(
          'Day 7 · \$29.99 a year, renewing automatically until you cancel',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('€29,99'), findsNothing);
      expect(sink.last('paywall shown')!['store'], 'ready');
      expect(sink.last('paywall shown')!['store_answered'], isTrue);
    });

    testWidgets('a trial too short for a reminder has no day for it', (
      tester,
    ) async {
      store.answerForTest(
        offering: _yearAt('\$29.99', intro: _freeFor(PeriodUnit.day, 2)),
      );
      await open(tester, 'archive', notifies: true);
      expect(timeline, findsOneWidget);
      expect(find.textContaining('we remind you'), findsNothing);
      expect(
        find.text(
          'Day 2 · \$29.99 a year, renewing automatically until you cancel',
        ),
        findsOneWidget,
      );
    });

    testWidgets('no trial on sale, none shown', (tester) async {
      store.answerForTest(offering: _yearAt('\$29.99'));
      await open(tester, 'sixth card');
      expect(timeline, findsNothing);
      expect(
        find.text(
          '\$29.99/yr charged today, renewing automatically until you cancel',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('paywall-cancel')), findsOneWidget);
      // Only the year is on sale, so only the year is shown: no month at a
      // price the store never gave.
      expect(find.text('Monthly'), findsNothing);
      expect(find.textContaining('€'), findsNothing);
    });

    testWidgets('none for a reader the store says has had it', (tester) async {
      store.answerForTest(
        offering: _yearAt('\$29.99', intro: _freeFor(PeriodUnit.week, 2)),
        yearlyEligibility:
            IntroEligibilityStatus.introEligibilityStatusIneligible,
      );
      await open(tester, 'journey');
      expect(timeline, findsNothing);
      expect(find.textContaining('days free'), findsNothing);
    });

    testWidgets('none for the month, which starts without one', (tester) async {
      await open(tester, 'see the plans');
      expect(timeline, findsOneWidget);
      await tester.tap(find.text('Monthly'));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(timeline, findsNothing);
      expect(
        find.text(
          '€3,99/mo charged today, renewing automatically until you cancel',
        ),
        findsOneWidget,
      );
    });

    testWidgets('none for a reader already on Astute+', (tester) async {
      await open(tester, 'manage plan', plus: true);
      expect(timeline, findsNothing);
    });
  });

  group('a store build shows only the prices the store gave', () {
    final bool preview = Subscription.previewWithoutStore;
    setUp(() => Subscription.previewWithoutStore = false);
    tearDown(() => Subscription.previewWithoutStore = preview);

    testWidgets('no answer: said as that, with a way to try again', (
      tester,
    ) async {
      await open(tester, 'sixth card');
      expect(find.text('Couldn’t reach Google Play'), findsOneWidget);
      expect(
        find.text(
          'The prices and the free trial come from the store. Check your '
          'connection and try again.',
        ),
        findsOneWidget,
      );
      // No price, no plan, and no button that would buy nothing.
      expect(find.textContaining('€'), findsNothing);
      expect(find.text('Yearly'), findsNothing);
      expect(find.byKey(const ValueKey('paywall-buy')), findsNothing);
      expect(find.textContaining('No payment is taken'), findsNothing);
      // What Apple asks for beside a subscription is there all the same.
      expect(find.text('Restore purchases'), findsOneWidget);
      expect(find.text('Terms of Use'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(sink.last('paywall shown')!['store'], 'unreachable');
      // Trying again asks the store; with none behind the test nothing
      // changes, and nothing breaks.
      await tester.tap(find.byKey(const ValueKey('paywall-try-again')));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Couldn’t reach Google Play'), findsOneWidget);
    });

    testWidgets('still asking: said as that, and the plans come with the '
        'answer', (tester) async {
      store.askingForTest(true);
      await open(tester, 'journey');
      expect(find.text('Asking Google Play for the prices…'), findsOneWidget);
      expect(find.textContaining('€'), findsNothing);
      expect(find.byKey(const ValueKey('paywall-buy')), findsNothing);
      expect(sink.last('paywall shown')!['store'], 'asking');
      store.answerForTest(
        offering: _yearAt('\$29.99', intro: _freeFor(PeriodUnit.week, 1)),
      );
      await tester.pump();
      expect(find.text('Asking Google Play for the prices…'), findsNothing);
      expect(find.text('Try 7 days free, then \$29.99/yr'), findsOneWidget);
    });

    testWidgets('on an iPhone: the App Store, and Settings to cancel', (
      tester,
    ) async {
      await open(tester, 'sixth card');
      expect(find.text('Couldn’t reach the App Store'), findsOneWidget);
      store.answerForTest(offering: _yearAt('\$29.99'));
      await tester.pump();
      expect(
        find.text(
          'Cancel any time in Settings › your name › Subscriptions, at least '
          '24 hours before it renews.',
        ),
        findsOneWidget,
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    test('the terms are Apple’s on an iPhone and the site’s elsewhere', () {
      expect(termsUrlFor(TargetPlatform.iOS), kAppleEulaUrl);
      expect(termsUrlFor(TargetPlatform.android), kSiteTermsUrl);
      expect(kSiteTermsUrl, 'https://astutetheapp.com/terms');
    });
  });

  group('buying', () {
    late _Till till;

    setUp(() {
      till = _Till();
      Subscription.useForTest(till);
      till.answerForTest(
        offering: _yearAt('\$29.99', intro: _freeFor(PeriodUnit.week, 1)),
      );
    });

    Future<void> frames(WidgetTester tester, [int n = 4]) async {
      for (var i = 0; i < n; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    final Finder buy = find.byKey(const ValueKey('paywall-buy'));

    testWidgets('a second press starts no second purchase', (tester) async {
      await open(tester, 'sixth card');
      await tester.tap(buy);
      await tester.pump();
      await tester.tap(buy, warnIfMissed: false);
      await tester.pump();
      expect(till.buys, 1);
      expect(find.text('One moment…'), findsOneWidget);
      // Backed out of the store's sheet: the button is the offer again.
      till.reply.complete(PurchaseOutcome.cancelled);
      await frames(tester);
      expect(find.text('Try 7 days free, then \$29.99/yr'), findsOneWidget);
      await tester.tap(buy);
      await tester.pump();
      expect(till.buys, 2);
    });

    testWidgets('a payment waiting for approval is said as that', (
      tester,
    ) async {
      till.reply.complete(PurchaseOutcome.pending);
      await open(tester, 'journey');
      await tester.tap(buy);
      // The store's answer, then the paywall's way out: half a second of
      // it, as every page leaves.
      await frames(tester, 12);
      expect(
        find.text(
          'Waiting for approval. Astute+ opens as soon as the payment goes '
          'through.',
        ),
        findsOneWidget,
      );
      expect(find.byType(PaywallScreen), findsNothing);
      expect(sink.last('purchase ended')!['outcome'], 'pending');
      expect(sink.last('paywall closed')!['left_by'], 'pending');
    });

    testWidgets('the screen a purchase ends on comes before the plan is '
        'written down', (tester) async {
      final _SlowApp app = _SlowApp();
      till.reply.complete(PurchaseOutcome.bought);
      await open(tester, 'sixth card', app: app);
      await tester.tap(buy);
      // The store's answer, then the fade, a hundred and fifty
      // milliseconds of it.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      expect(app.asked, isTrue);
      expect(app.gate.isCompleted, isFalse);
      expect(find.byType(PurchaseSuccessScreen), findsOneWidget);
      // A free trial is said as one: nothing was bought today.
      expect(find.text('Free trial started.'), findsOneWidget);
      expect(find.text('Purchase complete.'), findsNothing);
      // The reader starts, and the paywall waits for the plan before it
      // goes.
      await frames(tester, 30);
      await tester.tap(find.text('Let’s start'));
      await frames(tester);
      expect(find.byType(PurchaseSuccessScreen), findsNothing);
      expect(find.byType(PaywallScreen), findsOneWidget);
      app.gate.complete();
      await frames(tester, 12);
      expect(app.isPlus, isTrue);
      expect(find.byType(PaywallScreen), findsNothing);
      expect(sink.last('paywall closed')!['left_by'], 'bought');
    });

    testWidgets('a plan charged today is a purchase complete', (tester) async {
      till.answerForTest(offering: _yearAt('\$29.99'));
      till.reply.complete(PurchaseOutcome.bought);
      await open(tester, 'sixth card');
      await tester.tap(buy);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      expect(find.text('Purchase complete.'), findsOneWidget);
      expect(find.text('Free trial started.'), findsNothing);
    });
  });
}

/// A store that answers a purchase when the test says, and counts how often
/// it was asked to start one.
class _Till extends Subscription {
  _Till() : super(keyOverride: '');

  int buys = 0;

  /// Made on first use, inside the test's own clock: one made in setUp
  /// would answer on the real clock, which the test's frames never reach.
  late final Completer<PurchaseOutcome> reply = Completer<PurchaseOutcome>();

  @override
  Future<PurchaseOutcome> buy(Package package) {
    buys += 1;
    return reply.future;
  }
}

/// A reader's state whose plan takes as long to be written down as the test
/// says.
class _SlowApp extends AppState {
  final Completer<void> gate = Completer<void>();
  bool asked = false;

  @override
  Future<void> applyEntitlement(bool active) async {
    asked = true;
    await gate.future;
    await super.applyEntitlement(active);
  }
}
