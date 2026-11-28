// Photographs the first run, from the first screen to the first card, as a
// new reader goes through it on the real app: the intro's five scenes, Your
// mix, the three subjects the reader loves, and the first card of the first
// day (onboard-it-1-intro-0 … onboard-it-5-day); the mix's tap
// (onboard-it-mix-tap); the first finished day with the question about
// usage data on its shelf, at night and on paper (onboard-it-consent-dark,
// -light); the third finished day with Which parts offered on its shelf,
// and the page it opens (onboard-it-parts-dark, -light, -page); and the
// 320-wide phone in German, for what does not fit (onboard-de-small-…).
//
//   SHOTS=/some/folder LANG_SHOT=it flutter test tool/onboard_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it. The
// real app, its fonts loaded, on a 390 × 844 phone at 3×, with an iPhone's
// notch and home bar, its shadows soft as a phone draws them. A card's page
// cannot be drawn here, where there is no WebView: its place shows the
// photograph tool/cards/thumbs.cjs took of it (web/cards/thumbs/large).
//
// SHOTS is where the pictures go (tool/shots by default); LANG_SHOT is the
// phone's language, English when not given. A build with somewhere to send
// usage data is played, so the question about it is asked where a phone
// asks it.
//
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/card_page_store_base.dart';
import 'package:astuto/data/card_pages.dart';
import 'package:astuto/data/daily.dart' show dealDay;
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/genres_screen.dart';
import 'package:astuto/widgets/ui.dart' show PrimaryButton;
import 'package:astuto/widgets/web/card_thumb.dart';
import 'package:astuto/widgets/web/card_kit.dart';
import 'package:astuto/widgets/web/fake_web_surface.dart';
import 'package:astuto/widgets/web/page_messages.dart' show PageEnv;
import 'package:astuto/widgets/web/web_surface.dart';

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

void _prefs(Map<String, Object> values) =>
    SharedPreferences.setMockInitialValues(values);

/// The kit, put together at once: the page is a photograph here, so what
/// the kit would put inside it does not matter. The card's mark, which the
/// pages below carry at their head, is kept for the photograph to find.
class _InstantKit extends CardKit {
  @override
  Future<String> page(String html, PageEnv env) => Future.value(html);
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

/// A card's page, as its photograph: the front, as it first appears.
Widget _photo(FakeWebSurface surface) {
  final Widget ground = ColoredBox(
    color: surface.background ?? const Color(0xFF000000),
  );
  final String? id = _marked.firstMatch(surface.html ?? '')?.group(1);
  if (id == null) return ground;
  final File photo = File('web/cards/thumbs/large/$id-front.webp');
  if (!photo.existsSync()) return ground;
  return Image.memory(
    photo.readAsBytesSync(),
    fit: BoxFit.fill,
    gaplessPlayback: true,
  );
}

/// A card's picture, from the disk the site serves it from: the same bytes
/// each time it is asked for, so it is one picture in the cache, decoded
/// once, rather than a new one at every rebuild.
ImageProvider _local(Uri url) {
  final String path = url.path.startsWith('/cards/')
      ? url.path.substring('/cards/'.length)
      : url.path;
  return MemoryImage(
    _read.putIfAbsent(path, () {
      final File file = File('web/cards/$path');
      return file.existsSync() ? file.readAsBytesSync() : Uint8List(0);
    }),
  );
}

final Map<String, Uint8List> _read = {};

/// A reader [days] finished days in, today's five read a little after
/// seven in the evening, the question about reminders already put: the app
/// opens on the finished day's shelf.
Map<String, Object> _finished(String theme, {required int days}) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  String day(int back) => dateKey(today.subtract(Duration(days: back)));
  return {
    'knowit.onboarded': true,
    'knowit.plus': false,
    'knowit.firstDays': true,
    'knowit.installedOn': day(days - 1),
    'knowit.streak': days,
    'knowit.bestStreak': days,
    'knowit.lastCompletionDate': day(0),
    'knowit.completedDates': [for (int i = days - 1; i >= 0; i--) day(i)],
    'knowit.todayDate': day(0),
    'knowit.todayDeckIds': dealDay(date: now).cards
        .take(kPillsPerDay)
        .map((p) => p.id)
        .toList(),
    'knowit.todayIndex': kPillsPerDay,
    'knowit.pushAsked': true,
    'knowit.theme': theme,
  };
}

