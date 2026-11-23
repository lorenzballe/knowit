/// The small mark a card carries in its head when it trains a skill the
/// reader put in focus (lib/data/skill_levels.dart), and the sheet the mark
/// opens: the skill the card trains, the reader's score in it with its
/// month (lib/data/skill_scores.dart), and the way to What to learn.
library;

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
import 'liked_mark.dart';
import 'skill_score.dart';

/// The mark of the skill in focus a card trains: the skill's own glyph, as
/// small as the heart a liked card carries and in the same ink, in the
/// card's head on the right, where that heart stands or just before it.
/// Nothing more: the card is the question, and this is a quiet word on what
/// it trains. A tap, on the card being read, opens what it means
/// ([showSkillMarkSheet]).
///
/// Laid over a card, it is the middle of a square a finger can find
/// ([touch]) that leaves the card's own layout as it is; set in a row, as on
/// the shelf, where it is only seen, the square is the glyph's own.
class SkillMark extends StatelessWidget {
  const SkillMark({
    super.key,
    required this.skill,
    required this.ink,
    this.scale = 1,
    this.reach = touch,
    this.onTap,
  });

  final Skill skill;

  /// The card's ink, as the heart's.
  final Color ink;

  /// The card's size against the deck's own.
  final double scale;

  /// The square it takes, at the deck's size.
  final double reach;

  /// Opens what the mark means; null, it is only seen.
  final VoidCallback? onTap;

  /// The glyph's size: the heart's, a touch larger for its finer lines.
  static const double size = 16;

  /// The square a tap on it is heard in, laid over a card.
  static const double touch = 36;

  /// Between it and the heart.
  static const double gap = 8;

  /// Where it stands in a drawn card's head: its middle, in from the card's
  /// right edge in the page's points, at the right side of where a liked
  /// card's heart stands, before its tag ([CardTags.heartRight]), or just
  /// before that heart when the card is liked.
  static double middleOnPage(String? tag, {required bool liked}) =>
      CardTags.heartRight(tag) + (liked ? LikedMark.size + gap : 0) + size / 2;

  /// Whether a card's head, [width] across, has room for the mark with its
  /// middle [middle] in from the right, after the subject's mark and name
  /// and the chip, set as the card sets them (pill_card.dart; on a drawn
  /// card, the kit in the app, docs/cards/kit/astute-card.css): a mark of
  /// 16, then 8, the name at 11 points in capitals with 1.4 between letters,
  /// then 9 and the chip at 9.5 with 1 between letters and 8 either side;
  /// at the reader's text size ([scaler]) on the app's own face, at the
  /// page's own on a drawn one. Where it has none, the mark is left out
  /// rather than laid on them.
  static bool fits({
    required double width,
    required double middle,
    required String subject,
    String? chip,
    TextScaler scaler = TextScaler.noScaling,
  }) {
    double measure(String text, double size, double spacing) {
      final TextPainter t = TextPainter(
        text: TextSpan(
          text: text.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Figtree',
            fontSize: size,
            fontWeight: FontWeight.w600,
            letterSpacing: spacing,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final double w = t.width;
      t.dispose();
      return w;
    }

    double left = CardTags.margin + 16 + 8 + measure(subject, 11, 1.4);
    if (chip != null) left += 9 + measure(chip, 9.5, 1) + 16;
    return width - middle - size / 2 - gap >= left;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return KeyedSubtree(
      key: ValueKey('skill-mark-${skill.name}'),
      child: Semantics(
        label: l.skillMarkLabel(l.skillName(skill.name)),
        button: onTap != null,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: SizedBox.square(
            dimension: reach * scale,
            child: Center(
              child: CustomPaint(
                size: Size.square(size * scale),
                painter: SkillGlyph(skill, ink.withValues(alpha: 0.9)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Puts the sheet a card's skill mark opens: the skill the card trains, that
/// it is one the reader put in focus, their level in it, and the way to What
/// to learn.
Future<void> showSkillMarkSheet(
  BuildContext context,
  AppState app,
  Skill skill, {
  String? cardId,
}) {
  Analytics.capture('skill mark opened', {
    'skill': skill.name,
    if (cardId != null) ...app.cardFacts(cardId),
  });
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (_) => SkillMarkSheet(app: app, skill: skill),
  );
}

/// The sheet. Public so a test can lay it out in every language.
class SkillMarkSheet extends StatelessWidget {
  const SkillMarkSheet({super.key, required this.app, required this.skill});

  final AppState app;
  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final SkillScore score = scoreBookOf(app).of(skill);
    return Container(
      key: const ValueKey('skill-mark-sheet'),
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
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: skill.hues,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: skill.hues.last.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: CustomPaint(
                    size: const Size.square(32),
                    painter: SkillGlyph(skill, skill.onHues),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.skillMarkKicker,
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
              l.skillMarkBody,
              style: AppText.body(
                size: 15,
                height: 1.38,
                color: p.ink.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              key: const ValueKey('skill-mark-level'),
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  scoreNumber(context, score.now),
                  style: AppText.display(
                    size: 30,
                    weight: FontWeight.w600,
                    height: 1,
                    color: p.ink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: score.answers == 0
                        ? ScoreWeek(score: score, size: 13.5)
                        : Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: l.scoreWeek(
                                    signedNumber(context, score.week),
                                  ),
                                  style: TextStyle(
                                    color: moveColour(context, score.week),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '  \u00b7  ${l.scoreAnswers(score.answers)}',
                                ),
                              ],
                            ),
                            style: AppText.body(
                              size: 13.5,
                              color: p.ink.withValues(alpha: 0.55),
                            ),
                          ),
                  ),
                ),
              ],
            ),
            if (score.answers > 0) ...[
              const SizedBox(height: 12),
              ScoreSpark(
                values: score.days,
                colour: skill.mark(p.isDark),
                height: 34,
              ),
            ],
            const SizedBox(height: 24),
            ChunkyButton(
              key: const ValueKey('skill-mark-open'),
              label: l.skillMarkOpen,
              fill: p.inverse,
              ink: p.onInverse,
              height: 56,
              onPressed: () {
                final NavigatorState nav = Navigator.of(context);
                nav.pop();
                nav.push(
                  MaterialPageRoute<void>(
                    builder: (_) => SkillsScreen(app: app),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
