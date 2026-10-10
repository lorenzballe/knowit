import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/explore_mix.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import '../subject_icon.dart';
import 'parts.dart';

/// The shelves whose cards are cards — sideways rows and short lists — each
/// in the form the canvas drew for its kind (133b to 138c, 131e): you can
/// tell what a shelf holds before reading a word of it.

/// What a shelf does with a card the reader taps.
typedef OpenCard = void Function(List<Pill> shelf, Pill pill);

// ── True or false? (133e, answered on the shelf as 133b asks) ─────────────

/// Each card split corner to corner in two tones of its colour, a question
/// mark drawn large in the darker one, and TRUE and FALSE at its foot. A tap
/// on either is the answer, given before the card is opened, and the card
/// says at once whether it was right; the why is one more tap away.
class TrueFalseRow extends StatelessWidget {
  const TrueFalseRow({
    super.key,
    required this.pills,
    required this.isRead,
    required this.onOpen,
    required this.answerOf,
    required this.onCommit,
    this.onShown,
  });

  final List<Pill> pills;
  final bool Function(Pill) isRead;
  final OpenCard onOpen;

  /// What the reader answered on a card, if they have.
  final String? Function(Pill) answerOf;
  final void Function(Pill, String) onCommit;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    return SideRow(
      height: 236,
      count: pills.length,
      itemBuilder: (context, i) {
        final Pill p = pills[i];
        onShown?.call(p);
        return _TrueFalseCard(
          pill: p,
          read: isRead(p),
          answer: answerOf(p),
          onOpen: () => onOpen(pills, p),
          onCommit: (sayTrue) => onCommit(p, '${trueOrFalseIndex(p, sayTrue)}'),
        );
      },
    );
  }
}

class _TrueFalseCard extends StatelessWidget {
  const _TrueFalseCard({
    required this.pill,
    required this.read,
    required this.answer,
    required this.onOpen,
    required this.onCommit,
  });

  final Pill pill;
  final bool read;
  final String? answer;
  final VoidCallback onOpen;
  final ValueChanged<bool> onCommit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bool truth = trueOrFalseAnswer(pill);
    final int? said = answer == null ? null : int.tryParse(answer!);
    final bool done = said != null;
    final bool saidTrue = done && said == trueOrFalseIndex(pill, true);
    final bool right = done && saidTrue == truth;

