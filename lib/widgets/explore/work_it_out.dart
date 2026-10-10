import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../analytics.dart';
import '../../data/explore_mix.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../state/explore_play.dart';
import '../../theme.dart';
import 'parts.dart';

/// Every card on the row is this size, whatever its game: a row of cards of
/// six heights read as six shelves run together. Tall enough for the most a
/// card ever holds, a range bet laid with its verdict and its why under a
/// long question; anything less leaves the question the room.
const double kWorkCardWidth = 300;
const double kWorkCardHeight = 336;

/// Work it out — every way the canvas found to play a number, on one row.
///
/// 133b's three amounts to pick from, 138d's slider set and then checked,
/// 139d's three steps of more or less, 139c's two figures and which is
/// bigger, 139a's range that pays more the narrower it is, 139b's stake from
/// a hundred points a day. They were six rows behind a row of chips, and a
/// reader had to choose a way before playing any of them. Now they are one
/// row, two of each, laid out in an order drawn for the day: every card the
/// same size, and each saying in its corner which game it is, so the reader
/// knows what to do with it before reading a word of its question. They are
/// one skill, putting a number on something before being told it.
///
/// Every number is a card's own answer. A pick or a stake is the card
/// answered, and is recorded as the card's answer like one given on Today;
/// a guess on a slider or a range is a game with the card, kept for the day.
class WorkItOut extends StatelessWidget {
  const WorkItOut({
    super.key,
    required this.deal,
    required this.isRead,
    required this.onOpen,
    required this.answerOf,
    required this.onCommit,
    this.onShown,
  });

  final WorkItOutDeal deal;
  final bool Function(Pill) isRead;
  final void Function(List<Pill>, Pill) onOpen;
  final String? Function(Pill) answerOf;
  final void Function(Pill, String) onCommit;
  final ValueChanged<Pill>? onShown;

  /// The cards one place on the row holds: two for a comparison, one for
  /// everything else.
  List<Pill> _at(WorkKind kind, int i) => switch (kind) {
    WorkKind.pick => [deal.pick[i]],
    WorkKind.slide => [deal.slide[i].pill],
    WorkKind.closer => [deal.closer[i].pill],
    WorkKind.bigger => [deal.bigger[i].$1.pill, deal.bigger[i].$2.pill],
    WorkKind.range => [deal.range[i].pill],
    WorkKind.stake => [deal.stake[i]],
  };

  @override
  Widget build(BuildContext context) {
    // What the viewer pages through when a card on the row is opened: the
    // row, in its order.
    final List<Pill> shelf = [
      for (final (kind, i) in deal.row) ..._at(kind, i),
    ];
    void open(Pill p) => onOpen(shelf, p);
    return ListenableBuilder(
      listenable: ExplorePlay.instance,
      builder: (context, _) => SideRow(
        height: kWorkCardHeight + 4,
        count: deal.row.length,
        itemBuilder: (context, at) {
          final (WorkKind kind, int i) = deal.row[at];
          for (final p in _at(kind, i)) {
            onShown?.call(p);
          }
          return KeyedSubtree(
            key: ValueKey('work-${kind.name}-$i'),
            child: switch (kind) {
              WorkKind.pick => _PickCard(
                pill: deal.pick[i],
                read: isRead(deal.pick[i]),
                answer: answerOf(deal.pick[i]),
                onOpen: () => open(deal.pick[i]),
                onCommit: (said) => onCommit(deal.pick[i], said),
              ),
              WorkKind.slide => _SlideCard(
                card: deal.slide[i],
                read: isRead(deal.slide[i].pill),
                onOpen: () => open(deal.slide[i].pill),
              ),
              WorkKind.closer => _CloserCard(
                card: deal.closer[i],
                read: isRead(deal.closer[i].pill),
                onOpen: () => open(deal.closer[i].pill),
              ),
              WorkKind.bigger => _BiggerCard(
                a: deal.bigger[i].$1,
                b: deal.bigger[i].$2,
                onOpen: open,
              ),
              WorkKind.range => _RangeCard(
                card: deal.range[i],
                read: isRead(deal.range[i].pill),
                onOpen: () => open(deal.range[i].pill),
              ),
              WorkKind.stake => _StakeCard(
                pill: deal.stake[i],
                read: isRead(deal.stake[i]),
                onOpen: () => open(deal.stake[i]),
                onCommit: onCommit,
                answered: answerOf(deal.stake[i]) != null,
              ),
            },
          );
        },
      ),
    );
  }
}

