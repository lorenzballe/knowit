/// What to learn, five other ways, as the developer tools try them beside
/// the one that ships (DebugLooks.learn, lib/state/debug_looks.dart).
///
/// As it ships, a reader picks skills on What to learn, every skill has a
/// score with no top, a card that trains one picked carries its mark, its
/// back says how far the answer moved that score, Your journey opens on
/// Your training (the Astute score, the skills picked, "The others") and
/// the profile has a box of them. The owner did not believe in it.
///
/// Where the reader wants to see more clearly, their aim, is asked on the
/// profile in every look now (lib/widgets/aim_picker.dart), and leans
/// Explore, the coach and the paywall whatever the look: what the looks
/// answer is what becomes of the skills and their scores beside it. Each is
/// built for real, so it can be lived with on a phone:
///
/// - A, [LearnLook.score]: the Astute score alone. No skills, no marks, no
///   box under the question; Your journey opens on the score and its level.
/// - B, [LearnLook.aim]: the aim alone. No skills and no box under the
///   question, which is the whole of it on the profile; asked at the end of
///   the first run too; a card dealt for it says so under its head; Your
///   journey opens on its week in words and counts, never a score.
/// - C, [LearnLook.profile]: nothing to pick. The skills are read from the
///   reader's answers, strongest first, each as right answers out of
///   answers given, with the weakest to practise: Your journey opens on the
///   ranking on Astute+, and on the free plan the profile has the strongest
///   only, the rest behind the journey's own door.
/// - D, [LearnLook.aimProfile]: the aim, read. The four skills the aim takes
///   (aimSkills), ranked from the answers: where the reader sees clearly
///   and their blind spot, under the question, on either plan; the whole
///   profile and five cards on the blind spot in Your journey, Astute+.
/// - E, [LearnLook.weekly]: a focus a week. One of the aim's four skills,
///   Monday to Sunday: its mark on the cards that train it, a shelf of it
///   on Explore, the day's own cards leaning to it, its days on the profile
///   and in Your journey, and on Sunday how the week went. In turn on the
///   free plan; on Astute+ the one the reader slips on most.
///
/// What each reads from the answers is lib/data/learn_reading.dart. Nothing
/// here is measured that was not measured before: no event is added, and
/// the doors to the plans are the ones that already exist.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../data/goals.dart';
import '../data/learn_reading.dart';
import '../data/pills_repository.dart' show dateKey;
import '../data/skills.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../screens/area_screen.dart';
import '../screens/deck_viewer_screen.dart';
import '../screens/journey_screen.dart';
import '../state/app_state.dart';
import '../state/debug_looks.dart';
import '../theme.dart';
import 'aim_picker.dart' show AimRows;
import 'area_marks.dart';
import 'chunky.dart';
import 'fit_text.dart';
import 'premium.dart';
import 'training.dart' show ProfileTraining;
import 'ui.dart' show BackCircle, Eyebrow;

export '../data/learn_reading.dart';

/// What to learn's look in this run.
LearnLook get learnLook => DebugLooks.learnPicked;

/// The skills whose mark a card carries: the ones picked on What to learn,
/// as it ships; in E the week's one; none in the other looks, where no card
/// carries a skill's mark.
List<String> markedSkills(AppState app) => switch (learnLook) {
  LearnLook.today || LearnLook.mix => app.skills,
  LearnLook.weekly => [weekFocusOf(app).skill.name],
  _ => const [],
};

/// The skills whose score a card's back moves beside its verdict: the ones
/// picked, as it ships; none in the other looks, where the answer moves the
/// Astute score, the one score they keep.
List<String> scoredSkills(AppState app) =>
    learnLook == LearnLook.today || learnLook == LearnLook.mix
    ? app.skills
    : const [];

/// Whether a card dealt for the reader's goal keeps quiet about it under
/// its head: as it ships and in E, where a skill's mark says what the card
/// is for already ([marked]); in A and C, which keep the cards to the one
/// score or the answers. B and D, the looks of the aim, say it in words:
/// "For your goal: Money and shopping".
bool goalUnsaid(AppState app, {required bool marked}) => switch (learnLook) {
  LearnLook.today || LearnLook.mix || LearnLook.weekly => marked,
  LearnLook.aim || LearnLook.aimProfile => false,
  LearnLook.score || LearnLook.profile => true,
};

/// Whether the look is built on the reader's aim, and so asks for it at the
/// end of the first run (lib/main.dart): B, D and E.
bool get learnAsksAim => switch (learnLook) {
  LearnLook.aim || LearnLook.aimProfile || LearnLook.weekly => true,
  LearnLook.today ||
  LearnLook.mix ||
  LearnLook.score ||
  LearnLook.profile => false,
};

/// Capitals, with Turkish's dotted capital I.
String _caps(BuildContext context, String text) =>
    Localizations.localeOf(context).languageCode == 'tr'
    ? text.replaceAll('i', 'İ').toUpperCase()
    : text.toUpperCase();

