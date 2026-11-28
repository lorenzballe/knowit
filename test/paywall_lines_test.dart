// The paywall's two lines (look C, the one that ships): what holds up of
// the evidence for calibration, with its source and no percentage, and,
// under the button, that the app warns two days before a trial's charge —
// said only where it is true: a plan that starts with free days, to a
// reader the app can notify. The web's word on where the app is. And the
// saving the year's tile says, worked out from the store's two prices.
//
//   flutter test test/paywall_lines_test.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/store_links.dart';
import 'package:astuto/sync/subscription.dart';
import 'package:astuto/theme.dart';

final AppLocalizations _en = lookupAppLocalizations(const Locale('en'));

/// The year and the month as the store hands them over, at [year] and
/// [month], the year with two weeks free unless [trial] says not.
Offering _onSale({
  double year = 29.99,
  double month = 3.99,
  bool trial = true,
}) {
  const context = PresentedOfferingContext('default', null, null);
  final yearly = Package(
    r'$rc_annual',
    PackageType.annual,
    StoreProduct(
      'com.astuto.app.plus.yearly',
      'Astute+',
      'Astute+',
      year,
      '€${year.toStringAsFixed(2)}',
      'EUR',
      introductoryPrice: trial
          ? const IntroductoryPrice(0, '€0.00', 'P2W', 1, PeriodUnit.week, 2)
          : null,
    ),
    context,
  );
  final monthly = Package(
    r'$rc_monthly',
    PackageType.monthly,
    StoreProduct(
      'com.astuto.app.plus.monthly',
      'Astute+',
      'Astute+',
      month,
      '€${month.toStringAsFixed(2)}',
      'EUR',
    ),
    context,
  );
  return Offering(
    'default',
    '',
    const {},
    [yearly, monthly],
    annual: yearly,
    monthly: monthly,
  );
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

void main() {
  late Subscription store;
  final Subscription before = Subscription.instance;

  setUpAll(_loadRealFonts);

  setUp(() {
    Remote.reset();
    store = Subscription(keyOverride: '');
    store.answerForTest(offering: _onSale());
    Subscription.useForTest(store);
  });

  tearDown(() {
    Subscription.useForTest(before);
    Remote.reset();
  });

  /// The paywall from [source], for a reader on the free plan whose phone
  /// lets the app notify them when [notifies] says so; [asked] says the
  /// system's question was put.
  Future<AppState> open(
    WidgetTester tester, {
    bool notifies = true,
    bool asked = true,
    Size phone = const Size(390, 844),
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      'knowit.plus': false,
      'knowit.pushAsked': asked,
    });
    final AppState app = AppState(
      hasPermission: () async => notifies,
      askPermission: () async => notifies,
      arm: (_) async {},
      disarm: () async {},
      pushWidget: (_) async {},
    );
    await app.init();
    app.notificationsAllowed = notifies;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: PaywallScreen(app: app, source: 'see the plans'),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return app;
  }

  final Finder under = find.byKey(const ValueKey('paywall-cancel'));

  group('the line on the evidence', () {
    testWidgets('says what holds up, with its source, and no figure', (
      tester,
    ) async {
      await open(tester);
      final Finder science = find.byKey(const ValueKey('paywall-science'));
      expect(science, findsOneWidget);
      final String said = tester
          .widget<Text>(
            find.descendant(of: science, matching: find.byType(Text)),
          )
          .textSpan!
          .toPlainText();
      expect(said, contains(_en.paywallScience));
      expect(said, contains(_en.paywallScienceSource));
      expect(said, contains('Tetlock'));
      expect(said, contains('Mellers'));
      // No percentage, nor any other number, in any language: the size of
      // the training effect is disputed.
      for (final Locale locale in AppLocalizations.supportedLocales) {
        final AppLocalizations l = lookupAppLocalizations(locale);
        expect(
          l.paywallScience,
          isNot(matches(RegExp(r'[0-9%٪]'))),
          reason: locale.languageCode,
        );
      }
    });

    testWidgets('and holds on a small phone in German', (tester) async {
      await open(
        tester,
        phone: const Size(320, 568),
        locale: const Locale('de'),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('paywall-science')), findsOneWidget);
      expect(find.byKey(const ValueKey('paywall-buy')), findsOneWidget);
    });
  });

  group('the warning before the charge', () {
    test('two days, the day the app\'s own warning comes', () {
      // The line says "two" in words; the warning is armed for this day.
      expect(AppState.kTrialWarningDays, 2);
      expect(_en.paywallWarnBefore, 'We warn you two days before the charge');
    });

    testWidgets('under the button, beside the way out, on a plan that '
        'starts with free days', (tester) async {
      await open(tester);
      expect(
        find.descendant(of: under, matching: find.text(_en.paywallWarnBefore)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: under, matching: find.text(_en.cancelAnyTime)),
        findsOneWidget,
      );
    });

    testWidgets('not on a plan charged today', (tester) async {
      await open(tester);
      await tester.tap(find.text(_en.planMonthly));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text(_en.paywallWarnBefore), findsNothing);
      expect(
        find.descendant(
          of: under,
          matching: find.text(_en.paywallChargedToday),
        ),
        findsOneWidget,
      );
    });

    testWidgets('not to a reader the app cannot notify', (tester) async {
      await open(tester, notifies: false, asked: true);
      expect(find.text(_en.paywallWarnBefore), findsNothing);
      expect(find.text(_en.cancelAnyTime), findsOneWidget);
    });

    testWidgets('promised to one not asked yet: the sheet asks once the '
        'trial has started', (tester) async {
      await open(tester, notifies: false, asked: false);
      expect(find.text(_en.paywallWarnBefore), findsOneWidget);
    });

    testWidgets('not where the store gives no free days', (tester) async {
      store.answerForTest(offering: _onSale(trial: false));
      await open(tester);
      expect(find.text(_en.paywallWarnBefore), findsNothing);
    });
  });

  group('the saving the year says', () {
    test('worked out from the store\'s two prices, never written in', () {
      store.answerForTest(offering: _onSale(year: 29.99, month: 3.99));
      expect(yearlySaving(), 37);
      // A price changed in the store says its own saving at once.
      store.answerForTest(offering: _onSale(year: 29.99, month: 4.99));
      expect(yearlySaving(), 50);
      store.answerForTest(offering: _onSale(year: 24.99, month: 5.99));
      expect(yearlySaving(), 65);
      // A year that saves nothing claims nothing.
      store.answerForTest(offering: _onSale(year: 59.99, month: 4.99));
      expect(yearlySaving(), isNull);
    });

    testWidgets('and the tile says it', (tester) async {
      store.answerForTest(offering: _onSale(year: 29.99, month: 5.99));
      await open(tester);
      expect(find.text(_en.savePercent(58)), findsOneWidget);
      expect(find.text(_en.savePercent(37)), findsNothing);
    });
  });

  group('the web\'s word on where the app is', () {
    test('Android now, the iPhone on its way, as the site says it', () {
      // lib/store_links.dart, held to tool/site/chrome.py by
      // tool/remote/test_app.py.
      expect(kGooglePlayOpen, isTrue);
      expect(kAppStoreOpen, isFalse);
      for (final Locale locale in AppLocalizations.supportedLocales) {
        final AppLocalizations l = lookupAppLocalizations(locale);
        final String code = locale.languageCode;
        // Where to get it now: Android; the iPhone said as coming, never
        // offered beside it.
        expect(l.plusInTheAppAndroid, contains('Android'), reason: code);
        expect(l.plusInTheAppAndroid, contains('iPhone'), reason: code);
        expect(
          l.plusInTheAppAndroid,
          isNot(contains(l.plusInTheApp)),
          reason: code,
        );
      }
      expect(_en.plusInTheAppAndroid, contains('coming to iPhone'));
      expect(_en.plusInTheAppAndroid, isNot(contains('iPhone or')));
    });
  });
}
