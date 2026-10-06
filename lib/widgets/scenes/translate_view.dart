import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/scene.dart';
import '../../theme.dart';

/// Plays a [TranslateScene]: tap the jargon, read what it really says.
///
/// The scene is one printed sheet laid on the card: a letterhead with a
/// double rule, a heading, the jargon set in the serif of a contract, and a
/// stub at the foot behind a perforation, like the tear-off end of a ticket.
/// The marked phrases sit under a pale marker with a dotted rule beneath.
///
/// A tap on a phrase selects it the way an editor does — an outline with a
/// round handle at each end, a highlight sweeping across — and then the
/// plain words are typed in over it, in the app's sans, the document
/// reflowing as they arrive. The stub says why the phrase was worded that
/// way, quoting the jargon it replaced. The phrase that hides the catch is
/// printed solid once translated, so the finished sheet shows at a glance
/// where the trap was. When every phrase is translated the stub settles on
/// what to watch for, and, if the first tap was a guess, whether it was
/// right — said with a mark and in words, never by colour alone.
///
/// Drags are not claimed: a swipe across the sheet still moves the deck.
/// Taps on the sheet are kept while there is something left to translate,
/// so a tap that misses a phrase does not turn the card over; once the
/// sheet is finished, only the phrases keep their taps.
class TranslateSceneView extends StatefulWidget {
  final TranslateScene scene;
  final Color ink;
  final Color ground;
  const TranslateSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<TranslateSceneView> createState() => _TranslateSceneViewState();
}

/// The parts of the flip, on one clock: the selection sweeps across the
/// jargon, then the plain words are typed in, then the handles settle.
const double _sweepEnd = 0.3;

