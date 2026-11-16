/// Books in pills: a book's big ideas, a card each, read in a few minutes.
///
/// A book is the cards of the bank that name it (`book` on the card, see
/// [PillBook]): four to eight ideas in the book's own order, each a card in
/// the app's words, with the book named on its source. The row shows each
/// book's own cover (the edition its ISBN names, published beside the
/// cards; one drawn in the subject's colour while it comes or where it will
/// not), its title and author, and how many of its ideas the reader has
/// read. A book's page says why it is worth the minutes: the prize, the
/// copies sold, the bestseller list.
///
/// The way in is a path's: on the free plan a book's first [kBookFree]
/// ideas, then the card that offers the rest. One book a week is whole for
/// everybody, the same for every reader: the book of the week, first in the
/// row, marked as such. A book read whole is a reason to come back for the
/// next one; a book stopped at two of five, a reason to see the plans.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../analytics.dart';
import '../../../data/pill_bank.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../screens/deck_viewer_screen.dart';
import '../../../state/app_state.dart';
import '../../../theme.dart';
import '../../../widgets/premium.dart';
import '../../../widgets/web/card_thumb.dart';
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
        height: _BookTile.height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: books.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) => _BookTile(
            book: books[i],
            read: books[i].cards
                .where((p) => app.seenIds.contains(p.id))
                .length,
            weekly: books[i].id == weekly,
            locked: !app.isPlus && books[i].id != weekly,
            onTap: () => openBookPage(context, app, books[i], weekly: weekly),
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

/// Where a book's cover is published: beside the cards, by the book's id
/// (web/cards/covers/<id>.jpg, the edition its `isbn` names).
Uri bookCoverUrl(PillBook book) => CardThumb.urlOf('covers/${book.id}.jpg');

/// About how long a book takes: its words at an unhurried reading pace, and
/// half a minute an idea to think and answer; never under three minutes.
int bookMinutes(CardBook book) {
  int words = 0;
  for (final Pill p in book.cards) {
    words += '${p.question} ${p.answer} ${p.barMove}'.split(' ').length;
  }
  return math.max(3, (words / 120 + book.cards.length * 0.5).round());
}

/// A book's cover: the edition's own, fetched like a card's picture, and
/// while it comes or where it will not, one drawn in the subject's colour
/// with the title and the author in the app's type.
class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.book, required this.width});

  final CardBook book;
  final double width;

  @override
  Widget build(BuildContext context) {
    final double height = width * 1.5;
    final Pill first = book.first;
    final Widget drawn = _DrawnCover(book: book, width: width);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.06),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: width * 0.12,
            offset: Offset(0, width * 0.04),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image(
        image: CardThumb.image(bookCoverUrl(book.book)),
        fit: BoxFit.cover,
        width: width,
        height: height,
        semanticLabel: '${book.book.title}, ${book.book.author}',
        frameBuilder: (context, child, frame, synchronous) => Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: first.color),
            if (frame == null && !synchronous) drawn,
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 220),
              child: child,
            ),
          ],
        ),
        errorBuilder: (context, error, stack) => drawn,
      ),
    );
  }
}

class _DrawnCover extends StatelessWidget {
  const _DrawnCover({required this.book, required this.width});

  final CardBook book;
  final double width;

  @override
  Widget build(BuildContext context) {
    final Pill first = book.first;
    final Color ink = first.ink;
    final double k = width / 120;
    return Container(
      color: first.color,
      padding: EdgeInsets.fromLTRB(12 * k, 14 * k, 12 * k, 12 * k),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              book.book.title,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: AppText.display(
                size: 17 * k,
                weight: FontWeight.w600,
                height: 1.08,
                color: ink,
              ),
            ),
          ),
          Text(
            book.book.author,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              size: 10.5 * k,
              weight: FontWeight.w600,
              color: ink.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

/// A book in the row: its cover, the book of the week marked, its title and
/// author under it, and how far the reader has read. The week's book says
/// so under its cover, never over the publisher's title.
class _BookTile extends StatelessWidget {
  const _BookTile({
    required this.book,
    required this.read,
    required this.weekly,
    required this.locked,
    required this.onTap,
  });

  static const double width = 124;
  static const double height = 186 + 10 + 26 + 36 + 18 + 12;

  final CardBook book;
  final int read;
  final bool weekly;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return Semantics(
      button: true,
      label: '${book.book.title}, ${book.book.author}',
      child: GestureDetector(
        key: ValueKey('book-${book.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  BookCover(book: book, width: width),
                  if (locked)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (weekly)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    l.bookFreeThisWeek.toUpperCase(),
                    key: const ValueKey('book-weekly'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 10,
                      weight: FontWeight.w800,
                      height: 1.25,
                      spacing: 0.7,
                      color: p.ink.withValues(alpha: 0.62),
                    ),
                  ),
                ),
              Text(
                book.book.title,
                maxLines: weekly ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 13.5,
                  weight: FontWeight.w700,
                  height: 1.25,
                  color: p.ink,
                ),
              ),
              Text(
                book.book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(size: 12, color: p.inkMuted),
              ),
              const SizedBox(height: 7),
              _Progress(of: book.cards.length, read: read),
            ],
          ),
        ),
      ),
    );
  }
}

