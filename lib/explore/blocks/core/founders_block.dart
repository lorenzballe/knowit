/// What founders read (lib/data/founders.dart): the people who built the
/// companies everyone knows, and the books in pills they recommended in
/// public, with their words and where they said them.
///
/// On Explore for every subject, a row of the people, each a tile with their
/// face, how many of the books they recommended are in pills, their name and
/// what they built, opening a page of their own: those books, every one of
/// them a book in pills to open, with their words about it and where they
/// said it, a tap away; and, at its foot, that these are books they
/// recommended in public and that they have no connection with Astute, and
/// who took the photo, under what licence.
///
/// On a subject's page, where a person would have a book or two, the books
/// of that subject they recommended instead, one list, not by person: each
/// book with the face, the name and the words of who recommended it, and
/// the others who did. A person, or a book, not in the bank is passed over,
/// and with nothing to show there is no section.
///
/// Nothing is ever cut short: a tile is as tall as the longest name and
/// role need at the reader's text size, measured.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../analytics.dart';
import '../../../data/founders.dart';
import '../../../data/pill_bank.dart';
import '../../../l10n/l10n.dart';
import '../../../legal.dart' show openLink;
import '../../../models/pill.dart';
import '../../../state/app_state.dart';
import '../../../theme.dart';
import '../../../widgets/top_edge.dart' show SoftTop;
import '../../../widgets/ui.dart' show BackCircle;
import '../../explore_block.dart';
import 'books_block.dart';
import 'layout.dart';

/// One person as the row and their page show them: who, and the books of
/// theirs that are in pills, each with their pick, in their page's order.
class FounderShelf {
  const FounderShelf(this.founder, this.books);

  final Founder founder;
  final List<(BookPick, CardBook)> books;

  /// How many of their books the reader has read whole.
  int readIn(Set<String> seen) =>
      books.where((b) => b.$2.cards.every((c) => seen.contains(c.id))).length;
}

/// The people of [kFounders] with a book in pills in [bank], in the row's
/// order, each with those books; a book not in the bank is passed over, and
/// so is a person with none.
List<FounderShelf> foundersOf(List<Pill> bank, {required DateTime today}) {
  final Map<String, CardBook> books = {
    for (final CardBook b in booksOf(bank, today: today)) b.id: b,
  };
  final List<FounderShelf> out = [];
  for (final Founder f in kFounders) {
    final List<(BookPick, CardBook)> theirs = [
      for (final BookPick k in f.picks)
        if (books[k.book] case final CardBook b) (k, b),
    ];
    if (theirs.isNotEmpty) out.add(FounderShelf(f, theirs));
  }
  return out;
}

/// A book of a subject as its page lists it: the book, and who recommended
/// it, the first whose words there are first.
class SubjectPick {
  const SubjectPick(this.book, this.picks);

  final CardBook book;
  final List<(Founder, BookPick)> picks;
}

/// The books of [subject] (a subject's name) that the people of [kFounders]
/// recommended, in the books' weekly turn, each with who recommended it:
/// those who said something of it first, in the row's order.
List<SubjectPick> subjectPicksOf(
  List<Pill> bank, {
  required DateTime today,
  required String subject,
}) => [
  for (final CardBook b in booksOf(bank, today: today, subject: subject))
    if (picksOf(b.id) case final List<(Founder, BookPick)> picks
        when picks.isNotEmpty)
      SubjectPick(b, [
        for (final k in picks)
          if (k.$2.said.isNotEmpty) k,
        for (final k in picks)
          if (k.$2.said.isEmpty) k,
      ]),
];

/// The block: see the library's own words.
class FoundersBlock extends ExploreBlock with SectionLayout {
  const FoundersBlock();

  /// Fewer people than this and the row is not drawn: one or two are not a
  /// row worth the room.
  static const int fewest = 3;