class _TranslateSceneViewState extends State<TranslateSceneView>
    with TickerProviderStateMixin {
  late List<bool> _plain = List.filled(widget.scene.phrases.length, false);

  /// The phrase under the selection, whose note is on the stub.
  int? _active;

  /// The first phrase tapped, when the first tap is a guess.
  int? _guess;

  /// The phrase being retyped, until its flip lands.
  int? _typing;

  late final AnimationController _flip =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed) _landed();
      });

  // On arrival each marker brightens in turn, so the phrases are seen to be
  // things to touch. The first part of the clock is the wait; no Timer,
  // which would outlive a disposed widget and hang a test.
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  // Once the last phrase lands its note stays a while before the stub moves
  // on to what to watch for: long enough to be read.
  late final AnimationController _settle =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2800),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _active = null);
        }
      });

  bool _started = false;
  bool _calm = false;
  bool _reader = false;

  // The body's measured type size, kept per box: it is fitted once to every
  // reading the sheet can show, so translating never changes the size.
  Size? _fittedFor;
  double _bodySize = 16;

  /// The last laid-out body, for hit-testing and the reader's nodes.
  _TranslateBody? _body;

  TranslateScene get _s => widget.scene;
  int get _done => _plain.where((p) => p).length;
  bool get _finished => _done == _s.phrases.length;
  bool get _showWatch => _finished && _active == null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calm = MediaQuery.disableAnimationsOf(context);
    _reader = MediaQuery.accessibleNavigationOf(context);
    if (!_started && !_calm) {
      _started = true;
      _nudge.forward();
    }
  }

  /// A different card in the same place starts over.
  @override
  void didUpdateWidget(TranslateSceneView old) {
    super.didUpdateWidget(old);
    if (old.scene.raw != widget.scene.raw) {
      _reset();
      _fittedFor = null;
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    _nudge.dispose();
    _settle.dispose();
    _body?.dispose();
    super.dispose();
  }

  void _reset() {
    _flip.stop();
    _settle.stop();
    _settle.value = 0;
    _flip.value = 0;
    _plain = List.filled(_s.phrases.length, false);
    _active = null;
    _guess = null;
    _typing = null;
  }

  // ---- what a tap does ----

  void _tap(int i) {
    _nudge.stop();
    _settle.stop();
    if (!_plain[i]) {
      if (_typing != null) _landed();
      HapticFeedback.selectionClick();
      setState(() {
        if (_s.asksForGuess && _guess == null) _guess = i;
        _plain[i] = true;
        _active = i;
        _typing = i;
      });
      if (_calm) {
        _flip.value = 1;
        _landed();
      } else {
        _flip.forward(from: 0);
      }
      return;
    }
    HapticFeedback.selectionClick();
    if (_typing != null) {
      _flip.value = 1;
      _landed();
    }
    // On a finished sheet a second tap on the selected phrase lets go of it
    // and brings back the line to keep.
    setState(() => _active = _finished && _active == i ? null : i);
  }

  /// A flip has landed: the catch is felt as well as seen, and the last one
  /// starts the wait before the stub moves on.
  void _landed() {
    final i = _typing;
    if (i == null) return;
    _typing = null;
    if (_s.phrases[i].isCatch) HapticFeedback.lightImpact();
    if (_finished) {
      // A screen reader hears each note on its phrase; nothing moves on
      // under it by itself.
      if (_reader) {
        if (mounted) setState(() => _active = null);
      } else {
        _settle.forward(from: 0);
      }
    }
    if (mounted) setState(() {});
  }

  void _again() {
    HapticFeedback.selectionClick();
    setState(_reset);
  }

  int? _hit(Offset p) => _body?.hit(p);

  // ---- type ----

  TextStyle _printed(double s, Color c) => AppText.display(
    size: s,
    weight: FontWeight.w500,
    height: 1.42,
    spacing: -0.1,
    color: c,
  );

  /// The plain words: the app's own sans, a touch smaller so its larger
  /// x-height sits level with the serif, and the same line pitch.
  TextStyle _spoken(double s, Color c) => AppText.body(
    size: s * 0.93,
    weight: FontWeight.w700,
    height: 1.42 / 0.93,
    spacing: -0.1,
    color: c,
  );

  /// The document as it reads now, a phrase partly typed when it is the one
  /// flipping, and where each phrase sits in it.
  (TextSpan, List<TextRange>) _compose(
    double size, {
    required List<bool> plain,
    int? typing,
    double t = 1,
  }) {
    final ink = widget.ink;
    final spans = <InlineSpan>[];
    final ranges = List<TextRange>.filled(_s.phrases.length, TextRange.empty);
    var at = 0;
    for (final r in _s.runs) {
      if (r.phrase < 0) {
        spans.add(TextSpan(text: r.text));
        at += r.text.length;
        continue;
      }
      final p = _s.phrases[r.phrase];
      String text;
      TextStyle style;
      if (!plain[r.phrase] || (r.phrase == typing && t < _sweepEnd)) {
        text = p.text;
        style = _printed(size, ink);
      } else {
        final typed = r.phrase == typing
            ? Curves.easeOut.transform(
                ((t - _sweepEnd) / (0.9 - _sweepEnd)).clamp(0.0, 1.0),
              )
            : 1.0;
        text = p.plain.substring(0, (p.plain.length * typed).ceil());
        // The catch is printed reversed out of solid ink once it lands.
        final solid = p.isCatch ? _solidness(r.phrase, typing, t) : 0.0;
        style = _spoken(size, Color.lerp(ink, widget.ground, solid)!);
      }
      spans.add(TextSpan(text: text, style: style));
      ranges[r.phrase] = TextRange(start: at, end: at + text.length);
      at += text.length;
    }
    return (TextSpan(style: _printed(size, ink), children: spans), ranges);
  }

  /// How solid the catch's marker is: pale while it is typed, solid as the
  /// flip ends.
  double _solidness(int i, int? typing, double t) {
    if (i != typing) return 1;
    return Curves.easeOut.transform(((t - 0.86) / 0.14).clamp(0.0, 1.0));
  }

  /// The largest size at which every reading of the sheet fits [box]: all
  /// jargon, all plain, and each mixture between, so no tap can push the
  /// text out of its sheet.
  double _fit(Size box, double max) {
    final n = _s.phrases.length;
    bool fits(double size) {
      for (var mask = 0; mask < 1 << n; mask++) {
        final plain = [for (var i = 0; i < n; i++) mask & (1 << i) != 0];
        final tp = TextPainter(
          text: _compose(size, plain: plain).$1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: box.width);
        final h = tp.height;
        tp.dispose();
        if (h > box.height) return false;
      }
      return true;
    }

    var lo = 11.5, hi = max;
    if (fits(hi)) return hi;
    if (!fits(lo)) return lo;
    for (var k = 0; k < 7; k++) {
      final mid = (lo + hi) / 2;
      if (fits(mid)) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (lo * 2).floorToDouble() / 2;
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final big = box.maxHeight >= 420;
        final roomy = box.maxHeight >= 320;
        final padX = big ? 20.0 : 16.0;
        final inner = box.maxWidth - padX * 2;
        final stub = _stubHeight(context, inner, big, box.maxHeight);
        final paper = Color.lerp(widget.ground, widget.ink, 0.05)!;
        return Semantics(
          container: true,
          child: GestureDetector(
            // While there is something left to translate a tap on the sheet
            // is the scene's, so a near miss does not turn the card over.
            behavior: HitTestBehavior.opaque,
            onTap: _finished ? null : () {},
            child: CustomPaint(
              painter: _TranslatePaperPainter(
                ink: widget.ink,
                ground: widget.ground,
                paper: paper,
                stub: stub,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  padX,
                  big ? 16 : 12,
                  padX,
                  _TranslatePaperPainter.edge,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _letterhead(big),
                    if (_s.title.isNotEmpty && roomy) ...[
                      SizedBox(height: big ? 14 : 10),
                      Text(
                        _s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.display(
                          size: big ? 23 : 19,
                          weight: FontWeight.w800,
                          height: 1.1,
                          spacing: -0.4,
                          color: widget.ink,
                        ),
                      ),
                    ],
                    SizedBox(height: big ? 12 : 8),
                    Expanded(child: _sheet(big, paper)),
                    SizedBox(height: stub, child: _stub(context, big)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _letterhead(bool big) {
    final ink = widget.ink;
    final size = big ? 11.5 : 10.5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                _s.head.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: AppText.label(
                  size: size,
                  weight: FontWeight.w800,
                  spacing: 1.6,
                  color: ink,
                ),
              ),
            ),
            if (_s.ref.isNotEmpty) ...[
              const SizedBox(width: 10),
              Text(
                _s.ref,
                style: AppText.body(
                  size: size + 0.5,
                  weight: FontWeight.w600,
                  color: ink.withValues(alpha: 0.62),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        // A letterhead's double rule: one heavy, one hairline under it.
        Container(height: 2, color: ink),
        const SizedBox(height: 2.5),
        Container(height: 0.8, color: ink.withValues(alpha: 0.55)),
      ],
    );
  }

  /// The text of the sheet, painted and hit-tested from one layout.
  Widget _sheet(bool big, Color paper) {
    return LayoutBuilder(
      builder: (context, box) {
        final room = Size(box.maxWidth, box.maxHeight - (big ? 18 : 12));
        if (_fittedFor != room) {
          _fittedFor = room;
          _bodySize = _fit(room, big ? 26 : 21);
        }
        return AnimatedBuilder(
          animation: Listenable.merge([_flip, _nudge]),
          builder: (context, _) {
            final body = _layout(room.width, paper);
            final old = _body;
            _body = body;
            // The previous layout is let go after this frame has painted.
            if (old != null) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => old.dispose(),
              );
            }
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Semantics(
                  container: true,
                  label: _s.reading({
                    for (var i = 0; i < _plain.length; i++)
                      if (_plain[i]) i,
                  }),
                  child: ExcludeSemantics(
                    child: GestureDetector(
                      // Only the phrases are claimed once the sheet is done;
                      // the painter says where they are.
                      behavior: HitTestBehavior.deferToChild,
                      onTapUp: (d) {
                        final i = _hit(d.localPosition);
                        if (i != null) _tap(i);
                      },
                      child: RepaintBoundary(
                        child: CustomPaint(
                          size: Size(room.width, box.maxHeight),
                          painter: _TranslateBodyPainter(
                            body: body,
                            claimAll: !_finished,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < _s.phrases.length; i++)
                  if (body.bounds[i] != Rect.zero)
                    Positioned.fromRect(
                      rect: body.bounds[i],
                      child: Semantics(
                        key: ValueKey('translate-phrase-$i'),
                        button: true,
                        selected: _active == i,
                        label: _plain[i]
                            ? '${_s.phrases[i].plain}. ${_s.phrases[i].why}'
                            : _s.phrases[i].text,
                        onTap: () => _tap(i),
                        child: const SizedBox.expand(),
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }

  /// Lays the body out as it reads at this frame and works out every mark:
  /// where each marker goes, how far the selection has swept, the caret.
  _TranslateBody _layout(double width, Color paper) {
    final t = _flip.value;
    final (span, ranges) = _compose(
      _bodySize,
      plain: _plain,
      typing: _typing,
      t: t,
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
      ..layout(maxWidth: width);
    final line = tp.preferredLineHeight;
    final marks = <_TranslateMark>[];
    final bounds = <Rect>[];
    for (var i = 0; i < _s.phrases.length; i++) {
      final r = ranges[i];
      final boxes = [
        for (final b in tp.getBoxesForSelection(
          TextSelection(baseOffset: r.start, extentOffset: r.end),
          boxHeightStyle: ui.BoxHeightStyle.max,
        ))
          _trim(b.toRect(), line),
      ];
      final flipping = i == _typing;
      final p = _s.phrases[i];
      Offset? caret;
      if (flipping && t >= _sweepEnd && t < 1) {
        final c = tp.getOffsetForCaret(TextPosition(offset: r.end), Rect.zero);
        caret = c;
      }
      // Each marker brightens once, in turn, as the card arrives.
      final local = ((_nudge.value - 0.2 - i * 0.14) / 0.36).clamp(0.0, 1.0);
      final pulse = _nudge.isAnimating ? math.sin(local * math.pi) : 0.0;
      double band;
      if (!_plain[i]) {
        band = 0.13 + 0.2 * pulse;
      } else if (p.isCatch) {
        band = 0.3 + 0.7 * _solidness(i, _typing, t);
      } else {
        band = flipping
            ? 0.3 - 0.16 * ((t - 0.86) / 0.14).clamp(0.0, 1.0)
            : 0.14;
      }
      marks.add(
        _TranslateMark(
          boxes: boxes,
          band: band,
          sweep: flipping && t < _sweepEnd ? t / _sweepEnd : 0,
          dotted: !_plain[i] || (flipping && t < _sweepEnd),
          selected: _active == i,
          handles: _active == i
              ? (flipping
                    ? Curves.easeOutBack.transform(math.min(1, t * 4))
                    : 1)
              : 0,
          caret: caret,
        ),
      );
      // The reader's node sits on the phrase's first line, where it starts:
      // an outline round every line would take in words that are not it.
      bounds.add(boxes.isEmpty ? Rect.zero : boxes.first);
    }
    return _TranslateBody(
      text: tp,
      marks: marks,
      bounds: bounds,
      line: line,
      ink: widget.ink,
      paper: paper,
    );
  }

  /// A selection box is the whole line, leading and all; a marker sits on
  /// the letters, so the box loses some of its height above and below.
  static Rect _trim(Rect r, double line) => Rect.fromLTRB(
    r.left - 2,
    r.top + line * 0.1,
    r.right + 2,
    r.bottom - line * 0.06,
  );

  // ---- the stub ----

  TextStyle _noteStyle(bool big) => AppText.body(
    size: big ? 16 : 14.5,
    weight: FontWeight.w500,
    height: 1.34,
    color: widget.ink.withValues(alpha: 0.92),
  );

  TextStyle _lineStyle(bool big) => AppText.display(
    size: big ? 20 : 17,
    weight: FontWeight.w700,
    height: 1.18,
    spacing: -0.3,
    color: widget.ink,
  );

  /// Tall enough for the longest thing the stub will ever say, measured,
  /// so it never jumps between states.
  double _stubHeight(BuildContext context, double width, bool big, double h) {
    double measure(String text, TextStyle style) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 3,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: width);
      final out = tp.height;
      tp.dispose();
      return out;
    }

    var most = math.max(
      measure(_s.ask, _lineStyle(big)),
      measure(_s.watch, _lineStyle(big)),
    );
    for (final p in _s.phrases) {
      most = math.max(most, measure(p.why, _noteStyle(big)));
    }
    const label = 18.0;
    final top = big ? 20.0 : 16.0;
    return (top + label + 6 + most + (big ? 14 : 10)).clamp(0.0, h * 0.44);
  }

  Widget _stub(BuildContext context, bool big) {
    final l = context.l10n;
    final ink = widget.ink;
    final n = _s.phrases.length;
    final small = AppText.label(
      size: big ? 11 : 10.5,
      color: ink.withValues(alpha: 0.62),
    );
    final strong = small.copyWith(color: ink, fontWeight: FontWeight.w800);

    String key;
    Widget left;
    Widget right;
    Widget main;
    if (_showWatch) {
      key = 'watch';
      final g = _guess;
      left = g == null
          ? Text(l.sceneNOfM(n, n).toUpperCase(), style: strong)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    l.sceneYourGuess.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: strong,
                  ),
                ),
                const SizedBox(width: 6),
                _TranslateVerdict(
                  right: g == _s.catchIndex,
                  ink: ink,
                  ground: widget.ground,
                ),
              ],
            );
      right = Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _again,
          child: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              l.sceneTryAgain,
              style:
                  AppText.body(
                    size: big ? 14 : 13,
                    weight: FontWeight.w700,
                    color: ink,
                  ).copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: ink.withValues(alpha: 0.5),
                  ),
            ),
          ),
        ),
      );
      main = Text(
        _s.watch,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: _lineStyle(big),
      );
    } else if (_active case final i?) {
      key = 'p$i';
      final p = _s.phrases[i];
      left = Text(
        '“${p.text}”'.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: small,
      );
      right = Text(l.sceneNOfM(_done, n).toUpperCase(), style: strong);
      main = Text(
        p.why,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: _noteStyle(big),
      );
    } else {
      key = 'ask';
      left = Text(
        (_s.asksForGuess ? l.sceneTapToPick : l.sceneNOfM(0, n)).toUpperCase(),
        style: strong,
      );
      right = _s.asksForGuess
          ? Text(l.sceneNOfM(0, n).toUpperCase(), style: small)
          : const SizedBox.shrink();
      main = Text(
        _s.ask,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: _lineStyle(big),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: big ? 20 : 16),
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: _calm ? 0 : 280),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topLeft,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, .18),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        child: Column(
          key: ValueKey(key),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 18,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Align(alignment: Alignment.centerLeft, child: left),
                  ),
                  const SizedBox(width: 10),
                  right,
                ],
              ),
            ),
            const SizedBox(height: 6),
            Semantics(liveRegion: true, child: main),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────── the pieces ─────────────────────────────────

/// How a phrase is marked at one frame.
class _TranslateMark {
  /// Its letters, one rectangle per line it runs over.
  final List<Rect> boxes;

  /// The marker's strength: pale on jargon, solid on the catch.
  final double band;

  /// How far the selection has swept across the jargon, 0 to 1.
  final double sweep;

  /// A dotted rule under jargon still to be translated.
  final bool dotted;

  /// Under the editor's selection: an outline, and handles grown by [handles].
  final bool selected;
  final double handles;

  /// Where the typing has got to, while it types.
  final Offset? caret;

  const _TranslateMark({
    required this.boxes,
    required this.band,
    required this.sweep,
    required this.dotted,
    required this.selected,
    required this.handles,
    required this.caret,
  });
}

/// One frame of the body: its laid-out text and every mark on it. The
/// painter draws it and the tap is tested against it, so the two agree to
/// the pixel.
class _TranslateBody {
  final TextPainter text;
  final List<_TranslateMark> marks;

  /// Each phrase's first line, for the screen reader's nodes.
  final List<Rect> bounds;
  final double line;
  final Color ink;
  final Color paper;

  _TranslateBody({
    required this.text,
    required this.marks,
    required this.bounds,
    required this.line,
    required this.ink,
    required this.paper,
  });

  /// The phrase under [p], or the nearest one within reach of a thumb: a
  /// line of text is shorter than a fingertip, so each line of a phrase is
  /// a target as tall as 44 points, and between two the nearer wins.
  int? hit(Offset p) {
    final reach = math.max(8.0, (44 - line) / 2);
    int? best;
    var bestD = double.infinity;
    for (var i = 0; i < marks.length; i++) {
      for (final b in marks[i].boxes) {
        if (!b.inflate(reach).contains(p)) continue;
        final dx = math.max(0.0, math.max(b.left - p.dx, p.dx - b.right));
        final dy = math.max(0.0, math.max(b.top - p.dy, p.dy - b.bottom));
        final d = dx * dx + dy * dy;
        if (d < bestD) {
          bestD = d;
          best = i;
        }
      }
    }
    return best;
  }

  void dispose() => text.dispose();
}

class _TranslateBodyPainter extends CustomPainter {
  final _TranslateBody body;

  /// While the sheet is unfinished every tap on it is the scene's; after,
  /// only taps on phrases are, and the rest turn the card over.
  final bool claimAll;

  _TranslateBodyPainter({required this.body, required this.claimAll});

  final Paint _fill = Paint();
  final Paint _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = body.ink;

    // Markers under the letters.
    for (final m in body.marks) {
      final r = Radius.circular(math.min(4, body.line * 0.16));
      _fill.color = ink.withValues(alpha: m.band.clamp(0.0, 1.0));
      for (final b in m.boxes) {
        canvas.drawRRect(RRect.fromRectAndRadius(b, r), _fill);
      }
      // The selection sweeps across the jargon in reading order.
      if (m.sweep > 0) {
        final total = m.boxes.fold(0.0, (a, b) => a + b.width);
        var left = total * Curves.easeInOut.transform(m.sweep);
        _fill.color = ink.withValues(alpha: 0.3);
        for (final b in m.boxes) {
          if (left <= 0) break;
          final w = math.min(left, b.width);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(b.left, b.top, w, b.height),
              r,
            ),
            _fill,
          );
          left -= w;
        }
      }
    }

    body.text.paint(canvas, Offset.zero);

    for (final m in body.marks) {
      if (m.dotted) {
        _fill.color = ink.withValues(alpha: 0.6);
        for (final b in m.boxes) {
          final y = b.bottom - 1.2;
          for (var x = b.left + 2; x < b.right - 2; x += 4.5) {
            canvas.drawCircle(Offset(x, y), 0.95, _fill);
          }
        }
      }
      if (m.caret case final c?) {
        _fill.color = ink;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              c.dx + 1,
              c.dy + body.line * 0.12,
              2,
              body.line * 0.78,
            ),
            const Radius.circular(1),
          ),
          _fill,
        );
      }
      if (m.selected && m.boxes.isNotEmpty) _selection(canvas, m);
    }
  }

  /// The editor's selection: a thin outline round each line of the phrase,
  /// and a round handle on a short stem at its start and at its end.
  void _selection(Canvas canvas, _TranslateMark m) {
    final ink = body.ink;
    _line
      ..color = ink
      ..strokeWidth = 1.4;
    for (final b in m.boxes) {
      canvas.drawRect(b.inflate(1.5), _line);
    }
    final k = m.handles;
    if (k <= 0) return;
    final first = m.boxes.first.inflate(1.5);
    final last = m.boxes.last.inflate(1.5);
    void handle(Offset at, Offset stem) {
      final tip = at + stem * k;
      _line.strokeWidth = 1.6;
      canvas.drawLine(at, tip, _line);
      _fill.color = body.paper;
      canvas.drawCircle(tip, 5 * k, _fill);
      _fill.color = ink;
      canvas.drawCircle(tip, 3.8 * k, _fill);
    }

    handle(first.topLeft, const Offset(-1.5, -1.5));
    handle(last.bottomRight, const Offset(1.5, 1.5));
  }

  @override
  bool? hitTest(Offset position) => claimAll || body.hit(position) != null;

  @override
  bool shouldRepaint(_TranslateBodyPainter old) =>
      old.body != body || old.claimAll != claimAll;
}

