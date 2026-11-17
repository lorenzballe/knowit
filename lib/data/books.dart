/// Books in pills, as data: a book is the cards of the bank that name it
/// (`book` on the card, see [PillBook]), four to eight ideas in the book's
/// own order. Explore's row draws them (explore/blocks/core/books_block.dart);
/// the reminders name the week's book from here.
library;

import 'dart:math' as math;

import '../models/pill.dart';

/// How many of a book's ideas the free plan reads: the way in.
const int kBookFree = 2;

/// One book: what it is, and its ideas in order.
class CardBook {
  const CardBook(this.book, this.cards);

  /// The book, as its first card names it.
  final PillBook book;

  /// Its ideas, part 1 first.
  final List<Pill> cards;

  String get id => book.id;
  Pill get first => cards.first;
}

/// The books of [bank], whole ones only (four ideas or more), the book of
/// the week first, the rest in a weekly turn: the same for every reader.
/// Narrowed to [subject] (a subject's name) when there is one.
List<CardBook> booksOf(
  List<Pill> bank, {
  required DateTime today,
  String? subject,
}) {
  final Map<String, List<Pill>> byBook = {};
  for (final Pill p in bank) {
    final PillBook? b = p.book;
    if (b == null) continue;
    byBook.putIfAbsent(b.id, () => []).add(p);
  }
  final List<CardBook> all = [
    for (final MapEntry<String, List<Pill>> e in byBook.entries)
      if (e.value.length >= 4)
        CardBook(
          (e.value..sort((a, b) => a.book!.part.compareTo(b.book!.part)))
              .first
              .book!,
          e.value,
        ),
  ]..sort((a, b) => a.id.compareTo(b.id));
  if (all.isEmpty) return const [];
  final int week = today.difference(DateTime(2026)).inDays ~/ 7;
  final int start = week % all.length;
  final List<CardBook> turned = [
    for (int i = 0; i < all.length; i++) all[(start + i) % all.length],
  ];
  return subject == null
      ? turned
      : [
          for (final CardBook b in turned)
            if (b.first.topic == subject) b,
        ];
}

/// The book every reader reads whole this week: the first of [booksOf]
/// for the whole bank, whatever subject is in view.
String? bookOfTheWeek(List<Pill> bank, DateTime today) {
  final List<CardBook> books = booksOf(bank, today: today);
  return books.isEmpty ? null : books.first.id;
}

/// About how long a book takes: its words at an unhurried reading pace, and
/// half a minute an idea to think and answer; never under three minutes.
int bookMinutes(CardBook book) {
  int words = 0;
  for (final Pill p in book.cards) {
    words += '${p.question} ${p.answer} ${p.barMove}'.split(' ').length;
  }
  return math.max(3, (words / 120 + book.cards.length * 0.5).round());
}
