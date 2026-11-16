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

  test('a book is read from the card file', () {
    final Pill card = PillBank.live.firstWhere((p) => p.book != null);
    expect(card.book!.part, greaterThanOrEqualTo(1));
    expect(card.book!.year, greaterThan(1900));
  });
}
