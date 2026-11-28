/// Books in pills: a book's big ideas, a card each, read in a few minutes.
///
/// A book is the cards of the bank that name it (`book` on the card, see
/// [PillBook]): four to eight ideas in the book's own order, each a card in
/// the app's words, with the book named on its source. The section sets the
/// book of the week apart at its head, its cover large on a ground of its
/// subject's colour, with why it is worth the minutes and how long they
/// are; the other books follow in a row, each with its own cover (the
/// edition its ISBN names, published beside the cards; one drawn in the
/// subject's colour while it comes or where it will not), its title and
/// author, and how many of its ideas the reader has read. A book's page says
/// why it is worth the minutes: the prize, the copies sold, the bestseller
/// list; and who recommended it, of the people on What founders read
/// (founders_block.dart).
///
/// The way in is a path's: on the free plan a book's first [kBookFree]
/// ideas, then the card that offers the rest. One book a week is whole for
/// everybody, the same for every reader: the book of the week, set apart at
/// the head of the section. A book read whole is a reason to come back for
/// the next one; a book stopped at two of five, a reason to see the plans.
///
/// A book with a summary has a longer way in too: "Read in 15 minutes" on
/// its page, the book read whole in five to eight parts, and, behind the
/// switch `bookAudio`, the same summary read aloud (lib/books/). Its cards
/// stay as they are, under the summary.
library;

