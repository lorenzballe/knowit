// Photographs the first run's free trial (`trial.firstRun`, off as built) as
// a new reader goes through it, on the medium phone (390 × 844) at night, in
// Italian and in English: the one card, played; the offer; the day's five
// after "Continue for free"; the screen the trial starts on after "Start the
// free trial", and the five after it, on Astute+.
//
//   TRIAL_SHOTS=/some/dir PAGE_SHOTS=/dir/of/pages \
//     flutter test tool/trial_day_shots.dart --update-goldens
//
// A camera, not a check, like the other shots: it lives outside test/ so CI
// never runs it. The pictures land where TRIAL_SHOTS says, or in the
// gallery, which is not kept.
//
// The store is a stand-in holding the plans as the owner sets them in App
// Store Connect — a year at €39,99 with fourteen days free, a month at
// €4,99 — written as the App Store writes a price in each language. The app
// reads whatever the store says, here as on a phone; nothing in it knows
// these prices.
//
// A drawn card cannot draw its page here, where there is no WebView: its
// page is a photograph in the page's place (FakeWebSurface's face), taken in
// a browser with exactly what the app told the page (PageEnv: the language,
// the foot's words, the chip, the size the deck gives the card), as it
// first appears and once played: <card>-<told>-<width>x<height>-<start|end>
// .png in PAGE_SHOTS, <told> a hash of what it was told. A page with no
// photograph is drawn as its ground, and what it was told is written to
// pages-wanted.json beside the pictures, so it can be taken.
//
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/card_page_store_base.dart';
import 'package:astuto/data/card_pages.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/first_card_screen.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/screens/purchase_success_screen.dart';
import 'package:astuto/screens/today_screen.dart';
import 'package:astuto/sync/subscription.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/web/card_kit.dart';
import 'package:astuto/widgets/web/fake_web_surface.dart';
import 'package:astuto/widgets/web/page_messages.dart' show PageEnv;
import 'package:astuto/widgets/web/web_surface.dart';

import '../test/explore/core_harness.dart' show loadFonts;

final String _out =
    Platform.environment['TRIAL_SHOTS'] ?? 'shots/gallery/trial-day-one';
final String _pages = Platform.environment['PAGE_SHOTS'] ?? '$_out/pages';

/// The medium phone, its insets an iPhone's of that size, three pixels a
/// point.
const Size _phone = Size(390, 844);
const EdgeInsets _insets = EdgeInsets.only(top: 47, bottom: 34);
const double _ratio = 3;

/// What the app told each page, by the page's key: its card, and a hash of
/// what it was told apart from its size and whether it is in front.
final Map<String, ({String id, Map<String, Object?> env})> _told = {};

/// The pages drawn with no photograph, by key, and the size they were
/// drawn at.
final Map<String, Size> _wanted = {};

/// A short, stable hash of [text]: FNV-1a, 32 bits, in hex.
String _hash(String text) {
  int h = 0x811c9dc5;
  for (final int unit in utf8.encode(text)) {
    h ^= unit;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

/// Which photograph of a page stands in it: as it first appears, or played.
final ValueNotifier<String> _pageStage = ValueNotifier<String>('start');

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
      39.99,
      it ? '39,99 €' : '€39.99',
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
      4.99,
      it ? '4,99 €' : '€4.99',
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

/// A store whose sheet always says yes: the year's free trial, started.
class _Store extends Subscription {
  _Store() : super(keyOverride: '');

  @override
  Future<PurchaseOutcome> buy(Package package) async {
    holdForTest(
      EntitlementInfo(
        kPlusEntitlement,
        true,
        true,
        DateTime.now().toUtc().toIso8601String(),
        DateTime.now().toUtc().toIso8601String(),
        package.storeProduct.identifier,
        true,
        periodType: PeriodType.trial,
        expirationDate: DateTime.now()
            .add(const Duration(days: 14))
            .toUtc()
            .toIso8601String(),
      ),
    );
    return PurchaseOutcome.bought;
  }
}

/// The kit, put together at once: the page is a photograph here, so what
/// the kit would put inside it does not matter. What the app tells the
/// page is kept, and the page marked with it.
class _InstantKit extends CardKit {
  @override
  Future<String> page(String html, PageEnv env) {
    final String id = _marked.firstMatch(html)?.group(1) ?? 'unknown';
    final Map<String, Object?> told = env.toJson();
    final String key =
        '$id-${_hash(jsonEncode({...told}
          ..remove('shown')
          ..remove('size')))}';
    _told[key] = (id: id, env: told);
    return Future.value('<!--page:$key-->$html');
  }
}

