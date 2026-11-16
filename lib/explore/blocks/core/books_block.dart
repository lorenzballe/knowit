/// Books in pills: a book's big ideas, a card each, read in a few minutes.
///
/// A book is the cards of the bank that name it (`book` on the card, see
/// [PillBook]): four to eight ideas in the book's own order, each a card in
/// the app's words, with the book named on its source. The row shows each as
/// a cover drawn in its subject's colour, the title and the author set in
/// the app's type (no publisher's cover: those are not ours to show), and
/// how many of its ideas the reader has read.
///
/// The way in is a path's: on the free plan a book's first [kBookFree]
/// ideas, then the card that offers the rest. One book a week is whole for
/// everybody, the same for every reader: the book of the week, first in the
/// row, marked as such. A book read whole is a reason to come back for the
/// next one; a book stopped at two of five, a reason to see the plans.
library;

import 'package:flutter/material.dart';

import '../../../data/pill_bank.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../screens/deck_viewer_screen.dart';
import '../../../state/app_state.dart';
import '../../../theme.dart';
import '../../../widgets/premium.dart';
import '../../explore_block.dart';
import 'layout.dart';

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

/// The block: see the library's own words.
class BooksBlock extends ExploreBlock with SectionLayout {
  const BooksBlock();

  @override
  String get name => 'books';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final AppState app = host.app;
    final List<CardBook> books = booksOf(
      PillBank.live,
      today: app.today,
      subject: host.subject,
    );
    if (books.isEmpty) return null;
    final String? weekly = bookOfTheWeek(PillBank.live, app.today);
    return SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      child: SizedBox(
        height: _BookCover.height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: books.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) => _BookCover(
            book: books[i],
            read: books[i].cards
                .where((p) => app.seenIds.contains(p.id))
                .length,
            weekly: books[i].id == weekly,
            locked: !app.isPlus && books[i].id != weekly,
            onTap: () => openBook(context, app, books[i], weekly: weekly),
          ),
        ),
      ),
    );
  }
}

/// Opens [book] at full size, an idea at a time, counted as read as they
/// go: whole on Astute+ and for the book of the week, from [from]; on the
/// free plan its first [kBookFree], then the card that offers the rest.
Future<void> openBook(
  BuildContext context,
  AppState app,
  CardBook book, {
  String? weekly,
  int from = 0,
}) {
  final bool whole = app.isPlus || book.id == weekly;
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DeckViewerScreen(
        app: app,
        deck: whole ? book.cards : book.cards.take(kBookFree).toList(),
        title: book.book.title,
        initialIndex: whole ? from : 0,
        countsAsRead: true,
        answering: true,
        source: 'book',
        of: book.cards.length,
        end: whole ? null : BookMore(app: app, book: book),
      ),
    ),
  );
}

/// A book's cover, drawn: its subject's colour, the title large, the
/// author, and a dot for each idea, filled for the ones read.
class _BookCover extends StatelessWidget {
  const _BookCover({
    required this.book,
    required this.read,
    required this.weekly,
    required this.locked,
    required this.onTap,
  });

  static const double height = 218;
  static const double width = 146;

  final CardBook book;
  final int read;
  final bool weekly;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Pill first = book.first;
    final Color ink = first.ink;
    return Semantics(
      button: true,
      label: '${book.book.title}, ${book.book.author}',
      child: GestureDetector(
        key: ValueKey('book-${book.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: first.color,
            borderRadius: BorderRadius.circular(18),
            // The spine: a darker edge, as on a book.
            border: Border(
              left: BorderSide(color: ink.withValues(alpha: 0.22), width: 5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (weekly ? l.bookOfTheWeek : l.subjectOf(first.topic))
                          .toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label(
                        size: 9.5,
                        weight: FontWeight.w800,
                        spacing: 1.1,
                        color: ink.withValues(alpha: weekly ? 0.95 : 0.65),
                      ),
                    ),
                  ),
                  if (locked)
                    Icon(
                      Icons.lock_rounded,
                      size: 13,
                      color: ink.withValues(alpha: 0.55),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  book.book.title,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.display(
                    size: 20,
                    weight: FontWeight.w600,
                    height: 1.08,
                    spacing: -0.5,
                    color: ink,
                  ),
                ),
              ),
              Text(
                book.book.author,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w600,
                  height: 1.2,
                  color: ink.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 10),
              ExcludeSemantics(
                child: Row(
                  children: [
                    for (int i = 0; i < book.cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: ink.withValues(alpha: i < read ? 0.9 : 0.22),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Text(
                l.bookIdeas(book.cards.length),
                style: AppText.body(
                  size: 11,
                  weight: FontWeight.w700,
                  color: ink.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The card after a book's free ideas: how many are left, the next one's
/// question, and the way to them, through the plans and on where it was
/// left.
class BookMore extends StatelessWidget {
  const BookMore({super.key, required this.app, required this.book});

  final AppState app;
  final CardBook book;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Pill first = book.first;
    final Color ink = first.ink;
    final int left = book.cards.length - kBookFree;
    return Container(
      key: const ValueKey('book-more'),
      decoration: BoxDecoration(
        color: first.color,
        borderRadius: BorderRadius.circular(34),
      ),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${book.book.title} · ${book.book.author}'.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    size: 11,
                    weight: FontWeight.w700,
                    spacing: 1.1,
                    color: ink.withValues(alpha: 0.72),
                  ),
                ),
              ),
              Icon(
                Icons.lock_rounded,
                size: 18,
                color: ink.withValues(alpha: 0.7),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Text(
              book.cards[kBookFree].question,
              key: const ValueKey('book-more-next'),
              style: AppText.display(
                size: 28,
                weight: FontWeight.w600,
                height: 1.1,
                spacing: -0.6,
                color: ink,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l.bookMoreTitle(left),
            style: AppText.display(
              size: 22,
              weight: FontWeight.w600,
              height: 1.1,
              spacing: -0.5,
              color: ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.bookMoreLine,
            style: AppText.body(
              size: 14.5,
              height: 1.4,
              color: ink.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              key: const ValueKey('book-more-go'),
              style: FilledButton.styleFrom(
                backgroundColor: ink,
                foregroundColor: first.color,
                shape: const StadiumBorder(),
              ),
              onPressed: () => requirePlus(context, app, () {
                final NavigatorState nav = Navigator.of(context);
                nav.pop();
                openBook(nav.context, app, book, from: kBookFree);
              }, source: 'books'),
              child: Text(
                l.bookMoreGo,
                style: AppText.body(size: 16, weight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
