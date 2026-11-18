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
/// for every subject: a shelf of each goal's cards for the day, new every
/// day, and a way to change them.
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
    final List<Goal> aims = [
      for (final String k in app.goals)
        if (Goal.of(k) case final Goal g) g,
    ];
    if (aims.isEmpty) {
      if (app.goalAsked) return null;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _Ask(app: app),
      );
    }
    // A shelf for each goal, in the order they were picked; a card on one
    // shelf is not on the next, where two goals share a subject.
    final Set<String> taken = {...app.seenIds};
    final List<Widget> shelves = [];
    for (final Goal goal in aims) {
      final List<Pill> cards = goal.cardsFor(app.today, taken);
      if (cards.isEmpty) continue;
      taken.addAll([for (final Pill p in cards) p.id]);
      shelves.add(
        ShelfFrame(
          title: l.goalShelf(goalName(l, goal)),
          line: goalLine(l, goal),
          // The way to change them, once, on the first shelf.
          trailing: shelves.isEmpty
              ? GestureDetector(
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
                )
              : null,
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
        ),
      );
    }
    if (shelves.isEmpty) return null;
    if (shelves.length == 1) return shelves.single;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < shelves.length; i++) ...[
          if (i > 0) const SizedBox(height: kSectionGap),
          shelves[i],
        ],
      ],
    );
  }
}

/// Opens the goals, to pick them or change them, as a page of its own.
Future<void> openGoalScreen(
  BuildContext context,
  AppState app, {
  required String from,
}) => Navigator.of(context).push(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (routeContext) => GoalScreen(
      editing: true,
      initial: app.goals,
      onSkip: () => Navigator.of(routeContext).pop(),
      onDone: (keys) async {
        Analytics.capture('goal picked', {
          'goal': keys.join(','),
          'goals': keys.length,
          'from': from,
        });
        await app.setGoals(keys);
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
          // The goals' marks, overlapping as a row of faces does, each
          // ringed in the card's own ground so the next one sits clear.
          SizedBox(
            height: 28,
            width: 28 + (Goal.values.length - 1) * 19,
            child: Stack(
              children: [
                for (int i = 0; i < Goal.values.length; i++)
                  Positioned(
                    left: i * 19.0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: goalHue(Goal.values[i]),
                        shape: BoxShape.circle,
                        border: Border.all(color: p.surfaceRaised, width: 2),
                      ),
                      child: Icon(
                        goalIcon(Goal.values[i]),
                        size: 13,
                        color: inkOn(goalHue(Goal.values[i])),
                      ),
                    ),
                  ),
              ],
            ),
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
