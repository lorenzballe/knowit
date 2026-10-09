import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/explore_mix.dart';
import '../../data/themed_shelves.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import '../subject_icon.dart';
import 'parts.dart';

/// Today's edition — artboard 141f, the front page.
///
/// The day laid out the way a paper lays out its front: a masthead, a lead
/// with its standfirst, two columns, the numbers, a correction and a puzzle.
/// It is the same page for everybody who opens the app today, read or not,
/// and it says so under the masthead, which is the one claim it makes.
class FrontPageView extends StatelessWidget {
  const FrontPageView({
    super.key,
    required this.page,
    required this.onOpen,
    this.onShown,
  });

  final FrontPage page;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  String _date(BuildContext context) {
    final DateTime now = DateTime.now();
    String out;
    try {
      out = DateFormat.MMMMEEEEd(Localizations.localeOf(context).toString())
          .format(now);
    } catch (_) {
      out = DateFormat.MMMMEEEEd('en').format(now);
    }
    return upper(context, out);
  }

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    final l = context.l10n;
    final List<Pill> all = page.cards;
    for (final p in all) {
      onShown?.call(p);
    }
    final Pill lead = page.lead;
    final TextStyle caps = AppText.label(
      size: 9.5,
      weight: FontWeight.w700,
      spacing: 1.3,
      color: ink.withValues(alpha: 0.5),
    );
    final BorderSide rule = BorderSide(color: ink.withValues(alpha: 0.14));

    Widget open(Pill p, Widget child) => GestureDetector(
      key: ValueKey('front-${p.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => onOpen(all, p),
      child: child,
    );

    Widget dotted(Pill p) => Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            upper(context, p.topic),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(
              size: 9,
              weight: FontWeight.w700,
              spacing: 1.2,
              color: ink.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );

    return Padding(
      key: const ValueKey('front-page'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_date(context), textAlign: TextAlign.center, style: caps),
          const SizedBox(height: 10),
          Text(
            l.theAstute,
            textAlign: TextAlign.center,
            style: AppText.display(
              size: 46,
              weight: FontWeight.w600,
              height: 1,
              spacing: -1.8,
              color: ink,
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 2, color: ink),
          const SizedBox(height: 3),
          Container(height: 1, color: ink),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(upper(context, l.todaysEdition), style: caps),
              ),
              Text(upper(context, l.sameForEveryoneCaps), style: caps),
            ],
          ),
          const SizedBox(height: 18),
          open(
            lead,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: lead.color,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned(
                        right: -34,
                        bottom: -60,
                        child: SubjectIcon(
                          subject: lead.topic,
                          size: 230,
                          stroke: 2.2,
                          ink: shade(lead.color, 0.84),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        top: 16,
                        right: 16,
                        child: CardHead(
                          pill: lead,
                          label: '${lead.topic} · ${l.theLead}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  lead.question,
                  style: AppText.display(
                    size: 21,
                    weight: FontWeight.w600,
                    height: 1.1,
                    spacing: -0.63,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lead.barMove,
                  style: AppText.body(
                    size: 13.5,
                    weight: FontWeight.w500,
                    height: 1.45,
                    color: ink.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          if (page.columns.length == 2) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(border: Border(top: rule)),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < 2; i++) ...[
                      if (i > 0) ...[
                        const SizedBox(width: 14),
                        Container(width: 1, color: ink.withValues(alpha: 0.14)),
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        child: open(
                          page.columns[i],
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              dotted(page.columns[i]),
                              const SizedBox(height: 8),
                              Text(
                                page.columns[i].question,
                                style: AppText.display(
                                  size: 16.5,
                                  weight: FontWeight.w600,
                                  height: 1.15,
                                  spacing: -0.41,
                                  color: ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (page.numbers.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(border: Border(top: rule)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(upper(context, l.inNumbers), style: caps),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < page.numbers.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(
                          child: open(
                            page.numbers[i],
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: page.numbers[i].color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    shelfFigure(page.numbers[i]) ?? '',
                                    style: AppText.display(
                                      size: 24,
                                      weight: FontWeight.w600,
                                      height: 1,
                                      spacing: -0.6,
                                      color: ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  page.numbers[i].question,
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body(
                                    size: 11,
                                    weight: FontWeight.w500,
                                    height: 1.35,
                                    color: ink.withValues(alpha: 0.58),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (page.correction case final Pill fix) ...[
            const SizedBox(height: 18),
            open(
              fix,
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ink.withValues(alpha: 0.16)),
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
                            color: fix.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(upper(context, l.corrections), style: caps),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.themeMythsLine,
                      style: AppText.body(
                        size: 12,
                        weight: FontWeight.w500,
                        height: 1.35,
                        color: ink.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fix.question,
                      style: AppText.display(
                        size: 17,
                        weight: FontWeight.w600,
                        height: 1.22,
                        spacing: -0.3,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (page.puzzle case final Pill puzzle) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.p.inverse,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Kicker(
                    l.puzzleOfTheDay,
                    color: context.p.onInverse.withValues(alpha: 0.62),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    puzzle.question,
                    style: AppText.display(
                      size: 18,
                      weight: FontWeight.w600,
                      height: 1.2,
                      spacing: -0.4,
                      color: context.p.onInverse,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FlatButton(
                    key: ValueKey('front-${puzzle.id}'),
                    label: l.themeWorkItOut,
                    background: context.p.onInverse,
                    foreground: context.p.inverse,
                    onTap: () => onOpen(all, puzzle),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          Text(
            l.editionEnd,
            textAlign: TextAlign.center,
            style: AppText.display(
              size: 17,
              weight: FontWeight.w600,
              height: 1.2,
              spacing: -0.3,
              color: ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            l.editionTomorrow,
            textAlign: TextAlign.center,
            style: AppText.body(
              size: 12,
              height: 1.3,
              color: ink.withValues(alpha: 0.42),
            ),
          ),
        ],
      ),
    );
  }
}
