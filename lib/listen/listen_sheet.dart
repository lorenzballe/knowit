/// Listen, as the reader meets it: a quiet entry at the end of Today's
/// header while the five are read, and the small player it opens: the five
/// in a list, the one being read lit and the others quiet, a line across
/// the top that fills as each is heard, play and pause, and on to the next.
///
/// On the free plan the first card that can be heard is free; after it the
/// player stops on the offer of the rest, which opens the paywall through
/// [requirePlus] (source `listen`), and with Astute+ taken there it goes
/// straight on. Behind the server's switch `listen` (docs/REMOTE.md), and
/// hidden for the sitting the moment the server says it has no key.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/pills_repository.dart' show dateKey, kPillsPerDay;
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../screens/today_done_view.dart' show plusActionOf;
import '../state/app_state.dart';
import '../sync/listen_client.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/premium.dart';
import '../widgets/subject_icon.dart';
import 'listen_session.dart';

/// Whether Listen is offered on Today: the server's switch on, Firebase up
/// to ask, and no word from the server, this sitting, that it has no key.
bool listenOffered(AppState app) =>
    app.listenOn &&
    ListenClient.reachable() &&
    !ListenClient.unconfigured.value;

/// Opens the player on today's five.
Future<void> showListenSheet(
  BuildContext context,
  AppState app, {
  String from = 'today',
}) async {
  HapticFeedback.selectionClick();
  final DateTime today = app.today;
  final ListenSession session = ListenSession(
    cards: app.todaysDeck.take(kPillsPerDay).toList(),
    date: dateKey(today),
    tz: DateTime.now().timeZoneOffset.inMinutes,
    plus: app.isPlus,
    facts: app.cardFacts,
    from: from,
  );
  unawaited(session.begin());
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8C141416),
      builder: (_) => ListenSheet(app: app, session: session),
    );
  } finally {
    await session.close();
    session.dispose();
  }
}

// ── The entry ─────────────────────────────────────────────────────────────

