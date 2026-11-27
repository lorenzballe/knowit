// Photographs the paywall's looks side by side — A, as it ships, and the
// prototypes B, C and D the debug section can put on a phone
// (lib/state/debug_looks.dart) — on the medium phone (390 × 844) at night,
// with the store's plans as the owner sets them: a year at €29,99 with
// fourteen days free, and a month at €3,99.
//
//   PAYWALL_SHOTS=/some/dir flutter test tool/paywall_looks_shots.dart \
//     --update-goldens
//
// A camera, not a check, like the other shots: it lives outside test/ so CI
// never runs it. The pictures land where PAYWALL_SHOTS says, or in
// tool/shots/paywall-looks, which is not kept.
//
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/state/debug_looks.dart';
import 'package:astuto/sync/subscription.dart';
import 'package:astuto/theme.dart';

import '../test/explore/core_harness.dart';

final String _out =
    Platform.environment['PAYWALL_SHOTS'] ?? 'shots/paywall-looks';

Future<void> _settle(WidgetTester tester, [int frames = 30]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

/// The plans as the owner sets them, as the store writes their prices in
/// [locale]'s language: the year with fourteen days free, and the month.
Offering _onSale(Locale locale) {
  final bool comma = const {
    'it',
    'de',
    'fr',
    'es',
    'pt',
    'nl',
    'pl',
    'ru',
    'tr',
  }.contains(locale.languageCode);
  String euros(String whole, String cents) =>
      comma ? '$whole,$cents €' : '€$whole.$cents';
  const context = PresentedOfferingContext('default', null, null);
  final year = Package(
    r'$rc_annual',
    PackageType.annual,
    StoreProduct(
      'astuto_pro_year',
      'Astute+',
      'Astute+',
      29.99,
      euros('29', '99'),
      'EUR',
      introductoryPrice: IntroductoryPrice(
        0,
        euros('0', '00'),
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
    StoreProduct(
      'astuto_pro',
      'Astute+',
      'Astute+',
      3.99,
      euros('3', '99'),
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

void main() {
  late Subscription store;
  final Subscription before = Subscription.instance;
  late bool tools;

  setUpAll(() async {
    await loadFonts();
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
    Remote.baseline = const RemoteConfig(
      hash: 'the-build-own',
      schema: kRemoteSchema,
      parts: {},
    );
    Remote.reset();
  });

  setUp(() {
    tools = debugToolsOn;
    debugToolsOn = true;
    store = Subscription(keyOverride: '');
    Subscription.useForTest(store);
  });

  tearDown(() {
    debugToolsOn = tools;
    DebugLooks.reset();
    Subscription.useForTest(before);
  });

  Future<void> shoot(
    WidgetTester tester,
    String name, {
    PaywallLook look = PaywallLook.a,
    String source = 'see the plans',
    Locale locale = const Locale('it'),
    bool trialUsed = false,
    bool secondStep = false,
    Size phone = const Size(390, 844),
    EdgeInsets insets = const EdgeInsets.only(top: 47, bottom: 34),
    Map<String, Object> prefs = const {},
    double text = 1,
    int frames = 30,
  }) async {
    final view = tester.view;
    view.physicalSize = phone * 3;
    view.devicePixelRatio = 3;
    view.padding = FakeViewPadding(
      top: insets.top * 3,
      bottom: insets.bottom * 3,
    );
    view.viewPadding = view.padding;
    store.answerForTest(
      offering: _onSale(locale),
      yearlyEligibility: trialUsed
          ? IntroEligibilityStatus.introEligibilityStatusIneligible
          : null,
    );
    // The look as the debug section keeps it, read back as the app starts.
    final app = await readyApp({
      'knowit.plus': false,
      'knowit.debug.paywallLook': look.name,
      ...prefs,
    });
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        locale: locale,
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(text)),
            child: PaywallScreen(app: app, source: source),
          ),
        ),
      ),
    );
    await _settle(tester, frames);
    if (secondStep) {
      await tester.tap(find.byKey(const ValueKey('paywall-next')));
      await _settle(tester, 12);
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('$_out/$name.png'),
    );
  }

  /// A reader who wants to decide better and leaned the mix towards
  /// psychology, economics and science: what C opens on.
  final Map<String, Object> decides = {
    'knowit.goals': ['decide'],
    'knowit.topicWeights': jsonEncode({
      'psychology': 1.0,
      'economics': 0.95,
      'science': 0.9,
      'history': 0.5,
      'space': 0.5,
      'technology': 0.45,
      'human_body': 0.4,
      'language': 0.4,
      'philosophy': 0.35,
      'maths': 0.3,
    }),
    'knowit.topics': [
      'psychology',
      'economics',
      'science',
      'history',
      'space',
      'technology',
      'human_body',
      'language',
      'philosophy',
      'maths',
      'thinking',
    ],
  };

  testWidgets('the four looks, with free days and without', (tester) async {
    addTearDown(tester.view.reset);
    for (final bool used in const [false, true]) {
      final String state = used ? 'used' : 'trial';
      await shoot(tester, 'A-$state', trialUsed: used, prefs: decides);
      await shoot(
        tester,
        'B-$state',
        look: PaywallLook.b,
        trialUsed: used,
        prefs: decides,
      );
      await shoot(
        tester,
        'C-$state',
        look: PaywallLook.c,
        trialUsed: used,
        prefs: decides,
      );
      await shoot(
        tester,
        'D1-$state',
        look: PaywallLook.d,
        trialUsed: used,
        prefs: decides,
      );
      await shoot(
        tester,
        'D2-$state',
        look: PaywallLook.d,
        trialUsed: used,
        secondStep: true,
        prefs: decides,
      );
    }
  });

  testWidgets('the edges: a small phone, German, large text, a door', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    for (final PaywallLook look in const [
      PaywallLook.b,
      PaywallLook.c,
      PaywallLook.d,
    ]) {
      final String n = look.name.toUpperCase();
      await shoot(
        tester,
        'edge-$n-se-de',
        look: look,
        locale: const Locale('de'),
        phone: const Size(375, 667),
        insets: const EdgeInsets.only(top: 20),
        prefs: decides,
      );
      await shoot(
        tester,
        'edge-$n-text',
        look: look,
        text: 1.6,
        prefs: decides,
      );
      await shoot(
        tester,
        'edge-$n-sixth',
        look: look,
        source: 'sixth card',
        locale: const Locale('en'),
      );
    }
    await shoot(
      tester,
      'edge-D2-se-de',
      look: PaywallLook.d,
      locale: const Locale('de'),
      phone: const Size(375, 667),
      insets: const EdgeInsets.only(top: 20),
      secondStep: true,
      prefs: decides,
    );
  });
}
