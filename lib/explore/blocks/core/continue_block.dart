/// Continue: what the reader started and left — a path's part opened and
/// read partway, a book stopped at one of its ideas — the latest first, each
/// a tap from the card where they stopped.
///
/// A path counts once the reader has opened it (AppState.pathsOpened) and
/// read a card of it; a book once one of its ideas is read; either until it
/// is read whole. A part of a path read whole hands on to the next part,
/// deeper, while the theme has one. Where the next card is past what the free plan opens, the
/// tile says so with a lock and opens the path's or the book's own page,
/// where the way on is. Nothing started, no section: a new reader never
/// sees it.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../analytics.dart';
import '../../../data/genre_names.dart';
import '../../../data/genres.dart';
import '../../../data/pill_bank.dart';
import '../../../data/topics.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../screens/card_path_screen.dart';
import '../../../state/app_state.dart';
import '../../../state/reading_log.dart';
import '../../../theme.dart';
import '../../../widgets/subject_icon.dart';
import '../../explore_block.dart';
import 'books_block.dart';
import 'layout.dart';
import 'paths_block.dart';

/// Something started and not finished: a part of a path, or a book.
class Started {
  const Started.path(
    CardPath this.path, {
    required this.read,
    required this.next,
    required this.at,
  }) : book = null;

  const Started.book(
    CardBook this.book, {
    required this.read,
    required this.next,
    required this.at,
  }) : path = null;

  final CardPath? path;
  final CardBook? book;

  /// How many of its cards are read, and where the first one not read is.
  final int read;
  final int next;

  /// When it was last read or opened, in seconds since the epoch.
  final int at;

  List<Pill> get cards => path?.cards ?? book!.cards;

  /// Its subject, by name.
  String get topic => cards.first.topic;
}

/// A path the reader opened, as AppState.pathsOpened keeps it:
/// `genre|subject|part|at`.
typedef OpenedPath = ({String genre, String topicKey, int part, int at});

OpenedPath? parseOpenedPath(String raw) {
  final List<String> parts = raw.split('|');
  if (parts.length != 4) return null;
  final int? part = int.tryParse(parts[2]);
  final int? at = int.tryParse(parts[3]);
  if (part == null || at == null) return null;
  return (genre: parts[0], topicKey: parts[1], part: part, at: at);
}

/// What [app]'s reader started and has not finished, the latest first,
/// [limit] at most, narrowed to [subject] (a subject's name) when there is
/// one.
List<Started> startedOf(AppState app, {String? subject, int limit = 3}) {
  final Set<String> seen = app.seenIds;
  // When each card was last read: the reading log, oldest first.
  final Map<String, int> lastRead = {
    for (final CardReadEntry e in app.readingLog) e.id: e.at,
  };
  int latest(List<Pill> cards, int floor) {
    int at = floor;
    for (final Pill c in cards) {
      final int? t = lastRead[c.id];
      if (t != null && t > at) at = t;
    }
    return at;
  }

  final List<Started> out = [];
  final Set<String> kept = {};
  for (final String raw in app.pathsOpened) {
    final OpenedPath? o = parseOpenedPath(raw);
    if (o == null || !kept.add('${o.genre}|${o.topicKey}|${o.part}')) continue;
    final Genre? genre = genreById(o.genre);
    if (genre == null || kTopics[o.topicKey] == null) continue;
    final List<CardPath> parts = partsOf(genre, o.topicKey, PillBank.live);
    if (o.part < 1 || o.part > parts.length) continue;
    final CardPath path = parts[o.part - 1];
    final int read = path.cards.where((c) => seen.contains(c.id)).length;
    if (read == 0) continue;
    if (read >= path.cards.length) {
      // A part read whole: the theme goes on, deeper, in the next one,
      // unless that one is in hand already.
      if (o.part >= parts.length ||
          !kept.add('${o.genre}|${o.topicKey}|${o.part + 1}')) {
        continue;
      }
      final CardPath deeper = parts[o.part];
      final int done = deeper.cards.where((c) => seen.contains(c.id)).length;
      if (done >= deeper.cards.length) continue;
      out.add(
        Started.path(
          deeper,
          read: done,
          next: deeper.cards.indexWhere((c) => !seen.contains(c.id)),
          at: latest(path.cards, o.at),
        ),
      );
      continue;
    }
    out.add(
      Started.path(
        path,
        read: read,
        next: path.cards.indexWhere((c) => !seen.contains(c.id)),
        at: latest(path.cards, o.at),
      ),
    );
  }
  for (final CardBook book in booksOf(PillBank.live, today: app.today)) {
    final int read = book.cards.where((c) => seen.contains(c.id)).length;
    if (read == 0 || read >= book.cards.length) continue;
    out.add(
      Started.book(
        book,
        read: read,
        next: book.cards.indexWhere((c) => !seen.contains(c.id)),
        at: latest(book.cards, 0),
      ),
    );
  }
  out.sort((a, b) => b.at.compareTo(a.at));
  return [
    for (final Started s in out)
      if (subject == null || s.topic == subject) s,
  ].take(limit).toList();
}

