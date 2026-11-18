import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/goals.dart';
import '../data/topics.dart';
import '../l10n/l10n.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// The second step of the first run, after the intro: what the reader wants
/// to get better at, as a person (lib/data/goals.dart). Each tap ticks a
/// goal or takes its tick away, up to [kMostGoals]; Next takes them; Skip
/// goes on without any.
///
/// It is asked before the mix because it is the why before the what: the
/// subjects say what a reader likes to read, the goals what they want the
/// reading for. From here on each is a shelf of its own on Explore, a lean
/// in the deals, and what the coach writes towards. Profile opens the same
/// screen to change them ([editing]).
class GoalScreen extends StatefulWidget {
  const GoalScreen({
    super.key,
    required this.onDone,
    required this.onSkip,
    this.initial = const [],
    this.editing = false,
  });

  /// The goals picked, by key, in the order they were ticked.
  final ValueChanged<List<String>> onDone;

  /// The corner: on the first run, on without a goal; from Profile, back.
  final VoidCallback onSkip;

  /// The goals already held, ticked when the screen opens.
  final List<String> initial;

  /// Opened from Profile rather than on the first run: the corner closes,
  /// and the button saves.
  final bool editing;

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  late List<Goal> _picked = _held(widget.initial);

  /// Whether the line under the question is lit: a tap on a goal past the
  /// third says why it took no tick.
  bool _told = false;

  static List<Goal> _held(List<String> keys) => [
    for (final String k in keys)
      if (Goal.of(k) case final Goal g) g,
  ].take(kMostGoals).toList();

  @override
  void didUpdateWidget(GoalScreen old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.initial, widget.initial)) {
      _picked = _held(widget.initial);
    }
  }

  void _tap(Goal g) {
    if (_picked.contains(g)) {
      HapticFeedback.selectionClick();
      setState(() => _picked.remove(g));
      return;
    }
    if (_picked.length >= kMostGoals) {
      // Full: the tick is not taken, and the line that says up to three
      // lights up to say why.
      HapticFeedback.heavyImpact();
      setState(() => _told = true);
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _told = false);
      });
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _picked.add(g));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final bool full = _picked.length >= kMostGoals;
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
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: AppText.body(
                size: 13.5,
                height: 1.4,
                weight: _told ? FontWeight.w600 : FontWeight.w400,
                color: Colors.white.withValues(alpha: _told ? 1 : 0.55),
              ),
              child: Text(l.goalAskLine),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: Goal.values.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final Goal g = Goal.values[i];
                  final bool picked = _picked.contains(g);
                  return GoalTile(
                    key: ValueKey('goal-tile-${g.key}'),
                    goal: g,
                    picked: picked,
                    dimmed: full && !picked,
                    onTap: () => _tap(g),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            _GoButton(
              label: widget.editing ? l.goalSave : l.next,
              enabled: _picked.isNotEmpty,
              onTap: () => widget.onDone([for (final Goal g in _picked) g.key]),
            ),
          ],
        ),
      ),
    );
  }
}

/// One goal to tick: its mark on the colour of its first subject, its name,
/// a line on what it trains, and the tick, an empty ring until it is
/// ticked. With three ticked, the others fade: they take no tick until one
/// is taken away.
class GoalTile extends StatelessWidget {
  const GoalTile({
    super.key,
    required this.goal,
    required this.picked,
    required this.onTap,
    this.dimmed = false,
  });

  final Goal goal;
  final bool picked;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color hue = goalHue(goal);
    return Semantics(
      button: true,
      selected: picked,
      enabled: !dimmed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: dimmed ? 0.42 : 1,
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
                const SizedBox(width: 10),
                _Tick(on: picked),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The tick at a goal's end: an empty ring, or a white disc with a check.
class _Tick extends StatelessWidget {
  const _Tick({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? Colors.white : Colors.transparent,
        border: Border.all(
          color: on ? Colors.white : Colors.white.withValues(alpha: 0.35),
          width: 1.6,
        ),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: on ? 1 : 0,
        child: const Icon(Icons.check_rounded, size: 16, color: Colors.black),
      ),
    );
  }
}

/// The white button at the foot, dimmed until a goal is ticked.
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
  Goal.stress => l.goalStress,
  Goal.learn => l.goalLearn,
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
  Goal.stress => l.goalStressLine,
  Goal.learn => l.goalLearnLine,
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
  Goal.stress => Icons.self_improvement_rounded,
  Goal.learn => Icons.school_rounded,
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
    Goal.stress => 'philosophy',
    Goal.learn => 'language',
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
