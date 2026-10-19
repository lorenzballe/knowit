/// The shapes that run down the page, every card whole: rows in the cards'
/// own colours (131c), a checklist of things to try before tonight (131e,
/// and 132b's with a sun going down behind each), a list of figures (131e)
/// and a line of time down the page (131e, 131f, 132b).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/explore_mix.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/card_edge.dart';
import '../../../widgets/explore/parts.dart';
import '../../../widgets/subject_icon.dart';
import '../../explore_block.dart';
import 'deal.dart';
import 'look.dart';
import 'outlines.dart';
import 'shelf.dart';
import 'signatures.dart';
import 'vocabulary.dart';
import 'years.dart';

/// A question set whole, at a size of its own: the rows of a list grow to
/// hold it rather than fit it to a box.
Widget _question(Pill p, double size, {double height = 1.2, Color? colour}) =>
    Text(
      p.question,
      style: AppText.display(
        size: size,
        weight: FontWeight.w600,
        height: height,
        spacing: -0.027 * size,
        color: colour ?? p.ink,
      ),
    );

/// A row of a list: tappable, seen as it is built, opening among the rest.
Widget _row(
  ExploreHost host,
  ShapeDeal deal,
  List<Pill> shelf,
  Pill p,
  Widget child,
) {
  host.seen(deal.section, p);
  return CardTap(
    pill: p,
    onTap: () => host.open(deal.section, shelf, p),
    child: child,
  );
}

// ── Rows (131c) ──────────────────────────────────────────────────────────

/// Something to try before tonight, as rows the width of the page, each in
/// its card's colour with its mark beside the question (131c).
class RowsBlock extends ShapeBlock {
  const RowsBlock();

  @override
  String get name => 'shape-rows';

  @override
  ShapeVocabulary get words => const ShapeVocabulary(
    canvas: ['131c'],
    kind: 'practical',
    limit: 3,
    most: 8,
    fewest: 2,
  );

