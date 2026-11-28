/// The summary on a book's page: the longer way into the book, beside its
/// cards. "Read in 15 minutes" opens the reader where the reader left it
/// (lib/books/summary_reader.dart); "Listen" plays it aloud from the same
/// place (lib/books/book_player.dart), behind the switch `bookAudio`; and
/// the summary's parts follow in order, each read, still to read, or for
/// Astute+, the one being read aloud lit.
///
/// The week's free book is whole for everybody, to read and to hear, and so
/// is the first part of any book; the rest opens through the plans
/// ([requirePlus], source `book summary`).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/book_summaries.dart';
import '../data/books.dart';
import '../l10n/l10n.dart';
import '../models/book_summary.dart';
import '../state/app_state.dart';
import '../sync/book_audio_client.dart';
import '../theme.dart';
import '../widgets/premium.dart';
import 'book_player.dart';
import 'book_player_view.dart';
import 'summary_reader.dart';

/// Whether [book]'s summary is whole for the reader: Astute+, or the week's
/// book.
bool summaryWhole(AppState app, CardBook book, String? weekly) =>
    app.isPlus || book.id == weekly;

/// The block on a book's page: the two ways into the summary, and its parts.
class SummaryBlock extends StatelessWidget {
  const SummaryBlock({
    super.key,
    required this.app,
    required this.book,
    required this.summaryRef,
    required this.weekly,
  });

  final AppState app;
  final CardBook book;
  final SummaryRef summaryRef;

  /// The book of the week's id: whole for everybody.
  final String? weekly;

  @override
  Widget build(BuildContext context) {
    final BookSummary? summary = BookSummaries.instance.inHand(summaryRef);
    if (summary == null) BookSummaries.instance.warm(summaryRef);
    return ValueListenableBuilder<BookPlayer?>(
      valueListenable: BookPlayer.current,
      builder: (context, current, _) {
        final BookPlayer? mine = current != null && current.book.id == book.id
            ? current
            : null;
        return ListenableBuilder(
          listenable: Listenable.merge([
            app,
            app.summaries,
            BookAudioClient.unconfigured,
            ?mine,
          ]),
          builder: (context, _) => _build(context, summary, mine),
        );
      },
    );
  }

