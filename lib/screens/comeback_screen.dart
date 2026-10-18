import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/topics.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// Shown once when a streak has lapsed: glad the reader is here, what the
/// lapse did not take, and the way in.
///
/// It used to open on "You missed 3 days." at the size of a headline, and
/// count the cards that "went unread" — a bill, handed to the one reader
/// who came back. The week strip under the title already shows the gap;
/// nothing here needs to say it again.
class ComebackScreen extends StatelessWidget {
  final AppState app;
  final VoidCallback onContinue;

  const ComebackScreen({
    super.key,
    required this.app,
    required this.onContinue,
  });

  /// The topic the reader has kept the most pills from — the one they will
  /// miss noticing.
  String? get _favouriteTopic {
    if (app.savedIds.isEmpty) return null;
    final counts = <String, int>{};
    for (final id in app.savedIds) {
      final key = id.split('-').first;
      final style = kTopics[key];
      if (style != null) {
        counts[style.name] = (counts[style.name] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    final best = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return best.key;
  }

  @override
  Widget build(BuildContext context) {
    final favourite = _favouriteTopic;
    final int due = app.dueReviews.length;
    final bool kept = app.keptWeeks > 0 || favourite != null || due > 0;
    // Moving the reminder is offered only where there is one to move: a
    // reader the system will not let the app reach has no reminder, and a
    // button that moves it says otherwise.
    final bool reminder = app.notificationsOn && app.notificationsAllowed;
    final String other = app.notifyTime == '19:00' ? '08:30' : '19:00';

    return Scaffold(
      backgroundColor: context.p.surface,
      body: SafeArea(
        child: FlexPage(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A welcome, not a verdict: the counter is reset either way,
              // and the reader who came back is the one worth talking to.
              Eyebrow(context.l10n.welcomeBack),
              const SizedBox(height: 11),
              Text(
                context.l10n.comebackTitle,
                style: AppText.display(
                  size: 38,
                  weight: FontWeight.w700,
                  height: 1.05,
                  spacing: -1.5,
                  color: context.p.ink,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                context.l10n.bestStreakStillRecord(app.bestStreak),
                style: AppText.body(
                  size: 15,
                  height: 1.5,
                  color: context.p.inkMuted,
                ),
              ),
              const SizedBox(height: 24),
              WeekStrip(
                week: app.weekCompletion(),
                onColor: context.p.inverse,
                offColor: context.p.line,
              ),
              // What the lapse did not take, when there is any: five days
              // out of seven still keep a week, and those weeks are still
              // theirs; so is the subject they keep most; and a card they
              // got right, come back to see whether it stuck, is a better
              // reason to open the app than a broken counter is.
              if (kept) ...[
                const SizedBox(height: 24),
                PaperCard(
                  padding: const EdgeInsets.all(20),
                  radius: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow(context.l10n.comebackStillYours),
                      if (app.keptWeeks > 0) ...[
                        const SizedBox(height: 14),
                        _KeptLine(
                          color: context.p.link,
                          text: context.l10n.nWeeksKept(app.keptWeeks),
                        ),
                      ],
                      if (favourite != null) ...[
                        SizedBox(height: app.keptWeeks > 0 ? 11 : 14),
                        _KeptLine(
                          color: context.p.link,
                          text: context.l10n.stillMostKeptTopic(
                            context.l10n.subjectOf(favourite),
                          ),
                        ),
                      ],
                      if (due > 0) ...[
                        SizedBox(
                          height: app.keptWeeks > 0 || favourite != null
                              ? 11
                              : 14,
                        ),
                        _KeptLine(
                          color: context.p.ink,
                          text: context.l10n.cardsDueBackToday(due),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const Spacer(),
              PrimaryButton(
                label: context.l10n.startAgainWithTodaysFive,
                onPressed: onContinue,
              ),
              if (reminder) ...[
                const SizedBox(height: 4),
                QuietButton(
                  label: context.l10n.moveMyReminderTo(
                    clockTime(context, other),
                  ),
                  onPressed: () async {
                    await app.setNotifyTime(other);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.l10n.dailyNudgeMovedTo(
                            clockTime(context, other),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KeptLine extends StatelessWidget {
  final Color color;
  final String text;
  const _KeptLine({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TopicDot(color, size: 8),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppText.body(
              size: 13.5,
              weight: FontWeight.w500,
              height: 1.35,
              color: context.p.ink,
            ),
          ),
        ),
      ],
    );
  }
}
