/// Why this card: what one of today's cards says on its front under its
/// head, and the sheet the line opens (prototype E2).
///
/// The sheet says why the card was dealt and what the deal knew: the move
/// it trains and how the reader has done on it, their level in its
/// subject, when they last met the move, the goal it is about, the cards
/// like it they liked. Then the two answers the reader can give it, more
/// like this and less, which lean the next days as a like and a throw do.
/// A card dealt at random on the free plan says so, and what Astute+ deals
/// instead.
library;

import 'package:flutter/material.dart';

import '../analytics.dart';
import '../data/why.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../screens/tune_screen.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'area_marks.dart' show goalName;
import 'chunky.dart';
import 'move_words.dart';
import 'premium.dart';

/// The line [why] says on its card, or null where the card says why itself
/// (a card about where the reader lives).
String? whyLine(AppLocalizations l, CardWhy why) {
  final String subject = l.subjectOf(why.pill.topic);
  final String move = moveName(l, why.pill.principle);
  return switch (why.kind) {
    WhyKind.missing => l.whyMissing(move),
    WhyKind.again =>
      why.pill.principle.isReal ? l.whyMoveAgain(move) : l.whyAgain,
    WhyKind.sunday => l.sundayOneMore,
    WhyKind.skill => l.whySkill(l.skillName(why.skill!.name)),
    WhyKind.goal => l.whyGoal(goalName(l, why.goal!)),
    WhyKind.liked => l.whyLiked(why.liked),
    WhyKind.hard => l.whyHard(subject),
    WhyKind.level => l.whyLevel(subject),
    WhyKind.gentle => l.whyGentle(subject),
    WhyKind.subject => l.whyYourSubject(subject),
    WhyKind.place => null,
    WhyKind.random => l.whyRandom,
  };
}

/// The mark beside the line: what kind of reason it is.
IconData whyIcon(WhyKind kind) => switch (kind) {
  WhyKind.missing => Icons.track_changes_rounded,
  WhyKind.again => Icons.replay_rounded,
  WhyKind.sunday => Icons.auto_awesome_rounded,
  WhyKind.skill => Icons.fitness_center_rounded,
  WhyKind.goal => Icons.flag_rounded,
  WhyKind.liked => Icons.favorite_rounded,
  WhyKind.hard => Icons.trending_up_rounded,
  WhyKind.level => Icons.stairs_rounded,
  WhyKind.gentle => Icons.login_rounded,
  WhyKind.subject => Icons.category_rounded,
  WhyKind.place => Icons.place_rounded,
  WhyKind.random => Icons.casino_rounded,
};

/// Puts the sheet for [pill], one of today's cards. [sunday] when it is the
/// one more of the reader's own their Sunday gives.
Future<void> showWhySheet(
  BuildContext context,
  AppState app,
  Pill pill, {
  bool sunday = false,
}) {
  final CardWhy why = whyOf(app, pill, sunday: sunday);
  Analytics.capture('why opened', {
    ...app.cardFacts(pill.id),
    'why': why.kind.name,
  });
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (_) => WhySheet(app: app, why: why),
  );
}

/// The sheet. Public so a test can lay it out in every language.
class WhySheet extends StatelessWidget {
  const WhySheet({super.key, required this.app, required this.why});

  final AppState app;
  final CardWhy why;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final Pill pill = why.pill;
    final String subject = l.subjectOf(pill.topic);
    final String? line = whyLine(l, why);
    final Mastery? mastery = why.mastery;

    final List<(String, String, String)> facts = [
      ('why-level', l.whyLevelRow(subject), l.whyLevelWord(why.level.name)),
      if (why.lastMet case final int days)
        ('why-last', l.whyLastMetRow, l.whyDaysAgo(days)),
      if (why.goal case final goal?)
        ('why-goal', l.whyGoalRow, goalName(l, goal)),
      if (why.liked > 0) ('why-liked', l.whyLikedRow, '${why.liked}'),
    ];

