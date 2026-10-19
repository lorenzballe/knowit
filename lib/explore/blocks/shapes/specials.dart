/// The sideways shapes whose tile is more than a face with words on it: the
/// stamp and the postcard of a place, the ticket and the band of something
/// to try today, the card with its twin behind it, and the debate split in
/// two halves whose foot takes a side (131b, 131d, 132a, 132b).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/explore_mix.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/explore/parts.dart';
import '../../explore_block.dart';
import 'deal.dart';
import 'look.dart';
import 'outlines.dart';
import 'places.dart';
import 'shelf.dart';
import 'signatures.dart';
import 'tile.dart';
import 'vocabulary.dart';

/// A sideways row of [deal]'s cards, each built by [tile], at the margins
/// every shelf keeps: what every shape below lays its tiles out with.
Widget _row(
  ExploreHost host,
  ShapeDeal deal, {
  required double height,
  required double width,
  required Widget Function(Pill p) tile,
  double gap = 10,
}) {
  final List<Pill> cards = deal.cards;
  return SideRow(
    height: height,
    gap: gap,
    count: cards.length,
    itemBuilder: (context, i) {
      final Pill p = cards[i];
      host.seen(deal.section, p);
      return CardTap(
        pill: p,
        onTap: () => host.open(deal.section, cards, p),
        child: SizedBox(width: width, child: tile(p)),
      );
    },
  );
}

/// A country's code, set in the app's voice, never larger than the reader's
/// text setting would make a mark of the design: it is drawn, not read, and
/// the question says where the card is set in words.
Widget _code(String code, Color colour, double size) => ExcludeSemantics(
  child: Text(
    code,
    maxLines: 1,
    textScaler: TextScaler.noScaling,
    style: AppText.display(
      size: size,
      weight: FontWeight.w600,
      height: 0.9,
      spacing: -0.02 * size,
      color: colour,
    ),
  ),
);

// ── The stamp (131d, 132a, 132b) ─────────────────────────────────────────

/// A stamp at one size.
@immutable
class _StampSize {
  const _StampSize(this.width, this.height, this.inset, this.min, this.max);

  final double width;
  final double height;

  /// Inside the frame.
  final double inset;
  final double min;
  final double max;
}

/// A place, on postage stamps: perforated, framed, the country's code in
/// the corner where it is known, and with the postmark signature its code
/// set large and the stamp franked (132a). With `"style": {"tilt": true}`
/// the stamps lie as they were stuck on, each at its own angle (132b).
class StampBlock extends ShapeBlock {
  const StampBlock();

  @override
  String get name => 'shape-stamp';

  @override
  ShapeVocabulary get words => const ShapeVocabulary(
    canvas: ['131d', '131f', '132a', '132b'],
    kind: 'place',
    signatures: ['postmark', 'none'],
    fields: ['codes'],
    style: {'tilt': ShapeStyleKey.flag()},
  );

  static const Map<String, _StampSize> _sizes = {
    's': _StampSize(160, 196, 12, 10.5, 14.5),
    'm': _StampSize(176, 216, 14, 11, 15),
    'l': _StampSize(196, 240, 15, 11.5, 16.5),
  };

  Map<String, Object?> _codes(ExploreSection section) =>
      section.get<Map<String, Object?>>('codes') ?? const {};

