import 'package:flutter/material.dart';

import '../../../analytics.dart';
import '../../../data/goals.dart';
import '../../../data/topics.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../screens/goal_screen.dart';
import '../../../state/app_state.dart';
import '../../../theme.dart';
import '../../../widgets/explore/card_tiles.dart';
import '../../../widgets/explore/first_shelves.dart';
import '../../explore_block.dart';
import 'layout.dart';

/// What the reader wants to get better at (lib/data/goals.dart), on Explore
/// for every subject: a shelf of the goal's cards for the day, new every
/// day, with the goal's mark and a way to change it.
///
/// The first run asks the question (screens/goal_screen.dart). A reader who
/// came before it did is asked here instead, once, by a card that opens the
/// same screen; put away, it does not come back, and Profile still has it.
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
    final Goal? goal = Goal.of(app.goal);
    if (goal == null) {
      if (app.goalAsked) return null;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _Ask(app: app),
      );
    }
    final List<Pill> cards = goal.cardsFor(app.today, app.seenIds);
    if (cards.isEmpty) return null;
    return ShelfFrame(
      title: l.goalShelf(goalName(l, goal)),
      line: goalLine(l, goal),
      trailing: GestureDetector(
        key: const ValueKey('goal-change'),
        behavior: HitTestBehavior.opaque,
        onTap: () => openGoalScreen(context, app, from: 'explore'),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            l.goalChange,
            style: AppText.body(
              size: 13.5,
              weight: FontWeight.w700,
              color: context.p.inkMuted,
            ),
          ),
        ),
      ),
      child: TileRow(
        size: TileSize.m,
        pills: cards,
        isRead: host.isRead,
        onShown: (pill) => host.seen(section, pill),
        onOpen: (shelf, pill) {
          Analytics.capture('goal opened', {
            'goal': goal.key,
            'rank': shelf.indexOf(pill) + 1,
          });
          host.open(section, shelf, pill);
        },
      ),
    );
  }
}

/// Opens the goals, to pick one or change it, as a page of its own.
Future<void> openGoalScreen(
  BuildContext context,
  AppState app, {
  required String from,
}) => Navigator.of(context).push(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (routeContext) => GoalScreen(
      editing: true,
      initial: app.goal,
      onSkip: () => Navigator.of(routeContext).pop(),
      onDone: (key) async {
        Analytics.capture('goal picked', {'goal': key, 'from': from});
        await app.setGoal(key);
        if (routeContext.mounted) Navigator.of(routeContext).pop();
      },
    ),
  ),
);

/// The question, once, for a reader the first run never asked: what a goal
/// is, a row of the goals' marks, the way in, and the way to put it away.
class _Ask extends StatelessWidget {
  const _Ask({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    return Container(
      key: const ValueKey('goal-ask'),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final Goal g in Goal.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: goalHue(g),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      goalIcon(g),
                      size: 14,
                      color: inkOn(goalHue(g)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            l.goalAsk,
            style: AppText.display(
              size: 21,
              weight: FontWeight.w600,
              height: 1.15,
              spacing: -0.4,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.goalAskLine,
            style: AppText.body(size: 13.5, height: 1.4, color: p.inkMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                key: const ValueKey('goal-ask-open'),
                behavior: HitTestBehavior.opaque,
                onTap: () => openGoalScreen(context, app, from: 'explore'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: p.inverse,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    l.goalPick,
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w800,
                      color: p.onInverse,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                key: const ValueKey('goal-ask-later'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Analytics.capture('goal put away', {'from': 'explore'});
                  app.markGoalAsked();
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    l.goalNotNow,
                    style: AppText.body(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: p.inkMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
