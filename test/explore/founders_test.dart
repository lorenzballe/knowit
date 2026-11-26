// What founders read (explore/blocks/core/founders_block.dart,
// lib/data/founders.dart): on Explore for every subject, a row of the people
// who built the companies everyone knows, each with their face, opening a
// page of the books in pills they recommended in public, with their words
// and where they said them, that they have no connection with Astute, and
// who took the photo; on a subject's page, that subject's books they
// recommended, in one list. A book's page says who recommended it. Nothing
// is ever cut short.
//
//   flutter test test/explore/founders_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/founders.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/core/books_block.dart';
import 'package:astuto/explore/blocks/core/founders_block.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
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
    'id': 'founders',
    'block': 'founders',
    'title': {'en': 'What founders read', 'it': 'Cosa leggono i fondatori'},
    'subtitle': {
      'en':
          'Each with the books they recommended in public, and where '
          'they said it.',
    },
  },
]);

Future<void> _page(WidgetTester tester, Widget home, {double text = 1}) async {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(text)),
          child: home,
        ),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// No words on screen cut short: no ellipsis asked for, and none needed.
void _nothingCut(WidgetTester tester) {
  for (final Text t in tester.widgetList<Text>(find.byType(Text))) {
    expect(t.overflow, isNot(TextOverflow.ellipsis), reason: t.data);
  }
  for (final RenderParagraph r in tester.renderObjectList<RenderParagraph>(
    find.byType(RichText),
  )) {
    expect(r.didExceedMaxLines, isFalse, reason: r.text.toPlainText());
  }
}

