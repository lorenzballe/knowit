import 'package:flutter/material.dart';

import '../../analytics.dart';
import '../../data/explore_mix.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import 'parts.dart';

/// Through time — artboard 141c's ruler, on the ages the bank's cards are
/// set in.
///
/// Drag along the ruler, or step with the arrows, and the shelf under it
/// turns to that age: the ancient world, the Middle Ages, the centuries
/// after, the last one, this one. The canvas ran its ruler back to the first
/// light; the bank tags the ages people lived in, so that is where this one
/// starts. The cards for an age are dealt afresh every day, and the ruler
/// opens on a different age each morning.
class ThroughTime extends StatefulWidget {
  const ThroughTime({
    super.key,
    required this.eras,
    required this.startAt,
    required this.isRead,
    required this.onOpen,
    this.onShown,
  });

  /// The cards for each age that has any, oldest first.
  final List<(String, List<Pill>)> eras;

  /// The age the ruler opens on.
  final int startAt;
  final bool Function(Pill) isRead;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  State<ThroughTime> createState() => _ThroughTimeState();
}

class _ThroughTimeState extends State<ThroughTime> {
  late int _at = widget.startAt.clamp(0, widget.eras.length - 1);

  void _go(int to) {
    final int next = to.clamp(0, widget.eras.length - 1);
    if (next == _at) return;
    Analytics.capture('explore era', {'era': widget.eras[next].$1});
    setState(() => _at = next);
  }

  (String, String) _names(BuildContext context, String era) {
    final l = context.l10n;
    return switch (era) {
      'ancient' => (l.eraAncient, l.eraAncientWhen),
      'medieval' => (l.eraMedieval, l.eraMedievalWhen),
      'early_modern' => (l.eraEarlyModern, l.eraEarlyModernWhen),
      'nineteenth' => (l.eraNineteenth, l.eraNineteenthWhen),
      'twentieth' => (l.eraTwentieth, l.eraTwentiethWhen),
      _ => (l.eraRecent, l.eraRecentWhen),
    };
  }

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    final int n = widget.eras.length;
    final (String era, List<Pill> cards) = widget.eras[_at];
    final (String name, String span) = _names(context, era);
    final List<Pill> shown = cards.take(2).toList();
    for (final p in shown) {
      widget.onShown?.call(p);
    }

    Widget arrow(IconData icon, int to, String key) {
      final bool live = to >= 0 && to < n;
      return Semantics(
        key: ValueKey(key),
        button: true,
        enabled: live,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: live ? () => _go(to) : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: live ? 1 : 0.3,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ink.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: ink),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.bottomLeft,
                    children: [...previous, ?current],
                  ),
                  child: Column(
                    key: ValueKey(era),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Kicker(name, color: ink.withValues(alpha: 0.5)),
                      const SizedBox(height: 7),
                      Text(
                        span,
                        style: AppText.display(
                          size: 32,
                          weight: FontWeight.w600,
                          height: 1.02,
                          spacing: -1,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              arrow(Icons.chevron_left_rounded, _at - 1, 'era-back'),
              const SizedBox(width: 6),
              arrow(Icons.chevron_right_rounded, _at + 1, 'era-on'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 29),
          child: _Ruler(stops: n, at: _at, onPick: _go),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                context.l10n.eraRulerOld,
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w600,
                  height: 1,
                  color: ink.withValues(alpha: 0.45),
                ),
              ),
              const Spacer(),
              Text(
                context.l10n.eraRulerNow,
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w600,
                  height: 1,
                  color: ink.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: SizedBox(
              key: ValueKey('era-cards-$era'),
              height: 236,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < shown.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: _eraCard(context, cards, shown[i])),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (cards.length > 2) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FlatButton(
                key: const ValueKey('era-more'),
                label: context.l10n.eraMore(cards.length - 2),
                background: ink.withValues(alpha: 0.08),
                foreground: ink,
                height: 36,
                size: 12.5,
                icon: Icon(Icons.layers_rounded, size: 15, color: ink),
                onTap: () => widget.onOpen(cards, cards[2]),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _eraCard(BuildContext context, List<Pill> cards, Pill p) {
    final String? year = questionYear(p);
    return CardTap(
      pill: p,
      onTap: () => widget.onOpen(cards, p),
      child: Container(
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
              trailing: widget.isRead(p) ? ReadMark(pill: p) : null,
            ),
            if (year != null) ...[
              const SizedBox(height: 10),
              Text(
                year,
                style: AppText.display(
                  size: 26,
                  weight: FontWeight.w600,
                  height: 1,
                  spacing: -0.8,
                  color: shade(p.color, 0.62),
                ),
              ),
            ],
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: CardQuestion(
                  text: p.question,
                  color: p.ink,
                  min: 10.5,
                  max: 16.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The ruler: a stop for every age, a line filled as far as the one chosen,
/// and a thumb that can be dragged from one to the next.
class _Ruler extends StatelessWidget {
  const _Ruler({required this.stops, required this.at, required this.onPick});

  final int stops;
  final int at;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return LayoutBuilder(
      builder: (context, box) {
        final double w = box.maxWidth;
        double x(int i) => stops < 2 ? 0 : w * i / (stops - 1);
        int nearest(double dx) =>
            stops < 2 ? 0 : (dx / w * (stops - 1)).round().clamp(0, stops - 1);
        return GestureDetector(
          key: const ValueKey('era-ruler'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => onPick(nearest(d.localPosition.dx)),
          onHorizontalDragUpdate: (d) => onPick(nearest(d.localPosition.dx)),
          child: SizedBox(
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = 0; i < stops; i++)
                  Positioned(
                    left: x(i) - 0.5,
                    top: 6,
                    width: 1,
                    height: 14,
                    child: ColoredBox(color: ink.withValues(alpha: 0.24)),
                  ),
                Positioned(
                  left: -9,
                  right: -9,
                  top: 28,
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ink.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  left: -9,
                  top: 28,
                  height: 4,
                  width: x(at) + 9,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                for (int i = 0; i < stops; i++)
                  Positioned(
                    left: x(i) - 4,
                    top: 26,
                    width: 8,
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= at ? ink : ink.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  left: x(at) - 11,
                  top: 19,
                  width: 22,
                  height: 22,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.p.surface,
                      border: Border.all(color: ink, width: 3),
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
