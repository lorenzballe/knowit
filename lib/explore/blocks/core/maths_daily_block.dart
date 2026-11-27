import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../analytics.dart';
import '../../../data/pill_bank.dart';
import '../../../data/pills_repository.dart' show dateKey;
import '../../../data/topics.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../state/app_state.dart';
import '../../../theme.dart';
import '../../../utils/share_text.dart';
import '../../../widgets/deeper_sheet.dart' show GoDeeper, cardAiOn;
import '../../explore_block.dart';
import 'layout.dart';
import '../../../l10n/dates.dart';

/// The problem of the day, on the Maths page of Explore: one problem a day
/// from the maths cards that ask for an answer, the same for everyone, so a
/// result can be compared and sent like a puzzle's; solved, it says so,
/// counts the days in a row, and offers the result to send.
///
/// Shown only while Explore is narrowed to Maths: that is where a reader who
/// wants a daily problem goes looking for one.
class MathsDailyBlock extends ExploreBlock with SectionLayout {
  const MathsDailyBlock();

  @override
  String get name => 'maths-daily';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    if (host.subject != kTopics['maths']?.name) return null;
    final AppState app = host.app;
    final Pill? pill = mathsProblemOf(app, app.today);
    if (pill == null) return null;
    return SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _Problem(
          host: host,
          section: section,
          pill: pill,
        ),
      ),
    );
  }
}

/// The ideas a problem of one of several options is a problem for: working
/// something out, or reasoning with chances and growth. A true-or-false
/// about a chart is a good card, but not a problem.
const Set<Principle> _worked = {
  Principle.computation,
  Principle.estimation,
  Principle.exponential,
  Principle.independence,
  Principle.conditional,
  Principle.simpson,
};

