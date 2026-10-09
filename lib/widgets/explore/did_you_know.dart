import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../analytics.dart';
import '../../data/explore_mix.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../state/explore_play.dart';
import '../../theme.dart';
import 'parts.dart';

/// Did you know? — artboard 141b's pile.
///
/// The cards with nothing to answer, met one at a time: a tap turns one over
/// to the first lines of its answer, and a throw says what it was — right,
/// new to you; left, you knew it. The two buttons under the pile do the same
/// for a thumb that would rather tap, and count as they go. At the end, the
/// ones that were new, each a tap from its card.
///
/// A card judged is a card read: its answer has been seen.
class DidYouKnow extends StatefulWidget {
  const DidYouKnow({
    super.key,
    required this.pills,
    required this.onOpen,
    required this.onRead,
    this.onShown,
  });

  final List<Pill> pills;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill> onRead;
  final ValueChanged<Pill>? onShown;

  @override
  State<DidYouKnow> createState() => _DidYouKnowState();
}

class _DidYouKnowState extends State<DidYouKnow>
    with SingleTickerProviderStateMixin {
  bool _turned = false;
  double _dx = 0;

  late final AnimationController _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  double _from = 0;
  double _to = 0;
  bool? _judgingNew;

  Map<String, String> get _said {
    final Object? kept = ExplorePlay.instance['dyk'];
    if (kept is! Map) return {};
    return {
      for (final e in kept.entries)
        if (e.value is String) '${e.key}': e.value as String,
    };
  }

  @override
  void initState() {
    super.initState();
    _fly.addListener(() {
      setState(() {
        _dx = _from + (_to - _from) * Curves.easeIn.transform(_fly.value);
      });
    });
    _fly.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      final bool? judged = _judgingNew;
      _judgingNew = null;
      if (judged != null) _record(judged);
      setState(() => _dx = 0);
    });
  }

  @override
  void dispose() {
    _fly.dispose();
    super.dispose();
  }

  Pill? get _top {
    final said = _said;
    for (final p in widget.pills) {
      if (!said.containsKey(p.id)) return p;
    }
    return null;
  }

  void _record(bool isNew) {
    final Pill? p = _top;
    if (p == null) return;
    ExplorePlay.instance.put('dyk', {..._said, p.id: isNew ? 'n' : 'k'});
    widget.onRead(p);
    Analytics.capture('explore did you know', {'pill_id': p.id, 'new': isNew});
    setState(() => _turned = false);
  }

  void _judge(bool isNew) {
    if (_top == null || _fly.isAnimating) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _record(isNew);
      return;
    }
    _judgingNew = isNew;
    _from = _dx;
    _to = isNew ? 520 : -520;
    _fly.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ExplorePlay.instance,
      builder: (context, _) {
        final said = _said;
        final int done = widget.pills
            .where((p) => said.containsKey(p.id))
            .length;
        final Pill? top = _top;
        final Color ink = context.p.ink;
        final l = context.l10n;
        return Column(
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
                          l.didYouKnow,
                          style: AppText.body(
                            size: 16,
                            weight: FontWeight.w600,
                            height: 1,
                            spacing: -0.2,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l.didYouKnowLine,
                          style: AppText.body(
                            size: 12,
                            height: 1.3,
                            color: ink.withValues(alpha: 0.42),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l.nOfM(
                      math.min(done + 1, widget.pills.length),
                      widget.pills.length,
                    ),
                    style: AppText.body(
                      size: 12,
                      weight: FontWeight.w600,
                      height: 1,
                      color: ink.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: top == null
                  ? _summary(context, said)
                  : _pile(context, top),
            ),
          ],
        );
      },
    );
  }

  Widget _pile(BuildContext context, Pill top) {
    widget.onShown?.call(top);
    final said = _said;
    final List<Pill> rest = [
      for (final p in widget.pills)
        if (!said.containsKey(p.id) && p.id != top.id) p,
    ];
    final int knew = said.values.where((v) => v == 'k').length;
    final int fresh = said.values.where((v) => v == 'n').length;
    final l = context.l10n;

    Widget behind(Pill p, double dy, double scale) => Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: 300,
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..translateByDouble(0, dy, 0, 1)
          ..scaleByDouble(scale, scale, 1, 1),
        child: Opacity(
          opacity: 0.55,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.color,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );

    final double toNew = (_dx / 90).clamp(0, 1);
    final double toKnew = (-_dx / 90).clamp(0, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 326,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (rest.length > 1) behind(rest[1], 24, 0.9),
              if (rest.isNotEmpty) behind(rest[0], 12, 0.95),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 300,
                child: GestureDetector(
                  key: ValueKey('dyk-${top.id}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _turned = !_turned),
                  onHorizontalDragUpdate: (d) =>
                      setState(() => _dx += d.delta.dx),
                  onHorizontalDragEnd: (d) {
                    final double v = d.primaryVelocity ?? 0;
                    if (_dx.abs() > 90 || v.abs() > 800) {
                      _judge((_dx != 0 ? _dx : v) > 0);
                    } else {
                      setState(() => _dx = 0);
                    }
                  },
                  child: Transform.translate(
                    offset: Offset(_dx, 0),
                    child: Transform.rotate(
                      angle: _dx / 18 * math.pi / 180,
                      child: _face(context, top, toNew, toKnew),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _countButton(
                context,
                key: 'dyk-knew',
                label: l.knewIt,
                count: knew,
                lit: false,
                onTap: () => _judge(false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _countButton(
                context,
                key: 'dyk-new',
                label: l.newToMe,
                count: fresh,
                lit: true,
                onTap: () => _judge(true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _face(BuildContext context, Pill p, double toNew, double toKnew) {
    final l = context.l10n;
    final TextStyle foot = AppText.label(
      size: 9,
      weight: FontWeight.w700,
      spacing: 1.2,
      color: subOn(p),
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.p.isDark ? 0.6 : 0.18,
            ),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardHead(pill: p),
              const SizedBox(height: 12),
              if (_turned) ...[
                Text(
                  p.question,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    size: 12.5,
                    weight: FontWeight.w600,
                    height: 1.3,
                    color: p.ink.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Expanded(
                child: CardQuestion(
                  key: ValueKey('dyk-face-${p.id}-$_turned'),
                  text: _turned ? firstLines(p.answer) : p.question,
                  color: p.ink,
                  min: 14,
                  max: _turned ? 22 : 27,
                  height: 1.1,
                  tracking: -0.034,
                  alignment: Alignment.centerLeft,
                ),
              ),
              const SizedBox(height: 12),
              if (_turned)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('← ${upper(context, l.knewIt)}', style: foot),
                    Text('${upper(context, l.newToMe)} →', style: foot),
                  ],
                )
              else
                Text(upper(context, l.tapToTurn), style: foot),
            ],
          ),
          Positioned(
            left: -4,
            top: 34,
            child: Opacity(
              opacity: toNew,
              child: _stamp(
                context,
                upper(context, l.newToMe),
                winColor(context),
                const Color(0xFF111113),
                -0.14,
              ),
            ),
          ),
          Positioned(
            right: -4,
            top: 34,
            child: Opacity(
              opacity: toKnew,
              child: _stamp(
                context,
                upper(context, l.knewIt),
                const Color(0xFF111113),
                const Color(0xFFF1EFEA),
                0.14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stamp(
    BuildContext context,
    String text,
    Color bg,
    Color fg,
    double angle,
  ) => Transform.rotate(
    angle: angle,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: AppText.label(
          size: 13,
          weight: FontWeight.w800,
          spacing: 1,
          height: 1,
          color: fg,
        ),
      ),
    ),
  );

  Widget _countButton(
    BuildContext context, {
    required String key,
    required String label,
    required int count,
    required bool lit,
    required VoidCallback onTap,
  }) {
    final Color bg = lit
        ? context.p.inverse
        : context.p.ink.withValues(alpha: 0.08);
    final Color fg = lit ? context.p.onInverse : context.p.ink;
    return Semantics(
      key: ValueKey(key),
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    size: 14,
                    weight: FontWeight.w700,
                    height: 1,
                    color: fg,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Container(
                constraints: const BoxConstraints(minWidth: 24),
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: lit ? context.p.surface : fg.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w700,
                    height: 1,
                    color: lit ? context.p.ink : fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary(BuildContext context, Map<String, String> said) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final List<Pill> fresh = [
      for (final p in widget.pills)
        if (said[p.id] == 'n') p,
    ];
    final int knew = widget.pills.length - fresh.length;
    return Container(
      key: const ValueKey('dyk-done'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.dykNew(fresh.length),
            style: AppText.display(
              size: 34,
              weight: FontWeight.w600,
              height: 1.05,
              spacing: -1,
              color: ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.dykKnew(knew),
            style: AppText.body(
              size: 13,
              weight: FontWeight.w600,
              height: 1.3,
              color: ink.withValues(alpha: 0.55),
            ),
          ),
          for (final p in fresh) ...[
            const SizedBox(height: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onOpen(fresh, p),
              child: Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: ink.withValues(alpha: 0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: p.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.question,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          size: 13,
                          weight: FontWeight.w600,
                          height: 1.3,
                          color: ink,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: ink.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FlatButton(
            key: const ValueKey('dyk-again'),
            label: l.dykAgain,
            background: context.p.inverse,
            foreground: context.p.onInverse,
            height: 40,
            size: 13,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            onTap: () {
              ExplorePlay.instance.put('dyk', null);
              setState(() => _turned = false);
            },
          ),
        ],
      ),
    );
  }
}
