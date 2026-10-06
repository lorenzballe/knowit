import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/scene.dart';
import '../../theme.dart';
import '../place_it.dart' show roughNumber;

/// Plays a [RankScene]: drag the rows into order, lock it in, watch the truth.
///
/// Before: a column of rows beside fixed place numbers, 1 at the top where
/// [RankScene.most] goes. Each row is dragged by the whole of itself; the
/// others step aside as it passes. After: the rows slide to their true
/// places, each row fills from the left like a bar to its real value while
/// the number counts up, and the row the reader misplaced most turns solid.
///
/// Every row also says how far it moved (▲2, ▼1, or ✓ when it was right),
/// so the verdict does not live in colour or motion alone.
class RankSceneView extends StatefulWidget {
  final RankScene scene;
  final Color ink;
  final Color ground;
  const RankSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<RankSceneView> createState() => _RankSceneViewState();
}

class _RankSceneViewState extends State<RankSceneView>
    with TickerProviderStateMixin {
  /// Item indices, top first: the reader's current order.
  late List<int> _order = List.generate(widget.scene.items.length, (i) => i);

  // The row under the finger, where its top is, and the place it would
  // drop into if let go now.
  int? _dragged;
  double _dragTop = 0;
  double _grabTop = 0;
  double _grabY = 0;
  int _hover = 0;

  // Fixed at lock-in.
  List<int>? _guess;
  late List<int> _truth = widget.scene.truth;
  int _surprise = -1;

  /// Slides, fills and the final highlight, all on one clock so they stay in
  /// step and a widget test can run them to the end.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  // On arrival the top row dips and comes back, so the rows are seen to be
  // movable. The first part of the controller is the wait; no Timer, which
  // would outlive a disposed widget and hang a test.
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  bool _started = false;

  bool get _locked => _guess != null;
  int get _n => widget.scene.items.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _nudge.forward();
    }
  }

  /// A different card in the same place starts over.
  @override
  void didUpdateWidget(RankSceneView old) {
    super.didUpdateWidget(old);
    if (old.scene.raw != widget.scene.raw) {
      _reveal.value = 0;
      _order = List.generate(widget.scene.items.length, (i) => i);
      _truth = widget.scene.truth;
      _dragged = null;
      _guess = null;
      _surprise = -1;
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    _nudge.dispose();
    super.dispose();
  }

  // ---- ordering ----

  /// The order the rows would take if the dragged one were dropped now.
  List<int> get _shown {
    final d = _dragged;
    if (d == null) return _order;
    return [..._order]
      ..remove(d)
      ..insert(_hover, d);
  }

  void _startDrag(int item, double globalY, double pitch) {
    if (_locked) return;
    _nudge.stop();
    HapticFeedback.selectionClick();
    final slot = _order.indexOf(item);
    setState(() {
      _dragged = item;
      _hover = slot;
      _grabTop = _dragTop = slot * pitch;
      _grabY = globalY;
    });
  }

  void _updateDrag(double globalY, double pitch) {
    if (_dragged == null) return;
    final top = (_grabTop + globalY - _grabY).clamp(0.0, (_n - 1) * pitch);
    final slot = (top / pitch).round().clamp(0, _n - 1);
    if (slot != _hover) HapticFeedback.selectionClick();
    setState(() {
      _dragTop = top;
      _hover = slot;
    });
  }

  void _endDrag() {
    if (_dragged == null) return;
    setState(() {
      _order = _shown;
      _dragged = null;
    });
  }

  /// Screen-reader and keyboard path: the same move as a drag, one place.
  void _step(int item, int by) {
    if (_locked) return;
    final from = _order.indexOf(item);
    final to = (from + by).clamp(0, _n - 1);
    if (to == from) return;
    HapticFeedback.selectionClick();
    setState(() {
      _order = [..._order]
        ..removeAt(from)
        ..insert(to, item);
    });
  }

  void _lock() {
    if (_locked) return;
    HapticFeedback.lightImpact();
    _nudge.stop();
    setState(() {
      if (_dragged != null) {
        _order = _shown;
        _dragged = null;
      }
      _guess = List.of(_order);
      _surprise = widget.scene.surpriseFor(_guess!);
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = 1;
    } else {
      _reveal.forward();
    }
  }

  // ---- numbers ----

  static bool _prefix(String unit) =>
      const {'€', r'$', '£', '¥'}.contains(unit);

  /// Decimals the value deserves: whole numbers stay whole, small fractions
  /// keep one or two places.
  static int _decimals(double v) {
    if (v >= 100 || v == v.roundToDouble()) return 0;
    return v >= 1 ? 1 : 2;
  }

  static String _number(double v, int decimals) {
    if (v >= 1e6) return roughNumber(v);
    final parts = v.toStringAsFixed(decimals).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return parts.length > 1 ? '$whole.${parts[1]}' : whole;
  }

  String _withUnit(String n) {
    final u = widget.scene.unit;
    if (u.isEmpty) return n;
    return _prefix(u) ? '$u$n' : '$n $u';
  }

  /// The figure shown while a bar grows: on a log scale it climbs through
  /// the orders of magnitude, as the bar does.
  double _countUp(int item, double g) {
    final s = widget.scene;
    final v = s.items[item].value;
    if (g >= 1) return v;
    if (!s.log) return v * g;
    final lo = s.items.map((e) => e.value).reduce(math.min) / 10;
    return lo * math.pow(v / lo, g);
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final s = widget.scene;
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, box) {
        // The footer is the one thing that must keep its size; the list
        // takes the rest and its rows grow with it, up to a point.
        final tight = box.maxHeight < 330;
        final headerH = 18.0;
        final footerH = tight ? 44.0 : 50.0;
        final gapTop = tight ? 8.0 : 12.0;
        final gapBottom = tight ? 10.0 : 14.0;
        final listH = math.max(
          0.0,
          box.maxHeight - headerH - gapTop - gapBottom - footerH,
        );
        var gap = (listH * 0.03).clamp(5.0, 10.0);
        final rowH = math.min((listH - gap * (_n - 1)) / _n, 104.0);
        gap = math.min((listH - rowH * _n) / (_n - 1), 22.0);
        final pitch = rowH + gap;
        final inset = (listH - (rowH * _n + gap * (_n - 1))) / 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: headerH,
              child: AnimatedBuilder(
                animation: _reveal,
                builder: (context, _) => _Header(
                  quantity: s.quantity,
                  // Before: which end is the top. After: how many were
                  // already in their place.
                  sign: _locked ? 0 : 1,
                  trailing: _locked ? l10n.sceneNOfM(_correct, _n) : s.most,
                  trailingOpacity: _locked ? _fade(.82) : 1,
                  ink: ink,
                ),
              ),
            ),
            SizedBox(height: gapTop),
            SizedBox(
              height: listH,
              child: GestureDetector(
                // A tap among the rows is a miss at a row, not a request to
                // turn the card over; once locked, the card is free again.
                behavior: HitTestBehavior.opaque,
                onTap: _locked ? null : () {},
                child: AnimatedBuilder(
                  animation: Listenable.merge([_reveal, _nudge]),
                  builder: (context, _) => _list(rowH, pitch, inset),
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
                        opacity: _fade(.84),
                        child: _Note(text: s.items[_surprise].note, ink: ink),
                      ),
                    )
                  : _LockButton(
                      label: l10n.sceneLockIn,
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

  int get _correct {
    final g = _guess;
    if (g == null) return 0;
    var n = 0;
    for (var i = 0; i < _n; i++) {
      if (g[i] == _truth[i]) n++;
    }
    return n;
  }

  /// 0 → 1 over the last part of the reveal, from [from] on.
  double _fade(double from) => Curves.easeOut.transform(
    ((_reveal.value - from) / (1 - from)).clamp(0, 1),
  );

  Widget _list(double rowH, double pitch, double inset) {
    final ink = widget.ink;
    final numW = (rowH * 0.5).clamp(22.0, 40.0);
    // Capped so a short list's tall rows don't set labels too big to fit
    // beside their values.
    final font = (rowH * 0.36).clamp(14.0, 22.0);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final t = _reveal.value;
    final move = Curves.easeInOutCubic.transform((t / .35).clamp(0, 1));
    final shown = _shown;

    // The top row's arrival dip: nothing for the first 40%, then one bump.
    final np = ((_nudge.value - .4) / .6).clamp(0.0, 1.0);
    final dip = math.sin(np * math.pi) * pitch * .16;

    final rows = <Widget>[];
    for (final item in _order) {
      final dragging = item == _dragged;
      double top;
      if (_locked) {
        final from = _guess!.indexOf(item) * pitch;
        final to = _truth.indexOf(item) * pitch;
        top = from + (to - from) * move;
      } else if (dragging) {
        top = _dragTop;
      } else {
        top = shown.indexOf(item) * pitch + (shown.first == item ? dip : 0);
      }

      double grow = 0;
      if (_locked) {
        final r = _truth.indexOf(item);
        final start = .32 + r * (.22 / (_n - 1));
        grow = Curves.easeOutCubic.transform(
          ((t - start) / .42).clamp(0.0, 1.0),
        );
      }
      final highlight = item == _surprise ? _fade(.82) : 0.0;
      final moved = _locked ? _guess!.indexOf(item) - _truth.indexOf(item) : 0;

      rows.add(
        AnimatedPositioned(
          key: ValueKey(item),
          // Rows stepping aside glide; the one under the finger, and every
          // row during the reveal, follows its own clock instead.
          duration: dragging || _locked || reduce
              ? Duration.zero
              : const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          left: numW + 8,
          right: 0,
          top: inset + top,
          height: rowH,
          child: _row(
            item: item,
            rowH: rowH,
            pitch: pitch,
            font: font,
            dragging: dragging,
            grow: grow,
            highlight: highlight,
            moved: moved,
            settled: t >= .32,
          ),
        ),
      );
    }
    // The lifted row is drawn last, over the ones it passes.
    if (_dragged != null) {
      final i = _order.indexOf(_dragged!);
      rows.add(rows.removeAt(i));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var slot = 0; slot < _n; slot++)
          Positioned(
            left: 0,
            width: numW,
            top: inset + slot * pitch,
            height: rowH,
            child: ExcludeSemantics(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${slot + 1}',
                  style: AppText.display(
                    size: font * 1.15,
                    weight: FontWeight.w800,
                    height: 1,
                    color: ink.withValues(alpha: 0.38),
                  ),
                ),
              ),
            ),
          ),
        ...rows,
      ],
    );
  }

  Widget _row({
    required int item,
    required double rowH,
    required double pitch,
    required double font,
    required bool dragging,
    required double grow,
    required double highlight,
    required int moved,
    required bool settled,
  }) {
    final s = widget.scene;
    final it = s.items[item];
    final l10n = context.l10n;
    final full = _withUnit(_number(it.value, _decimals(it.value)));

    final tile = _RankTile(
      label: it.label,
      value: _locked
          ? _withUnit(_number(_countUp(item, grow), _decimals(it.value)))
          : null,
      moved: _locked && settled ? moved : null,
      // A figure appears as its bar starts, not as a row of zeros before.
      valueOpacity: (grow * 3).clamp(0.0, 1.0),
      bar: _locked ? s.barOf(item) * grow : 0,
      lifted: dragging,
      highlight: highlight,
      rowH: rowH,
      font: font,
      ink: widget.ink,
      ground: widget.ground,
    );

    if (_locked) {
      return Semantics(
        label: it.label,
        value: '$full, ${l10n.sceneNOfM(_truth.indexOf(item) + 1, _n)}',
        child: ExcludeSemantics(child: tile),
      );
    }

    final place = _order.indexOf(item);
    return Semantics(
      label: it.label,
      value: l10n.sceneNOfM(place + 1, _n),
      increasedValue: place > 0 ? l10n.sceneNOfM(place, _n) : null,
      decreasedValue: place < _n - 1 ? l10n.sceneNOfM(place + 2, _n) : null,
      // Up the list is toward the most.
      onIncrease: place > 0 ? () => _step(item, -1) : null,
      onDecrease: place < _n - 1 ? () => _step(item, 1) : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // From the finger's first touch, so the row does not lag behind
          // it by the slop the gesture needs to be recognised.
          dragStartBehavior: DragStartBehavior.down,
          // Vertical is the move. Horizontal is claimed too, and read only
          // for its vertical part, so a slanted drag that starts on a row
          // moves the row instead of swiping the deck away.
          onVerticalDragStart: (d) =>
              _startDrag(item, d.globalPosition.dy, pitch),
          onVerticalDragUpdate: (d) => _updateDrag(d.globalPosition.dy, pitch),
          onVerticalDragEnd: (_) => _endDrag(),
          onVerticalDragCancel: _endDrag,
          onHorizontalDragStart: (d) =>
              _startDrag(item, d.globalPosition.dy, pitch),
          onHorizontalDragUpdate: (d) =>
              _updateDrag(d.globalPosition.dy, pitch),
          onHorizontalDragEnd: (_) => _endDrag(),
          onHorizontalDragCancel: _endDrag,
          child: tile,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String quantity;
  final int sign;
  final String trailing;
  final double trailingOpacity;
  final Color ink;
  const _Header({
    required this.quantity,
    required this.sign,
    required this.trailing,
    required this.trailingOpacity,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Text(
          quantity.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.label(size: 10.5, color: ink.withValues(alpha: 0.6)),
        ),
      ),
      const SizedBox(width: 10),
      Opacity(
        opacity: trailingOpacity,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Mark(moved: sign, color: ink, size: 10.5, number: false),
            const SizedBox(width: 5),
            Text(
              trailing.toUpperCase(),
              style: AppText.label(
                size: 10.5,
                weight: FontWeight.w800,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// One row: a rounded slab that, after the reveal, is also a bar.
///
/// The bar is a darker fill growing from the left inside the slab, with
/// the value printed at the row's end.
class _RankTile extends StatelessWidget {
  final String label;
  final String? value;
  final double valueOpacity;

  /// Places the row climbed (positive) or fell to reach the truth; zero
  /// when the reader had it right, null before the reveal.
  final int? moved;
  final double bar;
  final bool lifted;
  final double highlight;
  final double rowH;
  final double font;
  final Color ink;
  final Color ground;
  const _RankTile({
    required this.label,
    required this.value,
    required this.valueOpacity,
    required this.moved,
    required this.bar,
    required this.lifted,
    required this.highlight,
    required this.rowH,
    required this.font,
    required this.ink,
    required this.ground,
  });

  Widget _content(Color color, double width) {
    final pad = (rowH * 0.24).clamp(12.0, 20.0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(
                      size: font,
                      weight: FontWeight.w700,
                      height: 1.05,
                      spacing: -0.2 - font * 0.01,
                      color: color,
                    ),
                  ),
                ),
                if (moved != null) ...[
                  SizedBox(width: font * 0.4),
                  _Mark(
                    moved: moved!,
                    color: color.withValues(alpha: 0.7),
                    size: (font * 0.55).clamp(10.5, 13.0),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: font * 0.4),
          if (value != null)
            // The value wins the row: the label gives way first, and only a
            // figure wider than most of the row is set smaller.
            Opacity(
              opacity: valueOpacity,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width * 0.5),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    value!,
                    maxLines: 1,
                    style:
                        AppText.display(
                          size: font * 0.98,
                          weight: FontWeight.w800,
                          height: 1,
                          spacing: -0.4,
                          color: color,
                        ).copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                ),
              ),
            )
          else
            _Grip(
              color: color.withValues(alpha: 0.45),
              size: math.max(font * 0.9, 18),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular((rowH * 0.3).clamp(10.0, 20.0));
    // The surprise turns over: the slab goes solid ink, its bar becomes a
    // lighter band of the ground colour and its words take the ground.
    // Lifted under the finger, a row turns over the same way.
    final solid = lifted ? 1.0 : highlight;
    final slab = Color.lerp(ink.withValues(alpha: 0.08), ink, solid)!;
    final barColor = Color.lerp(
      ink.withValues(alpha: 0.16),
      ground.withValues(alpha: 0.3),
      solid,
    )!;
    final face = Color.lerp(ink, ground, solid)!;

    return AnimatedScale(
      scale: lifted ? 1.03 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: slab,
          boxShadow: lifted
              ? const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              fit: StackFit.expand,
              children: [
                if (bar > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: bar.clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: ColoredBox(color: barColor),
                    ),
                  ),
                _content(face, box.maxWidth),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// How a row moved, drawn rather than typed (the fonts carry no arrows):
/// a small triangle up or down with the number of places, or a tick when
/// the row was already in its place.
class _Mark extends StatelessWidget {
  final int moved;
  final Color color;
  final double size;
  final bool number;
  const _Mark({
    required this.moved,
    required this.color,
    required this.size,
    this.number = true,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox.square(
        dimension: size * 0.9,
        child: CustomPaint(painter: _MarkPainter(moved.sign, color)),
      ),
      if (number && moved != 0) ...[
        SizedBox(width: size * 0.22),
        Text(
          '${moved.abs()}',
          style: AppText.label(
            size: size,
            weight: FontWeight.w800,
            spacing: 0,
            height: 1,
            color: color,
          ),
        ),
      ],
    ],
  );
}

class _MarkPainter extends CustomPainter {
  /// 1 up, -1 down, 0 a tick.
  final int dir;
  final Color color;
  _MarkPainter(this.dir, this.color);

  late final Paint _fill = Paint()..color = color;
  late final Paint _stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (dir == 0) {
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.08, h * 0.55)
          ..lineTo(w * 0.38, h * 0.84)
          ..lineTo(w * 0.94, h * 0.18),
        _stroke,
      );
      return;
    }
    final up = dir > 0;
    canvas.drawPath(
      Path()
        ..moveTo(w / 2, up ? h * 0.12 : h * 0.88)
        ..lineTo(w, up ? h * 0.88 : h * 0.12)
        ..lineTo(0, up ? h * 0.88 : h * 0.12)
        ..close(),
      _fill,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.dir != dir || old.color != color;
}

/// Three short rules: the sign for "this can be dragged".
class _Grip extends StatelessWidget {
  final Color color;
  final double size;
  const _Grip({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size * 0.62,
    child: CustomPaint(painter: _GripPainter(color)),
  );
}

class _GripPainter extends CustomPainter {
  final Color color;
  _GripPainter(this.color);

  late final Paint _line = Paint()
    ..color = color
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final y = 1.1 + (size.height - 2.2) * i / 2;
      canvas.drawLine(Offset(1.1, y), Offset(size.width - 1.1, y), _line);
    }
  }

  @override
  bool shouldRepaint(_GripPainter old) => old.color != color;
}

class _LockButton extends StatelessWidget {
  final String label;
  final Color ink;
  final Color ground;
  final VoidCallback onTap;
  const _LockButton({
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

class _Note extends StatelessWidget {
  final String text;
  final Color ink;
  const _Note({required this.text, required this.ink});

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Align(
      alignment: Alignment.topLeft,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppText.body(
          size: 14,
          weight: FontWeight.w600,
          height: 1.3,
          color: ink.withValues(alpha: 0.92),
        ),
      ),
    ),
  );
}