/// The sheet: a paper a shade off the card, an ink frame, the ink edge every
/// Astute surface stands on, and a perforation across the foot with a notch
/// bitten out of each side, where the stub tears off.
class _TranslatePaperPainter extends CustomPainter {
  static const double edge = 5;

  final Color ink;
  final Color ground;
  final Color paper;

  /// How tall the stub under the perforation is.
  final double stub;

  _TranslatePaperPainter({
    required this.ink,
    required this.ground,
    required this.paper,
    required this.stub,
  });

  final Paint _fill = Paint();
  final Paint _stroke = Paint()..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    const r = Radius.circular(12);
    final sheet = Rect.fromLTWH(0, 0, size.width, size.height - edge);

    // Shadow, then the ink edge under the sheet, then the sheet.
    _fill
      ..color = const Color(0x2E000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(sheet.shift(const Offset(0, 9)), r),
      _fill,
    );
    _fill.maskFilter = null;
    _fill.color = ink;
    canvas.drawRRect(
      RRect.fromRectAndRadius(sheet.shift(const Offset(0, edge)), r),
      _fill,
    );
    _fill.color = paper;
    canvas.drawRRect(RRect.fromRectAndRadius(sheet, r), _fill);
    _stroke
      ..color = ink
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(sheet.deflate(1), r), _stroke);

    // The perforation: a notch on each edge and a row of short dashes.
    final y = sheet.bottom - stub;
    const notch = 8.0;
    // Bitten out of the sheet only: the notch must not cover the shadow
    // that falls on the card beside it.
    canvas.save();
    canvas.clipRect(sheet);
    for (final x in [sheet.left, sheet.right]) {
      final c = Offset(x, y);
      _fill.color = ground;
      canvas.drawCircle(c, notch + 1, _fill);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: notch),
        x == sheet.left ? -math.pi / 2 : math.pi / 2,
        math.pi,
        false,
        _stroke,
      );
    }
    canvas.restore();
    _stroke
      ..color = ink.withValues(alpha: 0.45)
      ..strokeWidth = 1.5;
    const dash = 5.0, gap = 4.0;
    for (var x = notch + 6; x < size.width - notch - 6; x += dash + gap) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dash, size.width - notch - 6), y),
        _stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_TranslatePaperPainter old) =>
      old.ink != ink ||
      old.ground != ground ||
      old.paper != paper ||
      old.stub != stub;
}

/// A tick in a ring when the guess was right, a cross when it was not.
class _TranslateVerdict extends StatelessWidget {
  final bool right;
  final Color ink;
  final Color ground;
  const _TranslateVerdict({
    required this.right,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 16,
    child: CustomPaint(
      painter: _TranslateVerdictPainter(right: right, ink: ink, ground: ground),
    ),
  );
}

class _TranslateVerdictPainter extends CustomPainter {
  final bool right;
  final Color ink;
  final Color ground;
  _TranslateVerdictPainter({
    required this.right,
    required this.ink,
    required this.ground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r, Paint()..color = ink);
    final p = Paint()
      ..color = ground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (right) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - r * 0.42, c.dy + r * 0.02)
          ..lineTo(c.dx - r * 0.1, c.dy + r * 0.34)
          ..lineTo(c.dx + r * 0.46, c.dy - r * 0.3),
        p,
      );
    } else {
      final d = r * 0.34;
      canvas.drawLine(c + Offset(-d, -d), c + Offset(d, d), p);
      canvas.drawLine(c + Offset(d, -d), c + Offset(-d, d), p);
    }
  }

  @override
  bool shouldRepaint(_TranslateVerdictPainter old) =>
      old.right != right || old.ink != ink || old.ground != ground;
}