export '../../../data/books.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../analytics.dart';
import '../../../books/book_player_view.dart' show bookPlayerRoom;
import '../../../books/book_player.dart';
import '../../../books/summary_entry.dart';
import '../../../data/founders.dart';
import '../../../data/books.dart';
import '../../../data/pill_bank.dart';
import '../../../l10n/l10n.dart';
import '../../../legal.dart' show openLink;
import '../../../models/book_summary.dart';
import '../../../models/pill.dart';
import '../../../screens/deck_viewer_screen.dart';
import '../../../state/app_state.dart';
import '../../../theme.dart';
import '../../../widgets/premium.dart';
import '../../../widgets/top_edge.dart' show SoftTop;
import '../../../widgets/ui.dart' show BackCircle;
import '../../../widgets/web/card_thumb.dart';
import '../../explore_block.dart';
import 'founders_block.dart' show FounderFace, FounderPhotoCredit, FounderWords;
import 'layout.dart';

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
    // The week's book at the head when it is among them (on a subject's
    // page it may not be), the others in a row under it.
    final CardBook? week = books.where((b) => b.id == weekly).firstOrNull;
    final List<CardBook> rest = [
      for (final CardBook b in books)
        if (b.id != weekly) b,
    ];
    int readOf(CardBook b) =>
        b.cards.where((p) => app.seenIds.contains(p.id)).length;
    const double width = _BookTile.rowWidth;
    return SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      // Every book at once, on a page of its own: the library.
      trailing: books.length > 3
          ? TextButton(
              key: const ValueKey('books-see-all'),
              onPressed: () => openLibrary(context, app, weekly: weekly),
              style: TextButton.styleFrom(
                foregroundColor: context.p.ink,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                context.l10n.booksSeeAll,
                style: AppText.body(size: 13.5, weight: FontWeight.w700),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (week != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: WeekBook(
                book: week,
                read: readOf(week),
                free: !app.isPlus,
                onTap: () => openBookPage(context, app, week, weekly: weekly),
              ),
            ),
          if (week != null && rest.isNotEmpty) const SizedBox(height: 16),
          if (rest.isNotEmpty)
            SizedBox(
              height: _BookTile.heightOf(context, rest, width),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: rest.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _BookTile(
                  book: rest[i],
                  width: width,
                  read: readOf(rest[i]),
                  weekly: false,
                  locked: !app.isPlus,
                  onTap: () =>
                      openBookPage(context, app, rest[i], weekly: weekly),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The book of the week at the head of the books: its cover large, on a
/// ground of its subject's colour; what it is, why it is worth the minutes,
/// how many they are, and how far the reader is. Whole for everybody this
/// week, which a reader on the free plan is told.
class WeekBook extends StatelessWidget {
  const WeekBook({
    super.key,
    required this.book,
    required this.read,
    required this.free,
    required this.onTap,
  });

  final CardBook book;
  final int read;

  /// Whether to say it is free this week: on the free plan.
  final bool free;
  final VoidCallback onTap;

  static const double cover = 112;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final Color hue = book.first.color;
    final Color ground = Color.alphaBlend(
      hue.withValues(alpha: p.isDark ? 0.17 : 0.22),
      p.surfaceRaised,
    );
    // The eyebrow in the subject's colour at night, where every hue reads
    // on the dark tint; on paper, in ink.
    final Color eyebrow = p.isDark ? hue : p.ink.withValues(alpha: 0.62);
    final String meta =
        '${l.bookIdeas(book.cards.length)} · '
        '${l.bookMinutes(bookMinutes(book))}';
    return Semantics(
      button: true,
      label: [
        l.bookOfTheWeek,
        book.book.title,
        book.book.author,
        if (free) l.bookFreeThisWeek,
        meta,
      ].join(', '),
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('book-week-${book.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: ground,
            borderRadius: BorderRadius.circular(24),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      BookCover(book: book, width: cover),
                      if (read >= book.cards.length)
                        const Positioned(
                          right: 6,
                          top: 6,
                          child: BookStateBadge(done: true),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: cover * 1.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.bookOfTheWeek.toUpperCase(),
                          style: AppText.label(
                            size: 10.5,
                            weight: FontWeight.w800,
                            spacing: 1.2,
                            height: 1.25,
                            color: eyebrow,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.book.title,
                          style: AppText.display(
                            size: 22,
                            weight: FontWeight.w600,
                            height: 1.08,
                            spacing: -0.5,
                            color: p.ink,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          book.book.author,
                          style: AppText.body(
                            size: 13.5,
                            height: 1.25,
                            color: p.inkMuted,
                          ),
                        ),
                        const Spacer(),
                        if (book.book.badge.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            book.book.badge,
                            style: AppText.body(
                              size: 12.5,
                              height: 1.3,
                              color: p.ink.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (free)
                              _Chip(
                                text: l.bookFreeThisWeek,
                                ground: p.inverse,
                                ink: p.onInverse,
                              ),
                            Text(
                              meta,
                              style: AppText.body(
                                size: 12.5,
                                weight: FontWeight.w700,
                                color: p.ink.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        BookProgress(of: book.cards.length, read: read),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The height [text] takes set in [style] (over the page's own) at most
/// [width] wide, at the reader's text size: what a tile must hold to show
/// it whole, never cut short.
double wordsHeight(
  BuildContext context,
  String text,
  TextStyle style,
  double width,
) {
  final TextPainter painter = TextPainter(
    text: TextSpan(
      text: text,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
  )..layout(maxWidth: width);
  final double height = painter.height;
  painter.dispose();
  return height;
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
        end: whole
            ? BookDone(app: app, book: book, weekly: weekly)
            : BookMore(app: app, book: book),
      ),
    ),
  );
}

/// Where a book's cover is published: beside the cards, by the book's id
/// (`web/cards/covers/<id>.jpg`, the edition its `isbn` names).
Uri bookCoverUrl(PillBook book) => CardThumb.urlOf('covers/${book.id}.jpg');

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
            // A word is never broken across two lines ("Destructio / n"):
            // the title comes down a size, its optical size with it, until
            // its widest word fits the cover's width.
            child: LayoutBuilder(
              builder: (context, box) {
                TextStyle style(double size) => AppText.display(
                  size: size,
                  weight: FontWeight.w600,
                  height: 1.08,
                  color: ink,
                );
                final TextScaler scaler = MediaQuery.textScalerOf(context);
                double widest(double size) {
                  double most = 0;
                  for (final String word in book.book.title.split(
                    RegExp(r'\s+'),
                  )) {
                    // Measured in the style the title is drawn in: the
                    // page's own, under the cover's.
                    final TextPainter painter = TextPainter(
                      text: TextSpan(
                        text: word,
                        style: DefaultTextStyle.of(context).style
                            .merge(style(size)),
                      ),
                      textDirection: Directionality.of(context),
                      textScaler: scaler,
                      maxLines: 1,
                    )..layout();
                    most = math.max(most, painter.width);
                    painter.dispose();
                  }
                  return most;
                }

                // How tall the whole title stands at [size].
                double tall(double size) {
                  final TextPainter painter = TextPainter(
                    text: TextSpan(
                      text: book.book.title,
                      style: DefaultTextStyle.of(context).style
                          .merge(style(size)),
                    ),
                    textDirection: Directionality.of(context),
                    textScaler: scaler,
                  )..layout(maxWidth: box.maxWidth);
                  final double height = painter.height;
                  painter.dispose();
                  return height;
                }

                double size = 17 * k;
                // Down a step at a time, measured again at each, since the
                // face's optical size changes its widths with its size.
                while (size > 11 * k &&
                    box.maxWidth.isFinite &&
                    widest(size) > box.maxWidth * 0.98) {
                  size -= 0.5 * k;
                }
                // And on down, to a floor, until the whole title stands on
                // the cover: a title is never cut short.
                while (size > 7 * k &&
                    box.maxWidth.isFinite &&
                    box.maxHeight.isFinite &&
                    tall(size) > box.maxHeight) {
                  size -= 0.5 * k;
                }
                return Text(
                  book.book.title,
                  overflow: TextOverflow.clip,
                  style: style(size),
                );
              },
            ),
          ),
          Text(
            book.book.author,
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

/// A book read whole (a tick), or one for Astute+ (a lock), on its cover's
/// corner; [small] on a cover a row of a page holds.
class BookStateBadge extends StatelessWidget {
  const BookStateBadge({super.key, required this.done, this.small = false});

  final bool done;
  final bool small;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(done ? (small ? 2 : 3) : (small ? 4 : 5)),
    decoration: BoxDecoration(
      color: done
          ? const Color(0xFF22C55E)
          : Colors.black.withValues(alpha: 0.55),
      shape: BoxShape.circle,
    ),
    child: Icon(
      done ? Icons.check_rounded : Icons.lock_rounded,
      size: done ? (small ? 12 : 14) : (small ? 10 : 12),
      color: Colors.white,
    ),
  );
}

/// A book in the row: its cover, its title and author under it, and how far
/// the reader has read. In the library the week's book says so under its
/// cover, never over the publisher's title.
class _BookTile extends StatelessWidget {
  const _BookTile({
    required this.book,
    required this.read,
    required this.weekly,
    required this.locked,
    required this.onTap,
    this.width = rowWidth,
    this.line = false,
  });

  /// The tile's width in the row.
  static const double rowWidth = 116;

  static TextStyle _lineStyle(Palette p) => AppText.body(
    size: 10,
    weight: FontWeight.w800,
    height: 1.25,
    spacing: 0.7,
    color: p.ink.withValues(alpha: 0.62),
  );

  static TextStyle _titleStyle(Palette p) => AppText.body(
    size: 13.5,
    weight: FontWeight.w700,
    height: 1.25,
    color: p.ink,
  );

  static TextStyle _authorStyle(Palette p) =>
      AppText.body(size: 12, height: 1.3, color: p.inkMuted);

  /// How tall the tallest of [books] stands as a tile [width] wide, at the
  /// reader's text size: its cover, its title and its author whole, however
  /// many lines they take, and the dashes; the week's line over the title
  /// of [marked].
  static double heightOf(
    BuildContext context,
    Iterable<CardBook> books,
    double width, {
    String? marked,
  }) {
    final Palette p = context.p;
    final String week = context.l10n.bookFreeThisWeek.toUpperCase();
    double most = width * 1.5;
    for (final CardBook b in books) {
      most = math.max(
        most,
        width * 1.5 +
            10 +
            (b.id == marked
                ? wordsHeight(context, week, _lineStyle(p), width) + 2
                : 0) +
            wordsHeight(context, b.book.title, _titleStyle(p), width) +
            wordsHeight(context, b.book.author, _authorStyle(p), width) +
            7 +
            3,
      );
    }
    return (most + 2).ceilToDouble();
  }

  final CardBook book;
  final int read;
  final bool weekly;
  final bool locked;
  final VoidCallback onTap;
  final double width;

  /// Whether the tile may carry the week's line (the library's do).
  final bool line;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final bool marked = line && weekly;
    return Semantics(
      button: true,
      label: [
        book.book.title,
        book.book.author,
        if (marked) l.bookFreeThisWeek,
      ].join(', '),
      child: GestureDetector(
        key: ValueKey('book-${book.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  BookCover(book: book, width: width),
                  // A book read whole says so, where a locked one shows
                  // its lock.
                  if (read >= book.cards.length)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: BookStateBadge(
                        key: ValueKey('book-read-${book.id}'),
                        done: true,
                      ),
                    )
                  else if (locked)
                    const Positioned(
                      right: 6,
                      top: 6,
                      child: BookStateBadge(done: false),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (marked)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    l.bookFreeThisWeek.toUpperCase(),
                    key: const ValueKey('book-weekly'),
                    style: _lineStyle(p),
                  ),
                ),
              Text(book.book.title, style: _titleStyle(p)),
              Text(book.book.author, style: _authorStyle(p)),
              const SizedBox(height: 7),
              BookProgress(of: book.cards.length, read: read),
            ],
          ),
        ),
      ),
    );
  }
}

/// A dash for each idea, filled for the ones read.
class BookProgress extends StatelessWidget {
  const BookProgress({super.key, required this.of, required this.read});

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
    // A book with a summary opens on it; its cards follow, as they were.
    final SummaryRef? summary = PillBank.summaryOf(book.id);
    return ListenableBuilder(
      listenable: Listenable.merge([app, BookPlayer.current]),
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
            // The app's own back button, Apple's glass one on iOS 26, as
            // on every other screen, not the system's bare arrow.
            leadingWidth: 64,
            leading: Center(
              child: BackCircle(onPressed: () => Navigator.of(context).pop()),
            ),
          ),
          body: SoftTop(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                24,
                4,
                24,
                MediaQuery.paddingOf(context).bottom +
                    28 +
                    bookPlayerRoom(context),
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
                    // With a summary, each way in says its own minutes.
                    if (summary == null)
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
                if (summary != null)
                  SummaryBlock(
                    key: const ValueKey('book-summary'),
                    app: app,
                    book: book,
                    summaryRef: summary,
                    weekly: weekly,
                  )
                else
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
                if (picksOf(book.id) case final List<(Founder, BookPick)> picks
                    when picks.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text(
                    l.bookRecommendedBy.toUpperCase(),
                    style: AppText.body(
                      size: 11,
                      weight: FontWeight.w800,
                      spacing: 1.3,
                      color: p.ink.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final (Founder who, BookPick pick) in picks)
                    _PickRow(
                      key: ValueKey('book-pick-${who.id}'),
                      founder: who,
                      pick: pick,
                    ),
                ],
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
                // Under a summary, the cards are the short way in: their
                // minutes, and the button that plays them.
                if (summary != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${l.bookIdeas(book.cards.length)} · '
                    '${l.bookMinutes(bookMinutes(book))}',
                    style: AppText.body(
                      size: 13,
                      weight: FontWeight.w600,
                      color: p.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      key: const ValueKey('book-go'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.ink,
                        side: BorderSide(color: p.lineStrong, width: 1.2),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => _openAt(context, next == -1 ? 0 : next),
                      child: Text(
                        go,
                        style: AppText.body(
                          size: 15.5,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
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
                  style: AppText.body(
                    size: 12.5,
                    height: 1.4,
                    color: p.inkFaint,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One person's recommendation on a book's page: their face (the initials of
/// their name while there is no photo), who, what they built, their words,
/// and where they said them, a tap away; and who took the photo.
class _PickRow extends StatelessWidget {
  const _PickRow({super.key, required this.founder, required this.pick});

  final Founder founder;
  final BookPick pick;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: p.ink.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Analytics.capture('book pick source', {
              'who': founder.name,
              'book': pick.book,
              'from': 'book',
            });
            openLink(pick.url);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 16, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FounderFace(founder: founder, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        founder.name,
                        style: AppText.body(
                          size: 15.5,
                          weight: FontWeight.w700,
                          color: p.ink,
                        ),
                      ),
                      Text(
                        context.l10n.roleOf(founder),
                        style: AppText.body(size: 13, color: p.inkMuted),
                      ),
                      if (pick.said.isNotEmpty) ...[
                        const SizedBox(height: 9),
                        Text(
                          '“${pick.said}”',
                          style: AppText.display(
                            size: 16,
                            weight: FontWeight.w500,
                            height: 1.32,
                            color: p.ink.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                      const SizedBox(height: 9),
                      // The arrow held to the last word by a space that
                      // does not break, never on a line of its own.
                      Text(
                        '${context.l10n.sourceOf(pick)}\u00A0↗',
                        style: AppText.body(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: p.inkMuted,
                        ),
                      ),
                      // Who took the photo, as its licence asks.
                      if (founder.photo != null) ...[
                        const SizedBox(height: 3),
                        FounderPhotoCredit(founder: founder),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
  String from = 'books',
}) {
  Analytics.capture('book opened', {
    'book': book.id,
    'from': from,
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

/// Whether the reader has read every idea of [book].
bool bookRead(AppState app, CardBook book) =>
    book.cards.every((p) => app.seenIds.contains(p.id));

/// The card after the last idea of a book read whole: the book finished,
/// how many ideas in how long, how many books the reader has finished, and
/// the next book to open.
class BookDone extends StatefulWidget {
  const BookDone({
    super.key,
    required this.app,
    required this.book,
    this.weekly,
  });

  final AppState app;
  final CardBook book;
  final String? weekly;

  @override
  State<BookDone> createState() => _BookDoneState();
}

class _BookDoneState extends State<BookDone> {
  late final List<CardBook> _all = booksOf(
    PillBank.live,
    today: widget.app.today,
  );

  /// The books finished, this one counted: its last idea may still be on
  /// its way to being marked read.
  int get _finished => _all
      .where((b) => b.id == widget.book.id || bookRead(widget.app, b))
      .length;

  CardBook? get _next => _all
      .where((b) => b.id != widget.book.id && !bookRead(widget.app, b))
      .firstOrNull;

  @override
  void initState() {
    super.initState();
    Analytics.capture('book finished', {
      'book': widget.book.id,
      'finished': _finished,
      'is_plus': widget.app.isPlus,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final CardBook book = widget.book;
    final Pill first = book.first;
    final Color ink = first.ink;
    final CardBook? next = _next;
    return Container(
      key: const ValueKey('book-done'),
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
                  style: AppText.label(
                    size: 11,
                    weight: FontWeight.w700,
                    spacing: 1.1,
                    color: ink.withValues(alpha: 0.72),
                  ),
                ),
              ),
              Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: ink.withValues(alpha: 0.8),
              ),
            ],
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.bookDoneTitle,
                  style: AppText.display(
                    size: 36,
                    weight: FontWeight.w600,
                    height: 1.05,
                    spacing: -0.8,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l.bookDoneLine(book.cards.length, bookMinutes(book)),
                  style: AppText.body(
                    size: 16,
                    height: 1.4,
                    color: ink.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.bookDoneCount(_finished),
                  key: const ValueKey('book-done-count'),
                  style: AppText.body(
                    size: 14,
                    weight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
          if (next != null) ...[
            Text(
              l.bookDoneNext.toUpperCase(),
              style: AppText.label(
                size: 11,
                weight: FontWeight.w700,
                spacing: 1.1,
                color: ink.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${next.book.title} · ${next.book.author}',
              style: AppText.display(
                size: 20,
                weight: FontWeight.w600,
                height: 1.15,
                color: ink,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                key: const ValueKey('book-done-next'),
                style: FilledButton.styleFrom(
                  backgroundColor: ink,
                  foregroundColor: first.color,
                  shape: const StadiumBorder(),
                ),
                onPressed: () {
                  final NavigatorState nav = Navigator.of(context);
                  nav.pop();
                  openBookPage(
                    nav.context,
                    widget.app,
                    next,
                    weekly: widget.weekly,
                  );
                },
                child: Text(
                  l.bookDoneGo,
                  style: AppText.body(size: 16, weight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Opens the library: every book, covers in a grid.
Future<void> openLibrary(BuildContext context, AppState app, {String? weekly}) {
  Analytics.capture('books library opened', {'is_plus': app.isPlus});
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => LibraryScreen(app: app, weekly: weekly),
    ),
  );
}

/// Every book in pills at once: the week's first, then the rest in their
/// weekly turn, each with its cover, how far the reader has read, a tick
/// when read whole and a lock where Astute+ opens it.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.app, this.weekly});

  final AppState app;
  final String? weekly;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: p.ink,
        // The app's own back button, Apple's glass one on iOS 26.
        leadingWidth: 64,
        leading: Center(
          child: BackCircle(onPressed: () => Navigator.of(context).pop()),
        ),
        title: Text(
          context.l10n.booksLibraryTitle,
          style: AppText.body(size: 17, weight: FontWeight.w700, color: p.ink),
        ),
      ),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final List<CardBook> books = booksOf(PillBank.live, today: app.today);
          return LayoutBuilder(
            builder: (context, box) {
              const double side = 20, gap = 12;
              final int across = box.maxWidth >= 600 ? 4 : 3;
              final double width =
                  (box.maxWidth - side * 2 - gap * (across - 1)) / across;
              final int rows = (books.length + across - 1) ~/ across;
              return SoftTop(
                child: ListView.builder(
                  key: const ValueKey('books-library'),
                  padding: EdgeInsets.fromLTRB(
                    side,
                    8,
                    side,
                    MediaQuery.paddingOf(context).bottom + 24,
                  ),
                  itemCount: rows,
                  itemBuilder: (context, r) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int c = 0; c < across; c++) ...[
                          if (c > 0) const SizedBox(width: gap),
                          if (r * across + c < books.length)
                            _BookTile(
                              book: books[r * across + c],
                              width: width,
                              line: true,
                              read: books[r * across + c].cards
                                  .where((p) => app.seenIds.contains(p.id))
                                  .length,
                              weekly: books[r * across + c].id == weekly,
                              locked:
                                  !app.isPlus &&
                                  books[r * across + c].id != weekly,
                              onTap: () => openBookPage(
                                context,
                                app,
                                books[r * across + c],
                                weekly: weekly,
                              ),
                            )
                          else
                            SizedBox(width: width),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
