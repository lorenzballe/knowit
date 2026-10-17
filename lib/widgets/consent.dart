import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme.dart';

/// Whether Astute may measure how the app is used, asked before anything is
/// measured, with its two answers side by side and the same size: saying no
/// is as easy as saying yes, and neither is the one the screen leans on.
///
/// On the intro it sits under "Start reading", white on the dark, and is
/// not in the way: the reader can start without answering, and no answer
/// is a no until they give one. A reader who started without answering is
/// asked once more, as a sheet, after their first finished day
/// ([showConsentSheet]). Either way the answer is kept and can be changed
/// in Profile, under Usage data. See Analytics, which sets nothing up
/// before a yes.
class ConsentChoice extends StatelessWidget {
  const ConsentChoice({super.key, required this.onAnswer});

  /// True for yes, false for no.
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      key: const ValueKey('consent'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: l.consentTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xEBFFFFFF),
                  ),
                ),
                const TextSpan(text: ' '),
                TextSpan(text: l.consentLine),
              ],
            ),
            textAlign: TextAlign.center,
            style: AppText.body(
              size: 13,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 10),
          _Answers(onAnswer: onAnswer, onDark: true),
        ],
      ),
    );
  }
}

/// Puts the question as a sheet, for a reader who has not answered it: the
/// title, what is shared and what never is, where to change it, and the
/// two answers. It waits for one of them — swiping it away would leave the
/// question neither asked nor answered — and returns it: true for yes.
Future<bool?> showConsentSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (_) => const ConsentSheet(),
  );
}

/// The sheet itself. Public so a test can lay it out in every language.
class ConsentSheet extends StatelessWidget {
  const ConsentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return Container(
      key: const ValueKey('consent-sheet'),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        26,
        22,
        MediaQuery.paddingOf(context).bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.consentTitle,
              style: AppText.display(
                size: 20,
                weight: FontWeight.w600,
                spacing: -0.6,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 8),
            // What Profile's switch says it measures, word for word: the
            // two places that speak of it cannot drift apart.
            Text(
              l.anonymousUsageLine,
              style: AppText.body(size: 13.5, height: 1.45, color: p.inkMuted),
            ),
            const SizedBox(height: 8),
            Text(
              l.consentChangeLater(l.tabProfile, l.anonymousUsage),
              style: AppText.body(size: 13.5, height: 1.45, color: p.inkMuted),
            ),
            const SizedBox(height: 20),
            _Answers(
              onAnswer: (bool yes) => Navigator.of(context).pop(yes),
              onDark: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// No and yes, in that order, as two buttons of one size and one look —
/// the same height too, when one of them needs a second line.
class _Answers extends StatelessWidget {
  const _Answers({required this.onAnswer, required this.onDark});

  final ValueChanged<bool> onAnswer;
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
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
