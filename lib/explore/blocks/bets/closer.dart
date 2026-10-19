/// Closer, closer (139d): three steps of more or less, each told right or
/// wrong at once, the stretch the answer is in halving every time.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../theme.dart';
import '../../explore_block.dart';
import 'answers.dart';
import 'bet_host.dart';
import 'bets_day.dart';
import 'block.dart';
import 'deal.dart';
import 'parts.dart';

/// The block: a row of shares to close in on.
class CloserBlock extends BetBlock {
  const CloserBlock();

  @override
  String get name => 'bets-closer';

  @override
  int get defaultLimit => 3;

  /// Any share. The steps are a game with the card, not its answer: each
  /// is told right or wrong at once, and the stretch that halves is the
  /// answer's, not the reader's.
  @override
  bool fits(BetAnswer a) => a.share;

  /// How many steps a game takes: `steps`, 2 to 5, three by default.
  static int stepsOf(BetSection shelf) =>
      shelf.count('steps', 3, min: 2, max: 5);

  @override
  String title(AppLocalizations l, BetSection shelf) => l.betsCloserTitle;

  @override
  String line(AppLocalizations l, BetSection shelf) =>
      l.betsCloserLine('${stepsOf(shelf)}');

  @override
  Widget body(
    BuildContext context,
    ExploreHost host,
    BetSection shelf,
    List<BetAnswer> cards,
  ) {
    final BetTileSize size = sizeOf(shelf);
    return BetTiles(
      size: size,
      count: cards.length,
      onSeen: (i) => host.seen(shelf.section, cards[i].pill),
      builder: (context, i) => CloserTile(
        key: ValueKey('bets-closer-${cards[i].pill.id}'),
        host: host,
        shelf: shelf,
        answer: cards[i],
        cards: cards,
        size: size,
        steps: stepsOf(shelf),
      ),
    );
  }
}

/// Where a game of more or less has got to, from the taps so far.
@immutable
class CloserGame {
  const CloserGame._({
    required this.lo,
    required this.hi,
    required this.right,
    required this.taken,
    required this.done,
    this.last,
    this.exact = false,
  });

  /// The stretch the answer is in.
  final double lo;
  final double hi;

  /// The steps said right, and taken.
  final int right;
  final int taken;
  final bool done;

  /// The last step: what was said, what is so, and of what.
  final (bool more, bool truthMore, double at)? last;

  /// Whether the answer sat exactly on the last step's line, which ends
  /// the game: there is nothing left to close in on.
  final bool exact;

  /// The midpoint asked about next.
  double get middle => (lo + hi) / 2;

  /// The game after [taps], `M` for more and `L` for less, on [value] in
  /// [steps] steps.
  factory CloserGame.of(String taps, double value, int steps) {
    double lo = 0, hi = 100;
    int right = 0, taken = 0;
    (bool, bool, double)? last;
    bool exact = false;
    for (final String t in taps.split('')) {
      if (t != 'M' && t != 'L') continue;
      if (taken >= steps || exact) break;
      final double m = (lo + hi) / 2;
      final bool more = t == 'M';
      taken++;
      if ((value - m).abs() < 1e-9) {
        // On the line itself: neither side is wrong, and the game is over.
        right++;
        exact = true;
        last = (more, more, m);
        lo = hi = value;
        break;
      }
      final bool truthMore = value > m;
      if (more == truthMore) right++;
      last = (more, truthMore, m);
      if (truthMore) {
        lo = m;
      } else {
        hi = m;
      }
    }
    return CloserGame._(
      lo: lo,
      hi: hi,
      right: right,
      taken: taken,
      done: exact || taken >= steps,
      last: last,
      exact: exact,
    );
  }
}

/// One share to close in on.
class CloserTile extends StatelessWidget {
  const CloserTile({
    super.key,
    required this.host,
    required this.shelf,
    required this.answer,
    required this.cards,
    required this.size,
    required this.steps,
  });

  final ExploreHost host;
  final BetSection shelf;
  final BetAnswer answer;
  final List<BetAnswer> cards;
  final BetTileSize size;
  final int steps;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pill = answer.pill;
    final BetsDay day = BetsDay.instance;
    final BetInk ink = BetInk.of(context, pill, shelf.tone());
    final BetNumbers n = BetNumbers(
      Localizations.localeOf(context).languageCode,
    );
    final String key = BetsDay.draftKey('closer', pill.id);
    final Bet? bet = day.betOn('closer', pill.id);
    final Object? kept = day.draft(key);
    final String taps = bet?.said ?? (kept is String ? kept : '');
    final CloserGame game = CloserGame.of(taps, answer.value, steps);
    final bool done = bet != null || game.done;
    final String said = n.percent(answer.value);

