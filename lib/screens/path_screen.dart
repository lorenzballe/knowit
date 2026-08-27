import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/pills_data.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/motion.dart';
import 'lesson_screen.dart';
import 'today_screen.dart';

/// One lesson on the path: a principle, and the cards that teach it.
class PathUnit {
  final Principle principle;
  final List<Pill> cards;

  /// How many of the graded cards in this unit have been answered.
  final int met;
  final int right;

  const PathUnit({
    required this.principle,
    required this.cards,
    required this.met,
    required this.right,
  });

  int get total => cards.where((c) => c.isGraded && c.asksSomething).length;
  bool get isDone => total > 0 && met >= total;
}

/// Builds the path from the pool and what the reader has already answered.
///
/// Nothing new is stored: a unit is finished when its cards have been
/// answered, which the answers already say. A progress bar that is really a
/// second copy of the truth is a progress bar that will eventually disagree
/// with it.
List<PathUnit> buildPath(AppState app) {
  final out = <PathUnit>[];
  for (final principle in Principle.values) {
    if (!principle.isReal) continue;
    final asks = kPillPool
        .where((p) => p.principle == principle && p.asksSomething)
        .toList();
    if (asks.isEmpty) continue;

    // A fact rides along with every lesson: it is the reason to open the app
    // rather than the training, and it opens up the subject either way.
    final facts = kPillPool.where((p) => !p.asksSomething).toList();
    final fact = facts.isEmpty ? null : facts[principle.index % facts.length];

    final mastery = app.masteryOf(principle);
    out.add(
      PathUnit(
        principle: principle,
        cards: [?fact, ...asks],
        met: mastery.met,
        right: mastery.right,
      ),
    );
  }
  return out;
}

/// The home screen: a path you climb rather than a day you are handed.
///
/// The app used to open on "today's five" — a set that arrived, got done, and
/// left nothing behind but a streak. There was nowhere to be, and no sense of
/// having got anywhere. A path answers both: every unit is a named move you
/// can be bad at, and finishing one visibly opens the next.
class PathScreen extends StatelessWidget {
  final AppState app;
  const PathScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final units = buildPath(app);
    // The first unfinished unit is where you are; everything past it waits.
    final current = units.indexWhere((u) => !u.isDone);
    final atEnd = current == -1;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Text(
                  'Knowit',
                  style: AppText.display(
                    size: 21,
                    weight: FontWeight.w700,
                    spacing: -0.5,
                    color: context.p.ink,
                  ),
                ),
                const Spacer(),
                _Chip(
                  icon: Icons.local_fire_department_rounded,
                  label: '${app.liveStreak}',
                ),
                const SizedBox(width: 8),
                _Chip(
                  icon: Icons.workspace_premium_rounded,
                  label:
                      '${units.where((u) => u.isDone).length}/${units.length}',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
              itemCount: units.length + 1,
              itemBuilder: (context, index) {
                // The daily five sit at the top of the path rather than in a
                // tab of their own. The path is what gives the app somewhere
                // to be going; the day is what brings anybody back tomorrow,
                // and an app needs both.
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: _TodayCard(app: app),
                  );
                }
                final i = index - 1;
                final unit = units[i];
                final isCurrent = i == current;
                final locked = !unit.isDone && !isCurrent && !atEnd;
                return RiseIn.staggered(
                  math.min(i, 6),
                  step: const Duration(milliseconds: 46),
                  child: _UnitRow(
                    app: app,
                    unit: unit,
                    index: i,
                    isCurrent: isCurrent,
                    locked: locked,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: context.p.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.p.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.limeDark),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppText.body(
              size: 13,
              weight: FontWeight.w700,
              color: context.p.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  final AppState app;
  final PathUnit unit;
  final int index;
  final bool isCurrent;
  final bool locked;

  const _UnitRow({
    required this.app,
    required this.unit,
    required this.index,
    required this.isCurrent,
    required this.locked,
  });

  void _start(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          app: app,
          cards: unit.cards,
          title: unit.principle.label,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A gentle weave, so the eye follows a route rather than a column.
    // Only the node leans. Leaning the whole row squeezed the text column
    // and truncated the very line that says what the unit is.
    final lean = math.sin(index * 0.9) * 26;

    final face = locked ? context.p.line : AppColors.lime;
    final ink = locked ? context.p.inkFaint : AppColors.limeInk;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Transform.translate(
              offset: Offset(lean, 0),
              child: _Node(
                face: face,
                ink: ink,
                locked: locked,
                done: unit.isDone,
                current: isCurrent,
                onTap: locked ? null : () => _start(context),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unit.principle.label,
                  style: AppText.display(
                    size: 17,
                    weight: FontWeight.w700,
                    height: 1.15,
                    spacing: -0.3,
                    color: locked ? context.p.inkFaint : context.p.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  locked
                      ? 'Finish the one above'
                      : '${unit.met}/${unit.total} · ${unit.principle.oneLine}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    size: 12.5,
                    height: 1.35,
                    color: context.p.inkFaint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The circle you tap. Thick, so it reads as a button on a board rather than
/// a bullet in a list.
class _Node extends StatelessWidget {
  final Color face;
  final Color ink;
  final bool locked;
  final bool done;
  final bool current;
  final VoidCallback? onTap;

  const _Node({
    required this.face,
    required this.ink,
    required this.locked,
    required this.done,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: chunkyEdge(face, 0.14),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.only(bottom: 5),
      child: Container(
        decoration: BoxDecoration(color: face, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(
          locked
              ? Icons.lock_rounded
              : done
              ? Icons.check_rounded
              : Icons.play_arrow_rounded,
          size: 27,
          color: ink,
        ),
      ),
    );

    return Semantics(
      button: !locked,
      label: locked ? 'Locked' : 'Start this lesson',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: current ? PopIn(strength: 0.12, child: circle) : circle,
      ),
    );
  }
}

/// The way into today's deck, kept at the head of the path.
class _TodayCard extends StatelessWidget {
  final AppState app;
  const _TodayCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final total = app.todaysDeck.length;
    final done = app.todayCompleted ? total : app.todayIndex;
    final finished = app.todayCompleted;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: context.p.inverse,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TODAY',
                style: AppText.label(
                  size: 10.5,
                  spacing: 1.5,
                  color: AppColors.lime,
                ),
              ),
              const Spacer(),
              Text(
                '$done of $total',
                style: AppText.label(
                  size: 11,
                  color: context.p.onInverse.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            finished
                ? 'Done for today.'
                : done == 0
                ? 'Your five are ready.'
                : 'You are part way through.',
            style: AppText.display(
              size: 24,
              weight: FontWeight.w700,
              height: 1.1,
              spacing: -0.8,
              color: context.p.onInverse,
            ),
          ),
          const SizedBox(height: 14),
          ChunkyButton(
            label: finished ? 'READ THEM AGAIN' : 'START',
            height: 50,
            fill: AppColors.lime,
            ink: AppColors.limeInk,
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => TodayRoute(app: app))),
          ),
        ],
      ),
    );
  }
}

/// Today's deck, opened as its own screen off the path.
class TodayRoute extends StatelessWidget {
  final AppState app;
  const TodayRoute({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.p.surface,
      body: TodayScreen(app: app, onBack: () => Navigator.of(context).pop()),
    );
  }
}
