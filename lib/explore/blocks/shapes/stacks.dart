/// The shapes that hold their cards in a pile: a deck turned a card at a
/// time (131e, and 132b's with the quote struck out), one debate at a time
/// with its two sides to take (131e, and 132b's in two halves), and a hand
/// of cards fanned out (131e, and 132b's with two circles).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;

import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/card_edge.dart';
import '../../../widgets/explore/parts.dart';
import '../../explore_block.dart';
import 'deal.dart';
import 'look.dart';
import 'outlines.dart';
import 'shelf.dart';
import 'signatures.dart';
import 'tile.dart';
import 'vocabulary.dart';

/// Where a pile is, under its cards: how many there are, which is in front,
/// and a dot for each, the one in front drawn long.
class _PileFoot extends StatelessWidget {
  const _PileFoot({required this.at, required this.count, this.hint});

  final int at;
  final int count;

  /// What to do with the pile, said after the count.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    final String count0 = context.l10n.nOfM(at + 1, count);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            hint == null ? count0 : '$count0 · $hint',
            style: AppText.body(
              size: 12,
              weight: FontWeight.w600,
              height: 1.25,
              color: ink.withValues(alpha: 0.42),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: i == at ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == at ? ink : ink.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// What a card standing up off the page throws under it: black on the
/// night paper, as the canvas has it, and the app's own faint lift on the
/// day paper, where black would be a smudge.
List<BoxShadow> _standing(BuildContext context, {Offset? offset}) =>
    context.p.isDark
    ? [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 22,
          offset: offset ?? const Offset(0, 10),
        ),
      ]
    : cardLift(context.p);

// ── The deck (131e, 132b) ────────────────────────────────────────────────

/// A deck at one size.
@immutable
class _DeckSize {
  const _DeckSize(this.card, this.pad, this.min, this.max);

  final double card;
  final double pad;
  final double min;
  final double max;
}

/// Myths, as a deck: one card at the front, the edges of the next two under
/// it, a swipe to the next and back, a tap to open the one in front (131e);
/// with the quote signature, the myth's opening quote struck out behind it
/// (132b).
class DeckBlock extends ShapeBlock {
  const DeckBlock();

  @override
  String get name => 'shape-deck';

  @override
  ShapeVocabulary get words => const ShapeVocabulary(
    canvas: ['131e', '132b'],
    kind: 'myths',
    signatures: ['none', 'quote'],
    fewest: 2,
  );

  static const Map<String, _DeckSize> _sizes = {
    's': _DeckSize(196, 15, 12, 19),
    'm': _DeckSize(220, 17, 13, 22),
    'l': _DeckSize(236, 18, 13.5, 23),
  };

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) => _Deck(
    key: ValueKey('shape-deck-${deal.section.id}'),
    host: host,
    deal: deal,
    size: _sizes[sizeOf(deal.section)]!,
    quote: signatureOf(deal.section) == 'quote',
  );
}

class _Deck extends StatefulWidget {
  const _Deck({
    super.key,
    required this.host,
    required this.deal,
    required this.size,
    required this.quote,
  });

  final ExploreHost host;
  final ShapeDeal deal;
  final _DeckSize size;
  final bool quote;

  @override
  State<_Deck> createState() => _DeckState();
}

class _DeckState extends State<_Deck> with SingleTickerProviderStateMixin {
  /// The card in front.
  int _at = 0;

  /// How far the card in front has been pulled sideways.
  double _drag = 0;

  /// Carries the card off the deck, or back onto it, once it is let go.
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..addListener(() => setState(() => _drag = _flight.evaluate(_settle)));
  Animatable<double> _flight = ConstantTween<double>(0);

  List<Pill> get _cards => widget.deal.cards;

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  /// Turns to the card at [to], as a swipe does: the one in front leaves
  /// the way it was pushed, and the deck says which card is in front now.
  Future<void> _turn(int to, double width) async {
    if (to < 0 || to >= _cards.length || _settle.isAnimating) return;
    final double off = (to > _at ? -1 : 1) * width * 1.15;
    if (!MediaQuery.disableAnimationsOf(context)) {
      _flight = Tween<double>(
        begin: _drag,
        end: off,
      ).chain(CurveTween(curve: Curves.easeInCubic));
      await _settle.forward(from: 0);
    }
    if (!mounted) return;
    setState(() {
      _at = to;
      _drag = 0;
    });
    widget.host.note(widget.deal.section, 'turned', {
      'pill': _cards[to].id,
      'at': to,
    });
  }

