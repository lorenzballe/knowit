// Photographs what Astute+ is sold with: the new reader's gift — its moment
// in the first run (gift-*), the one quiet line in its last two days on the
// finished day's shelf (two-days-*), the page the morning after it (gift-end-*)
// and the paywall it opens (gift-end-paywall-*) — three evenings of the card
// after the fifth, each saying one true thing (sixth-1, -2, -3), the
// paywall with its two new lines (paywall-*, paywall-evidence-* with its
// list at its end), the web's paywall (web-*) and
// the end of Explore's flow with its number set (explore-end-*); at night
// and on paper, on a 390 × 844 iPhone; and each again in German on the
// 320-wide phone (de-320-*), the pages that scroll there also at their
// foot, to catch what overflows.
//
//   SHOTS=/some/folder LANG_SHOT=it flutter test tool/money_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it. The
// real app, its fonts loaded, its shadows soft as a phone draws them, the
// shelf's cards their pictures from web/cards/thumbs/; the paywall and the
// gift's moment are pumped as the screens they are, the rest are the app
// opened onto the day each shows. The store is a stand-in holding the plans
// as the owner sets them — a year at €29,99 with fourteen days free, a month
// at €3,99 — which the app reads as it reads the store's; on the web's
// paywall, a store that never answers, as the web has none.
//
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/daily.dart' show dealDay;
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/explore/blocks/core/feed_cap.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/subscription.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/sixth_card.dart';
import 'package:astuto/widgets/web/card_thumb.dart';

