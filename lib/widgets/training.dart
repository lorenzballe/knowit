/// The reader's training: the skills they picked to get better at
/// (lib/data/skills.dart, picked on What to learn) and their score in each,
/// a number with no top that every answer moves, shown from 0
/// (lib/data/skill_scores.dart).
///
/// One vocabulary across the app: the skill's badge (its glyph on its two
/// hues), its score and its line over the month (lib/widgets/skill_score.dart).
/// The subjects are coloured pills, what the reader reads; the skills are
/// never pills, they are what the reading trains. Shown in two places: the
/// first chapter of Your journey ([TrainingChapter]), where every score
/// counts from where the reader last saw it, and a box on the profile
/// ([ProfileTraining]). What the day's cards did to the scores is not said
/// over the finished day any more: the journey says it, counting.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../analytics.dart';
import '../data/skill_scores.dart';
import '../data/skills.dart';
import '../l10n/l10n.dart';
import '../screens/skills_screen.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'chunky.dart';
import 'count_since.dart';
import 'fit_text.dart';
import 'level_up.dart' show LevelLine;
import 'skill_score.dart';
import 'skills_sheet.dart' show showSkillsSheet;
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

/// A score's number as the training sets it: the reader's digits, in
/// figures of one width, so a score counting up does not shake.
TextStyle _figures(TextStyle style) =>
    style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

/// A score that counts from where the reader last saw it on the journey
/// (count_since.dart): [builder] draws the number at each step, and the
/// mark of how far it went.
Widget _counted(
  String id,
  SkillScore score,
  Widget Function(BuildContext context, String number, Widget? mark) builder,
) => CountSince(
  id: id,
  value: score.now.toDouble(),
  shows: (v) => '${v.round()}',
  builder: (context, v, mark) =>
      builder(context, scoreNumber(context, v.round()), mark),
);

/// One skill the reader picked, tight: its badge, its name and how far its
/// score moved this week, its line over the month, small, and the score,
/// with the mark of how far it went since the reader last looked under it.
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
      child: Row(
        key: ValueKey('training-row-${skill.name}'),
        children: [
          SkillBadge(skill: skill, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.skillName(skill.name),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    size: 14.5,
                    weight: FontWeight.w700,
                    height: 1.2,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 1),
                ScoreWeek(score: score, size: 11.5),
              ],
            ),
          ),
          if (score.answers > 0) ...[
            const SizedBox(width: 10),
            ExcludeSemantics(
              child: SizedBox(
                width: 44,
                child: ScoreSpark(
                  values: score.days,
                  colour: lineColour(context, skill),
                  height: 18,
                ),
              ),
            ),
          ],
          const SizedBox(width: 12),
          _counted(
            'skill.${skill.name}',
            score,
            (context, number, mark) => Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  number,
                  style: _figures(
                    AppText.display(
                      size: 19,
                      weight: FontWeight.w600,
                      height: 1.1,
                      color: p.ink,
                    ),
                  ),
                ),
                ?mark,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A skill not picked, in the zone below: its badge, its name and its
/// score, two to a row where every name keeps its words whole ([fitsIn]).
class _SkillCell extends StatelessWidget {
  const _SkillCell({required this.skill, required this.score});

  final Skill skill;
  final SkillScore score;

  static const double _badge = 22;

  /// The smallest the name is set, to keep a long word whole.
  static const double _nameLeast = 10.5;

  static TextStyle _name(Palette p) => AppText.body(
    size: 12.5,
    weight: FontWeight.w600,
    height: 1.15,
    color: p.ink,
  );

  static TextStyle _number(Palette p) => _figures(
    AppText.body(
      size: 12.5,
      weight: FontWeight.w700,
      color: p.ink.withValues(alpha: 0.55),
    ),
  );

  /// Whether the cell keeps every word of its name whole in [width]: what
  /// its badge, its gaps and its score take, the score's room kept for a
  /// mark as long as the score under it, and what is left for the name's
  /// widest word at the smallest size the name is set.
  static bool fitsIn(
    BuildContext context,
    Skill skill,
    SkillScore score,
    double width,
  ) {
    final p = context.p;
    final TextStyle ground = DefaultTextStyle.of(context).style;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection direction = Directionality.of(context);
    double widthOf(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: ground.merge(style)),
        maxLines: 1,
        textDirection: direction,
        textScaler: scaler,
      )..layout();
      final double w = painter.width;
      painter.dispose();
      return w;
    }

    final String number = scoreNumber(context, score.now);
    final double figures = math.max(
      widthOf(number, _number(p)),
      widthOf('+$number', SinceMark.styleIn(p.ink)),
    );
    return FitText.wordsFit(
      context.l10n.skillName(skill.name),
      ground.merge(_name(p).copyWith(fontSize: _nameLeast)),
      scaler,
      direction,
      width - _badge - 8 - 6 - figures,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Row(
      key: ValueKey('training-other-${skill.name}'),
      children: [
        SkillBadge(skill: skill, size: _badge),
        const SizedBox(width: 8),
        // Beside a score of three figures a name has little more than
        // eighty points on a small phone, less than some of its words need
        // ("wetenschapper"): set a size or two down until each word is
        // whole, rather than cut or broken in the middle.
        Expanded(
          child: FitText(
            context.l10n.skillName(skill.name),
            maxLines: 2,
            minSize: _nameLeast,
            wholeWords: true,
            style: _name(p),
          ),
        ),
        const SizedBox(width: 6),
        _counted(
          'skill.${skill.name}',
          score,
          (context, number, mark) => Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(number, style: _number(p)),
              ?mark,
            ],
          ),
        ),
      ],
    );
  }
}