/// "Listen to today's five": a small pill on the same faint ground as the
/// finished day's "See again", a headphones mark and the words, 30 high to
/// the eye. Where the row is short it says one word, and at the least the
/// mark alone; a screen reader always hears the whole.
class ListenEntry extends StatelessWidget {
  const ListenEntry({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static const double height = 30;

  static TextStyle _style(Color ink) =>
      AppText.body(size: 12.5, weight: FontWeight.w700, color: ink);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final TextStyle style = _style(ink);
    return LayoutBuilder(
      builder: (context, box) {
        // Padding, mark and gap around the words.
        const double around = 9 + 16 + 5 + 12;
        String? label = l.listenEntry;
        if (around + _width(context, label, style) > box.maxWidth) {
          label = l.listenEntryShort;
        }
        if (around + _width(context, label, style) > box.maxWidth) {
          label = null;
        }
        final Widget mark = Icon(
          Icons.headphones_rounded,
          size: 16,
          color: ink,
        );
        // A node of its own: merged into the header's, the whole of Today
        // would be read as one button.
        return Semantics(
          container: true,
          button: true,
          label: l.listenEntry,
          excludeSemantics: true,
          child: GestureDetector(
            key: const ValueKey('listen-entry'),
            behavior: HitTestBehavior.opaque,
            onTap: onPressed,
            child: Container(
              height: height,
              width: label == null ? height : null,
              padding: label == null
                  ? EdgeInsets.zero
                  : const EdgeInsets.fromLTRB(9, 0, 12, 0),
              decoration: BoxDecoration(
                color: ink.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: label == null
                  ? mark
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        mark,
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: style,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

double _width(BuildContext context, String text, TextStyle style) {
  final TextPainter painter = TextPainter(
    text: TextSpan(
      text: text,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final double width = painter.width;
  painter.dispose();
  return width;
}

// ── The player ────────────────────────────────────────────────────────────

/// The player, as a sheet. Public so a test, and the camera, can lay it out.
class ListenSheet extends StatelessWidget {
  const ListenSheet({super.key, required this.app, required this.session});

  final AppState app;
  final ListenSession session;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    return Container(
      key: const ValueKey('listen-sheet'),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) => SingleChildScrollView(
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
                            l.listenTitle,
                            style: AppText.display(
                              size: 26,
                              weight: FontWeight.w600,
                              spacing: -0.6,
                              color: p.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Round(
                    key: const ValueKey('listen-close'),
                    icon: Icons.close_rounded,
                    label: l.closeLabel,
                    size: 34,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Line(session: session),
              const SizedBox(height: 14),
              for (int k = 0; k < session.cards.length; k++)
                _Row(app: app, session: session, k: k),
              const SizedBox(height: 14),
              _Foot(app: app, session: session),
            ],
          ),
        ),
      ),
    );
  }
}

/// The line across the top: one stroke a card, as Today's bars are, each
/// filling as its card is read.
class _Line extends StatelessWidget {
  const _Line({required this.session});

  final ListenSession session;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final int n = session.cards.length;
    return Row(
      key: const ValueKey('listen-line'),
      children: [
        for (int k = 0; k < n; k++)
          Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: k == n - 1 ? 0 : 5),
              decoration: BoxDecoration(
                color: p.line,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: session.progressOf(k),
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

/// One card of the five: the one being read lit, on a raised ground, with
/// its whole question and where in it the voice is; the rest quiet, a line
/// each, and what they came to.
class _Row extends StatelessWidget {
  const _Row({required this.app, required this.session, required this.k});

  final AppState app;
  final ListenSession session;
  final int k;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    final Pill pill = session.cards[k];
    final ListenCardState state = session.states[k];
    final bool lit =
        k == session.at &&
        const {
          ListenPhase.question,
          ListenPhase.think,
          ListenPhase.answer,
          ListenPhase.turn,
        }.contains(session.phase);
    final String? where = lit
        ? switch (session.phase) {
            ListenPhase.question => l.listenQuestion,
            ListenPhase.think => l.listenThink,
            ListenPhase.answer || ListenPhase.turn => l.listenAnswer,
            _ => null,
          }
        : switch (state) {
            ListenCardState.nothing => l.listenNothing,
            ListenCardState.unavailable => l.listenCardUnavailable,
            _ => null,
          };
    final Color mark = _tint(context, pill.color);
    final Widget head = Row(
      children: [
        CardMark(pill: pill, size: 15, ink: mark),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            [l.subjectOf(pill.topic), ?where].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              size: 12,
              weight: FontWeight.w600,
              color: p.ink.withValues(alpha: lit ? 0.7 : 0.45),
            ),
          ),
        ),
        if (state == ListenCardState.locked) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.lock_rounded,
            size: 13,
            color: p.ink.withValues(alpha: 0.4),
          ),
        ] else if (state == ListenCardState.heard && !lit) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.check_rounded,
            size: 14,
            color: p.ink.withValues(alpha: 0.45),
          ),
        ],
      ],
    );
    if (lit) {
      return Container(
        key: ValueKey('listen-row-$k-lit'),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            head,
            const SizedBox(height: 8),
            Text(
              pill.question,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
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
      );
    }
    final bool quiet =
        state == ListenCardState.nothing ||
        state == ListenCardState.unavailable ||
        state == ListenCardState.locked;
    final Widget row = Padding(
      key: ValueKey('listen-row-$k'),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          head,
          const SizedBox(height: 4),
          Text(
            pill.question,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              size: 14,
              weight: FontWeight.w500,
              height: 1.3,
              color: p.ink.withValues(alpha: quiet ? 0.38 : 0.62),
            ),
          ),
        ],
      ),
    );
    // A card that is Astute+'s opens the paywall, as going on to it does.
    if (state != ListenCardState.locked) return row;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openPlus(context, app, session),
        child: row,
      ),
    );
  }

  /// A subject's colour as a mark on this ground, unless the ground is so
  /// close to it that the mark would vanish (TomorrowLine's rule).
  static Color _tint(BuildContext context, Color colour) {
    final double a = colour.computeLuminance();
    final double b = context.p.surface.computeLuminance();
    final double ratio =
        (a > b ? a + 0.05 : b + 0.05) / (a > b ? b + 0.05 : a + 0.05);
    return ratio < 1.6 ? context.p.ink : colour;
  }
}

