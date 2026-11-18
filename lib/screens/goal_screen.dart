import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/goals.dart';
import '../data/topics.dart';
import '../l10n/l10n.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// The second step of the first run, after the intro: what the reader wants
/// to get better at, as a person (lib/data/goals.dart). A tap picks a goal,
/// Next takes it; Skip goes on without one.
///
/// It is asked before the mix because it is the why before the what: the
/// subjects say what a reader likes to read, the goal what they want the
/// reading for. From here on it is a shelf of its own on Explore, a lean in
/// the deals, the coach's aim, and one more card when the day's five are
/// done. Profile opens the same screen to change it ([editing]).
class GoalScreen extends StatefulWidget {
  const GoalScreen({
    super.key,
    required this.onDone,
    required this.onSkip,
    this.initial,
    this.editing = false,
  });

  /// The goal picked, by key.
  final ValueChanged<String> onDone;

  /// The corner: on the first run, on without a goal; from Profile, back.
  final VoidCallback onSkip;

  /// The goal already held, picked when the screen opens.
  final String? initial;

  /// Opened from Profile rather than on the first run: the corner closes,
  /// and the button saves.
  final bool editing;

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  late Goal? _picked = Goal.of(widget.initial);

  @override
  void didUpdateWidget(GoalScreen old) {
    super.didUpdateWidget(old);
    if (old.initial != widget.initial) _picked = Goal.of(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          safe.top > 14 ? safe.top : 14,
          18,
          22 + (safe.bottom > 34 ? safe.bottom - 34 : 0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    l.goalAsk,
                    style: AppText.display(
                      size: 30,
                      weight: FontWeight.w600,
                      height: 1.04,
                      spacing: -1,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (widget.editing)
                  IconButton(
                    key: const ValueKey('goal-close'),
                    onPressed: widget.onSkip,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                  )
                else
                  SkipCorner(
                    onTap: widget.onSkip,
                    color: Colors.white,
                    inset: 18,
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              l.goalAskLine,
              style: AppText.body(
                size: 13.5,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: Goal.values.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final Goal g = Goal.values[i];
                  return GoalTile(
                    key: ValueKey('goal-tile-${g.key}'),
                    goal: g,
                    picked: _picked == g,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _picked = g);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            _GoButton(
              label: widget.editing ? l.goalSave : l.next,
              enabled: _picked != null,
              onTap: () => widget.onDone(_picked!.key),
            ),
          ],
        ),
      ),
    );
  }
}

/// One goal to pick: its mark on the colour of its first subject, its name,
/// and a line on what it trains.
class GoalTile extends StatelessWidget {
  const GoalTile({
    super.key,
    required this.goal,
    required this.picked,
    required this.onTap,
  });

  final Goal goal;
  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color hue = goalHue(goal);
    return Semantics(
      button: true,
      selected: picked,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            color: picked
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: picked
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.1),
              width: picked ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: hue, shape: BoxShape.circle),
                child: Icon(goalIcon(goal), size: 22, color: inkOn(hue)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goalName(l, goal),
                      style: AppText.body(
                        size: 16,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      goalLine(l, goal),
                      style: AppText.body(
                        size: 13,
                        height: 1.3,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: picked ? 1 : 0,
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The white button at the foot, dimmed until a goal is picked.
class _GoButton extends StatelessWidget {
  const _GoButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        key: const ValueKey('goal-next'),
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: enabled ? 1 : 0.35,
          child: Container(
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              label,
              style: AppText.body(
                size: 16,
                weight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ),
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

/// What a goal trains, in a line.
String goalLine(AppLocalizations l, Goal g) => switch (g) {
  Goal.decide => l.goalDecideLine,
  Goal.people => l.goalPeopleLine,
  Goal.business => l.goalBusinessLine,
  Goal.money => l.goalMoneyLine,
  Goal.nonsense => l.goalNonsenseLine,
  Goal.health => l.goalHealthLine,
  Goal.culture => l.goalCultureLine,
  Goal.world => l.goalWorldLine,
};

/// A goal's mark.
IconData goalIcon(Goal g) => switch (g) {
  Goal.decide => Icons.alt_route_rounded,
  Goal.people => Icons.forum_rounded,
  Goal.business => Icons.rocket_launch_rounded,
  Goal.money => Icons.savings_rounded,
  Goal.nonsense => Icons.fact_check_rounded,
  Goal.health => Icons.spa_rounded,
  Goal.culture => Icons.theater_comedy_rounded,
  Goal.world => Icons.public_rounded,
};

/// A goal's colour: the colour of the subject it leans on most.
Color goalHue(Goal g) {
  final String key = switch (g) {
    Goal.decide => 'psychology',
    Goal.people => 'life',
    Goal.business => 'technology',
    Goal.money => 'economics',
    Goal.nonsense => 'science',
    Goal.health => 'medicine',
    Goal.culture => 'art',
    Goal.world => 'space',
  };
  return kTopics[key]?.color ?? Colors.white;
}
