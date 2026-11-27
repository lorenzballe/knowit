/// What to learn, three other ways, as the developer tools try them beside
/// the one that ships (DebugLooks.learn, lib/state/debug_looks.dart).
///
/// As it ships, a reader picks skills on What to learn, every skill has a
/// score with no top, a card that trains one picked carries its mark, its
/// back says how far the answer moved that score, Your journey opens on
/// Your training (the Astute score, the skills picked, "The others") and
/// the profile has a box of them. The owner did not believe in it. Three
/// answers, each built for real so it can be lived with on a phone:
///
/// - A, [LearnLook.score]: the Astute score alone. No picker, no marks, no
///   skill scores; Your training keeps the score, its line and its level.
/// - B, [LearnLook.aim]: one aim, asked once at the end of the first run:
///   where the reader wants to be sharper, one of the six areas the cards
///   already name on their backs ("Useful for: Money and shopping",
///   lib/data/goals.dart). Said in words and counts, never a score; a card
///   dealt for it says so under its head; its page holds its paths. The
///   question is now the profile's, for every reader, in every look
///   (lib/widgets/aim_picker.dart), with the aim's shelf on Explore every
///   day: B asks it at the end of the first run too, with the same rows,
///   and adds the aim's week under it on the profile and in Your journey.
/// - C, [LearnLook.profile]: nothing to pick. The skills are read from the
///   reader's answers, strongest first, each as right answers out of
///   answers given, with the weakest to practise: a chapter of Your journey
///   on Astute+, and on the free plan the strongest only, the rest behind
///   the journey's own door.
///
/// Nothing here is measured that was not measured before: no event is
/// added, and the doors to the plans are the ones that already exist.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/goals.dart';
import '../data/pill_bank.dart';
import '../data/pills_repository.dart' show dateKey, dealableOn;
import '../data/skill_levels.dart';
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

/// What to learn's look in this run.
LearnLook get learnLook => DebugLooks.learnPicked;

/// The skills whose mark a card carries and whose score its back moves:
/// the ones picked on What to learn, as it ships; none in the other looks,
/// where no card carries a skill's mark.
List<String> markedSkills(AppState app) =>
    learnLook == LearnLook.today ? app.skills : const [];

/// Whether a card dealt for the reader's goal keeps quiet about it under
/// its head: as it ships, where the mark of a skill picked says it already
/// ([marked]); in A and C, where the reader has no goal to be told of (the
/// goals a build before kept still lean the deals). Only B says it, in
/// words: "For your goal: Money and shopping".
bool goalUnsaid(AppState app, {required bool marked}) => switch (learnLook) {
  LearnLook.today => marked,
  LearnLook.aim => false,
  LearnLook.score || LearnLook.profile => true,
};

/// Capitals, with Turkish's dotted capital I.
String _caps(BuildContext context, String text) =>
    Localizations.localeOf(context).languageCode == 'tr'
    ? text.replaceAll('i', 'İ').toUpperCase()
    : text.toUpperCase();

/// A label in small capitals, as Your training's own.
Widget _smallCaps(BuildContext context, String text) => Text(
  _caps(context, text),
  style: AppText.body(
    size: 9.5,
    weight: FontWeight.w700,
    spacing: 1.3,
    color: context.p.ink.withValues(alpha: 0.45),
  ),
);

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

// ── The profile ───────────────────────────────────────────────────────────

