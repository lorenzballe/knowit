// Photographs Books in pills (explore/blocks/core/books_block.dart): the row
// of books in Explore, and the card that ends a book's free ideas; and, on
// a 390 by 844 phone, Explore as the bundled document lays it, at the books
// and at what the founders read, and a founder's own page.
//
//   flutter test tool/books_shots.dart --update-goldens
//   flutter test tool/books_shots.dart --plain-name phone --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it.
// SHOTS (a folder) and LANG_SHOT (a language, Italian by default) move it,
// and PAPER=1 takes the phone on paper rather than at night.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/core/books_block.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/ui.dart' show BackCircle;
import 'package:astuto/widgets/web/card_thumb.dart';

import '../test/explore/core_harness.dart';

/// A picture of the bank's own, from the folder the site serves it from: a
/// card's from web/cards/thumbs/, a book's cover from web/cards/covers/.
final Map<String, ImageProvider> _pictures = {};
ImageProvider _picture(Uri url) {
  final List<String> path = url.pathSegments;
  final String rel = path.sublist(path.indexOf('cards') + 1).join('/');
  return _pictures.putIfAbsent(rel, () {
    final File file = File('web/cards/$rel');
    return MemoryImage(
      file.existsSync() ? file.readAsBytesSync() : Uint8List(0),
    );
  });
}

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
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
  await _settle(tester, 5);
}

