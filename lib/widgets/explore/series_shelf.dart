import 'package:flutter/material.dart';

import '../../data/explore_mix.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import '../subject_icon.dart';

/// In a few cards — artboard 140d's series.
///
/// Some things take more than one card: odds that lie in four different
/// costumes, why a study can mislead, the history everybody half remembers.
/// Each series is a tile with its cards fanned at the top, its name, how
/// long it takes, and its questions in the order they are met, easiest
/// first. A tap opens the run from the start.
class SeriesRow extends StatelessWidget {
  const SeriesRow({
    super.key,
    required this.series,
    required this.onOpen,
    this.onShown,
  });

  final List<Series> series;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  static String title(BuildContext context, Series s) {
    final l = context.l10n;
    return switch (s.kind) {
      SeriesKind.odds => l.seriesOdds,
      SeriesKind.studies => l.seriesStudies,
      SeriesKind.growth => l.seriesGrowth,
      SeriesKind.anchors => l.seriesAnchors,
      SeriesKind.retold => l.seriesRetold,
      SeriesKind.strand => l.seriesStrand(s.strand),
    };
  }

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return SizedBox(
      height: 292,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        itemCount: series.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final Series s = series[i];
          for (final p in s.cards) {
            onShown?.call(p);
          }
          final int minutes = s.cards.fold(0, (sum, p) => sum + minutesFor(p));
          return GestureDetector(
            key: ValueKey('series-${s.key}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => onOpen(s.cards, s.cards.first),
            child: Container(
              width: 286,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ink.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 76,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (int k = 0; k < s.cards.length; k++)
                          Positioned(
                            left: k * 16.0,
                            top: k * 2.0,
                            child: Transform.rotate(
                              angle: (k * 4 - 5) * 3.14159 / 180,
                              child: Container(
                                width: 52,
                                height: 68,
                                padding: const EdgeInsets.all(8),
                                alignment: Alignment.topLeft,
                                decoration: BoxDecoration(
                                  color: s.cards[k].color,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: context.p.isDark ? 0.5 : 0.16,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(-4, 2),
                                    ),
                                  ],
                                ),
                                child: SubjectIcon(
                                  subject: s.cards[k].topic,
                                  size: 12,
                                  stroke: 2.4,
                                  ink: s.cards[k].ink,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title(context, s),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(
                      size: 19,
                      weight: FontWeight.w600,
                      height: 1.15,
                      spacing: -0.4,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    context.l10n.seriesMeta(s.cards.length, minutes),
                    style: AppText.body(
                      size: 11.5,
                      weight: FontWeight.w600,
                      height: 1,
                      color: ink.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (int k = 0; k < s.cards.length; k++) ...[
                    if (k > 0) const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: s.cards[k].color,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${k + 1}',
                            style: AppText.body(
                              size: 10,
                              weight: FontWeight.w700,
                              height: 1,
                              color: s.cards[k].ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            s.cards[k].question,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              size: 12,
                              weight: FontWeight.w500,
                              height: 1.3,
                              color: ink.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
