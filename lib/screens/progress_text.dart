import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';
import '../state/progress.dart';

/// The ladder, in words: the engine names rungs and steps by id and kind,
/// and these put the phone's language to them.
String rungName(BuildContext context, Rung rung) =>
    context.l10n.rungName(rung.id);

String rungClaim(BuildContext context, Rung rung) =>
    context.l10n.rungClaim(rung.id);

/// The first reading under the floor, in words: "So far: you said 80%
/// twice, and you were right twice." Every one right, none, or some.
String earlyReadingText(BuildContext context, EarlyReading r) {
  final l = context.l10n;
  if (r.right == r.count) return l.earlyReadingAll(r.level, r.count);
  if (r.right == 0) return l.earlyReadingNone(r.level, r.count);
  return l.earlyReadingSome(r.level, r.count, r.right);
}

String? stepText(BuildContext context, Standing standing) {
  final Step? step = standing.step;
  if (step == null) return null;
  final l = context.l10n;
  return switch (step.kind) {
    StepKind.read => l.stepRead(step.n),
    StepKind.answer => l.stepAnswer(step.n),
    StepKind.judge => l.stepJudge(step.n),
    StepKind.hold => l.stepHold(step.n),
    StepKind.gap => l.stepGap(step.n, step.target),
    StepKind.beforeJudged => l.stepBeforeJudged(step.n),
  };
}
