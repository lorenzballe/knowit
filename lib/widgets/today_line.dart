/// The line at the top of Today, over the day's cards, on the mornings
/// there is something of the reader's own to say before the first card.
///
/// On the morning after a freeze kept the streak, that the day missed was
/// covered (`streak.told`): before, it was said only on the finished day's
/// shelf, after the five, and a reader who came back to a streak still
/// standing was never told why. And on a new reader's second and third
/// days (`opening.dayLine`), which day it is, how the day before went in
/// its own numbers — right of those answered, and how sure the reader said
/// they were — and, when there is one, the subject met for the first time
/// today: the second day had opened exactly as the first, with nothing new
/// said. Nothing here is made up: a day before with no question to count
/// says it was read, and "yesterday" is only said of yesterday.
///
/// Said in the muted ink under the header, all day long, so the deck below
/// keeps one size through the day; it comes in with a short rise, and
/// stands still for a reader who asked for less motion.
library;

import 'package:flutter/material.dart';

import '../data/first_days.dart' show kOpeningDays;
import '../data/pills_repository.dart' show dateKey, dayShift;
import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// What Today says above the day's cards, or null when it says nothing:
/// [lead] said first, in the ink, and [text] after it.
({String? lead, String text})? todayLineOf(BuildContext context, AppState app) {
  final l = context.l10n;
  if (app.streakToldOn && app.streakWasFrozen) {
    return (lead: null, text: l.freezeSavedLine(app.frozeDays));
  }
  if (!app.dayLineOn || !app.firstDays) return null;
  // The opening's second and third days, counted by the days finished
  // before them, the day before among them.
  final int before = app.dayNumberOf(app.today);
  if (before < 1 || before >= kOpeningDays) return null;
  final String yesterday = dateKey(dayShift(app.today, -1));
  if (!app.completedDates.contains(yesterday)) return null;
  final ({int asked, int right, int? sure})? n = app.numbersOn(yesterday);
  final String how = switch (n) {
    null => l.todayLineRead,
    (asked: final int asked, right: final int right, sure: final int sure) =>
      l.elided(l.todayLineSure(right, asked, sure)),
    (asked: final int asked, right: final int right, sure: null) =>
      l.todayLineRight(right, asked),
  };
  final List<String> first = app.firstSubjectsToday;
  final String text = first.isEmpty
      ? how
      : '$how ${l.todayLineFirstSubject(l.subjectOf(first.first))}';
  return (
    lead: '${l.dayTitle(app.dayNumber)}${_stop(l.localeName)}',
    text: text,
  );
}

/// The full stop after the day's name, as the reader's script writes it.
String _stop(String locale) =>
    locale.startsWith('ja') || locale.startsWith('zh') ? '。' : '.';

/// The line, as Today sets it under its header.
class TodayLine extends StatelessWidget {
  const TodayLine({super.key, this.lead, required this.text});

  /// Said first, in the ink: which day this is.
  final String? lead;
  final String text;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    final String? lead = this.lead;
    final bool joined = lead != null && (lead.endsWith('。') || text.isEmpty);
    return TweenAnimationBuilder<double>(
      key: const ValueKey('today-line'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: still ? 0 : 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 6 * (1 - t)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text.rich(
          TextSpan(
            children: [
              if (lead != null)
                TextSpan(
                  text: joined ? lead : '$lead ',
                  style: AppText.body(
                    size: 13.5,
                    weight: FontWeight.w700,
                    height: 1.35,
                    color: context.p.ink,
                  ),
                ),
              TextSpan(text: text),
            ],
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppText.body(
            size: 13.5,
            weight: FontWeight.w500,
            height: 1.35,
            color: context.p.inkMuted,
          ),
        ),
      ),
    );
  }
}