/// Where the profile showed Your training, under the subjects: the box of
/// What to learn's look, or nothing in A. Changed in the developer tools,
/// it shows at once.
class LearnProfileBox extends StatelessWidget {
  const LearnProfileBox({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<LearnLook>(
    valueListenable: DebugLooks.learn,
    builder: (context, _, _) {
      final Widget? box = switch (learnLook) {
        LearnLook.today => ProfileTraining(app: app),
        LearnLook.score => null,
        // Picked in the section over it; with none, nothing to add here.
        LearnLook.aim => aimOf(app) == null ? null : AimBox(app: app),
        LearnLook.profile => StrengthsBox(app: app),
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

// ── B · One aim ───────────────────────────────────────────────────────────

/// The reader's aim: the first of their goals, the one B asks for.
Goal? aimOf(AppState app) => Goal.of(app.goal);

/// Whether [p] is one of [aim]'s own cards: in one of its genres or
/// training one of its moves, as the card's back names it ("Useful for").
bool _forAim(Goal aim, Pill p) => (aim.fitOf(p) ?? 2) < 2;

/// What the last [days] days did for the reader's aim: the cards of it
/// read, and the answers given on them, right and in all.
({int cards, int answers, int right}) aimTally(
  AppState app,
  Goal aim, {
  int days = 7,
}) {
  final DateTime t = app.today;
  final String from = dateKey(DateTime(t.year, t.month, t.day - (days - 1)));
  final Set<String> read = {
    for (final MapEntry<String, List<String>> e in app.readDays.entries)
      if (e.key.compareTo(from) >= 0) ...e.value,
  };
  var cards = 0;
  for (final String id in read) {
    final Pill? p = PillBank.byId(id);
    if (p != null && _forAim(aim, p)) cards++;
  }
  var answers = 0, right = 0;
  for (final Judgement j in app.judgements) {
    final String? id = j.pillId, on = j.on;
    if (id == null || on == null || on.compareTo(from) < 0) continue;
    final Pill? p = PillBank.byId(id);
    if (p == null || !_forAim(aim, p)) continue;
    answers++;
    if (j.correct) right++;
  }
  return (cards: math.max(cards, answers), answers: answers, right: right);
}

/// Opens the aim's own page: its paths, the moves it trains, more of it.
void _openAimPage(BuildContext context, AppState app, Goal aim) {
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

/// B on the profile: the aim, its line, what this week did for it, and on
/// the free plan what Astute+ adds to it. The card opens the aim's page.
/// It is picked in the section over it, where every reader picks it
/// (lib/widgets/aim_picker.dart): the box has no way of its own to change
/// it, and with none picked it is not there.
class AimBox extends StatelessWidget {
  const AimBox({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Goal? aim = aimOf(app);
    if (aim == null) return const SizedBox.shrink();
    return Column(
      key: const ValueKey('profile-aim'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Eyebrow(l.whyGoalRow),
        const SizedBox(height: 11),
        _ProfileCard(
          key: const ValueKey('profile-aim-card'),
          onTap: () => _openAimPage(context, app, aim),
          child: _AimSummary(app: app, aim: aim, size: 21),
        ),
        if (!app.isPlus) ...[
          const SizedBox(height: 10),
          _AimPlus(app: app, aim: aim),
        ],
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
        // The mark by the name's first line, where the name takes two.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.textScalerOf(context).scale(size) * 0.17,
              ),
              child: Icon(
                goalIcon(aim),
                size: 18,
                color: p.ink.withValues(alpha: 0.8),
              ),
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
        const SizedBox(height: 12),
        Container(height: 1, color: p.ink.withValues(alpha: 0.08)),
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

/// On the free plan, under the aim: what Astute+ does for it, the door to
/// the plans by its paths.
class _AimPlus extends StatelessWidget {
  const _AimPlus({required this.app, required this.aim});

  final AppState app;
  final Goal aim;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    return Semantics(
      button: true,
      child: GestureDetector(
        key: const ValueKey('profile-aim-plus'),
        behavior: HitTestBehavior.opaque,
        onTap: () => requirePlus(
          context,
          app,
          () => _openAimPage(context, app, aim),
          source: 'paths',
        ),
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
                  l.aimPlus,
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

/// B in Your journey, under the Astute score: the aim, what the week did
/// for it, and the way to its page. With none, what an aim does and the
/// way to pick one.
class AimPanel extends StatelessWidget {
  const AimPanel({super.key, required this.app});

  final AppState app;

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
          _smallCaps(context, l.whyGoalRow),
          const SizedBox(height: 10),
          if (aim == null) ...[
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
          ] else ...[
            _AimSummary(app: app, aim: aim, size: 24),
            const SizedBox(height: 14),
            GestureDetector(
              key: const ValueKey('journey-aim-open'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _openAimPage(context, app, aim),
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

/// How many answers a skill needs behind it to be ranked: fewer, and two
/// lucky answers would make it the reader's strong point.
const int kStrengthAnswers = 4;

/// A skill read from the reader's answers: how many were given on cards
/// that train it, and how many were right.
class SkillTally {
  const SkillTally(this.skill, this.answers, this.right);

  final Skill skill;
  final int answers;
  final int right;

  /// The share right, drawn a little towards a half while answers are few,
  /// so three right of three does not outrank twenty of twenty-four.
  double get rank => (right + 1) / (answers + 2);
}

/// Every skill as the reader's answers have it, the ranked first, strongest
/// first (of two as strong, the one with more answers, then What to learn's
/// order), and after them the ones with too few answers, in that order.
List<SkillTally> skillTallies(AppState app) {
  final Map<Skill, int> answers = {for (final Skill s in Skill.values) s: 0};
  final Map<Skill, int> right = {for (final Skill s in Skill.values) s: 0};
  for (final Judgement j in app.judgements) {
    final String? id = j.pillId;
    if (id == null) continue;
    final Pill? p = PillBank.byId(id);
    if (p == null || !p.isGraded) continue;
    for (final Skill s in Skill.values) {
      if (!s.trains(p)) continue;
      answers[s] = answers[s]! + 1;
      if (j.correct) right[s] = right[s]! + 1;
    }
  }
  final List<SkillTally> all = [
    for (final Skill s in Skill.values) SkillTally(s, answers[s]!, right[s]!),
  ];
  final List<SkillTally> ranked =
      [
        for (final SkillTally t in all)
          if (t.answers >= kStrengthAnswers) t,
      ]..sort((a, b) {
        final int byRank = b.rank.compareTo(a.rank);
        if (byRank != 0) return byRank;
        final int byAnswers = b.answers.compareTo(a.answers);
        if (byAnswers != 0) return byAnswers;
        return a.skill.index.compareTo(b.skill.index);
      });
  return [
    ...ranked,
    for (final SkillTally t in all)
      if (t.answers < kStrengthAnswers) t,
  ];
}

/// The ranked of [tallies]: the skills with enough answers behind them.
List<SkillTally> _ranked(List<SkillTally> tallies) => [
  for (final SkillTally t in tallies)
    if (t.answers >= kStrengthAnswers) t,
];

/// Five cards to practise [skill] on: not read yet, that ask, that can be
/// dealt today, the ones that train it most closely first.
List<Pill> practiceCards(AppState app, Skill skill, {int count = 5}) {
  final int seed = app.today.difference(DateTime(2026)).inDays;
  int mix(String id) {
    var h = 0x811c9dc5 ^ seed;
    for (final int c in id.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h;
  }

  final List<(int, int, Pill)> pool = [
    for (final Pill p in PillBank.cards)
      if (p.isGraded && !app.seenIds.contains(p.id) && dealableOn(p, app.today))
        if (skill.fitOf(p) case final int fit) (fit, mix(p.id), p),
  ]..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2.compareTo(b.$2));
  return [for (final (_, _, Pill p) in pool.take(count)) p];
}

/// A skill's mark as C draws it: its glyph in the page's ink, on a square
/// of a hairline, never on the skill's two hues.
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

/// One skill in the profile's box: a kicker, its mark and name, and its
/// right answers out of those given.
class _StrengthLine extends StatelessWidget {
  const _StrengthLine({required this.kicker, required this.tally});

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
          Container(height: 1, color: p.ink.withValues(alpha: 0.08)),
          const SizedBox(height: 12),
          if (app.isPlus && ranked.length > 1)
            _StrengthLine(kicker: l.strengthsWeak, tally: ranked.last)
          else
            Row(
              key: const ValueKey('profile-strengths-locked'),
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
                    l.strengthsLocked,
                    style: AppText.body(
                      size: 13,
                      height: 1.38,
                      weight: FontWeight.w600,
                      color: p.ink.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ],
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

/// C in Your journey, under the Astute score: every skill read from the
/// reader's answers, strongest first, each with its right answers out of
/// those given and a bar of the share; the ones with too few answers named
/// at the foot; and the weakest to practise, five cards of it.
class StrengthsPanel extends StatelessWidget {
  const StrengthsPanel({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final List<SkillTally> tallies = skillTallies(app);
    final List<SkillTally> ranked = _ranked(tallies);
    final List<SkillTally> few = [
      for (final SkillTally t in tallies)
        if (t.answers < kStrengthAnswers) t,
    ];
    final SkillTally? weakest = ranked.length > 1 ? ranked.last : null;
    return _Panel(
      child: Column(
        key: const ValueKey('journey-strengths'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _smallCaps(context, l.strengthsTitle),
          const SizedBox(height: 8),
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
            Text(
              l.strengthsFew(
                [for (final SkillTally t in few) l.skillName(t.skill.name)]
                    .join(', '),
              ),
              key: const ValueKey('journey-strengths-few'),
              style: AppText.body(
                size: 12.5,
                height: 1.4,
                color: p.ink.withValues(alpha: 0.5),
              ),
            ),
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

/// The weakest skill to practise: five cards of it, answered as the day's
/// are, the answer held until the reader commits.
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
/// those given, and under them a bar of the share right, in the page's ink.
class _StrengthRow extends StatelessWidget {
  const _StrengthRow({required this.tally, required this.place});

  final SkillTally tally;
  final int place;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final double share = tally.answers == 0 ? 0 : tally.right / tally.answers;
    final String name = l.skillName(tally.skill.name);
    final String right = l.answersRightOf(tally.right, tally.answers);
    return Semantics(
      container: true,
      label: '$place. $name, $right',
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
        ],
      ),
    );
  }
}
