/// More of the themes the app rotates, each with a form of its own — the
/// canvas's 133e.
///
/// The themes are the app's (themed_shelves.dart); what these blocks add
/// is the form, so a shelf says what it holds before a word of it is read:
/// an answer box for a number worked out in your head, a card's own picture
/// for a card that draws its point, graph paper under a mechanism, a circle
/// for wonder, a band that says when a changing thing was last brought up
/// to date. True or false, true stories, where it came from and for the
/// sharpest are in the app already, as core's shelves.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../data/themed_shelves.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/card_edge.dart';
import '../../../widgets/subject_icon.dart';
import '../../explore_block.dart';
import 'kit.dart';

/// A shelf of tiles of one form: the form's own name and line unless the
/// section gives its own, and its cards in a row.
Widget formShelf({
  required BuildContext context,
  required ExploreHost host,
  required ExploreSection section,
  required String title,
  required String line,
  required List<Pill> cards,
  required double height,
  required Widget Function(Pill pill, List<Pill> shelf) tile,
}) {
  final String lang = host.language;
  return host.watch(
    section,
    PurposeShelf(
      title: section.title(lang) ?? title,
      line: section.subtitle(lang) ?? line,
      child: SideRow(
        height: height + 4,
        count: cards.length,
        itemBuilder: (context, i) {
          host.seen(section, cards[i]);
          return tile(cards[i], cards);
        },
      ),
    ),
  );
}

// ── Work it out, in your head ────────────────────────────────────────────

/// The answer a number card takes, as it reads on the card: `41%`, `12
/// tonnes`. Null on a card that does not ask for a number.
String? numberAnswer(Pill p) {
  final (num answer, String unit) = switch (p.challenge) {
    TypeNumber(:final answer, :final unit) => (answer, unit),
    Estimate(:final answer, :final unit) => (answer, unit),
    _ => (double.nan, ''),
  };
  if (answer.isNaN) return null;
  final String n = answer == answer.roundToDouble()
      ? '${answer.round()}'
      : '$answer';
  return isPercent(unit) ? '$n%' : (unit.isEmpty ? n : '$n $unit');
}

/// Whether a card's unit is a share.
bool isPercent(String unit) =>
    const {'%', 'percent', 'per cent'}.contains(unit.trim().toLowerCase());

/// 133e: a number to reach in your head, typed on the shelf.
class InYourHeadBlock extends ExploreBlock {
  const InYourHeadBlock();

  @override
  String get name => 'purpose.in-your-head';

  /// The block's sizes; `m` is the canvas's.
  static const Map<String, TileSize> sizes = {
    's': TileSize(200, 212),
    'm': TileSize(222, 228),
    'l': TileSize(250, 252),
  };

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> cards = cardsOf(
      host,
      section,
      limit: 8,
      canDraw: (p) => numberAnswer(p) != null,
    );
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final TileSize size = sizeOf(section, sizes);
    return formShelf(
      context: context,
      host: host,
      section: section,
      title: l.themeWorkItOut,
      line: l.purposeInYourHeadLine,
      cards: cards,
      height: size.height,
      tile: (p, shelf) => HeadTile(
        key: ValueKey('head-${p.id}'),
        pill: p,
        size: size,
        read: host.isRead(p),
        given: host.app.answerFor(p.id)?.response,
        onOpen: () => host.open(section, shelf, p),
        onCommit: (response) {
          PurposePlay.writeSet('said', PurposePlay.setOf('said')..add(p.id));
          host.commit(p, response);
        },
      ),
    );
  }
}

/// A number card with its answer box: tapped, the box takes the number;
/// sent, the card says whether it was right.
class HeadTile extends StatefulWidget {
  const HeadTile({
    super.key,
    required this.pill,
    required this.size,
    required this.read,
    required this.given,
    required this.onOpen,
    required this.onCommit,
  });

  final Pill pill;
  final TileSize size;
  final bool read;
  final String? given;
  final VoidCallback onOpen;
  final ValueChanged<String> onCommit;

  @override
  State<HeadTile> createState() => _HeadTileState();
}

class _HeadTileState extends State<HeadTile> {
  final TextEditingController _typed = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _typing = false;
  String? _said;

  @override
  void dispose() {
    _typed.dispose();
    _focus.dispose();
    super.dispose();
  }

  String? get _answer => widget.given ?? _said;

  void _open() {
    if (_answer != null) return;
    setState(() => _typing = true);
    _focus.requestFocus();
  }

