// Photographs the first week's page and the first month's
// (lib/screens/first_offer.dart) as the developer tools preview them, with
// their sample numbers: in Italian and English, at night and by day, on the
// smallest phone (375 × 667, an iPhone SE) and a large one (430 × 932); and
// the foot of the profile, where the two previews are opened from.
//
//   FIRST_OFFER_SHOTS=/some/dir flutter test tool/first_offer_shots.dart \
//     --update-goldens
//
// A camera, not a check, like the other shots: it lives outside test/ so CI
// never runs it. The pictures land where FIRST_OFFER_SHOTS says, or in the
// gallery, which is not kept.
//
// The store is a stand-in holding the plans as the owner sets them — a year
// at €29,99 with fourteen days free, a month at €3,99 — written as the App
// Store writes a price in each language. The app reads whatever the store
// says, here as on a phone; nothing in it knows these prices.
//
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/daily.dart' show dealDay;
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/first_offers.dart';
import 'package:astuto/sync/subscription.dart';
import 'package:astuto/theme.dart';

import '../test/explore/core_harness.dart' show loadFonts;

final String _out =
    Platform.environment['FIRST_OFFER_SHOTS'] ?? 'shots/gallery/first-offer';

/// The two phones, each with its own insets, three pixels a point.
const Map<String, (Size, EdgeInsets)> _phones = {
  'small': (Size(375, 667), EdgeInsets.only(top: 20)),
  'large': (Size(430, 932), EdgeInsets.only(top: 59, bottom: 34)),
};
const double _ratio = 3;

/// The plans as the owner sets them, as the App Store writes their prices
/// in [locale]'s language.
Offering _onSale(Locale locale) {
  final bool it = locale.languageCode == 'it';
  const context = PresentedOfferingContext('default', null, null);
  final year = Package(
    r'$rc_annual',
    PackageType.annual,
    StoreProduct(
      'com.astuto.app.plus.yearly',
      'Astute+',
      'Astute+',
      29.99,
      it ? '29,99 €' : '€29.99',
      'EUR',
      introductoryPrice: IntroductoryPrice(
        0,
        it ? '0,00 €' : '€0.00',
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
      'com.astuto.app.plus.monthly',
      'Astute+',
      'Astute+',
      3.99,
      it ? '3,99 €' : '€3.99',
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

Future<void> _settle(WidgetTester tester, [int frames = 14]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

/// The date key [back] days before today, on the calendar.
String _day(int back) {
  final DateTime now = DateTime.now();
  return dateKey(DateTime(now.year, now.month, now.day - back));
}

void main() {
  setUpAll(() async {
    await loadFonts();
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
  });

  final Subscription before = Subscription.instance;

  /// The phone [phone], in [locale]'s language, the store's plans on sale.
  void phoneIn(WidgetTester tester, String phone, Locale locale) {
    final (Size size, EdgeInsets insets) = _phones[phone]!;
    final view = tester.view;
    view.physicalSize = size * _ratio;
    view.devicePixelRatio = _ratio;
    view.padding = FakeViewPadding(
      top: insets.top * _ratio,
      bottom: insets.bottom * _ratio,
    );
    view.viewPadding = view.padding;
    tester.platformDispatcher.localesTestValue = [locale];
    tester.platformDispatcher.localeTestValue = locale;
    addTearDown(() {
      view.reset();
      tester.platformDispatcher.clearLocalesTestValue();
      tester.platformDispatcher.clearLocaleTestValue();
      Subscription.useForTest(before);
      Remote.reset();
    });
    Subscription.useForTest(
      Subscription(keyOverride: '')
        ..answerForTest(offering: _onSale(locale))
        ..holdForTest(null),
    );
  }

  for (final FirstOffer which in FirstOffer.values) {
    for (final Locale locale in const [Locale('it'), Locale('en')]) {
      for (final Brightness light in Brightness.values) {
        for (final String phone in _phones.keys) {
          final String name =
              '${which.name}-${locale.languageCode}-'
              '${light == Brightness.dark ? 'dark' : 'light'}-$phone';
          testWidgets(name, (tester) async {
            phoneIn(tester, phone, locale);
            // A reader not yet asked about reminders: the trial's days say
            // the one sent two days before the charge.
            SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
            final AppState app = AppState(
              hasPermission: () async => true,
              askPermission: () async => true,
              arm: (_) async {},
              disarm: () async {},
              pushWidget: (_) async {},
            );
            await app.init();
            await tester.pumpWidget(
              MaterialApp(
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: buildAstutoTheme(light),
                debugShowCheckedModeBanner: false,
                home: FirstOfferScreen(
                  app: app,
                  which: which,
                  numbers: FirstOfferNumbers.sample(which),
                  preview: true,
                ),
              ),
            );
            await _settle(tester);
            await expectLater(
              find.byType(MaterialApp).first,
              matchesGoldenFile('$_out/$name.png'),
            );
            await tester.pumpWidget(const SizedBox());
          });
        }
      }
    }
  }

  testWidgets('debug-buttons', (tester) async {
    final bool tools = debugToolsOn;
    debugToolsOn = true;
    addTearDown(() => debugToolsOn = tools);
    phoneIn(tester, 'large', const Locale('it'));
    final List<String> deck = dealDay(date: DateTime.now()).cards
        .take(kPillsPerDay)
        .map((p) => p.id)
        .toList();
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      'knowit.pushAsked': true,
      'knowit.widgetAsked': true,
      'knowit.accountOffered': true,
      'knowit.reviewAsked': true,
      'knowit.goalAsked': true,
      'knowit.placeAsks': 9,
      'knowit.todayDate': _day(0),
      'knowit.todayDeckIds': deck,
      'knowit.todayIndex': deck.length,
      'knowit.streak': 3,
      'knowit.lastCompletionDate': _day(0),
      'knowit.completedDates': [_day(2), _day(1), _day(0)],
      'knowit.seenIds': deck,
    });
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester, 20);
    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await _settle(tester);
    final Finder list = find
        .descendant(
          of: find.byType(ProfileScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    final Finder paywall = find.byKey(const ValueKey('debug-open-paywall'));
    await tester.scrollUntilVisible(paywall, 400, scrollable: list);
    await _settle(tester, 4);
    // "Open the paywall" a little under the top, the two previews under it.
    await tester.drag(list, Offset(0, 260 - tester.getTopLeft(paywall).dy));
    await _settle(tester, 8);
    expect(find.byKey(const ValueKey('debug-first-week')), findsOneWidget);
    expect(find.byKey(const ValueKey('debug-first-month')), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp).first,
      matchesGoldenFile('$_out/debug-buttons.png'),
    );
    // And what the first of them opens.
    await tester.tap(find.byKey(const ValueKey('debug-first-week')));
    await _settle(tester, 14);
    expect(find.byKey(const ValueKey('first-offer')), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp).first,
      matchesGoldenFile('$_out/debug-opened.png'),
    );
    await tester.pumpWidget(const SizedBox());
  });
}
