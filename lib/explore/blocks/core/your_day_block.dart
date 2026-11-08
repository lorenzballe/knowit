/// The reader's day, at the top of Explore: how many of today's five are
/// read and how many are left, a bar for each of the five, the week from
/// Monday to Sunday with the days finished lit, and the streak. A tap goes
/// to Today, where the five are.
///
/// Explore is where a reader goes once the day is read, or instead of
/// reading it; the panel is what keeps the day in sight from there, so the
/// five are never more than a tap away and a streak is never lost by
/// somebody who forgot it was running.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../data/pills_repository.dart'
    show dateKey, dayShift, kPillsPerDay;
import '../../../l10n/l10n.dart';
import '../../../state/app_state.dart';
import '../../../theme.dart';
import '../../explore_block.dart';
import 'layout.dart';

/// The orange a finished day and the streak's flame are lit in: Food's on
/// the wheel, the warmest colour the app has, and the one the streak has
/// worn in every design of it.
const Color kStreakOrange = Color(0xFFFF7A1A);

/// The week the panel shows: Monday to Sunday of the week [today] falls in,
/// each day with whether the reader finished it.
List<({DateTime day, bool done})> weekOf(AppState app, DateTime today) {
  final Set<String> done = app.completedDates.toSet();
  final DateTime monday = dayShift(today, 1 - today.weekday);
  return [
    for (int i = 0; i < 7; i++)
      (
        day: dayShift(monday, i),
        done: done.contains(dateKey(dayShift(monday, i))),
      ),
  ];
}

/// The block: see the library's own words. Not drawn while Explore is
/// narrowed to a subject, which is a question about that subject and not
/// about the reader's day, nor before a day has been dealt.
class YourDayBlock extends ExploreBlock with SectionLayout {
  const YourDayBlock();

  @override
  String get name => 'your-day';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final AppState app = host.app;
    if (host.subject != null || app.todaysDeck.isEmpty) return null;
    // A second set dealt after the five does not make the day longer: the
    // panel counts the five.
    final int read = app.dayClosed
        ? kPillsPerDay
        : app.todayIndex.clamp(0, kPillsPerDay);
    return SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: DayPanel(
          read: read,
          of: kPillsPerDay,
          streak: app.liveStreak,
          week: weekOf(app, app.today),
          today: app.today,
          onTap: host.openToday,
        ),
      ),
    );
  }
}

/// The panel itself, given what it shows.
class DayPanel extends StatelessWidget {
  const DayPanel({
    super.key,
    required this.read,
    required this.of,
    required this.streak,
    required this.week,
    required this.today,
    required this.onTap,
  });

  /// How many of the day's cards are read, of how many.
  final int read;
  final int of;

  /// The streak as it stands; nothing is said of one at 0.
  final int streak;

  /// Monday to Sunday, each day with whether it was finished.
  final List<({DateTime day, bool done})> week;

  /// Which of the week's days is today.
  final DateTime today;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final int left = of - read;
    final Color ink = context.p.ink;
    return Semantics(
      button: true,
      hint: l.exploreDayOpen,
      child: GestureDetector(
        key: const ValueKey('your-day'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
          decoration: BoxDecoration(
            color: context.p.surfaceRaised,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: l.exploreDayRead(read, of)),
                          TextSpan(
                            text:
                                ' · ${left > 0 ? l.exploreDayLeft(left) : l.exploreDayDone}',
                            style: TextStyle(
                              color: ink.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      key: const ValueKey('your-day-count'),
                      style: AppText.body(
                        size: 14,
                        weight: FontWeight.w600,
                        height: 1.25,
                        color: ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: ink.withValues(alpha: 0.35),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  for (int i = 0; i < of; i++) ...[
                    if (i > 0) const SizedBox(width: 5),
                    Expanded(
                      child: Container(
                        key: ValueKey(
                          'your-day-bar-$i-${i < read ? 'read' : 'unread'}',
                        ),
                        height: 6,
                        decoration: BoxDecoration(
                          color: i < read ? ink : ink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 15),
              // The week, and the streak it adds up to at its end: the
              // count above keeps the whole width for its words.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Week(week: week, today: today),
                  ),
                  if (streak > 0) ...[
                    const SizedBox(width: 10),
                    StreakChip(
                      streak: streak,
                      key: const ValueKey('your-day-streak'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Monday to Sunday, a dot a day: lit orange once finished, ringed for
/// today while it is not, faint for the days still to come.
class _Week extends StatelessWidget {
  const _Week({required this.week, required this.today});

  final List<({DateTime day, bool done})> week;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final DateFormat letter = DateFormat('EEEEE', locale);
    final String todayKey = dateKey(today);
    final Color ink = context.p.ink;
    return Row(
      children: [
        for (final (:day, :done) in week)
          Expanded(
            child: Builder(
              builder: (context) {
                final bool isToday = dateKey(day) == todayKey;
                final bool ahead = !isToday && day.isAfter(today);
                return Column(
                  key: ValueKey(
                    'your-day-${day.weekday}-${done ? 'done' : 'open'}'
                    '${isToday ? '-today' : ''}',
                  ),
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? kStreakOrange
                            : ink.withValues(alpha: ahead ? 0.04 : 0.08),
                        border: isToday && !done
                            ? Border.all(
                                color: ink.withValues(alpha: 0.7),
                                width: 1.6,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: done
                          ? const Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: Color(0xFF1A0B00),
                            )
                          : null,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      letter.format(day),
                      maxLines: 1,
                      style: AppText.label(
                        size: 10,
                        spacing: 0.4,
                        color: isToday
                            ? ink
                            : ink.withValues(alpha: ahead ? 0.3 : 0.5),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

/// The streak as a pill: an orange flame and the days, on the panel's dark.
/// The same chip stands beside Explore's search, so the streak reads the
/// same wherever it is said.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.streak, this.height = 30});

  final int streak;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.fromLTRB(8, 4, 11, 4),
      decoration: BoxDecoration(
        color: context.p.ink.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 16,
            color: kStreakOrange,
          ),
          const SizedBox(width: 4),
          Text(
            context.l10n.streakDays(streak),
            maxLines: 1,
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w600,
              height: 1.1,
              color: context.p.ink,
            ),
          ),
        ],
      ),
    );
  }
}
