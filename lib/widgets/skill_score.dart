/// How a score of lib/data/skill_scores.dart is shown: its number in the
/// reader's own digits, how far it moved, and its line over the last month.
/// One vocabulary for Your training, the profile, What to learn, the day's
/// sheet and the sheet a card's mark opens.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/pills_repository.dart' show dateKey;
import '../data/skill_scores.dart';
import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// The reader's scores, worked out once for each new judgement and each
/// day, however many places show them.
ScoreBook scoreBookOf(AppState app) {
  final String key = '${app.judgements.length}|${dateKey(app.today)}';
  final _Kept? kept = _kept[app];
  if (kept != null && kept.key == key) return kept.book;
  final ScoreBook book = scoresOf(app.judgements, today: app.today);
  _kept[app] = _Kept(key, book);
  return book;
}

class _Kept {
  const _Kept(this.key, this.book);
  final String key;
  final ScoreBook book;
}

final Expando<_Kept> _kept = Expando('scores');

/// [n] in the reader's digits, grouped: 1,284 or 1.284.
String scoreNumber(BuildContext context, int n) =>
    NumberFormat.decimalPattern(Localizations.localeOf(context).toLanguageTag())
        .format(n);

/// [n] with its sign: +24, −8, or 0.
String signedNumber(BuildContext context, int n) {
  final String digits = scoreNumber(context, n.abs());
  if (n > 0) return '+$digits';
  if (n < 0) return '−$digits';
  return digits;
}

/// The colour of a score that rose: a green that reads on both pages.
Color scoreUp(BuildContext context) =>
    context.p.isDark ? const Color(0xFF3DDC84) : const Color(0xFF138A4C);

/// The colour of how far a score moved: green when it rose, the page's
/// quieter ink when it held or fell.
Color moveColour(BuildContext context, int n) =>
    n > 0 ? scoreUp(context) : context.p.ink.withValues(alpha: 0.55);

/// How far a score moved in the last seven days, in its colour.
class ScoreWeek extends StatelessWidget {
  const ScoreWeek({super.key, required this.score, this.size = 12.5});

  final SkillScore score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (score.answers == 0) {
      return Text(
        l.scoreStart,
        style: AppText.body(
          size: size,
          height: 1.3,
          color: context.p.ink.withValues(alpha: 0.55),
        ),
      );
    }
    return Text(
      l.scoreWeek(signedNumber(context, score.week)),
      style: AppText.body(
        size: size,
        weight: FontWeight.w700,
        height: 1.3,
        color: moveColour(context, score.week),
      ),
    );
  }
}

/// A score's line over the last month, ending on a dot where it stands: a
/// month with no answer, or one that held still, is a level line.
class ScoreSpark extends StatelessWidget {
  const ScoreSpark({
    super.key,
    required this.values,
    required this.colour,
    this.height = 26,
  });

  final List<int> values;
  final Color colour;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(painter: _SparkPainter(values, colour)),
  );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.colour);

  final List<int> values;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0) return;
    const double dot = 3.4;
    final int lo = values.reduce(math.min), hi = values.reduce(math.max);
    final double top = dot + 1, room = size.height - 2 * top;
    // A line that never moved sits at mid height.
    double yOf(int v) =>
        hi == lo ? size.height / 2 : top + room * (hi - v) / (hi - lo);
    final double w = size.width - dot - 1;
    Offset at(int i) => Offset(w * i / (values.length - 1), yOf(values[i]));
    final Path line = Path()..moveTo(at(0).dx, at(0).dy);
    for (int i = 1; i < values.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }
    final Path under = Path.from(line)
      ..lineTo(at(values.length - 1).dx, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      under,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colour.withValues(alpha: 0.24), colour.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(at(values.length - 1), dot, Paint()..color = colour);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.colour != colour || !_same(old.values, values);

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