    return Container(
      key: const ValueKey('why-sheet'),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: ListenableBuilder(
          listenable: app,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.lineStrong,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                header: true,
                child: Text(
                  l.whyTitle,
                  style: AppText.display(
                    size: 26,
                    weight: FontWeight.w600,
                    spacing: -0.6,
                    color: p.ink,
                  ),
                ),
              ),
              if (line != null) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        whyIcon(why.kind),
                        size: 16,
                        color: p.ink.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line,
                        key: const ValueKey('why-line'),
                        style: AppText.body(
                          size: 14.5,
                          weight: FontWeight.w600,
                          height: 1.3,
                          color: p.ink.withValues(alpha: 0.82),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              if (mastery != null) ...[
                _MovePanel(move: pill.principle, mastery: mastery),
                const SizedBox(height: 10),
              ],
              if (why.random && !app.isPlus) ...[
                _PlusPanel(app: app),
                const SizedBox(height: 10),
              ],
              for (final (int i, (String, String, String) f) in facts.indexed)
                _Fact(
                  key: ValueKey(f.$1),
                  label: f.$2,
                  value: f.$3,
                  rule: i > 0,
                ),
              const SizedBox(height: 18),
              _Answers(app: app, pill: pill),
              const SizedBox(height: 14),
              Center(
                child: Semantics(
                  button: true,
                  child: GestureDetector(
                    key: const ValueKey('why-tune'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      final NavigatorState nav = Navigator.of(context);
                      nav.pop();
                      nav.push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              TuneScreen(app: app, picked: app.pickedTopics),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune_rounded, size: 15, color: p.inkMuted),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              l.whyTune,
                              style: AppText.body(
                                size: 13.5,
                                weight: FontWeight.w600,
                                color: p.inkMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The move the card trains: its name, its line, and how the reader has
/// done on it, a dot for each card met and filled for each got right.
class _MovePanel extends StatelessWidget {
  const _MovePanel({required this.move, required this.mastery});

  final Principle move;
  final Mastery mastery;

  /// The most dots drawn: past them, the words say it.
  static const int _dots = 8;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final Color ink = p.onInverse;
    final int met = mastery.met;
    final String record = met == 0
        ? l.newMove
        : '${l.whyMet(met)} ${l.whyRight(mastery.right)}';
    return Container(
      key: const ValueKey('why-move'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: p.inverse,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.whyTrains(moveName(l, move)).toUpperCase(),
            style: AppText.label(
              size: 11,
              weight: FontWeight.w700,
              spacing: 1.1,
              color: ink.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            moveLine(l, move),
            style: AppText.display(
              size: 20,
              weight: FontWeight.w600,
              height: 1.2,
              spacing: -0.4,
              color: ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  record,
                  key: const ValueKey('why-record'),
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w500,
                    height: 1.3,
                    color: ink.withValues(alpha: 0.78),
                  ),
                ),
              ),
              if (met > 0) ...[
                const SizedBox(width: 10),
                ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < met.clamp(0, _dots); i++)
                        Container(
                          width: 11,
                          height: 11,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < mastery.right ? ink : Colors.transparent,
                            border: Border.all(color: ink, width: 1.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A card dealt at random, on the free plan: so it is, and what Astute+
/// deals instead.
class _PlusPanel extends StatelessWidget {
  const _PlusPanel({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return Container(
      key: const ValueKey('why-plus'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.whyRandomLine,
            style: AppText.body(size: 13.5, height: 1.35, color: p.inkMuted),
          ),
          const SizedBox(height: 8),
          Text(
            l.whyPlusLine,
            style: AppText.body(
              size: 14.5,
              weight: FontWeight.w600,
              height: 1.35,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 14),
          ChunkyButton(
            key: const ValueKey('why-make-mine'),
            label: l.whyMakeMine,
            fill: p.inverse,
            ink: p.onInverse,
            height: 50,
            onPressed: () =>
                requirePlus(context, app, () {}, source: 'why card'),
          ),
        ],
      ),
    );
  }
}

/// One thing the deal knew, and what it was.
class _Fact extends StatelessWidget {
  const _Fact({
    super.key,
    required this.label,
    required this.value,
    required this.rule,
  });

  final String label;
  final String value;

  /// A hairline above it: every row but the first.
  final bool rule;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: rule ? Border(top: BorderSide(color: p.line)) : null,
      ),
      // The value at the row's end, never wider than half of it; the label
      // takes the rest and wraps.
      child: LayoutBuilder(
        builder: (context, box) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: AppText.body(size: 14, height: 1.3, color: p.ink),
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * 0.5),
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  height: 1.3,
                  color: p.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// More like this, and less: a like and a throw, said from here. Less
/// closes the sheet and says so once, with the way back, as a throw does.
class _Answers extends StatelessWidget {
  const _Answers({required this.app, required this.pill});

  final AppState app;
  final Pill pill;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final bool liked = app.isLiked(pill.id);
    return Row(
      children: [
        Expanded(
          child: ChunkyButton(
            key: const ValueKey('why-more'),
            label: liked ? l.whyMoreDone : l.whyMore,
            fill: p.inverse,
            ink: p.onInverse,
            height: 52,
            leading: liked
                ? Icon(Icons.check_rounded, size: 18, color: p.onInverse)
                : null,
            onPressed: liked
                ? null
                : () {
                    Analytics.capture('why more', app.cardFacts(pill.id));
                    app.toggleLiked(pill.id);
                  },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ChunkyButton(
            key: const ValueKey('why-less'),
            label: l.whyLess,
            fill: p.surfaceRaised,
            ink: p.ink,
            edge: p.lineStrong,
            height: 52,
            onPressed: () {
              Analytics.capture('why less', app.cardFacts(pill.id));
              final ScaffoldMessengerState? messenger =
                  ScaffoldMessenger.maybeOf(context);
              Navigator.of(context).pop();
              app.dislike(pill.id);
              messenger
                ?..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(l.lessLikeThis),
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(
                      label: l.undo,
                      onPressed: () => app.undislike(pill.id),
                    ),
                  ),
                );
            },
          ),
        ),
      ],
    );
  }
}
