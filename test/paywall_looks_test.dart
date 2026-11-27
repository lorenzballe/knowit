// The paywall's prototypes, B, C and D, which the developer tools put on a
// phone in place of A (lib/screens/paywall_looks.dart, DebugLooks.paywall):
// A with the app's own cards for the marks and the free days laid out over
// the button; C opening on the reader's goal and subjects; D in two steps.
// Each holds what A holds on every door — every feature with its line, the
// plans, the button, the links — on a free reader, on one the store gives no
// free days to, in a long language, at a large text size and on a small
// phone. A stays the paywall as it ships, and a build without the tools
// never shows another.
//
//   flutter test test/paywall_looks_test.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/debug_flags.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/debug_looks.dart';
import 'package:astuto/sync/subscription.dart';
import 'package:astuto/theme.dart';

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

/// The plans as the store hands them over: a year at a price the app never
/// writes itself, with fourteen days free, and a month.
Offering _onSale() {
  const context = PresentedOfferingContext('default', null, null);
  final year = Package(
    r'$rc_annual',
    PackageType.annual,
    StoreProduct(
      'astuto_pro_year',
      'Astute+',
      'Astute+',
      29.99,
      r'$29.99',
      'USD',
      introductoryPrice: IntroductoryPrice(
        0,
        r'$0.00',
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
    StoreProduct('astuto_pro', 'Astute+', 'Astute+', 3.99, r'$3.99', 'USD'),
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

/// A reader who wants to decide better, and leaned the mix towards
/// psychology, economics and science.
final Map<String, Object> _decides = {
  'knowit.goals': ['decide'],
  'knowit.topicWeights': jsonEncode({
    'psychology': 1.0,
    'economics': 0.95,
    'science': 0.9,
    'history': 0.5,
    'space': 0.4,
  }),
  'knowit.topics': [
    'psychology',
    'economics',
    'science',
    'history',
    'space',
    'thinking',
  ],
};

/// A store that counts the purchases it is asked to start, and never
/// answers them.
class _Till extends Subscription {
  _Till() : super(keyOverride: '');

  int buys = 0;

  @override
  Future<PurchaseOutcome> buy(Package package) {
    buys += 1;
    // The store's sheet stays up: no answer, and no timer left behind.
    return Completer<PurchaseOutcome>().future;
  }
}

void main() {
  late _Till store;
  final Subscription before = Subscription.instance;
  late bool tools;

  setUpAll(_loadRealFonts);

  setUp(() {
    tools = debugToolsOn;
    debugToolsOn = true;
    store = _Till();
    Subscription.useForTest(store);
  });

  tearDown(() {
    debugToolsOn = tools;
    DebugLooks.reset();
    Subscription.useForTest(before);
  });

  /// The paywall as [source] opens it, in [look], pushed over a screen of its
  /// own as every door pushes it.
  Future<AppState> open(
    WidgetTester tester,
    PaywallLook look, {
    String source = 'see the plans',
    Map<String, Object> prefs = const {},
    bool plus = false,
    Size phone = const Size(390, 844),
    double notch = 47,
    double homeBar = 34,
    Locale locale = const Locale('en'),
    double text = 1,
  }) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = FakeViewPadding(top: notch, bottom: homeBar);
    tester.view.viewPadding = FakeViewPadding(top: notch, bottom: homeBar);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      'knowit.plus': plus,
      'knowit.debug.paywallLook': look.name,
      ...prefs,
    });
    final AppState reader = AppState();
    await reader.init();
    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        navigatorKey: navigator,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: const Scaffold(body: Text('Under the paywall')),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(text)),
          child: child!,
        ),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => PaywallScreen(app: reader, source: source),
      ),
    );
    await frames(tester);
    return reader;
  }

  final Finder rail = find.byKey(const ValueKey('paywall-rail'));
  final Finder buy = find.byKey(const ValueKey('paywall-buy'));
  final Finder next = find.byKey(const ValueKey('paywall-next'));
  final Finder sheet = find.byKey(const ValueKey('paywall-sheet'));
  final Finder cards = find.byKey(const ValueKey('paywall-cards'));
  final Finder features = find.byKey(const ValueKey('paywall-features'));

  String headline(WidgetTester tester) => tester
      .widgetList<RichText>(
        find.descendant(
          of: find.byKey(const ValueKey('paywall-headline')),
          matching: find.byType(RichText),
        ),
      )
      .first
      .text
      .toPlainText();

  test('A is the paywall as it ships, and a look kept by a build with the '
      'tools is never read by one without them', () async {
    SharedPreferences.setMockInitialValues({'knowit.debug.paywallLook': 'c'});
    DebugLooks.load(await SharedPreferences.getInstance());
    expect(DebugLooks.paywall.value, PaywallLook.c);
    debugToolsOn = false;
    expect(DebugLooks.paywallPicked, PaywallLook.a);
    debugToolsOn = true;
    expect(DebugLooks.paywallPicked, PaywallLook.c);
    DebugLooks.reset();
    expect(DebugLooks.paywallPicked, PaywallLook.a);
  });

  testWidgets('without the tools, a kept look still opens on A', (
    tester,
  ) async {
    debugToolsOn = false;
    await open(tester, PaywallLook.b);
    expect(features, findsNothing);
    expect(rail, findsNothing);
    // A's own list: the day's five is there whatever the AI switch says
    // (the assistant and the coach show only where it is on).
    expect(find.byKey(const ValueKey('paywall-feature-five')), findsOneWidget);
    expect(buy, findsOneWidget);
  });

  group('every look holds everything A holds, on one screen', () {
    for (final PaywallLook look in const [
      PaywallLook.b,
      PaywallLook.c,
      PaywallLook.d,
    ]) {
      testWidgets(look.name, (tester) async {
        store.answerForTest(offering: _onSale());
        final l = lookupAppLocalizations(const Locale('en'));
        await open(tester, look);
        expect(tester.takeException(), isNull);
        for (final String words in [
          l.perkAskTitle,
          l.perkAskLine,
          l.perkCoachTitle,
          l.perkCoachLine,
          l.perkOwnFiveTitle,
          l.perkFiveShort,
          l.perkShelvesTitle,
          l.perkShelvesLine,
          l.perkGapTitle,
          l.perkGapShort,
          l.perkReadTitle,
          l.perkReadShort,
        ]) {
          expect(find.text(words), findsOneWidget, reason: words);
          // All of it on the screen: nothing under the fold of a common
          // phone.
          expect(
            tester.getBottomLeft(find.text(words)).dy,
            lessThan(844),
            reason: words,
          );
        }
        expect(find.text('NEW'), findsNWidgets(2));
        expect(find.text(l.restorePurchases), findsOneWidget);
        expect(find.text(l.termsOfUse), findsOneWidget);
        expect(find.text(l.privacyPolicy), findsOneWidget);
        expect(
          tester.getBottomLeft(find.text(l.restorePurchases)).dy,
          lessThanOrEqualTo(844),
        );
        // The real cards: as the features' marks in B and C, drifting in a
        // row of their own in D.
        if (look == PaywallLook.d) {
          expect(cards, findsOneWidget);
          expect(next, findsOneWidget);
          expect(buy, findsNothing);
          expect(find.text('Yearly'), findsNothing);
        } else {
          expect(cards, findsNothing);
          expect(buy, findsOneWidget);
          expect(find.text('Yearly'), findsOneWidget);
          expect(find.text('Monthly'), findsOneWidget);
        }
        expect(
          find.descendant(of: features, matching: find.byType(Text)),
          findsWidgets,
        );
      });
    }
  });

  group('the free days, day by day, at the store’s own price', () {
    testWidgets('B: today, the reminder, and the day the year starts, over '
        'a button that says the same', (tester) async {
      store.answerForTest(offering: _onSale());
      await open(tester, PaywallLook.b);
      expect(rail, findsOneWidget);
      final l = lookupAppLocalizations(const Locale('en'));
      expect(
        find.descendant(of: rail, matching: find.text(l.trialStepToday)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: rail, matching: find.text(l.paywallStepFree)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: rail, matching: find.text(l.paywallStepRemind)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: rail, matching: find.text(r'$29.99/yr')),
        findsOneWidget,
      );
      expect(find.text(r'Try 14 days free, then $29.99/yr'), findsOneWidget);
      expect(find.text('Cancel any time'), findsOneWidget);
      // Over the button it explains.
      expect(
        tester.getBottomLeft(rail).dy,
        lessThan(tester.getTopLeft(buy).dy),
      );
    });

    testWidgets('the month, charged today: the days go, and the line under '
        'the button says so', (tester) async {
      store.answerForTest(offering: _onSale());
      await open(tester, PaywallLook.b);
      await tester.tap(find.text('Monthly'));
      await frames(tester);
      expect(rail, findsNothing);
      expect(find.text(r'Subscribe for $3.99/mo'), findsOneWidget);
      expect(find.text('Charged today · Cancel any time'), findsOneWidget);
      await tester.tap(find.text('Yearly'));
      await frames(tester);
      expect(rail, findsOneWidget);
    });

    testWidgets('no reminder promised where none can reach the reader', (
      tester,
    ) async {
      store.answerForTest(offering: _onSale());
      await open(
        tester,
        PaywallLook.b,
        prefs: const {'knowit.pushAsked': true},
      );
      final l = lookupAppLocalizations(const Locale('en'));
      expect(rail, findsOneWidget);
      expect(find.text(l.paywallStepRemind), findsNothing);
    });

    for (final PaywallLook look in const [
      PaywallLook.b,
      PaywallLook.c,
      PaywallLook.d,
    ]) {
      testWidgets('${look.name}: a reader the store gives no free days to is '
          'told what is charged, and promised no free day', (tester) async {
        store.answerForTest(
          offering: _onSale(),
          yearlyEligibility:
              IntroEligibilityStatus.introEligibilityStatusIneligible,
        );
        await open(tester, look);
        if (look == PaywallLook.d) {
          expect(find.text('See the plans'), findsOneWidget);
          await tester.tap(next);
          await frames(tester);
          expect(sheet, findsOneWidget);
          expect(find.byKey(const ValueKey('paywall-days')), findsNothing);
        }
        expect(rail, findsNothing);
        expect(find.textContaining('free'), findsNothing);
        expect(find.text(r'Subscribe for $29.99/yr'), findsOneWidget);
        expect(find.text('Charged today · Cancel any time'), findsOneWidget);
      });
    }
  });

  group('C opens on the reader', () {
    testWidgets('their goal in the headline, their subjects in the line', (
      tester,
    ) async {
      await open(tester, PaywallLook.c, prefs: _decides);
      expect(headline(tester), 'For people who want to decide better.');
      expect(
        find.textContaining('from Psychology, Economics and Science'),
        findsOneWidget,
      );
      // The word it leans on is painted, and only that.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('paywall-headline')),
          matching: find.byType(ShaderMask),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a reader who told it nothing: the door’s own words', (
      tester,
    ) async {
      await open(tester, PaywallLook.c);
      expect(headline(tester), 'Be the one nobody fools.');
      expect(
        find.textContaining('Five cards a day at your level.'),
        findsOneWidget,
      );
    });

    testWidgets('a door reached for one thing still opens on that thing', (
      tester,
    ) async {
      await open(tester, PaywallLook.c, source: 'journey', prefs: _decides);
      expect(headline(tester), 'See how much you really know.');
      await open(tester, PaywallLook.c, source: 'sixth card', prefs: _decides);
      expect(headline(tester), 'All five, yours.');
    });

    testWidgets('B, the same reader: the door’s own words', (tester) async {
      await open(tester, PaywallLook.b, prefs: _decides);
      expect(headline(tester), 'Be the one nobody fools.');
    });

    test('the subjects a reader leaned towards: the few set above the rest, '
        'or none', () async {
      Future<List<String>> leaning(Map<String, double>? weights) async {
        SharedPreferences.setMockInitialValues({
          'knowit.onboarded': true,
          if (weights != null) 'knowit.topicWeights': jsonEncode(weights),
        });
        final AppState app = AppState();
        await app.init();
        return leaningSubjects(app);
      }

      expect(await leaning(null), isEmpty);
      // The wheel as it comes: every subject all the way in.
      expect(
        await leaning({
          for (final k in ['science', 'space', 'art']) k: 1.0,
        }),
        ['science', 'space', 'art'],
      );
      expect(
        await leaning({
          for (final k in ['science', 'space', 'art', 'music']) k: 1.0,
        }),
        isEmpty,
      );
      expect(
        await leaning({
          'psychology': 1.0,
          'economics': 0.9,
          'science': 0.8,
          'space': 0.4,
          'art': 0.4,
        }),
        ['psychology', 'economics', 'science'],
      );
      expect(
        await leaning({
          'psychology': 1.0,
          'economics': 1.0,
          'science': 0.5,
          'space': 0.5,
          'art': 0.5,
        }),
        ['psychology', 'economics'],
      );
    });
  });

  group('D, in two steps', () {
    testWidgets('the plans come up over the page, and go down again before '
        'the paywall does', (tester) async {
      store.answerForTest(offering: _onSale());
      await open(tester, PaywallLook.d);
      expect(find.text('Start the free trial'), findsOneWidget);
      expect(sheet, findsNothing);
      await tester.tap(next);
      await frames(tester);
      expect(sheet, findsOneWidget);
      expect(find.byKey(const ValueKey('paywall-days')), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);
      expect(find.text(r'Try 14 days free, then $29.99/yr'), findsOneWidget);
      // The sheet whole on the screen, the button in it.
      expect(tester.getBottomLeft(buy).dy, lessThanOrEqualTo(844));
      // A tap on the page lowers it.
      await tester.tapAt(const Offset(195, 120));
      await frames(tester);
      expect(sheet, findsNothing);
      // Up again, the back gesture lowers it first, and then leaves.
      await tester.tap(next);
      await frames(tester);
      await tester.binding.handlePopRoute();
      await frames(tester);
      expect(sheet, findsNothing);
      expect(find.byType(PaywallScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await frames(tester);
      expect(find.byType(PaywallScreen), findsNothing);
    });

    testWidgets('the button in the sheet buys, once', (tester) async {
      store.answerForTest(offering: _onSale());
      await open(tester, PaywallLook.d);
      await tester.tap(next);
      await frames(tester);
      await tester.tap(buy);
      await tester.pump();
      await tester.tap(buy, warnIfMissed: false);
      await tester.pump();
      expect(store.buys, 1);
      expect(find.text('One moment…'), findsOneWidget);
    });
  });

  testWidgets('B and C buy from their own button, once', (tester) async {
    store.answerForTest(offering: _onSale());
    for (final PaywallLook look in const [PaywallLook.b, PaywallLook.c]) {
      store.buys = 0;
      await open(tester, look);
      await tester.tap(buy);
      await tester.pump();
      await tester.tap(buy, warnIfMissed: false);
      await tester.pump();
      expect(store.buys, 1, reason: look.name);
    }
  });

  testWidgets('a reader already on Astute+: the plan is theirs, and the '
      'store’s place for it', (tester) async {
    store.answerForTest(offering: _onSale());
    for (final PaywallLook look in const [
      PaywallLook.b,
      PaywallLook.c,
      PaywallLook.d,
    ]) {
      await open(tester, look, plus: true);
      expect(find.text('ASTUTE+ IS ACTIVE'), findsOneWidget, reason: look.name);
      expect(find.text('Manage subscription'), findsOneWidget);
      expect(rail, findsNothing);
    }
  });

  group('a store build shows only the prices the store gave', () {
    final bool preview = Subscription.previewWithoutStore;
    setUp(() => Subscription.previewWithoutStore = false);
    tearDown(() => Subscription.previewWithoutStore = preview);

    for (final PaywallLook look in const [
      PaywallLook.b,
      PaywallLook.c,
      PaywallLook.d,
    ]) {
      testWidgets(look.name, (tester) async {
        await open(tester, look);
        expect(find.byKey(const ValueKey('paywall-store')), findsOneWidget);
        expect(find.textContaining(r'$'), findsNothing);
        expect(buy, findsNothing);
        expect(next, findsNothing);
        expect(rail, findsNothing);
        expect(find.text('Restore purchases'), findsOneWidget);
        expect(find.text('Terms of Use'), findsOneWidget);
        expect(find.text('Privacy Policy'), findsOneWidget);
      });
    }
  });

  group('a small phone, a long language, every door', () {
    for (final PaywallLook look in const [
      PaywallLook.b,
      PaywallLook.c,
      PaywallLook.d,
    ]) {
      testWidgets(look.name, (tester) async {
        store.answerForTest(offering: _onSale());
        const Locale de = Locale('de');
        final l = lookupAppLocalizations(de);
        for (final String source in const [
          'see the plans',
          'journey',
          'sixth card',
          'archive',
          'paths',
          'deeper why',
        ]) {
          await open(
            tester,
            look,
            source: source,
            prefs: _decides,
            phone: const Size(375, 667),
            notch: 20,
            homeBar: 0,
            locale: de,
          );
          expect(tester.takeException(), isNull, reason: source);
          for (final String words in [
            l.perkAskTitle,
            l.perkAskLine,
            l.perkCoachTitle,
            l.perkCoachLine,
            l.perkOwnFiveTitle,
            l.perkFiveShort,
            l.perkShelvesTitle,
            l.perkShelvesLine,
            l.perkGapTitle,
            l.perkGapShort,
            l.perkReadTitle,
            l.perkReadShort,
          ]) {
            expect(find.text(words), findsOneWidget, reason: '$source $words');
          }
          // The way on, and what Apple asks for, on the screen.
          final Finder press = look == PaywallLook.d ? next : buy;
          expect(
            tester.getBottomLeft(press).dy,
            lessThanOrEqualTo(667),
            reason: source,
          );
          expect(
            tester.getBottomLeft(find.text(l.restorePurchases)).dy,
            lessThanOrEqualTo(667),
            reason: source,
          );
          if (look == PaywallLook.d) {
            await tester.tap(next);
            await frames(tester);
            expect(tester.takeException(), isNull, reason: source);
            expect(
              tester.getBottomLeft(buy).dy,
              lessThanOrEqualTo(667),
              reason: source,
            );
          }
        }
      });
    }
  });

  group('large text: one page that scrolls, nothing cut', () {
    for (final PaywallLook look in const [
      PaywallLook.b,
      PaywallLook.c,
      PaywallLook.d,
    ]) {
      for (final double text in const [1.6, 2.0]) {
        testWidgets('${look.name} at $text', (tester) async {
          store.answerForTest(offering: _onSale());
          await open(
            tester,
            look,
            text: text,
            prefs: _decides,
            locale: const Locale('de'),
          );
          expect(tester.takeException(), isNull);
          final l = lookupAppLocalizations(const Locale('de'));
          expect(find.text(l.perkReadShort), findsOneWidget);
          if (look == PaywallLook.d) {
            // At the foot of the page that scrolls.
            await tester.ensureVisible(next);
            await frames(tester, 2);
            await tester.tap(next);
            await frames(tester);
            expect(tester.takeException(), isNull);
          }
          expect(buy, findsOneWidget);
        });
      }
    }
  });
}

Future<void> frames(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