/// A label in small capitals, as Your training's own.
Widget _smallCaps(BuildContext context, String text, {Key? key}) => Text(
  _caps(context, text),
  key: key,
  style: AppText.body(
    size: 9.5,
    weight: FontWeight.w700,
    spacing: 1.3,
    color: context.p.ink.withValues(alpha: 0.45),
  ),
);

/// A hairline across a box, between what it says.
Widget _rule(BuildContext context) =>
    Container(height: 1, color: context.p.ink.withValues(alpha: 0.08));

/// The faint panel the journey's chapters sit on.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
    decoration: BoxDecoration(
      color: context.p.ink.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(22),
    ),
    child: child,
  );
}

/// The profile's own card, as Your journey's door under it.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.child, this.onTap, super.key});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 10, 15),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.line),
        ),
        child: Row(
          children: [
            Expanded(child: child),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: p.ink.withValues(alpha: 0.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A link in the page's link colour.
Widget _link(BuildContext context, String text, VoidCallback onTap, Key key) =>
    Semantics(
      button: true,
      child: GestureDetector(
        key: key,
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            text,
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w600,
              color: context.p.link,
            ),
          ),
        ),
      ),
    );

/// On the free plan, under a box: what Astute+ adds to it, the plan's name
/// in its small pill, the door to the plans.
class _PlusLine extends StatelessWidget {
  const _PlusLine({required this.text, required this.onTap, super.key});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: p.link.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l.plusName,
                    style: AppText.label(
                      size: 9.5,
                      weight: FontWeight.w700,
                      spacing: 0.6,
                      color: p.link,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  text,
                  style: AppText.body(
                    size: 13,
                    height: 1.38,
                    color: p.ink.withValues(alpha: 0.72),
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

// ── The profile ───────────────────────────────────────────────────────────

/// Where the profile showed Your training, under the question of the aim:
/// the box of What to learn's look, or nothing in A and B. Changed in the
/// developer tools, it shows at once.
class LearnProfileBox extends StatelessWidget {
  const LearnProfileBox({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<LearnLook>(
    valueListenable: DebugLooks.learn,
    builder: (context, _, _) {
      final Widget? box = switch (learnLook) {
        LearnLook.today || LearnLook.mix => ProfileTraining(app: app),
        // The question over it is the whole of A's and B's profile.
        LearnLook.score || LearnLook.aim => null,
        LearnLook.profile => StrengthsBox(app: app),
        LearnLook.aimProfile => AimReadBox(app: app),
        LearnLook.weekly => FocusBox(app: app),
      };
      if (box == null) return const SizedBox.shrink();
      return Padding(padding: const EdgeInsets.only(top: 22), child: box);
    },
  );
}

/// Opens Your journey: on the free plan through its own door, the plans.
void _openJourney(BuildContext context, AppState app) => requirePlus(
  context,
  app,
  () => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (routeContext) => JourneyScreen(
        app: app,
        onBack: () => Navigator.of(routeContext).pop(),
      ),
    ),
  ),
  source: 'journey',
);

// ── B · The aim ───────────────────────────────────────────────────────────

/// The reader's aim: the first of their goals, the one the profile asks for.
Goal? aimOf(AppState app) => Goal.of(app.goal);

/// Opens the aim's own page: its paths, the moves it trains, more of it;
/// from the profile's sheet too (lib/widgets/aim_picker.dart).
void openAimPage(BuildContext context, AppState app, Goal aim) {
  HapticFeedback.selectionClick();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AreaScreen(app: app, area: aim),
    ),
  );
}

/// Opens the question, from Your journey: on the profile it is a section
/// of its own (lib/widgets/aim_picker.dart).
void openAim(BuildContext context, AppState app) {
  HapticFeedback.selectionClick();
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => AimScreen(app: app)));
}

/// One question: where the reader wants to be sharper. The six areas, each
/// with its line, one to pick, in the profile's own rows. At the end of the
/// first run it has Next and Skip; from Your journey, Done, and the way
/// back.
class AimScreen extends StatefulWidget {
  const AimScreen({super.key, required this.app, this.firstRun = false});

  final AppState app;

  /// Asked as the first run's last step.
  final bool firstRun;

  @override
  State<AimScreen> createState() => _AimScreenState();
}

class _AimScreenState extends State<AimScreen> {
  late Goal? _picked = widget.firstRun ? null : aimOf(widget.app);