/// The problems a day can bring: the maths cards with something to work
/// out — a number, an estimate, or one of several options when finding it
/// takes working — in an order of their own that stays the same, so
/// neighbouring days do not bring neighbouring cards.
List<Pill> mathsProblems() {
  final String? maths = kTopics['maths']?.name;
  final List<Pill> pool = [
    for (final Pill p in PillBank.cards)
      if (p.topic == maths &&
          (p.challenge is TypeNumber ||
              p.challenge is Estimate ||
              (p.challenge is PickOne && _worked.contains(p.principle))))
        p,
  ];
  int mix(String id) {
    // FNV-1a: the same on every phone and every run.
    var h = 0x811c9dc5;
    for (final int c in id.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h;
  }

  pool.sort((a, b) => mix(a.id).compareTo(mix(b.id)));
  return pool;
}

/// The day's problem for this reader: the day's card in the shared order, or
/// the next one along that they have not answered before, so nobody is set a
/// problem twice. The one they answered on [day] itself stays the day's.
Pill? mathsProblemOf(AppState app, DateTime day) {
  final List<Pill> pool = mathsProblems();
  if (pool.isEmpty) return null;
  final String key = dateKey(day);
  final int start =
      DateTime(day.year, day.month, day.day).difference(DateTime(2026)).inDays %
      pool.length;
  final Set<String> today = {
    for (final Judgement j in app.judgements)
      if (j.on == key && j.pillId != null) j.pillId!,
  };
  for (var i = 0; i < pool.length; i++) {
    final Pill p = pool[(start + i) % pool.length];
    if (today.contains(p.id)) return p;
    if (!app.answers.containsKey(p.id)) return p;
  }
  return pool[start];
}

/// The days in a row, up to [day], with a problem of the day answered:
/// counted from yesterday while today's is still open.
int mathsStreak(AppState app, DateTime day) {
  final Set<String> problems = {for (final Pill p in mathsProblems()) p.id};
  final Set<String> days = {
    for (final Judgement j in app.judgements)
      if (j.on != null && problems.contains(j.pillId)) j.on!,
  };
  DateTime d = DateTime(day.year, day.month, day.day);
  if (!days.contains(dateKey(d))) d = DateTime(d.year, d.month, d.day - 1);
  var n = 0;
  while (days.contains(dateKey(d))) {
    n++;
    d = DateTime(d.year, d.month, d.day - 1);
  }
  return n;
}

class _Problem extends StatelessWidget {
  const _Problem({
    required this.host,
    required this.section,
    required this.pill,
  });

  final ExploreHost host;
  final ExploreSection section;
  final Pill pill;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final AppState app = host.app;
    final String key = dateKey(app.today);
    Judgement? done;
    for (final Judgement j in app.judgements) {
      if (j.pillId == pill.id && j.on == key) done = j;
    }
    final int streak = mathsStreak(app, app.today);
    final Color jade = kTopics['maths']?.color ?? const Color(0xFF0E9A70);
    final Color deep = Color.lerp(jade, Colors.black, 0.45)!;
    String date() {
      try {
        return formatDay(DateFormat.MMMMd(host.language), app.today);
      } catch (_) {
        return DateFormat.MMMMd('en').format(app.today);
      }
    }

    final TextStyle small = AppText.body(
      size: 12,
      weight: FontWeight.w800,
      spacing: 1.2,
      color: Colors.white.withValues(alpha: 0.75),
    );
    return Semantics(
      button: done == null,
      child: GestureDetector(
        key: const ValueKey('maths-daily'),
        behavior: HitTestBehavior.opaque,
        onTap: done != null
            ? null
            : () {
                Analytics.capture('maths daily opened', {
                  'pill_id': pill.id,
                  'streak': streak,
                });
                host.open(section, [pill], pill);
              },
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [jade, deep],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(date().toUpperCase(), style: small)),
                  if (streak > 0)
                    Text(
                      '🔥 ${l.mathsDailyStreak(streak)}',
                      key: const ValueKey('maths-daily-streak'),
                      style: small,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                pill.question,
                style: AppText.display(
                  size: 21,
                  weight: FontWeight.w600,
                  height: 1.22,
                  spacing: -0.4,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              if (done == null)
                _Pillish(
                  label: l.mathsDailySolve,
                  icon: Icons.calculate_rounded,
                  ink: deep,
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            done.correct
                                ? '✓  ${l.mathsDailySolved}'
                                : l.mathsDailyMissed,
                            key: const ValueKey('maths-daily-done'),
                            style: AppText.body(
                              size: 16,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.mathsDailyTomorrow,
                            style: AppText.body(
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                          // Another like it, made on the spot from the
                          // same idea (Go deeper's new case), where the
                          // answers by Claude are on.
                          if (cardAiOn(app, host.language)) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              key: const ValueKey('maths-daily-another'),
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Analytics.capture('maths daily another', {
                                  'pill_id': pill.id,
                                  'is_plus': app.isPlus,
                                });
                                GoDeeper.open?.call(context, pill);
                              },
                              child: Text(
                                '${l.mathsDailyAnother} →',
                                style: AppText.body(
                                  size: 13.5,
                                  weight: FontWeight.w800,
                                  color: Colors.white,
                                ).copyWith(
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white54,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    GestureDetector(
                      key: const ValueKey('maths-daily-share'),
                      onTap: () {
                        Analytics.capture('maths daily shared', {
                          'right': done!.correct,
                          'streak': streak,
                        });
                        shareText(
                          [
                            'Astute · ${section.title(host.language) ?? ''} · ${date()}',
                            done.correct
                                ? '✅ ${l.mathsDailySolved}'
                                : '❌ ${l.mathsDailyMissed}',
                            if (streak > 1) '🔥 ${l.mathsDailyStreak(streak)}',
                            'astutetheapp.com',
                          ].join('\n'),
                        );
                      },
                      child: _Pillish(
                        label: l.storyShare,
                        icon: Icons.ios_share_rounded,
                        ink: deep,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A white pill with a label: the block's one control.
class _Pillish extends StatelessWidget {
  const _Pillish({required this.label, required this.icon, required this.ink});

  final String label;
  final IconData icon;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: ink),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppText.body(size: 14, weight: FontWeight.w800, color: ink),
        ),
      ],
    ),
  );
}
