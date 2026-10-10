import 'package:flutter/material.dart';

import '../../analytics.dart';
import '../../data/explore_mix.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../state/explore_play.dart';
import '../../theme.dart';
import '../motion.dart';
import 'parts.dart';

/// Spot the false one: four claims from true-or-false cards under the
/// true-or-false shelf, three true and one not, and the reader picks the one
/// they think is false.
///
/// A pick is a tap and then a word to say it is meant, because four claims
/// are worth weighing against each other and a finger lands on one long
/// before the mind has settled. Then every claim says what it is, true or
/// false, under it: the false one struck out and crossed, the pick ringed,
/// and each a tap from its card for the why.
///
/// Only the claim picked is an answer: calling it false is the same answer
/// its card takes, so it is recorded as that card's, and the card counts as
/// read. The other three were not answered and are left alone.
class SpotTheFalseBlock extends StatefulWidget {
  const SpotTheFalseBlock({
    super.key,
    required this.spot,
    required this.onOpen,
    required this.onCommit,
    this.onShown,
  });

  final SpotTheFalse spot;
  final void Function(List<Pill>, Pill) onOpen;

  /// An answer given here, recorded the way the card itself takes one.
  final void Function(Pill, String) onCommit;
  final ValueChanged<Pill>? onShown;

  @override
  State<SpotTheFalseBlock> createState() => _SpotTheFalseBlockState();
}

class _SpotTheFalseBlockState extends State<SpotTheFalseBlock> {
  /// The claim tapped, not yet said to be meant.
  String? _chosen;

  /// What was played today is kept under the four it was played on, so the
  /// answer is still there when the shelf is scrolled back to.
  String get _key =>
      'spot:${[for (final p in widget.spot.cards) p.id].join(',')}';

  String? get _picked => switch (ExplorePlay.instance[_key]) {
    final String id when widget.spot.cards.any((p) => p.id == id) => id,
    _ => null,
  };

  void _confirm() {
    final String? id = _chosen;
    if (id == null || _picked != null) return;
    final Pill pill = widget.spot.cards.firstWhere((p) => p.id == id);
    ExplorePlay.instance.put(_key, id);
    Analytics.capture('explore spot', {
      'pill_id': pill.id,
      'right': pill.id == widget.spot.falseOne.id,
    });
    widget.onCommit(pill, '${trueOrFalseIndex(pill, false)}');
    setState(() => _chosen = null);
  }

  @override
  Widget build(BuildContext context) {
    for (final p in widget.spot.cards) {
      widget.onShown?.call(p);
    }
    // The day's play can arrive from the phone after the shelf is drawn.
    return ListenableBuilder(
      listenable: ExplorePlay.instance,
      builder: (context, _) => _block(context),
    );
  }

  Widget _block(BuildContext context) {
    final List<Pill> cards = widget.spot.cards;
    final String? picked = _picked;
    final bool done = picked != null;
    final Color ink = context.p.ink;
    final l = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        key: const ValueKey('mix-spot-false'),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          color: ink.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Kicker(l.spotTitle),
            ),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                l.spotLine,
                style: AppText.display(
                  size: 23,
                  weight: FontWeight.w600,
                  height: 1.1,
                  spacing: -0.6,
                  color: ink,
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (int i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              _claim(context, i, picked),
            ],
            const SizedBox(height: 14),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: done
                  ? _said(context, picked)
                  : _chosen == null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        l.spotPrompt,
                        style: AppText.body(
                          size: 12.5,
                          weight: FontWeight.w500,
                          height: 1.3,
                          color: ink.withValues(alpha: 0.55),
                        ),
                      ),
                    )
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: FlatButton(
                        key: const ValueKey('spot-confirm'),
                        label: l.spotConfirm,
                        background: context.p.inverse,
                        foreground: context.p.onInverse,
                        height: 42,
                        size: 13.5,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        onTap: _confirm,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// One claim: its number on a tile of its subject's colour, the claim, and
  /// its subject; once the pick is made, what it is.
  Widget _claim(BuildContext context, int i, String? picked) {
    final Pill p = widget.spot.cards[i];
    final l = context.l10n;
    final Color ink = context.p.ink;
    final bool done = picked != null;
    final bool chosen = !done && _chosen == p.id;
    final bool mine = picked == p.id;
    final bool truth = trueOrFalseAnswer(p);

    // The false one, once it is told, turns to the page's own ink and is
    // crossed: not a red, because a claim being false is a thing to read
    // about, not an alarm. The true ones keep their number and their
    // colour, which is their subject's: a tick on a red tile reads as both
    // answers at once, and the word under each says true already.
    final bool lit = done && !truth;
    final Widget mark = lit
        ? Icon(
            Icons.close_rounded,
            key: const ValueKey('x'),
            size: 19,
            color: context.p.onInverse,
          )
        : Text(
            '${i + 1}',
            key: const ValueKey('n'),
            style: AppText.display(
              size: 17,
              weight: FontWeight.w700,
              height: 1,
              color: p.ink,
            ),
          );

    final TextStyle claim =
        AppText.body(
          size: 14,
          weight: FontWeight.w600,
          height: 1.32,
          color: ink.withValues(alpha: lit ? 0.62 : 0.92),
        ).copyWith(
          decoration: TextDecoration.lineThrough,
          decorationThickness: 1.6,
          // There from the start and clear until the false one is told, so the
          // strike is drawn in rather than switched on.
          decorationColor: ink.withValues(alpha: lit ? 0.75 : 0),
        );

    return Semantics(
      key: ValueKey('spot-${p.id}'),
      button: true,
      selected: chosen || mine,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: done
            ? () => widget.onOpen(widget.spot.cards, p)
            : () => setState(() => _chosen = chosen ? null : p.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(8, 9, 10, 10),
          decoration: BoxDecoration(
            color: chosen || mine
                ? ink.withValues(alpha: 0.06)
                : ink.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ink.withValues(alpha: chosen || mine ? 0.7 : 0),
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: lit ? context.p.inverse : p.color,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, t) =>
                      ScaleTransition(scale: t, child: child),
                  child: mark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      style: claim,
                      child: Text(claimOf(p)),
                    ),
                    const SizedBox(height: 5),
                    if (done)
                      RiseIn.staggered(
                        i,
                        step: const Duration(milliseconds: 70),
                        child: Text(
                          upper(
                            context,
                            [
                              truth ? l.sayTrue : l.sayFalse,
                              if (mine) l.spotYours,
                            ].join(' · '),
                          ),
                          key: ValueKey(
                            'spot-${p.id}-${truth ? 'true' : 'false'}',
                          ),
                          style: AppText.label(
                            size: 9.5,
                            weight: FontWeight.w700,
                            spacing: 1.2,
                            height: 1.2,
                            color: ink.withValues(
                              alpha: lit || mine ? 0.85 : 0.5,
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        upper(context, p.topic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(
                          size: 9,
                          weight: FontWeight.w700,
                          spacing: 1.2,
                          height: 1.2,
                          color: ink.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// How the pick went, in words, and the way to the why.
  Widget _said(BuildContext context, String picked) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final bool found = picked == widget.spot.falseOne.id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PopIn(
            strength: 0.12,
            child: Text(
              found ? l.spotFound : l.spotMissed,
              key: const ValueKey('spot-said'),
              style: AppText.body(
                size: 14,
                weight: FontWeight.w700,
                height: 1.3,
                color: ink,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.spotWhy,
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w500,
              height: 1.3,
              color: ink.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
