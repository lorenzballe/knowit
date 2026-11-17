import 'package:flutter/material.dart';

import '../../../analytics.dart';
import '../../../data/goals.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../state/app_state.dart';
import '../../../theme.dart';
import '../../../widgets/explore/card_tiles.dart';
import '../../../widgets/explore/first_shelves.dart';
import '../../explore_block.dart';
import 'layout.dart';

/// What the reader wants to get better at (lib/data/goals.dart), on Explore
/// for every subject. Before they say: the section's question, and the goals
/// to pick from, one tap each. Once said: a shelf of the goal's cards for
/// the day, new every day, and a way to change it.
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
      return SectionFrame(
        title: section.title(host.language),
        line: section.subtitle(host.language),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final Goal g in Goal.values)
                _Chip(
                  key: ValueKey('goal-${g.key}'),
                  label: '${goalEmoji(g)}  ${goalName(l, g)}',
                  onTap: () {
                    Analytics.capture('goal picked', {'goal': g.key});
                    app.setGoal(g.key);
                  },
                ),
            ],
          ),
        ),
      );
    }
    final List<Pill> cards = goal.cardsFor(app.today, app.seenIds);
    if (cards.isEmpty) return null;
    return ShelfFrame(
      title: l.goalShelf(goalName(l, goal)),
      line: l.goalShelfLine,
      trailing: GestureDetector(
        key: const ValueKey('goal-change'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Analytics.capture('goal changed', {'from': goal.key});
          app.setGoal(null);
        },
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

/// A goal as the reader reads it.
String goalName(AppLocalizations l, Goal g) => switch (g) {
  Goal.decide => l.goalDecide,
  Goal.people => l.goalPeople,
  Goal.business => l.goalBusiness,
  Goal.money => l.goalMoney,
  Goal.nonsense => l.goalNonsense,
  Goal.health => l.goalHealth,
  Goal.culture => l.goalCulture,
  Goal.world => l.goalWorld,
};

/// The mark beside a goal's name.
String goalEmoji(Goal g) => switch (g) {
  Goal.decide => '🧭',
  Goal.people => '🗣️',
  Goal.business => '🚀',
  Goal.money => '💶',
  Goal.nonsense => '🔍',
  Goal.health => '🌱',
  Goal.culture => '🎭',
  Goal.world => '🌍',
};

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: p.lineStrong),
          ),
          child: Text(
            label,
            style: AppText.body(
              size: 14,
              weight: FontWeight.w700,
              color: p.ink,
            ),
          ),
        ),
      ),
    );
  }
}
