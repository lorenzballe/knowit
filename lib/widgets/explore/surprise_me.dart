import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../analytics.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import 'parts.dart';

/// Not sure where to start? — artboard 138f, the very bottom.
///
/// One card from anywhere: any subject, any shelf. Two cards peek out from
/// behind a dark one that says so, and a tap deals a card into its place,
/// with the way to open it and the way to have another. The last shelf, for
/// whoever scrolled this far and has not found theirs.
class SurpriseMe extends StatefulWidget {
  const SurpriseMe({super.key, required this.pool, required this.onOpen});

  /// Where the card comes from: everything not read, in the subject chosen.
  final List<Pill> pool;
  final void Function(List<Pill>, Pill) onOpen;

  @override
  State<SurpriseMe> createState() => _SurpriseMeState();
}

class _SurpriseMeState extends State<SurpriseMe> {
  final math.Random _random = math.Random();
  Pill? _card;

  void _deal() {
    if (widget.pool.isEmpty) return;
    Pill next = widget.pool[_random.nextInt(widget.pool.length)];
    for (int i = 0; i < 4 && next.id == _card?.id; i++) {
      next = widget.pool[_random.nextInt(widget.pool.length)];
    }
    Analytics.capture('explore surprise', {'pill_id': next.id});
    setState(() => _card = next);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pool.isEmpty) return const SizedBox.shrink();
    final Color ink = context.p.ink;
    final l = context.l10n;
    final Pill? card = _card;
    // The two that peek out: the first and last of the pool, so they are
    // the same two every time the shelf is built.
    final Color peekA = widget.pool.first.color;
    final Color peekB = widget.pool.last.color;

    Widget peek(Color c, double angle, double top) => Positioned(
      left: 22,
      right: 22,
      top: top,
      height: 236,
      child: Transform.rotate(
        angle: angle,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 264,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            peek(peekA, -0.04, 0),
            peek(peekB, 0.035, 18),
            Positioned(
              left: 0,
              right: 0,
              top: 8,
              height: 236,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, a) => ScaleTransition(
                  scale: Tween(begin: 0.94, end: 1.0).animate(a),
                  child: FadeTransition(opacity: a, child: child),
                ),
                child: card == null
                    ? Container(
                        key: const ValueKey('surprise-idle'),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: context.p.isDark
                              ? const Color(0xFF0E0E10)
                              : context.p.surfaceRaised,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: ink.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l.anyCard,
                              textAlign: TextAlign.center,
                              style: AppText.display(
                                size: 24,
                                weight: FontWeight.w600,
                                height: 1.15,
                                spacing: -0.6,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: 18),
                            FlatButton(
                              key: const ValueKey('surprise-me'),
                              label: l.surpriseMe,
                              background: context.p.inverse,
                              foreground: context.p.onInverse,
                              height: 44,
                              size: 14,
                              padding: const EdgeInsets.fromLTRB(16, 0, 20, 0),
                              icon: Icon(
                                Icons.shuffle_rounded,
                                size: 17,
                                color: context.p.onInverse,
                              ),
                              onTap: _deal,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        key: ValueKey('surprise-${card.id}'),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: card.color,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: context.p.isDark ? 0.6 : 0.18,
                              ),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CardHead(pill: card),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 12,
                                  bottom: 12,
                                ),
                                child: CardQuestion(
                                  text: card.question,
                                  color: card.ink,
                                  min: 13,
                                  max: 23,
                                  height: 1.12,
                                  tracking: -0.032,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                FlatButton(
                                  key: const ValueKey('surprise-open'),
                                  label: l.openWord,
                                  background: card.ink,
                                  foreground: card.color,
                                  height: 38,
                                  size: 13,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  onTap: () => widget.onOpen([card], card),
                                ),
                                const SizedBox(width: 8),
                                FlatButton(
                                  key: const ValueKey('surprise-again'),
                                  label: l.anotherOne,
                                  background: fillOn(card),
                                  foreground: card.ink,
                                  height: 38,
                                  size: 13,
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    0,
                                    15,
                                    0,
                                  ),
                                  icon: Icon(
                                    Icons.shuffle_rounded,
                                    size: 15,
                                    color: card.ink,
                                  ),
                                  onTap: _deal,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