void main() {
  setUpAll(() async {
    await _loadFonts();
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
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
    WebSurfaces.debugUse(() => FakeWebSurface(face: _photo));
    CardThumb.image = _local;
  });

  tearDownAll(() {
    WebSurfaces.debugUse(null);
    CardKit.instance = CardKit();
  });

  final String out = Platform.environment['SHOTS'] ?? 'shots';
  final Locale locale = Locale(Platform.environment['LANG_SHOT'] ?? 'en');
  final String lang = locale.languageCode;

  setUp(() {
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.alwaysUse24HourFormatTestValue = true;
    final view = dispatcher.views.first;
    view.physicalSize = const Size(390, 844) * 3;
    view.devicePixelRatio = 3;
    // An iPhone's notch and home bar.
    view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    dispatcher.localeTestValue = locale;
    dispatcher.localesTestValue = [locale];
    // A build with somewhere to send usage data, as the stores' builds are:
    // the question about it is asked where a phone asks it.
    Analytics.useForTest(null);
    Analytics.canAskForTest = true;
  });

  tearDown(() {
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.views.first.reset();
    dispatcher.clearLocaleTestValue();
    dispatcher.clearLocalesTestValue();
    dispatcher.clearAlwaysUse24HourTestValue();
    Analytics.useForTest(null);
  });

  Future<void> settle(WidgetTester tester, {int frames = 14}) async {
    for (int f = 0; f < frames; f++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
  }

  /// Every picture on screen, decoded for real, which the test's clock
  /// alone never finishes.
  Future<void> decode(WidgetTester tester) async {
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
    await settle(tester, frames: 4);
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    await decode(tester);
    await expectLater(
      find.byType(MaterialApp).first,
      matchesGoldenFile('$out/onboard-$name.png'),
    );
  }

  Future<void> open(WidgetTester tester, Map<String, Object> prefs) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    // Shadows blurred, as on a phone.
    debugDisableShadows = false;
    _prefs(prefs);
    await tester.pumpWidget(const AstutoApp());
    await settle(tester, frames: 24);
  }

  Future<void> leave(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
    debugDisableShadows = true;
  }

  /// The first run, screen by screen, from a fresh install to the first
  /// card: whatever this build asks on the way, in its order. With [whole]
  /// false, only the first card, which is the one screen of the first run
  /// that follows the phone's theme.
  Future<void> firstRun(
    WidgetTester tester,
    String prefix, {
    required String theme,
    bool whole = true,
  }) async {
    final AppLocalizations l = lookupAppLocalizations(locale);
    Future<void> snap(String name) async {
      if (whole) await shoot(tester, '$prefix-$name');
    }

    await open(tester, {'knowit.theme': theme});
    // The intro: its five scenes, a tap apart.
    for (int scene = 0; scene < 5; scene++) {
      if (scene > 0) {
        await tester.tapAt(const Offset(195, 300));
        await settle(tester, frames: 20);
      }
      await snap('1-intro-$scene');
    }
    await tester.tap(find.byKey(const ValueKey('intro-start')));
    // Your mix as it opens, then, on a build that shows it, the slide
    // shown on the first subject, half way, and the grid at rest after it.
    await settle(tester, frames: 8);
    await snap('2-mix');
    if (find.byKey(const ValueKey('mix-next')).evaluate().isNotEmpty) {
      await settle(tester, frames: 12);
      await snap('2-mix-slide');
      await settle(tester, frames: 24);
      // A tap on Sport takes it out; the count under the grid says so.
      await tester.tap(find.byKey(const ValueKey('mix-sport')));
      await settle(tester, frames: 6);
      await snap('2-mix-tap');
    }
    await tester.tap(find.text(l.next));
    await settle(tester, frames: 20);
    // Which parts, on a build that still asks it in the first run.
    if (find.text(l.genresTitle).evaluate().isNotEmpty) {
      await shoot(tester, '$prefix-3-genres');
      await tester.tap(
        find.descendant(
          of: find.byType(GenresScreen),
          matching: find.byType(PrimaryButton),
        ),
      );
      await settle(tester, frames: 30);
    }
    // The three the reader loves, on a build that asks.
    final Finder loves = find.byKey(const ValueKey('loves-page'));
    if (loves.evaluate().isNotEmpty) {
      await snap('3-loves');
      for (final String key in const ['space', 'history', 'music']) {
        await tester.tap(find.byKey(ValueKey('love-$key')));
        await settle(tester, frames: 6);
      }
      await settle(tester);
      await snap('4-loves-three');
      // A fourth is one too many, and the line says so.
      await tester.tap(find.byKey(const ValueKey('love-art')));
      await settle(tester, frames: 4);
      await snap('4-loves-full');
      await settle(tester, frames: 30);
      await tester.tap(find.byKey(const ValueKey('loves-done')));
      await settle(tester, frames: 30);
    }
    await settle(tester, frames: 30);
    await shoot(tester, '$prefix-5-day');
    await leave(tester);
  }

  testWidgets('the first run, at night', (tester) async {
    await firstRun(tester, lang, theme: 'dark');
  });

  testWidgets('the first card, on paper', (tester) async {
    await firstRun(tester, '$lang-light', theme: 'light', whole: false);
  });

  // The third finished day: Which parts, offered on the shelf, at night and
  // on paper, and the page it opens. Asked of a build with nowhere to send
  // usage data, so the question about it is not the shelf's card instead.
  for (final String theme in ['dark', 'light']) {
    testWidgets('the third finished day, $theme', (tester) async {
      Analytics.canAskForTest = false;
      await open(tester, _finished(theme, days: 3));
      await settle(tester, frames: 30);
      await shoot(tester, '$lang-parts-$theme');
      if (theme == 'dark') {
        await tester.tap(find.byKey(const ValueKey('parts-offer-choose')));
        await settle(tester, frames: 30);
        await shoot(tester, '$lang-parts-page');
      }
      await leave(tester);
    });
  }

  // The 320-wide phone, no notch, in German.
  testWidgets('the first run on the small phone, in German', (tester) async {
    final dispatcher = tester.platformDispatcher;
    tester.view.physicalSize = const Size(320, 568) * 3;
    tester.view.padding = const FakeViewPadding(top: 20 * 3);
    tester.view.viewPadding = const FakeViewPadding(top: 20 * 3);
    dispatcher.localeTestValue = const Locale('de');
    dispatcher.localesTestValue = [const Locale('de')];
    final AppLocalizations l = lookupAppLocalizations(const Locale('de'));
    await open(tester, {'knowit.theme': 'dark'});
    await shoot(tester, 'de-small-1-intro-0');
    await tester.tap(find.byKey(const ValueKey('intro-start')));
    await settle(tester, frames: 20);
    await shoot(tester, 'de-small-2-mix');
    await tester.tap(find.text(l.next));
    await settle(tester, frames: 20);
    if (find.text(l.genresTitle).evaluate().isNotEmpty) {
      await shoot(tester, 'de-small-3-genres');
    }
    if (find.byKey(const ValueKey('loves-page')).evaluate().isNotEmpty) {
      for (final String key in const ['space', 'history', 'music']) {
        await tester.tap(find.byKey(ValueKey('love-$key')));
        await settle(tester, frames: 4);
      }
      await settle(tester);
      await shoot(tester, 'de-small-3-loves');
    }
    await leave(tester);
  });

  // The shelf's card on the 320-wide phone, in German.
  testWidgets('the first finished day on the small phone, in German', (
    tester,
  ) async {
    final dispatcher = tester.platformDispatcher;
    tester.view.physicalSize = const Size(320, 568) * 3;
    tester.view.padding = const FakeViewPadding(top: 20 * 3);
    tester.view.viewPadding = const FakeViewPadding(top: 20 * 3);
    dispatcher.localeTestValue = const Locale('de');
    dispatcher.localesTestValue = [const Locale('de')];
    await open(tester, _finished('dark', days: 1));
    await settle(tester, frames: 30);
    await shoot(tester, 'de-small-4-consent');
    await leave(tester);
    // Too short for the card beside the day's cards: it waits. An SE has
    // the room, and is asked.
    tester.view.physicalSize = const Size(375, 667) * 3;
    await open(tester, _finished('dark', days: 1));
    await settle(tester, frames: 30);
    await shoot(tester, 'de-se-4-consent');
    await leave(tester);
  });

  // Which parts on the 320-wide phone, in German.
  testWidgets('the third finished day on the small phone, in German', (
    tester,
  ) async {
    final dispatcher = tester.platformDispatcher;
    tester.view.physicalSize = const Size(320, 568) * 3;
    tester.view.padding = const FakeViewPadding(top: 20 * 3);
    tester.view.viewPadding = const FakeViewPadding(top: 20 * 3);
    dispatcher.localeTestValue = const Locale('de');
    dispatcher.localesTestValue = [const Locale('de')];
    Analytics.canAskForTest = false;
    await open(tester, _finished('dark', days: 3));
    await settle(tester, frames: 30);
    await shoot(tester, 'de-small-5-parts');
    await leave(tester);
    tester.view.physicalSize = const Size(375, 667) * 3;
    await open(tester, _finished('dark', days: 3));
    await settle(tester, frames: 30);
    await shoot(tester, 'de-se-5-parts');
    await leave(tester);
  });

  // The first finished day's shelf, at night and on paper.
  for (final String theme in ['dark', 'light']) {
    testWidgets('the first finished day, $theme', (tester) async {
      await open(tester, _finished(theme, days: 1));
      await settle(tester, frames: 30);
      await shoot(tester, '$lang-consent-$theme');
      await leave(tester);
    });
  }
}
