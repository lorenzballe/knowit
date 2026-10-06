import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/scene.dart';
import '../../theme.dart';

/// Plays a [MatchScene]: draw a line from each idea to what it explains,
/// lock it in, and watch the tangle untie itself into a ladder.
///
/// Before: the ideas in a column on the left, set in the serif; what they
/// explain in a shuffled column on the right. A line is drawn by dragging
/// from either side to the other (the line follows the finger and snaps to
/// the item it would land on), or by tapping one item and then its partner.
/// Every item can hold one line; drawing a new one to it lets the old one
/// go. Tapping a linked item takes its line back off.
///
/// After: the wrong lines retract, the right column slides until every item
/// sits beside its true partner, and the missing lines draw themselves in,
/// straight. Each rung carries a tick or a cross for what the reader had,
/// the pair most people miss opens turned over with its note underneath,
/// and tapping any other rung shows its note instead.
///
/// The board claims every drag inside it until the answer is locked, so a
/// line drawn sideways never swipes the deck; once locked it lets go of
/// drags again, and only the rungs themselves still answer a tap.
class MatchSceneView extends StatefulWidget {
  final MatchScene scene;
  final Color ink;
  final Color ground;
  const MatchSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<MatchSceneView> createState() => _MatchSceneViewState();
}

/// One end of a line: an item on the left or right, by its pair index.
typedef _MatchEnd = ({bool left, int i});