  Future<void> _done({required bool keep}) async {
    final Goal? aim = _picked;
    if (keep && aim != null) await widget.app.setGoals([aim.key]);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final double foot = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      key: const ValueKey('aim-screen'),
      backgroundColor: p.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.firstRun)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Row(
                  children: [
                    BackCircle(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  widget.firstRun ? 28 : 18,
                  20,
                  12,
                ),
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l.aimTitle,
                      style: AppText.display(
                        size: 31,
                        weight: FontWeight.w600,
                        height: 1.12,
                        spacing: -0.5,
                        color: p.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.aimLine,
                    style: AppText.body(
                      size: 15,
                      height: 1.4,
                      color: p.ink.withValues(alpha: 0.62),
                    ),
                  ),
                  const SizedBox(height: 22),
                  // The profile's own rows (lib/widgets/aim_picker.dart):
                  // one picker, wherever the question is asked.
                  AimRows(
                    picked: _picked,
                    keyPrefix: 'aim-',
                    gap: 10,
                    onPick: (g) {
                      HapticFeedback.selectionClick();
                      setState(() => _picked = g);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                widget.firstRun ? 4 : (foot > 0 ? foot : 16),
              ),
              child: ChunkyButton(
                key: const ValueKey('aim-done'),
                label: widget.firstRun ? l.next : l.skillsDone,
                fill: p.inverse,
                ink: p.onInverse,
                height: 58,
                onPressed: _picked == null && widget.firstRun
                    ? null
                    : () => _done(keep: true),
              ),
            ),
            if (widget.firstRun)
              Padding(
                padding: EdgeInsets.only(bottom: foot > 0 ? foot - 6 : 10),
                child: Center(
                  child: TextButton(
                    key: const ValueKey('aim-skip'),
                    onPressed: () => _done(keep: false),
                    child: Text(
                      l.skip,
                      style: AppText.body(
                        size: 14.5,
                        weight: FontWeight.w600,
                        color: p.ink.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The aim's mark and name, the mark by the name's first line where the
/// name takes two, and its line under them.
class _AimHead extends StatelessWidget {
  const _AimHead({required this.aim, this.size = 22});

  final Goal aim;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.textScalerOf(context).scale(size) * 0.17,
              ),
              child: Icon(goalIcon(aim), size: 18, color: goalTone(aim, p)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                goalName(l, aim),
                style: AppText.display(
                  size: size,
                  weight: FontWeight.w600,
                  height: 1.12,
                  spacing: -0.3,
                  color: p.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          goalLine(l, aim),
          style: AppText.body(
            size: 13.5,
            height: 1.35,
            color: p.ink.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// The aim in words, then this week's cards of it and the answers on them.
class _AimSummary extends StatelessWidget {
  const _AimSummary({required this.app, required this.aim, this.size = 22});

  final AppState app;
  final Goal aim;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final tally = aimTally(app, aim);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AimHead(aim: aim, size: size),
        const SizedBox(height: 12),
        _rule(context),
        const SizedBox(height: 10),
        // The week's cards of it, then how the answers on them went, each
        // on a line of its own: run together, the second broke in the
        // middle of its words on a phone of the ordinary width.
        Text(
          l.aimWeek(tally.cards),
          key: const ValueKey('aim-week'),
          style: AppText.body(
            size: 13.5,
            weight: FontWeight.w700,
            height: 1.35,
            color: p.ink,
          ),
        ),
        if (tally.answers > 0) ...[
          const SizedBox(height: 2),
          Text(
            l.answersRightOf(tally.right, tally.answers),
            style: AppText.body(
              size: 13,
              height: 1.35,
              color: p.ink.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }
}

/// With no aim yet, in Your journey: what an aim does, and the way to pick.
class _NoAim extends StatelessWidget {
  const _NoAim({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.aimNone,
          style: AppText.body(
            size: 15,
            height: 1.38,
            color: p.ink.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 16),
        ChunkyButton(
          key: const ValueKey('journey-aim-pick'),
          label: l.aimPick,
          fill: p.inverse,
          ink: p.onInverse,
          height: 52,
          onPressed: () => openAim(context, app),
        ),
      ],
    );
  }
}

/// B at the head of Your journey: the aim, what the week did for it, and
/// the way to its page. With none, what an aim does and the way to pick
/// one.
class AimPanel extends StatelessWidget {
  const AimPanel({super.key, required this.app, this.label = true});

  final AppState app;

  /// Whether it says "Your goal" over itself: not where the chapter's head
  /// says it.
  final bool label;

  /// The link at the end of the chapter's head: the question again.
  static Widget change(BuildContext context, AppState app) => _link(
    context,
    context.l10n.edit,
    () => openAim(context, app),
    const ValueKey('journey-aim-edit'),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final Goal? aim = aimOf(app);
    return _Panel(
      child: Column(
        key: const ValueKey('journey-aim'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label) ...[
            _smallCaps(context, l.whyGoalRow),
            const SizedBox(height: 10),
          ],
          if (aim == null)
            _NoAim(app: app)
          else ...[
            _AimSummary(app: app, aim: aim, size: 24),
            const SizedBox(height: 14),
            GestureDetector(
              key: const ValueKey('journey-aim-open'),
              behavior: HitTestBehavior.opaque,
              onTap: () => openAimPage(context, app, aim),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      l.aimOpen,
                      style: AppText.body(
                        size: 14,
                        weight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 17,
                    color: p.ink.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── C · Where you're strong ───────────────────────────────────────────────

/// The ranked of [tallies]: the skills with enough answers behind them.
List<SkillTally> _ranked(List<SkillTally> tallies) => [
  for (final SkillTally t in tallies)
    if (t.ranked) t,
];

/// A skill's mark as C and D draw it: its glyph in the page's ink, on a
/// square of a hairline, never on the skill's two hues.
class _InkMark extends StatelessWidget {
  const _InkMark({required this.skill, this.size = 30});

  final Skill skill;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: p.ink.withValues(alpha: 0.18)),
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size.square(size * 0.58),
        painter: SkillGlyph(skill, p.ink.withValues(alpha: 0.88)),
      ),
    );
  }
}

/// One skill in a profile's box: a kicker, its mark and name, and its right
/// answers out of those given.
class _StrengthLine extends StatelessWidget {
  const _StrengthLine({required this.kicker, required this.tally, super.key});

  final String kicker;
  final SkillTally tally;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _smallCaps(context, kicker),
        const SizedBox(height: 8),
        Row(
          children: [
            _InkMark(skill: tally.skill),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.skillName(tally.skill.name),
                    style: AppText.display(
                      size: 19,
                      weight: FontWeight.w600,
                      height: 1.15,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.answersRightOf(tally.right, tally.answers),
                    style: AppText.body(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: p.ink.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A padlock and what Astute+ adds, inside a profile's box.
class _LockedLine extends StatelessWidget {
  const _LockedLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            Icons.lock_rounded,
            size: 15,
            color: p.ink.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppText.body(
              size: 13,
              height: 1.38,
              weight: FontWeight.w600,
              color: p.ink.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }
}

/// C on the profile: the reader's strong point, read from their answers;
/// on Astute+ where they slip most beside it, and the box opens the journey;
/// on the free plan the rest is the journey's, behind its door.
class StrengthsBox extends StatelessWidget {
  const StrengthsBox({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final List<SkillTally> ranked = _ranked(skillTallies(app));
    final Widget inside;
    if (ranked.isEmpty) {
      inside = Text(
        l.strengthsEmpty,
        style: AppText.body(
          size: 14,
          height: 1.38,
          color: p.ink.withValues(alpha: 0.72),
        ),
      );
    } else {
      inside = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StrengthLine(kicker: l.strengthsBest, tally: ranked.first),
          const SizedBox(height: 14),
          _rule(context),
          const SizedBox(height: 12),
          if (app.isPlus && ranked.length > 1)
            _StrengthLine(kicker: l.strengthsWeak, tally: ranked.last)
          else
            _LockedLine(
              key: const ValueKey('profile-strengths-locked'),
              text: l.strengthsLocked,
            ),
        ],
      );
    }
    return Column(
      key: const ValueKey('profile-strengths'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Eyebrow(l.strengthsTitle),
        const SizedBox(height: 11),
        _ProfileCard(onTap: () => _openJourney(context, app), child: inside),
      ],
    );
  }
}

/// C at the head of Your journey: every skill read from the reader's
/// answers, strongest first, each with its right answers out of those given
/// and a bar of the share; the ones with too few answers named at the
/// foot; and the weakest to practise, five cards of it.
class StrengthsPanel extends StatelessWidget {
  const StrengthsPanel({super.key, required this.app, this.label = true});

  final AppState app;

  /// Whether it says "Where you're strong" over itself: not where the
  /// chapter's head says it.
  final bool label;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final List<SkillTally> tallies = skillTallies(app);
    final List<SkillTally> ranked = _ranked(tallies);
    final List<SkillTally> few = [
      for (final SkillTally t in tallies)
        if (!t.ranked) t,
    ];
    final SkillTally? weakest = ranked.length > 1 ? ranked.last : null;
    return _Panel(
      child: Column(
        key: const ValueKey('journey-strengths'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label) ...[
            _smallCaps(context, l.strengthsTitle),
            const SizedBox(height: 8),
          ],
          Text(
            l.strengthsLine,
            style: AppText.body(
              size: 13.5,
              height: 1.35,
              color: p.ink.withValues(alpha: 0.62),
            ),
          ),
          if (ranked.isEmpty) ...[
            const SizedBox(height: 14),
            Text(
              l.strengthsEmpty,
              style: AppText.body(
                size: 15,
                height: 1.38,
                color: p.ink.withValues(alpha: 0.75),
              ),
            ),
          ],
          for (final (int i, SkillTally t) in ranked.indexed) ...[
            SizedBox(height: i == 0 ? 16 : 13),
            _StrengthRow(tally: t, place: i + 1),
          ],
          if (few.isNotEmpty) ...[
            const SizedBox(height: 16),
            _FewLine(key: const ValueKey('journey-strengths-few'), few: few),
          ],
          if (weakest != null) ...[
            const SizedBox(height: 18),
            _PracticeButton(app: app, skill: weakest.skill),
          ],
        ],
      ),
    );
  }
}

/// The skills with too few answers yet, named in a line.
class _FewLine extends StatelessWidget {
  const _FewLine({required this.few, super.key});

  final List<SkillTally> few;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Text(
      l.strengthsFew(
        [for (final SkillTally t in few) l.skillName(t.skill.name)].join(', '),
      ),
      style: AppText.body(
        size: 12.5,
        height: 1.4,
        color: context.p.ink.withValues(alpha: 0.5),
      ),
    );
  }
}

/// A skill to practise: five cards of it, answered as the day's are, the
/// answer held until the reader commits.
class _PracticeButton extends StatelessWidget {
  const _PracticeButton({required this.app, required this.skill});

  final AppState app;
  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final List<Pill> cards = practiceCards(app, skill);
    if (cards.isEmpty) return const SizedBox.shrink();
    final String label = l.strengthsPractice(l.skillName(skill.name));
    // A long name in a long language takes a second line rather than being
    // cut: the button grows with its words.
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('journey-strengths-practice'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DeckViewerScreen(
                app: app,
                deck: cards,
                title: l.skillName(skill.name),
                answering: true,
                countsAsRead: true,
                source: 'journey',
              ),
            ),
          );
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
          decoration: BoxDecoration(
            color: p.inverse,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppText.body(
                    size: 15,
                    weight: FontWeight.w700,
                    height: 1.25,
                    color: p.onInverse,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 19, color: p.onInverse),
            ],
          ),
        ),
      ),
    );
  }
}

/// One ranked skill: its place, its mark and name, its right answers out of
/// those given, and under them a bar of the share right, in the page's ink;
/// under the bar, where it is one, what it is to the reader ([tag]).
class _StrengthRow extends StatelessWidget {
  const _StrengthRow({required this.tally, required this.place, this.tag});

  final SkillTally tally;
  final int place;

  /// A word in small capitals under its bar: "Blind spot".
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final double share = tally.answers == 0 ? 0 : tally.right / tally.answers;
    final String name = l.skillName(tally.skill.name);
    final String right = l.answersRightOf(tally.right, tally.answers);
    return Semantics(
      container: true,
      label: ['$place. $name, $right', ?tag].join('. '),
      excludeSemantics: true,
      child: Column(
        key: ValueKey('strength-${tally.skill.name}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18,
                child: Text(
                  '$place',
                  style:
                      AppText.display(
                        size: 15,
                        weight: FontWeight.w600,
                        color: p.ink.withValues(alpha: 0.45),
                      ).copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ),
              const SizedBox(width: 6),
              _InkMark(skill: tally.skill, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: FitText(
                  name,
                  maxLines: 2,
                  minSize: 12,
                  wholeWords: true,
                  style: AppText.body(
                    size: 14.5,
                    weight: FontWeight.w700,
                    height: 1.2,
                    color: p.ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                right,
                style: AppText.body(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: p.ink.withValues(alpha: 0.62),
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(
                height: 4,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(color: p.ink.withValues(alpha: 0.1)),
                    ),
                    FractionallySizedBox(
                      widthFactor: share.clamp(0.0, 1.0),
                      child: ColoredBox(color: p.ink.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (tag case final String word) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: _smallCaps(context, word),
            ),
          ],
        ],
      ),
    );
  }
}

// ── D · The aim, read ─────────────────────────────────────────────────────

/// D on the profile, under the question it echoes: among the four skills
/// the reader's aim takes, where their answers say they see most clearly,
/// and their blind spot, on either plan; on the free plan, what Astute+
/// adds. The box opens Your journey, where the whole reading is. With no
/// aim, the way to the question just above.
class AimReadBox extends StatelessWidget {
  const AimReadBox({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final Goal? aim = aimOf(app);
    final AimReading? reading = aim == null ? null : aimReading(app, aim);
    final TextStyle note = AppText.body(
      size: 14,
      height: 1.38,
      color: p.ink.withValues(alpha: 0.72),
    );
    final Widget inside;
    if (reading == null) {
      inside = Text(l.readNoAim, style: note);
    } else if (reading.sharpest == null) {
      inside = Text(l.readEmpty, style: note);
    } else {
      final SkillTally? blind = reading.blind;
      inside = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StrengthLine(kicker: l.strengthsBest, tally: reading.sharpest!),
          if (blind != null) ...[
            const SizedBox(height: 14),
            _rule(context),
            const SizedBox(height: 12),
            _StrengthLine(
              key: const ValueKey('profile-read-blind'),
              kicker: l.readBlind,
              tally: blind,
            ),
          ],
          if (!app.isPlus) ...[
            const SizedBox(height: 14),
            _rule(context),
            const SizedBox(height: 12),
            _LockedLine(
              key: const ValueKey('profile-read-locked'),
              text: l.readLocked,
            ),
          ],
        ],
      );
    }
    return Column(
      key: const ValueKey('profile-read'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Eyebrow(l.readTitle),
        const SizedBox(height: 11),
        _ProfileCard(
          key: const ValueKey('profile-read-card'),
          onTap: reading == null ? null : () => _openJourney(context, app),
          child: inside,
        ),
      ],
    );
  }
}

/// D at the head of Your journey: the aim, its four skills ranked from the
/// reader's answers, the blind spot named under its bar and five cards to
/// practise it; then the rest of the profile, the other skills ranked the
/// same way. With no aim, what an aim does and the way to pick one.
class AimReadPanel extends StatelessWidget {
  const AimReadPanel({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final Goal? aim = aimOf(app);
    if (aim == null) {
      return _Panel(
        child: KeyedSubtree(
          key: const ValueKey('journey-read'),
          child: _NoAim(app: app),
        ),
      );
    }
    final AimReading reading = aimReading(app, aim);
    final SkillTally? blind = reading.blind;
    final Set<Skill> taken = aimSkills(aim).toSet();
    final List<SkillTally> others = [
      for (final SkillTally t in skillTallies(app))
        if (!taken.contains(t.skill)) t,
    ];
    final List<SkillTally> othersRanked = _ranked(others);
    final List<SkillTally> othersFew = [
      for (final SkillTally t in others)
        if (!t.ranked) t,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          child: Column(
            key: const ValueKey('journey-read'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AimHead(aim: aim, size: 24),
              const SizedBox(height: 12),
              _rule(context),
              const SizedBox(height: 12),
              Text(
                l.readLine,
                style: AppText.body(
                  size: 13.5,
                  height: 1.35,
                  color: p.ink.withValues(alpha: 0.62),
                ),
              ),
              if (reading.ranked.isEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  l.readEmpty,
                  style: AppText.body(
                    size: 15,
                    height: 1.38,
                    color: p.ink.withValues(alpha: 0.75),
                  ),
                ),
              ],
              for (final (int i, SkillTally t) in reading.ranked.indexed) ...[
                SizedBox(height: i == 0 ? 16 : 13),
                _StrengthRow(
                  tally: t,
                  place: i + 1,
                  tag: identical(t, blind) ? l.readBlind : null,
                ),
              ],
              if (reading.few.isNotEmpty) ...[
                const SizedBox(height: 14),
                _FewLine(few: reading.few),
              ],
              if (blind != null) ...[
                const SizedBox(height: 18),
                _PracticeButton(app: app, skill: blind.skill),
              ],
            ],
          ),
        ),
        if (others.isNotEmpty) ...[
          const SizedBox(height: 8),
          _Panel(
            child: Column(
              key: const ValueKey('journey-read-others'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _smallCaps(context, l.readOthers),
                for (final SkillTally t in othersRanked) ...[
                  const SizedBox(height: 10),
                  _OtherRow(tally: t),
                ],
                if (othersFew.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _FewLine(few: othersFew),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A skill the aim does not take, tight: its mark, its name and its right
/// answers out of those given.
class _OtherRow extends StatelessWidget {
  const _OtherRow({required this.tally});

  final SkillTally tally;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final String name = l.skillName(tally.skill.name);
    final String right = l.answersRightOf(tally.right, tally.answers);
    return Semantics(
      container: true,
      label: '$name, $right',
      excludeSemantics: true,
      child: Row(
        children: [
          _InkMark(skill: tally.skill, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: FitText(
              name,
              maxLines: 2,
              minSize: 11,
              wholeWords: true,
              style: AppText.body(
                size: 13.5,
                weight: FontWeight.w600,
                height: 1.2,
                color: p.ink,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            right,
            style: AppText.body(
              size: 12,
              weight: FontWeight.w600,
              color: p.ink.withValues(alpha: 0.55),
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

// ── E · A focus a week ────────────────────────────────────────────────────

/// The week's skill as E draws it: its glyph in its own colour, in a thin
/// ring of it, as the aim's rows draw an area: one colour on the page, the
/// rest its ink.
class _FocusMark extends StatelessWidget {
  const _FocusMark({required this.skill, this.size = 36});

  final Skill skill;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color tone = skill.mark(context.p.isDark);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: tone, width: 1.2),
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size.square(size * 0.52),
        painter: SkillGlyph(skill, tone),
      ),
    );
  }
}

/// A day of the week's skill: a ring, filled as far round as its answers
/// were right; faint for a day with none, fainter for one still to come.
class _DayDot extends CustomPainter {
  const _DayDot({required this.day, required this.ink});

  final FocusDay? day;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide / 2 - 0.8;
    final FocusDay? d = day;
    final double alpha = d == null
        ? 0.14
        : d.answers == 0
        ? 0.3
        : 0.85;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = ink.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    if (d == null || d.answers == 0 || d.right == 0) return;
    final Paint fill = Paint()..color = ink.withValues(alpha: 0.85);
    if (d.right >= d.answers) {
      canvas.drawCircle(c, r, fill);
      return;
    }
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * d.right / d.answers,
      true,
      fill,
    );
  }

  @override
  bool shouldRepaint(_DayDot old) => old.day != day || old.ink != ink;
}

/// The week of the focus, Monday to Sunday: each day's initial over its
/// ring, today's in full ink; with [counts], each day's right answers out
/// of those given under it.
class _WeekDays extends StatelessWidget {
  const _WeekDays({
    required this.week,
    required this.start,
    required this.today,
    this.counts = false,
  });

  final FocusWeek week;
  final DateTime start;
  final DateTime today;
  final bool counts;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final DateFormat initial = DateFormat('EEEEE', locale);
    final DateFormat named = DateFormat('EEEE', locale);
    final String todayKey = dateKey(today);
    final double dot = counts ? 18 : 15;
    return Row(
      key: const ValueKey('focus-days'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < 7; i++)
          Builder(
            builder: (context) {
              final DateTime day = DateTime(
                start.year,
                start.month,
                start.day + i,
              );
              final FocusDay? d = week.days[i];
              final bool now = dateKey(day) == todayKey;
              return Semantics(
                label: [
                  named.format(day),
                  if (d != null && d.answers > 0)
                    l.answersRightOf(d.right, d.answers),
                ].join(', '),
                excludeSemantics: true,
                child: SizedBox(
                  width: counts ? 34 : 26,
                  child: Column(
                    children: [
                      Text(
                        _caps(context, initial.format(day)),
                        style: AppText.body(
                          size: 10.5,
                          weight: FontWeight.w700,
                          color: p.ink.withValues(alpha: now ? 0.95 : 0.45),
                        ),
                      ),
                      const SizedBox(height: 6),
                      CustomPaint(
                        size: Size.square(dot),
                        painter: _DayDot(day: d, ink: p.ink),
                      ),
                      if (counts) ...[
                        const SizedBox(height: 5),
                        Text(
                          d == null || d.answers == 0
                              ? '–'
                              : '${d.right}/${d.answers}',
                          maxLines: 1,
                          style:
                              AppText.body(
                                size: 10.5,
                                weight: FontWeight.w600,
                                color: p.ink.withValues(alpha: 0.55),
                              ).copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// The week's skill and how it was chosen, beside its mark.
class _FocusHead extends StatelessWidget {
  const _FocusHead({required this.focus, this.size = 19, this.mark = 36});

  final WeekFocus focus;
  final double size;
  final double mark;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    return Row(
      children: [
        _FocusMark(skill: focus.skill, size: mark),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.skillName(focus.skill.name),
                style: AppText.display(
                  size: size,
                  weight: FontWeight.w600,
                  height: 1.15,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                focus.chosen ? l.focusFromMisses : l.focusFromGoal,
                style: AppText.body(
                  size: 12.5,
                  height: 1.3,
                  color: p.ink.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// How the week has gone so far, or on Sunday how it went and the next
/// week's skill; and from Monday to Saturday last week's, where it had
/// answers.
class _FocusTally extends StatelessWidget {
  const _FocusTally({required this.app, required this.focus});

  final AppState app;
  final WeekFocus focus;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final FocusWeek week = focusWeek(app, focus);
    final bool sunday = app.today.weekday == DateTime.sunday;
    final TextStyle strong = AppText.body(
      size: 13.5,
      weight: FontWeight.w700,
      height: 1.35,
      color: p.ink,
    );
    final TextStyle soft = AppText.body(
      size: 13,
      height: 1.35,
      color: p.ink.withValues(alpha: 0.6),
    );
    final List<Widget> lines;
    if (sunday) {
      final WeekFocus next = weekFocusOf(app, on: focus.nextStart);
      lines = [
        _smallCaps(context, l.focusResult, key: const ValueKey('focus-result')),
        const SizedBox(height: 6),
        Text(
          week.answers == 0
              ? l.aimWeek(week.cards)
              : l.answersRightOf(week.right, week.answers),
          style: AppText.display(
            size: 21,
            weight: FontWeight.w600,
            height: 1.15,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l.focusNext(l.skillName(next.skill.name)),
          key: const ValueKey('focus-next'),
          style: strong,
        ),
      ];
    } else {
      final WeekFocus last = weekFocusOf(app, on: focus.lastStart);
      final FocusWeek lastWeek = focusWeek(app, last);
      lines = [
        Text(l.aimWeek(week.cards), style: strong),
        if (week.answers > 0) ...[
          const SizedBox(height: 2),
          Text(l.answersRightOf(week.right, week.answers), style: soft),
        ],
        if (lastWeek.answers > 0) ...[
          const SizedBox(height: 12),
          _rule(context),
          const SizedBox(height: 10),
          Text(
            l.focusLast(l.skillName(last.skill.name)),
            key: const ValueKey('focus-last'),
            style: strong.copyWith(
              fontSize: 13,
              color: p.ink.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 2),
          Text(l.answersRightOf(lastWeek.right, lastWeek.answers), style: soft),
        ],
      ];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines,
    );
  }
}

/// E on the profile, under the question: this week's skill, how it was
/// chosen, its days so far, and how the week is going; on Sunday how it
/// went and the next. On the free plan what Astute+ changes, under it. The
/// box opens Your journey, where the week is day by day.
class FocusBox extends StatelessWidget {
  const FocusBox({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final WeekFocus focus = weekFocusOf(app);
    return Column(
      key: const ValueKey('profile-focus'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Eyebrow(l.focusTitle),
        const SizedBox(height: 11),
        _ProfileCard(
          key: const ValueKey('profile-focus-card'),
          onTap: () => _openJourney(context, app),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FocusHead(focus: focus),
              const SizedBox(height: 16),
              _WeekDays(
                week: focusWeek(app, focus),
                start: focus.start,
                today: app.today,
              ),
              const SizedBox(height: 14),
              _rule(context),
              const SizedBox(height: 11),
              _FocusTally(app: app, focus: focus),
            ],
          ),
        ),
        if (!app.isPlus) ...[
          const SizedBox(height: 10),
          _PlusLine(
            key: const ValueKey('profile-focus-plus'),
            text: l.focusPlus,
            onTap: () => _openJourney(context, app),
          ),
        ],
      ],
    );
  }
}

/// E at the head of Your journey: this week's skill, how it was chosen and
/// what its mark means, the week day by day with each day's answers, how it
/// is going, five cards to train it now, and last week's; on Sunday how it
/// went and the next.
class FocusPanel extends StatelessWidget {
  const FocusPanel({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final WeekFocus focus = weekFocusOf(app);
    return _Panel(
      child: Column(
        key: const ValueKey('journey-focus'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FocusHead(focus: focus, size: 24, mark: 44),
          const SizedBox(height: 12),
          Text(
            l.focusLine,
            style: AppText.body(
              size: 13.5,
              height: 1.35,
              color: p.ink.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 18),
          _WeekDays(
            week: focusWeek(app, focus),
            start: focus.start,
            today: app.today,
            counts: true,
          ),
          const SizedBox(height: 16),
          _rule(context),
          const SizedBox(height: 12),
          _FocusTally(app: app, focus: focus),
          const SizedBox(height: 18),
          _PracticeButton(app: app, skill: focus.skill),
        ],
      ),
    );
  }
}

/// Puts the sheet a card's mark opens in E: the week's skill, what its mark
/// means, and the way to the week in Your journey.
Future<void> showFocusMarkSheet(
  BuildContext context,
  AppState app,
  Skill skill,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  barrierColor: const Color(0x8C141416),
  builder: (_) => FocusMarkSheet(app: app, skill: skill),
);

/// The sheet. Public so a test can lay it out in every language.
class FocusMarkSheet extends StatelessWidget {
  const FocusMarkSheet({super.key, required this.app, required this.skill});

  final AppState app;
  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final WeekFocus focus = weekFocusOf(app);
    final FocusWeek week = focusWeek(app, focus);
    return Container(
      key: const ValueKey('focus-mark-sheet'),
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
        child: Column(
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
            const SizedBox(height: 22),
            Row(
              children: [
                _FocusMark(skill: skill, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _caps(context, l.focusTitle),
                        style: AppText.label(
                          size: 11,
                          spacing: 1.2,
                          color: p.ink.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Semantics(
                        header: true,
                        child: Text(
                          l.skillName(skill.name),
                          style: AppText.display(
                            size: 25,
                            weight: FontWeight.w600,
                            height: 1.1,
                            spacing: -0.5,
                            color: p.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l.focusMarkBody,
              style: AppText.body(
                size: 15,
                height: 1.38,
                color: p.ink.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 20),
            _WeekDays(week: week, start: focus.start, today: app.today),
            const SizedBox(height: 24),
            ChunkyButton(
              key: const ValueKey('focus-mark-open'),
              label: l.focusOpen,
              fill: p.inverse,
              ink: p.onInverse,
              height: 56,
              onPressed: () {
                final NavigatorState nav = Navigator.of(context);
                final BuildContext below = nav.context;
                nav.pop();
                _openJourney(below, app);
              },
            ),
          ],
        ),
      ),
    );
  }
}
