import 'package:flutter/material.dart';

import '../../../data/goals.dart';
import '../../../data/learn_reading.dart';
import '../../../data/skills.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../state/app_state.dart';
import '../../../state/debug_looks.dart';
import '../../../theme.dart';
import '../../../widgets/explore/card_tiles.dart';
import '../../../widgets/explore/first_shelves.dart';
import '../../explore_block.dart';
import 'layout.dart';

/// The week's skill on Explore, in What to learn's look E as the developer
/// tools try it (lib/widgets/learn_looks.dart): cards that train it, not
/// read yet, the closest first, under its name and the mark its cards
/// carry. Among the first shelves, over the reader's goal's
/// (withAimShelf), for every subject; in every other look, and on a
/// subject's page, nothing.
class FocusBlock extends ExploreBlock with SectionLayout {
  const FocusBlock();

  @override
  String get name => 'focus';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    if (host.subject != null) return null;
    if (DebugLooks.learnPicked != LearnLook.weekly) return null;
    final AppState app = host.app;
    final l = context.l10n;
    final Skill skill = weekFocusOf(app).skill;
    // Not the cards the goal's shelf under it shows: the week's skill and
    // the goal often share cards, and one card twice in two rows reads as
    // a slip.
    final Set<String> aimShows = {
      if (Goal.of(app.goal) case final Goal aim)
        for (final Pill p in aim.cardsFor(app.today, app.seenIds)) p.id,
    };
    final List<Pill> cards = [
      for (final Pill p in practiceCards(app, skill, count: 20))
        if (!aimShows.contains(p.id)) p,
    ].take(10).toList();
    if (cards.isEmpty) return null;
    return ShelfFrame(
      title: l.focusShelf(l.skillName(skill.name)),
      line: l.focusShelfLine,
      // The mark its cards carry, in the skill's colour: what the shelf is
      // of, at a glance.
      trailing: Padding(
        key: const ValueKey('focus-shelf-mark'),
        padding: const EdgeInsets.only(right: 10),
        child: ExcludeSemantics(
          child: CustomPaint(
            size: const Size.square(18),
            painter: SkillGlyph(skill, skill.mark(context.p.isDark)),
          ),
        ),
      ),
      child: TileRow(
        size: TileSize.m,
        pills: cards,
        isRead: host.isRead,
        onShown: (pill) => host.seen(section, pill),
        onOpen: (shelf, pill) => host.open(section, shelf, pill),
      ),
    );
  }
}
