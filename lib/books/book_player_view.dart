/// A book's summary heard, as the reader meets it: the player, as a sheet
/// over the book's page (the summary's parts in a list, the one being read
/// lit and the others quiet, a line across the top that fills as each is
/// heard, back fifteen seconds, play and pause, on to the next part), and
/// the small player that stays over every screen while the book plays, a
/// tap from the whole one and a cross from stopping.
///
/// On the free plan the first part of any book is heard, and the week's
/// book whole; past them the player stops on the offer of the rest, which
/// opens the paywall through [requirePlus] (source `book audio`), and with
/// Astute+ taken there it goes straight on. Behind the server's switch
/// `bookAudio` (docs/REMOTE.md), and hidden for the sitting the moment the
/// server says it has no key ([bookAudioOffered]).
///
/// The small player never covers a card: it steps aside while Today's deck
/// is on the table and while a screen of cards is open ([BookPlayerRoom]),
/// and under any sheet or dialog.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/books.dart';
import '../data/pills_repository.dart' show dateKey;
import '../explore/blocks/core/books_block.dart' show BookCover;
import '../l10n/l10n.dart';
import '../models/book_summary.dart';
import '../screens/today_done_view.dart' show plusActionOf;
import '../state/app_state.dart';
import '../sync/book_audio_client.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/premium.dart';
import 'book_player.dart';
import 'player_room.dart';

export 'player_room.dart';

/// Whether a book's summary can be listened to: the server's switch on,
/// Firebase up to ask, and no word from the server, this sitting, that it
/// has no key.
bool bookAudioOffered(AppState app) =>
    app.bookAudioOn &&
    BookAudioClient.reachable() &&
    !BookAudioClient.unconfigured.value;

/// Starts reading [summary] aloud from part [at], and opens the player over
/// [context]. Whatever book played before stops.
Future<void> startBookAudio(
  BuildContext context,
  AppState app,
  CardBook book,
  BookSummary summary, {
  required bool whole,
  int at = 0,
  String from = 'book',
}) async {
  HapticFeedback.selectionClick();
  final BookPlayer player = BookPlayer(
    book: book,
    summary: summary,
    date: dateKey(app.today),
    tz: DateTime.now().timeZoneOffset.inMinutes,
    whole: whole,
    shelf: app.summaries,
    from: from,
  );
  unawaited(BookPlayer.play(player, at: at));
  await showBookPlayer(context, app, player);
}

/// Opens the whole player on [player], over [context].
Future<void> showBookPlayer(
  BuildContext context,
  AppState app,
  BookPlayer player,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  barrierColor: const Color(0x8C141416),
  builder: (_) => BookPlayerSheet(app: app, player: player),
);

/// The paywall, from the player: with Astute+ taken there, the rest of the
/// book follows at once.
Future<void> _openPlus(BuildContext context, AppState app, BookPlayer player) =>
    requirePlus(context, app, player.unlock, source: 'book audio');

/// How much room the small player takes at the foot of a page, so a page
/// can keep its last lines clear of it: none while nothing plays. A page
/// that asks under the host is built again as a book starts and stops.
double bookPlayerRoom(BuildContext context) {
  context.dependOnInheritedWidgetOfExactType<_Playing>();
  return BookPlayer.current.value == null ? 0 : MiniBookPlayer.height + 18;
}

/// The book playing, for every page under the host: what [bookPlayerRoom]
/// listens to.
class _Playing extends InheritedNotifier<ValueNotifier<BookPlayer?>> {
  const _Playing({required super.notifier, required super.child});
}

// ── The small player, over every screen ──────────────────────────────────

/// Puts the small player over the app while a book plays: above the tab
/// bar on the tabs, at the foot of any other page; never over a card,
/// a sheet or a dialog. Sits above the navigator (MaterialApp's builder).
class BookPlayerHost extends StatelessWidget {
  const BookPlayerHost({super.key, required this.app, required this.child});