/// Under the list: the buttons while there is something to play; the offer
/// once the free card is heard; a calm word when nothing can be heard; and
/// once all is heard, the way to hear it again.
class _Foot extends StatelessWidget {
  const _Foot({required this.app, required this.session});

  final AppState app;
  final ListenSession session;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    switch (session.phase) {
      case ListenPhase.offer:
        return _Offer(app: app, session: session);
      case ListenPhase.unavailable:
        return _Said(
          key: const ValueKey('listen-unavailable'),
          line: l.listenUnavailable,
          action: l.tryAgain,
          onAction: session.toggle,
        );
      case ListenPhase.done:
        return _Said(
          key: const ValueKey('listen-done'),
          line: l.listenDone,
          action: l.listenAgain,
          onAction: session.toggle,
        );
      default:
        break;
    }
    final bool waiting =
        session.phase == ListenPhase.preparing ||
        session.phase == ListenPhase.waiting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 22,
          child: waiting
              ? Text(
                  session.phase == ListenPhase.preparing
                      ? l.listenPreparing
                      : l.listenWaiting,
                  key: const ValueKey('listen-waiting'),
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
            // As wide as the button on the other side, so play is centred.
            const SizedBox(width: 48),
            const SizedBox(width: 22),
            _Round(
              key: const ValueKey('listen-play'),
              icon: session.playing
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              label: session.playing ? l.videoPause : l.videoPlay,
              size: 66,
              filled: true,
              onTap: waiting ? null : session.toggle,
            ),
            const SizedBox(width: 22),
            _Round(
              key: const ValueKey('listen-next'),
              icon: Icons.skip_next_rounded,
              label: l.listenNextCard,
              size: 48,
              onTap: waiting
                  ? null
                  : () {
                      if (session.nextIsLocked &&
                          session.freeCard == session.at) {
                        _openPlus(context, app, session);
                      } else {
                        session.next();
                      }
                    },
            ),
          ],
        ),
        if (!session.plus) ...[
          const SizedBox(height: 14),
          Text(
            l.listenFreeNote,
            key: const ValueKey('listen-free-note'),
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

/// The paywall, from the player: with Astute+ taken there, the rest of the
/// five follow at once.
Future<void> _openPlus(
  BuildContext context,
  AppState app,
  ListenSession session,
) => requirePlus(context, app, session.unlock, source: 'listen');

/// After the free card: what the rest is, and the way to it.
class _Offer extends StatelessWidget {
  const _Offer({required this.app, required this.session});

  final AppState app;
  final ListenSession session;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    return Container(
      key: const ValueKey('listen-offer'),
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
            l.listenOfferTitle,
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
            l.listenOfferLine,
            style: AppText.body(
              size: 14,
              height: 1.35,
              color: p.ink.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          ChunkyButton(
            key: const ValueKey('listen-plus'),
            label: plusActionOf(context),
            fill: p.inverse,
            ink: p.onInverse,
            height: 50,
            onPressed: () => _openPlus(context, app, session),
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
            color: p.ink.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: _Pill(label: action, onTap: onAction),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap});

  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return Semantics(
      button: true,
      child: GestureDetector(
        key: const ValueKey('listen-again'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ink.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: AppText.body(
              size: 13.5,
              weight: FontWeight.w700,
              color: ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// A round button: play and pause filled, the rest on the faint ground.
class _Round extends StatelessWidget {
  const _Round({
    super.key,
    required this.icon,
    required this.label,
    required this.size,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
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
            child: Icon(icon, size: size * 0.46, color: ink),
          ),
        ),
      ),
    );
  }
}