/// Every card's page in the bank, by its id.
final Map<String, File> _bankPages = {
  for (final FileSystemEntity f in Directory(
    'tool/cards/bank',
  ).listSync(recursive: true))
    if (f is File && f.path.endsWith('.html'))
      f.uri.pathSegments.last.replaceAll('.html', ''): f,
};

/// The page's own card, marked in the page as it is handed over.
final RegExp _marked = RegExp(r'<!--card:([^>]+)-->');

/// The page's key, marked in front of it by the kit.
final RegExp _keyed = RegExp(r'^<!--page:([^>]+)-->');

/// A page's photograph in its place, at the size the deck gives it.
class _PagePhoto extends StatefulWidget {
  const _PagePhoto(this.surface);

  final FakeWebSurface surface;

  @override
  State<_PagePhoto> createState() => _PagePhotoState();
}

class _PagePhotoState extends State<_PagePhoto>
    with SingleTickerProviderStateMixin {
  /// Watches for the page to be handed over, which can come after the
  /// surface is drawn, and stops once it has.
  late final Ticker _watch;
  String? _key;

  @override
  void initState() {
    super.initState();
    _pageStage.addListener(_restage);
    _watch = createTicker((_) {
      final String? key = _keyed
          .firstMatch(widget.surface.html ?? '')
          ?.group(1);
      if (key == null) return;
      _watch.stop();
      setState(() => _key = key);
    })..start();
  }

  void _restage() => setState(() {});

  @override
  void dispose() {
    _pageStage.removeListener(_restage);
    _watch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final Widget ground = ColoredBox(
        color: widget.surface.background ?? const Color(0xFF000000),
      );
      final String? key = _key;
      if (key == null || !box.hasBoundedWidth || !box.hasBoundedHeight) {
        return ground;
      }
      final String size = '${box.maxWidth.round()}x${box.maxHeight.round()}';
      final File photo = File('$_pages/$key-$size-${_pageStage.value}.png');
      if (!photo.existsSync()) {
        _wanted[key] = box.biggest;
        return ground;
      }
      return Image.memory(
        photo.readAsBytesSync(),
        fit: BoxFit.fill,
        gaplessPlayback: true,
      );
    },
  );
}

