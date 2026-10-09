import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import 'parts.dart';

/// Myths, busted — artboard 131e's deck.
///
/// One myth at a time, large, with the next two showing their edges under it
/// in darker tones of their own colours. A sideways throw turns the top one
/// over to the back of the pile; a tap opens it. A myth is a single claim to
/// sit with, which a row of eight small cards never let it be.
class MythDeck extends StatefulWidget {
  const MythDeck({
    super.key,
    required this.pills,
    required this.isRead,
    required this.onOpen,
    this.onShown,
  });

  final List<Pill> pills;
  final bool Function(Pill) isRead;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  State<MythDeck> createState() => _MythDeckState();
}

class _MythDeckState extends State<MythDeck>
    with SingleTickerProviderStateMixin {
  int _at = 0;
  double _dx = 0;

  late final AnimationController _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  double _from = 0;
  double _to = 0;
  bool _turning = false;

  @override
  void initState() {
    super.initState();
    _fly.addListener(() {
      setState(() {
        _dx = _from + (_to - _from) * Curves.easeOutCubic.transform(_fly.value);
      });
    });
    _fly.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      setState(() {
        if (_turning) _at = (_at + 1) % widget.pills.length;
        _turning = false;
        _dx = 0;
      });
    });
  }

  @override
  void dispose() {
    _fly.dispose();
    super.dispose();
  }

  void _settle(double to, {required bool turn}) {
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() {
        if (turn) _at = (_at + 1) % widget.pills.length;
        _dx = 0;
      });
      return;
    }
    _from = _dx;
    _to = to;
    _turning = turn;
    _fly.forward(from: 0);
  }

  void _dragEnd(DragEndDetails d) {
    final double v = d.primaryVelocity ?? 0;
    if (_dx.abs() > 70 || v.abs() > 700) {
      final double dir = _dx != 0 ? _dx.sign : v.sign;
      _settle(dir * 520, turn: true);
    } else {
      _settle(0, turn: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Pill> pills = widget.pills;
    final int n = pills.length;
    final Pill top = pills[_at % n];
    final Pill next = pills[(_at + 1) % n];
    final Pill after = pills[(_at + 2) % n];
    widget.onShown?.call(top);

    Widget back(Color color, double dy, double scale) => Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: 220,
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..translateByDouble(0, dy, 0, 1)
          ..scaleByDouble(scale, scale, 1, 1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );

    // The pile closes up as the top card goes: the one under it rises
    // towards where the top one was.
    final double lift = (_dx.abs() / 260).clamp(0, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: 240,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (n > 2) back(shade(after.color, 0.62), 20, 0.88),
                if (n > 1)
                  back(
                    shade(next.color, 0.84 + 0.16 * lift),
                    10 - 10 * lift,
                    0.94 + 0.06 * lift,
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 220,
                  child: GestureDetector(
                    key: ValueKey('explore-${top.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onOpen(pills, top),
                    onHorizontalDragUpdate: n < 2
                        ? null
                        : (d) => setState(() => _dx += d.delta.dx),
                    onHorizontalDragEnd: n < 2 ? null : _dragEnd,
                    child: Transform.translate(
                      offset: Offset(_dx, 0),
                      child: Transform.rotate(
                        angle: _dx / 18 * math.pi / 180,
                        child: _Face(pill: top, read: widget.isRead(top)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.mythDeckHint(_at % n + 1, n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    height: 1,
                    color: context.p.ink.withValues(alpha: 0.42),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              for (int i = 0; i < math.min(n, 8); i++) ...[
                if (i > 0) const SizedBox(width: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: i == _at % n ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: context.p.ink.withValues(
                      alpha: i == _at % n ? 1 : 0.22,
                    ),
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

class _Face extends StatelessWidget {
  const _Face({required this.pill, required this.read});

  final Pill pill;
  final bool read;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: pill.color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.p.isDark ? 0.5 : 0.18,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHead(
            pill: pill,
            trailing: read ? ReadMark(pill: pill) : null,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: CardQuestion(
                text: pill.question,
                color: pill.ink,
                min: 14,
                max: 23,
                height: 1.12,
                tracking: -0.034,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