/// The first chapter of Your journey: the reader's Astute score, every
/// answer's, set large, with its week and its month; under it, tight, each
/// skill they picked with its own; the others in a zone of their own below,
/// two to a row, each with its score. With none picked, what training is
/// and the way to pick. The chapter's head carries the way to change them
/// ([TrainingChapter.change]). Every score counts from where the reader
/// last saw it on the journey.
///
/// The skills were each a row as large as the Astute score's own, a badge,
/// a name, a number and a line apiece, four of them as tall as a phone: the
/// owner asked for the one number to stay large and the rest to be smaller
/// and tighter.
class TrainingChapter extends StatelessWidget {
  const TrainingChapter({
    super.key,
    required this.app,
    this.skills = true,
    this.label = true,
  });

  final AppState app;

  /// Whether the skills follow the score: false for the looks of What to
  /// learn that have none (lib/widgets/learn_looks.dart), where the chapter
  /// is the Astute score, its line over the month and its level.
  final bool skills;

  /// Whether the score carries its name over it: false where the chapter's
  /// head already says it.
  final bool label;

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
    final Widget rule = Container(
      height: 1,
      color: p.ink.withValues(alpha: 0.08),
    );
    // The one number is every reader's, skills picked or not, and its line
    // over the month; under it, the level it has reached and how far the
    // next one is, on the panel's own ground (lib/widgets/level_up.dart).
    final List<Widget> score = [
      _Overall(score: book.overall, label: label),
      if (book.overall.answers > 0) ...[
        const SizedBox(height: 12),
        ScoreSpark(values: book.overall.days, colour: p.ink, height: 40),
      ],
      const SizedBox(height: 16),
      LevelLine(app: app, framed: false),
    ];
    if (!skills) {
      return _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: score,
        ),
      );
    }
    final Widget top = _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...score,
          if (picked.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              l.trainingLine,
              style: AppText.body(
                size: 13.5,
                height: 1.35,
                color: p.ink.withValues(alpha: 0.62),
              ),
            ),
          ],
          const SizedBox(height: 16),
          rule,
          if (picked.isEmpty) ...[
            const SizedBox(height: 16),
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
          ] else
            for (final (int i, Skill s) in picked.indexed) ...[
              SizedBox(height: i == 0 ? 14 : 12),
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
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  LayoutBuilder(
                    builder: (context, box) {
                      const double gap = 14;
                      // Two to a row; one where a column would be too
                      // narrow for a name and its score: in German or
                      // Russian on a small phone, where a word of a name
                      // would not stay whole beside a score of three
                      // figures.
                      final double half = (box.maxWidth - gap) / 2;
                      final bool two = others.every(
                        (s) => _SkillCell.fitsIn(context, s, book.of(s), half),
                      );
                      final double width = two ? half : box.maxWidth;
                      return Wrap(
                        spacing: gap,
                        runSpacing: 10,
                        children: [
                          for (final Skill s in others)
                            SizedBox(
                              width: width,
                              child: _SkillCell(skill: s, score: book.of(s)),
                            ),
                        ],
                      );
                    },
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
/// large, the mark of how far it went since the reader last looked at its
/// shoulder, and how far it moved this week.
class _Overall extends StatelessWidget {
  const _Overall({required this.score, this.label = true});

  final SkillScore score;

  /// Whether its name stands over it.
  final bool label;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Column(
      key: const ValueKey('training-score'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label) ...[
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
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _counted(
              'score',
              score,
              (context, number, mark) => Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style: _figures(
                      AppText.display(
                        size: 44,
                        weight: FontWeight.w600,
                        height: 1,
                        spacing: -1,
                        color: p.ink,
                      ),
                    ),
                  ),
                  if (mark != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 1),
                      child: mark,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ScoreWeek(score: score, size: 13),
              ),
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
        // The owner's mix: the skills as they are, behind a tap, in a sheet
        // like the goal's (lib/widgets/skills_sheet.dart).
        onTap: () => showSkillsSheet(context, app),
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
                    Icons.expand_more_rounded,
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