  @override
  String get name => 'founders';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final AppState app = host.app;
    final String? weekly = bookOfTheWeek(PillBank.live, app.today);
    final String title =
        section.title(host.language) ?? context.l10n.foundersTitle;
    final String? subject = host.subject;
    if (subject != null) {
      final List<SubjectPick> picks = subjectPicksOf(
        PillBank.live,
        today: app.today,
        subject: subject,
      );
      if (picks.isEmpty) return null;
      return SectionFrame(
        title: title,
        line: section.subtitle(host.language),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (final SubjectPick k in picks)
                FounderPickCard(
                  key: ValueKey('subject-pick-${k.book.id}'),
                  app: app,
                  book: k.book,
                  pick: k.picks.first.$2,
                  by: k.picks.first.$1,
                  also: [for (final (f, _) in k.picks.skip(1)) f],
                  weekly: weekly,
                  from: section.id,
                ),
            ],
          ),
        ),
      );
    }
    final List<FounderShelf> people = foundersOf(
      PillBank.live,
      today: app.today,
    );
    if (people.length < fewest) return null;
    final double height = FounderTile.heightOf(context, people);
    return SectionFrame(
      title: title,
      line: section.subtitle(host.language),
      child: SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: people.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, i) => FounderTile(
            key: ValueKey('founder-${people[i].founder.id}'),
            shelf: people[i],
            read: people[i].readIn(app.seenIds),
            height: height,
            onTap: () => openFounder(
              context,
              app,
              people[i],
              weekly: weekly,
              from: section.id,
            ),
          ),
        ),
      ),
    );
  }
}

/// The initials of a person's name in the app's serif: what stands in for
/// their face where there is no photo. A mark, not words to read: held to
/// its size whatever the text size.
class FounderMonogram extends StatelessWidget {
  const FounderMonogram({super.key, required this.founder, required this.size});

  final Founder founder;
  final double size;

  @override
  Widget build(BuildContext context) => MediaQuery.withNoTextScaling(
    child: Text(
      founder.monogram,
      maxLines: 1,
      style: AppText.display(
        size: size,
        weight: FontWeight.w500,
        height: 1,
        spacing: -size * 0.025,
        color: context.p.ink.withValues(alpha: 0.9),
      ),
    ),
  );
}

/// A person's face, round: their photo, kept in the app
/// ([Founder.photoAsset]), decoded no larger than it is shown; the
/// initials of their name in its place while there is none. Left out of
/// what a screen reader says, which names the person beside it.
class FounderFace extends StatelessWidget {
  const FounderFace({super.key, required this.founder, required this.size});

  final Founder founder;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final Widget initials = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.alphaBlend(p.ink.withValues(alpha: 0.1), p.surfaceRaised),
        shape: BoxShape.circle,
      ),
      child: FounderMonogram(founder: founder, size: size * 0.38),
    );
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: founder.photo == null
            ? initials
            : DecoratedBox(
                // A hairline round the photo, so a dark suit keeps its edge
                // on the night's black.
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: p.ink.withValues(alpha: 0.12),
                    width: 0.8,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    founder.photoAsset,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                        .ceil(),
                    errorBuilder: (_, _, _) => initials,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Who took a person's photo, under what licence, from where and what was
/// done to it, small, opening the photo's own page; nothing where there is
/// no photo.
class FounderPhotoCredit extends StatelessWidget {
  const FounderPhotoCredit({
    super.key,
    required this.founder,
    this.center = false,
  });

  final Founder founder;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final FounderPhoto? photo = founder.photo;
    if (photo == null) return const SizedBox.shrink();
    final Palette p = context.p;
    return Semantics(
      link: true,
      child: GestureDetector(
        key: ValueKey('founder-photo-${founder.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => openLink(photo.page),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(
            '${context.l10n.founderPhoto(photo.author, photo.licence)}'
            '\u00A0↗',
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: AppText.body(size: 11, height: 1.35, color: p.inkFaint),
          ),
        ),
      ),
    );
  }
}

/// One person in the row: their face, how many of the books they
/// recommended are in pills, their name, what they built, and a step for
/// each of those books, filled for the ones read whole, on the ground of a
/// raised card.
class FounderTile extends StatelessWidget {
  const FounderTile({
    super.key,
    required this.shelf,
    required this.read,
    required this.height,
    required this.onTap,
  });

  final FounderShelf shelf;
  final int read;
  final double height;
  final VoidCallback onTap;

  static const double width = 150, face = 58;

  static TextStyle _countStyle(Palette p) => AppText.label(
    size: 9.5,
    weight: FontWeight.w700,
    spacing: 1.1,
    height: 1.25,
    color: p.ink.withValues(alpha: 0.5),
  );

  static TextStyle _nameStyle(Palette p) => AppText.display(
    size: 19,
    weight: FontWeight.w600,
    height: 1.08,
    spacing: -0.4,
    color: p.ink,
  );

  static TextStyle _roleStyle(Palette p) =>
      AppText.body(size: 12, height: 1.3, color: p.inkMuted);

