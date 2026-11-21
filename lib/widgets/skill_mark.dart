/// The mark a card carries when it trains a skill the reader picked in What
/// to learn (lib/data/skill_levels.dart), the bar of a skill's level, and
/// the sheet the mark opens.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../analytics.dart';
import '../data/skill_levels.dart';
import '../data/skills.dart';
import '../l10n/l10n.dart';
import '../screens/skills_screen.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'chunky.dart';

/// A skill's level as a bar of five, one a level: those climbed full, the one
/// being climbed filled as far as the next level comes nearer, all five full
/// at the top; in the skill's two hues.
class SkillBar extends StatelessWidget {
  const SkillBar({
    super.key,
    required this.skill,
    required this.level,
    this.height = 5,
  });

  final Skill skill;
  final SkillLevel level;
  final double height;

  /// How full the [i]th of the five is.
  double fillOf(int i) {
    if (level.level >= SkillLevel.top || i < level.level - 1) return 1;
    if (i == level.level - 1) return level.toNext.clamp(0.0, 1.0);
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final Color track = p.ink.withValues(alpha: p.isDark ? 0.14 : 0.1);
    final LinearGradient hues = LinearGradient(colors: skill.hues);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (int i = 0; i < SkillLevel.top; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(height),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: track),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fillOf(i),
                      child: DecoratedBox(
                        decoration: BoxDecoration(gradient: hues),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The mark a card carries when it trains one of the skills the reader put
/// in focus: the skill's badge, round, its two hues and its mark, ringed in
/// white so it stands off any card's colour, on the card's top right corner
/// as a dot on an app's icon says there is something for you there. The
/// badge is the one the skill has in What to learn, so the two read as one.
/// It comes in with the card, swelling into place. A tap, on the card being
/// read, says what it means ([showSkillMarkSheet]).
///
/// Laid in a card's own corner ([room] square, the card's top right), it
/// stands where nothing of the card's is: a card's corner is round, and its
/// head starts below it.
class SkillMark extends StatelessWidget {
  const SkillMark({super.key, required this.skill, this.scale = 1, this.onTap});

  final Skill skill;

  /// The card's size against the deck's own.
  final double scale;

  /// Opens what the mark means; null, it is only seen.
  final VoidCallback? onTap;

  /// The badge's size on a card being read, ring included.
  static const double size = 24;

  /// How far in from the card's top and right edges the badge stands: so
  /// near the corner that it hangs over its curve, as an app's dot does,
  /// clear of the tag a drawn card prints at the right of its head.
  static const double inset = 2;

  /// The corner a tap on the badge is heard in, square.
  static const double room = 46;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    final double d = size * scale;
    final Widget badge = Container(
      width: d,
      height: d,
      padding: EdgeInsets.all(1.8 * scale),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0x40000000),
            blurRadius: 5 * scale,
            offset: Offset(0, 1.5 * scale),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: skill.hues,
          ),
        ),
        child: Center(
          child: CustomPaint(
            size: Size.square(d * 0.58),
            painter: SkillGlyph(skill, skill.onHues),
          ),
        ),
      ),
    );
    final String name = context.l10n.skillName(skill.name);
    return KeyedSubtree(
      key: ValueKey('skill-mark-${skill.name}'),
      child: Semantics(
        label: context.l10n.skillMarkLabel(name),
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
            dimension: room * scale,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(
                  top: inset * scale,
                  right: inset * scale,
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: still ? 1 : 0, end: 1),
                  duration: Duration(milliseconds: still ? 0 : 460),
                  curve: Curves.easeOutBack,
                  builder: (context, t, child) => Transform.scale(
                    scale: 0.4 + 0.6 * t,
                    child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
                  ),
                  child: badge,
                ),
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
    final SkillLevel level = SkillLevel.of(
      cardsTrainingEach(app.seenIds)[skill] ?? 0,
    );
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
            Text(
              '${l.skillLevel(level.level)} · ${l.nCards(level.cards)}',
              key: const ValueKey('skill-mark-level'),
              style: AppText.body(
                size: 14,
                weight: FontWeight.w700,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 9),
            SkillBar(skill: skill, level: level, height: 7),
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