Future<void> _loadFonts() async {
  final fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons':
        '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key);
    final bytes = await File(entry.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

/// The plans as the owner sets them, as the store writes their prices in
/// [locale]'s language.
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
      'com.astuto.app.plus.yearly',
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
      'com.astuto.app.plus.monthly',
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

int _docs = 0;

/// The server's word for these pictures: the gift on, and Explore's end at
/// twenty cards a day for the free plan.
void _server() => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'money-shots-${_docs++}',
      'app': {
        'flags': {'trial.reverse': true, 'trial.firstRun': true, 'cardAi': true},
        'tunables': {'explore.freeCards': 20},
      },
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

final DateTime _now = DateTime.now();
final DateTime _today = DateTime(_now.year, _now.month, _now.day);
String _ago(int days) =>
    dateKey(DateTime(_today.year, _today.month, _today.day - days));

/// A reader past the first run, every sheet of the finished day already
/// asked or answered, so nothing rises over what is photographed.
Map<String, Object> _reader(String theme) => {
  'knowit.onboarded': true,
  'knowit.plus': false,
  'knowit.theme': theme,
  'knowit.pushAsked': true,
  'knowit.accountOffered': true,
  'knowit.widgetAsked': true,
  'knowit.reviewAsked': true,
  'knowit.goalAsked': true,
  'knowit.placeAsks': 9,
};

/// Today's five as the phone deals them, by id.
List<String> _five() =>
    dealDay(date: _now).cards.take(kPillsPerDay).map((p) => p.id).toList();

/// Cards with a right answer, none of [not].
List<Pill> _graded(int n, {Set<String> not = const {}}) => PillBank.cards
    .where((p) => p.isGraded && !not.contains(p.id))
    .take(n)
    .toList();

/// Day 13 of the gift, its five read tonight: the shelf, and its line.
Map<String, Object> _thirteenth(String theme) {
  final List<String> five = _five();
  return {
    ..._reader(theme),
    'knowit.installedOn': _ago(12),
    'knowit.giftFrom': _ago(12),
    'knowit.giftGiven': true,
    'knowit.streak': 13,
    'knowit.bestStreak': 13,
    'knowit.lastCompletionDate': _ago(0),
    'knowit.completedDates': [for (int i = 12; i >= 0; i--) _ago(i)],
    'knowit.todayDate': _ago(0),
    'knowit.todayDeckIds': five,
    'knowit.todayIndex': kPillsPerDay,
    'knowit.seenIds': five,
  };
}

/// The morning after the gift: fourteen days begun fourteen days ago,
/// twelve of them read, 62 cards, how sure against how right measured on
/// the sixth day 17 points off and 12 at the end.
Map<String, Object> _fifteenth(String theme) {
  final Set<String> five = _five().toSet();
  final List<Pill> cards = _graded(62, not: five);
  final List<int> read = [for (int d = 1; d <= 14; d++) d]
    ..remove(4)
    ..remove(9);
  final Map<String, List<String>> readDays = {};
  for (int i = 0; i < cards.length; i++) {
    final int day = read[i % read.length];
    readDays.putIfAbsent(_ago(15 - day), () => []).add(cards[i].id);
  }
  // Twelve answers by the sixth day: four said 60% sure, one right; eight
  // said 70%, five right. Then thirteen more by the fourteenth: four at
  // 70%, all right; three at 80%, two right; six at 90%, all right.
  final List<Map<String, Object?>> said = [];
  int next = 0;
  void answer(int sure, int n, int right, List<int> days) {
    for (int i = 0; i < n; i++) {
      said.add({
        'c': sure,
        'k': i < right,
        'p': cards[next++].id,
        'd': _ago(15 - days[i % days.length]),
      });
    }
  }

  answer(60, 4, 1, [1, 2, 3, 5]);
  answer(70, 8, 5, [1, 2, 3, 5, 6, 6, 2, 3]);
  answer(70, 4, 4, [7, 8, 10, 11]);
  answer(80, 3, 2, [12, 13, 14]);
  answer(90, 6, 6, [10, 11, 12, 13, 14, 14]);
  return {
    ..._reader(theme),
    'knowit.installedOn': _ago(14),
    'knowit.giftFrom': _ago(14),
    'knowit.giftGiven': true,
    'knowit.streak': 5,
    'knowit.bestStreak': 5,
    'knowit.lastCompletionDate': _ago(1),
    'knowit.completedDates': [for (final int d in read) _ago(15 - d)],
    'knowit.readDays': jsonEncode(readDays),
    'knowit.seenIds': [for (final Pill p in cards) p.id],
    'knowit.judgements': jsonEncode(said),
  };
}

/// A free reader's evening, three days running: the first saying nothing
/// yet; the second with a card missed at 90% today; the third with two
/// cards got wrong back and waiting.
Map<String, Object> _evening(String theme, int n) {
  final Set<String> five = _five().toSet();
  final List<Pill> cards = _graded(6, not: five);
  return {
    ..._reader(theme),
    'knowit.installedOn': _ago(4),
    'knowit.streak': n,
    'knowit.bestStreak': n,
    'knowit.lastCompletionDate': _ago(1),
    'knowit.completedDates': [for (int i = n; i >= 1; i--) _ago(i)],
    if (n == 2) ...{
      'knowit.sixthSaid': '${_ago(1)}|tomorrow',
      'knowit.judgements': jsonEncode([
        {'c': 90, 'k': false, 'p': cards[0].id, 'd': _ago(0)},
      ]),
    },
    if (n == 3) ...{
      'knowit.sixthSaid': '${_ago(1)}|sure',
      'knowit.answersJson': jsonEncode({
        cards[1].id: {'r': '0', 'd': _ago(1)},
        cards[2].id: {'r': '0', 'd': _ago(0)},
      }),
    },
  };
}

/// A free reader who read twenty cards on Explore today.
Map<String, Object> _explorer(String theme) {
  final Set<String> five = _five().toSet();
  final List<String> twenty = [
    for (final Pill p in PillBank.cards.where((p) => !five.contains(p.id)))
      p.id,
  ].take(20).toList();
  return {
    ..._reader(theme),
    'knowit.installedOn': _ago(6),
    'knowit.streak': 3,
    'knowit.bestStreak': 3,
    'knowit.lastCompletionDate': _ago(1),
    'knowit.completedDates': [_ago(3), _ago(2), _ago(1)],
    'knowit.readDays': jsonEncode({_ago(0): twenty}),
    'knowit.seenIds': twenty,
  };
}

/// A card's picture from the folder the site serves them from, read once
/// and kept: the same provider for the same picture, so what was decoded
/// before the photograph is what the photograph shows. One not on the disk
/// fails, and the card is drawn in its words, as on a phone.
final Map<String, ImageProvider> _thumbs = {};
ImageProvider _thumb(Uri url) {
  final String path = url.path;
  final int at = path.indexOf('thumbs/');
  final File file = File('web/cards/${at < 0 ? path : path.substring(at)}');
  return _thumbs.putIfAbsent(
    file.path,
    () => file.existsSync()
        ? MemoryImage(file.readAsBytesSync())
        : FileImage(file),
  );
}

void main() {
  final String out = Platform.environment['SHOTS'] ?? 'shots';
  final Locale locale = Locale(Platform.environment['LANG_SHOT'] ?? 'en');
  final Subscription before = Subscription.instance;
  final ThumbImage pictures = CardThumb.image;

  setUpAll(() async {
    await _loadFonts();
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
    CardThumb.image = _thumb;
  });

  tearDownAll(() => CardThumb.image = pictures);

  /// The phone: [small], the 320-wide one with no notch, or an iPhone.
  void phone(WidgetTester tester, Locale lang, {bool small = false}) {
    final dispatcher = tester.platformDispatcher;
    final view = tester.view;
    view.physicalSize =
        (small ? const Size(320, 568) : const Size(390, 844)) * 3;
    view.devicePixelRatio = 3;
    view.padding = small
        ? const FakeViewPadding(top: 20 * 3)
        : const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    view.viewPadding = view.padding;
    dispatcher.localeTestValue = lang;
    dispatcher.localesTestValue = [lang];
    dispatcher.alwaysUse24HourFormatTestValue = true;
  }

  /// The store, holding the plans as the owner sets them, in [lang]'s
  /// writing; or, for the web, a store that never answers, as there is none.
  void store(Locale lang, {bool web = false}) => Subscription.useForTest(
    web
        ? Subscription(keyOverride: '')
        : (Subscription(keyOverride: '')
            ..answerForTest(offering: _onSale(lang))
            ..holdForTest(null)),
  );

  setUp(() {
    _server();
    store(locale);
    // Shadows blurred, as on a phone.
    debugDisableShadows = false;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });

  tearDown(() {
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.views.first.reset();
    dispatcher.clearLocaleTestValue();
    dispatcher.clearLocalesTestValue();
    dispatcher.clearAlwaysUse24HourTestValue();
    Subscription.useForTest(before);
    PaywallScreen.webForShots = false;
    Remote.reset();
  });

  Future<void> settle(WidgetTester tester, {int frames = 14}) async {
    for (int f = 0; f < frames; f++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
  }

  /// Every picture on the screen decoded for real, which the test's clock
  /// alone never finishes: the shelf's cards are their pictures.
  Future<void> decodeShown(WidgetTester tester) async {
    final Set<ImageProvider> shown = {
      for (final Image image in tester.widgetList<Image>(find.byType(Image)))
        image.image,
    };
    if (shown.isEmpty) return;
    final BuildContext context = tester.element(
      find.byType(MaterialApp).first,
    );
    await tester.runAsync(() async {
      for (final ImageProvider p in shown) {
        await precacheImage(
          p,
          context,
          onError: (_, _) {},
        ).timeout(const Duration(seconds: 10), onTimeout: () {});
      }
    });
    await settle(tester, frames: 6);
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    await decodeShown(tester);
    await expectLater(
      find.byType(MaterialApp).first,
      matchesGoldenFile('$out/$name.png'),
    );
  }

  /// Gone with the app, so nothing of it outlives the platform it was on.
  Future<void> leave(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
    debugDefaultTargetPlatformOverride = null;
    debugDisableShadows = true;
  }

  /// A screen on its own, as the app draws it.
  Future<void> alone(
    WidgetTester tester,
    Widget screen, {
    required Brightness light,
    required Locale lang,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: lang,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(light),
        debugShowCheckedModeBanner: false,
        home: screen,
      ),
    );
    await settle(tester, frames: 24);
  }

  /// [prefs]' reader, the app's state as the phone keeps it, on a phone
  /// that lets the app notify them.
  Future<AppState> reader(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final AppState app = AppState(
      hasPermission: () async => true,
      askPermission: () async => true,
      arm: (_) async {},
      disarm: () async {},
      pushWidget: (_) async {},
    );
    await app.init();
    return app;
  }

  /// The app opened on [prefs]' day.
  Future<void> openApp(WidgetTester tester, Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    await tester.pumpWidget(const AstutoApp());
    await settle(tester, frames: 30);
  }

  /// The five thrown, one after the other, as a reader throws them: the
  /// card after the fifth on top.
  Future<void> throwFive(WidgetTester tester) async {
    for (int i = 0; i < kPillsPerDay + 3; i++) {
      if (find.byType(SixthCard).hitTestable().evaluate().isNotEmpty) break;
      final Rect deck = tester.getRect(find.byType(PillCardStack));
      await tester.flingFrom(
        Offset(deck.center.dx, deck.top + 90),
        const Offset(-320, 0),
        900,
      );
      await settle(tester, frames: 12);
    }
    await settle(tester, frames: 24);
    expect(find.byType(SixthCard), findsOneWidget);
  }

  Finder down() => find
      .byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .first;

  /// Explore opened, and scrolled to the end of its flow: the card the day
  /// ends on with its top [above] points from the top of the screen.
  Future<void> toTheEnd(WidgetTester tester, {required double above}) async {
    await tester.tap(find.byKey(const ValueKey('tab-Explore')));
    await settle(tester, frames: 20);
    final Finder card = find.byKey(
      const ValueKey('explore-cap'),
      skipOffstage: false,
    );
    for (int i = 0; i < 120 && card.evaluate().isEmpty; i++) {
      await tester.drag(down(), const Offset(0, -500));
      await tester.pump();
    }
    await tester.ensureVisible(card);
    await settle(tester);
    final double top = tester.getTopLeft(card).dy;
    await tester.drag(down(), Offset(0, -(top - above)));
    await settle(tester, frames: 16);
  }

  /// A page's scrolling part taken to its end: the paywall's evidence over
  /// the plans, the gift's fifteenth over its button.
  Future<void> toTheFoot(WidgetTester tester) async {
    final ScrollableState list = tester.state<ScrollableState>(down());
    list.position.jumpTo(list.position.maxScrollExtent);
    await settle(tester, frames: 8);
  }

  /// The morning after the gift, its page risen over the day, and the
  /// paywall "Keep Astute+" opens; for a reader who let the app notify
  /// them, as most who read for fourteen days have.
  Future<void> morningAfter(
    WidgetTester tester, {
    required String theme,
    required String name,
  }) async {
    await openApp(tester, _fifteenth(theme));
    await settle(tester, frames: 20);
    expect(find.byType(GiftEndScreen), findsOneWidget);
    tester
            .widget<GiftEndScreen>(find.byType(GiftEndScreen))
            .app
            .notificationsAllowed =
        true;
    await shoot(tester, name);
    await tester.tap(find.byKey(const ValueKey('gift-end-keep')));
    await settle(tester, frames: 24);
    expect(find.byType(PaywallScreen), findsOneWidget);
    await shoot(tester, name.replaceFirst('gift-end', 'gift-end-paywall'));
  }

  for (final (String theme, Brightness light) in const [
    ('dark', Brightness.dark),
    ('light', Brightness.light),
  ]) {
    testWidgets('gift-$theme', (tester) async {
      phone(tester, locale);
      final AppState app = await reader({'knowit.theme': theme});
      await alone(
        tester,
        GiftScreen(app: app, onDone: () {}),
        light: light,
        lang: locale,
      );
      await shoot(tester, 'gift-$theme');
      await leave(tester);
    });

    testWidgets('two-days-$theme', (tester) async {
      phone(tester, locale);
      await openApp(tester, _thirteenth(theme));
      await shoot(tester, 'two-days-$theme');
      await leave(tester);
    });

    testWidgets('gift-end-$theme', (tester) async {
      phone(tester, locale);
      await morningAfter(tester, theme: theme, name: 'gift-end-$theme');
      await leave(tester);
    });

    testWidgets('paywall-$theme', (tester) async {
      phone(tester, locale);
      final AppState app = await reader({
        'knowit.onboarded': true,
        'knowit.theme': theme,
      });
      await alone(
        tester,
        PaywallScreen(app: app, source: 'see the plans'),
        light: light,
        lang: locale,
      );
      await shoot(tester, 'paywall-$theme');
      // And its list taken to its end: the evidence's line over the plans,
      // the warning under the button.
      await toTheFoot(tester);
      await shoot(tester, 'paywall-evidence-$theme');
      await leave(tester);
    });

    testWidgets('web-$theme', (tester) async {
      phone(tester, locale);
      PaywallScreen.webForShots = true;
      store(locale, web: true);
      final AppState app = await reader({
        'knowit.onboarded': true,
        'knowit.theme': theme,
      });
      await alone(
        tester,
        PaywallScreen(app: app, source: 'see the plans'),
        light: light,
        lang: locale,
      );
      expect(find.byKey(const ValueKey('paywall-in-the-app')), findsOneWidget);
      await shoot(tester, 'web-$theme');
      await leave(tester);
    });

    testWidgets('explore-end-$theme', (tester) async {
      phone(tester, locale);
      await openApp(tester, _explorer(theme));
      // The card halfway down, what the page laid before it over it.
      await toTheEnd(tester, above: 380);
      expect(find.byType(FeedCapCard), findsOneWidget);
      await shoot(tester, 'explore-end-$theme');
      await leave(tester);
    });
  }

  // Three evenings running, at night: what the card after the fifth says
  // on each, never what it said the evening before.
  for (final int n in const [1, 2, 3]) {
    testWidgets('sixth-$n', (tester) async {
      phone(tester, locale);
      await openApp(tester, _evening('dark', n));
      await throwFive(tester);
      await shoot(tester, 'sixth-$n');
      await leave(tester);
    });
  }

  // On the 320-wide phone, in German: each of them, where a word too long
  // would show it.
  group('de-320', () {
    const Locale de = Locale('de');
    setUp(() => store(de));

    testWidgets('de-320-gift', (tester) async {
      phone(tester, de, small: true);
      final AppState app = await reader({'knowit.theme': 'dark'});
      await alone(
        tester,
        GiftScreen(app: app, onDone: () {}),
        light: Brightness.dark,
        lang: de,
      );
      await shoot(tester, 'de-320-gift');
      // And scrolled to its foot: the fifteenth, over the button.
      await toTheFoot(tester);
      await shoot(tester, 'de-320-gift-foot');
      await leave(tester);
    });

    testWidgets('de-320-two-days', (tester) async {
      phone(tester, de, small: true);
      await openApp(tester, _thirteenth('dark'));
      await shoot(tester, 'de-320-two-days');
      await leave(tester);
    });

    testWidgets('de-320-gift-end', (tester) async {
      phone(tester, de, small: true);
      await morningAfter(tester, theme: 'dark', name: 'de-320-gift-end');
      await leave(tester);
    });

    testWidgets('de-320-paywall', (tester) async {
      phone(tester, de, small: true);
      final AppState app = await reader({
        'knowit.onboarded': true,
        'knowit.theme': 'dark',
      });
      await alone(
        tester,
        PaywallScreen(app: app, source: 'see the plans'),
        light: Brightness.dark,
        lang: de,
      );
      await shoot(tester, 'de-320-paywall');
      await toTheFoot(tester);
      await shoot(tester, 'de-320-paywall-evidence');
      await leave(tester);
    });

    testWidgets('de-320-web', (tester) async {
      phone(tester, de, small: true);
      PaywallScreen.webForShots = true;
      store(de, web: true);
      final AppState app = await reader({
        'knowit.onboarded': true,
        'knowit.theme': 'dark',
      });
      await alone(
        tester,
        PaywallScreen(app: app, source: 'see the plans'),
        light: Brightness.dark,
        lang: de,
      );
      await shoot(tester, 'de-320-web');
      await leave(tester);
    });

    for (final int n in const [1, 2, 3]) {
      testWidgets('de-320-sixth-$n', (tester) async {
        phone(tester, de, small: true);
        await openApp(tester, _evening('dark', n));
        await throwFive(tester);
        await shoot(tester, 'de-320-sixth-$n');
        await leave(tester);
      });
    }

    testWidgets('de-320-explore-end', (tester) async {
      phone(tester, de, small: true);
      await openApp(tester, _explorer('dark'));
      await toTheEnd(tester, above: 180);
      expect(find.byType(FeedCapCard), findsOneWidget);
      await shoot(tester, 'de-320-explore-end');
      await leave(tester);
    });
  });
}
