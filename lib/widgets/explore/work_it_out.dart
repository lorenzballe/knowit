import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../analytics.dart';
import '../../data/explore_mix.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../state/explore_play.dart';
import '../../theme.dart';
import 'parts.dart';

/// Work it out — every way the canvas found to play a number, on one shelf.
///
/// 133b's three amounts to pick from, 138d's slider set and then checked,
/// 139d's three steps of more or less, 139c's two figures and which is
/// bigger, 139a's range that pays more the narrower it is, 139b's stake from
/// a hundred points a day. Six ways, one shelf, a row of chips to move
/// between them: they are one skill, putting a number on something before
/// being told it, and six shelves of it would have buried everything under
/// them.
///
/// Every number is a card's own answer. A pick or a stake is the card
/// answered, and is recorded as the card's answer like one given on Today;
/// a guess on a slider or a range is a game with the card, kept for the day.
class WorkItOut extends StatefulWidget {
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

  @override
  State<WorkItOut> createState() => _WorkItOutState();
}

enum _Mode { pick, slide, closer, bigger, range, stake }

class _WorkItOutState extends State<WorkItOut> {
  _Mode? _mode;

  List<_Mode> get _modes => [
    if (widget.deal.pick.isNotEmpty) _Mode.pick,
    if (widget.deal.slide.isNotEmpty) _Mode.slide,
    if (widget.deal.closer.isNotEmpty) _Mode.closer,
    if (widget.deal.bigger.isNotEmpty) _Mode.bigger,
    if (widget.deal.range.isNotEmpty) _Mode.range,
    if (widget.deal.stake.isNotEmpty) _Mode.stake,
  ];

  String _label(BuildContext context, _Mode m) {
    final l = context.l10n;
    return switch (m) {
      _Mode.pick => l.modePick,
      _Mode.slide => l.modeSlide,
      _Mode.closer => l.modeCloser,
      _Mode.bigger => l.modeBigger,
      _Mode.range => l.modeRange,
      _Mode.stake => l.modeStake,
    };
  }

  String _line(BuildContext context, _Mode m) {
    final l = context.l10n;
    return switch (m) {
      _Mode.pick => l.modePickLine,
      _Mode.slide => l.modeSlideLine,
      _Mode.closer => l.modeCloserLine,
      _Mode.bigger => l.modeBiggerLine,
      _Mode.range => l.modeRangeLine,
      _Mode.stake => l.modeStakeLine(ExplorePlay.dailyPoints),
    };
  }