  /// How tall the tallest of [people]'s tiles stands at the reader's text
  /// size: the face and the count beside it, the name and what they built
  /// whole, however many lines they take, and the steps; never less than a
  /// path's tile.
  static double heightOf(BuildContext context, List<FounderShelf> people) {
    final l = context.l10n;
    final Palette p = context.p;
    const double inner = width - 28;
    double most = 196;
    for (final FounderShelf s in people) {
      final double count = wordsHeight(
        context,
        l.founderBookCount(s.books.length).toUpperCase(),
        _countStyle(p),
        inner - face - 8,
      );
      most = math.max(
        most,
        14 +
            math.max(face, count) +
            14 +
            wordsHeight(context, s.founder.name, _nameStyle(p), inner) +
            6 +
            wordsHeight(context, l.roleOf(s.founder), _roleStyle(p), inner) +
            10 +
            4 +
            14,
      );
    }
    return (most + 2).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final Founder f = shelf.founder;
    final int n = shelf.books.length;
    return Semantics(
      button: true,
      label: '${f.name}, ${l.roleOf(f)}, ${l.founderBookCount(n)}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: BorderRadius.circular(22),
            border: p.isDark ? null : Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FounderFace(founder: f, size: face),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.founderBookCount(n).toUpperCase(),
                      textAlign: TextAlign.end,
                      style: _countStyle(p),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(f.name, style: _nameStyle(p)),
              const SizedBox(height: 6),
              Text(l.roleOf(f), style: _roleStyle(p)),
              const SizedBox(height: 10),
              // A step for each of their books, the ones read whole filled.
              ExcludeSemantics(
                child: Row(
                  children: [
                    for (int i = 0; i < n; i++) ...[
                      if (i > 0) const SizedBox(width: 3),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: p.ink.withValues(
                              alpha: i < read ? 0.85 : 0.16,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A founder's words in the reader's language: what they built, and where
/// they said a pick. The data (lib/data/founders.dart) keeps them in
/// English, which is what a language without words for them says.
extension FounderWords on AppLocalizations {
  /// What [f] built, in a few words: "Cofondatore di Microsoft".
  String roleOf(Founder f) => founderRole(f.id.replaceAll('-', '_'), f.role);

  /// Where [k] was said: "l’assemblea annuale di Berkshire Hathaway".
  String whereOf(BookPick k) {
    final String? key = k.whereKey;
    return key == null ? k.where : founderWhere(key, k.where);
  }

  /// Where and when, as a line of its own prints it, its first letter set
  /// up: "GatesNotes, 2016", "L’assemblea annuale di Berkshire Hathaway,
  /// 2008".
  String sourceOf(BookPick k) {
    final String place = whereOf(k);
    if (place.isEmpty) return '${k.year}';
    return '${place[0].toUpperCase()}${place.substring(1)}, ${k.year}';
  }
}

/// Opens [shelf]'s page, from [from] (the section's id).
Future<void> openFounder(
  BuildContext context,
  AppState app,
  FounderShelf shelf, {
  String? weekly,
  String from = 'founders',
}) {
  Analytics.capture('founder opened', {
    'founder': shelf.founder.id,
    'from': from,
    'books': shelf.books.length,
    'read': shelf.readIn(app.seenIds),
    'is_plus': app.isPlus,
  });
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => FounderScreen(app: app, shelf: shelf, weekly: weekly),
    ),
  );
}

/// A person's own page: their face, name and what they built, how much
/// there is to read, then the books they recommended, each a book in pills
/// that opens, with their words about it and where they said them, which a
/// tap opens; at its foot, that these are books they recommended in public
/// and that they have no connection with Astute, and who took the photo.
class FounderScreen extends StatelessWidget {
  const FounderScreen({
    super.key,
    required this.app,
    required this.shelf,
    this.weekly,
  });

  final AppState app;
  final FounderShelf shelf;

  /// The book of the week's id: whole for everybody.
  final String? weekly;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final Founder f = shelf.founder;
    final int ideas = shelf.books.fold(0, (n, b) => n + b.$2.cards.length);
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
      ),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) => SoftTop(
          child: ListView(
            key: ValueKey('founder-page-${f.id}'),
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              MediaQuery.paddingOf(context).bottom + 28,
            ),
            children: [
              Center(child: FounderFace(founder: f, size: 112)),
              const SizedBox(height: 18),
              Semantics(
                header: true,
                child: Text(
                  f.name,
                  textAlign: TextAlign.center,
                  style: AppText.display(
                    size: 30,
                    weight: FontWeight.w600,
                    height: 1.1,
                    spacing: -0.7,
                    color: p.ink,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.roleOf(f),
                textAlign: TextAlign.center,
                style: AppText.body(size: 15, height: 1.35, color: p.inkMuted),
              ),
              const SizedBox(height: 12),
              // How much there is to read: the books, and their ideas.
              Text(
                '${l.founderBookCount(shelf.books.length)} · ${l.bookIdeas(ideas)}',
                key: const ValueKey('founder-count'),
                textAlign: TextAlign.center,
                style: AppText.body(
                  size: 13.5,
                  weight: FontWeight.w700,
                  color: p.ink.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  l.founderTheirBooks.toUpperCase(),
                  style: AppText.body(
                    size: 11,
                    weight: FontWeight.w800,
                    spacing: 1.3,
                    color: p.ink.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              for (final (BookPick pick, CardBook book) in shelf.books)
                FounderPickCard(
                  key: ValueKey('founder-book-${book.id}'),
                  app: app,
                  book: book,
                  pick: pick,
                  weekly: weekly,
                  who: f,
                  from: 'founder',
                ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recommended in public, not to Astute: nothing on the
                    // page reads as their word for the app.
                    Text(
                      l.founderAbout(f.name),
                      key: const ValueKey('founder-about'),
                      style: AppText.body(
                        size: 12.5,
                        height: 1.4,
                        color: p.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FounderPhotoCredit(founder: f),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A book someone recommended, as a person's page and a subject's page list
/// it: its cover, title and author, their words about it, where they said
/// them (a tap opens it), and how far the reader is in it; a tap anywhere
/// else opens the book's page. On a subject's page, [by] is who said it,
/// with their face and name beside where, and [also] the others who
/// recommended it.
class FounderPickCard extends StatelessWidget {
  const FounderPickCard({
    super.key,
    required this.app,
    required this.book,
    required this.pick,
    required this.weekly,
    required this.from,
    this.who,
    this.by,
    this.also = const [],
  });

  final AppState app;
  final CardBook book;
  final BookPick pick;
  final String? weekly;

  /// Where the card is: `founder` (a person's page) or the section's id.
  final String from;

  /// Whose page the card is on, when it is on one.
  final Founder? who;

  /// Who said it, named with their face, on a subject's page.
  final Founder? by;

  /// The others who recommended the book.
  final List<Founder> also;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final Founder? said = by ?? who;
    final int read = book.cards.where((c) => app.seenIds.contains(c.id)).length;
    final bool done = read >= book.cards.length;
    final bool locked = !app.isPlus && book.id != weekly;
    final Widget source = Semantics(
      link: true,
      child: InkWell(
        key: ValueKey('founder-source-${book.id}'),
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Analytics.capture('book pick source', {
            'who': ?said?.name,
            'book': book.id,
            'from': from,
          });
          openLink(pick.url);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          // The arrow held to the last word by a space that does not break.
          child: Text(
            by == null
                ? '${l.sourceOf(pick)}\u00A0↗'
                : '${by!.name} · ${l.whereOf(pick)}, ${pick.year}\u00A0↗',
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w600,
              height: 1.35,
              color: p.inkMuted,
            ),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: p.ink.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () =>
              openBookPage(context, app, book, weekly: weekly, from: from),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    BookCover(book: book, width: 66),
                    if (done || locked)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: BookStateBadge(done: done, small: true),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.book.title,
                        style: AppText.body(
                          size: 15.5,
                          weight: FontWeight.w700,
                          height: 1.25,
                          color: p.ink,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        book.book.author,
                        style: AppText.body(
                          size: 13,
                          height: 1.3,
                          color: p.inkMuted,
                        ),
                      ),
                      if (pick.said.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          '“${pick.said}”',
                          style: AppText.display(
                            size: 16,
                            weight: FontWeight.w500,
                            height: 1.32,
                            color: p.ink.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      if (by == null)
                        source
                      else
                        Row(
                          children: [
                            FounderFace(founder: by!, size: 26),
                            const SizedBox(width: 8),
                            Expanded(child: source),
                          ],
                        ),
                      if (also.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            l.founderAlso(
                              [for (final Founder f in also) f.name].join(', '),
                            ),
                            key: ValueKey('founder-also-${book.id}'),
                            style: AppText.body(
                              size: 12,
                              height: 1.35,
                              color: p.inkFaint,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              book.id == weekly && !app.isPlus
                                  ? l.bookFreeThisWeek
                                  : '${l.bookIdeas(book.cards.length)} · '
                                        '${l.bookMinutes(bookMinutes(book))}',
                              style: AppText.body(
                                size: 12,
                                weight: FontWeight.w700,
                                color: p.ink.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 64,
                            child: BookProgress(
                              of: book.cards.length,
                              read: read,
                            ),
                          ),
                        ],
                      ),
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
