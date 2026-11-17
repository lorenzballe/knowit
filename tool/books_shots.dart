// Photographs Books in pills (explore/blocks/core/books_block.dart): the row
// of books in Explore, and the card that ends a book's free ideas.
//
//   flutter test tool/books_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it.
// SHOTS (a folder) and LANG_SHOT (a language, Italian by default) move it.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/core/books_block.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/web/card_thumb.dart';

import '../test/explore/core_harness.dart';

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
}