/// The day's points, level with the shelf's name: what a bet is paid from.
class WorkWallet extends StatelessWidget {
  const WorkWallet({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ExplorePlay.instance,
      builder: (context, _) => Container(
        key: const ValueKey('work-wallet'),
        height: 26,
        padding: const EdgeInsets.fromLTRB(7, 0, 10, 0),
        decoration: BoxDecoration(
          color: context.p.inverse,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.adjust_rounded, size: 15, color: context.p.onInverse),
            const SizedBox(width: 5),
            Text(
              '${ExplorePlay.instance.points}',
              style: AppText.body(
                size: 12,
                weight: FontWeight.w700,
                height: 1,
                color: context.p.onInverse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A share as it reads on the slider: whole, or to one place.
String _pct(num v) {
  final double d = v.toDouble();
  if (d == d.roundToDouble()) return '${d.round()}%';
  return '${d.toStringAsFixed(1)}%';
}

/// The game a card is, as its corner says it.
String _gameOf(BuildContext context, WorkKind kind) {
  final l = context.l10n;
  return switch (kind) {
    WorkKind.pick => l.modePick,
    WorkKind.slide => l.modeSlide,
    WorkKind.closer => l.modeCloser,
    WorkKind.bigger => l.modeBigger,
    WorkKind.range => l.modeRange,
    WorkKind.stake => l.modeStake,
  };
}

/// The head of a card on this row: its subject on the left, as on every
/// card, and in the corner, filled in the card's ink, the game it is.
class _Head extends StatelessWidget {
  const _Head({required this.pill, required this.kind, this.read = false});

  final Pill pill;
  final WorkKind kind;
  final bool read;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CardHead(
            pill: pill,
            trailing: read ? ReadMark(pill: pill) : null,
          ),
        ),
        const SizedBox(width: 8),
        // The game wins the room: in a long language the subject's name
        // gives way first, and the mark beside it still says the subject.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 196),
          child: Container(
            key: ValueKey('work-game-${pill.id}'),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: pill.ink,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              upper(context, _gameOf(context, kind)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(
                size: 9,
                weight: FontWeight.w700,
                spacing: 1,
                height: 1,
                color: pill.color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A card of this row: the size every card on it is, the colour of its
/// subject, the head and the question, and under them the game.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.pill,
    required this.kind,
    required this.read,
    required this.onOpen,
    required this.game,
  });

  final Pill pill;
  final WorkKind kind;
  final bool read;
  final VoidCallback onOpen;

  /// What is played: the options, the slider, the steps, the stake.
  final Widget game;

  @override
  Widget build(BuildContext context) {
    return CardTap(
      pill: pill,
      onTap: onOpen,
      child: Container(
        width: kWorkCardWidth,
        height: kWorkCardHeight,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: pill.color,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Head(pill: pill, kind: kind, read: read),
            // The question takes what the game leaves: every question on
            // the row starts at the same height, and every game sits on
            // the card's foot.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: CardQuestion(
                  text: pill.question,
                  color: pill.ink,
                  min: 11,
                  max: 19,
                ),
              ),
            ),
            game,
          ],
        ),
      ),
    );
  }
}

/// A slider across the card: the track, what is set, the thumb, and once it
/// is checked where the answer was.
class _Track extends StatelessWidget {
  const _Track({
    required this.pill,
    required this.value,
    required this.onChanged,
    this.answer,
    this.band,
  });

  final Pill pill;
  final double value;
  final ValueChanged<double>? onChanged;
  final double? answer;