    // Once answered: the side picked is filled, and struck through when it
    // was wrong; the right side, when it was not the one picked, is ringed.
    Widget side(bool isTrue) {
      final bool picked = done && saidTrue == isTrue;
      final bool isRight = isTrue == truth;
      final bool ringed = done && !picked && isRight;
      final String word = upper(context, isTrue ? l.sayTrue : l.sayFalse);
      return Semantics(
        button: !done,
        key: ValueKey('tf-${pill.id}-${isTrue ? 'true' : 'false'}'),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: done ? null : () => onCommit(isTrue),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: done && !picked && !ringed ? 0.4 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: picked ? pill.ink : pill.ink.withValues(alpha: 0),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: pill.ink.withValues(alpha: ringed ? 1 : 0),
                  width: 1.5,
                ),
              ),
              child: Text(
                word,
                style:
                    AppText.label(
                      size: 10,
                      weight: FontWeight.w700,
                      spacing: 1.4,
                      color: picked ? pill.color : pill.ink,
                    ).copyWith(
                      decoration: picked && !isRight
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: pill.color,
                      decorationThickness: 2,
                    ),
              ),
            ),
          ),
        ),
      );
    }

    return CardTap(
      pill: pill,
      onTap: onOpen,
      child: SizedBox(
        width: 200,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: CustomPaint(
            painter: _SplitPainter(pill.color, shade(pill.color, 0.84)),
            child: Stack(
              children: [
                Positioned(
                  right: 8,
                  bottom: -34,
                  child: Text(
                    '?',
                    textScaler: TextScaler.noScaling,
                    style: AppText.display(
                      size: 170,
                      weight: FontWeight.w600,
                      height: 1,
                      color: shade(pill.color, 0.74),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 6, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: CardHead(
                          pill: pill,
                          trailing: read ? ReadMark(pill: pill) : null,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, right: 10),
                          child: CardQuestion(
                            text: pill.question,
                            color: pill.ink,
                            min: 11,
                            max: 17,
                          ),
                        ),
                      ),
                      if (done)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, right: 10),
                          child: Text(
                            right
                                ? l.tfRight
                                : l.tfWrong(truth ? l.sayTrue : l.sayFalse),
                            key: ValueKey('tf-verdict-${pill.id}'),
                            maxLines: 2,
                            style: AppText.body(
                              size: 12,
                              weight: FontWeight.w700,
                              height: 1.25,
                              color: pill.ink,
                            ),
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Transform.translate(
                            offset: const Offset(-10, 0),
                            child: side(true),
                          ),
                          side(false),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The card's colour above the diagonal, its darker tone below — the line
/// running corner to corner whatever the card's shape, as the canvas has it.
class _SplitPainter extends CustomPainter {
  _SplitPainter(this.light, this.dark);

  final Color light;
  final Color dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = light);
    canvas.drawPath(
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = dark,
    );
  }

  @override
  bool shouldRepaint(_SplitPainter old) =>
      old.light != light || old.dark != dark;
}

// ── True stories (133e) ──────────────────────────────────────────────────

/// A story's beats across the top, the way a story is played on a phone,
/// and how long it takes at the foot.
class StoryRow extends StatelessWidget {
  const StoryRow({
    super.key,
    required this.pills,
    required this.isRead,
    required this.onOpen,
    this.onShown,
  });

  final List<Pill> pills;
  final bool Function(Pill) isRead;
  final OpenCard onOpen;
  final ValueChanged<Pill>? onShown;

  /// The story's beats: the sentences its answer tells it in, three to five.
  static int beats(Pill p) =>
      p.answer.split(RegExp(r'(?<=[.!?])\s+')).length.clamp(3, 5);

  @override
  Widget build(BuildContext context) {
    return SideRow(
      height: 254,
      count: pills.length,
      itemBuilder: (context, i) {
        final Pill p = pills[i];
        onShown?.call(p);
        final int n = beats(p);
        return CardTap(
          pill: p,
          onTap: () => onOpen(pills, p),
          child: Container(
            width: 210,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: p.color,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (int k = 0; k < n; k++) ...[
                      if (k > 0) const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: p.ink.withValues(alpha: k == 0 ? 1 : 0.14),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 13),
                CardHead(
                  pill: p,
                  trailing: isRead(p) ? ReadMark(pill: p) : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                    child: CardQuestion(
                      text: p.question,
                      color: p.ink,
                      min: 11,
                      max: 17.5,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 15, color: p.ink),
                    const SizedBox(width: 5),
                    Text(
                      context.l10n.minutesShort(minutesFor(p)),
                      style: AppText.label(
                        size: 9,
                        weight: FontWeight.w700,
                        spacing: 1.2,
                        color: p.ink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Seen, not read (133e) ────────────────────────────────────────────────

/// Cards that draw their point, each with a small drawing of the kind of
/// picture it holds at its foot: bars, a line, a field of dots.
class SeenRow extends StatelessWidget {
  const SeenRow({
    super.key,
    required this.pills,
    required this.isRead,
    required this.onOpen,
    this.onShown,
  });

  final List<Pill> pills;
  final bool Function(Pill) isRead;
  final OpenCard onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    return SideRow(
      height: 252,
      count: pills.length,
      itemBuilder: (context, i) {
        final Pill p = pills[i];
        onShown?.call(p);
        return CardTap(
          pill: p,
          onTap: () => onOpen(pills, p),
          child: Container(
            width: 200,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(
              color: p.color,
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardHead(
                  pill: p,
                  trailing: isRead(p) ? ReadMark(pill: p) : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: CardQuestion(
                      text: p.question,
                      color: p.ink,
                      min: 11,
                      max: 16.5,
                    ),
                  ),
                ),
                SizedBox(
                  height: 66,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _SeenGlyph(
                      kind: switch (p.diagram) {
                        LineDiagram() => _Glyph.line,
                        DotsDiagram() => _Glyph.dots,
                        AreaDiagram() || SplitDiagram() => _Glyph.area,
                        _ => _Glyph.bars,
                      },
                      tone: shade(p.color, 0.74),
                      ink: p.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _Glyph { bars, line, dots, area }

class _SeenGlyph extends CustomPainter {
  _SeenGlyph({required this.kind, required this.tone, required this.ink});

  final _Glyph kind;
  final Color tone;
  final Color ink;

  static const List<double> _rise = [10, 14, 20, 30, 44, 62];

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fill = Paint()..color = tone;
    switch (kind) {
      case _Glyph.bars:
        const double gap = 5;
        final double w = (size.width - gap * 5) / 6;
        for (int i = 0; i < 6; i++) {
          final double h = _rise[i];
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              Rect.fromLTWH(i * (w + gap), size.height - h, w, h),
              topLeft: const Radius.circular(5),
              topRight: const Radius.circular(5),
            ),
            i == 5 ? (Paint()..color = ink) : fill,
          );
        }
      case _Glyph.line:
        final path = Path();
        const List<double> ys = [0.78, 0.7, 0.74, 0.52, 0.46, 0.22, 0.12];
        for (int i = 0; i < ys.length; i++) {
          final Offset o = Offset(
            size.width * i / (ys.length - 1),
            size.height * ys[i] - 4,
          );
          i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
        }
        final area = Path.from(path)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(area, fill);
        canvas.drawPath(
          path,
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      case _Glyph.dots:
        const int cols = 10;
        const int rows = 4;
        final double step = size.width / cols;
        final double r = math.min(step * 0.32, 5);
        for (int y = 0; y < rows; y++) {
          for (int x = 0; x < cols; x++) {
            final bool lit = y == rows - 1 && x < 3;
            canvas.drawCircle(
              Offset(step * (x + 0.5), size.height - 8 - y * (r * 2 + 6)),
              r,
              lit ? (Paint()..color = ink) : fill,
            );
          }
        }
      case _Glyph.area:
        final double w = size.width;
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(0, 8, w * 0.62, size.height - 8),
            topLeft: const Radius.circular(6),
            topRight: const Radius.circular(6),
          ),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(w * 0.62 + 5, 30, w * 0.38 - 5, size.height - 30),
            topLeft: const Radius.circular(6),
            topRight: const Radius.circular(6),
          ),
          Paint()..color = ink,
        );
    }
  }

  @override
  bool shouldRepaint(_SeenGlyph old) =>
      old.kind != kind || old.tone != tone || old.ink != ink;
}

// ── Where it came from (133e) ────────────────────────────────────────────

/// When it began, large, and a dashed line from then to today.
class OriginRow extends StatelessWidget {
  const OriginRow({
    super.key,
    required this.pills,
    required this.isRead,
    required this.onOpen,
    this.onShown,
  });

  final List<Pill> pills;
  final bool Function(Pill) isRead;
  final OpenCard onOpen;
  final ValueChanged<Pill>? onShown;

  /// The card's year if its question names one, or the age it is set in.
  static String when(BuildContext context, Pill p) {
    final String? year = questionYear(p);
    if (year != null) return year;
    final l = context.l10n;
    return switch (p.era) {
      'ancient' => l.eraShortAncient,
      'medieval' => l.eraShortMedieval,
      'early_modern' => l.eraShortEarlyModern,
      'nineteenth' => l.eraShortNineteenth,
      'twentieth' => l.eraShortTwentieth,
      'recent' => l.eraShortRecent,
      _ => '—',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SideRow(
      height: 240,
      count: pills.length,
      itemBuilder: (context, i) {
        final Pill p = pills[i];
        onShown?.call(p);
        final TextStyle label = AppText.label(
          size: 9,
          weight: FontWeight.w700,
          spacing: 1.2,
          color: subOn(p),
        );
        return CardTap(
          pill: p,
          onTap: () => onOpen(pills, p),
          child: Container(
            width: 206,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.color,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardHead(
                  pill: p,
                  trailing: isRead(p) ? ReadMark(pill: p) : null,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(upper(context, l.firstLabel), style: label),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          when(context, p),
                          maxLines: 1,
                          style: AppText.display(
                            size: 38,
                            weight: FontWeight.w600,
                            height: 0.9,
                            spacing: -1.4,
                            color: p.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomPaint(
                          size: const Size.fromHeight(2),
                          painter: _Dashes(hairOn(p)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(upper(context, l.todayLabel), style: label),
                    ],
                  ),
                ),
                Expanded(
                  child: CardQuestion(
                    text: p.question,
                    color: p.ink,
                    min: 11,
                    max: 16.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Dashes extends CustomPainter {
  _Dashes(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (double x = 0; x < size.width; x += 7) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(math.min(x + 4, size.width), size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Dashes old) => old.color != color;
}

// ── For the sharpest (133e) ──────────────────────────────────────────────

/// The hardest cards, dark, ringed in the subject's colour, with HARD on
/// them: the one shelf where the colour is held back to an edge.
class SharpRow extends StatelessWidget {
  const SharpRow({
    super.key,
    required this.pills,
    required this.isRead,
    required this.onOpen,
    this.onShown,
  });

  final List<Pill> pills;
  final bool Function(Pill) isRead;
  final OpenCard onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    final bool dark = context.p.isDark;
    return SideRow(
      height: 230,
      count: pills.length,
      itemBuilder: (context, i) {
        final Pill p = pills[i];
        onShown?.call(p);
        // On paper a pale colour cannot carry text: take its darker tone.
        final Color accent = !dark && p.color.computeLuminance() > 0.45
            ? shade(p.color, 0.62)
            : p.color;
        final Color ground = dark
            ? const Color(0xFF0B0B0D)
            : context.p.surfaceRaised;
        return CardTap(
          pill: p,
          onTap: () => onOpen(pills, p),
          child: Container(
            width: 204,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ground,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: accent, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardHead(
                  pill: p,
                  ink: accent,
                  labelInk: accent,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isRead(p)) ...[
                        ReadMark(pill: p, color: accent),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          upper(context, context.l10n.hardBadge),
                          style: AppText.label(
                            size: 9,
                            weight: FontWeight.w700,
                            spacing: 1,
                            height: 1,
                            color: ground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: CardQuestion(
                      text: p.question,
                      color: context.p.ink,
                      min: 11,
                      max: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Came back (133d) ─────────────────────────────────────────────────────

/// A card due again, with how long it waited and how it went last time.
class CameBackCard {
  const CameBackCard(this.pill, {required this.days, required this.right});

  final Pill pill;
  final int days;
  final bool right;
}

class CameBackRow extends StatelessWidget {
  const CameBackRow({
    super.key,
    required this.cards,
    required this.onOpen,
    this.onShown,
  });

  final List<CameBackCard> cards;
  final OpenCard onOpen;
  final ValueChanged<Pill>? onShown;

  static String after(BuildContext context, int days) {
    final l = context.l10n;
    if (days == 7) return l.cameBackAfterWeek;
    if (days >= 14 && days % 7 == 0) return l.cameBackAfterWeeks(days ~/ 7);
    return l.cameBackAfterDays(days);
  }

  @override
  Widget build(BuildContext context) {
    final List<Pill> shelf = [for (final c in cards) c.pill];
    return SideRow(
      height: 228,
      count: cards.length,
      itemBuilder: (context, i) {
        final CameBackCard c = cards[i];
        final Pill p = c.pill;
        onShown?.call(p);
        return CardTap(
          pill: p,
          onTap: () => onOpen(shelf, p),
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.color,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 26,
                  padding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
                  decoration: BoxDecoration(
                    color: p.ink,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.replay_rounded, size: 14, color: p.color),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          upper(context, after(context, c.days)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.label(
                            size: 9,
                            weight: FontWeight.w700,
                            spacing: 1.1,
                            height: 1,
                            color: p.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: CardQuestion(
                      text: p.question,
                      color: p.ink,
                      min: 11,
                      max: 17,
                    ),
                  ),
                ),
                Row(
                  children: [
                    SubjectIcon(subject: p.topic, size: 14, ink: subOn(p)),
                    const SizedBox(width: 7),
                    // Gives way in a language that takes more words to say
                    // it, rather than running off the card.
                    Flexible(
                      child: Text(
                        c.right
                            ? context.l10n.rightLastTime
                            : context.l10n.wrongLastTime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          size: 11,
                          weight: FontWeight.w600,
                          height: 1,
                          color: subOn(p),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── One move, many places (133c) ─────────────────────────────────────────

/// The cards where one thinking move hides, each saying where: in a hiring
/// change, in a famous study. The move is named over them the way every
/// shelf is named; it was set large in a box of its own, and the name took
/// more room than the cards and still did not say what it meant.
class MoveRow extends StatelessWidget {
  const MoveRow({
    super.key,
    required this.pills,
    required this.isRead,
    required this.onOpen,
    this.onShown,
  });

  final List<Pill> pills;
  final bool Function(Pill) isRead;
  final OpenCard onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    return SideRow(
      height: 220,
      count: pills.length,
      itemBuilder: (context, i) {
        final Pill p = pills[i];
        onShown?.call(p);
        return CardTap(
          pill: p,
          onTap: () => onOpen(pills, p),
          child: Container(
            width: 196,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardHead(
                  pill: p,
                  trailing: isRead(p) ? ReadMark(pill: p) : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 9),
                    child: CardQuestion(
                      text: p.question,
                      color: p.ink,
                      min: 10.5,
                      max: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 9),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: hairOn(p))),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 14, color: p.ink),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.l10n.hidesIn(inSentence(genreLabel(p))),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                            size: 11,
                            weight: FontWeight.w600,
                            height: 1,
                            color: p.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// What the reader has done with a move, level with the shelf's name: met
/// it so many times, lit; or not yet, outlined.
class MoveBadge extends StatelessWidget {
  const MoveBadge({super.key, required this.label, required this.lit});

  final String label;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: lit ? context.p.inverse : null,
        borderRadius: BorderRadius.circular(8),
        border: lit ? null : Border.all(color: ink.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.body(
          size: 10.5,
          weight: FontWeight.w700,
          height: 1,
          color: lit ? context.p.onInverse : ink,
        ),
      ),
    );
  }
}

// ── What if it's true? (138a) ────────────────────────────────────────────

/// Big ideas on wide cards, a question mark drawn large behind each, and at
/// the foot the question the card leaves you with: what keeps working after
/// the card is closed.
class WhatIfRow extends StatelessWidget {
  const WhatIfRow({
    super.key,
    required this.pills,
    required this.isRead,
    required this.onOpen,
    this.onShown,
  });

  final List<Pill> pills;
  final bool Function(Pill) isRead;
  final OpenCard onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    return SideRow(
      height: 244,
      count: pills.length,
      itemBuilder: (context, i) {
        final Pill p = pills[i];
        onShown?.call(p);
        return CardTap(
          pill: p,
          onTap: () => onOpen(pills, p),
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: p.color,
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  right: -4,
                  bottom: -60,
                  child: Text(
                    '?',
                    textScaler: TextScaler.noScaling,
                    style: AppText.display(
                      size: 250,
                      weight: FontWeight.w600,
                      height: 1,
                      color: shade(p.color, 0.86),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CardHead(
                        pill: p,
                        trailing: isRead(p) ? ReadMark(pill: p) : null,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                          child: CardQuestion(
                            text: p.question,
                            color: p.ink,
                            min: 13,
                            max: 21,
                            height: 1.12,
                            tracking: -0.032,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(top: 11),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: hairOn(p))),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.replay_rounded,
                                size: 14,
                                color: p.ink,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                p.ask,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body(
                                  size: 11.5,
                                  weight: FontWeight.w600,
                                  height: 1.3,
                                  color: p.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── How sure am I, and why? (138c) ───────────────────────────────────────

/// A question to ask of your own life, set large under what it is about,
/// and the cards that ask it in other words.
class HowSureShelf extends StatelessWidget {
  const HowSureShelf({
    super.key,
    required this.pills,
    required this.isRead,
    required this.onOpen,
    this.onShown,
  });

  final List<Pill> pills;
  final bool Function(Pill) isRead;
  final OpenCard onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Kicker(context.l10n.whatYouBelieve),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: ink.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                context.l10n.howSure,
                style: AppText.display(
                  size: 25,
                  weight: FontWeight.w600,
                  height: 1.12,
                  spacing: -0.6,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SideRow(
          height: 200,
          count: pills.length,
          itemBuilder: (context, i) {
            final Pill p = pills[i];
            onShown?.call(p);
            return CardTap(
              pill: p,
              onTap: () => onOpen(pills, p),
              child: Container(
                width: 290,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CardHead(
                      pill: p,
                      trailing: isRead(p) ? ReadMark(pill: p) : null,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: CardQuestion(
                          text: p.question,
                          color: p.ink,
                          min: 12,
                          max: 19,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Use it today (131e) ──────────────────────────────────────────────────

/// Something to try, or to say, before tonight: three rows, each the thing
/// itself in its card's colour, and the rest a tap away. A row opens its
/// card. There was a ring on each to tick it off as tried, and nobody could
/// tell what the ring was for.
class UseTodayList extends StatefulWidget {
  const UseTodayList({
    super.key,
    required this.pills,
    required this.isRead,
    required this.onOpen,
    this.onShown,
  });

  final List<Pill> pills;
  final bool Function(Pill) isRead;
  final OpenCard onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  State<UseTodayList> createState() => _UseTodayListState();
}

class _UseTodayListState extends State<UseTodayList> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final List<Pill> shown = _all
        ? widget.pills
        : widget.pills.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final Pill p in shown) ...[
            _row(context, p),
            const SizedBox(height: 7),
          ],
          if (widget.pills.length > 3)
            Semantics(
              key: const ValueKey('use-today-all'),
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _all = !_all),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.p.ink.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _all
                        ? context.l10n.showFewer
                        : context.l10n.showAllN(widget.pills.length),
                    style: AppText.body(
                      size: 13,
                      weight: FontWeight.w600,
                      height: 1,
                      color: context.p.ink.withValues(alpha: 0.62),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, Pill p) {
    widget.onShown?.call(p);
    return CardTap(
      pill: p,
      onTap: () => widget.onOpen(widget.pills, p),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
        decoration: BoxDecoration(
          color: p.color,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardHead(
              pill: p,
              trailing: widget.isRead(p) ? ReadMark(pill: p) : null,
            ),
            const SizedBox(height: 8),
            Text(
              p.question,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppText.display(
                size: 15,
                weight: FontWeight.w600,
                height: 1.18,
                spacing: -0.4,
                color: p.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
