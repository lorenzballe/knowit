import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../state/progress.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'progress_text.dart';
import 'week_screen.dart';

/// The ladder as a trail: where the reader has been, where they stand, and
/// what is ahead — each stop with the day it was first reached.
///
/// One tap under the level on the journey, rather than the journey itself.
/// The page a reader opens every day is the numbers; this is the page they
/// open when they want to see how far the numbers have carried them.
class PathScreen extends StatelessWidget {
  const PathScreen({super.key, required this.app, required this.onBack});

  final AppState app;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    return Scaffold(
      backgroundColor: context.p.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
          children: [
            Row(
              children: [
                BackCircle(onPressed: onBack),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.thePath,
                    style: AppText.display(
                      size: 27,
                      weight: FontWeight.w600,
                      height: 1,
                      spacing: -0.8,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Trail(app: app),
            const SizedBox(height: 22),
            // The week is the same question at another distance.
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (routeContext) => WeekScreen(
                      app: app,
                      onBack: () => Navigator.of(routeContext).pop(),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      l.yourWeek,
                      style: AppText.body(
                        size: 14,
                        weight: FontWeight.w600,
                        color: context.p.link,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '→',
                      style: AppText.body(size: 14, color: context.p.link),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The rungs, one under the other, on a trail.
class _Trail extends StatelessWidget {
  const _Trail({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final standing = app.standing;
    final int at = standing.at;
    return Column(
      children: [
        for (var i = 0; i < kRungs.length; i++)
          _Stop(
            app: app,
            rung: kRungs[i],
            index: i,
            at: at,
            first: i == 0,
            last: i == kRungs.length - 1,
            standing: standing,
          ),
      ],
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({
    required this.app,
    required this.rung,
    required this.index,
    required this.at,
    required this.first,
    required this.last,
    required this.standing,
  });

  final AppState app;
  final Rung rung;
  final int index;
  final int at;
  final bool first;
  final bool last;
  final Standing standing;

  bool get reached => index <= at;
  bool get here => index == at;

  String? _reachedOn(BuildContext context) {
    final String? key = app.rungDates[rung.id];
    if (key == null) return null;
    final parts = key.split('-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.contains(null)) return null;
    final date = DateTime(parts[0]!, parts[1]!, parts[2]!);
    final String locale = Localizations.localeOf(context).toString();
    return context.l10n.reachedOn(DateFormat.MMMd(locale).format(date));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final Color faint = ink.withValues(alpha: 0.28);
    final String? when = reached ? _reachedOn(context) : null;
    final String? step = here ? stepText(context, standing) : null;
    final Rung? next = standing.next;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: CustomPaint(
              painter: _TrailPainter(
                ink: ink,
                reached: reached,
                here: here,
                first: first,
                last: last,
                nextReached: index + 1 <= at,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          rungName(context, rung),
                          key: ValueKey('stop-${rung.id}'),
                          style: AppText.display(
                            size: here ? 21 : 17,
                            weight: FontWeight.w600,
                            spacing: -0.4,
                            color: reached ? ink : faint,
                          ),
                        ),
                      ),
                      if (here)
                        Text(
                          l.youAreHere,
                          style: AppText.label(
                            size: 10,
                            weight: FontWeight.w700,
                            spacing: 1.2,
                            color: ink.withValues(alpha: 0.5),
                          ),
                        )
                      else if (when != null)
                        Text(
                          when,
                          style: AppText.body(
                            size: 12,
                            color: ink.withValues(alpha: 0.45),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rungClaim(context, rung),
                    style: AppText.body(
                      size: 13.5,
                      height: 1.4,
                      color: reached ? ink.withValues(alpha: 0.65) : faint,
                    ),
                  ),
                  if (here && next != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 6,
                        child: Stack(
                          children: [
                            Container(color: ink.withValues(alpha: 0.09)),
                            FractionallySizedBox(
                              widthFactor: standing.toNext.clamp(0.02, 1.0),
                              child: Container(color: ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step == null
                          ? l.nextRung(rungName(context, next))
                          : l.stepThenRung(step, rungName(context, next)),
                      style: AppText.body(
                        size: 13,
                        weight: FontWeight.w500,
                        height: 1.35,
                        color: ink.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The dot and the line through it: solid where the reader has been, a
/// ring where they are, faint where they are going.
class _TrailPainter extends CustomPainter {
  const _TrailPainter({
    required this.ink,
    required this.reached,
    required this.here,
    required this.first,
    required this.last,
    required this.nextReached,
  });

  final Color ink;
  final bool reached;
  final bool here;
  final bool first;
  final bool last;
  final bool nextReached;

  @override
  void paint(Canvas canvas, Size size) {
    const double dotY = 11;
    final double x = size.width / 2;
    final line = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    if (!first) {
      line.color = ink.withValues(alpha: reached ? 0.55 : 0.14);
      canvas.drawLine(Offset(x, 0), Offset(x, dotY - 9), line);
    }
    if (!last) {
      line.color = ink.withValues(alpha: nextReached ? 0.55 : 0.14);
      canvas.drawLine(Offset(x, dotY + 9), Offset(x, size.height), line);
    }
    final dot = Paint()..style = PaintingStyle.fill;
    if (here) {
      dot.color = ink;
      canvas.drawCircle(Offset(x, dotY), 7, dot);
      dot.color = ink.withValues(alpha: 0.18);
      canvas.drawCircle(Offset(x, dotY), 12, dot);
    } else {
      dot.color = reached ? ink : ink.withValues(alpha: 0.18);
      canvas.drawCircle(Offset(x, dotY), 5, dot);
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.reached != reached ||
      old.here != here ||
      old.nextReached != nextReached ||
      old.ink != ink;
}