Future<void> _settle(WidgetTester tester, [int frames = 14]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

/// Every picture on screen, decoded before the photograph, in real time.
Future<void> _decodeShown(WidgetTester tester) async {
  final Set<ImageProvider> shown = {
    for (final Image image in tester.widgetList<Image>(find.byType(Image)))
      image.image,
  };
  if (shown.isEmpty) return;
  final BuildContext context = tester.element(find.byType(MaterialApp).first);
  await tester.runAsync(() async {
    for (final ImageProvider p in shown) {
      await precacheImage(
        p,
        context,
        onError: (_, _) {},
      ).timeout(const Duration(seconds: 10), onTimeout: () {});
    }
  });
  await _settle(tester, 4);
}

void main() {
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
    CardKit.instance = _InstantKit();
    CardPages.instance = CardPages(
      fetch: (url) async {
        final String? id = RegExp(r'pages/([^/?]+)\.html')
            .firstMatch(url.toString())
            ?.group(1);
        final File? page = id == null ? null : _bankPages[id];
        if (page == null) return null;
        return '<!--card:$id-->${page.readAsStringSync()}';
      },
      store: MemoryPageStore(),
    );
    WebSurfaces.debugUse(
      () => FakeWebSurface(face: (surface) => _PagePhoto(surface)),
    );
  });

  tearDownAll(() {
    WebSurfaces.debugUse(null);
    CardKit.instance = CardKit();
    Directory(_out).createSync(recursive: true);
    File('$_out/pages-wanted.json').writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert([
        for (final MapEntry<String, Size> e in _wanted.entries)
          {
            'key': e.key,
            'id': _told[e.key]?.id,
            'w': e.value.width.round(),
            'h': e.value.height.round(),
            'env': _told[e.key]?.env,
          },
      ]),
    );
    if (_wanted.isNotEmpty) {
      // ignore: avoid_print
      print('Pages to photograph: ${_wanted.keys.join(', ')}');
    }
  });

  final Subscription before = Subscription.instance;

  /// A fresh install in [locale]'s language, the store's plans on sale and
  /// the server's switch on, at its first screen.
  Future<AppLocalizations> launch(WidgetTester tester, Locale locale) async {
    final view = tester.view;
    view.physicalSize = _phone * _ratio;
    view.devicePixelRatio = _ratio;
    view.padding = FakeViewPadding(
      top: _insets.top * _ratio,
      bottom: _insets.bottom * _ratio,
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
      _pageStage.value = 'start';
    });
    Remote.adopt(
      RemoteConfig.parse(
        jsonEncode({
          'schema': 1,
          'hash': 'trial-day-one-${locale.languageCode}',
          'app': {
            'flags': {'trial.firstRun': true},
          },
          'strings': <String, Object?>{},
          'explore': null,
          'looks': null,
        }),
      ),
    );
    Subscription.useForTest(_Store()..answerForTest(offering: _onSale(locale)));
    SharedPreferences.setMockInitialValues({});
    // The pictures the trial's own screen draws, decoded in real time.
    await tester.runAsync(PurchaseSuccessScreen.precache);
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester, 20);
    return lookupAppLocalizations(locale);
  }

  /// Through the intro, the mix and the genres, each walked past, to the
  /// one card.
  Future<void> toTheCard(WidgetTester tester, AppLocalizations l) async {
    await tester.tap(find.text(l.skip).first);
    await _settle(tester);
    await tester.tap(find.text(l.next));
    await _settle(tester);
    await tester.tap(find.text(l.skip).first);
    await _settle(tester, 30);
    expect(find.byType(FirstCardScreen), findsOneWidget);
  }

  /// The one card, thrown on as a reader throws a card: the offer.
  Future<void> throwTheCard(WidgetTester tester) async {
    final Rect deck = tester.getRect(find.byType(PillCardStack));
    await tester.flingFrom(
      Offset(deck.center.dx, deck.top + 90),
      const Offset(-320, 0),
      900,
    );
    await _settle(tester, 30);
    expect(find.byType(TrialOfferScreen), findsOneWidget);
  }

  Future<void> shoot(WidgetTester tester, String lang, String name) async {
    await _decodeShown(tester);
    await expectLater(
      find.byType(MaterialApp).first,
      matchesGoldenFile('$_out/$lang-$name.png'),
    );
  }

  for (final Locale locale in const [Locale('it'), Locale('en')]) {
    final String lang = locale.languageCode;

    testWidgets('$lang: the card, the offer, and "Continue for free"', (
      tester,
    ) async {
      final AppLocalizations l = await launch(tester, locale);
      await toTheCard(tester, l);
      await _settle(tester, 20);
      await shoot(tester, lang, '1-card');
      // Played: its page as it is once the reader has done the one thing
      // it asks.
      _pageStage.value = 'end';
      await _settle(tester, 6);
      await shoot(tester, lang, '2-card-played');
      // The day's five come in as they first appear.
      _pageStage.value = 'start';
      await throwTheCard(tester);
      await shoot(tester, lang, '3-offer');
      await tester.tap(find.text(l.trialOfferFree));
      await _settle(tester, 30);
      expect(find.byType(TodayScreen), findsOneWidget);
      await shoot(tester, lang, '4-free-today');
    });

    testWidgets('$lang: "Start the free trial"', (tester) async {
      final AppLocalizations l = await launch(tester, locale);
      await toTheCard(tester, l);
      await throwTheCard(tester);
      await tester.tap(find.text(l.trialOfferStart));
      // The take, to its end: about three seconds, and the button.
      for (int i = 0; i < 90; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(PurchaseSuccessScreen), findsOneWidget);
      await shoot(tester, lang, '5-trial-started');
      await tester.tap(find.text(l.letsStart));
      await _settle(tester, 30);
      expect(find.byType(TodayScreen), findsOneWidget);
      await shoot(tester, lang, '6-trial-today');
    });
  }
}
