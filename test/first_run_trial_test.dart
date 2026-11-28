// The first run's free trial, behind the server's switch `trial.firstRun`:
// after the onboarding, one real card, then the offer, then the day's five.
// Off as built, and then the first run is what it always was.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/first_days.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/first_card_screen.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/screens/purchase_success_screen.dart';
import 'package:astuto/screens/today_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/subscription.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

final AppLocalizations _en = lookupAppLocalizations(const Locale('en'));

/// The store as the owner sets it: a year at €39.99 with two weeks free,
/// and a month at €4.99.
Offering _onSale() {
  const context = PresentedOfferingContext('default', null, null);
  final year = Package(
    r'$rc_annual',
    PackageType.annual,
    const StoreProduct(
      'com.astuto.app.plus.yearly',
      'Astute+',
      'Astute+',
      39.99,
      '€39.99',
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
      4.99,
      '€4.99',
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

/// Astute+ as RevenueCat describes it: the year, in its free trial unless
/// told otherwise, ending in two weeks.
EntitlementInfo _plus({PeriodType period = PeriodType.trial}) =>
    EntitlementInfo(
      kPlusEntitlement,
      true,
      true,
      DateTime.now().toUtc().toIso8601String(),
      DateTime.now().toUtc().toIso8601String(),
      'com.astuto.app.plus.yearly',
      true,
      periodType: period,
      expirationDate: DateTime.now()
          .add(const Duration(days: 14))
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
    holdForTest(_plus());
    return PurchaseOutcome.bought;
  }
}

int _docs = 0;

/// The server turns the first run's trial on, or says nothing of it.
void _switch({required bool on}) => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'trial-first-run-${_docs++}',
      'app': {
        'flags': {if (on) 'trial.firstRun': true},
      },
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

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

/// A fresh install, through the intro, the mix and the three loved, each
/// left as it starts: the onboarding's end. [atIntro] runs while the intro
/// is up: the store answering, as it does a moment after launch.
Future<AppState> _throughTheOnboarding(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  VoidCallback? atIntro,
}) async {
  SharedPreferences.setMockInitialValues({...prefs});
  await tester.pumpWidget(const AstutoApp());
  await _settle(tester);
  if (atIntro != null) {
    atIntro();
    await _settle(tester);
  }
  await tester.tap(find.text('Start reading'));
  await _settle(tester);
  await tester.tap(find.text('Next'));
  await _settle(tester);
  expect(find.text('Pick the three you love'), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('loves-done')));
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

/// Today, with the day's five on the table and none of them read.
void _expectTheFive(WidgetTester tester, AppState app) {
  expect(find.byType(TodayScreen), findsOneWidget);
  expect(find.byType(PillCardStack), findsOneWidget);
  expect(find.byType(TrialOfferScreen), findsNothing);
  expect(find.byType(FirstCardScreen), findsNothing);
  expect(app.todaysDeck, hasLength(kPillsPerDay));
  expect(app.todayIndex, 0);
  expect(app.onboarded, isTrue);
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
    Subscription.useForTest(store);
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    Subscription.useForTest(before);
    Remote.reset();
  });

  testWidgets('with the switch off, the first run is as built: the five at '
      'once, nothing played, nothing offered', (tester) async {
    _switch(on: false);
    final AppState app = await _throughTheOnboarding(tester);

    _expectTheFive(tester, app);
    expect(find.byType(PaywallScreen), findsNothing);
    expect(app.seenIds, isEmpty);
    expect(app.trialOfferedOn, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('knowit.trialOfferedOn'), isNull);
    // As the build has it, without a word from the server.
    expect(AppState.kFirstRunTrialFlag.fallback, isFalse);
  });

  testWidgets('with it on: one real card, the offer at the store\'s price, '
      'and "Continue for free" lands on Today with the five dealt', (
    tester,
  ) async {
    _switch(on: true);
    final AppState app = await _throughTheOnboarding(tester);

    // One card, the opening's best for this reader, on its own.
    expect(find.byType(FirstCardScreen), findsOneWidget);
    expect(find.text(_en.firstCardTitle), findsOneWidget);
    final FirstCardScreen first = tester.widget(find.byType(FirstCardScreen));
    final String card = first.card.id;
    expect(kFirstDays.map((c) => c.id), contains(card));
    expect(find.byType(TrialOfferScreen), findsNothing);
    expect(app.onboarded, isFalse);

    await _throwTheCard(tester);

    // The offer: the year's price as the store writes it, its days, and
    // the way out as plain as the way in.
    expect(find.byType(TrialOfferScreen), findsOneWidget);
    expect(find.text(_en.trialOfferTitle), findsOneWidget);
    expect(find.text('€39.99'), findsOneWidget);
    expect(find.text(_en.trialStepToday), findsOneWidget);
    expect(find.text(_en.trialStepDay(12)), findsOneWidget);
    expect(find.text(_en.trialStepReminderLine(2)), findsOneWidget);
    expect(find.text(_en.trialStepDay(14)), findsOneWidget);
    expect(find.text(_en.trialOfferStart), findsOneWidget);
    expect(find.text(_en.trialOfferFree), findsOneWidget);
    // A button like the other, not a word at the foot.
    final Size free = tester.getSize(
      find.byKey(const ValueKey('trial-offer-free')),
    );
    final Size start = tester.getSize(
      find.byKey(const ValueKey('trial-offer-start')),
    );
    expect(free.width, start.width);
    expect(free.height, greaterThanOrEqualTo(48));
    // Noted as it went up.
    expect(app.trialOfferedOn, dateKey(app.today));

    await tester.tap(find.text(_en.trialOfferFree));
    await _settle(tester, 14);

    _expectTheFive(tester, app);
    expect(store.buys, 0);
    expect(app.isPlus, isFalse);
    // The card played was read outside the day, and the day never deals
    // it again.
    expect(app.seenIds, contains(card));
    expect(app.todaysDeck.map((p) => p.id), isNot(contains(card)));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('knowit.trialOfferedOn'), dateKey(app.today));
  });

  testWidgets('"Start the free trial" ends on the trial\'s own screen, then '
      'Today with the five, all of them the reader\'s', (tester) async {
    _switch(on: true);
    final AppState app = await _throughTheOnboarding(tester);
    await _throwTheCard(tester);
    expect(find.byType(TrialOfferScreen), findsOneWidget);

    await tester.tap(find.text(_en.trialOfferStart));
    await _settle(tester, 40);

    expect(store.buys, 1);
    expect(find.byType(PurchaseSuccessScreen), findsOneWidget);
    expect(find.text(_en.trialStartedTitle), findsOneWidget);
    await tester.tap(find.text(_en.letsStart));
    await _settle(tester, 14);

    _expectTheFive(tester, app);
    expect(app.isPlus, isTrue);
    expect(app.ownIdsToday, hasLength(kPillsPerDay));
  });

  group('never to a reader who already has Astute+', () {
    testWidgets('the store says so before the onboarding ends: no card, no '
        'offer', (tester) async {
      _switch(on: true);
      final AppState app = await _throughTheOnboarding(
        tester,
        atIntro: () => store.holdForTest(_plus(period: PeriodType.normal)),
      );

      _expectTheFive(tester, app);
      expect(app.isPlus, isTrue);
      expect(app.trialOfferedOn, isNull);
      expect(app.seenIds, isEmpty);
    });

    testWidgets('and when it says so while the card is read, the offer '
        'stays away', (tester) async {
      _switch(on: true);
      final AppState app = await _throughTheOnboarding(tester);
      expect(find.byType(FirstCardScreen), findsOneWidget);

      store.holdForTest(_plus(period: PeriodType.normal));
      await _settle(tester);
      await _throwTheCard(tester);

      _expectTheFive(tester, app);
      expect(app.trialOfferedOn, isNull);
    });

    testWidgets('and the offer itself steps aside the moment Astute+ is '
        'theirs', (tester) async {
      _switch(on: true);
      final AppState app = await _throughTheOnboarding(tester);
      await _throwTheCard(tester);
      expect(find.byType(TrialOfferScreen), findsOneWidget);

      // A purchase restored, or an account that has it, heard late.
      store.holdForTest(_plus(period: PeriodType.normal));
      await _settle(tester, 14);

      _expectTheFive(tester, app);
      expect(store.buys, 0);
    });
  });

  group('never twice in a day', () {
    testWidgets('a first run on the day the offer was put goes straight to '
        'the five', (tester) async {
      _switch(on: true);
      final AppState app = await _throughTheOnboarding(
        tester,
        prefs: {'knowit.trialOfferedOn': dateKey(DateTime.now())},
      );

      _expectTheFive(tester, app);
      expect(app.seenIds, isEmpty);
    });

    test('the day is the phone\'s: a sign-out does not forget it', () async {
      _switch(on: true);
      SharedPreferences.setMockInitialValues({});
      final AppState app = AppState(
        hasPermission: () async => false,
        askPermission: () async => false,
        arm: (_) async {},
        disarm: () async {},
        pushWidget: (_) async {},
      );
      await app.init();
      expect(trialOfferDue(app, store: store), isTrue);

      await app.notedTrialOffered();
      expect(trialOfferDue(app, store: store), isFalse);

      await app.signOut();
      expect(app.trialOfferedToday, isTrue);
      expect(trialOfferDue(app, store: store), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('knowit.trialOfferedOn'), dateKey(app.today));
    });

    test('and the next day it may be put again', () async {
      _switch(on: true);
      final DateTime now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        'knowit.trialOfferedOn': dateKey(
          DateTime(now.year, now.month, now.day - 1),
        ),
      });
      final AppState app = AppState(
        hasPermission: () async => false,
        askPermission: () async => false,
        arm: (_) async {},
        disarm: () async {},
        pushWidget: (_) async {},
      );
      await app.init();
      expect(app.trialOfferedToday, isFalse);
      expect(trialOfferDue(app, store: store), isTrue);
    });
  });

  group('the offer holds on any phone, the way out always in reach', () {
    for (final (Size phone, double notch, double text, Locale locale) in const [
      (Size(375, 667), 20.0, 1.0, Locale('de')),
      (Size(375, 667), 20.0, 1.0, Locale('it')),
      (Size(390, 844), 47.0, 1.0, Locale('ru')),
      (Size(390, 844), 47.0, 1.6, Locale('en')),
    ]) {
      testWidgets('${phone.width.round()} by ${phone.height.round()}, '
          '${locale.languageCode}, text at $text', (tester) async {
        tester.view.physicalSize = phone;
        tester.view.devicePixelRatio = 1;
        tester.view.padding = FakeViewPadding(top: notch);
        tester.view.viewPadding = FakeViewPadding(top: notch);
        addTearDown(tester.view.reset);
        _switch(on: true);
        SharedPreferences.setMockInitialValues({});
        final AppState app = AppState(
          hasPermission: () async => false,
          askPermission: () async => false,
          arm: (_) async {},
          disarm: () async {},
          pushWidget: (_) async {},
        );
        await app.init();
        int done = 0;
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildAstutoTheme(Brightness.dark),
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(text)),
                child: TrialOfferScreen(app: app, onDone: () => done++),
              ),
            ),
          ),
        );
        await _settle(tester, 14);

        expect(tester.takeException(), isNull);
        final AppLocalizations l = lookupAppLocalizations(locale);
        // Both buttons on screen, whatever scrolls above them.
        expect(find.text(l.trialOfferStart).hitTestable(), findsOneWidget);
        expect(find.text(l.trialOfferFree).hitTestable(), findsOneWidget);
        expect(find.text(l.restorePurchases).hitTestable(), findsOneWidget);
        // Every day of the trial said, the price among them.
        expect(find.text(l.trialStepToday), findsOneWidget);
        expect(find.text(l.trialStepDay(14)), findsOneWidget);
        expect(find.text('€39.99'), findsOneWidget);

        await tester.tap(find.text(l.trialOfferFree));
        await tester.pump();
        expect(done, 1);
      });
    }
  });

  test('no offer without the store\'s own year and free days', () async {
    _switch(on: true);
    SharedPreferences.setMockInitialValues({});
    final AppState app = AppState(
      hasPermission: () async => false,
      askPermission: () async => false,
      arm: (_) async {},
      disarm: () async {},
      pushWidget: (_) async {},
    );
    await app.init();
    expect(trialOfferDue(app, store: store), isTrue);
    // Nothing on sale yet: a debug build's plans as sold do not count.
    store.answerForTest();
    expect(trialOfferDue(app, store: store), isFalse);
    // A year with no free days.
    final Offering sale = _onSale();
    final Package year = sale.annual!;
    final Package plain = Package(
      year.identifier,
      year.packageType,
      StoreProduct(
        year.storeProduct.identifier,
        'Astute+',
        'Astute+',
        39.99,
        '€39.99',
        'EUR',
      ),
      year.presentedOfferingContext,
    );
    store.answerForTest(
      offering: Offering('default', '', const {}, [plain], annual: plain),
    );
    expect(trialOfferDue(app, store: store), isFalse);
    // A reader Apple says has had them.
    store.answerForTest(
      offering: _onSale(),
      yearlyEligibility:
          IntroEligibilityStatus.introEligibilityStatusIneligible,
    );
    expect(trialOfferDue(app, store: store), isFalse);
  });
}