  @override
  Widget build(BuildContext context) {
    final modes = _modes;
    if (modes.isEmpty) return const SizedBox.shrink();
    final _Mode mode = modes.contains(_mode) ? _mode! : modes.first;
    final Color ink = context.p.ink;
    return ListenableBuilder(
      listenable: ExplorePlay.instance,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.themeWorkItOut,
                        style: AppText.body(
                          size: 16,
                          weight: FontWeight.w600,
                          height: 1,
                          spacing: -0.2,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _line(context, mode),
                          key: ValueKey(mode),
                          style: AppText.body(
                            size: 12,
                            height: 1.3,
                            color: ink.withValues(alpha: 0.42),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _Wallet(points: ExplorePlay.instance.points),
              ],
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: modes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final bool on = modes[i] == mode;
                return Semantics(
                  key: ValueKey('work-${modes[i].name}-${on ? 'on' : 'off'}'),
                  button: true,
                  selected: on,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Analytics.capture('explore work mode', {
                        'mode': modes[i].name,
                      });
                      setState(() => _mode = modes[i]);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: on
                            ? context.p.inverse
                            : ink.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        _label(context, modes[i]),
                        style: AppText.body(
                          size: 12.5,
                          weight: FontWeight.w600,
                          height: 1,
                          color: on
                              ? context.p.onInverse
                              : ink.withValues(alpha: 0.62),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            child: KeyedSubtree(
              key: ValueKey(mode),
              child: switch (mode) {
                _Mode.pick => _PickRow(
                  pills: widget.deal.pick,
                  isRead: widget.isRead,
                  onOpen: widget.onOpen,
                  answerOf: widget.answerOf,
                  onCommit: widget.onCommit,
                  onShown: widget.onShown,
                ),
                _Mode.slide => _SlideRow(
                  cards: widget.deal.slide,
                  onOpen: widget.onOpen,
                  onShown: widget.onShown,
                ),
                _Mode.closer => _CloserRow(
                  cards: widget.deal.closer,
                  onOpen: widget.onOpen,
                  onShown: widget.onShown,
                ),
                _Mode.bigger => _BiggerList(
                  pairs: widget.deal.bigger,
                  onOpen: widget.onOpen,
                  onShown: widget.onShown,
                ),
                _Mode.range => _RangeRow(
                  cards: widget.deal.range,
                  onOpen: widget.onOpen,
                  onShown: widget.onShown,
                ),
                _Mode.stake => _StakeRow(
                  pills: widget.deal.stake,
                  onOpen: widget.onOpen,
                  answerOf: widget.answerOf,
                  onCommit: widget.onCommit,
                  onShown: widget.onShown,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The day's points, level with the shelf's name.
class _Wallet extends StatelessWidget {
  const _Wallet({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('work-wallet'),
      height: 30,
      padding: const EdgeInsets.fromLTRB(8, 0, 11, 0),
      decoration: BoxDecoration(
        color: context.p.inverse,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.adjust_rounded, size: 16, color: context.p.onInverse),
          const SizedBox(width: 5),
          Text(
            '$points',
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w700,
              height: 1,
              color: context.p.onInverse,
            ),
          ),
        ],
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

/// The head and question every card on this shelf starts with.
class _Top extends StatelessWidget {
  const _Top({required this.pill, this.minHeight = 88, this.max = 18});

  final Pill pill;
  final double minHeight;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CardHead(pill: pill),
        const SizedBox(height: 12),
        SizedBox(
          height: minHeight,
          child: CardQuestion(
            text: pill.question,
            color: pill.ink,
            min: 11.5,
            max: max,
          ),
        ),
      ],
    );
  }
}

/// A card of this shelf: 300 wide, the colour of its subject.
class _Card extends StatelessWidget {
  const _Card({required this.pill, required this.onOpen, required this.child});

  final Pill pill;
  final VoidCallback onOpen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CardTap(
      pill: pill,
      onTap: onOpen,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: pill.color,
          borderRadius: BorderRadius.circular(22),
        ),
        child: child,
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

// ── Pick one (133b) ──────────────────────────────────────────────────────

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.pills,
    required this.isRead,
    required this.onOpen,
    required this.answerOf,
    required this.onCommit,
    this.onShown,
  });

  final List<Pill> pills;
  final bool Function(Pill) isRead;
  final void Function(List<Pill>, Pill) onOpen;
  final String? Function(Pill) answerOf;
  final void Function(Pill, String) onCommit;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    return SideRow(
      height: 272,
      count: pills.length,
      itemBuilder: (context, i) {
        final Pill p = pills[i];
        onShown?.call(p);
        final PickOne c = p.challenge as PickOne;
        final int? said = int.tryParse(answerOf(p) ?? '');
        final bool done = said != null;
        return CardTap(
          pill: p,
          onTap: () => onOpen(pills, p),
          child: Container(
            width: 236,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.color,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardHead(
                  pill: p,
                  trailing: isRead(p) ? ReadMark(pill: p) : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: CardQuestion(
                      text: p.question,
                      color: p.ink,
                      min: 11,
                      max: 16.5,
                    ),
                  ),
                ),
                for (int k = 0; k < c.options.length; k++) ...[
                  if (k > 0) const SizedBox(height: 5),
                  _option(context, p, c, k, said, done),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _option(
    BuildContext context,
    Pill p,
    PickOne c,
    int k,
    int? said,
    bool done,
  ) {
    final bool right = k == c.correct;
    final bool lit = done && right;
    final bool wrongPick = done && k == said && !right;
    return Semantics(
      key: ValueKey('pick-${p.id}-$k'),
      button: !done,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: done ? null : () => onCommit(p, '$k'),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: done && !lit && !wrongPick ? 0.4 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 32,
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

class _SlideRow extends StatelessWidget {
  const _SlideRow({required this.cards, required this.onOpen, this.onShown});

  final List<PercentCard> cards;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    final List<Pill> shelf = [for (final c in cards) c.pill];
    final play = ExplorePlay.instance;
    final offs = <double>[
      for (final c in cards)
        if (play['slide:${c.pill.id}'] case {'ck': true, 'v': final num v})
          (v - c.value).abs(),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SideRow(
          height: 340,
          count: cards.length,
          itemBuilder: (context, i) {
            final PercentCard c = cards[i];
            onShown?.call(c.pill);
            return _SlideCard(card: c, onOpen: () => onOpen(shelf, c.pill));
          },
        ),
        _Note(
          offs.isEmpty
              ? context.l10n.slideNote
              : context.l10n.slideAverage(
                  (offs.reduce((a, b) => a + b) / offs.length).round(),
                ),
        ),
      ],
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.card, required this.onOpen});

  final PercentCard card;
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
    return _Card(
      pill: p,
      onOpen: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Top(pill: p, minHeight: 76, max: 17),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _pct(v),
                style: AppText.display(
                  size: 34,
                  weight: FontWeight.w600,
                  height: 1,
                  spacing: -1,
                  color: p.ink,
                ),
              ),
              const Spacer(),
              Text(
                upper(context, checked ? l.answerIs(card.said) : l.dragToSet),
                style: AppText.label(
                  size: 9,
                  weight: FontWeight.w700,
                  spacing: 1.2,
                  color: checked ? p.ink : subOn(p),
                ),
              ),
            ],
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
            Text(
              '${l.itIs(inSentence(card.said))} ${l.slideOff(off)}',
              key: ValueKey('slide-said-${p.id}'),
              style: AppText.body(
                size: 13,
                weight: FontWeight.w600,
                height: 1.35,
                color: p.ink,
              ),
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

class _CloserRow extends StatelessWidget {
  const _CloserRow({required this.cards, required this.onOpen, this.onShown});

  final List<PercentCard> cards;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    final List<Pill> shelf = [for (final c in cards) c.pill];
    return SideRow(
      height: 360,
      count: cards.length,
      itemBuilder: (context, i) {
        final PercentCard c = cards[i];
        onShown?.call(c.pill);
        return _CloserCard(card: c, onOpen: () => onOpen(shelf, c.pill));
      },
    );
  }
}

class _CloserCard extends StatelessWidget {
  const _CloserCard({required this.card, required this.onOpen});

  final PercentCard card;
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
        height: 42,
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
    return _Card(
      pill: p,
      onOpen: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Top(pill: p, minHeight: 80, max: 17),
          const SizedBox(height: 12),
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
          const SizedBox(height: 14),
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
            const SizedBox(height: 12),
          ],
          Text(
            message,
            key: ValueKey('closer-said-${p.id}'),
            style: AppText.body(
              size: 13,
              weight: FontWeight.w600,
              height: 1.4,
              color: p.ink,
            ),
          ),
          if (done) _Why(p),
        ],
      ),
    );
  }
}

// ── Which is bigger? (139c) ──────────────────────────────────────────────

class _BiggerList extends StatelessWidget {
  const _BiggerList({required this.pairs, required this.onOpen, this.onShown});

  final List<BiggerPair> pairs;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    final play = ExplorePlay.instance;
    final List<Pill> shelf = [
      for (final (a, b) in pairs) ...[a.pill, b.pill],
    ];
    int asked = 0, right = 0;
    for (final (a, b) in pairs) {
      final Object? pick = play['bigger:${a.pill.id}:${b.pill.id}'];
      if (pick is int) {
        asked++;
        if ((pick == 0) == (a.value > b.value)) right++;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (a, b) in pairs) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _BiggerPairView(
              a: a,
              b: b,
              onOpen: (p) => onOpen(shelf, p),
              onShown: onShown,
            ),
          ),
          const SizedBox(height: 10),
        ],
        _Note(
          asked == 0
              ? context.l10n.biggerNote
              : context.l10n.biggerScore(right, asked),
        ),
      ],
    );
  }
}

class _BiggerPairView extends StatelessWidget {
  const _BiggerPairView({
    required this.a,
    required this.b,
    required this.onOpen,
    this.onShown,
  });

  final PercentCard a;
  final PercentCard b;
  final ValueChanged<Pill> onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    final play = ExplorePlay.instance;
    final String key = 'bigger:${a.pill.id}:${b.pill.id}';
    final Object? kept = play[key];
    final int? picked = kept is int ? kept : null;
    final int bigger = a.value > b.value ? 0 : 1;
    final l = context.l10n;
    onShown?.call(a.pill);
    onShown?.call(b.pill);

    Widget side(int j, PercentCard c) {
      final bool done = picked != null;
      final bool big = done && j == bigger;
      final Color ink = big ? context.p.onInverse : context.p.ink;
      final String tag = !done
          ? l.tapIfBigger
          : big
          ? (picked == j ? l.biggerYouGotIt : l.biggerLabel)
          : (picked == j ? l.yourPick : '');
      return Expanded(
        child: GestureDetector(
          key: ValueKey('bigger-${c.pill.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: done
              ? () => onOpen(c.pill)
              : () {
                  play.put(key, j);
                  Analytics.capture('explore bigger picked', {
                    'right': j == bigger,
                  });
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            constraints: const BoxConstraints(minHeight: 136),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: big
                  ? context.p.inverse
                  : context.p.ink.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: c.pill.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        upper(context, c.pill.topic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(
                          size: 8.5,
                          weight: FontWeight.w700,
                          spacing: 1.1,
                          color: ink.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  done ? _pct(c.value) : '?',
                  style: AppText.display(
                    size: 30,
                    weight: FontWeight.w600,
                    height: 1,
                    spacing: -1,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  c.pill.question,
                  maxLines: 7,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w500,
                    height: 1.35,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  upper(context, tag),
                  style: AppText.label(
                    size: 9,
                    weight: FontWeight.w700,
                    spacing: 1.2,
                    color: ink.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [side(0, a), const SizedBox(width: 8), side(1, b)],
          ),
        ),
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.p.surface,
            shape: BoxShape.circle,
            border: Border.all(color: context.p.ink.withValues(alpha: 0.18)),
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
      ],
    );
  }
}

// ── Bet a range (139a) ───────────────────────────────────────────────────

/// How wide a range is, either side of the guess, and what it pays.
const List<(int, int)> _widths = [(5, 30), (10, 20), (20, 10)];

class _RangeRow extends StatelessWidget {
  const _RangeRow({required this.cards, required this.onOpen, this.onShown});

  final List<PercentCard> cards;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    final List<Pill> shelf = [for (final c in cards) c.pill];
    final play = ExplorePlay.instance;
    final l = context.l10n;
    // What was laid today, read back: the points were paid when the bet
    // was laid, and the slip only says what they came to.
    final slip = <(PercentCard, int, int, int)>[];
    int won = 0;
    for (final c in cards) {
      final Object? kept = play['range:${c.pill.id}'];
      if (kept case {'lk': true, 'g': final num g, 'w': final num w}) {
        final (int half, int pays) = _widths[w.toInt()];
        final double lo = math.max(0, g - half).toDouble();
        final double hi = math.min(100, g + half).toDouble();
        final int paid = c.value >= lo && c.value <= hi ? pays : 0;
        slip.add((c, lo.round(), hi.round(), paid));
        won += paid;
      }
    }
    final Color ink = context.p.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SideRow(
          height: 384,
          count: cards.length,
          itemBuilder: (context, i) {
            final PercentCard c = cards[i];
            onShown?.call(c.pill);
            return _RangeCard(card: c, onOpen: () => onOpen(shelf, c.pill));
          },
        ),
        const SizedBox(height: 14),
        Container(
          key: const ValueKey('bet-slip'),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: ink.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      l.betSlip,
                      style: AppText.body(
                        size: 16,
                        weight: FontWeight.w600,
                        height: 1,
                        spacing: -0.2,
                        color: ink,
                      ),
                    ),
                  ),
                  Text(
                    l.pointsToday(won),
                    style: AppText.body(
                      size: 12.5,
                      weight: FontWeight.w700,
                      height: 1,
                      color: winColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (slip.isEmpty)
                Text(
                  l.slipEmpty,
                  style: AppText.body(
                    size: 12.5,
                    weight: FontWeight.w500,
                    height: 1.4,
                    color: ink.withValues(alpha: 0.55),
                  ),
                )
              else
                for (final (c, lo, hi, paid) in slip)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: c.pill.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.pill.question,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              size: 12.5,
                              weight: FontWeight.w500,
                              height: 1.2,
                              color: ink.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$lo–$hi%',
                          style: AppText.body(
                            size: 12,
                            weight: FontWeight.w600,
                            height: 1,
                            color: ink.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          paid > 0 ? '+$paid' : '0',
                          style: AppText.body(
                            size: 12.5,
                            weight: FontWeight.w700,
                            height: 1,
                            color: paid > 0
                                ? winColor(context)
                                : ink.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 4),
              Text(
                l.goNarrow,
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w500,
                  height: 1.4,
                  color: ink.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RangeCard extends StatelessWidget {
  const _RangeCard({required this.card, required this.onOpen});

  final PercentCard card;
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

    return _Card(
      pill: p,
      onOpen: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Top(pill: p, minHeight: 76, max: 17),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _pct(g),
                style: AppText.display(
                  size: 34,
                  weight: FontWeight.w600,
                  height: 1,
                  spacing: -1,
                  color: p.ink,
                ),
              ),
              const Spacer(),
              Text(
                '${lo.round()}–${hi.round()}%',
                style: AppText.body(
                  size: 11,
                  weight: FontWeight.w700,
                  height: 1,
                  color: p.ink,
                ),
              ),
            ],
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
          Row(
            children: [
              for (int j = 0; j < _widths.length; j++) ...[
                if (j > 0) const SizedBox(width: 6),
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: locked && j != wi ? 0.4 : 1,
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
                      onTap: locked ? null : () => keep(width: j),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (locked) ...[
            Text(
              hit
                  ? l.inRange(pays, inSentence(card.said))
                  : l.missedRange(inSentence(card.said)),
              key: ValueKey('range-said-${p.id}'),
              style: AppText.body(
                size: 13,
                weight: FontWeight.w600,
                height: 1.35,
                color: p.ink,
              ),
            ),
            _Why(p),
          ] else
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
      ),
    );
  }
}

// ── Place your bet (139b) ────────────────────────────────────────────────

const List<int> _stakes = [10, 20, 30];

class _StakeRow extends StatelessWidget {
  const _StakeRow({
    required this.pills,
    required this.onOpen,
    required this.answerOf,
    required this.onCommit,
    this.onShown,
  });

  final List<Pill> pills;
  final void Function(List<Pill>, Pill) onOpen;
  final String? Function(Pill) answerOf;
  final void Function(Pill, String) onCommit;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    return SideRow(
      height: 348,
      count: pills.length,
      itemBuilder: (context, i) {
        final Pill p = pills[i];
        onShown?.call(p);
        return _StakeCard(
          pill: p,
          onOpen: () => onOpen(pills, p),
          onCommit: onCommit,
          answered: answerOf(p) != null,
        );
      },
    );
  }
}

class _StakeCard extends StatelessWidget {
  const _StakeCard({
    required this.pill,
    required this.onOpen,
    required this.onCommit,
    required this.answered,
  });

  final Pill pill;
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

    return _Card(
      pill: p,
      onOpen: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Top(pill: p, minHeight: 92, max: 18),
          const SizedBox(height: 13),
          Row(
            children: [
              for (int j = 0; j < c.options.length; j++) ...[
                if (j > 0) const SizedBox(width: 6),
                Expanded(child: _stakeOption(context, j, c, o, done)),
              ],
            ],
          ),
          const SizedBox(height: 13),
          if (done) ...[
            Text(
              '${win ? l.youWin(_stakes[k]) : l.youLose(_stakes[k])} '
              '${l.theAnswer(c.options[c.correct])}',
              key: ValueKey('stake-said-${p.id}'),
              style: AppText.body(
                size: 13,
                weight: FontWeight.w600,
                height: 1.35,
                color: p.ink,
              ),
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
      padding: const EdgeInsets.only(top: 8),
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

/// A line under a way of playing: how it went, or how to play it.
class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Text(
        text,
        style: AppText.body(
          size: 12,
          weight: FontWeight.w500,
          height: 1.4,
          color: context.p.ink.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
