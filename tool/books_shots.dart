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

import '../test/explore/core_harness.dart';

void main() {
  setUpAll(loadFonts);

  testWidgets('books in pills', (tester) async {
    final String out = Platform.environment['SHOTS'] ?? 'shots';
    final Locale locale = Locale(Platform.environment['LANG_SHOT'] ?? 'it');
    final app = await readyApp();
    final List<ExploreSection> sections = sectionsOf([
      {
        'id': 'books',
        'block': 'books',
        'title': {'en': 'Books in pills', 'it': 'Libri in pillole'},
        'subtitle': {
          'en': "A book's big ideas in five cards, a few minutes each.",
          'it':
              "Le grandi idee di un libro in cinque carte, pochi minuti l'una.",
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
  });
}