class _MatchSceneViewState extends State<MatchSceneView>
    with TickerProviderStateMixin {
  /// Left item → the right item the reader joined it to (pair indices).
  Map<int, int> _links = {};

  /// The item tapped first, waiting for its partner.
  _MatchEnd? _picked;

  // A line being dragged: where it starts, where the finger is, and the
  // item it would land on if let go now.
  _MatchEnd? _from;
  Offset _finger = Offset.zero;
  _MatchEnd? _hover;

  /// The left item whose line was drawn last; it grows on [_grow].
  int? _fresh;

  /// Lines just let go of, as (left, right); they retract on [_fade].
  List<(int, int)> _gone = const [];

  // A drag let go over nothing: its line springs back on [_snap].
  _MatchEnd? _snapFrom;
  Offset _snapTip = Offset.zero;

  // Fixed at lock-in.
  Map<int, int>? _guess;
  int _focus = 0;

  bool _touched = false;
  bool _started = false;

  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    value: 1,
  );
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );
  late final AnimationController _snap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );

  /// The untangling, all on one clock so its steps stay in order and a
  /// widget test can run it to the end.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  // On arrival a line reaches out from the first idea and draws back, so
  // the items are seen to be things that can be joined. The first part of
  // the controller is the wait; no Timer, which would outlive a disposed
  // widget and hang a test.
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  // Measuring the text to size it is the one costly step; it is redone
  // only when the room or the text scale changes.
  _MatchGeometry? _geo;
  (Size, TextScaler)? _geoKey;

  bool get _locked => _guess != null;
  int get _n => widget.scene.pairs.length;
  bool get _calm => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !_calm) {
      _started = true;
      _nudge.forward();
    }
  }

  /// A different card in the same place starts over.
  @override
  void didUpdateWidget(MatchSceneView old) {
    super.didUpdateWidget(old);
    if (old.scene.raw != widget.scene.raw) {
      _reveal.value = 0;
      _links = {};
      _picked = _from = _hover = _snapFrom = null;
      _fresh = null;
      _gone = const [];
      _guess = null;
      _geo = null;
    }
  }

  @override
  void dispose() {
    _grow.dispose();
    _fade.dispose();
    _snap.dispose();
    _reveal.dispose();
    _nudge.dispose();
    super.dispose();
  }

  // ---- moves ----

  void _run(AnimationController c) {
    if (_calm) {
      c.value = 1;
    } else {
      c.forward(from: 0);
    }
  }

  void _touch() {
    _touched = true;
    _nudge.stop();
  }

  int? _leftOf(int right) {
    for (final e in _links.entries) {
      if (e.value == right) return e.key;
    }
    return null;
  }

  bool _isLinked(_MatchEnd e) =>
      e.left ? _links.containsKey(e.i) : _leftOf(e.i) != null;

  /// Takes the line off [e], letting it retract.
  void _unlink(_MatchEnd e) {
    final l = e.left ? e.i : _leftOf(e.i);
    if (l == null) return;
    final r = _links.remove(l);
    if (r == null) return;
    _gone = [(l, r)];
    _run(_fade);
  }

  /// Joins left [l] to right [r]; whatever either held before lets go.
  void _link(int l, int r) {
    if (_links[l] == r) {
      setState(() => _picked = null);
      return;
    }
    final gone = <(int, int)>[];
    final oldR = _links.remove(l);
    if (oldR != null) gone.add((l, oldR));
    final oldL = _leftOf(r);
    if (oldL != null) {
      _links.remove(oldL);
      gone.add((oldL, r));
    }
    HapticFeedback.lightImpact();
    setState(() {
      _links[l] = r;
      _fresh = l;
      _picked = null;
      _gone = gone;
    });
    _run(_grow);
    if (gone.isNotEmpty) _run(_fade);
  }

  /// The tap path, which a screen reader shares: pick, switch, join.
  void _tap(_MatchEnd e) {
    if (_locked) {
      final row = e.i;
      if (row != _focus) {
        HapticFeedback.selectionClick();
        setState(() => _focus = row);
      }
      return;
    }
    _touch();
    final p = _picked;
    if (p == null || p.left == e.left) {
      if (p == e) {
        setState(() => _picked = null);
        return;
      }
      HapticFeedback.selectionClick();
      setState(() {
        if (p == null && _isLinked(e)) _unlink(e);
        _picked = e;
      });
      return;
    }
    _link(p.left ? p.i : e.i, p.left ? e.i : p.i);
  }

  _MatchEnd? _hit(Offset at, _MatchGeometry g) {
    final row = (at.dy / g.pitch).floor();
    if (row < 0 || row >= _n) return null;
    // A little beyond each column's edge still counts, so a thumb that
    // lands on a dot catches the item the dot belongs to.
    if (at.dx <= g.leftW + 14) return (left: true, i: row);
    if (at.dx >= g.rightX - 14) {
      return (left: false, i: widget.scene.order[row]);
    }
    return null;
  }

  /// Where a dragged line would land: past the middle of the gap, the
  /// nearest item of the other column.
  _MatchEnd? _target(Offset at, _MatchGeometry g) {
    final from = _from;
    if (from == null) return null;
    final row = (at.dy / g.pitch).floor().clamp(0, _n - 1);
    if (from.left && at.dx >= g.gapMid) {
      return (left: false, i: widget.scene.order[row]);
    }
    if (!from.left && at.dx <= g.gapMid) return (left: true, i: row);
    return null;
  }

  void _dragStart(Offset at, _MatchGeometry g) {
    final e = _hit(at, g);
    if (e == null || _locked) return;
    _touch();
    HapticFeedback.selectionClick();
    setState(() {
      if (_isLinked(e)) _unlink(e);
      _picked = null;
      _from = e;
      _finger = at;
      _hover = null;
      _snap.value = 1;
    });
  }

  void _dragUpdate(Offset at, _MatchGeometry g) {
    if (_from == null) return;
    final hover = _target(at, g);
    if (hover != null && hover != _hover) HapticFeedback.selectionClick();
    setState(() {
      _finger = at;
      _hover = hover;
    });
  }

  void _dragEnd() {
    final from = _from;
    if (from == null) return;
    final to = _hover;
    _from = _hover = null;
    if (to != null) {
      _link(from.left ? from.i : to.i, from.left ? to.i : from.i);
      return;
    }
    setState(() {
      _snapFrom = from;
      _snapTip = _finger;
    });
    _run(_snap);
  }

  void _lock() {
    if (_locked || _links.length < _n) return;
    HapticFeedback.lightImpact();
    _nudge.stop();
    setState(() {
      _guess = Map.of(_links);
      _focus = widget.scene.focusFor(_guess!);
      _picked = _from = _hover = null;
    });
    _run(_reveal);
  }

  int get _correct {
    final g = _guess;
    if (g == null) return 0;
    return g.entries.where((e) => e.key == e.value).length;
  }

  // ---- reveal clock ----

  double _span(double from, double length, [Curve curve = Curves.linear]) =>
      curve.transform(((_reveal.value - from) / length).clamp(0.0, 1.0));

  /// Wrong lines let go of the wrong partner.
  double get _retract => _span(0, .2, Curves.easeInCubic);

  /// The right column slides into its true order.
  double get _slide => _span(.16, .46, Curves.easeInOutCubic);

  /// The missing lines draw in, following their partners as they arrive.
  double get _redraw => _span(.42, .34, Curves.easeOutCubic);
  double _badge(int row) => _span(.7 + row * .03, .12, Curves.easeOutCubic);

  /// The pair to read first turns over, and its note comes up.
  double get _settle => _span(.82, .18, Curves.easeOut);

  /// Where right item [p] stands, as a row that may be between rows.
  double _rowOf(int p) {
    final slot = widget.scene.order.indexOf(p).toDouble();
    if (!_locked) return slot;
    return slot + (p - slot) * _slide;
  }

  // ---- build ----

  _MatchGeometry _measure(Size board) {
    final scaler = MediaQuery.textScalerOf(context);
    final key = (board, scaler);
    if (_geo == null || _geoKey != key) {
      _geo = _MatchGeometry.measure(widget.scene, board, scaler);
      _geoKey = key;
    }
    return _geo!;
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final s = widget.scene;
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, box) {
        final tight = box.maxHeight < 330;
        final headerH = tight ? 15.0 : 18.0;
        final gapTop = tight ? 8.0 : 12.0;
        final gapBottom = tight ? 8.0 : 14.0;
        final footerH = tight ? 42.0 : 50.0;
        final boardH = math.max(
          0.0,
          box.maxHeight - headerH - gapTop - gapBottom - footerH,
        );
        final g = _measure(Size(box.maxWidth, boardH));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: headerH,
              child: AnimatedBuilder(
                animation: _reveal,
                builder: (context, _) => _MatchHeader(
                  left: s.leftTitle,
                  right: s.rightTitle,
                  score: _locked ? l10n.sceneNOfM(_correct, _n) : null,
                  scoreOpacity: _settle,
                  rightX: g.rightX,
                  size: tight ? 9.5 : 10.5,
                  ink: ink,
                ),
              ),
            ),
            SizedBox(height: gapTop),
            SizedBox(
              height: boardH,
              child: GestureDetector(
                // Until the answer is in, the board owns every drag and
                // every tap inside it: a line drawn sideways must not swipe
                // the card away, and a missed tap must not turn it over.
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onTap: _locked ? null : () => setState(() => _picked = null),
                onPanStart: _locked
                    ? null
                    : (d) => _dragStart(d.localPosition, g),
                onPanUpdate: _locked
                    ? null
                    : (d) => _dragUpdate(d.localPosition, g),
                onPanEnd: _locked ? null : (_) => _dragEnd(),
                onPanCancel: _locked ? null : _dragEnd,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _grow,
                    _fade,
                    _snap,
                    _reveal,
                    _nudge,
                  ]),
                  builder: (context, _) => _board(g),
                ),
              ),
            ),
            SizedBox(height: gapBottom),
            SizedBox(
              height: footerH,
              child: _locked
                  ? AnimatedBuilder(
                      animation: _reveal,
                      builder: (context, _) => Opacity(
                        opacity: _settle,
                        child: _MatchNote(
                          text: s.pairs[_focus].note,
                          size: tight ? 13 : 14,
                          ink: ink,
                        ),
                      ),
                    )
                  : _MatchLockButton(
                      label: l10n.sceneLockIn,
                      enabled: _links.length == _n,
                      ink: ink,
                      ground: widget.ground,
                      onTap: _lock,
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _board(_MatchGeometry g) {
    final s = widget.scene;
    final ink = widget.ink;
    final ground = widget.ground;
    final settle = _settle;
    final tiles = <Widget>[];

    // Left column: fixed rows.
    for (var i = 0; i < _n; i++) {
      final e = (left: true, i: i);
      tiles.add(
        Positioned.fromRect(
          rect: g.leftRect(i),
          child: _semantics(
            e,
            _MatchTile(
              text: s.pairs[i].left,
              style: g.leftStyle(ink),
              lines: 2,
              padH: g.padH,
              solid: _solidOf(e, settle),
              linked: _isLinked(e) || _locked,
              hover: _hover == e,
              lifted: _picked == e || _from == e,
              flying: false,
              ink: ink,
              ground: ground,
            ),
          ),
        ),
      );
    }

    // Right column: each item at its own, possibly moving, row. Items in
    // flight are drawn last so they pass over the ones standing still.
    final moving = <Widget>[];
    for (var p = 0; p < _n; p++) {
      final e = (left: false, i: p);
      final row = _rowOf(p);
      final travel = (row - s.order.indexOf(p)).abs();
      final inFlight = _locked && _slide > 0 && _slide < 1 && travel > 0;
      final tile = Positioned.fromRect(
        rect: g.rightRect(row),
        child: _semantics(
          e,
          _MatchTile(
            text: s.pairs[p].right,
            style: g.rightStyle(ink),
            lines: g.rightLines,
            padH: g.padH,
            solid: _solidOf(e, settle),
            linked: _isLinked(e) || _locked,
            hover: _hover == e,
            lifted: _picked == e || _from == e,
            flying: inFlight,
            ink: ink,
            ground: ground,
          ),
        ),
      );
      (inFlight ? moving : tiles).add(tile);
    }
    tiles.addAll(moving);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ...tiles,
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: _MatchPainter(_picture(g), ink: ink, ground: ground),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Turned over (solid ink) for the pair being read after the reveal.
  double _solidOf(_MatchEnd e, double settle) {
    if (!_locked) return 0;
    final row = e.i;
    return row == _focus ? settle : 0;
  }

  Widget _semantics(_MatchEnd e, Widget child) {
    final s = widget.scene;
    final l10n = context.l10n;
    final pair = s.pairs[e.i];
    if (_locked) {
      // After the reveal a rung is read as one thing, from its left end.
      // The right end still answers a tap: after the reveal it stands in
      // its partner's row.
      if (!e.left) {
        return ExcludeSemantics(
          child: GestureDetector(onTap: () => _tap(e), child: child),
        );
      }
      final g = _guess![e.i]!;
      final verdict = g == e.i
          ? ''
          : ' ${l10n.sceneYou}: ${s.pairs[g].right}.';
      return Semantics(
        button: true,
        selected: _focus == e.i,
        label: '${pair.left}: ${pair.right}.$verdict',
        hint: _focus == e.i ? pair.note : null,
        onTap: () => _tap(e),
        child: ExcludeSemantics(
          child: GestureDetector(onTap: () => _tap(e), child: child),
        ),
      );
    }
    final partner = e.left
        ? (_links[e.i] == null ? null : s.pairs[_links[e.i]!].right)
        : (_leftOf(e.i) == null ? null : s.pairs[_leftOf(e.i)!].left);
    return Semantics(
      button: true,
      selected: _picked == e,
      label: e.left ? pair.left : pair.right,
      value: partner,
      onTap: () => _tap(e),
      child: ExcludeSemantics(
        child: GestureDetector(onTap: () => _tap(e), child: child),
      ),
    );
  }

  /// Everything the painter draws this frame, worked out here so the
  /// painter only draws.
  _MatchPicture _picture(_MatchGeometry g) {
    final lines = <_MatchLine>[];
    final dots = <_MatchDot>[];
    final badges = <_MatchBadge>[];
    Offset? tip;

    Offset leftDot(int i) => Offset(g.leftW, g.dotY(i.toDouble()));
    Offset rightDot(int p) => Offset(g.rightX, g.dotY(_rowOf(p)));
    final missed = widget.scene.pairs.indexWhere((p) => p.missed);

    if (_locked) {
      final guess = _guess!;
      for (var i = 0; i < _n; i++) {
        final weight = i == missed ? 2.6 + 1.6 * _settle : 2.6;
        if (guess[i] == i) {
          lines.add((a: leftDot(i), b: rightDot(i), draw: 1, weight: weight,
              alpha: 1));
        } else {
          if (_retract < 1) {
            lines.add((a: leftDot(i), b: rightDot(guess[i]!),
                draw: 1 - _retract, weight: 2.6, alpha: 1 - _retract * .5));
          }
          if (_redraw > 0) {
            lines.add((a: leftDot(i), b: rightDot(i), draw: _redraw,
                weight: weight, alpha: 1));
          }
        }
        final b = _badge(i);
        if (b > 0) {
          badges.add((
            c: Offset((g.leftW + g.rightX) / 2, g.dotY(i.toDouble())),
            ok: guess[i] == i,
            t: b,
          ));
        }
        dots.add((c: leftDot(i), state: 1));
        dots.add((c: rightDot(i), state: 1));
      }
      return (lines: lines, dots: dots, badges: badges, tip: null);
    }

    for (final e in _links.entries) {
      lines.add((
        a: leftDot(e.key),
        b: rightDot(e.value),
        draw: e.key == _fresh ? Curves.easeOutCubic.transform(_grow.value) : 1,
        weight: 2.6,
        alpha: 1,
      ));
    }
    if (_fade.value < 1) {
      for (final (l, r) in _gone) {
        lines.add((
          a: leftDot(l),
          b: rightDot(r),
          draw: 1 - Curves.easeInCubic.transform(_fade.value),
          weight: 2.6,
          alpha: 1 - _fade.value,
        ));
      }
    }
    Offset dotOf(_MatchEnd e) => e.left ? leftDot(e.i) : rightDot(e.i);
    final from = _from;
    if (from != null) {
      final hover = _hover;
      final end = hover == null ? _finger : dotOf(hover);
      lines.add((a: dotOf(from), b: end, draw: 1, weight: 2.6, alpha: 1));
      if (hover == null) tip = _finger;
    }
    final snapFrom = _snapFrom;
    if (snapFrom != null && _snap.value < 1) {
      lines.add((
        a: dotOf(snapFrom),
        b: _snapTip,
        draw: 1 - Curves.easeOutCubic.transform(_snap.value),
        weight: 2.6,
        alpha: 1 - _snap.value * .4,
      ));
    }
    // The arrival hint: a line reaches part of the way and draws back.
    if (!_touched && _nudge.value > 0 && _nudge.value < 1) {
      final np = ((_nudge.value - .35) / .65).clamp(0.0, 1.0);
      final reach = math.sin(np * math.pi) * .62;
      if (reach > 0) {
        lines.add((
          a: leftDot(0),
          b: rightDot(widget.scene.order[math.min(1, _n - 1)]),
          draw: reach,
          weight: 2.6,
          alpha: .55,
        ));
      }
    }

    for (var i = 0; i < _n; i++) {
      final l = (left: true, i: i);
      final r = (left: false, i: i);
      int state(_MatchEnd e) => _picked == e || _from == e || _hover == e
          ? 2
          : _isLinked(e)
          ? 1
          : 0;
      dots.add((c: leftDot(i), state: state(l)));
      dots.add((c: rightDot(i), state: state(r)));
    }
    return (lines: lines, dots: dots, badges: badges, tip: tip);
  }
}

// ---- geometry ----

/// Where everything on the board stands, worked out once per size: the
/// row pitch, both columns, and the type sizes that let every item fit.
/// The tiles, the painter and the hit-test all read this one object, so a
/// line always meets the dot of the tile it belongs to.
class _MatchGeometry {
  final int n;
  final double pitch;
  final double tileH;
  final double leftW;
  final double rightX;
  final double rightW;
  final double leftSize;
  final double rightSize;
  final int rightLines;
  final double padH;

  const _MatchGeometry({
    required this.n,
    required this.pitch,
    required this.tileH,
    required this.leftW,
    required this.rightX,
    required this.rightW,
    required this.leftSize,
    required this.rightSize,
    required this.rightLines,
    required this.padH,
  });

  double get gapMid => (leftW + rightX) / 2;
  double dotY(double row) => row * pitch + pitch / 2;
  Rect leftRect(int row) =>
      Rect.fromLTWH(0, dotY(row.toDouble()) - tileH / 2, leftW, tileH);
  Rect rightRect(double row) =>
      Rect.fromLTWH(rightX, dotY(row) - tileH / 2, rightW, tileH);

  static TextStyle _left(double size, Color ink) => AppText.display(
    size: size,
    weight: FontWeight.w700,
    height: 1.08,
    spacing: -0.2 - size * 0.012,
    color: ink,
  );

  static TextStyle _right(double size, Color ink) => AppText.body(
    size: size,
    weight: FontWeight.w600,
    height: 1.16,
    color: ink,
  );

  TextStyle leftStyle(Color ink) => _left(leftSize, ink);
  TextStyle rightStyle(Color ink) => _right(rightSize, ink);

  static TextPainter _lay(
    String text,
    TextStyle style,
    TextScaler scaler, {
    int? lines,
    double maxWidth = double.infinity,
  }) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: lines,
  )..layout(maxWidth: maxWidth);

  /// The largest size, from [hi] down to [lo], at which every text fits a
  /// box [w] × [h] in at most [lines] lines with no word broken.
  static double _fit(
    List<String> texts,
    TextStyle Function(double) style,
    TextScaler scaler,
    double w,
    double h,
    int lines,
    double hi,
    double lo,
  ) {
    for (var size = hi; size > lo; size -= 0.5) {
      final st = style(size);
      final fits = texts.every((t) {
        final tp = _lay(t, st, scaler, lines: lines, maxWidth: w);
        final ok = !tp.didExceedMaxLines && tp.height <= h;
        tp.dispose();
        if (!ok) return false;
        for (final word in t.split(' ')) {
          final wp = _lay(word, st, scaler);
          final wide = wp.width > w;
          wp.dispose();
          if (wide) return false;
        }
        return true;
      });
      if (fits) return size;
    }
    return lo;
  }

  factory _MatchGeometry.measure(
    MatchScene scene,
    Size board,
    TextScaler scaler,
  ) {
    final n = scene.pairs.length;
    final w = board.width;
    final pitch = board.height / n;
    // Tiles grow with the room up to a comfortable slab; any height left
    // over goes to the gaps between rows, which gives the lines room.
    final gap = (pitch * 0.12).clamp(4.0, 22.0);
    final tileH = math.max(24.0, math.min(pitch - gap, 104.0));
    final padH = w < 300 ? 10.0 : 13.0;
    const padV = 4.0;
    final colGap = (w * 0.14).clamp(38.0, 60.0);
    final avail = w - colGap;
    final innerH = tileH - padV * 2;

    final lefts = [for (final p in scene.pairs) p.left];
    final rights = [for (final p in scene.pairs) p.right];
    const black = Color(0xFF000000);
    double fitLeft(double width) => _fit(
      lefts,
      (s) => _left(s, black),
      scaler,
      width - padH * 2,
      innerH,
      2,
      math.min(24, tileH * 0.42),
      12,
    );
    // Right: as many lines as the tile holds, at most three.
    const rightLines = 3;
    double fitRight(double width) => _fit(
      rights,
      (s) => _right(s, black),
      scaler,
      width - padH * 2,
      innerH,
      rightLines,
      math.min(17, tileH * 0.36),
      10.5,
    );

    // The split between the columns is the one that lets the smaller of
    // the two type sizes, each against what it would like to be, be
    // largest: short ideas give their width to long explanations.
    var best = -1.0;
    var leftMax = avail * 0.4;
    var leftSize = 12.0;
    for (var share = 0.28; share <= 0.5; share += 0.02) {
      final lw = avail * share;
      final ls = fitLeft(lw);
      final rs = fitRight(avail - lw);
      final score = math.min(ls / 21, rs / 14.5) + rs / 1000;
      if (score > best) {
        best = score;
        leftMax = lw;
        leftSize = ls;
      }
    }

    // Every left tile as wide as the widest needs, so the dots stand in
    // one line and no curve passes over a tile; what the left column does
    // not use goes to the right one.
    var hug = 0.0;
    final st = _left(leftSize, black);
    for (final t in lefts) {
      final tp = _lay(t, st, scaler, lines: 2, maxWidth: leftMax - padH * 2);
      hug = math.max(hug, tp.width);
      tp.dispose();
    }
    final leftW = math.min(leftMax, hug + padH * 2 + 4);
    final rightW = avail - leftW;
    final rightSize = fitRight(rightW);

    return _MatchGeometry(
      n: n,
      pitch: pitch,
      tileH: tileH,
      leftW: leftW,
      rightX: w - rightW,
      rightW: rightW,
      leftSize: leftSize,
      rightSize: rightSize,
      rightLines: rightLines,
      padH: padH,
    );
  }
}

// ---- painting ----

/// A curve from [a] to [b], drawn from [a] for the share [draw] of its
/// length.
typedef _MatchLine = ({
  Offset a,
  Offset b,
  double draw,
  double weight,
  double alpha,
});

/// An item's dot: 0 free, 1 joined, 2 in hand (picked, dragged, aimed at).
typedef _MatchDot = ({Offset c, int state});

/// A rung's verdict: a tick if the reader had it, a cross if not.
typedef _MatchBadge = ({Offset c, bool ok, double t});

typedef _MatchPicture = ({
  List<_MatchLine> lines,
  List<_MatchDot> dots,
  List<_MatchBadge> badges,
  Offset? tip,
});

class _MatchPainter extends CustomPainter {
  final _MatchPicture picture;
  final Color ink;
  final Color ground;
  _MatchPainter(this.picture, {required this.ink, required this.ground});

  late final Paint _glow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  late final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  late final Paint _fill = Paint();

  /// Leaves each end level, so a line meets its dot head-on and the
  /// curve does all its turning in the open middle of the gap.
  static Path _curve(Offset a, Offset b) {
    final dir = b.dx >= a.dx ? 1.0 : -1.0;
    final k = math.max((b.dx - a.dx).abs() * 0.62, 18.0);
    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx + dir * k, a.dy, b.dx - dir * k, b.dy, b.dx, b.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final l in picture.lines) {
      if (l.draw <= 0 || l.alpha <= 0) continue;
      var path = _curve(l.a, l.b);
      if (l.draw < 1) {
        final m = path.computeMetrics().first;
        path = m.extractPath(0, m.length * l.draw);
      }
      // A soft wide stroke under the line gives it a little body.
      _glow
        ..color = ink.withValues(alpha: 0.08 * l.alpha)
        ..strokeWidth = l.weight + 6;
      canvas.drawPath(path, _glow);
      _stroke
        ..color = ink.withValues(alpha: l.alpha)
        ..strokeWidth = l.weight;
      canvas.drawPath(path, _stroke);
    }

    for (final d in picture.dots) {
      switch (d.state) {
        case 2:
          _fill.color = ink.withValues(alpha: 0.18);
          canvas.drawCircle(d.c, 11, _fill);
          _fill.color = ink;
          canvas.drawCircle(d.c, 6, _fill);
        case 1:
          _fill.color = ink;
          canvas.drawCircle(d.c, 5, _fill);
        default:
          _fill.color = ground;
          canvas.drawCircle(d.c, 5, _fill);
          _stroke
            ..color = ink.withValues(alpha: 0.6)
            ..strokeWidth = 1.8;
          canvas.drawCircle(d.c, 5, _stroke);
      }
    }

    final tip = picture.tip;
    if (tip != null) {
      _fill.color = ink;
      canvas.drawCircle(tip, 6, _fill);
    }

    for (final b in picture.badges) {
      final r = 10.0 * b.t;
      if (r <= 0) continue;
      _fill.color = b.ok ? ink : ground;
      canvas.drawCircle(b.c, r, _fill);
      _stroke
        ..color = ink
        ..strokeWidth = 2;
      if (!b.ok) canvas.drawCircle(b.c, r, _stroke);
      _stroke.color = b.ok ? ground : ink;
      final s = r * 0.42;
      final c = b.c;
      if (b.ok) {
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - s, c.dy + s * 0.05)
            ..lineTo(c.dx - s * 0.25, c.dy + s * 0.75)
            ..lineTo(c.dx + s, c.dy - s * 0.65),
          _stroke,
        );
      } else {
        canvas.drawLine(c + Offset(-s, -s), c + Offset(s, s), _stroke);
        canvas.drawLine(c + Offset(s, -s), c + Offset(-s, s), _stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_MatchPainter old) =>
      old.ink != ink ||
      old.ground != ground ||
      old.picture.tip != picture.tip ||
      !listEquals(old.picture.lines, picture.lines) ||
      !listEquals(old.picture.dots, picture.dots) ||
      !listEquals(old.picture.badges, picture.badges);
}

// ---- pieces ----

class _MatchHeader extends StatelessWidget {
  final String left;
  final String right;
  final String? score;
  final double scoreOpacity;
  final double rightX;
  final double size;
  final Color ink;
  const _MatchHeader({
    required this.left,
    required this.right,
    required this.score,
    required this.scoreOpacity,
    required this.rightX,
    required this.size,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    final style = AppText.label(size: size, color: ink.withValues(alpha: 0.6));
    return Stack(
      children: [
        Positioned(
          left: 0,
          width: rightX - 8,
          top: 0,
          bottom: 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              left.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ),
        Positioned(
          left: rightX,
          right: 0,
          top: 0,
          bottom: 0,
          child: Row(
            children: [
              Expanded(
                child: Opacity(
                  opacity: score == null ? 1 : 1 - scoreOpacity,
                  child: Text(
                    right.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (score != null)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: scoreOpacity,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  score!.toUpperCase(),
                  style: AppText.label(
                    size: size,
                    weight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One item: a rounded slab with its words. Picked or dragged from, it
/// lifts and turns solid; aimed at by a line, it takes a ring; read after
/// the reveal, it turns solid too.
class _MatchTile extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int lines;
  final double padH;
  final double solid;
  final bool linked;
  final bool hover;
  final bool lifted;

  /// Sliding past the others during the reveal: raised, not turned over.
  final bool flying;
  final Color ink;
  final Color ground;
  const _MatchTile({
    required this.text,
    required this.style,
    required this.lines,
    required this.padH,
    required this.solid,
    required this.linked,
    required this.hover,
    required this.lifted,
    required this.flying,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) {
    final raised = lifted || flying;
    final turn = lifted ? 1.0 : solid;
    // Opaque, mixed onto the ground, so a tile sliding past another
    // during the reveal covers it instead of showing both texts at once.
    final rest = Color.alphaBlend(
      ink.withValues(alpha: linked ? 0.14 : 0.08),
      ground,
    );
    final face = Color.lerp(ink, ground, turn)!;
    return LayoutBuilder(
      builder: (context, box) {
        final radius = BorderRadius.circular(
          (box.maxHeight * 0.28).clamp(10.0, 18.0),
        );
        return AnimatedScale(
          scale: raised ? 1.03 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: Color.lerp(rest, ink, turn),
              border: hover
                  ? Border.all(color: ink, width: 2)
                  : Border.all(color: const Color(0x00000000), width: 2),
              boxShadow: raised
                  ? const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padH - 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  maxLines: lines,
                  overflow: TextOverflow.ellipsis,
                  style: style.copyWith(color: face),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MatchLockButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final Color ink;
  final Color ground;
  final VoidCallback onTap;
  const _MatchLockButton({
    required this.label,
    required this.enabled,
    required this.ink,
    required this.ground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    label: label,
    onTap: enabled ? onTap : null,
    child: ExcludeSemantics(
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.32,
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: ink,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            // Not yet: the tap is still the scene's, and does nothing.
            onTap: enabled ? onTap : () {},
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
    ),
  );
}

class _MatchNote extends StatelessWidget {
  final String text;
  final double size;
  final Color ink;
  const _MatchNote({required this.text, required this.size, required this.ink});

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Align(
        key: ValueKey(text),
        alignment: Alignment.topLeft,
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.body(
            size: size,
            weight: FontWeight.w600,
            height: 1.3,
            color: ink.withValues(alpha: 0.92),
          ),
        ),
      ),
    ),
  );
}
