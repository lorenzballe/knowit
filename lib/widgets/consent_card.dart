import 'package:flutter/material.dart';

import '../analytics.dart';
import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../sync/push.dart';
import '../theme.dart';
import '../utils/reminders.dart' show remindersSupported;
import 'consent.dart';

/// The question about usage data, as a calm card on the finished day's
/// shelf: "Help make Astute better? We count how the app is used, with no
/// advertising and never your name", No and Yes side by side and the same
/// size. Compact, for the shelf's cards keep their room above it; where the
/// answer can be changed is said in Profile, under Usage data, where it is
/// changed, and in the privacy policy.
///
/// It used to be the first thing the app asked, on the intro's foot before
/// a single card, and a tester found that backwards. It waits now for the
/// end of the first day — after the day's own moment and after the
/// reminder's question, which goes first — and it does not block: the shelf
/// is all there around it, and it stays on the shelf, day after day, until
/// it is answered. Nothing is measured before a yes, as ever (Analytics):
/// PostHog is not even set up until one, and a no sends nothing at all.
class ConsentCard extends StatefulWidget {
  const ConsentCard({
    super.key,
    required this.app,
    this.padding = EdgeInsets.zero,
  });

  final AppState app;

  /// Around the card while it is up; folded away with it once answered.
  final EdgeInsets padding;

  /// Whether the card is on the shelf: a build with somewhere to send
  /// usage data, a reader who has not answered, the day finished, and the
  /// reminder's question not waiting to be put first.
  static bool due(AppState app) =>
      Analytics.canAsk &&
      !Analytics.answered &&
      app.dayClosed &&
      !reminderFirst(app);

  /// Whether the reminder's question is still to come this evening: the
  /// sheet rises over the shelf, and the card waits for it to be answered.
  /// Not on the evening the first day was celebrated: the reminder was the
  /// celebration's to ask, and the shell does not raise it again then.
  static bool reminderFirst(AppState app) =>
      !app.celebratedToday &&
      app.shouldAskForPush &&
      remindersSupported &&
      Push.instance.canAsk;

  @override
  State<ConsentCard> createState() => _ConsentCardState();
}

class _ConsentCardState extends State<ConsentCard> {
  /// Answered here: the card goes at once, whatever the next build says.
  bool _answered = false;

  Future<void> _answer(bool yes) async {
    setState(() => _answered = true);
    await answerConsent(yes, from: 'shelf', app: widget.app);
  }

  @override
  Widget build(BuildContext context) {
    final bool shown = !_answered && ConsentCard.due(widget.app);
    // Gone once answered, folding away rather than leaving a hole.
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: shown
          ? Padding(padding: widget.padding, child: _card(context))
          : const SizedBox(width: double.infinity),
    );
  }

  Widget _card(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return Container(
      key: const ValueKey('consent-card'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
      ),
      // The words grow with the reader's text size up to half as large
      // again: past that, the card would take the shelf it sits on.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.consentTitle,
              style: AppText.body(
                size: 15.5,
                weight: FontWeight.w700,
                height: 1.25,
                spacing: -0.2,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.consentCardLine,
              style: AppText.body(size: 13.5, height: 1.4, color: p.inkMuted),
            ),
            const SizedBox(height: 12),
            ConsentAnswers(onAnswer: _answer, onDark: false),
          ],
        ),
      ),
    );
  }
}
