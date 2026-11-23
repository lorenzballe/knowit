/// The reader's training: the skills they picked to get better at
/// (lib/data/skills.dart, picked on What to learn), their score in each, a
/// number with no top that every answer moves (lib/data/skill_scores.dart),
/// and what a day's cards did to it.
///
/// One vocabulary across the app: the skill's badge (its glyph on its two
/// hues), its score and its line over the month (lib/widgets/skill_score.dart).
/// The subjects are coloured pills, what the reader reads; the skills are
/// never pills, they are what the reading trains. Shown in three places: the first chapter of Your journey
/// ([TrainingChapter]), a box on the profile ([ProfileTraining]), and the
/// sheet that rises when the day's cards are done ([showDayTraining]).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../analytics.dart';
import '../data/skill_levels.dart';
import '../data/skill_scores.dart';
import '../data/skills.dart';
import '../l10n/l10n.dart';
import '../screens/skills_screen.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'chunky.dart';
import 'skill_score.dart';
import 'ui.dart' show Eyebrow;

/// The skills [app]'s reader picked, in the order they picked them, that
/// this build knows.
List<Skill> pickedSkills(AppState app) => [
  for (final String k in app.skills)
    if (Skill.of(k) case final Skill s) s,
];

/// Opens What to learn, where skills are picked and every level is shown.
void openSkills(BuildContext context, AppState app, {required String from}) {
  HapticFeedback.selectionClick();
  Analytics.capture('skills opened', {'from': from});
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => SkillsScreen(app: app)));
}

/// A skill's badge: its glyph on a rounded square of its two hues, as What
/// to learn and the mark's sheet draw it.
class SkillBadge extends StatelessWidget {
  const SkillBadge({super.key, required this.skill, required this.size});

  final Skill skill;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.3),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: skill.hues,
      ),
    ),
    alignment: Alignment.center,
    child: CustomPaint(
      size: Size.square(size * 0.6),
      painter: SkillGlyph(skill, skill.onHues),
    ),
  );
}

/// The faint panel the training sits on, as the journey's tiles.
class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: context.p.ink.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(22),
    ),
    child: child,
  );
}

/// The colour a skill's line is drawn in: its own, a shade darker on paper.
Color lineColour(BuildContext context, Skill s) => s.mark(context.p.isDark);

/// One skill the reader picked, at full size: its badge, its name and how
/// far its score moved this week, the score, and its line over the month.
class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill, required this.score});

  final Skill skill;
  final SkillScore score;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final l = context.l10n;
    return Semantics(
      container: true,
      child: Column(
        key: ValueKey('training-row-${skill.name}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SkillBadge(skill: skill, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.skillName(skill.name),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 16,
                        weight: FontWeight.w700,
                        height: 1.2,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    ScoreWeek(score: score),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                scoreNumber(context, score.now),
                style: AppText.display(
                  size: 25,
                  weight: FontWeight.w600,
                  height: 1.1,
                  color: p.ink,
                ),
              ),
            ],
          ),
          if (score.answers > 0) ...[
            const SizedBox(height: 10),
            ScoreSpark(
              values: score.days,
              colour: lineColour(context, skill),
              height: 26,
            ),
          ],
        ],
      ),
    );
  }
}

