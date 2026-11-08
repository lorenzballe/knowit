/// The reader's subjects, each with a level from 1 to 10: a ring in the
/// subject's colour round the level, four to a row, the subject's name
/// under it. A tap narrows Explore to the subject, as its chip does.
///
/// It shows the subjects the reader has read anything of, the furthest on
/// first, at most eight unless the section says (`limit`); a reader who has
/// read nothing yet has no subjects to show, and no section.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/pill_bank.dart';
import '../../../data/topics.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../screens/mix_screen.dart' show kMixSubjects;
import '../../../state/app_state.dart';
import '../../../theme.dart';
import '../../explore_block.dart';
import 'layout.dart';

/// How far a reader has gone into one subject.
@immutable
class SubjectLevel {
  const SubjectLevel({
    required this.key,
    required this.read,
    required this.right,
  });

  /// The subject's key (`space`, `history`).
  final String key;

  /// Its cards the reader has read, and the ones they answered right.
  final int read;
  final int right;

  /// The points the level is reckoned from: a card read is one, a card
  /// answered right two more. Answering is weighed over reading because it
  /// is the reader showing they know it, not only that they met it; a wrong
  /// answer still counts as the card read, so trying never costs a point.
  int get points => read + 2 * right;

  /// The level, 1 to 10.
  ///
  /// Level n is reached at 3 × (n − 1)² points: 3 for level 2, 12 for 3,
  /// 27 for 4, 48 for 5, 75 for 6, 108 for 7, 147 for 8, 192 for 9 and 243
  /// for 10. The steps widen as the levels rise, so the first ones come in
  /// a day or two of reading a subject and the tenth takes a few hundred
  /// cards' worth of a subject of three hundred or so — about all of it
  /// read, with a fair share answered right. Points only ever grow (a read
  /// card stays read, an answer right stays right), so a level never goes
  /// down.
  int get level => levelFor(points);

  /// How far from this level to the next, 0 to 1; 1 at level 10.
  double get toNext {
    final int n = level;
    if (n >= 10) return 1;
    final int from = pointsFor(n);
    return (points - from) / (pointsFor(n + 1) - from);
  }

  /// The points level [n] is reached at.
  static int pointsFor(int n) => 3 * (n - 1) * (n - 1);

  /// The level [points] come to.
  static int levelFor(int points) {
    if (points <= 0) return 1;
    return math.min(10, 1 + math.sqrt(points / 3).floor());
  }
}

/// Every subject of the row at the top the reader has read anything of,
/// furthest on first: the cards read of it ([AppState.seenIds]) and the
/// ones answered right ([AppState.answers]), counted over every card still
/// dealt to somebody, as the journey counts them.
List<SubjectLevel> subjectLevels(AppState app) {
  final Map<String, String> keyOf = {
    for (final MapEntry<String, TopicStyle> e in kTopics.entries)
      e.value.name: e.key,
  };
  final Map<String, int> read = {};
  final Map<String, int> right = {};
  for (final Pill p in PillBank.live) {
    final String? key = keyOf[p.topic];
    if (key == null) continue;
    if (app.seenIds.contains(p.id)) read[key] = (read[key] ?? 0) + 1;
    final String? said = app.answers[p.id]?.response;
    if (said != null && p.isGraded && p.challenge.accepts(said)) {
      right[key] = (right[key] ?? 0) + 1;
    }
  }
  final List<SubjectLevel> out = [
    for (final s in kMixSubjects)
      if ((read[s.key] ?? 0) > 0 || (right[s.key] ?? 0) > 0)
        SubjectLevel(
          key: s.key,
          read: read[s.key] ?? 0,
          right: right[s.key] ?? 0,
        ),
  ];
  // Furthest on first; between two at the same points, the wheel's order.
  final Map<String, int> wheel = {
    for (int i = 0; i < kMixSubjects.length; i++) kMixSubjects[i].key: i,
  };
  out.sort((a, b) {
    final int by = b.points.compareTo(a.points);
    return by != 0 ? by : wheel[a.key]!.compareTo(wheel[b.key]!);
  });
  return out;
}

/// The block: see the library's own words.
class SubjectLevelsBlock extends ExploreBlock with SectionLayout {
  const SubjectLevelsBlock();

  @override
  String get name => 'subject-levels';

  /// Subjects shown when the section gives no `limit`: two rows.
  static const int defaultLimit = 8;

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<SubjectLevel> levels = subjectLevels(host.app)
        .take(section.limit ?? defaultLimit)
        .toList();
    if (levels.isEmpty) return null;
    final l = context.l10n;
    Widget cell(SubjectLevel s) {
      final TopicStyle topic = kTopics[s.key]!;
      final bool on = host.subject == topic.name;
      final String name = l.subjectName(s.key);
      return Semantics(
        button: true,
        selected: on,
        label: l.exploreSubjectLevel(name, s.level),
        excludeSemantics: true,
        child: GestureDetector(
          key: ValueKey('subject-level-${s.key}-${s.level}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => host.openSubject(topic.name),
          child: Column(
            children: [
              LevelRing(
                level: s.level,
                share: (s.level - 1 + s.toNext) / 9,
                colour: topic.color,
                on: on,
              ),
              const SizedBox(height: 7),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 11.5,
                  weight: on ? FontWeight.w700 : FontWeight.w600,
                  height: 1.2,
                  color: on
                      ? context.p.ink
                      : context.p.ink.withValues(alpha: 0.66),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: [
            for (int i = 0; i < levels.length; i += 4) ...[
              if (i > 0) const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int j = i; j < i + 4; j++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: j < levels.length
                            ? cell(levels[j])
                            : const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A level in its ring: the subject's colour round a dark track, as far as
/// [share] goes, the level in the middle.
class LevelRing extends StatelessWidget {
  const LevelRing({
    super.key,
    required this.level,
    required this.share,
    required this.colour,
    this.on = false,
    this.size = 62,
  });

  final int level;

  /// How much of the ring is lit, 0 to 1.
  final double share;
  final Color colour;

  /// Whether Explore is narrowed to this subject: the ring sits on its tint.
  final bool on;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          share: share.clamp(0.0, 1.0),
          colour: colour,
          track: context.p.ink.withValues(alpha: 0.09),
          fill: on ? colour.withValues(alpha: 0.18) : null,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '$level',
                style: AppText.display(
                  size: 22,
                  weight: FontWeight.w600,
                  height: 1,
                  spacing: -0.5,
                  color: context.p.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.share,
    required this.colour,
    required this.track,
    this.fill,
  });

  final double share;
  final Color colour;
  final Color track;
  final Color? fill;

  static const double stroke = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = size.center(Offset.zero);
    final double radius = (math.min(size.width, size.height) - stroke) / 2;
    if (fill != null) {
      canvas.drawCircle(centre, radius, Paint()..color = fill!);
    }
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (share <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      2 * math.pi * share,
      false,
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.share != share ||
      old.colour != colour ||
      old.track != track ||
      old.fill != fill;
}