final Founder _gates = founderById('bill-gates')!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  final DateTime monday = DateTime(2026, 11, 16);

  test('every pick is of a book in pills, said in public, quoted as said, '
      'with the page where anyone can read it', () {
    final Set<String> books = {
      for (final CardBook b in booksOf(PillBank.live, today: monday)) b.id,
    };
    final Set<String> ids = {};
    final Set<String> names = {};
    expect(kFounders.length, greaterThanOrEqualTo(FoundersBlock.fewest));
    for (final Founder f in kFounders) {
      expect(ids.add(f.id), isTrue, reason: f.id);
      expect(names.add(f.name), isTrue, reason: f.name);
      expect(f.id, matches(RegExp(r'^[a-z]+(-[a-z]+)+$')), reason: f.id);
      expect(f.role.trim(), isNotEmpty, reason: f.name);
      expect(f.monogram, matches(RegExp(r'^[A-Z]{2}$')), reason: f.name);
      expect(f.picks, isNotEmpty, reason: f.name);
      final Set<String> theirs = {};
      for (final BookPick k in f.picks) {
        final String at = '${f.name}: ${k.book}';
        // Only a book the app has in pills, and opens: nothing listed that
        // the app does not show.
        expect(books, contains(k.book), reason: at);
        expect(theirs.add(k.book), isTrue, reason: '$at twice');
        expect(k.where.trim(), isNotEmpty, reason: at);
        expect(k.year, inInclusiveRange(1990, 2026), reason: at);
        expect(Uri.parse(k.url).scheme, 'https', reason: at);
        // Typeset like the cards: no straight quote marks.
        expect(k.said.contains("'") || k.said.contains('"'), isFalse);
      }
      // The one they said most about first: their words before a list.
      final int listed = f.picks.indexWhere((k) => k.said.isEmpty);
      if (listed != -1) {
        expect(f.picks.skip(listed).every((k) => k.said.isEmpty), isTrue);
      }
    }
    expect(_gates.monogram, 'BG');
    expect(founderById('tobi-lutke')!.name, 'Tobi Lütke');
    expect(founderById('nobody'), isNull);
    // A place said as a phrase is set up on its own line, with the year.
    expect(
      founderById('warren-buffett')!.picks[1].source,
      'His letter to Berkshire Hathaway’s shareholders, 2017',
    );
  });

  test('every face is a photo free to use from Wikimedia Commons, kept small '
      'in the app, credited beside it in CREDITS.md and on the page', () {
    final String credits = File('assets/founders/CREDITS.md')
        .readAsStringSync();
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- assets/founders/'),
    );
    for (final Founder f in kFounders) {
      final FounderPhoto? photo = f.photo;
      expect(photo, isNotNull, reason: f.name);
      expect(
        photo!.licence,
        matches(RegExp(r'^(CC0|Public domain|CC BY(-SA)? \d\.\d)$')),
        reason: f.name,
      );
      expect(photo.author.trim(), isNotEmpty, reason: f.name);
      expect(Uri.parse(photo.page).host, 'commons.wikimedia.org');
      final File file = File(f.photoAsset);
      expect(file.existsSync(), isTrue, reason: f.photoAsset);
      expect(file.lengthSync(), lessThan(40 * 1024), reason: f.photoAsset);
      for (final String said in [
        f.name,
        photo.author,
        photo.licence,
        photo.page,
      ]) {
        expect(credits, contains(said), reason: '${f.name}: $said');
      }
    }
    expect(credits, contains('cropped'));
    // Nothing kept that no one shows.
    expect(
      {
        for (final FileSystemEntity e in Directory(
          'assets/founders',
        ).listSync())
          e.uri.pathSegments.last,
      },
      {'CREDITS.md', for (final Founder f in kFounders) '${f.id}.webp'},
    );
  });

  test('a book of the bank is who recommended it, in the row\'s order; a '
      'pick whose book is not in pills is passed over, and so is a person '
      'with none', () {
    expect(
      [for (final (Founder f, _) in picksOf('sapiens')) f.name],
      ['Bill Gates', 'Mark Zuckerberg', 'Naval Ravikant'],
    );
    expect(picksOf('no-such-book'), isEmpty);

    final List<FounderShelf> all = foundersOf(PillBank.live, today: monday);
    expect(
      [for (final s in all) s.founder.id],
      [for (final f in kFounders) f.id],
    );
    // Without Sapiens in the bank, Naval Ravikant has nothing in pills.
    final List<Pill> without = [
      for (final Pill p in PillBank.live)
        if (p.book?.id != 'sapiens') p,
    ];
    final List<FounderShelf> fewer = foundersOf(without, today: monday);
    expect(fewer.map((s) => s.founder.id), isNot(contains('naval-ravikant')));
    final FounderShelf gates = fewer.firstWhere(
      (s) => s.founder.id == 'bill-gates',
    );
    expect(gates.books.map((b) => b.$2.id), isNot(contains('sapiens')));
    expect(gates.books, hasLength(_gates.picks.length - 1));
  });

  test('a subject\'s books are listed once each, whoever said something of '
      'it first', () {
    final List<SubjectPick> history = subjectPicksOf(
      PillBank.live,
      today: monday,
      subject: 'History',
    );
    expect(
      {for (final k in history) k.book.id},
      {'sapiens', 'guns-germs-and-steel'},
    );
    final SubjectPick sapiens = history.firstWhere(
      (k) => k.book.id == 'sapiens',
    );
    // Mark Zuckerberg's was a list with no words of its own: after those
    // who said something.
    expect(
      [for (final (f, _) in sapiens.picks) f.name],
      ['Bill Gates', 'Naval Ravikant', 'Mark Zuckerberg'],
    );
    expect(
      subjectPicksOf(PillBank.live, today: monday, subject: 'Art'),
      isEmpty,
    );
  });

  testWidgets('on Explore: a tile for each person, their face, how many '
      'books, their name and what they built, none of it cut', (tester) async {
    final AppState app = await _app();
    await pumpSections(tester, CoreHost(app), _sections);
    expect(find.text('What founders read'), findsOneWidget);
    final Finder gates = find.byKey(const ValueKey('founder-bill-gates'));
    expect(gates, findsOneWidget);
    expect(
      find.descendant(of: gates, matching: find.byType(FounderFace)),
      findsOneWidget,
    );
    for (final String words in [
      'Bill Gates',
      'Co-founder of Microsoft',
      '6 BOOKS',
    ]) {
      expect(
        find.descendant(of: gates, matching: find.text(words)),
        findsOneWidget,
        reason: words,
      );
    }
    _nothingCut(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with no title from the document, the row is called what it is '
      'in the reader\'s language', (tester) async {
    final AppState app = await _app();
    await pumpSections(
      tester,
      CoreHost(app, language: 'it'),
      sectionsOf([
        {'id': 'founders', 'block': 'founders'},
      ]),
      locale: const Locale('it'),
    );
    expect(find.text('Cosa leggono i fondatori'), findsOneWidget);
    expect(find.text('6 LIBRI'), findsOneWidget);
  });

  testWidgets('on a subject\'s page: its books they recommended, one list, '
      'each with the face, name and words of who said it, and who else did', (
    tester,
  ) async {
    final AppState app = await _app();
    await pumpSections(
      tester,
      CoreHost(app, subject: 'History'),
      _sections,
      size: const Size(390, 1400),
    );
    expect(find.text('What founders read'), findsOneWidget);
    // Not the row of people.
    expect(find.byKey(const ValueKey('founder-bill-gates')), findsNothing);
    final Finder sapiens = find.byKey(const ValueKey('subject-pick-sapiens'));
    expect(sapiens, findsOneWidget);
    expect(
      find.byKey(const ValueKey('subject-pick-guns-germs-and-steel')),
      findsOneWidget,
    );
    final BookPick said = _gates.picks.firstWhere((k) => k.book == 'sapiens');
    expect(
      find.descendant(of: sapiens, matching: find.text('“${said.said}”')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sapiens,
        matching: find.text('Bill Gates · ${said.source} ↗'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sapiens, matching: find.byType(FounderFace)),
      findsOneWidget,
    );
    expect(
      find.text('Also recommended by Naval Ravikant, Mark Zuckerberg'),
      findsOneWidget,
    );
    _nothingCut(tester);
    expect(tester.takeException(), isNull);

    // A subject none of whose books they recommended has no section.
    await pumpSections(tester, CoreHost(app, subject: 'Art'), _sections);
    expect(find.text('What founders read'), findsNothing);
  });

  testWidgets('a tile opens the person\'s page', (tester) async {
    final AppState app = await _app();
    await pumpSections(
      tester,
      CoreHost(app),
      _sections,
      size: const Size(390, 844),
    );
    await tester.tap(find.byKey(const ValueKey('founder-bill-gates')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(FounderScreen), findsOneWidget);
    expect(find.text('Bill Gates'), findsOneWidget);
    expect(find.text('6 books · 30 ideas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the page, whole: the face, every book of theirs in pills in '
      'their order with their words and its source, that they have no tie '
      'to Astute, and who took the photo', (tester) async {
    final AppState app = await _app();
    final FounderShelf gates = foundersOf(
      PillBank.live,
      today: app.today,
    ).firstWhere((s) => s.founder.id == 'bill-gates');
    await _page(tester, FounderScreen(app: app, shelf: gates));
    expect(find.byType(FounderFace), findsOneWidget);
    expect(find.text('Co-founder of Microsoft'), findsOneWidget);
    expect(find.text('THE BOOKS THEY RECOMMENDED'), findsOneWidget);
    for (final (BookPick pick, CardBook book) in gates.books) {
      final Finder row = find.byKey(ValueKey('founder-book-${book.id}'));
      expect(row, findsOneWidget, reason: book.id);
      // The title beside the cover (and on the cover drawn while the
      // edition's own comes).
      expect(
        find.descendant(of: row, matching: find.text(book.book.title)),
        findsWidgets,
      );
      if (pick.said.isNotEmpty) {
        expect(
          find.descendant(of: row, matching: find.text('“${pick.said}”')),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(of: row, matching: find.text('${pick.source} ↗')),
        findsOneWidget,
      );
    }
    // In their order: the first above the second.
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('founder-book-business-adventures')),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('founder-book-factfulness')))
            .dy,
      ),
    );
    expect(
      find.text(
        'These are books Bill Gates recommended in public, in the words '
        'quoted, each with where it was said. Bill Gates has no connection '
        'with Astute.',
      ),
      findsOneWidget,
    );
    final FounderPhoto photo = _gates.photo!;
    expect(
      find.text(
        'Photo: ${photo.author}, ${photo.licence}, Wikimedia Commons, '
        'cropped ↗',
      ),
      findsOneWidget,
    );
    _nothingCut(tester);
    expect(tester.takeException(), isNull);

    // A book of theirs opens its own page.
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('founder-book-factfulness')),
        matching: find.byType(BookCover),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(BookScreen), findsOneWidget);
  });

  testWidgets('at twice the text size the row, the list and the page still '
      'fit, nothing cut', (tester) async {
    final AppState app = await _app();
    await pumpSections(tester, CoreHost(app), _sections, text: 2);
    expect(find.byKey(const ValueKey('founder-bill-gates')), findsOneWidget);
    _nothingCut(tester);
    expect(tester.takeException(), isNull);
    await pumpSections(
      tester,
      CoreHost(app, subject: 'Economics'),
      _sections,
      text: 2,
      size: const Size(375, 2400),
    );
    expect(
      find.byKey(const ValueKey('subject-pick-business-adventures')),
      findsOneWidget,
    );
    _nothingCut(tester);
    expect(tester.takeException(), isNull);
    final FounderShelf buffett = foundersOf(
      PillBank.live,
      today: app.today,
    ).firstWhere((s) => s.founder.id == 'warren-buffett');
    await _page(tester, FounderScreen(app: app, shelf: buffett), text: 2);
    expect(find.text('Warren Buffett'), findsOneWidget);
    _nothingCut(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a book's page says who recommended it, with their face, in "
      'their words, where, and who took the photo', (tester) async {
    final AppState app = await _app();
    final CardBook sapiens = booksOf(
      PillBank.live,
      today: app.today,
    ).firstWhere((b) => b.id == 'sapiens');
    await _page(tester, BookScreen(app: app, book: sapiens));
    expect(find.text('RECOMMENDED BY'), findsOneWidget);
    for (final (Founder who, BookPick k) in picksOf('sapiens')) {
      final Finder row = find.byKey(ValueKey('book-pick-${who.id}'));
      expect(row, findsOneWidget, reason: who.name);
      expect(
        find.descendant(of: row, matching: find.text(who.role)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.byType(FounderFace)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('${k.source} ↗')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.byType(FounderPhotoCredit)),
        findsOneWidget,
      );
      if (k.said.isNotEmpty) {
        expect(
          find.descendant(of: row, matching: find.text('“${k.said}”')),
          findsOneWidget,
        );
      }
    }
    _nothingCut(tester);
    expect(tester.takeException(), isNull);

    // A book nobody here recommended says nothing of the kind.
    final CardBook other = booksOf(
      PillBank.live,
      today: app.today,
    ).firstWhere((b) => picksOf(b.id).isEmpty);
    await _page(tester, BookScreen(app: app, book: other));
    expect(find.text('RECOMMENDED BY'), findsNothing);
  });
}