/// A skill not picked, small: its badge, its name and its score.
class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.skill, required this.score});

  final Skill skill;
  final SkillScore score;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      key: ValueKey('training-other-${skill.name}'),
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SkillBadge(skill: skill, size: 22),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              context.l10n.skillName(skill.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                size: 12.5,
                weight: FontWeight.w600,
                color: p.ink,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            scoreNumber(context, score.now),
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w700,
              color: p.ink.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// The first chapter of Your journey: the reader's Astute score, every
/// answer's, with its week and its month; then each skill they picked with
/// its own; the others under them, small, each with its score. With none
/// picked, what training is and the way to pick. The chapter's head carries
/// the way to change them ([TrainingChapter.change]).
class TrainingChapter extends StatelessWidget {
  const TrainingChapter({super.key, required this.app});

  final AppState app;

  /// The link at the end of the chapter's head: to What to learn.
  static Widget change(BuildContext context, AppState app) => Semantics(
    button: true,
    child: GestureDetector(
      key: const ValueKey('training-change'),
      behavior: HitTestBehavior.opaque,
      onTap: () => openSkills(context, app, from: 'journey'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          context.l10n.edit,
          style: AppText.body(
            size: 12.5,
            weight: FontWeight.w600,
            color: context.p.link,
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final l = context.l10n;
    final ScoreBook book = scoreBookOf(app);
    final List<Skill> picked = pickedSkills(app);
    final List<Skill> others = [
      for (final Skill s in Skill.values)
        if (!picked.contains(s)) s,
    ];
    final Widget top = picked.isEmpty
        ? _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.trainingEmpty,
                  style: AppText.body(
                    size: 15,
                    height: 1.38,
                    color: p.ink.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 16),
                ChunkyButton(
                  key: const ValueKey('training-pick'),
                  label: l.trainingPick,
                  fill: p.inverse,
                  ink: p.onInverse,
                  height: 52,
                  onPressed: () => openSkills(context, app, from: 'journey'),
                ),
              ],
            ),
          )
        : _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Overall(score: book.overall),
                const SizedBox(height: 8),
                Text(
                  l.trainingLine,
                  style: AppText.body(
                    size: 13.5,
                    height: 1.35,
                    color: p.ink.withValues(alpha: 0.62),
                  ),
                ),
                if (book.overall.answers > 0) ...[
                  const SizedBox(height: 12),
                  ScoreSpark(
                    values: book.overall.days,
                    colour: p.ink,
                    height: 40,
                  ),
                ],
                const SizedBox(height: 18),
                Container(height: 1, color: p.ink.withValues(alpha: 0.08)),
                for (final Skill s in picked) ...[
                  const SizedBox(height: 18),
                  _SkillRow(skill: s, score: book.of(s)),
                ],
              ],
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        top,
        if (others.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => openSkills(context, app, from: 'journey others'),
            child: _Panel(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _caps(context, l.trainingOthers),
                    style: AppText.body(
                      size: 9.5,
                      weight: FontWeight.w700,
                      spacing: 1.3,
                      color: p.ink.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final Skill s in others)
                        _SkillChip(skill: s, score: book.of(s)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The Astute score at the head of Your training: its name, the number
/// big, and how far it moved this week.
class _Overall extends StatelessWidget {
  const _Overall({required this.score});

  final SkillScore score;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Column(
      key: const ValueKey('training-score'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _caps(context, context.l10n.scoreTitle),
          style: AppText.body(
            size: 9.5,
            weight: FontWeight.w700,
            spacing: 1.3,
            color: p.ink.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 12,
          children: [
            Text(
              scoreNumber(context, score.now),
              style: AppText.display(
                size: 44,
                weight: FontWeight.w600,
                height: 1,
                spacing: -1,
                color: p.ink,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ScoreWeek(score: score, size: 13),
            ),
          ],
        ),
      ],
    );
  }
}

/// Capitals, with Turkish's dotted capital I.
String _caps(BuildContext context, String text) =>
    Localizations.localeOf(context).languageCode == 'tr'
    ? text.replaceAll('i', 'İ').toUpperCase()
    : text.toUpperCase();

/// The profile's training: under the subjects, which are coloured pills, not
/// a second wall of pills but the skills picked, at most three, each with its
/// badge, its score and its week; with none picked, what training is. The
/// whole box opens What to learn, where they are picked and every score is.
class ProfileTraining extends StatelessWidget {
  const ProfileTraining({super.key, required this.app});

  final AppState app;

  /// How many of the skills picked the box shows.
  static const int shown = 3;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final l = context.l10n;
    final List<Skill> picked = pickedSkills(app);
    final ScoreBook book = scoreBookOf(app);
    final Widget inside = picked.isEmpty
        ? Text(
            l.trainingEmpty,
            style: AppText.body(
              size: 14,
              height: 1.38,
              color: p.ink.withValues(alpha: 0.72),
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (int i, Skill s) in picked.take(shown).indexed) ...[
                if (i > 0) const SizedBox(height: 13),
                _row(context, s, book.of(s)),
              ],
              if (picked.length > shown) ...[
                const SizedBox(height: 11),
                Text(
                  l.trainingMore(picked.length - shown),
                  style: AppText.body(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: p.ink.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          );
    return Semantics(
      container: true,
      button: true,
      label: [
        l.trainingTitle,
        for (final Skill s in picked.take(shown))
          '${l.skillName(s.name)}, ${scoreNumber(context, book.of(s).now)}',
        if (picked.isEmpty) l.trainingEmpty,
      ].join('. '),
      hint: l.edit,
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('profile-skills'),
        behavior: HitTestBehavior.opaque,
        onTap: () => openSkills(context, app, from: 'profile'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Eyebrow(l.trainingTitle)),
                Text(
                  l.edit,
                  style: AppText.body(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: p.link,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            // The profile's own card, as Your journey's under it.
            Container(
              key: const ValueKey('profile-training'),
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
              decoration: BoxDecoration(
                color: p.surfaceRaised,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: p.line),
              ),
              child: Row(
                children: [
                  Expanded(child: inside),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: p.ink.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, Skill s, SkillScore score) {
    final p = context.p;
    final l = context.l10n;
    return Row(
      key: ValueKey('profile-training-${s.name}'),
      children: [
        SkillBadge(skill: s, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.skillName(s.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 14.5,
                  weight: FontWeight.w700,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 2),
              ScoreWeek(score: score, size: 12),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          scoreNumber(context, score.now),
          style: AppText.display(
            size: 19,
            weight: FontWeight.w600,
            color: p.ink,
          ),
        ),
      ],
    );
  }
}

/// What the day did to one skill: how many of its cards train it, and the
/// skill's score at the end of yesterday and now.
@immutable
class DayTraining {
  const DayTraining({
    required this.skill,
    required this.plus,
    required this.before,
    required this.after,
  });

  final Skill skill;

  /// How many of the day's cards, new to the reader, train it.
  final int plus;

  /// The skill's score at the end of yesterday, and now.
  final int before;
  final int after;

  /// How far the day moved it.
  int get moved => after - before;
}

/// What [app]'s day did in the skills the reader picked: those the day's
/// cards trained or whose score the day moved, the most moved first, at most
/// three. A card back for another go was read before and is not counted as
/// one of the day's. Empty when the reader picked none, or the day touched
/// none of them.
List<DayTraining> dayTrainingOf(AppState app) {
  final List<Skill> picked = pickedSkills(app);
  if (picked.isEmpty) return const [];
  final Map<Skill, int> today = cardsTrainingEach([
    for (final p in app.todaysDeck)
      if (!app.reviewIdsToday.contains(p.id)) p.id,
  ]);
  final ScoreBook book = scoreBookOf(app);
  final List<DayTraining> out = [
    for (final Skill s in picked)
      if ((today[s] ?? 0) > 0 || book.of(s).today != 0)
        DayTraining(
          skill: s,
          plus: today[s] ?? 0,
          before: book.of(s).now - book.of(s).today,
          after: book.of(s).now,
        ),
  ];
  // The most moved first; then the most trained; then the one picked first.
  final List<(int, DayTraining)> ranked = [...out.indexed]
    ..sort((a, b) {
      int by = b.$2.moved.abs().compareTo(a.$2.moved.abs());
      if (by == 0) by = b.$2.plus.compareTo(a.$2.plus);
      return by != 0 ? by : a.$1.compareTo(b.$1);
    });
  return [for (final (_, DayTraining d) in ranked.take(3)) d];
}

/// Puts the sheet that marks the day done: all of the day's cards read, and
/// what they did to the scores, each counting from where it stood this
/// morning.
Future<void> showDayTraining(
  BuildContext context,
  AppState app,
  List<DayTraining> items,
) {
  Analytics.capture('day training shown', {
    'skills': items.map((d) => d.skill.name).join(','),
    'rose': items.where((d) => d.moved > 0).length,
  });
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (_) =>
        DayTrainingSheet(app: app, items: items, cards: app.todaysDeck.length),
  );
}

/// The sheet. Public so a test can lay it out in every language.
class DayTrainingSheet extends StatefulWidget {
  const DayTrainingSheet({
    super.key,
    required this.app,
    required this.items,
    required this.cards,
  });

  final AppState app;
  final List<DayTraining> items;

  /// How many cards the day had: five, six on a Sunday.
  final int cards;

  @override
  State<DayTrainingSheet> createState() => _DayTrainingSheetState();
}

class _DayTrainingSheetState extends State<DayTrainingSheet>
    with SingleTickerProviderStateMixin {
  /// The scores counting, one after another.
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 700 + 220 * widget.items.length),
  );

  @override
  void initState() {
    super.initState();
    // A beat for the sheet to come up, then the scores.
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _fill.value = 1;
      } else {
        _fill.forward();
      }
      if (widget.items.any((d) => d.moved > 0)) {
        HapticFeedback.mediumImpact();
      }
    });
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  /// How far the [i]th score has counted, 0 to 1: each starts a little
  /// after the one above it.
  double _at(int i) {
    const double lag = 0.18;
    final double window = 1 - lag * (widget.items.length - 1);
    final double t = ((_fill.value - lag * i) / window).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final l = context.l10n;
    return Container(
      key: const ValueKey('day-training'),
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
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text(
                l.trainingDayTitle('${widget.cards}'),
                style: AppText.display(
                  size: 28,
                  weight: FontWeight.w600,
                  height: 1.1,
                  spacing: -0.6,
                  color: p.ink,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _dayScore(context),
            const SizedBox(height: 18),
            AnimatedBuilder(
              animation: _fill,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (int i, DayTraining d)
                      in widget.items.indexed) ...[
                    if (i > 0) const SizedBox(height: 16),
                    _item(context, d, _at(i)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 26),
            ChunkyButton(
              key: const ValueKey('day-training-done'),
              label: l.skillsDone,
              fill: p.inverse,
              ink: p.onInverse,
              height: 56,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                key: const ValueKey('day-training-levels'),
                onPressed: () {
                  final NavigatorState nav = Navigator.of(context);
                  nav.pop();
                  nav.push(
                    MaterialPageRoute<void>(
                      builder: (_) => SkillsScreen(app: widget.app),
                    ),
                  );
                },
                child: Text(
                  l.skillMarkOpen,
                  style: AppText.body(
                    size: 14,
                    weight: FontWeight.w600,
                    color: p.link,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The Astute score under the title, and how far today moved it.
  Widget _dayScore(BuildContext context) {
    final p = context.p;
    final l = context.l10n;
    final SkillScore overall = scoreBookOf(widget.app).overall;
    return Text.rich(
      key: const ValueKey('day-training-score'),
      TextSpan(
        children: [
          TextSpan(text: '${l.scoreTitle} '),
          TextSpan(
            text: scoreNumber(context, overall.now),
            style: TextStyle(color: p.ink, fontWeight: FontWeight.w700),
          ),
          const TextSpan(text: '  \u00b7  '),
          TextSpan(
            text: l.scoreToday(signedNumber(context, overall.today)),
            style: TextStyle(
              color: moveColour(context, overall.today),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      style: AppText.body(
        size: 15,
        height: 1.35,
        color: p.ink.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _item(BuildContext context, DayTraining d, double t) {
    final p = context.p;
    final l = context.l10n;
    final int shown = (d.before + d.moved * t).round();
    final Color moved = moveColour(context, d.moved);
    return Row(
      key: ValueKey('day-training-${d.skill.name}'),
      children: [
        SkillBadge(skill: d.skill, size: 38),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l.skillName(d.skill.name),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              size: 15,
              weight: FontWeight.w700,
              height: 1.2,
              color: p.ink,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          scoreNumber(context, shown),
          style: AppText.display(
            size: 21,
            weight: FontWeight.w600,
            color: p.ink,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: moved.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            signedNumber(context, d.moved),
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w800,
              color: moved,
            ),
          ),
        ),
      ],
    );
  }
}