  /// For a range: how far either side of the thumb it reaches.
  final double? band;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final double w = box.maxWidth - 22;
        double at(double dx) =>
            ((dx - 11) / w * 100).clamp(0, 100).roundToDouble();
        final double x = 11 + w * value / 100;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onChanged == null
              ? null
              : (d) => onChanged!(at(d.localPosition.dx)),
          onHorizontalDragStart: onChanged == null
              ? null
              : (d) => onChanged!(at(d.localPosition.dx)),
          onHorizontalDragUpdate: onChanged == null
              ? null
              : (d) => onChanged!(at(d.localPosition.dx)),
          child: SizedBox(
            height: 28,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 11,
                  height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: fillOn(pill),
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                if (band == null)
                  Positioned(
                    left: 0,
                    top: 11,
                    height: 6,
                    width: x,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: pill.ink,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  )
                else
                  Positioned(
                    left: 11 + w * ((value - band!).clamp(0, 100)) / 100,
                    width:
                        w *
                        (((value + band!).clamp(0, 100) -
                                (value - band!).clamp(0, 100)) /
                            100),
                    top: 6,
                    height: 16,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: hairOn(pill),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                if (answer != null)
                  Positioned(
                    left: 11 + w * answer! / 100 - 2,
                    top: 0,
                    width: 4,
                    height: 28,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: pill.ink,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Positioned(
                  left: x - 11,
                  top: 3,
                  width: 22,
                  height: 22,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pill.color,
                      border: Border.all(color: pill.ink, width: 3),
                    ),
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

/// The figure set so far, large, and what to do with it beside it.
class _Figure extends StatelessWidget {
  const _Figure({required this.pill, required this.value, required this.side});

  final Pill pill;
  final String value;
  final Widget side;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: AppText.display(
            size: 34,
            weight: FontWeight.w600,
            height: 1,
            spacing: -1,
            color: pill.ink,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Align(alignment: Alignment.centerRight, child: side),
        ),
      ],
    );
  }
}

/// What a game came to, in a sentence on the card.
class _Verdict extends StatelessWidget {
  const _Verdict(this.text, {required this.pill, super.key});

  final String text;
  final Pill pill;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: AppText.body(
        size: 13,
        weight: FontWeight.w600,
        height: 1.35,
        color: pill.ink,
      ),
    );
  }
}

// ── Pick one (133b) ──────────────────────────────────────────────────────

class _PickCard extends StatelessWidget {
  const _PickCard({
    required this.pill,
    required this.read,
    required this.answer,
    required this.onOpen,
    required this.onCommit,
  });

  final Pill pill;
  final bool read;

  /// What the reader answered on the card, if they have.
  final String? answer;
  final VoidCallback onOpen;
  final ValueChanged<String> onCommit;

  @override
  Widget build(BuildContext context) {
    final PickOne c = pill.challenge as PickOne;
    final int? said = int.tryParse(answer ?? '');
    final bool done = said != null;
    return _Frame(
      pill: pill,
      kind: WorkKind.pick,
      read: read,
      onOpen: onOpen,
      game: Column(
        children: [
          for (int k = 0; k < c.options.length; k++) ...[
            if (k > 0) const SizedBox(height: 6),
            _option(k, c, said, done),
          ],
        ],
      ),
    );
  }

