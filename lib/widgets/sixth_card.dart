import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../l10n/l10n.dart';
import '../screens/today_done_view.dart' show plusActionOf, weekNoteOf;
import '../state/app_state.dart';
import '../state/sixth_line.dart';
import 'magic_card.dart';

/// The card after the fifth, on the free plan: the rim, Astute+'s name,
/// and one true thing about the reader's day in place of the same sale
/// every evening — what came at random, what is waiting, where they are
/// better than the cards they are dealt — with what Astute+ would have done
/// with it under it, then the door to the paywall ([onAction]). What it
/// says is chosen in lib/state/sixth_line.dart; this only says it, the
/// same on the deck after the fifth and on the shelf, and keeps what it
/// said for the day.
class SixthCard extends StatelessWidget {
  const SixthCard({super.key, required this.app, required this.onAction});

  final AppState app;

  /// The door: the paywall.
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final SixthLine? said = sixthLineOf(app);
    if (said != null) {
      final String kept = said.keptAs(app.today);
      if (app.sixthSaid != kept) {
        // Kept after the frame: what a card says is a side effect of the
        // day, not of painting it.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => app.noteSixthSaid(kept),
        );
      }
    }
    return sixthCardOf(
      context,
      said,
      note: weekNoteOf(context, app),
      action: plusActionOf(context),
      onAction: onAction,
    );
  }
}

/// The card that says [said], with the week's [note] over it and the
/// door's [action]: as the deck and the shelf show it, and as the tests
/// measure it. With nothing to say, the offer as it always read.
MagicCard sixthCardOf(
  BuildContext context,
  SixthLine? said, {
  (String, String)? note,
  required String action,
  required VoidCallback onAction,
}) {
  final l = context.l10n;
  if (said == null) {
    return MagicCard(
      key: const ValueKey('sixth-plain'),
      eyebrow: l.plusNameCaps,
      note: note,
      headline: l.plusCardHeadline,
      line: l.magicLine,
      action: action,
      onAction: onAction,
    );
  }
  final (String headline, String line) = sixthWords(context, said);
  return MagicCard(
    key: ValueKey('sixth-${said.kind.name}'),
    eyebrow: l.plusNameCaps,
    note: note,
    headline: headline,
    line: line,
    action: action,
    onAction: onAction,
    // A sentence rather than an offer: a size smaller, on as many lines
    // as it needs.
    headlineSize: 31,
    headlineLines: 5,
  );
}

/// [said] in the reader's language: the thing that is true, set large, and
/// what Astute+ would have done with it, under it.
(String, String) sixthWords(BuildContext context, SixthLine said) {
  final l = context.l10n;
  final String locale = Localizations.localeOf(context).toString();
  return switch (said.kind) {
    SixthKind.tomorrow => (
      l.sixthRandomTomorrow(said.n),
      l.sixthRandomTomorrowPlus,
    ),
    SixthKind.today => (l.sixthRandomToday(said.n), l.sixthRandomTodayPlus),
    SixthKind.sure => (
      l.elided(
        l.sixthSureWrong(
          NumberFormat.percentPattern(locale).format(said.n / 100),
        ),
      ),
      l.sixthSureWrongPlus,
    ),
    SixthKind.misses => (l.sixthMisses(said.n), l.sixthMissesPlus),
    SixthKind.level => (
      l.elided(l.sixthLevel(l.subjectName(said.subject!), said.n, said.of)),
      l.sixthLevelPlus(l.subjectName(said.subject!)),
    ),
  };
}
