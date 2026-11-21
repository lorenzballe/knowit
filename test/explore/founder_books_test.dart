// What the founders read (explore/blocks/core/books_block.dart,
// lib/data/book_picks.dart): the books in pills that the people who built
// the companies everyone knows recommended in public, under their names, and
// on a book's page who said it, in their words, and where.
//
//   flutter test test/explore/founder_books_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/book_picks.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/explore/blocks/core/books_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';

import 'core_harness.dart';

Future<AppState> _app() async {
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
  final app = AppState();
  await app.init();
  return app;
}

final List<ExploreSection> _sections = sectionsOf([
  {
    'id': 'founder-books',
    'block': 'founder-books',
    'title': {'en': 'What the founders read'},
    'subtitle': {'en': 'Books they recommended, with where they said it.'},
  },
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final DateTime monday = DateTime(2026, 11, 16);

  test('every pick is of a whole book of the bank, said in public, with '
      'the page where anyone can read it', () {
    final Set<String> books = {
      for (final CardBook b in booksOf(PillBank.live, today: monday)) b.id,
    };
    expect(bookPicks.length, greaterThanOrEqualTo(FounderBooksBlock.fewest));
    for (final MapEntry<String, List<BookPick>> e in bookPicks.entries) {
      // A book still being written waits with its picks for its cards.
      if (!books.contains(e.key)) {
        expect(bookPicksComing, contains(e.key), reason: e.key);
      }
      expect(e.value, isNotEmpty, reason: e.key);
      final Set<String> who = {};
      for (final BookPick k in e.value) {
        expect(who.add(k.who), isTrue, reason: '${e.key}: ${k.who} twice');
        expect(k.who.trim(), isNotEmpty);
        expect(k.role.trim(), isNotEmpty);
        expect(k.where.trim(), isNotEmpty);
        expect(k.year, inInclusiveRange(1990, 2026), reason: k.who);
        expect(Uri.parse(k.url).scheme, 'https', reason: k.url);
        // Typeset like the cards: no straight quote marks.
        expect(k.said.contains("'") || k.said.contains('"'), isFalse);
      }
    }
  });

  testWidgets('on Explore: the books under the names of who recommended '
      'them; none of them, no shelf on a subject with fewer than two', (
    tester,
  ) async {
    final AppState app = await _app();
    await pumpSections(tester, CoreHost(app), _sections);
    expect(find.text('What the founders read'), findsOneWidget);
    final Finder tiles = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('founder-book-'),
    );
    expect(tiles, findsWidgets);
    final String id = (tester.widget(tiles.first).key! as ValueKey<String>)
        .value
        .substring('founder-book-'.length);
    expect(picksOf(id), isNotEmpty);
    expect(
      find.descendant(
        of: tiles.first,
        matching: find.text(
          [for (final BookPick k in picksOf(id)) k.who]
              .join(' · ')
              .toUpperCase(),
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    // A subject whose books nobody here recommended has no shelf.
    final String none = kTopics.entries
        .firstWhere(
          (t) => booksOf(
            PillBank.live,
            today: app.today,
            subject: t.value.name,
          ).where((b) => picksOf(b.id).isNotEmpty).isEmpty,
        )
        .value
        .name;
    await pumpSections(tester, CoreHost(app, subject: none), _sections);
    expect(find.text('What the founders read'), findsNothing);
  });

  testWidgets("a book's page says who recommended it, in their words, and "
      'where', (tester) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final AppState app = await _app();
    final CardBook sapiens = booksOf(
      PillBank.live,
      today: app.today,
    ).firstWhere((b) => b.id == 'sapiens');
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.light),
        home: BookScreen(app: app, book: sapiens),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('RECOMMENDED BY'), findsOneWidget);
    for (final BookPick k in picksOf('sapiens')) {
      expect(find.byKey(ValueKey('book-pick-${k.who}')), findsOneWidget);
      expect(find.text(k.role), findsOneWidget);
      expect(find.text('${k.where}, ${k.year}'), findsOneWidget);
      if (k.said.isNotEmpty) expect(find.text('“${k.said}”'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);

    // A book nobody here recommended says nothing of the kind.
    final CardBook other = booksOf(
      PillBank.live,
      today: app.today,
    ).firstWhere((b) => picksOf(b.id).isEmpty);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.light),
        home: BookScreen(app: app, book: other),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('RECOMMENDED BY'), findsNothing);
  });
}