  Widget _option(int k, PickOne c, int? said, bool done) {
    final Pill p = pill;
    final bool right = k == c.correct;
    final bool lit = done && right;
    final bool wrongPick = done && k == said && !right;
    return Semantics(
      key: ValueKey('pick-${p.id}-$k'),
      button: !done,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: done ? null : () => onCommit('$k'),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: done && !lit && !wrongPick ? 0.4 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: lit ? p.ink : fillOn(p),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    c.options[k],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppText.body(
                          size: 12.5,
                          weight: FontWeight.w700,
                          height: 1,
                          color: lit ? p.color : p.ink,
                        ).copyWith(
                          decoration: wrongPick
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: p.ink,
                        ),
                  ),
                ),
                if (lit) Icon(Icons.check_rounded, size: 16, color: p.color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Move it, then check (138d) ───────────────────────────────────────────

class _SlideCard extends StatelessWidget {
  const _SlideCard({
    required this.card,
    required this.read,
    required this.onOpen,
  });

  final PercentCard card;
  final bool read;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final Pill p = card.pill;
    final play = ExplorePlay.instance;
    final String key = 'slide:${p.id}';
    final Map kept = play[key] is Map ? play[key] as Map : const {};
    final double v = (kept['v'] as num?)?.toDouble() ?? 50;
    final bool checked = kept['ck'] == true;
    final int off = (v - card.value).abs().round();
    final l = context.l10n;
    return _Frame(
      pill: p,
      kind: WorkKind.slide,
      read: read,
      onOpen: onOpen,
      game: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Figure(
            pill: p,
            value: _pct(v),
            side: Text(
              upper(context, checked ? l.answerIs(card.said) : l.dragToSet),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(
                size: 9,
                weight: FontWeight.w700,
                spacing: 1.2,
                color: checked ? p.ink : subOn(p),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Track(
            pill: p,
            value: v,
            answer: checked ? card.value : null,
            onChanged: checked
                ? null
                : (x) => play.put(key, {'v': x, 'ck': false}),
          ),
          const SizedBox(height: 12),
          if (checked) ...[
            _Verdict(
              '${l.itIs(inSentence(card.said))} ${l.slideOff(off)}',
              key: ValueKey('slide-said-${p.id}'),
              pill: p,
            ),
            _Why(p),
          ] else
            FlatButton(
              key: ValueKey('slide-check-${p.id}'),
              label: l.check,
              background: p.ink,
              foreground: p.color,
              onTap: () {
                play.put(key, {'v': v, 'ck': true});
                Analytics.capture('explore slide checked', {
                  'pill_id': p.id,
                  'off': off,
                });
              },
            ),
        ],
      ),
    );
  }
}

// ── Closer, closer (139d) ────────────────────────────────────────────────

class _CloserCard extends StatelessWidget {
  const _CloserCard({
    required this.card,
    required this.read,
    required this.onOpen,
  });

  final PercentCard card;
  final bool read;
  final VoidCallback onOpen;

  static const int steps = 3;

  @override
  Widget build(BuildContext context) {
    final Pill p = card.pill;
    final play = ExplorePlay.instance;
    final String key = 'closer:${p.id}';
    final String taps = play[key] is String ? play[key] as String : '';
    final l = context.l10n;
    double lo = 0, hi = 100;
    int right = 0;
    (bool more, bool truthMore, double at)? last;
    for (final t in taps.split('')) {
      if (t.isEmpty) continue;
      final double m = (lo + hi) / 2;
      final bool truthMore = card.value > m;
      final bool more = t == 'M';
      if (more == truthMore) right++;
      last = (more, truthMore, m);
      if (truthMore) {
        lo = m;
      } else {
        hi = m;
      }
    }
    final bool done = taps.length >= steps;
    final double m = (lo + hi) / 2;
    final String message;
    if (done) {
      message = l.closerDone(inSentence(card.said), right, steps);
    } else if (last == null) {
      message = l.closerStart;
    } else {
      final (bool more, bool truthMore, double at) = last;
      final String v = _pct(at);
      message = more == truthMore
          ? (truthMore ? l.closerYesMore(v) : l.closerYesLess(v))
          : (truthMore ? l.closerNoMore(v) : l.closerNoLess(v));
    }

    Widget pick(bool more) => Expanded(
      child: FlatButton(
        key: ValueKey('closer-${p.id}-${more ? 'more' : 'less'}'),
        label: more ? l.more : l.less,
        background: fillOn(p),
        foreground: p.ink,
        height: 40,
        radius: 12,
        size: 13.5,
        expand: true,
        icon: Icon(
          more ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 16,
          color: p.ink,
        ),
        onTap: () => play.put(key, '$taps${more ? 'M' : 'L'}'),
      ),
    );

    final TextStyle tick = AppText.body(
      size: 10,
      weight: FontWeight.w600,
      height: 1,
      color: subOn(p),
    );
    return _Frame(
      pill: p,
      kind: WorkKind.closer,
      read: read,
      onOpen: onOpen,
      game: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final double w = box.maxWidth;
              return SizedBox(
                height: 18,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 6,
                      height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: fillOn(p),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      left: w * lo / 100,
                      width: math.max(4, w * (hi - lo) / 100),
                      top: 2,
                      height: 14,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: hairOn(p),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                    if (done)
                      Positioned(
                        left: (w * card.value / 100 - 2).clamp(0, w - 4),
                        top: 0,
                        width: 4,
                        height: 18,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: p.ink,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%', style: tick),
              Text('50%', style: tick),
              Text('100%', style: tick),
            ],
          ),
          const SizedBox(height: 12),
          if (!done) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    l.moreOrLess(_pct(m)),
                    style: AppText.display(
                      size: 17,
                      weight: FontWeight.w600,
                      height: 1.2,
                      spacing: -0.3,
                      color: p.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  upper(context, l.stepOf(taps.length + 1, steps)),
                  style: AppText.label(
                    size: 9,
                    weight: FontWeight.w700,
                    spacing: 1.2,
                    color: subOn(p),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(children: [pick(false), const SizedBox(width: 8), pick(true)]),
            const SizedBox(height: 10),
          ],
          _Verdict(message, key: ValueKey('closer-said-${p.id}'), pill: p),
          if (done) _Why(p),
        ],
      ),
    );
  }
}

// ── Which is bigger? (139c) ──────────────────────────────────────────────

/// Two cards' figures on one card, each half in its own subject's colour,
/// and a tap on the half that is bigger. Once picked, both figures show and
/// each half opens its own card.
class _BiggerCard extends StatelessWidget {
  const _BiggerCard({required this.a, required this.b, required this.onOpen});

