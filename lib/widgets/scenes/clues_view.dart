import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/scene.dart';
import '../../theme.dart';

/// Plays a [CluesScene]: evidence cards laid on the table one by one, and a
/// guess the reader may make whenever they dare.
///
/// From the top: a points counter in station-clock tiles beside a meter of
/// one segment per clue, which drains a segment each time a card is turned;
/// the table, where each new card lands on top of the last and the older
/// ones stay visible as edges, each with its number and short name (tap an
/// edge to bring that card back to the front); the suspects as chips; and
/// at the foot the face-down pile (tap it for the next clue) beside the
/// lock-in button.
///
/// Once locked, the rest of the pile is dealt, each wrong suspect is struck
/// through and stamped with the number of the clue that ruled it out, the
/// decisive clue turns over in solid ink, and the scene's `why` line says
/// why that one settled it. The verdict is carried by words, numbers and
/// marks, never by colour or motion alone, and the end state is the same
/// with animations off.
class CluesSceneView extends StatefulWidget {
  final CluesScene scene;
  final Color ink;
  final Color ground;
  const CluesSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<CluesSceneView> createState() => _CluesSceneViewState();
}

class _CluesSceneViewState extends State<CluesSceneView>
    with TickerProviderStateMixin {
  /// Cards turned face up during play.
  int _seen = 1;

  /// The card at the front of the table.
  int _focus = 0;
  int? _pick;

  /// Cards that had been seen when the reader locked in; null before.
  int? _lockedAt;

  /// The reader chose a card to read after locking in: the reveal stops
  /// pulling the decisive one to the front.
  bool _refocused = false;

  /// One card landing, and the meter draining a segment with it.
  late final AnimationController _lay = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  /// Deal the rest, strike the suspects, turn the decisive card: one clock,
  /// so it stays in step and a test can run it to the end.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  // On arrival the face-down pile lifts twice, so it is seen to be
  // something to tap. The first part of the controller is the wait; no
  // Timer, which would outlive a disposed widget and hang a test.
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );
  bool _started = false;

  CluesScene get _s => widget.scene;
  int get _n => _s.clues.length;
  bool get _locked => _lockedAt != null;
  bool get _still => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_still) {
      _lay.value = 1;
    } else {
      _lay.forward();
      _nudge.forward();
    }
  }

  /// A different card in the same place starts over.
  @override
  void didUpdateWidget(CluesSceneView old) {
    super.didUpdateWidget(old);
    if (old.scene.raw != widget.scene.raw) {
      _seen = 1;
      _focus = 0;
      _pick = null;
      _lockedAt = null;
      _refocused = false;
      _reveal.value = 0;
      _lay.value = 1;
    }
  }

  @override
  void dispose() {
    _lay.dispose();
    _reveal.dispose();
    _nudge.dispose();
    super.dispose();
  }

  // ---- moves ----

  void _draw() {
    if (_locked || _seen >= _n) return;
    HapticFeedback.selectionClick();
    _nudge.stop();
    setState(() {
      _seen++;
      _focus = _seen - 1;
    });
    if (_still) {
      _lay.value = 1;
    } else {
      _lay.forward(from: 0);
    }
  }

  void _choose(int option) {
    if (_locked) return;
    HapticFeedback.selectionClick();
    setState(() => _pick = _pick == option ? null : option);
  }

  void _bringForward(int card) {
    if (card == _frontCard) return;
    HapticFeedback.selectionClick();
    setState(() {
      _focus = card;
      if (_locked) _refocused = true;
    });
  }

  void _lock() {
    if (_locked || _pick == null) return;
    HapticFeedback.lightImpact();
    _nudge.stop();
    _lay.value = 1;
    setState(() => _lockedAt = _seen);
    if (_still) {
      _reveal.value = 1;
    } else {
      _reveal.forward();
    }
  }

  // ---- the reveal's clock ----

  double _span(double from, double length, [Curve curve = Curves.easeOut]) =>
      curve.transform(((_reveal.value - from) / length).clamp(0.0, 1.0));

  /// How far card [c] has landed, 0 (still in the pile) to 1.
  double _landed(int c) {
    final at = _lockedAt;
    if (at == null || c < at) {
      if (c > _seen - 1) return 0;
      return c == _seen - 1 ? Curves.easeOutCubic.transform(_lay.value) : 1;
    }
    return _span((c - at) * 0.09, 0.2, Curves.easeOutCubic);
  }

  /// When the reveal pulls the decisive card forward.
  static const _turnAt = 0.66;

  int get _frontCard {
    if (!_locked) return _focus;
    if (_refocused) return _focus;
    if (_reveal.value >= _turnAt) return _s.decisive;
    var last = 0;
    for (var c = 0; c < _n; c++) {
      if (_landed(c) > 0) last = c;
    }
    return last;
  }

  /// The decisive card turning over to solid ink.
  double get _turn => _span(_turnAt, 0.16, Curves.easeInOut);

  /// The `why` line arriving.
  double get _noteIn => _span(0.82, 0.18);

  /// Strike-through progress for each option: wrong ones in the order the
  /// clues ruled them out.
  double _strike(int option) {
    if (!_locked || option == _s.answer) return 0;
    final wrong = [
      for (var o = 0; o < _s.options.length; o++)
        if (o != _s.answer) o,
    ]..sort((a, b) => _s.outBy(a).compareTo(_s.outBy(b)));
    return _span(0.46 + wrong.indexOf(option) * 0.07, 0.16);
  }

  bool get _right => _pick == _s.answer;

  // ---- score ----

  /// Points on the counter and filled segments of the meter, as reals so
  /// both can drain smoothly.
  (double, double) get _score {
    final at = _lockedAt;
    if (at != null) {
      final kept = _s.pointsAfter(at).toDouble();
      final segs = (_n - at + 1).toDouble();
      if (_right) return (kept, segs);
      final d = _span(0.12, 0.4, Curves.easeInOut);
      return (kept * (1 - d), segs * (1 - d));
    }
    final now = _s.pointsAfter(_seen).toDouble();
    final segs = (_n - _seen + 1).toDouble();
    if (_seen == 1) return (now, segs);
    final g = Curves.easeInOut.transform(_lay.value);
    final before = _s.pointsAfter(_seen - 1).toDouble();
    return (before + (now - before) * g, segs + 1 - g);
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        final tight = h < 400;
        final rows = (_s.options.length + 1) ~/ 2;
        final headerH = tight ? 26.0 : 34.0;
        final chipH = tight ? 36.0 : 46.0;
        final chipGap = tight ? 6.0 : 8.0;
        final footerH = tight ? 50.0 : 54.0;
        final gap = tight ? 8.0 : 14.0;
        final chipsH = rows * chipH + (rows - 1) * chipGap;
        final tableH = math.max(0.0, h - headerH - chipsH - footerH - gap * 3);

        return GestureDetector(
          // A tap that misses a control is still a tap at the evidence, not
          // a request to turn the card over; once locked, the card is free.
          behavior: HitTestBehavior.opaque,
          onTap: _locked ? null : () {},
          child: AnimatedBuilder(
            animation: Listenable.merge([_lay, _reveal, _nudge]),
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: headerH, child: _header(headerH)),
                SizedBox(height: gap),
                SizedBox(
                  height: tableH,
                  width: box.maxWidth,
                  child: _table(box.maxWidth, tableH, tight),
                ),
                SizedBox(height: gap),
                SizedBox(height: chipsH, child: _chips(chipH, chipGap)),
                SizedBox(height: gap),
                SizedBox(
                  height: footerH,
                  child: _locked
                      ? Opacity(
                          opacity: _noteIn,
                          child: _CluesNote(
                            text: _s.why,
                            ink: ink,
                            size: tight ? 13 : 14,
                          ),
                        )
                      : _footer(l10n),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(double height) {
    final (points, segs) = _score;
    final shown = points.round();
    return Semantics(
      label: context.l10n.sceneNOfM(math.min(_seen, _n), _n),
      value: '$shown',
      child: ExcludeSemantics(
        child: Row(
          children: [
            _CluesTiles(
              value: shown,
              height: height,
              ink: widget.ink,
              ground: widget.ground,
            ),
            SizedBox(width: height * 0.4),
            Expanded(
              child: SizedBox(
                height: height * 0.36,
                child: CustomPaint(
                  painter: _CluesMeterPainter(
                    segments: _n,
                    filled: segs,
                    ink: widget.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _table(double width, double height, bool tight) {
    final ink = widget.ink;
    final ground = widget.ground;
    final reduce = _still;
    final rowH = tight ? 24.0 : 32.0;
    final front = _frontCard;

    final laid = [
      for (var c = 0; c < _n; c++)
        if (_landed(c) > 0) c,
    ];
    final behind = [...laid]..remove(front);

    // The edges of the cards behind take a fixed band each, so the front
    // card keeps one size for the whole game; on a short table they give
    // way first, down to a sliver.
    final minFront = math.max(56.0, height * 0.5);
    final edge = _n > 1
        ? ((height - minFront) / (_n - 1)).clamp(6.0, rowH)
        : 0.0;
    // The front card takes whatever the edges behind it leave, so the first
    // clue is set large and each new card makes room for one more edge.
    final frontH = math.max(0.0, height - edge * behind.length);
    final cardW = width - 8;

    final children = <Widget>[];
    for (final c in [...behind, front]) {
      final isFront = c == front;
      final top = isFront
          ? height - frontH
          : height - frontH - (behind.length - behind.indexOf(c)) * edge;
      final land = _landed(c);
      // Each card lies a few points off true, as a hand would leave it.
      const jitter = [0.0, 6.0, 2.0, 7.0, 4.0];
      final decisive = _locked && c == _s.decisive ? _turn : 0.0;
      final card = _CluesCard(
        number: c + 1,
        tag: _s.clues[c].tag,
        text: _s.clues[c].text,
        outs: _locked && _reveal.value >= 0.46
            ? _s.clues[c].rulesOut.length
            : 0,
        rowH: rowH,
        // A sliver too thin for its name shows only the card's edge.
        named: isFront || edge >= rowH * 0.8,
        turned: decisive,
        front: isFront,
        ink: ink,
        ground: ground,
      );
      final l10n = context.l10n;
      final label = l10n.sceneNOfM(c + 1, _n);
      children.add(
        AnimatedPositioned(
          key: ValueKey(c),
          duration: reduce ? Duration.zero : const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          left: jitter[c],
          width: cardW,
          top: top,
          height: frontH,
          child: Transform.translate(
            // Landing: in from the pile at the bottom left, turning flat.
            offset: Offset(
              -(1 - land) * width * 0.3,
              (1 - land) * (frontH * 0.8 + 60),
            ),
            child: Transform.rotate(
              angle: -(1 - land) * 0.14,
              child: Opacity(
                opacity: land.clamp(0.0, 1.0),
                child: isFront
                    ? Semantics(
                        liveRegion: true,
                        label: label,
                        value: _s.clues[c].text,
                        child: ExcludeSemantics(child: card),
                      )
                    : Semantics(
                        button: true,
                        label: '$label, ${_s.clues[c].tag}',
                        onTap: () => _bringForward(c),
                        child: ExcludeSemantics(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _bringForward(c),
                            child: card,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    }
    return Stack(clipBehavior: Clip.none, children: children);
  }

  Widget _chips(double chipH, double gap) {
    final l10n = context.l10n;
    final opts = _s.options;
    return LayoutBuilder(
      builder: (context, box) {
        final half = (box.maxWidth - gap) / 2;
        final chips = <Widget>[];
        for (var o = 0; o < opts.length; o++) {
          final full = o == opts.length - 1 && opts.length.isOdd;
          final strike = _strike(o);
          final truth = _locked && o == _s.answer ? _span(0.62, 0.2) : 0.0;
          final out = _s.outBy(o);
          final chip = _CluesChip(
            label: opts[o],
            picked: _pick == o,
            locked: _locked,
            strike: strike,
            truth: truth,
            outBy: out >= 0 ? out + 1 : null,
            you: _locked ? l10n.sceneYou : null,
            height: chipH,
            ink: widget.ink,
            ground: widget.ground,
          );
          String value;
          if (!_locked) {
            value = '';
          } else if (o == _s.answer) {
            value = l10n.sceneTruth;
          } else {
            value = '✕ ${l10n.sceneNOfM(out + 1, _n)}';
          }
          chips.add(
            SizedBox(
              width: full ? box.maxWidth : half,
              height: chipH,
              child: Semantics(
                button: !_locked,
                selected: _pick == o,
                label: opts[o],
                value: value.isEmpty ? null : value,
                onTap: _locked ? null : () => _choose(o),
                child: ExcludeSemantics(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _locked ? null : () => _choose(o),
                    child: chip,
                  ),
                ),
              ),
            ),
          );
        }
        return Wrap(spacing: gap, runSpacing: gap, children: chips);
      },
    );
  }

  Widget _footer(AppLocalizations l10n) {
    final ink = widget.ink;
    final ground = widget.ground;
    final left = _n - _seen;
    // The pile lifts at 30% and 65% of the nudge: two small breaths.
    double lift(double at) =>
        math.sin(((_nudge.value - at) / 0.18).clamp(0.0, 1.0) * math.pi);
    final breath = (lift(0.3) + lift(0.65)) * 5;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Semantics(
            button: left > 0,
            enabled: left > 0,
            label: l10n.sceneNOfM(math.min(_seen + 1, _n), _n),
            onTap: left > 0 ? _draw : null,
            child: ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _draw,
                child: CustomPaint(
                  painter: _CluesPilePainter(
                    left: left,
                    lift: breath,
                    ink: ink,
                    ground: ground,
                  ),
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(0, -breath),
                      child: Text(
                        left > 0
                            ? l10n.sceneNOfM(_seen + 1, _n).toUpperCase()
                            : l10n.sceneNOfM(_n, _n).toUpperCase(),
                        maxLines: 1,
                        style: AppText.label(
                          size: 12,
                          weight: FontWeight.w800,
                          spacing: 1.4,
                          color: left > 0 ? ground : ink.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: _pick == null
              ? DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: ink.withValues(alpha: 0.28),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      l10n.sceneTapToPick,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 13.5,
                        weight: FontWeight.w600,
                        color: ink.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                )
              : _CluesLockButton(
                  label: l10n.sceneLockIn,
                  ink: ink,
                  ground: ground,
                  onTap: _lock,
                ),
        ),
      ],
    );
  }
}

/// The counter, in three tiles like a station clock, leading zeros dimmed.
class _CluesTiles extends StatelessWidget {
  final int value;
  final double height;
  final Color ink;
  final Color ground;
  const _CluesTiles({
    required this.value,
    required this.height,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) {
    final digits = value.clamp(0, 999).toString().padLeft(3, '0');
    final lead = value <= 0 ? 2 : 3 - value.toString().length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) SizedBox(width: height * 0.1),
          Container(
            width: height * 0.74,
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: i < lead ? ink.withValues(alpha: 0.22) : ink,
              borderRadius: BorderRadius.circular(height * 0.18),
            ),
            child: Text(
              digits[i],
              style: AppText.display(
                size: height * 0.72,
                weight: FontWeight.w800,
                height: 1,
                color: ground,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ],
      ],
    );
  }
}

/// One segment per clue: what a right answer is still worth.
class _CluesMeterPainter extends CustomPainter {
  final int segments;
  final double filled;
  final Color ink;
  _CluesMeterPainter({
    required this.segments,
    required this.filled,
    required this.ink,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 4.0;
    final w = (size.width - gap * (segments - 1)) / segments;
    final r = Radius.circular(size.height / 2);
    final empty = Paint()..color = ink.withValues(alpha: 0.16);
    final full = Paint()..color = ink;
    for (var i = 0; i < segments; i++) {
      final x = i * (w + gap);
      canvas.drawRRect(RRect.fromLTRBR(x, 0, x + w, size.height, r), empty);
      final f = (filled - i).clamp(0.0, 1.0);
      if (f > 0) {
        canvas.drawRRect(
          RRect.fromLTRBR(x, 0, x + w * f, size.height, r),
          full,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CluesMeterPainter old) =>
      old.filled != filled || old.segments != segments || old.ink != ink;
}

/// One evidence card: its number and short name along the top edge, which
/// is all that shows once another card lies over it, and the clue itself
/// set as large as the card allows.
class _CluesCard extends StatelessWidget {
  final int number;
  final String tag;
  final String text;

  /// Options this card ruled out, marked once the reveal has struck them.
  final int outs;
  final double rowH;
  final bool named;

  /// 0 → 1: the decisive card turning to solid ink.
  final double turned;
  final bool front;
  final Color ink;
  final Color ground;
  const _CluesCard({
    required this.number,
    required this.tag,
    required this.text,
    required this.outs,
    required this.rowH,
    required this.named,
    required this.turned,
    required this.front,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) {
    final paper = Color.lerp(Color.lerp(ground, ink, 0.05)!, ink, turned)!;
    final face = Color.lerp(ink, ground, turned)!;
    const pad = 14.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ink, width: 1.6),
        // A hard shadow, as of a card lying on a table under one lamp.
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: front ? 0.85 : 0.5),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.4),
        child: LayoutBuilder(
          builder: (context, box) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: math.min(rowH, box.maxHeight),
                child: !named
                    ? null
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: pad),
                        child: Row(
                          children: [
                            Text(
                              '$number',
                              style: AppText.display(
                                size: rowH * 0.6,
                                weight: FontWeight.w800,
                                height: 1,
                                color: face,
                              ),
                            ),
                            SizedBox(width: rowH * 0.32),
                            Expanded(
                              child: Text(
                                tag,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body(
                                  size: rowH * 0.44,
                                  weight: FontWeight.w700,
                                  height: 1,
                                  color: face.withValues(alpha: 0.72),
                                ),
                              ),
                            ),
                            for (var i = 0; i < outs; i++)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: SizedBox.square(
                                  dimension: rowH * 0.36,
                                  child: CustomPaint(
                                    painter: _CluesCrossPainter(face, 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
              if (box.maxHeight > rowH + 20)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(pad, 0, pad, 12),
                    child: _CluesFit(
                      text: text,
                      min: 11.5,
                      max: 36,
                      style: (s) => AppText.display(
                        size: s,
                        weight: FontWeight.w600,
                        height: 1.18,
                        spacing: -0.1 - s * 0.01,
                        color: face,
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

/// Text set at the largest size between [min] and [max] that fits its box;
/// below [min] it keeps [min] and ends in an ellipsis rather than spill.
class _CluesFit extends StatelessWidget {
  final String text;
  final double min;
  final double max;
  final TextStyle Function(double) style;
  const _CluesFit({
    required this.text,
    required this.min,
    required this.max,
    required this.style,
  });

  bool _fits(double s, double w, double h) {
    final st = style(s);
    for (final word in text.split(' ')) {
      final p = TextPainter(
        text: TextSpan(text: word, style: st),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (p.width > w) return false;
    }
    final p = TextPainter(
      text: TextSpan(text: text, style: st),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w);
    return p.height <= h;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      var size = min;
      if (w.isFinite && h.isFinite && w > 0 && h > 0) {
        if (_fits(max, w, h)) {
          size = max;
        } else {
          var lo = min, hi = max;
          while (hi - lo > 0.5) {
            final mid = (lo + hi) / 2;
            if (_fits(mid, w, h)) {
              lo = mid;
            } else {
              hi = mid;
            }
          }
          size = lo;
        }
      }
      final st = style(size);
      final lineH = (st.fontSize ?? size) * (st.height ?? 1.2);
      final lines = math.max(1, (h / lineH).floor());
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          text,
          maxLines: lines,
          overflow: TextOverflow.ellipsis,
          style: st,
        ),
      );
    },
  );
}

/// A suspect. Before the lock: outlined, solid when picked. After: the
/// answer solid with a tick, every other struck through, faded, and stamped
/// with the number of the clue that ruled it out; the reader's own pick
/// carries a "you" tab on its top edge.
class _CluesChip extends StatelessWidget {
  final String label;
  final bool picked;
  final bool locked;
  final double strike;
  final double truth;
  final int? outBy;
  final String? you;
  final double height;
  final Color ink;
  final Color ground;
  const _CluesChip({
    required this.label,
    required this.picked,
    required this.locked,
    required this.strike,
    required this.truth,
    required this.outBy,
    required this.you,
    required this.height,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) {
    // Before the lock, the pick is solid. After, solidity belongs to the
    // truth alone; the pick keeps a heavy outline and its tab.
    final solid = locked ? truth : (picked ? 1.0 : 0.0);
    final fill = Color.lerp(ink.withValues(alpha: 0.0), ink, solid)!;
    final face = Color.lerp(ink, ground, solid)!;
    final fade = 1 - strike * 0.6;
    final r = BorderRadius.circular(height * 0.32);
    final font = (height * 0.4).clamp(14.0, 18.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: fade,
            child: Container(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: r,
                border: Border.all(
                  color: ink.withValues(alpha: picked ? 1 : 0.5),
                  width: picked && locked ? 3 : 1.6,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: height * 0.32),
              child: Row(
                children: [
                  Flexible(
                    child: CustomPaint(
                      foregroundPainter: strike > 0
                          ? _CluesStrikePainter(strike, face)
                          : null,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.display(
                          size: font,
                          weight: FontWeight.w700,
                          height: 1.1,
                          spacing: -0.2,
                          color: face,
                        ),
                      ),
                    ),
                  ),
                  if (truth > 0) ...[
                    const SizedBox(width: 8),
                    Opacity(
                      opacity: truth,
                      child: SizedBox.square(
                        dimension: font * 0.9,
                        child: CustomPaint(painter: _CluesTickPainter(face)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // The stamp: which clue struck this one off.
        if (outBy != null && strike > 0)
          Positioned(
            right: -5,
            top: -7,
            child: Opacity(
              opacity: strike,
              child: Transform.scale(
                scale: 1.4 - 0.4 * strike,
                child: _CluesStamp(
                  number: outBy!,
                  size: (height * 0.5).clamp(20.0, 24.0),
                  ink: ink,
                  ground: ground,
                ),
              ),
            ),
          ),
        if (locked && picked && you != null)
          Positioned(
            left: height * 0.3,
            top: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: truth > 0.5 ? ground : ink,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ink, width: 1.4),
              ),
              child: Text(
                you!,
                style: AppText.label(
                  size: 9.5,
                  weight: FontWeight.w800,
                  height: 1.1,
                  color: truth > 0.5 ? ink : ground,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A round ink stamp: a cross and the clue's number.
class _CluesStamp extends StatelessWidget {
  final int number;
  final double size;
  final Color ink;
  final Color ground;
  const _CluesStamp({
    required this.number,
    required this.size,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: size,
    padding: EdgeInsets.symmetric(horizontal: size * 0.26),
    decoration: BoxDecoration(
      color: ink,
      borderRadius: BorderRadius.circular(size / 2),
      border: Border.all(color: ground, width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: size * 0.34,
          child: CustomPaint(painter: _CluesCrossPainter(ground, 1.8)),
        ),
        SizedBox(width: size * 0.16),
        Text(
          '$number',
          style: AppText.display(
            size: size * 0.6,
            weight: FontWeight.w800,
            height: 1,
            color: ground,
          ),
        ),
      ],
    ),
  );
}

class _CluesCrossPainter extends CustomPainter {
  final Color color;
  final double width;
  _CluesCrossPainter(this.color, this.width);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), p);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), p);
  }

  @override
  bool shouldRepaint(_CluesCrossPainter old) =>
      old.color != color || old.width != width;
}

class _CluesTickPainter extends CustomPainter {
  final Color color;
  _CluesTickPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.08, h * 0.55)
        ..lineTo(w * 0.38, h * 0.84)
        ..lineTo(w * 0.94, h * 0.18),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CluesTickPainter old) => old.color != color;
}

/// A line drawn through a struck-off name, left to right.
class _CluesStrikePainter extends CustomPainter {
  final double t;
  final Color color;
  _CluesStrikePainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.56;
    canvas.drawLine(
      Offset(-2, y),
      Offset(-2 + (size.width + 4) * t, y),
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CluesStrikePainter old) =>
      old.t != t || old.color != color;
}

/// The face-down pile: one card back per clue still to come, stacked a
/// little offset, hatched like the back of a playing card. Empty, it is a
/// dashed outline.
class _CluesPilePainter extends CustomPainter {
  final int left;
  final double lift;
  final Color ink;
  final Color ground;
  _CluesPilePainter({
    required this.left,
    required this.lift,
    required this.ink,
    required this.ground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height * 0.28);
    const step = 3.0;
    final depth = math.min(left, 4);
    final base = Rect.fromLTWH(
      0,
      depth > 1 ? step * (depth - 1) / 2 : 0,
      size.width - step * math.max(0, depth - 1),
      size.height - step * math.max(0, depth - 1),
    );
    if (left == 0) {
      final paint = Paint()
        ..color = ink.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      final path = Path()
        ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, r));
      for (final m in path.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 9) {
          canvas.drawPath(m.extractPath(d, d + 4.5), paint);
        }
      }
      return;
    }
    // From the bottom card up; the top one breathes with the nudge.
    for (var i = depth - 1; i >= 0; i--) {
      final dy = i == 0 ? -lift : 0.0;
      final rect = base.shift(Offset(step * i, -step * i / 2 + dy));
      final rr = RRect.fromRectAndRadius(rect, r);
      canvas.drawRRect(rr, Paint()..color = ink);
      canvas.drawRRect(
        rr.deflate(0.8),
        Paint()
          ..color = ground.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      if (i == 0) {
        canvas.save();
        canvas.clipRRect(rr.deflate(4));
        final hatch = Paint()
          ..color = ground.withValues(alpha: 0.13)
          ..strokeWidth = 1.2;
        for (var x = rect.left - rect.height; x < rect.right; x += 7) {
          canvas.drawLine(
            Offset(x, rect.bottom),
            Offset(x + rect.height, rect.top),
            hatch,
          );
        }
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_CluesPilePainter old) =>
      old.left != left ||
      old.lift != lift ||
      old.ink != ink ||
      old.ground != ground;
}

class _CluesLockButton extends StatelessWidget {
  final String label;
  final Color ink;
  final Color ground;
  final VoidCallback onTap;
  const _CluesLockButton({
    required this.label,
    required this.ink,
    required this.ground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    onTap: onTap,
    child: ExcludeSemantics(
      child: Material(
        color: ink,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: ground.withValues(alpha: 0.2),
          highlightColor: ground.withValues(alpha: 0.1),
          child: SizedBox.expand(
            child: Center(
              child: Text(
                label,
                style: AppText.label(
                  size: 13,
                  weight: FontWeight.w800,
                  spacing: 1.6,
                  color: ground,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CluesNote extends StatelessWidget {
  final String text;
  final Color ink;
  final double size;
  const _CluesNote({required this.text, required this.ink, required this.size});

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Align(
      alignment: Alignment.topLeft,
      child: Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: AppText.body(
          size: size,
          weight: FontWeight.w600,
          height: 1.25,
          color: ink.withValues(alpha: 0.92),
        ),
      ),
    ),
  );
}
