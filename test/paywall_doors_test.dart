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
import 'package:astuto/screens/paywall_screen.dart';
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
  /// plan unless told otherwise. [firstRun] is the onboarding's, with the
  /// way past it written under the offer.
  Future<void> open(
    WidgetTester tester,
    String source, {
    Map<String, Object> prefs = const {},
    bool plus = false,
    Size phone = const Size(390, 844),
    double notch = 47,
    Locale locale = const Locale('en'),
    bool firstRun = false,
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
    final app = AppState();
    await app.init();
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        // A paywall of its own each time, as every push is: one opened
        // over another in the same test would keep the first one's state.
        home: PaywallScreen(
          key: UniqueKey(),
          app: app,
          source: source,
          onClose: firstRun ? () {} : null,
        ),
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
      ('onboarding', outcome, 'B'),
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
          'store_answered': false,
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
      await open(tester, 'onboarding');
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
        for (final (String source, Map<String, Object> prefs, bool firstRun)
            in [
              ('journey', const <String, Object>{}, false),
              ('journey', _judged(12, sure: 80, right: 7), false),
              ('sixth card', const <String, Object>{}, false),
              ('archive', const <String, Object>{}, false),
              ('see the plans', const <String, Object>{}, false),
              ('onboarding', const <String, Object>{}, true),
            ]) {
          await open(
            tester,
            source,
            prefs: prefs,
            phone: const Size(375, 667),
            notch: 20,
            locale: locale,
            firstRun: firstRun,
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
          expect(find.byType(Scrollable), findsNothing);
        }
      });
    }
  });

  group('a trial is told as its days', () {
    final Finder timeline = find.byKey(const ValueKey('paywall-trial'));

    testWidgets('before the store answers: the plan as sold, two weeks', (
      tester,
    ) async {
      await open(tester, 'onboarding');
      expect(timeline, findsOneWidget);
      for (final String step in const [
        'Today · all of Astute+, free',
        'Day 12 · we remind you',
        'Day 14 · €29,99 for a year, unless you cancel',
      ]) {
        expect(
          find.descendant(of: timeline, matching: find.text(step)),
          findsOneWidget,
        );
      }
      // Said once: the days say what "no charge today" used to.
      expect(find.textContaining('No charge today'), findsNothing);
    });

    testWidgets('the store\'s own days and its own price', (tester) async {
      store.answerForTest(
        offering: _yearAt('\$29.99', intro: _freeFor(PeriodUnit.week, 1)),
      );
      await open(tester, 'journey');
      expect(find.text('Day 5 · we remind you'), findsOneWidget);
      expect(
        find.text('Day 7 · \$29.99 for a year, unless you cancel'),
        findsOneWidget,
      );
      expect(find.textContaining('€29,99 for a year'), findsNothing);
    });

    testWidgets('a trial too short for a reminder has no day for it', (
      tester,
    ) async {
      store.answerForTest(
        offering: _yearAt('\$29.99', intro: _freeFor(PeriodUnit.day, 2)),
      );
      await open(tester, 'archive');
      expect(timeline, findsOneWidget);
      expect(find.textContaining('we remind you'), findsNothing);
      expect(
        find.text('Day 2 · \$29.99 for a year, unless you cancel'),
        findsOneWidget,
      );
    });

    testWidgets('no trial on sale, none shown', (tester) async {
      store.answerForTest(offering: _yearAt('\$29.99'));
      await open(tester, 'sixth card');
      expect(timeline, findsNothing);
      expect(find.text('Charged today · cancel any time'), findsOneWidget);
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
        find.text('Cancel any time · No payment is taken in this build'),
        findsOneWidget,
      );
    });

    testWidgets('none for a reader already on Astute+', (tester) async {
      await open(tester, 'manage plan', plus: true);
      expect(timeline, findsNothing);
    });
  });
}