  final PercentCard a;
  final PercentCard b;
  final ValueChanged<Pill> onOpen;

  @override
  Widget build(BuildContext context) {
    final play = ExplorePlay.instance;
    final String key = 'bigger:${a.pill.id}:${b.pill.id}';
    final Object? kept = play[key];
    final int? picked = kept is int ? kept : null;
    final int bigger = a.value > b.value ? 0 : 1;
    final l = context.l10n;

    Widget half(int j, PercentCard c) {
      final Pill p = c.pill;
      final bool done = picked != null;
      final bool big = done && j == bigger;
      final String tag = !done
          ? l.tapIfBigger
          : big
          ? (picked == j ? l.biggerYouGotIt : l.biggerLabel)
          : (picked == j ? l.yourPick : '');
      return Expanded(
        child: GestureDetector(
          key: ValueKey('bigger-${p.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: done
              ? () => onOpen(p)
              : () {
                  play.put(key, j);
                  Analytics.capture('explore bigger picked', {
                    'right': j == bigger,
                  });
                },
          child: ColoredBox(
            color: p.color,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                j == 0 ? 18 : 14,
                18,
                j == 0 ? 14 : 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (j == 0)
                    _Head(pill: p, kind: WorkKind.bigger)
                  else
                    CardHead(pill: p),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 9, bottom: 8),
                      child: CardQuestion(
                        text: p.question,
                        color: p.ink,
                        min: 10.5,
                        max: 16,
                      ),
                    ),
                  ),
                  // The figure, then what it came to: kept to the left, so
                  // the seam's right end is free for the "or" between them.
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: done && !big ? 0.55 : 1,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          done ? _pct(c.value) : '?',
                          style: AppText.display(
                            size: 28,
                            weight: FontWeight.w600,
                            height: 1,
                            spacing: -0.8,
                            color: p.ink,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (big) ...[
                          Icon(Icons.check_rounded, size: 16, color: p.ink),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            upper(context, tag),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label(
                              size: 9,
                              weight: FontWeight.w700,
                              spacing: 1.2,
                              color: big ? p.ink : subOn(p),
                            ),
                          ),
                        ),
                        // Room for the "or" on the seam.
                        const SizedBox(width: 40),
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

    return SizedBox(
      width: kWorkCardWidth,
      height: kWorkCardHeight,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(children: [half(0, a), half(1, b)]),
          ),
          Positioned(
            right: 18,
            top: kWorkCardHeight / 2 - 15,
            child: IgnorePointer(
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.p.surface,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  l.sideOr,
                  style: AppText.display(
                    size: 12,
                    weight: FontWeight.w600,
                    height: 1,
                    color: context.p.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bet a range (139a) ───────────────────────────────────────────────────

/// How wide a range is, either side of the guess, and what it pays.
const List<(int, int)> _widths = [(5, 30), (10, 20), (20, 10)];

class _RangeCard extends StatelessWidget {
  const _RangeCard({
    required this.card,
    required this.read,
    required this.onOpen,
  });

  final PercentCard card;
  final bool read;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final Pill p = card.pill;
    final play = ExplorePlay.instance;
    final String key = 'range:${p.id}';
    final Map kept = play[key] is Map ? play[key] as Map : const {};
    final double g = (kept['g'] as num?)?.toDouble() ?? 50;
    final int wi = (kept['w'] as num?)?.toInt() ?? 1;
    final bool locked = kept['lk'] == true;
    final (int half, int pays) = _widths[wi];
    final double lo = math.max(0, g - half).toDouble();
    final double hi = math.min(100, g + half).toDouble();
    final bool hit = card.value >= lo && card.value <= hi;
    final l = context.l10n;

    void keep({double? guess, int? width, bool lock = false}) =>
        play.put(key, {'g': guess ?? g, 'w': width ?? wi, 'lk': lock});

    return _Frame(
      pill: p,
      kind: WorkKind.range,
      read: read,
      onOpen: onOpen,
      game: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Figure(
            pill: p,
            value: _pct(g),
            side: Text(
              '${lo.round()}–${hi.round()}%',
              style: AppText.body(
                size: 11,
                weight: FontWeight.w700,
                height: 1,
                color: p.ink,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Track(
            pill: p,
            value: g,
            band: half.toDouble(),
            answer: locked ? card.value : null,
            onChanged: locked ? null : (x) => keep(guess: x),
          ),
          const SizedBox(height: 12),
          // Once the bet is laid the widths have done their work: the band
          // on the track still shows the one chosen, and the room goes to
          // what the bet came to and why.
          if (locked) ...[
            _Verdict(
              hit
                  ? l.inRange(pays, inSentence(card.said))
                  : l.missedRange(inSentence(card.said)),
              key: ValueKey('range-said-${p.id}'),
              pill: p,
            ),
            _Why(p),
          ] else ...[
            Row(
              children: [
                for (int j = 0; j < _widths.length; j++) ...[
                  if (j > 0) const SizedBox(width: 6),
                  Expanded(
                    child: FlatButton(
                      key: ValueKey('range-${p.id}-$j'),
                      label: l.rangeWidth(_widths[j].$1, _widths[j].$2),
                      background: j == wi ? p.ink : fillOn(p),
                      foreground: j == wi ? p.color : p.ink,
                      height: 32,
                      radius: 10,
                      size: 11,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      expand: true,
                      onTap: () => keep(width: j),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            FlatButton(
              key: ValueKey('range-bet-${p.id}'),
              label: l.betWord,
              background: p.ink,
              foreground: p.color,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              onTap: () {
                keep(lock: true);
                if (hit) play.addPoints(pays);
                Analytics.capture('explore range bet', {
                  'pill_id': p.id,
                  'width': half,
                  'hit': hit,
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ── Place your bet (139b) ────────────────────────────────────────────────

const List<int> _stakes = [10, 20, 30];

class _StakeCard extends StatelessWidget {
  const _StakeCard({
    required this.pill,
    required this.read,
    required this.onOpen,
    required this.onCommit,
    required this.answered,
  });

  final Pill pill;
  final bool read;
  final VoidCallback onOpen;
  final void Function(Pill, String) onCommit;

  /// Answered already, somewhere else: there is nothing left to bet on.
  final bool answered;

  @override
  Widget build(BuildContext context) {
    final Pill p = pill;
    final PickOne c = p.challenge as PickOne;
    final play = ExplorePlay.instance;
    final String key = 'stake:${p.id}';
    final Map kept = play[key] is Map ? play[key] as Map : const {};
    final int? o = (kept['o'] as num?)?.toInt();
    final int k = (kept['k'] as num?)?.toInt() ?? 0;
    final bool done = kept['dn'] == true;
    final bool win = done && o == c.correct;
    final int wallet = play.points;
    final bool canBet = !done && o != null && _stakes[k] <= wallet;
    final l = context.l10n;

    void keep({int? option, int? stake, bool bet = false}) =>
        play.put(key, {'o': option ?? o, 'k': stake ?? k, 'dn': bet});

    return _Frame(
      pill: p,
      kind: WorkKind.stake,
      read: read,
      onOpen: onOpen,
      game: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (int j = 0; j < c.options.length; j++) ...[
                if (j > 0) const SizedBox(width: 6),
                Expanded(child: _stakeOption(context, j, c, o, done)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (done) ...[
            _Verdict(
              '${win ? l.youWin(_stakes[k]) : l.youLose(_stakes[k])} '
              '${l.theAnswer(c.options[c.correct])}',
              key: ValueKey('stake-said-${p.id}'),
              pill: p,
            ),
            _Why(p),
          ] else
            Row(
              children: [
                Text(
                  upper(context, l.stakeLabel),
                  style: AppText.label(
                    size: 9,
                    weight: FontWeight.w700,
                    spacing: 1.2,
                    color: subOn(p),
                  ),
                ),
                const SizedBox(width: 8),
                for (int j = 0; j < _stakes.length; j++) ...[
                  if (j > 0) const SizedBox(width: 5),
                  Opacity(
                    opacity: _stakes[j] > wallet && j != k ? 0.35 : 1,
                    child: FlatButton(
                      key: ValueKey('stake-${p.id}-k$j'),
                      label: '${_stakes[j]}',
                      background: j == k ? p.ink : fillOn(p),
                      foreground: j == k ? p.color : p.ink,
                      height: 30,
                      size: 12,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      onTap: answered || _stakes[j] > wallet
                          ? null
                          : () => keep(stake: j),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                // The bet takes what room the stakes leave, and keeps to the
                // right of it: on a narrow card it gives way before the row
                // runs off the edge.
                if (canBet && !answered)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FlatButton(
                        key: ValueKey('stake-bet-${p.id}'),
                        label: l.betN(_stakes[k]),
                        background: p.ink,
                        foreground: p.color,
                        height: 34,
                        size: 12.5,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        onTap: () {
                          final bool right = o == c.correct;
                          keep(bet: true);
                          play.addPoints(right ? _stakes[k] : -_stakes[k]);
                          onCommit(p, '$o');
                          Analytics.capture('explore stake bet', {
                            'pill_id': p.id,
                            'stake': _stakes[k],
                            'won': right,
                          });
                        },
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      answered
                          ? l.answeredAlready
                          : o == null
                          ? l.pickOneFirst
                          : l.notEnoughPoints,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      style: AppText.body(
                        size: 11.5,
                        weight: FontWeight.w600,
                        height: 1.2,
                        color: subOn(p),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _stakeOption(
    BuildContext context,
    int j,
    PickOne c,
    int? o,
    bool done,
  ) {
    final Pill p = pill;
    final bool on = done ? j == c.correct : j == o;
    final bool lost = done && j == o && j != c.correct;
    return GestureDetector(
      key: ValueKey('stake-${p.id}-o$j'),
      behavior: HitTestBehavior.opaque,
      onTap: done || answered
          ? null
          : () => ExplorePlay.instance.put('stake:${p.id}', {
              'o': j,
              'k':
                  ((ExplorePlay.instance['stake:${p.id}'] as Map?)?['k']
                          as num?)
                      ?.toInt() ??
                  0,
              'dn': false,
            }),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: done && !on && !lost ? 0.4 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? p.ink : (done ? p.ink.withValues(alpha: 0) : fillOn(p)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: lost ? p.ink : p.ink.withValues(alpha: 0),
              width: 2,
            ),
          ),
          child: Text(
            c.options[j],
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              size: 12,
              weight: FontWeight.w600,
              height: 1.1,
              color: on ? p.color : p.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// The first lines of the card's answer, under a verdict: a number checked
/// is a number explained, and the rest of the why is a tap away.
class _Why extends StatelessWidget {
  const _Why(this.pill);

  final Pill pill;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        firstLines(pill.answer, max: 150),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: AppText.body(
          size: 12,
          weight: FontWeight.w500,
          height: 1.38,
          color: pill.ink.withValues(alpha: 0.78),
        ),
      ),
    );
  }
}
