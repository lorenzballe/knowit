/// Whether Astute may measure how the app is used: the answer, and the two
/// buttons it is given with. The question itself is a card on the finished
/// day's shelf (lib/widgets/consent_card.dart), asked once the first day is
/// done; Profile's switch under Usage data is the same answer, and changes
/// it. See Analytics, which sets nothing up before a yes.
///
/// It used to be asked on the intro's foot, before a single card, and once
/// more as a sheet after the first finished day for a reader who had not
/// answered there.
library;

import 'package:flutter/material.dart';

import '../analytics.dart';
import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// The reader's answer, wherever it was given: a yes sets measurement up
/// there and then, and its first event is that yes; a no is kept, and
/// nothing is sent about it. [from] says where (`shelf`).
Future<void> answerConsent(
  bool yes, {
  required String from,
  AppState? app,
}) async {
  await Analytics.setCollecting(yes);
  if (!yes) return;
  Analytics.capture('usage sharing answered', {'on': true, 'from': from});
  // The reader's profile, said now that there is somewhere to say it.
  if (app != null && app.ready) app.refreshAnalytics();
}

/// No and yes, in that order, as two buttons of one size and one look —
/// the same height too, when one of them needs a second line: saying no is
/// as easy as saying yes, and neither is the one the screen leans on.
class ConsentAnswers extends StatelessWidget {
  const ConsentAnswers({
    super.key,
    required this.onAnswer,
    required this.onDark,
  });

  /// True for yes, false for no.
  final ValueChanged<bool> onAnswer;

  /// White on black, whatever the theme; otherwise the page's own ink.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Answer(
              key: const ValueKey('consent-no'),
              label: l.consentNo,
              onDark: onDark,
              onTap: () => onAnswer(false),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Answer(
              key: const ValueKey('consent-yes'),
              label: l.consentYes,
              onDark: onDark,
              onTap: () => onAnswer(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _Answer extends StatelessWidget {
  const _Answer({
    super.key,
    required this.label,
    required this.onDark,
    required this.onTap,
  });

  final String label;
  final bool onDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color ink = onDark ? Colors.white : context.p.ink;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ink.withValues(alpha: onDark ? 0.12 : 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ink.withValues(alpha: 0.16)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.body(
              size: 15,
              weight: FontWeight.w600,
              height: 1.2,
              color: ink.withValues(alpha: onDark ? 0.92 : 1),
            ),
          ),
        ),
      ),
    );
  }
}