void main() {
  setUpAll(loadFonts);

  testWidgets('books in pills', (tester) async {
    // The covers from the site's folder, as the site publishes them.
    final Map<String, ImageProvider> covers = {};
    CardThumb.image = (url) => covers.putIfAbsent(
      url.pathSegments.last,
      () => MemoryImage(
        File('web/cards/covers/${url.pathSegments.last}').readAsBytesSync(),
      ),
    );
    final String out = Platform.environment['SHOTS'] ?? 'shots';
    final Locale locale = Locale(Platform.environment['LANG_SHOT'] ?? 'it');
    final app = await readyApp();
    final List<ExploreSection> sections = sectionsOf([
      {
        'id': 'books',
        'block': 'books',
        'title': {'en': 'Books in pills', 'it': 'Libri in pillole'},
        'subtitle': {
          'en': "The big ideas of bestsellers, five cards a book, a few minutes in all.",
          'it': "Le grandi idee dei bestseller, cinque carte a libro, pochi minuti in tutto.",
        },
      },
    ]);
    for (final bool paper in [false, true]) {
      await pumpSections(
        tester,
        CoreHost(app, language: locale.languageCode),
        sections,
        size: const Size(402, 360),
        paper: paper,
        locale: locale,
      );
      // The covers decoded before the picture, as a phone has them by the
      // time the row scrolls into view.
      for (final Element e in find.byType(Image).evaluate().toList()) {
        await tester.runAsync(
          () => precacheImage(
            (e.widget as Image).image,
            e,
          ).timeout(const Duration(seconds: 10), onTimeout: () {}),
        );
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      for (int f = 0; f < 6; f++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('$out/books${paper ? '-light' : ''}.png'),
      );
    }

    // The card that ends a book's free ideas.
    final CardBook book = booksOf(PillBank.live, today: app.today)[1];
    tester.view.physicalSize = const Size(402, 680) * 3;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: BookMore(app: app, book: book),
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('$out/book-more.png'),
    );

    // A book's own page, two ideas read.
    final CardBook page = booksOf(PillBank.live, today: app.today).first;
    app.seenIds = {page.cards[0].id, page.cards[1].id};
    tester.view.physicalSize = const Size(402, 1180) * 3;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        debugShowCheckedModeBanner: false,
        home: BookScreen(app: app, book: page, weekly: null),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    for (int f = 0; f < 6; f++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(BookScreen),
      matchesGoldenFile('$out/book-page.png'),
    );

    // The library: every book at once.
    tester.view.physicalSize = const Size(402, 874) * 3;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        debugShowCheckedModeBanner: false,
        home: LibraryScreen(
          app: app,
          weekly: bookOfTheWeek(PillBank.live, app.today),
        ),
      ),
    );
    for (final Element e in find.byType(Image).evaluate().toList()) {
      await tester.runAsync(
        () => precacheImage(
          (e.widget as Image).image,
          e,
        ).timeout(const Duration(seconds: 10), onTimeout: () {}),
      );
    }
    for (int f = 0; f < 6; f++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(LibraryScreen),
      matchesGoldenFile('$out/books-library.png'),
    );
  });

  // Explore on a 390 by 844 phone, as the document the build bundles lays
  // it: the books, then what the founders read, then a founder's own page,
  // from the top and further down. A reader a few books in: one read whole,
  // one stopped at its third idea.
  testWidgets('books and founders on a phone', (tester) async {
    final String out = Platform.environment['SHOTS'] ?? 'shots';
    final String lang = Platform.environment['LANG_SHOT'] ?? 'it';
    final bool paper = Platform.environment['PAPER'] == '1';
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
    Remote.build = 99;
    CardThumb.image = _picture;
    const Size phone = Size(390, 844);
    const double ratio = 3;
    final view = tester.view;
    view.physicalSize = phone * ratio;
    view.devicePixelRatio = ratio;
    view.padding = const FakeViewPadding(top: 47 * ratio, bottom: 34 * ratio);
    view.viewPadding = view.padding;
    tester.platformDispatcher.localesTestValue = [Locale(lang)];
    tester.platformDispatcher.localeTestValue = Locale(lang);
    addTearDown(() {
      view.reset();
      tester.platformDispatcher.clearLocalesTestValue();
      tester.platformDispatcher.clearLocaleTestValue();
    });
    final List<CardBook> books = booksOf(PillBank.live, today: DateTime.now());
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      'knowit.pushAsked': true,
      if (paper) 'knowit.theme': 'light',
      'knowit.seenIds': [
        for (final p in books[2].cards) p.id,
        for (final p in books[4].cards.take(2)) p.id,
      ],
    });
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester, 20);
    await tester.tap(find.byKey(const ValueKey('tab-Explore')).first);
    await _settle(tester, 20);
    final String name = '390-$lang-${paper ? 'light' : 'dark'}';
    Future<void> take(String shot) async {
      await _decodeShown(tester);
      await expectLater(
        find.byType(MaterialApp).first,
        matchesGoldenFile('$out/$name-$shot.png'),
      );
    }

    final Finder down = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first;
    // Scrolls until the section [id] is drawn, then brings its top to
    // [above] points under the top of the screen.
    Future<void> reach(String id, {double above = 100}) async {
      final Finder target = find.byKey(
        ValueKey('section-$id'),
        skipOffstage: false,
      );
      final ScrollableState list = tester.state(down);
      for (int i = 0; i < 80 && target.evaluate().isEmpty; i++) {
        list.position.jumpTo(list.position.pixels + 400);
        await tester.pump();
      }
      await tester.pump();
      final double top = tester.getTopLeft(target).dy;
      list.position.jumpTo(list.position.pixels + top - above);
      await _settle(tester);
    }

    // Scrolls the page in front by [by] points, as far as it goes.
    Future<void> scrollPage(double by) async {
      final ScrollableState list = tester.state(
        find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .last,
      );
      list.position.jumpTo(
        (list.position.pixels + by).clamp(0, list.position.maxScrollExtent),
      );
      await _settle(tester);
    }

    await reach('books');
    await take('books');
    await reach('founders', above: 140);
    await take('founders');
    // A founder's own page, out of the first tile, from the top and
    // further down.
    await tester.tap(find.byKey(const ValueKey('founder-bill-gates')));
    await _settle(tester, 20);
    await take('founder');
    await scrollPage(560);
    await take('founder-down');
    // Its foot: recommended in public, no tie to Astute, who took the photo.
    await scrollPage(100000);
    await take('founder-foot');
    await scrollPage(-100000);
    await scrollPage(560);
    // One of their books' own page, at who recommended it.
    await tester.tap(find.byKey(const ValueKey('founder-book-sapiens')));
    await _settle(tester, 20);
    await scrollPage(520);
    await take('book-picks');
    // Back to Explore, and Economics alone: its books, then the ones the
    // founders recommended, in one list.
    for (int i = 0; i < 2; i++) {
      await tester.tap(find.byType(BackCircle).last);
      await _settle(tester, 12);
    }
    final ScrollableState explore = tester.state(down);
    explore.position.jumpTo(0);
    await _settle(tester);
    final Finder chip = find.byKey(const ValueKey('subject-Economics-off'));
    await tester.ensureVisible(chip);
    await _settle(tester);
    await tester.tap(chip);
    await _settle(tester, 20);
    await reach('books');
    await take('subject-books');
    await reach('founders', above: 110);
    await take('subject-founders');
    debugDefaultTargetPlatformOverride = null;
  });
}