    Future<void> tap(bool more) async {
      BetFeel.tick();
      final String next = '$taps${more ? 'M' : 'L'}';
      final CloserGame after = CloserGame.of(next, answer.value, steps);
      if (!after.done) {
        day.keepDraft(key, next);
        return;
      }
      await layBet(
        host,
        shelf.section,
        Bet(
          kind: 'closer',
          section: shelf.id,
          pill: pill.id,
          said: next,
          right: after.right == after.taken,
          facts: {'right': after.right, 'steps': after.taken},
          at: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      revealCard(host, shelf.section, pill);
    }

    String message(CloserGame g) {
      if (g.done) {
        return g.exact
            ? '${l.betsCloserExact(said)} ${l.betsScoreSentence(g.right, g.taken)}'
            : l.betsCloserDone(said, g.right, g.taken);
      }
      final last = g.last;
      if (last == null) return l.betsCloserStart('$steps');
      final (bool more, bool truthMore, double at) = last;
      final String v = n.percent(at);
      return more == truthMore
          ? (truthMore ? l.betsCloserYesMore(v) : l.betsCloserYesLess(v))
          : (truthMore ? l.betsCloserNoMore(v) : l.betsCloserNoLess(v));
    }

    Widget ask({bool ghost = false}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                l.betsMoreOrLess(n.percent(game.middle)),
                style: AppText.display(
                  size: 17,
                  weight: FontWeight.w600,
                  height: 1.2,
                  spacing: -0.3,
                  color: ink.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            BetKicker(
              l.betsStepOf(math.min(game.taken + 1, steps), steps),
              color: ink.sub,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final bool more in const [false, true]) ...[
              if (more) const SizedBox(width: 8),
              Expanded(
                child: BetChip(
                  key: ghost
                      ? null
                      : ValueKey(
                          'bets-closer-${pill.id}-${more ? 'more' : 'less'}',
                        ),
                  label: more ? l.betsMore : l.betsLess,
                  icon: more
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  ink: ink,
                  height: 42,
                  radius: 12,
                  size: 13.5,
                  onTap: ghost ? null : () => tap(more),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        BetVerdict(
          message(game),
          key: ghost ? null : ValueKey('bets-closer-said-${pill.id}'),
          ink: ink,
        ),
      ],
    );

    Widget over({bool ghost = false, CloserGame? as}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BetVerdict(
          message(as ?? game),
          key: ghost ? null : ValueKey('bets-closer-said-${pill.id}'),
          ink: ink,
        ),
        BetWhy(pill, ink: ink),
      ],
    );

    Widget track() {
      final TextStyle tick = AppText.body(
        size: 10,
        weight: FontWeight.w600,
        height: 1,
        color: ink.sub,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: game.lo, end: game.lo),
            duration: betMotion(context, 400),
            curve: Curves.easeOutCubic,
            builder: (context, lo, _) => TweenAnimationBuilder<double>(
              tween: Tween(begin: game.hi, end: game.hi),
              duration: betMotion(context, 400),
              curve: Curves.easeOutCubic,
              builder: (context, hi, _) => SizedBox(
                height: 18,
                child: CustomPaint(
                  painter: _Halves(
                    ink: ink,
                    lo: lo,
                    hi: hi,
                    answer: done ? answer.value : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(n.percent(0), style: tick),
              Text(n.percent(50), style: tick),
              Text(n.percent(100), style: tick),
            ],
          ),
        ],
      );
    }

    Widget whole(Widget foot) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [track(), const SizedBox(height: 14), foot],
    );

    // The longest the game's end can read: every step said wrong.
    final CloserGame worst = CloserGame.of(
      List.filled(steps, 'M').join(),
      answer.value < 50 ? 0 : 100,
      steps,
    );
    return BetFrame(
      pill: pill,
      ink: ink,
      size: size,
      read: host.isRead(pill),
      onOpen: done
          ? () =>
                host.open(shelf.section, [for (final c in cards) c.pill], pill)
          : null,
      game: BetRoom(
        keep: size.inRow,
        ghosts: [
          if (!done) ...[
            whole(ask(ghost: true)),
            whole(over(ghost: true, as: worst)),
          ],
        ],
        child: whole(done ? over() : ask()),
      ),
    );
  }
}

/// The track a game of more or less is played on: the rail, the stretch
/// the answer is still in, and at the end the answer itself.
class _Halves extends CustomPainter {
  const _Halves({
    required this.ink,
    required this.lo,
    required this.hi,
    required this.answer,
  });

  final BetInk ink;
  final double lo;
  final double hi;
  final double? answer;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    canvas.drawRRect(
      RRect.fromLTRBR(0, 6, w, 12, const Radius.circular(9)),
      Paint()..color = ink.fill,
    );
    final double left = w * lo / 100;
    final double right = math.max(left + 4, w * hi / 100);
    canvas.drawRRect(
      RRect.fromLTRBR(left, 2, right, 16, const Radius.circular(7)),
      Paint()..color = ink.hair,
    );
    final double? a = answer;
    if (a != null) {
      final double x = (w * a / 100).clamp(2, w - 2);
      canvas.drawRRect(
        RRect.fromLTRBR(x - 2, 0, x + 2, 18, const Radius.circular(2)),
        Paint()..color = ink.ink,
      );
    }
  }

  @override
  bool shouldRepaint(_Halves old) =>
      old.lo != lo ||
      old.hi != hi ||
      old.answer != answer ||
      old.ink.ink != ink.ink;
}
