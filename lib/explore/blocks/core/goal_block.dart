import 'package:flutter/material.dart';

import '../../../analytics.dart';
import '../../../data/goals.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../state/app_state.dart';
import '../../../widgets/area_marks.dart';
import '../../../widgets/explore/card_tiles.dart';
import '../../../widgets/explore/first_shelves.dart';
import '../../explore_block.dart';
import 'layout.dart';

/// Where a card pays off in a life (lib/data/goals.dart), on Explore for
/// every subject: a shelf of one area a day, each in turn, the same for
/// everybody, under the same words its cards carry on their backs: "Useful
/// for: Money and shopping". Nothing is asked of the reader for it.
class GoalBlock extends ExploreBlock with SectionLayout {
  const GoalBlock();

  @override
  String get name => 'goal';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    if (host.subject != null) return null;
    final AppState app = host.app;
    final l = context.l10n;
    final Goal area = Goal.ofDay(app.today);
    final List<Pill> cards = area.cardsFor(app.today, app.seenIds);
    if (cards.isEmpty) return null;
    return ShelfFrame(
      title: l.goalShelf(goalName(l, area)),
      line: goalLine(l, area),
      child: TileRow(
        size: TileSize.m,
        pills: cards,
        isRead: host.isRead,
        onShown: (pill) => host.seen(section, pill),
        onOpen: (shelf, pill) {
          Analytics.capture('area opened', {
            'area': area.key,
            'rank': shelf.indexOf(pill) + 1,
          });
          host.open(section, shelf, pill);
        },
      ),
    );
  }
}