  Widget _build(BuildContext context, BookSummary? summary, BookPlayer? mine) {
    final l = context.l10n;
    final Palette p = context.p;
    final bool whole = summaryWhole(app, book, weekly);
    final SummaryPlace? place = app.summaries.placeOf(book.id);
    final bool underway = place != null && place.underway;
    final bool finished = place != null && place.finished && !underway;
    final int parts = summary?.parts.length ?? summaryRef.parts;
    final String read = underway
        ? l.summaryContinue
        : finished
        ? l.summaryAgain
        : l.summaryReadIn(summaryRef.minutes);
    final bool listen = bookAudioOffered(app);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: FilledButton(
            key: const ValueKey('summary-read'),
            style: FilledButton.styleFrom(
              backgroundColor: p.inverse,
              foregroundColor: p.onInverse,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            onPressed: () => openSummary(context, app, book, weekly: weekly),
            child: _Label(icon: Icons.menu_book_rounded, text: read),
          ),
        ),
        if (underway && summary != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.summaryPartOf(place.part.clamp(0, parts - 1) + 1, parts),
                  style: _meta(p),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l.summaryMinutesLeft(
                  math.max(1, summary.minutesLeft(place.part, place.through)),
                ),
                style: _meta(p),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              key: const ValueKey('summary-progress'),
              value: summary.progress(place.part, place.through),
              minHeight: 3,
              color: p.ink,
              backgroundColor: p.line,
            ),
          ),
        ],
        if (listen) ...[
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
            child: OutlinedButton(
              key: const ValueKey('summary-listen'),
              style: OutlinedButton.styleFrom(
                foregroundColor: p.ink,
                side: BorderSide(color: p.lineStrong, width: 1.2),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              onPressed: () => _listen(context, summary, mine, place, whole),
              child: _Label(
                icon: !_going(mine)
                    ? Icons.headphones_rounded
                    : mine!.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                text: !_going(mine)
                    ? l.summaryListenFor(summaryRef.minutes)
                    : mine!.playing
                    ? l.summaryPause
                    : l.summaryResume,
              ),
            ),
          ),
        ],
        if (!whole) ...[
          const SizedBox(height: 10),
          Text(
            l.summaryFreeNote,
            key: const ValueKey('summary-free-note'),
            textAlign: TextAlign.center,
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w500,
              height: 1.35,
              color: p.inkMuted,
            ),
          ),
        ],
        if (summary != null) ...[
          const SizedBox(height: 28),
          Text(
            l.summaryTitle.toUpperCase(),
            style: AppText.body(
              size: 11,
              weight: FontWeight.w800,
              spacing: 1.3,
              color: p.ink.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < summary.parts.length; i++)
            SummaryPartRow(
              key: ValueKey('summary-part-$i'),
              n: i + 1,
              title: summary.parts[i].title,
              read: place?.read.contains(i) ?? false,
              locked: !whole && i > 0,
              lit: _going(mine) && mine!.at == i,
              onTap: () => _openPart(context, i, whole),
            ),
        ],
      ],
    );
  }

  static TextStyle _meta(Palette p) => AppText.body(
    size: 12.5,
    weight: FontWeight.w600,
    color: p.ink.withValues(alpha: 0.55),
  );

  /// Opens the reader at part [i]; past the free one, through the plans and
  /// straight to it.
  void _openPart(BuildContext context, int i, bool whole) {
    if (whole || i == 0) {
      openSummary(context, app, book, weekly: weekly, at: i);
      return;
    }
    requirePlus(
      context,
      app,
      () => openSummary(context, app, book, weekly: weekly, at: i),
      source: 'book summary',
    );
  }

  /// Whether [mine] is under way, a part playing or paused in, or the next
  /// one coming: what the button pauses and resumes.
  static bool _going(BookPlayer? mine) =>
      mine != null &&
      (mine.phase == BookPlayerPhase.playing ||
          mine.phase == BookPlayerPhase.waiting);

  /// Plays the summary from where the reader is, or pauses and resumes the
  /// one playing.
  Future<void> _listen(
    BuildContext context,
    BookSummary? inHand,
    BookPlayer? mine,
    SummaryPlace? place,
    bool whole,
  ) async {
    if (mine != null) {
      // Playing or paused: pause or play on. Still asking, at the offer, at
      // the end or unable to play: the player, which says where it is.
      if (_going(mine)) {
        await mine.toggle();
      } else {
        await showBookPlayer(context, app, mine);
      }
      return;
    }
    BookSummary? summary = inHand;
    try {
      summary ??= await BookSummaries.instance.of(summaryRef);
    } catch (_) {
      return;
    }
    if (!context.mounted) return;
    int at = place != null && place.underway ? place.part : 0;
    if (at >= summary.parts.length || (!whole && at > 0)) at = 0;
    unawaited(
      startBookAudio(
        context,
        app,
        book,
        summary,
        whole: whole,
        at: at,
        from: 'book',
      ),
    );
  }
}

/// An icon and its words, the words fading at the edge rather than
/// spilling where a small phone and a large text leave no room.
class _Label extends StatelessWidget {
  const _Label({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppText.body(size: 16, weight: FontWeight.w700, height: 1.2),
          ),
        ),
      ],
    );
  }
}

/// One part of a summary on its book's page: its number and title, and
/// whether it is read, still to read, or for Astute+; the one being read
/// aloud lit.
class SummaryPartRow extends StatelessWidget {
  const SummaryPartRow({
    super.key,
    required this.n,
    required this.title,
    required this.read,
    required this.locked,
    required this.lit,
    required this.onTap,
  });

  final int n;
  final String title;
  final bool read;
  final bool locked;
  final bool lit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    final Widget row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 26,
          child: Text(
            '$n',
            style: AppText.display(
              size: 18,
              weight: FontWeight.w600,
              color: p.ink.withValues(alpha: lit ? 0.75 : 0.45),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lit) ...[
                Row(
                  children: [
                    Icon(
                      Icons.graphic_eq_rounded,
                      size: 13,
                      color: p.ink.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        l.summaryNowPlaying.toUpperCase(),
                        style: AppText.label(
                          size: 10,
                          weight: FontWeight.w700,
                          spacing: 1.4,
                          color: p.ink.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Text(
                title,
                style: lit
                    ? AppText.display(
                        size: 17,
                        weight: FontWeight.w600,
                        height: 1.25,
                        color: p.ink,
                      )
                    : AppText.body(
                        size: 15,
                        weight: FontWeight.w600,
                        height: 1.35,
                        color: locked ? p.inkMuted : p.ink,
                      ),
              ),
            ],
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
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: lit
          ? Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
              decoration: BoxDecoration(
                color: p.surfaceRaised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p.line),
              ),
              child: row,
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
              child: row,
            ),
    );
  }
}