/// Whether the card [s] goes on with is past what the free plan opens.
bool isLocked(AppState app, Started s, {String? weekly}) {
  if (app.isPlus) return false;
  if (s.path != null) return s.next >= kPathFree;
  return s.book!.id != weekly && s.next >= kBookFree;
}

/// Goes on with [s]: at the card where the reader stopped, or, where that
/// card is locked, on the path's or the book's own page.
Future<void> goOn(BuildContext context, AppState app, Started s) {
  final String? weekly = bookOfTheWeek(PillBank.live, app.today);
  final bool locked = isLocked(app, s, weekly: weekly);
  Analytics.capture('continue opened', {
    'kind': s.path != null ? 'path' : 'book',
    'read': s.read,
    'of': s.cards.length,
    'locked': locked,
  });
  final CardPath? path = s.path;
  if (path != null) {
    return locked
        ? CardPathScreen.open(context, app, path, from: 'continue')
        : openPath(context, app, path, from: s.next);
  }
  return locked
      ? openBookPage(context, app, s.book!, weekly: weekly)
      : openBook(context, app, s.book!, weekly: weekly, from: s.next);
}

/// The block: see the library's own words.
class ContinueBlock extends ExploreBlock with SectionLayout {
  const ContinueBlock();

  @override
  String get name => 'continue';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final AppState app = host.app;
    final List<Started> started = startedOf(
      app,
      subject: host.subject,
      limit: section.limit ?? 3,
    );
    if (started.isEmpty) return null;
    final String? weekly = bookOfTheWeek(PillBank.live, app.today);
    final double height = StartedTile.heightFor(context);
    // Room under the row of its own: the cover after it sits close to what
    // is above it (its gap is 6, for the day's three), and a row of tiles
    // that close reads as the cover's own top.
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SectionFrame(
        title: section.title(host.language) ?? context.l10n.pathContinue,
        line: section.subtitle(host.language),
        child: LayoutBuilder(
          builder: (context, box) {
            final double room = box.maxWidth - 40;
            // One fills the row; more show the next one's edge, to say the
            // row goes on.
            final double width = started.length == 1
                ? room
                : (room * 0.86).clamp(0, 320).toDouble();
            return SizedBox(
              height: height,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: started.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) => SizedBox(
                  width: width,
                  child: StartedTile(
                    key: ValueKey('continue-$i'),
                    started: started[i],
                    locked: isLocked(app, started[i], weekly: weekly),
                    onTap: () => goOn(context, app, started[i]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A thing started: its mark (the subject's, or the book's cover), its
/// name, how far it is read, and the way on.
class StartedTile extends StatelessWidget {
  const StartedTile({
    super.key,
    required this.started,
    required this.locked,
    required this.onTap,
  });

  final Started started;
  final bool locked;
  final VoidCallback onTap;

  /// As tall as its two lines need at the reader's text size (the name, at
  /// 15 and a line of 1.25; the count, at 12.5 and 1.3; the bar and the room
  /// round them), and never less than a book's cover.
  static double heightFor(BuildContext context) {
    final TextScaler t = MediaQuery.textScalerOf(context);
    final double lines = t.scale(15) * 1.25 + t.scale(12.5) * 1.3;
    return math.max(84, (lines + 7 + 4 + 6 + 24 + 2).ceilToDouble());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final CardPath? path = started.path;
    final CardBook? book = started.book;
    final TopicStyle style =
        kTopics[path?.topicKey ?? topicKeyForName(started.topic)] ??
        kTopics.values.first;
    final String name = path != null ? l.themeOf(path.genre) : book!.book.title;
    // A part not begun is the next of one read whole: it says so.
    // Otherwise the line is the card the reader goes on with, by its place
    // and its question: what is next pulls harder than what is done, and
    // the bar above already says how far (prototype A3).
    final String meta = path != null && started.read == 0
        ? l.pathNextPart(path.part)
        : '${started.next + 1}/${started.cards.length} · '
              '${started.cards[started.next].question}';
    final String read = [
      if (path != null && path.parts > 1) l.pathPartOf(path.part, path.parts),
      l.pathReadOf(started.read, started.cards.length),
    ].join(' · ');
    final Color tint = p.isDark ? style.color : style.ink;
    return Semantics(
      button: true,
      label: '${l.pathContinue}: $name, $read. $meta',
      excludeSemantics: true,
      child: Material(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(
              children: [
                if (book != null)
                  BookCover(book: book, width: 40)
                else
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: style.color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SubjectIcon(
                      subject: style.name,
                      size: 21,
                      ink: style.ink,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          size: 15,
                          weight: FontWeight.w700,
                          height: 1.25,
                          color: p.ink,
                        ),
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: started.read / started.cards.length,
                          minHeight: 4,
                          color: tint,
                          backgroundColor: p.line,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          size: 12.5,
                          height: 1.3,
                          color: p.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: locked ? p.surface : style.color,
                    shape: BoxShape.circle,
                    border: locked ? Border.all(color: p.lineStrong) : null,
                  ),
                  child: Icon(
                    locked ? Icons.lock_rounded : Icons.arrow_forward_rounded,
                    size: locked ? 15 : 18,
                    color: locked ? p.inkMuted : style.ink,
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