  void _back() {
    _flight = Tween<double>(
      begin: _drag,
      end: 0,
    ).chain(CurveTween(curve: Curves.easeOutBack));
    _settle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final ExploreSection section = widget.deal.section;
    final _DeckSize size = widget.size;
    final Pill front = _cards[_at];
    widget.host.seen(section, front);
    final l = context.l10n;
    final Color page = context.p.surface;
    // The next two cards, under the one in front: their own colours, drawn
    // toward the page the further back they lie, their edges showing below.
    Widget under(int depth) {
      final int i = _at + depth;
      if (i >= _cards.length) return const SizedBox.shrink();
      return Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: size.card,
        child: Transform.translate(
          offset: Offset(0, 10.0 * depth),
          child: Transform.scale(
            scale: 1 - 0.06 * depth,
            alignment: Alignment.bottomCenter,
            child: CardDim(
              amount: depth == 1 ? 0.2 : 0.45,
              ground: page,
              radius: 22,
              child: DecoratedBox(
                decoration: cardFace(context, _cards[i].color, radius: 22),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, box) {
          final double width = box.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: size.card + 20,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    under(2),
                    under(1),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: size.card,
                      child: Transform.translate(
                        offset: Offset(_drag, 0),
                        child: Transform.rotate(
                          angle: _drag / width * 0.12,
                          alignment: Alignment.bottomCenter,
                          child: Semantics(
                            button: true,
                            customSemanticsActions: {
                              if (_at < _cards.length - 1)
                                CustomSemanticsAction(label: l.next): () =>
                                    _turn(_at + 1, width),
                              if (_at > 0)
                                CustomSemanticsAction(
                                  label: l.storyPrevious,
                                ): () =>
                                    _turn(_at - 1, width),
                            },
                            child: GestureDetector(
                              key: ValueKey('explore-${front.id}'),
                              behavior: HitTestBehavior.opaque,
                              onTap: () =>
                                  widget.host.open(section, _cards, front),
                              onHorizontalDragStart: (_) => _settle.stop(),
                              onHorizontalDragUpdate: (d) =>
                                  setState(() => _drag += d.delta.dx),
                              onHorizontalDragEnd: (d) {
                                final double v = d.primaryVelocity ?? 0;
                                final bool far = _drag.abs() > width * 0.22;
                                final bool fast = v.abs() > 600;
                                final int to = (far || fast)
                                    ? (_drag + v * 0.05 < 0 ? _at + 1 : _at - 1)
                                    : _at;
                                if (to != _at &&
                                    to >= 0 &&
                                    to < _cards.length) {
                                  _turn(to, width);
                                } else {
                                  _back();
                                }
                              },
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: _standing(context),
                                ),
                                child: ShapeTile(
                                  pill: front,
                                  read: widget.host.isRead(front),
                                  art: widget.quote
                                      ? [
                                          QuoteArt(
                                            mark: tone(front, Tones.graphic),
                                            bar: tone(front, Tones.over),
                                          ),
                                        ]
                                      : const [],
                                  look: TileLook(
                                    outline: const RoundOutline(22),
                                    padding: EdgeInsets.all(size.pad),
                                    named: true,
                                    words: widget.quote
                                        ? TileWords.top
                                        : TileWords.middle,
                                    min: size.min,
                                    max: size.max,
                                    lineHeight: 1.12,
                                    tracking: -0.034,
                                    gap: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _PileFoot(
                at: _at,
                count: _cards.length,
                hint: l.swipeForTheNextOne,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── One at a time (131e, 132b) ───────────────────────────────────────────

/// A pager at one size.
@immutable
class _PagerSize {
  const _PagerSize(this.card, this.pad, this.min, this.max, this.button);

  final double card;
  final double pad;
  final double min;
  final double max;
  final double button;
}

/// Debates, one at a time across the page, a swipe from one to the next,
/// and at the foot of each its two sides: a tap on one takes it, the answer
/// the card itself records (131e), and once one is taken the foot opens the
/// card like the rest of it. With the halves signature the card is in two
/// halves and an "or" stands between the sides (132b).
class PagerBlock extends ShapeBlock {
  const PagerBlock();

  @override
  String get name => 'shape-pager';

  @override
  ShapeVocabulary get words => const ShapeVocabulary(
    canvas: ['131e', '132b'],
    kind: 'debates',
    signatures: ['none', 'halves'],
    fewest: 1,
  );

  static const Map<String, _PagerSize> _sizes = {
    's': _PagerSize(228, 15, 12, 19, 42),
    'm': _PagerSize(252, 17, 13, 22, 46),
    'l': _PagerSize(262, 18, 13.5, 23, 48),
  };

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) => _Pager(
    key: ValueKey('shape-pager-${deal.section.id}'),
    host: host,
    deal: deal,
    size: _sizes[sizeOf(deal.section)]!,
    halves: signatureOf(deal.section) == 'halves',
  );
}

class _Pager extends StatefulWidget {
  const _Pager({
    super.key,
    required this.host,
    required this.deal,
    required this.size,
    required this.halves,
  });

  final ExploreHost host;
  final ShapeDeal deal;
  final _PagerSize size;
  final bool halves;

  @override
  State<_Pager> createState() => _PagerState();
}

class _PagerState extends State<_Pager> {
  final PageController _pages = PageController();
  int _at = 0;

  /// The sides taken here, by card, until the reader's answers say so.
  final Map<String, int> _said = {};

  List<Pill> get _cards => widget.deal.cards;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ExploreSection section = widget.deal.section;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.size.card,
          child: PageView.builder(
            controller: _pages,
            itemCount: _cards.length,
            onPageChanged: (i) {
              setState(() => _at = i);
              widget.host.note(section, 'paged', {
                'pill': _cards[i].id,
                'at': i,
              });
            },
            itemBuilder: (context, i) {
              final Pill p = _cards[i];
              widget.host.seen(section, p);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CardTap(
                  pill: p,
                  onTap: () => widget.host.open(section, _cards, p),
                  child: _card(context, p),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _PileFoot(at: _at, count: _cards.length),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, Pill p) {
    final _PagerSize size = widget.size;
    final List<String> sides = sidesOf(p);
    final int? taken =
        sideTaken(p, widget.host.app.answerFor(p.id)) ?? _said[p.id];
    final String or = context.l10n.sideOr;
    Widget side(int i) {
      final bool mine = taken == i;
      return Expanded(
        child: Semantics(
          button: taken == null,
          selected: mine,
          label: sides[i],
          excludeSemantics: true,
          child: GestureDetector(
            key: ValueKey('shape-side-${p.id}-$i'),
            behavior: HitTestBehavior.opaque,
            onTap: taken != null
                ? null
                : () {
                    setState(() => _said[p.id] = i);
                    widget.host.commit(p, '$i');
                  },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: taken != null && !mine ? 0.42 : 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: size.button,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: mine ? p.ink : fillOn(p),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  sideLabel(sides[i]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    size: 15,
                    weight: FontWeight.w600,
                    height: 1,
                    color: mine ? p.color : p.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final Widget buttons = sides.length < 2
        ? const SizedBox.shrink()
        : widget.halves
        ? Stack(
            alignment: Alignment.center,
            children: [
              Row(children: [side(0), const SizedBox(width: 44), side(1)]),
              ExcludeSemantics(
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.ink,
                    shape: BoxShape.circle,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        or,
                        maxLines: 1,
                        style: AppText.display(
                          size: or.length <= 2 ? 14 : 12,
                          weight: FontWeight.w600,
                          height: 1,
                          color: p.color,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        : Row(children: [side(0), const SizedBox(width: 8), side(1)]);

    return OutlinedFace(
      outline: const RoundOutline(22),
      colour: p.color,
      art: widget.halves ? [SplitArt.halves(tone(p, Tones.half))] : const [],
      padding: EdgeInsets.all(size.pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShapeHead(pill: p, named: true, read: widget.host.isRead(p)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: CardQuestion(
                text: p.question,
                color: p.ink,
                min: size.min,
                max: size.max,
                height: 1.12,
                tracking: -0.034,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
          buttons,
        ],
      ),
    );
  }
}

// ── The hand (131e, 132b) ────────────────────────────────────────────────

/// A hand at one size.
@immutable
class _HandSize {
  const _HandSize(this.width, this.height, this.top, this.min, this.max);

  final double width;
  final double height;

  /// Room above the cards, for one drawn up out of the hand.
  final double top;
  final double min;
  final double max;
}

/// Paradoxes, as a hand of cards fanned out: the one in front opens at a
/// tap, and a tap on one half hidden in the fan draws it up in front of the
/// others (131e); with the circles signature, two circles overlap at the
/// foot of each (132b).
class HandBlock extends ShapeBlock {
  const HandBlock();

  @override
  String get name => 'shape-hand';

  @override
  ShapeVocabulary get words => const ShapeVocabulary(
    canvas: ['131e', '132b'],
    kind: 'paradoxes',
    signatures: ['none', 'circles'],
    limit: 4,
    most: 5,
    fewest: 2,
  );

  static const Map<String, _HandSize> _sizes = {
    's': _HandSize(152, 180, 12, 10, 14.5),
    'm': _HandSize(170, 200, 14, 10.5, 16),
    'l': _HandSize(176, 220, 16, 10.5, 15),
  };

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) => _Hand(
    key: ValueKey('shape-hand-${deal.section.id}'),
    host: host,
    deal: deal,
    size: _sizes[sizeOf(deal.section)]!,
    circles: signatureOf(deal.section) == 'circles',
  );
}

class _Hand extends StatefulWidget {
  const _Hand({
    super.key,
    required this.host,
    required this.deal,
    required this.size,
    required this.circles,
  });

  final ExploreHost host;
  final ShapeDeal deal;
  final _HandSize size;
  final bool circles;

  @override
  State<_Hand> createState() => _HandState();
}

class _HandState extends State<_Hand> {
  /// The card drawn up in front of the others, if one is.
  int? _up;

  List<Pill> get _cards => widget.deal.cards;

  /// The card in front: the one drawn up, or the last of the fan.
  int get _front => _up ?? _cards.length - 1;

  @override
  Widget build(BuildContext context) {
    final _HandSize size = widget.size;
    final ExploreSection section = widget.deal.section;
    final int n = _cards.length;
    final bool night = context.p.isDark;
    final bool calm = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, box) {
          final double room = box.maxWidth;
          // The fan spreads to the width there is, and no wider than shows
          // a good part of every card.
          final double step = n > 1
              ? math.min((room - size.width - 28) / (n - 1), size.width * 0.62)
              : 0;
          final double spread = step * (n - 1) + size.width;
          final double left = math.max(14, (room - spread) / 2);
          Widget card(int i) {
            final Pill p = _cards[i];
            widget.host.seen(section, p);
            final double angle = n > 1 ? -7 + 14 * i / (n - 1) : 0;
            final bool up = _up == i;
            return AnimatedPositioned(
              key: ValueKey('hand-${p.id}'),
              duration: calm
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              left: left + i * step,
              top: size.top - (up ? size.top : 0),
              width: size.width,
              height: size.height,
              child: Transform.rotate(
                angle: angle * math.pi / 180,
                // About a point below the cards, as a hand holds them.
                alignment: const Alignment(0, 1.4),
                child: Semantics(
                  button: true,
                  onTap: () => widget.host.open(section, _cards, p),
                  child: GestureDetector(
                    key: ValueKey('explore-${p.id}'),
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    onTap: () {
                      if (i == _front) {
                        widget.host.open(section, _cards, p);
                        return;
                      }
                      setState(() => _up = i);
                      widget.host.note(section, 'raised', {
                        'pill': p.id,
                        'at': i,
                      });
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: night ? 0.45 : 0.14,
                            ),
                            blurRadius: 18,
                            offset: const Offset(-8, 0),
                          ),
                        ],
                      ),
                      child: ShapeTile(
                        pill: p,
                        read: widget.host.isRead(p),
                        art: widget.circles
                            ? [
                                CirclesArt(
                                  disc: tone(p, Tones.graphic),
                                  overlap: tone(p, Tones.over),
                                ),
                              ]
                            : const [],
                        look: TileLook(
                          outline: const RoundOutline(19),
                          min: size.min,
                          max: size.max,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          // Drawn back to front: the fan in order, the card drawn up last.
          final List<int> order = [
            for (int i = 0; i < n; i++)
              if (i != _up) i,
            ?_up,
          ];
          return SizedBox(
            height: size.height + size.top + 22,
            child: Stack(
              clipBehavior: Clip.none,
              children: [for (final int i in order) card(i)],
            ),
          );
        },
      ),
    );
  }
}