/// A dash for each idea, filled for the ones read.
class _Progress extends StatelessWidget {
  const _Progress({required this.of, required this.read});

  final int of;
  final int read;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (int i = 0; i < of; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: i < read ? 0.85 : 0.16),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.ground, required this.ink});

  final String text;
  final Color ground;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: ground,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: AppText.body(size: 10.5, weight: FontWeight.w800, color: ink),
    ),
  );
}

/// A book's own page, as a reader opens it from the row: the cover, the
/// title and the author, why it is worth the minutes, how long it takes,
/// its ideas in order (read, still to read, or for Astute+), and the way in.
class BookScreen extends StatelessWidget {
  const BookScreen({
    super.key,
    required this.app,
    required this.book,
    this.weekly,
  });

  final AppState app;
  final CardBook book;

  /// The book of the week's id: whole for everybody.
  final String? weekly;

  /// Opens the book at idea [i]. An idea past the free ones goes through
  /// the plans first and then straight to it, not back to the first two.
  void _openAt(BuildContext context, int i) {
    final bool whole = app.isPlus || book.id == weekly;
    if (whole || i < kBookFree) {
      openBook(context, app, book, weekly: weekly, from: i);
      return;
    }
    requirePlus(
      context,
      app,
      () => openBook(context, app, book, weekly: weekly, from: i),
      source: 'book idea',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final bool whole = app.isPlus || book.id == weekly;
        final List<bool> read = [
          for (final Pill c in book.cards) app.seenIds.contains(c.id),
        ];
        final int next = read.indexOf(false);
        final String go = next == -1
            ? l.bookAgain
            : next == 0
            ? l.bookStart
            : l.bookContinue;
        return Scaffold(
          backgroundColor: p.surface,
          appBar: AppBar(
            backgroundColor: p.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            foregroundColor: p.ink,
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              24,
              4,
              24,
              MediaQuery.paddingOf(context).bottom + 28,
            ),
            children: [
              Center(child: BookCover(book: book, width: 168)),
              const SizedBox(height: 22),
              Text(
                book.book.title,
                textAlign: TextAlign.center,
                style: AppText.display(
                  size: 26,
                  weight: FontWeight.w600,
                  height: 1.1,
                  spacing: -0.6,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${book.book.author} · ${book.book.year}',
                textAlign: TextAlign.center,
                style: AppText.body(size: 15, color: p.inkMuted),
              ),
              if (book.book.badge.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 17,
                      color: p.ink.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        book.book.badge,
                        textAlign: TextAlign.center,
                        style: AppText.body(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: p.ink.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    '${l.bookIdeas(book.cards.length)} · '
                    '${l.bookMinutes(bookMinutes(book))}',
                    style: AppText.body(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: p.inkMuted,
                    ),
                  ),
                  if (book.id == weekly)
                    _Chip(
                      text: l.bookFreeThisWeek,
                      ground: p.inverse,
                      ink: p.onInverse,
                    ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 54,
                child: FilledButton(
                  key: const ValueKey('book-go'),
                  style: FilledButton.styleFrom(
                    backgroundColor: p.inverse,
                    foregroundColor: p.onInverse,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => _openAt(context, next == -1 ? 0 : next),
                  child: Text(
                    go,
                    style: AppText.body(size: 16, weight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                l.bookTheIdeas.toUpperCase(),
                style: AppText.body(
                  size: 11,
                  weight: FontWeight.w800,
                  spacing: 1.3,
                  color: p.ink.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < book.cards.length; i++)
                _IdeaRow(
                  key: ValueKey('book-idea-$i'),
                  n: i + 1,
                  question: book.cards[i].question,
                  read: read[i],
                  locked: !whole && i >= kBookFree,
                  onTap: () => _openAt(context, i),
                ),
              const SizedBox(height: 18),
              Text(
                l.bookRetold(book.book.title, book.book.author),
                style: AppText.body(size: 12.5, height: 1.4, color: p.inkFaint),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One of a book's ideas on its page: its number, its question, and
/// whether it is read, still to read, or for Astute+.
class _IdeaRow extends StatelessWidget {
  const _IdeaRow({
    super.key,
    required this.n,
    required this.question,
    required this.read,
    required this.locked,
    required this.onTap,
  });

  final int n;
  final String question;
  final bool read;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '$n',
                style: AppText.display(
                  size: 18,
                  weight: FontWeight.w600,
                  color: p.ink.withValues(alpha: 0.45),
                ),
              ),
            ),
            Expanded(
              child: Text(
                question,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 15,
                  weight: FontWeight.w600,
                  height: 1.35,
                  color: locked ? p.inkMuted : p.ink,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              locked
                  ? Icons.lock_rounded
                  : read
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 19,
              color: read && !locked
                  ? const Color(0xFF22C55E)
                  : p.ink.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens a book's page.
Future<void> openBookPage(
  BuildContext context,
  AppState app,
  CardBook book, {
  String? weekly,
}) {
  Analytics.capture('book opened', {
    'book': book.id,
    'weekly': book.id == weekly,
    'is_plus': app.isPlus,
    'read': book.cards.where((p) => app.seenIds.contains(p.id)).length,
  });
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BookScreen(app: app, book: book, weekly: weekly),
    ),
  );
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
