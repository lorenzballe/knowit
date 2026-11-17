// Books in pills (explore/blocks/core/books_block.dart): a book's big ideas,
// a card each, in the book's order; one book a week whole for everybody, the
// rest two ideas free and then the way to Astute+.
//
//   flutter test test/explore/books_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/core/books_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';

Future<AppState> _app({bool plus = false}) async {
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    'knowit.plus': plus,
  });
  final app = AppState();
  await app.init();
  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final DateTime monday = DateTime(2026, 11, 16);

  test('the bank holds whole books, their ideas in the book\'s order', () {
    final List<CardBook> books = booksOf(PillBank.live, today: monday);
    expect(books.length, greaterThanOrEqualTo(8));
    for (final CardBook b in books) {
      expect(b.cards.length, inInclusiveRange(4, 8));
      expect(
        [for (final p in b.cards) p.book!.part],
        [for (var i = 1; i <= b.cards.length; i++) i],
      );
      expect(b.cards.every((p) => p.book!.title == b.book.title), isTrue);
      // Every idea says where it comes from, and goes deeper.
      expect(b.cards.every((p) => p.source.contains(b.book.author)), isTrue);
      expect(b.cards.every((p) => p.why.isNotEmpty), isTrue);
    }
  });

  test('a book a week, the same for everyone, turning each week', () {
    final String? now = bookOfTheWeek(PillBank.live, monday);
    final String? next = bookOfTheWeek(
      PillBank.live,
      monday.add(const Duration(days: 7)),
    );
    expect(now, isNotNull);
    expect(next, isNot(now));
    expect(booksOf(PillBank.live, today: monday).first.id, now);
  });

  test('a subject in view keeps only its books', () {
    final CardBook any = booksOf(PillBank.live, today: monday).first;
    final List<CardBook> only = booksOf(
      PillBank.live,
      today: monday,
      subject: any.first.topic,
    );
    expect(only, isNotEmpty);
    expect(only.every((b) => b.first.topic == any.first.topic), isTrue);
  });

  testWidgets('on the free plan a book stops after two ideas, on the card '
      'that offers the rest', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final AppState app = await _app();
    final List<CardBook> books = booksOf(PillBank.live, today: app.today);
    final String? weekly = bookOfTheWeek(PillBank.live, app.today);
    final CardBook other = books.firstWhere((b) => b.id != weekly);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: Scaffold(
          body: SizedBox(
            height: 700,
            child: BookMore(app: app, book: other),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('book-more')), findsOneWidget);
    expect(find.text(other.cards[kBookFree].question), findsOneWidget);
    expect(
      find.text('${other.cards.length - kBookFree} more ideas from this book'),
      findsOneWidget,
    );
  });

  Future<void> page(WidgetTester tester, AppState app, CardBook book) async {
    tester.view.physicalSize = const Size(420, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.light),
        home: BookScreen(
          app: app,
          book: book,
          weekly: bookOfTheWeek(PillBank.live, app.today),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('a book\'s page: why it is worth the minutes, its ideas in '
      'order, the free ones open and the rest for Astute+', (tester) async {
    final AppState app = await _app();
    final String? weekly = bookOfTheWeek(PillBank.live, app.today);
    final CardBook other = booksOf(
      PillBank.live,
      today: app.today,
    ).firstWhere((b) => b.id != weekly);
    await page(tester, app, other);
    expect(find.text(other.book.title), findsWidgets);
    expect(find.text(other.book.badge), findsOneWidget);
    expect(find.byKey(const ValueKey('book-go')), findsOneWidget);
    for (var i = 0; i < other.cards.length; i++) {
      expect(find.byKey(ValueKey('book-idea-$i')), findsOneWidget);
    }
    expect(
      find.byIcon(Icons.lock_rounded),
      findsNWidgets(other.cards.length - kBookFree),
    );
    // The idea past the free ones goes through the plans.
    await tester.tap(find.byKey(ValueKey('book-idea-$kBookFree')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(
      tester.widget<PaywallScreen>(find.byType(PaywallScreen)).source,
      'book idea',
    );
  });

  testWidgets('the book of the week, and every book on Astute+, open whole', (
    tester,
  ) async {
    final AppState free = await _app();
    final CardBook weekly = booksOf(PillBank.live, today: free.today).first;
    await page(tester, free, weekly);
    expect(find.byIcon(Icons.lock_rounded), findsNothing);

    final AppState plus = await _app(plus: true);
    final CardBook other = booksOf(PillBank.live, today: plus.today).last;
    await page(tester, plus, other);
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
  });

  test('a book takes a few honest minutes, never under three', () {
    for (final CardBook b in booksOf(PillBank.live, today: monday)) {
      expect(bookMinutes(b), inInclusiveRange(3, 12));
    }
  });

  test('every book says why it is worth reading, and names its edition', () {
    for (final CardBook b in booksOf(PillBank.live, today: monday)) {
      expect(b.book.badge, isNotEmpty);
      expect(b.book.isbn, matches(RegExp(r'^97[89]\d{10}$')));
    }
  });

  testWidgets('a book read whole ends on the card that says so, counts the '
      'books finished and offers the next', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final AppState app = await _app(plus: true);
    final List<CardBook> books = booksOf(PillBank.live, today: app.today);
    // One book already read before this one.
    app.seenIds = {for (final p in books[1].cards) p.id};
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: Scaffold(
          body: SizedBox(
            height: 700,
            child: BookDone(app: app, book: books[0]),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Book finished'), findsOneWidget);
    expect(find.text('Books finished: 2'), findsOneWidget);
    // The next is the first not yet read, never the one just finished.
    expect(find.byKey(const ValueKey('book-done-next')), findsOneWidget);
    expect(find.textContaining(books[2].book.title), findsOneWidget);
  });

  testWidgets('the library shows every book at once, the week\'s first', (
    tester,
  ) async {
    final AppState app = await _app();
    final List<CardBook> books = booksOf(PillBank.live, today: app.today);
    // Tall enough for every row of covers, so the grid builds them all.
    tester.view.physicalSize = Size(402, 320.0 * ((books.length + 2) ~/ 3) + 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: LibraryScreen(app: app, weekly: books.first.id),
      ),
    );
    await tester.pump();
    expect(find.text('All the books'), findsOneWidget);
    for (final CardBook b in books) {
      expect(find.byKey(ValueKey('book-${b.id}')), findsOneWidget);
    }
  });

  test('a book is read from the card file', () {
    final Pill card = PillBank.live.firstWhere((p) => p.book != null);
    expect(card.book!.part, greaterThanOrEqualTo(1));
    expect(card.book!.year, greaterThan(1900));
  });
}