  @override
  bool Function(Pill)? first(ExploreSection section) {
    final Map<String, Object?> codes = _codes(section);
    return (p) => stampCountry(p, codes) != null;
  }

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) {
    final ExploreSection section = deal.section;
    final _StampSize size = _sizes[sizeOf(section)]!;
    final bool franked = signatureOf(section) == 'postmark';
    final bool tilt = section.style['tilt'] == true;
    final Map<String, Object?> codes = _codes(section);
    final double k = size.width / 176;
    Widget stamp(Pill p) {
      final String? code = stampCountry(p, codes);
      final Widget face = OutlinedFace(
        outline: const StampOutline(),
        colour: p.color,
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(franked ? 2 : 3),
            border: Border.all(color: hairOn(p)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(franked ? 2 : 3),
            child: CustomPaint(
              painter: franked
                  ? _ArtPainter(
                      PostmarkArt(colour: tone(p, Tones.over), scale: k),
                    )
                  : null,
              child: Padding(
                padding: EdgeInsets.all(size.inset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ShapeHead(
                      pill: p,
                      read: host.isRead(p),
                      tickBeside: true,
                      trailing: code == null
                          ? null
                          : _code(code, p.ink, franked ? 30 * k : 13 * k),
                    ),
                    SizedBox(height: franked ? 8 : 10),
                    Expanded(
                      child: CardQuestion(
                        text: p.question,
                        color: p.ink,
                        min: size.min,
                        max: size.max,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      return face;
    }

    if (!tilt) {
      return _row(
        host,
        deal,
        height: size.height,
        width: size.width,
        tile: stamp,
      );
    }
    // Stuck on by hand: each at its own small angle, the first leaning
    // back, the next forward, and lifted off the page by its shadow.
    const List<double> angles = [-3, 2.5, -1.5, 3, -2.5, 1.5];
    final List<Pill> cards = deal.cards;
    final bool night = context.p.isDark;
    return SizedBox(
      height: size.height + 24,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 14),
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final Pill p = cards[i];
          host.seen(section, p);
          return CardTap(
            pill: p,
            onTap: () => host.open(section, cards, p),
            child: Transform.rotate(
              angle: angles[i % angles.length] * math.pi / 180,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: night ? 0.55 : 0.16,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 10),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: stamp(p),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A face art painted on its own, inside a box that is not a tile.
class _ArtPainter extends CustomPainter {
  _ArtPainter(this.art);

  final FaceArt art;

  @override
  void paint(Canvas canvas, Size size) => art.paint(canvas, size);

  @override
  bool shouldRepaint(_ArtPainter old) => old.art != art;
}

// ── The postcard (131b) ──────────────────────────────────────────────────

/// A place, on a postcard: its subject in the corner, a stamp with the
/// country's code where it is known, the postmark's waves beside it, and the
/// question written along the foot.
class PostcardBlock extends ShapeBlock {
  const PostcardBlock();

  @override
  String get name => 'shape-postcard';

  @override
  ShapeVocabulary get words =>
      const ShapeVocabulary(canvas: ['131b'], kind: 'place', fields: ['codes']);

  static const Map<String, (double, double, double, double)> _sizes = {
    's': (246, 152, 10.5, 14.5),
    'm': (276, 170, 11, 16.5),
    'l': (312, 192, 12, 18.5),
  };

  Map<String, Object?> _codes(ExploreSection section) =>
      section.get<Map<String, Object?>>('codes') ?? const {};

  @override
  bool Function(Pill)? first(ExploreSection section) {
    final Map<String, Object?> codes = _codes(section);
    return (p) => stampCountry(p, codes) != null;
  }

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) {
    final (double w, double h, double min, double max) =
        _sizes[sizeOf(deal.section)]!;
    final double k = w / 276;
    final Map<String, Object?> codes = _codes(deal.section);
    return _row(
      host,
      deal,
      height: h,
      width: w,
      tile: (p) {
        final String? code = stampCountry(p, codes);
        return OutlinedFace(
          outline: const RoundOutline(19),
          colour: p.color,
          art: [
            WavesArt(colour: hairOn(p), at: Offset(58 * k, 22 * k), scale: k),
          ],
          padding: EdgeInsets.all(16 * k),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    // Clear of the stamp and its postmark.
                    padding: EdgeInsets.only(right: 80 * k),
                    child: ShapeHead(
                      pill: p,
                      named: true,
                      read: host.isRead(p),
                    ),
                  ),
                  SizedBox(height: 24 * k),
                  Expanded(
                    child: CardQuestion(
                      text: p.question,
                      color: p.ink,
                      min: min,
                      max: max,
                      height: 1.16,
                      alignment: Alignment.bottomLeft,
                    ),
                  ),
                ],
              ),
              Positioned(
                right: -2 * k,
                top: -4 * k,
                child: _MiniStamp(pill: p, code: code, scale: k),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The stamp in a postcard's corner: its fill a tone down, its edge
/// perforated in the card's own colour, framed, the code in its middle.
class _MiniStamp extends StatelessWidget {
  const _MiniStamp({required this.pill, required this.code, this.scale = 1});

  final Pill pill;
  final String? code;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final String? c = code;
    return SizedBox(
      width: 36 * scale,
      height: 44 * scale,
      child: CustomPaint(
        painter: _MiniStampPainter(
          fill: tone(pill, Tones.half),
          edge: pill.color,
          frame: hairOn(pill),
          scale: scale,
        ),
        child: c == null ? null : Center(child: _code(c, pill.ink, 13 * scale)),
      ),
    );
  }
}

class _MiniStampPainter extends CustomPainter {
  _MiniStampPainter({
    required this.fill,
    required this.edge,
    required this.frame,
    required this.scale,
  });

  final Color fill;
  final Color edge;
  final Color frame;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final double k = scale;
    final Rect body = Rect.fromLTWH(3 * k, 1 * k, 30 * k, 42 * k);
    canvas.drawRect(body, Paint()..color = fill);
    // The perforation: dots of the card's colour every six points round the
    // edge, which is what a dotted round-capped border draws.
    final Paint dot = Paint()..color = edge;
    final double pitch = 6 * k;
    final double r = 2 * k;
    for (double x = body.left; x <= body.right + 0.01; x += pitch) {
      canvas
        ..drawCircle(Offset(x, body.top), r, dot)
        ..drawCircle(Offset(x, body.bottom), r, dot);
    }
    for (double y = body.top + pitch; y < body.bottom - 0.01; y += pitch) {
      canvas
        ..drawCircle(Offset(body.left, y), r, dot)
        ..drawCircle(Offset(body.right, y), r, dot);
    }
    canvas.drawRect(
      Rect.fromLTWH(7.5 * k, 5.5 * k, 21 * k, 33 * k),
      Paint()
        ..color = frame
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_MiniStampPainter old) =>
      old.fill != fill ||
      old.edge != edge ||
      old.frame != frame ||
      old.scale != scale;
}

// ── The ticket (131d) ────────────────────────────────────────────────────

/// Something to try today, as a ticket: the question above the line it
/// tears along, and on the stub the subject and how long it takes.
class TicketBlock extends ShapeBlock {
  const TicketBlock();

  @override
  String get name => 'shape-ticket';

  @override
  ShapeVocabulary get words =>
      const ShapeVocabulary(canvas: ['131d'], kind: 'practical');

  static const Map<String, (double, double, double, double, double)> _sizes = {
    's': (232, 152, 108, 10, 12.5),
    'm': (262, 170, 122, 10.5, 14),
    'l': (296, 192, 138, 11.5, 16),
  };

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) {
    final (double w, double h, double at, double min, double max) =
        _sizes[sizeOf(deal.section)]!;
    final double k = w / 262;
    final l = context.l10n;
    return _row(
      host,
      deal,
      height: h,
      width: w,
      tile: (p) => OutlinedFace(
        outline: TicketOutline(radius: 19, notch: 10 * k, at: at),
        colour: p.color,
        art: [_Tear(colour: hairOn(p), at: at - 1, inset: 18 * k)],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: at,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16 * k, 14 * k, 16 * k, 12 * k),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ShapeHead(pill: p, read: host.isRead(p)),
                    SizedBox(height: 8 * k),
                    Expanded(
                      child: CardQuestion(
                        text: p.question,
                        color: p.ink,
                        min: min,
                        max: max,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * k),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        subjectLabel(context, p),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tileLabel(subOn(p)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${upper(context, l.todayLabel)} · '
                      '${upper(context, l.minutesShort(minutesFor(p)))}',
                      maxLines: 1,
                      style: tileLabel(p.ink),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The line a ticket tears along: dashes across, short of the notches.
class _Tear extends FaceArt {
  const _Tear({required this.colour, required this.at, required this.inset});

  final Color colour;
  final double at;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = colour
      ..strokeWidth = 1.5;
    for (double x = inset; x < size.width - inset; x += 7) {
      canvas.drawLine(
        Offset(x, at),
        Offset(math.min(x + 4, size.width - inset), at),
        p,
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _Tear &&
      other.colour == colour &&
      other.at == at &&
      other.inset == inset;

  @override
  int get hashCode => Object.hash(_Tear, colour, at, inset);
}

// ── Try today (131b) ─────────────────────────────────────────────────────

/// Something to try before tonight, with a band at its foot: a box, TRY
/// TODAY, and how long it takes. The box is the card's read mark, ticked
/// once the card has been read, and does nothing else: the rings that once
/// ticked a row off as tried were taken away because nobody could tell what
/// they were for, and a box beside its own words, filled when the card is,
/// says what it is.
class TryBlock extends ShapeBlock {
  const TryBlock();

  @override
  String get name => 'shape-try';

  @override
  ShapeVocabulary get words =>
      const ShapeVocabulary(canvas: ['131b'], kind: 'practical');

  static const Map<String, (double, double, double, double, double)> _sizes = {
    's': (180, 174, 36, 10, 13.5),
    'm': (204, 196, 40, 10.5, 15),
    'l': (232, 222, 44, 11.5, 17),
  };

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) {
    final (double w, double h, double band, double min, double max) =
        _sizes[sizeOf(deal.section)]!;
    final l = context.l10n;
    return _row(
      host,
      deal,
      height: h,
      width: w,
      tile: (p) {
        final bool read = host.isRead(p);
        final bool dark = p.ink.computeLuminance() < 0.5;
        return OutlinedFace(
          outline: const RoundOutline(19),
          colour: p.color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ShapeHead(pill: p),
                      const SizedBox(height: 10),
                      Expanded(
                        child: CardQuestion(
                          text: p.question,
                          color: p.ink,
                          min: min,
                          max: max,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: band,
                color: tone(p, Tones.half),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Semantics(
                      label: read ? l.readMark : null,
                      child: Container(
                        key: ValueKey('shape-try-box-${p.id}'),
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: read ? p.ink : null,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: read
                                ? p.ink
                                : p.ink.withValues(alpha: dark ? 0.5 : 0.7),
                            width: 2,
                          ),
                        ),
                        child: read
                            ? Icon(
                                Icons.check_rounded,
                                size: 11,
                                color: p.color,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        upper(context, l.tryToday),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tileLabel(p.ink),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      upper(context, l.minutesShort(minutesFor(p))),
                      maxLines: 1,
                      style: tileLabel(subOn(p)),
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

// ── Twins (131b, 131f) ───────────────────────────────────────────────────

/// A paradox, with a twin card behind it, tipped: two true things, one
/// standing on the other.
class TwinsBlock extends ShapeBlock {
  const TwinsBlock();

  @override
  String get name => 'shape-twins';

  @override
  ShapeVocabulary get words =>
      const ShapeVocabulary(canvas: ['131b', '131f'], kind: 'paradoxes');

  static const Map<String, (double, double, double, double, double)> _sizes = {
    's': (152, 172, 11, 10, 14.5),
    'm': (172, 196, 12, 10.5, 16),
    'l': (196, 222, 13, 11, 18),
  };

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) {
    final (double w, double h, double off, double min, double max) =
        _sizes[sizeOf(deal.section)]!;
    return _row(
      host,
      deal,
      height: h + off,
      width: w + off + 2,
      gap: 6,
      tile: (p) => Stack(
        clipBehavior: Clip.none,
        children: [
          // The twin: the same card, behind, tipped from its foot.
          Positioned(
            left: off,
            top: 2,
            width: w,
            height: h,
            child: Transform.rotate(
              angle: 5 * math.pi / 180,
              alignment: Alignment.bottomCenter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tone(p, Tones.behind),
                  borderRadius: BorderRadius.circular(19),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: off,
            width: w,
            height: h,
            child: ShapeTile(
              pill: p,
              read: host.isRead(p),
              look: TileLook(
                outline: const RoundOutline(19),
                min: min,
                max: max,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Two sides (131b, 131f) ───────────────────────────────────────────────

/// A debate, the card in two halves, a side at the foot of each: a tap on
/// one takes it, the answer the card itself records for that side. The rest
/// of the card opens it.
class SidesBlock extends ShapeBlock {
  const SidesBlock();

  @override
  String get name => 'shape-sides';

  @override
  ShapeVocabulary get words => const ShapeVocabulary(
    canvas: ['131b', '131f'],
    kind: 'debates',
    signatures: ['halves'],
  );

  static const Map<String, (double, double, double, double, double)> _sizes = {
    's': (266, 170, 40, 11.5, 17),
    'm': (300, 190, 44, 12, 19),
    'l': (340, 214, 48, 13, 21.5),
  };

  @override
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal) {
    final (double w, double h, double foot, double min, double max) =
        _sizes[sizeOf(deal.section)]!;
    return _row(
      host,
      deal,
      height: h,
      width: w,
      tile: (p) => _SidesCard(
        pill: p,
        read: host.isRead(p),
        given: sideTaken(p, host.app.answerFor(p.id)),
        foot: foot,
        min: min,
        max: max,
        onSide: (side) => host.commit(p, '$side'),
      ),
    );
  }
}

class _SidesCard extends StatefulWidget {
  const _SidesCard({
    required this.pill,
    required this.read,
    required this.given,
    required this.foot,
    required this.min,
    required this.max,
    required this.onSide,
  });

  final Pill pill;
  final bool read;

  /// The side the reader took before, if any.
  final int? given;
  final double foot;
  final double min;
  final double max;
  final ValueChanged<int> onSide;

  @override
  State<_SidesCard> createState() => _SidesCardState();
}

class _SidesCardState extends State<_SidesCard> {
  /// A side taken here, until the reader's answers say so.
  int? _said;

  @override
  Widget build(BuildContext context) {
    final Pill p = widget.pill;
    final List<String> sides = sidesOf(p);
    final int? taken = widget.given ?? _said;
    Widget side(int i) {
      final bool mine = taken == i;
      final String label = upper(context, sideLabel(sides[i]));
      return Expanded(
        child: Semantics(
          button: taken == null,
          selected: mine,
          label: sides[i],
          excludeSemantics: true,
          child: GestureDetector(
            key: ValueKey('shape-side-${p.id}-$i'),
            behavior: HitTestBehavior.opaque,
            onTap: taken != null
                ? null
                : () {
                    setState(() => _said = i);
                    widget.onSide(i);
                  },
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: taken != null && !mine ? 0.42 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: mine ? p.ink : p.ink.withValues(alpha: 0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: tileLabel(
                      mine ? p.color : p.ink,
                      size: 10,
                      spacing: 1.6,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return OutlinedFace(
      outline: const RoundOutline(22),
      colour: p.color,
      art: [SplitArt.halves(tone(p, Tones.half))],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 17, 17, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShapeHead(pill: p, named: true, read: widget.read),
                  const SizedBox(height: 10),
                  Expanded(
                    child: CardQuestion(
                      text: p.question,
                      color: p.ink,
                      min: widget.min,
                      max: widget.max,
                      height: 1.14,
                      tracking: -0.032,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: widget.foot,
            child: sides.length >= 2
                ? Row(children: [side(0), side(1)])
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