  static const Map<String, (double, double, EdgeInsets)> _sizes = {
    's': (13.5, 15, EdgeInsets.fromLTRB(12, 12, 14, 12)),
    'm': (14.5, 15, EdgeInsets.fromLTRB(14, 14, 16, 14)),
    'l': (16, 17, EdgeInsets.fromLTRB(16, 16, 18, 16)),
  };

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) {
    final (double size, double radius, EdgeInsets pad) =
        _sizes[sizeOf(deal.section)]!;
    final List<Pill> cards = deal.cards;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 7),
            _row(
              host,
              deal,
              cards,
              cards[i],
              Container(
                padding: pad,
                decoration: cardFace(context, cards[i].color, radius: radius),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: SubjectIcon(
                        subject: cards[i].topic,
                        size: 16,
                        ink: cards[i].ink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _question(cards[i], size)),
                    if (host.isRead(cards[i])) ...[
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: ReadMark(pill: cards[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── The checklist (131e, 131f, 132b) ─────────────────────────────────────

/// Something to try before tonight, as a list to work down: the first few,
/// each the thing itself in its card's colour, the rest a tap away, and
/// with the sunset signature a sun going down behind each, and how long it
/// takes beside its subject (132b).
///
/// The canvas draws a ring at the end of every row. Rings to tick a row off
/// as tried were taken off the app's own Use it today because nobody could
/// tell what they were for, so here a ring is the card's read mark and
/// nothing else: drawn once the card has been read, ticked, and by default
/// not before (`"style": {"rings": "read"}`). `"all"` draws the canvas's
/// empty ring on every row until it is read; `"none"` none at all.
class ChecklistBlock extends ShapeBlock {
  const ChecklistBlock();

  @override
  String get name => 'shape-checklist';

  @override
  ShapeVocabulary get words => const ShapeVocabulary(
    canvas: ['131e', '131f', '132b'],
    kind: 'practical',
    signatures: ['sunset', 'none'],
    style: {
      'rings': ShapeStyleKey.oneOf(['read', 'all', 'none']),
      'shown': ShapeStyleKey.count(1, 8),
    },
  );

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) {
    final Object? rings = deal.section.style['rings'];
    final Object? shown = deal.section.style['shown'];
    return _Checklist(
      host: host,
      deal: deal,
      size: sizeOf(deal.section),
      sunset: signatureOf(deal.section) == 'sunset',
      rings: rings is String && ['read', 'all', 'none'].contains(rings)
          ? rings
          : 'read',
      shown: shown is int && shown >= 1 && shown <= 8 ? shown : 3,
    );
  }
}

class _Checklist extends StatefulWidget {
  const _Checklist({
    required this.host,
    required this.deal,
    required this.size,
    required this.sunset,
    required this.rings,
    required this.shown,
  });

  final ExploreHost host;
  final ShapeDeal deal;
  final String size;
  final bool sunset;
  final String rings;
  final int shown;

  @override
  State<_Checklist> createState() => _ChecklistState();
}

class _ChecklistState extends State<_Checklist> {
  bool _all = false;

  static const Map<String, (double, double, double, EdgeInsets)> _sizes = {
    's': (13.5, 24, 17, EdgeInsets.fromLTRB(14, 13, 14, 13)),
    'm': (15, 27, 18, EdgeInsets.fromLTRB(16, 15, 16, 15)),
    'l': (16.5, 30, 20, EdgeInsets.fromLTRB(18, 17, 18, 17)),
  };

  @override
  Widget build(BuildContext context) {
    final ExploreHost host = widget.host;
    final List<Pill> cards = widget.deal.cards;
    final List<Pill> showing = _all ? cards : cards.take(widget.shown).toList();
    final (double size, double ring, double radius, EdgeInsets pad) =
        _sizes[widget.size]!;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final Pill p in showing) ...[
            _row(
              host,
              widget.deal,
              cards,
              p,
              _item(context, p, size, ring, radius, pad),
            ),
            const SizedBox(height: 7),
          ],
          if (cards.length > widget.shown)
            Semantics(
              key: ValueKey('shape-checklist-all-${widget.deal.section.id}'),
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => _all = !_all);
                  host.note(
                    widget.deal.section,
                    _all ? 'expanded' : 'collapsed',
                    {'count': cards.length},
                  );
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.p.ink.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    _all ? l.showFewer : l.showAllN(cards.length),
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      size: 13,
                      weight: FontWeight.w600,
                      height: 1.2,
                      color: context.p.ink.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    Pill p,
    double size,
    double ring,
    double radius,
    EdgeInsets pad,
  ) {
    final bool read = widget.host.isRead(p);
    final bool ringed =
        widget.rings == 'all' || (widget.rings == 'read' && read);
    final l = context.l10n;
    final String head = widget.sunset
        ? '${subjectLabel(context, p)} · '
              '${upper(context, l.minutesShort(minutesFor(p)))}'
        : subjectLabel(context, p);
    final Widget body = Padding(
      padding: pad,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SubjectIcon(subject: p.topic, size: 15, ink: p.ink),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        head,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tileLabel(subOn(p)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _question(p, size, height: 1.18),
              ],
            ),
          ),
          if (ringed) ...[
            const SizedBox(width: 14),
            Semantics(
              label: read ? l.readMark : null,
              child: Container(
                key: ValueKey('shape-ring-${p.id}'),
                width: ring,
                height: ring,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: read ? p.ink : null,
                  border: Border.all(
                    color: read ? p.ink : p.ink.withValues(alpha: 0.7),
                    width: 2,
                  ),
                ),
                child: read
                    ? Icon(
                        Icons.check_rounded,
                        size: ring * 0.62,
                        color: p.color,
                      )
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
    // The sun is cut by the row's corners, and the hairline a pale card is
    // cut out of the page with is drawn over it, so it never covers the edge.
    final BorderRadius corners = BorderRadius.circular(radius);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: p.color, borderRadius: corners),
      foregroundDecoration: BoxDecoration(
        borderRadius: corners,
        border: cardHairline(p.color, context.p.surface),
      ),
      child: widget.sunset
          ? CustomPaint(
              painter: _Behind(
                SunArt(
                  colour: tone(p, Tones.graphic),
                  radius: 66,
                  fromCorner: const Offset(-32, 12),
                ),
              ),
              child: body,
            )
          : body,
    );
  }
}

/// A signature painted behind a row's words.
class _Behind extends CustomPainter {
  _Behind(this.art);

  final FaceArt art;

  @override
  void paint(Canvas canvas, Size size) => art.paint(canvas, size);

  @override
  bool shouldRepaint(_Behind old) => old.art != art;
}

// ── The figures (131e) ───────────────────────────────────────────────────

/// Numbers that surprise, as a list of figures: each set large in its
/// subject's colour, its question beside it and the subject under that,
/// hairlines between (131e). It takes only cards with a figure to set.
class FiguresBlock extends ShapeBlock {
  const FiguresBlock();

  @override
  String get name => 'shape-figures';

  @override
  ShapeVocabulary get words => const ShapeVocabulary(
    canvas: ['131e'],
    kind: 'numbers',
    limit: 4,
    most: 8,
  );

  static const Map<String, (double, double, double)> _sizes = {
    's': (80, 40, 13),
    'm': (92, 46, 14),
    'l': (104, 52, 15.5),
  };

  @override
  bool Function(Pill)? keep(ExploreSection section) =>
      (p) => figureOf(p) != null;

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) {
    final (double column, double figure, double size) =
        _sizes[sizeOf(deal.section)]!;
    final List<Pill> cards = deal.cards;
    final bool dark = context.p.isDark;
    final Color hair = context.p.ink.withValues(alpha: 0.1);
    // On paper a pale colour cannot carry a figure: its darker tone does, as
    // on the app's shelf of the hardest cards.
    Color figureColour(Pill p) => !dark && p.color.computeLuminance() > 0.45
        ? shade(p.color, 0.62)
        : p.color;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: hair)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final Pill p in cards)
            _row(
              host,
              deal,
              cards,
              p,
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: hair)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: column,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          figureOf(p)!,
                          maxLines: 1,
                          textScaler: TextScaler.noScaling,
                          style: AppText.display(
                            size: figure,
                            weight: FontWeight.w600,
                            height: 0.9,
                            spacing: -0.044 * figure,
                            color: figureColour(p),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _question(
                            p,
                            size,
                            height: 1.22,
                            colour: context.p.ink.withValues(alpha: 0.93),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              SubjectIcon(
                                subject: p.topic,
                                size: 12,
                                ink: figureColour(p),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  context.l10n.subjectOf(p.topic),
                                  style: AppText.body(
                                    size: 10.5,
                                    weight: FontWeight.w500,
                                    height: 1.2,
                                    spacing: 0.3,
                                    color: context.p.ink.withValues(
                                      alpha: 0.42,
                                    ),
                                  ),
                                ),
                              ),
                              if (host.isRead(p)) ...[
                                const SizedBox(width: 6),
                                ReadMark(
                                  pill: p,
                                  color: context.p.ink,
                                  size: 12,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── The timeline down the page (131e, 131f, 132b) ────────────────────────

/// The past down a line of time: each card on the line under its year, in
/// order, the line running the length of the shelf (131e, 131f); at the
/// large size the years are set as 132b sets them.
class TimelineBlock extends ShapeBlock {
  const TimelineBlock();

  @override
  String get name => 'shape-timeline';

  @override
  ShapeVocabulary get words => const ShapeVocabulary(
    canvas: ['131e', '131f', '132b'],
    kind: 'past',
    limit: 4,
    most: 8,
    fields: ['order'],
  );

  /// At each size: the years' column at its narrowest, the year's type,
  /// the question's, how far down the year starts and where its dot is.
  static const Map<String, (double, double, double, double, double)> _sizes = {
    's': (38, 13, 13.5, 14, 15),
    'm': (44, 15, 15, 15, 16),
    'l': (58, 22, 16, 13, 16),
  };

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) {
    final (double least, double year, double size, double drop, double dot) =
        _sizes[sizeOf(deal.section)]!;
    final List<Pill> cards = inOrderOfTime(deal);
    final Color ink = context.p.ink;
    final Color page = context.p.surface;
    final TextStyle yearStyle = AppText.display(
      size: year,
      weight: FontWeight.w600,
      height: 1,
      spacing: -0.027 * year,
      color: ink,
    );
    final List<String> years = [
      for (final Pill p in cards) yearLabel(context, p),
    ];
    // The years' column is as wide as its widest year, from the canvas's
    // width up to a quarter of the page; an age's name longer than that is
    // set smaller to fit, never broken.
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    double widest = least;
    for (final String y in years) {
      final TextPainter tp = TextPainter(
        text: TextSpan(text: y, style: yearStyle),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, tp.width);
      tp.dispose();
    }
    return LayoutBuilder(
      builder: (context, box) {
        final double column = math.min(widest, (box.maxWidth - 40) * 0.25);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < cards.length; i++)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: column,
                        child: Padding(
                          padding: EdgeInsets.only(top: drop),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topRight,
                              child: Text(
                                years[i],
                                maxLines: 1,
                                style: yearStyle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 14,
                        child: CustomPaint(
                          painter: _Spine(
                            line: ink.withValues(alpha: 0.16),
                            dot: cards[i].color,
                            ring: page,
                            at: dot,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _row(
                            host,
                            deal,
                            cards,
                            cards[i],
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: cardFace(
                                context,
                                cards[i].color,
                                radius: 19,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: SubjectIcon(
                                      subject: cards[i].topic,
                                      size: 15,
                                      ink: cards[i].ink,
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: _question(
                                      cards[i],
                                      size,
                                      height: 1.17,
                                    ),
                                  ),
                                  if (host.isRead(cards[i])) ...[
                                    const SizedBox(width: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: ReadMark(pill: cards[i]),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A stretch of the line down the page, and the dot of its card on it,
/// ringed in the page's colour so the line stops short of it.
class _Spine extends CustomPainter {
  _Spine({
    required this.line,
    required this.dot,
    required this.ring,
    required this.at,
  });

  final Color line;
  final Color dot;
  final Color ring;

  /// The top of the dot.
  final double at;

  @override
  void paint(Canvas canvas, Size size) {
    final double x = size.width / 2;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = line
        ..strokeWidth = 1,
    );
    final Offset c = Offset(x, at + 5);
    canvas
      ..drawCircle(c, 9, Paint()..color = ring)
      ..drawCircle(c, 5, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(_Spine old) =>
      old.line != line || old.dot != dot || old.ring != ring || old.at != at;
}