  final AppState app;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Playing(notifier: BookPlayer.current, child: _stack());
  }

  Widget _stack() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: child),
        ValueListenableBuilder<BookPlayer?>(
          valueListenable: BookPlayer.current,
          builder: (context, player, _) {
            if (player == null) {
              return const Positioned(
                left: 0,
                bottom: 0,
                child: SizedBox.shrink(),
              );
            }
            return ListenableBuilder(
              listenable: Listenable.merge([
                BookPlayerRoom.routes.revision,
                BookPlayerRoom.todayDeck,
                BookPlayerRoom.cards,
              ]),
              builder: (context, _) {
                final BookRoutes routes = BookPlayerRoom.routes;
                final bool onTabs = routes.pages <= 1;
                final bool hidden =
                    routes.popupOnTop ||
                    BookPlayerRoom.cards.value > 0 ||
                    (onTabs && BookPlayerRoom.todayDeck.value);
                final double foot = MediaQuery.paddingOf(context).bottom;
                return Positioned(
                  left: 12,
                  right: 12,
                  // Above the floating tab bar on the tabs (its 58 points
                  // and the gap under it), at the foot of any other page.
                  bottom: foot + (onTabs ? 76 : 10),
                  // Above the navigator there is no Material: the small
                  // player brings its own, for its words and its ink.
                  child: Material(
                    type: MaterialType.transparency,
                    child: IgnorePointer(
                      ignoring: hidden,
                      child: AnimatedOpacity(
                        opacity: hidden ? 0 : 1,
                        duration: const Duration(milliseconds: 180),
                        child: AnimatedSlide(
                          offset: hidden ? const Offset(0, 0.4) : Offset.zero,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: MiniBookPlayer(
                            player: player,
                            onOpen: () {
                              final BuildContext? under =
                                  BookPlayerRoom.navigator.currentContext;
                              if (under != null) {
                                showBookPlayer(under, app, player);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// The small player: the book's cover, its title and the part being read,
/// play and pause, and a cross that stops it; a line along its foot that
/// fills as the book is heard. A tap anywhere else opens the whole player.
class MiniBookPlayer extends StatelessWidget {
  const MiniBookPlayer({super.key, required this.player, required this.onOpen});

  final BookPlayer player;
  final VoidCallback onOpen;

  /// Its height, before the reader's text size grows it.
  static const double height = 62;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final int at = player.at < 0 ? 0 : player.at;
        final String where = [
          l.summaryPartOf(at + 1, player.summary.parts.length),
          player.summary.parts[at].title,
        ].join(' · ');
        return Semantics(
          container: true,
          label: '${player.summary.title}, $where',
          child: Container(
            key: const ValueKey('book-mini-player'),
            constraints: const BoxConstraints(minHeight: height),
            decoration: BoxDecoration(
              color: p.surfaceRaised,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: p.isDark ? 0.55 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(9, 8, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: l.bookAudioOpen,
                          child: GestureDetector(
                            key: const ValueKey('book-mini-open'),
                            behavior: HitTestBehavior.opaque,
                            onTap: onOpen,
                            child: Row(
                              children: [
                                ExcludeSemantics(
                                  child: BookCover(
                                    book: player.book,
                                    width: 30,
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        player.summary.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.body(
                                          size: 13.5,
                                          weight: FontWeight.w700,
                                          color: p.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        where,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.body(
                                          size: 12,
                                          weight: FontWeight.w500,
                                          color: p.ink.withValues(alpha: 0.58),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Round(
                        key: const ValueKey('book-mini-play'),
                        icon: player.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        label: player.playing ? l.videoPause : l.videoPlay,
                        size: 40,
                        filled: true,
                        onTap: player.toggle,
                      ),
                      const SizedBox(width: 6),
                      _Round(
                        key: const ValueKey('book-mini-stop'),
                        icon: Icons.close_rounded,
                        label: l.bookAudioStop,
                        size: 34,
                        onTap: player.stop,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: player.overall,
                    minHeight: 2,
                    color: p.ink,
                    backgroundColor: p.line,
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

// ── The whole player ─────────────────────────────────────────────────────

/// The player, as a sheet. Public so a test, and the camera, can lay it out.
class BookPlayerSheet extends StatelessWidget {
  const BookPlayerSheet({super.key, required this.app, required this.player});

  final AppState app;
  final BookPlayer player;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    return Container(
      key: const ValueKey('book-player'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      child: ListenableBuilder(
        listenable: player,
        builder: (context, _) {
          if (player.closed) return const SizedBox.shrink();
          final int n = player.summary.parts.length;
          final int at = player.at < 0 ? 0 : player.at;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.lineStrong,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: BookCover(book: player.book, width: 52),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.listenEntryShort.toUpperCase(),
                            style: AppText.label(
                              size: 10.5,
                              weight: FontWeight.w700,
                              spacing: 1.6,
                              color: p.ink.withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Semantics(
                            header: true,
                            child: Text(
                              player.summary.title,
                              style: AppText.display(
                                size: 22,
                                weight: FontWeight.w600,
                                height: 1.12,
                                spacing: -0.4,
                                color: p.ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            player.summary.author,
                            style: AppText.body(size: 13.5, color: p.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _Round(
                      key: const ValueKey('book-player-close'),
                      icon: Icons.keyboard_arrow_down_rounded,
                      label: l.closeLabel,
                      size: 34,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _Line(player: player),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(l.summaryPartOf(at + 1, n), style: _meta(p)),
                    ),
                    const SizedBox(width: 10),
                    if (player.minutesLeft > 0)
                      Text(
                        l.summaryMinutesLeft(player.minutesLeft),
                        style: _meta(p),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                for (int k = 0; k < n; k++)
                  _PartRow(app: app, player: player, k: k),
                const SizedBox(height: 12),
                _Foot(app: app, player: player),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    key: const ValueKey('book-player-stop'),
                    style: TextButton.styleFrom(
                      foregroundColor: p.ink.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      player.stop();
                      Navigator.of(context).maybePop();
                    },
                    child: Text(
                      l.bookAudioStop,
                      style: AppText.body(size: 13.5, weight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static TextStyle _meta(Palette p) => AppText.body(
    size: 12.5,
    weight: FontWeight.w600,
    color: p.ink.withValues(alpha: 0.55),
  );
}

/// The line across the top: one stroke a part, as Today's bars are, each
/// filling as its part is heard.
class _Line extends StatelessWidget {
  const _Line({required this.player});

  final BookPlayer player;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final int n = player.summary.parts.length;
    return Row(
      key: const ValueKey('book-player-line'),
      children: [
        for (int k = 0; k < n; k++)
          Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: k == n - 1 ? 0 : 4),
              decoration: BoxDecoration(
                color: p.line,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: player.progressOf(k),
                child: Container(
                  decoration: BoxDecoration(
                    color: p.ink,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// [d] as a clock reads it: 3:07.
String _clock(Duration d) {
  final int s = d.inSeconds.clamp(0, 99 * 60);
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// One part of the summary: the one being read lit, on a raised ground,
/// with where in it the voice is; the rest quiet, and what they came to.
/// A tap plays it; one that is Astute+'s opens the paywall.
class _PartRow extends StatelessWidget {
  const _PartRow({required this.app, required this.player, required this.k});

  final AppState app;
  final BookPlayer player;
  final int k;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    final SummaryPart part = player.summary.parts[k];
    final BookPartState state = player.states[k];
    final bool lit =
        k == player.at &&
        (player.phase == BookPlayerPhase.playing ||
            player.phase == BookPlayerPhase.waiting);
    final bool locked = state == BookPartState.locked;
    final VoidCallback onTap = locked
        ? () => _openPlus(context, app, player)
        : () => player.jumpTo(k);
    if (lit) {
      final Duration? whole = player.duration;
      return Semantics(
        button: true,
        child: Container(
          key: ValueKey('book-part-$k-lit'),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.graphic_eq_rounded,
                    size: 14,
                    color: p.ink.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l.summaryNowPlaying.toUpperCase(),
                      style: AppText.label(
                        size: 10.5,
                        weight: FontWeight.w700,
                        spacing: 1.4,
                        color: p.ink.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  if (whole != null && whole > Duration.zero)
                    Text(
                      '${_clock(player.position)} / ${_clock(whole)}',
                      style:
                          AppText.body(
                            size: 12,
                            weight: FontWeight.w600,
                            color: p.ink.withValues(alpha: 0.55),
                          ).copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                '${k + 1}. ${part.title}',
                style: AppText.display(
                  size: 17,
                  weight: FontWeight.w600,
                  height: 1.25,
                  spacing: -0.2,
                  color: p.ink,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final bool quiet = locked || state == BookPartState.unavailable;
    return Semantics(
      button: true,
      child: GestureDetector(
        key: ValueKey('book-part-$k'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${k + 1}',
                  style: AppText.display(
                    size: 15,
                    weight: FontWeight.w600,
                    color: p.ink.withValues(alpha: 0.4),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  part.title,
                  style: AppText.body(
                    size: 14.5,
                    weight: FontWeight.w500,
                    height: 1.3,
                    color: p.ink.withValues(alpha: quiet ? 0.4 : 0.66),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (locked)
                Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: p.ink.withValues(alpha: 0.4),
                )
              else if (state == BookPartState.heard)
                Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: p.ink.withValues(alpha: 0.45),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Under the parts: the buttons while there is something to play; the
/// offer once the free part is heard; a calm word when nothing can be
/// heard; and once all is heard, the way to hear it again.
class _Foot extends StatelessWidget {
  const _Foot({required this.app, required this.player});

  final AppState app;
  final BookPlayer player;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    switch (player.phase) {
      case BookPlayerPhase.offer:
        return _Offer(app: app, player: player);
      case BookPlayerPhase.unavailable:
        return _Said(
          key: const ValueKey('book-player-unavailable'),
          line: l.listenUnavailable,
          action: l.tryAgain,
          onAction: player.toggle,
        );
      case BookPlayerPhase.done:
        return _Said(
          key: const ValueKey('book-player-done'),
          line: l.bookAudioDone,
          action: l.listenAgain,
          onAction: player.toggle,
        );
      case BookPlayerPhase.preparing:
      case BookPlayerPhase.waiting:
      case BookPlayerPhase.playing:
        break;
    }
    final bool waiting =
        player.phase == BookPlayerPhase.preparing ||
        player.phase == BookPlayerPhase.waiting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 20),
          child: waiting
              ? Text(
                  player.phase == BookPlayerPhase.preparing
                      ? l.listenPreparing
                      : l.bookAudioWaiting,
                  key: const ValueKey('book-player-waiting'),
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w500,
                    color: p.ink.withValues(alpha: 0.5),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Round(
              key: const ValueKey('book-player-back'),
              label: l.bookAudioBack,
              size: 48,
              onTap: waiting ? null : player.back,
              child: _Back15(color: p.ink),
            ),
            const SizedBox(width: 22),
            _Round(
              key: const ValueKey('book-player-play'),
              icon: player.playing
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              label: player.playing ? l.videoPause : l.videoPlay,
              size: 66,
              filled: true,
              onTap: waiting ? null : player.toggle,
            ),
            const SizedBox(width: 22),
            _Round(
              key: const ValueKey('book-player-next'),
              icon: Icons.skip_next_rounded,
              label: l.summaryNextPart,
              size: 48,
              onTap: waiting
                  ? null
                  : () {
                      if (player.nextIsLocked) {
                        _openPlus(context, app, player);
                      } else {
                        player.next();
                      }
                    },
            ),
          ],
        ),
        if (!player.whole) ...[
          const SizedBox(height: 14),
          Text(
            l.summaryFreeNote,
            key: const ValueKey('book-player-free-note'),
            textAlign: TextAlign.center,
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w500,
              height: 1.3,
              color: p.ink.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }
}

/// After the free part: what the rest is, and the way to it.
class _Offer extends StatelessWidget {
  const _Offer({required this.app, required this.player});

  final AppState app;
  final BookPlayer player;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    return Container(
      key: const ValueKey('book-player-offer'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.plusNameCaps,
            style: AppText.label(
              size: 10.5,
              weight: FontWeight.w700,
              spacing: 1.6,
              color: p.link,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.bookAudioOfferTitle,
            style: AppText.display(
              size: 20,
              weight: FontWeight.w600,
              height: 1.2,
              spacing: -0.3,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.bookAudioOfferLine,
            style: AppText.body(
              size: 14,
              height: 1.35,
              color: p.ink.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          ChunkyButton(
            key: const ValueKey('book-player-plus'),
            label: plusActionOf(context),
            fill: p.inverse,
            ink: p.onInverse,
            height: 50,
            onPressed: () => _openPlus(context, app, player),
          ),
        ],
      ),
    );
  }
}

/// A calm line and one quiet way on.
class _Said extends StatelessWidget {
  const _Said({
    super.key,
    required this.line,
    required this.action,
    required this.onAction,
  });

  final String line;
  final String action;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final Color ink = p.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          line,
          textAlign: TextAlign.center,
          style: AppText.body(
            size: 14.5,
            weight: FontWeight.w500,
            height: 1.35,
            color: ink.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Semantics(
            button: true,
            child: GestureDetector(
              key: const ValueKey('book-player-again'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onAction(),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  action,
                  style: AppText.body(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The mark on "back 15 seconds": an arrow turning back round a 15.
class _Back15 extends StatelessWidget {
  const _Back15({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.replay_rounded, size: 30, color: color),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            '15',
            textScaler: TextScaler.noScaling,
            style: AppText.body(
              size: 8.5,
              weight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// A round button: play and pause filled, the rest on the faint ground.
class _Round extends StatelessWidget {
  const _Round({
    super.key,
    this.icon,
    this.child,
    required this.label,
    required this.size,
    required this.onTap,
    this.filled = false,
  });

  final IconData? icon;
  final Widget? child;
  final String label;
  final double size;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final bool off = onTap == null;
    final Color ground = filled ? p.inverse : p.ink.withValues(alpha: 0.08);
    final Color ink = filled ? p.onInverse : p.ink;
    return Semantics(
      container: true,
      button: true,
      enabled: !off,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: off
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: off ? 0.35 : 1,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: ground, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: child ?? Icon(icon, size: size * 0.46, color: ink),
          ),
        ),
      ),
    );
  }
}