  void _send() {
    final String? plain = TypeNumber.read(
      _typed.text,
      locale: Localizations.localeOf(context).toString(),
    );
    // A box with no number in it is not an answer: it stays open.
    if (plain == null) return;
    _focus.unfocus();
    setState(() {
      _said = plain;
      _typing = false;
    });
    widget.onCommit(plain);
  }

  @override
  Widget build(BuildContext context) {
    final Pill p = widget.pill;
    final l = context.l10n;
    final String? answer = _answer;
    final String unit = switch (p.challenge) {
      TypeNumber(:final unit) || Estimate(:final unit) => unit,
      _ => '',
    };
    final bool estimate = p.challenge is Estimate;
    final bool dark = p.ink.computeLuminance() < 0.5;
    final Color edge = p.ink.withValues(alpha: dark ? 0.5 : 0.7);
    final TextStyle figure = AppText.display(
      size: 18,
      weight: FontWeight.w600,
      height: 1,
      color: p.ink,
    );
    final String template = isPercent(unit)
        ? '__ %'
        : '${estimate ? '≈ ' : ''}__${unit.isEmpty ? '' : ' $unit'}';

    final Widget box;
    if (answer != null) {
      final String shown = isPercent(unit)
          ? '$answer%'
          : (unit.isEmpty ? answer : '$answer $unit');
      box = Text(
        shown,
        key: ValueKey('head-said-${p.id}'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: figure,
      );
    } else if (_typing) {
      box = Row(
        children: [
          Expanded(
            child: TextField(
              key: ValueKey('head-field-${p.id}'),
              controller: _typed,
              focusNode: _focus,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _send(),
              cursorColor: p.ink,
              style: figure,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: template,
                hintStyle: figure.copyWith(color: p.ink.withValues(alpha: 0.4)),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: l.check,
            child: GestureDetector(
              key: ValueKey('head-send-${p.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: _send,
              child: SizedBox(
                width: 34,
                height: 34,
                child: Center(
                  child: PurposeGlyph(Glyphs.check, size: 18, color: p.ink),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      box = Row(
        children: [
          Container(width: 2, height: 20, color: p.ink),
          const SizedBox(width: 8),
          Text(template, maxLines: 1, style: figure.copyWith(color: subOn(p))),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  upper(context, l.purposeInYourHead),
                  maxLines: 1,
                  style: AppText.label(
                    size: 9,
                    weight: FontWeight.w700,
                    spacing: 1.1,
                    height: 1,
                    color: subOn(p),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return CardTap(
      pill: p,
      onTap: widget.onOpen,
      child: Container(
        width: widget.size.width,
        height: widget.size.height,
        padding: const EdgeInsets.all(16),
        decoration: cardFace(context, p.color, radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PurposeHead(
              pill: p,
              trailing: widget.read ? ReadMark(pill: p) : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: CardQuestion(
                  text: p.question,
                  color: p.ink,
                  min: 10.5,
                  max: widget.size.width < 210 ? 15 : 16.5,
                ),
              ),
            ),
            if (answer != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  p.challenge.accepts(answer)
                      ? l.tfRight
                      : l.tfWrong(numberAnswer(p)!),
                  key: ValueKey('head-verdict-${p.id}'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w700,
                    height: 1.25,
                    color: p.ink,
                  ),
                ),
              ),
            Semantics(
              button: answer == null && !_typing,
              label: answer == null ? l.purposeInYourHead : null,
              child: GestureDetector(
                key: ValueKey('head-box-${p.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: _typing ? null : _open,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: answer != null ? fillOn(p) : null,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: answer != null ? Colors.transparent : edge,
                      width: 2,
                    ),
                  ),
                  child: box,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Seen, not read ───────────────────────────────────────────────────────

/// A card's picture in miniature: up to six bars, a line, or marks on a
/// line of time, each in the card's darker tone with the part that matters
/// in its ink.
@immutable
class Silhouette {
  const Silhouette.bars(this.values, this.lit) : kind = SilhouetteKind.bars;
  const Silhouette.line(this.values)
    : kind = SilhouetteKind.line,
      lit = const {};
  const Silhouette.time(this.values, this.lit) : kind = SilhouetteKind.time;

  final SilhouetteKind kind;

  /// From 0 to 1: bar heights, the line's points, or places along time.
  final List<double> values;

  /// Which of [values] are the point: drawn in the card's ink.
  final Set<int> lit;

  @override
  bool operator ==(Object other) =>
      other is Silhouette &&
      other.kind == kind &&
      _same(other.values, values) &&
      other.lit.length == lit.length &&
      other.lit.containsAll(lit);

  static bool _same(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(kind, Object.hashAll(values), lit.length);
}

/// What a [Silhouette] draws.
enum SilhouetteKind { bars, line, time }

/// The silhouette of [d]: the shape its own numbers make. Null for a
/// picture with nothing to draw small.
Silhouette? silhouetteOf(Diagram d) {
  Silhouette? bars(List<(double, bool)> items, {bool log = false}) {
    final List<(double, bool)> some = items.take(6).toList();
    if (some.isEmpty) return null;
    double at(double v) => log ? math.log(math.max(v, 1e-9)) : v;
    final List<double> raw = [for (final (v, _) in some) at(v)];
    final double lo = log ? raw.reduce(math.min) : 0;
    final double hi = raw.reduce(math.max);
    if (hi <= lo) return null;
    final List<double> values = [
      // Never flat to nothing: the smallest bar still stands a little.
      for (final double v in raw)
        (0.12 + 0.88 * (v - lo) / (hi - lo)).clamp(0.12, 1.0),
    ];
    Set<int> lit = {
      for (int i = 0; i < some.length; i++)
        if (some[i].$2) i,
    };
    if (lit.isEmpty) {
      int top = 0;
      for (int i = 1; i < values.length; i++) {
        if (values[i] > values[top]) top = i;
      }
      lit = {top};
    }
    return Silhouette.bars(values, lit);
  }

  switch (d) {
    case BarsDiagram(:final items, :final log):
      return bars([for (final i in items) (i.value, i.highlight)], log: log);
    case ScaleDiagram(:final items):
      return bars([for (final i in items) (i.value, i.highlight)], log: true);
    case AreaDiagram(:final items):
      return bars([for (final i in items) (i.value, i.highlight)]);
    case SplitDiagram(:final parts):
      return bars([for (final i in parts) (i.value, i.highlight)]);
    case DotsDiagram(:final groups):
      return bars([for (final g in groups) (g.n.toDouble(), g.highlight)]);
    case TreeDiagram(:final root):
      return bars([for (final c in root.children) (c.n, c.highlight)]);
    case LineDiagram(:final series):
      if (series.isEmpty) return null;
      final LineSeries s = series.firstWhere(
        (s) => s.highlight,
        orElse: () => series.first,
      );
      if (s.points.length < 2) return null;
      final List<double> ys = [for (final (_, y) in s.points) y];
      final double lo = ys.reduce(math.min), hi = ys.reduce(math.max);
      if (hi <= lo) return null;
      // Twelve points along it at most: enough for its shape, few enough
      // to read at this size.
      final int every = math.max(1, (ys.length / 12).ceil());
      return Silhouette.line([
        for (int i = 0; i < ys.length; i += every) (ys[i] - lo) / (hi - lo),
        if ((ys.length - 1) % every != 0) (ys.last - lo) / (hi - lo),
      ]);
    case TimelineDiagram(:final from, :final to, :final events, :final spans):
      if (to <= from) return null;
      final List<(double, bool)> marks = [
        for (final e in events) ((e.at - from) / (to - from), e.highlight),
        for (final s in spans) ((s.from - from) / (to - from), s.highlight),
      ];
      if (marks.isEmpty) return null;
      return Silhouette.time(
        [for (final (v, _) in marks) v.clamp(0.0, 1.0)],
        {
          for (int i = 0; i < marks.length; i++)
            if (marks[i].$2) i,
        },
      );
  }
}

/// 133e: cards that draw their point, each with its picture in miniature.
class SeenBlock extends ExploreBlock {
  const SeenBlock();

  @override
  String get name => 'purpose.seen';

  /// The block's sizes; `m` is the canvas's.
  static const Map<String, TileSize> sizes = {
    's': TileSize(176, 224),
    'm': TileSize(200, 248),
    'l': TileSize(228, 276),
  };

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> cards = cardsOf(
      host,
      section,
      limit: 8,
      canDraw: (p) => p.diagram != null && silhouetteOf(p.diagram!) != null,
    );
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final TileSize size = sizeOf(section, sizes);
    return formShelf(
      context: context,
      host: host,
      section: section,
      title: l.themeSeen,
      line: l.themeSeenLine,
      cards: cards,
      height: size.height,
      tile: (p, shelf) => CardTap(
        pill: p,
        onTap: () => host.open(section, shelf, p),
        child: Container(
          width: size.width,
          height: size.height,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: cardFace(context, p.color, radius: 22),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PurposeHead(
                pill: p,
                trailing: host.isRead(p) ? ReadMark(pill: p) : null,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: CardQuestion(
                    text: p.question,
                    color: p.ink,
                    min: 10.5,
                    max: size.width < 190 ? 15 : 16.5,
                  ),
                ),
              ),
              SizedBox(
                height: size.height * 0.27,
                child: ExcludeSemantics(
                  child: CustomPaint(
                    painter: SilhouettePainter(
                      silhouetteOf(p.diagram!)!,
                      tone: shade(p.color, 0.74),
                      ink: p.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws a [Silhouette] standing on the card's foot.
class SilhouettePainter extends CustomPainter {
  SilhouettePainter(this.shape, {required this.tone, required this.ink});

  final Silhouette shape;
  final Color tone;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fill = Paint();
    switch (shape.kind) {
      case SilhouetteKind.bars:
        final int n = shape.values.length;
        const double gap = 5;
        final double w = (size.width - gap * (n - 1)) / n;
        for (int i = 0; i < n; i++) {
          final double h = size.height * shape.values[i];
          final Rect r = Rect.fromLTWH(i * (w + gap), size.height - h, w, h);
          fill.color = shape.lit.contains(i) ? ink : tone;
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              r,
              topLeft: const Radius.circular(5),
              topRight: const Radius.circular(5),
            ),
            fill,
          );
        }
      case SilhouetteKind.line:
        final int n = shape.values.length;
        final double top = 6, bottom = size.height - 14;
        Offset at(int i) => Offset(
          size.width * i / (n - 1),
          bottom - (bottom - top) * shape.values[i],
        );
        final Path line = Path()..moveTo(at(0).dx, at(0).dy);
        for (int i = 1; i < n; i++) {
          line.lineTo(at(i).dx, at(i).dy);
        }
        final Path area = Path.from(line)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(area, fill..color = tone);
        canvas.drawPath(
          line,
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(at(n - 1), 4, Paint()..color = ink);
      case SilhouetteKind.time:
        final double y = size.height - 18;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, y - 2, size.width, 4),
            const Radius.circular(2),
          ),
          fill..color = tone,
        );
        for (int i = 0; i < shape.values.length; i++) {
          final double x = 7 + (size.width - 14) * shape.values[i];
          final bool lit = shape.lit.contains(i);
          canvas.drawCircle(
            Offset(x, y),
            lit ? 7 : 5,
            Paint()..color = lit ? ink : tone,
          );
        }
    }
  }

  @override
  bool shouldRepaint(SilhouettePainter old) =>
      old.shape != shape || old.tone != tone || old.ink != ink;
}

// ── How it really works ──────────────────────────────────────────────────

/// 133e: mechanisms, on graph paper, with THE MECHANISM at their foot.
class MechanismBlock extends ExploreBlock {
  const MechanismBlock();

  @override
  String get name => 'purpose.mechanism';

  /// The block's sizes; `m` is the canvas's.
  static const Map<String, TileSize> sizes = {
    's': TileSize(180, 212),
    'm': TileSize(206, 236),
    'l': TileSize(236, 262),
  };

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> cards = cardsOf(
      host,
      section,
      limit: 8,
      fits: (p) => fitsTheme(ShelfTheme.howItWorks, p),
    );
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final TileSize size = sizeOf(section, sizes);
    return formShelf(
      context: context,
      host: host,
      section: section,
      title: l.themeHowItWorks,
      line: l.themeHowItWorksLine,
      cards: cards,
      height: size.height,
      tile: (p, shelf) => CardTap(
        pill: p,
        onTap: () => host.open(section, shelf, p),
        child: Container(
          width: size.width,
          height: size.height,
          decoration: cardFace(context, p.color, radius: 22),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _GraphPaper(shade(p.color, 0.86)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PurposeHead(
                    pill: p,
                    trailing: host.isRead(p) ? ReadMark(pill: p) : null,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: CardQuestion(
                        text: p.question,
                        color: p.ink,
                        min: 11,
                        max: size.width < 200 ? 15.5 : 17.5,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      PurposeGlyph(
                        Glyphs.sun,
                        size: 14,
                        color: p.ink,
                        stroke: 2,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          upper(context, l.purposeMechanism),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.label(
                            size: 9,
                            weight: FontWeight.w700,
                            spacing: 1.2,
                            height: 1,
                            color: p.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lines every sixteen points, both ways, in the card's darker tone: the
/// paper a mechanism is worked out on.
class _GraphPaper extends CustomPainter {
  _GraphPaper(this.line);

  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (double x = 0.5; x < size.width; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0.5; y < size.height; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GraphPaper old) => old.line != line;
}

// ── Just curious ─────────────────────────────────────────────────────────

/// 133e: cards read for the pleasure of knowing why, each a circle.
class CuriousBlock extends ExploreBlock {
  const CuriousBlock();

  @override
  String get name => 'purpose.curious';

  /// The circles across, by size; `m` is the canvas's.
  static const Map<String, double> sizes = {'s': 184, 'm': 216, 'l': 248};

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> cards = cardsOf(
      host,
      section,
      limit: 8,
      fits: (p) => fitsTheme(ShelfTheme.curious, p),
    );
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final double across = sizeOf(section, sizes);
    return formShelf(
      context: context,
      host: host,
      section: section,
      title: l.themeCurious,
      line: l.themeCuriousLine,
      cards: cards,
      height: across,
      tile: (p, shelf) => CardTap(
        pill: p,
        onTap: () => host.open(section, shelf, p),
        child: Container(
          width: across,
          height: across,
          padding: EdgeInsets.all(across * 0.157),
          decoration: BoxDecoration(
            color: p.color,
            shape: BoxShape.circle,
            border: cardHairline(p.color, context.p.surface),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SubjectIcon(subject: p.topic, size: 15, ink: p.ink),
                  if (host.isRead(p)) ...[
                    const SizedBox(width: 6),
                    ReadMark(pill: p),
                  ],
                ],
              ),
              const SizedBox(height: 9),
              Expanded(
                // A circle's lines are centred, so the question is set to
                // the space with its lines centred too.
                child: DefaultTextStyle.merge(
                  textAlign: TextAlign.center,
                  child: CardQuestion(
                    text: p.question,
                    color: p.ink,
                    min: 10,
                    max: across < 200 ? 13.5 : 15,
                    height: 1.16,
                    tracking: -0.02,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Still moving ─────────────────────────────────────────────────────────

/// 133e: things still changing, each with a band that says when it was
/// last brought up to date, or how soon it could change.
class MovingBlock extends ExploreBlock {
  const MovingBlock();

  @override
  String get name => 'purpose.moving';

  /// The block's sizes; `m` is the canvas's.
  static const Map<String, TileSize> sizes = {
    's': TileSize(204, 196),
    'm': TileSize(232, 214),
    'l': TileSize(262, 236),
  };

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> cards = cardsOf(
      host,
      section,
      limit: 8,
      fits: (p) => fitsTheme(ShelfTheme.moving, p),
    );
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final TileSize size = sizeOf(section, sizes);
    final Object? dates = section.json['updated'];
    final String locale = Localizations.localeOf(context).toString();
    String band(Pill p) {
      final Object? raw = dates is Map ? dates[p.id] : null;
      final DateTime? on = raw is String ? DateTime.tryParse(raw) : null;
      if (on != null) {
        String date;
        try {
          date = DateFormat.MMMd(locale).format(on);
        } catch (_) {
          date = DateFormat.MMMd('en').format(on);
        }
        return l.purposeMovingUpdated(date);
      }
      return p.shelfLife == 'months'
          ? l.purposeMovingMonths
          : l.purposeMovingYears;
    }

    return formShelf(
      context: context,
      host: host,
      section: section,
      title: l.themeMoving,
      line: l.themeMovingLine,
      cards: cards,
      height: size.height,
      tile: (p, shelf) => CardTap(
        pill: p,
        onTap: () => host.open(section, shelf, p),
        child: Container(
          width: size.width,
          height: size.height,
          decoration: cardFace(context, p.color, radius: 22),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 30,
                color: shade(p.color, 0.86),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: p.ink,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        upper(context, band(p)),
                        key: ValueKey('moving-band-${p.id}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(
                          size: 9,
                          weight: FontWeight.w700,
                          spacing: 1.2,
                          height: 1,
                          color: p.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PurposeHead(
                        pill: p,
                        trailing: host.isRead(p) ? ReadMark(pill: p) : null,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: CardQuestion(
                            text: p.question,
                            color: p.ink,
                            min: 11,
                            max: size.width < 220 ? 15.5 : 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
