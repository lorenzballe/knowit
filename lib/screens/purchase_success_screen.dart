import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../theme.dart';

/// The screen after the store's purchase sheet closes — design 129a,
/// "check → plus → logo", carried over as it was drawn.
///
/// One continuous take. The logo's two cards draw the check while the ring
/// closes; confetti and a pulse land on the moment the purchase is
/// confirmed. Then the check turns into the plus of Astute+, and the plus
/// opens into the logo: the A settles on top and three more cards fan out,
/// one for each thing that just opened below. The seal stays on the ring;
/// the plan rises from the bottom; one button to begin.
///
/// Everything runs off a single clock, in seconds since the screen opened,
/// with the design's own delays, durations and curves.
class PurchaseSuccessScreen extends StatefulWidget {
  /// The reader's first name, or null when the app does not know it.
  final String? firstName;

  /// "Astute+ Yearly" or "Astute+ Monthly", already worded.
  final String planName;

  /// What the plan does next, in one line: free until when, or when it
  /// renews and for how much.
  final String planLine;

  /// The small line under the button.
  final String foot;

  /// Where "Receipt" goes, if anywhere.
  final VoidCallback? onReceipt;

  const PurchaseSuccessScreen({
    super.key,
    required this.firstName,
    required this.planName,
    required this.planLine,
    required this.foot,
    this.onReceipt,
  });

  @override
  State<PurchaseSuccessScreen> createState() => _PurchaseSuccessScreenState();
}

// The design's curves.
const Curve _ease = Cubic(.25, .1, .25, 1);
const Curve _easeOut = Cubic(0, 0, .58, 1);
const Curve _easeInOut = Cubic(.42, 0, .58, 1);
const Curve _up = Cubic(.2, .8, .2, 1);
const Curve _wave = Cubic(.2, .7, .3, 1);
const Curve _bump = Cubic(.3, 0, .3, 1);

double _c01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

/// How far a CSS animation with `both` fill has got at time [t].
double _prog(double t, double delay, double dur) => _c01((t - delay) / dur);

/// A value through keyframes `[offset, value]`, each segment eased by
/// [curve] as CSS does.
double _keys(double p, List<List<double>> k, [Curve curve = Curves.linear]) {
  if (p <= k.first[0]) return k.first[1];
  for (int i = 0; i < k.length - 1; i++) {
    final a = k[i], b = k[i + 1];
    if (p <= b[0]) {
      final double span = b[0] - a[0];
      final double u = span <= 0 ? 1 : curve.transform(_c01((p - a[0]) / span));
      return a[1] + (b[1] - a[1]) * u;
    }
  }
  return k.last[1];
}

class _PurchaseSuccessScreenState extends State<PurchaseSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);
  ui.Image? _imgA;
  ui.Image? _imgM;
  late final List<_Piece> _confetti = _Piece.burst(40);
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _t.value = elapsed.inMicroseconds / 1e6;
    })..start();
    _load('assets/brand/success-a.png').then((im) {
      if (mounted) setState(() => _imgA = im);
    });
    _load('assets/brand/success-mark.png').then((im) {
      if (mounted) setState(() => _imgM = im);
    });
  }

  static Future<ui.Image?> _load(String asset) async {
    try {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      return (await codec.getNextFrame()).image;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  void _start() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bool still = MediaQuery.disableAnimationsOf(context);
    final EdgeInsets pad = MediaQuery.viewPaddingOf(context);
    final String? first = widget.firstName;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: ValueListenableBuilder<double>(
          valueListenable: _t,
          builder: (context, raw, _) {
            // With motion turned off the screen opens on its last frame.
            final double t = still ? 8 : raw;
            return LayoutBuilder(
              builder: (context, box) {
                // The hero is 340 on a 874-tall phone; a shorter one gives
                // up some of it rather than scroll.
                final double rest = _rest(context, box, pad);
                final double hero = (box.maxHeight - rest).clamp(150.0, 340.0);
                // The space above the plan: whatever the hero and everything
                // under it leave over. Nothing flexes, so if a measurement is
                // off the screen scrolls a little instead of overflowing.
                final double room = math.max(0, box.maxHeight - rest - hero);
                final double heroTop = math.max(pad.top, 20) + 16;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // The glow sits 50 below the hero's centre, as drawn.
                    Positioned(
                      left: box.maxWidth / 2 - 310,
                      top: heroTop + hero / 2 - 190,
                      width: 620,
                      height: 480,
                      child: IgnorePointer(child: _Bloom(t: t)),
                    ),
                    // One screen, no scrolling — unless a long language on a
                    // short phone needs more than it has, which scrolls
                    // rather than overflows.
                    SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        22,
                        math.max(pad.top, 20) + 6,
                        22,
                        math.max(pad.bottom, 12) + 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          SizedBox(
                            height: hero,
                            child: Center(
                              child: FittedBox(
                                clipBehavior: Clip.none,
                                child: _Hero(
                                  t: t,
                                  imgA: _imgA,
                                  imgM: _imgM,
                                  confetti: _confetti,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _rise(
                            t,
                            1.15,
                            .7,
                            18,
                            _up,
                            Text(
                              l.purchaseComplete,
                              textAlign: TextAlign.center,
                              style: AppText.display(
                                size: 40,
                                height: 1.04,
                                spacing: -1.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _rise(
                            t,
                            1.25,
                            .7,
                            18,
                            _up,
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 320,
                                ),
                                child: Text(
                                  first == null
                                      ? l.successWelcome
                                      : l.successWelcomeNamed(first),
                                  textAlign: TextAlign.center,
                                  style: AppText.body(
                                    size: 17,
                                    height: 1.45,
                                    color: Colors.white.withValues(alpha: .6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _tile(
                                t,
                                2.95,
                                const Color(0xFF00D9D9),
                                l.successFiveCards,
                              ),
                              const SizedBox(width: 8),
                              _tile(
                                t,
                                3.1,
                                const Color(0xFF00D451),
                                l.yourJourney,
                              ),
                              const SizedBox(width: 8),
                              _tile(
                                t,
                                3.25,
                                const Color(0xFFFFE600),
                                l.successArchive,
                              ),
                            ],
                          ),
                          SizedBox(height: room),
                          _rise(
                            t,
                            3.3,
                            .8,
                            80,
                            const Cubic(.18, 1.2, .4, 1),
                            _plan(l),
                          ),
                          const SizedBox(height: 14),
                          _rise(t, 3.45, .7, 18, _up, _button(l)),
                          Opacity(
                            opacity: _easeOut.transform(_prog(t, 3.6, .7)),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                widget.foot,
                                textAlign: TextAlign.center,
                                style: AppText.body(
                                  size: 12.5,
                                  weight: FontWeight.w500,
                                  height: 1.4,
                                  color: Colors.white.withValues(alpha: .5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// How tall everything under the hero is, measured in this language at
  /// this width: the hero is 340 when the rest leaves room for it, and gives
  /// up what it must on a shorter phone or under a longer title.
  double _rest(BuildContext context, BoxConstraints box, EdgeInsets pad) {
    final l = context.l10n;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double width = box.maxWidth - 44;
    double measure(String text, TextStyle style, double maxWidth) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout(maxWidth: maxWidth);
      final double h = painter.height;
      painter.dispose();
      return h;
    }

    final String? first = widget.firstName;
    final double title = measure(
      l.purchaseComplete,
      AppText.display(size: 40, height: 1.04, spacing: -1.5),
      width,
    );
    final double sub = measure(
      first == null ? l.successWelcome : l.successWelcomeNamed(first),
      AppText.body(size: 17, height: 1.45),
      math.min(320, width),
    );
    final TextStyle tileStyle = AppText.body(
      size: 13,
      weight: FontWeight.w600,
      height: 1.2,
    );
    final double tileWidth = (width - 16) / 3 - 14;
    final double tile =
        13 +
        19 +
        10 +
        12 +
        2 +
        [
          l.successFiveCards,
          l.yourJourney,
          l.successArchive,
        ].map((s) => measure(s, tileStyle, tileWidth)).reduce(math.max);
    final double foot =
        16 +
        measure(
          widget.foot,
          AppText.body(size: 12.5, weight: FontWeight.w500, height: 1.4),
          width,
        );
    const double plan = 66, button = 60, gaps = 10 + 14 + 12 + 20 + 14;
    return math.max(pad.top, 20) +
        6 +
        math.max(pad.bottom, 12) +
        8 +
        title +
        sub +
        tile +
        plan +
        button +
        foot +
        gaps;
  }

  /// suUp / suRise: up from [dy] below, fading in.
  Widget _rise(
    double t,
    double delay,
    double dur,
    double dy,
    Curve curve,
    Widget child,
  ) {
    final double p = _prog(t, delay, dur);
    final double k = curve.transform(p);
    return Opacity(
      opacity: _c01(k),
      child: Transform.translate(offset: Offset(0, dy * (1 - k)), child: child),
    );
  }

  Widget _tile(double t, double delay, Color color, String label) {
    return Expanded(
      child: _rise(
        t,
        delay,
        .6,
        18,
        _up,
        Container(
          padding: const EdgeInsets.fromLTRB(6, 13, 6, 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .055),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
          ),
          child: Column(
            children: [
              Transform.rotate(
                angle: -8 * math.pi / 180,
                child: Container(
                  width: 13,
                  height: 19,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w600,
                  height: 1.2,
                  color: Colors.white.withValues(alpha: .88),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _plan(AppLocalizations l) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: .1)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/brand/success-icon.png',
                  width: 40,
                  height: 40,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.planName,
                      style: AppText.body(
                        size: 15,
                        weight: FontWeight.w600,
                        height: 1.1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.planLine,
                      style: AppText.body(
                        size: 12.5,
                        height: 1.3,
                        color: Colors.white.withValues(alpha: .62),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onReceipt,
                child: Text(
                  '${l.successReceipt} ›',
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w600,
                    height: 1,
                    color: Colors.white.withValues(alpha: .7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(AppLocalizations l) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: _start,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          height: 60,
          transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
          decoration: BoxDecoration(
            color: const Color(0xFFF1EFEA),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA8A59D),
                offset: Offset(0, _pressed ? 2 : 5),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: .45),
                offset: Offset(0, _pressed ? 10 : 16),
                blurRadius: _pressed ? 24 : 34,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            l.letsStart,
            style: AppText.body(
              size: 16.5,
              weight: FontWeight.w700,
              height: 1,
              spacing: .3,
              color: const Color(0xFF111113),
            ),
          ),
        ),
      ),
    );
  }
}

/// The coloured glow behind the hero: four soft blobs, blooming in at one
/// second and drifting slowly after three.
class _Bloom extends StatelessWidget {
  final double t;
  const _Bloom({required this.t});

  @override
  Widget build(BuildContext context) {
    final double p = _prog(t, 1, 2.4);
    final double opacity = _keys(p, [
      [0, 0],
      [.4, 1],
      [1, .8],
    ], _easeOut);
    final double scale = _keys(p, [
      [0, .6],
      [1, 1],
    ], _easeOut);
    double dx = 0, dy = 0;
    if (t > 3) {
      final double q = ((t - 3) % 14) / 14;
      final double k = _keys(q, [
        [0, 0],
        [.5, 1],
        [1, 0],
      ], _easeInOut);
      dx = 14 * k;
      dy = -10 * k;
    }
    return Opacity(
      opacity: _c01(opacity),
      child: Transform.scale(
        scale: scale,
        child: Transform.translate(
          offset: Offset(dx, dy),
          child: const CustomPaint(painter: _BloomPainter()),
        ),
      ),
    );
  }
}

class _BloomPainter extends CustomPainter {
  const _BloomPainter();

  static const _blobs = <(Rect, Color)>[
    (Rect.fromLTWH(150, 130, 200, 180), Color.fromRGBO(255, 31, 160, .22)),
    (Rect.fromLTWH(300, 100, 210, 190), Color.fromRGBO(43, 75, 255, .26)),
    (Rect.fromLTWH(200, 270, 230, 150), Color.fromRGBO(0, 217, 217, .13)),
    (Rect.fromLTWH(330, 250, 170, 150), Color.fromRGBO(255, 230, 0, .1)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (rect, color) in _blobs) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(99)),
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 56),
      );
    }
  }

  @override
  bool shouldRepaint(_BloomPainter old) => false;
}

/// The 340 × 340 hero: the ring, its two pulses, the confetti, the cards
/// becoming the logo, and the seal.
class _Hero extends StatelessWidget {
  final double t;
  final ui.Image? imgA;
  final ui.Image? imgM;
  final List<_Piece> confetti;

  const _Hero({
    required this.t,
    required this.imgA,
    required this.imgM,
    required this.confetti,
  });

  @override
  Widget build(BuildContext context) {
    // suBump9: two small beats, on the check and on the logo.
    final double bump = _keys(_prog(t, 1, 1.5), [
      [0, 1],
      [.10, 1.045],
      [.37, 1],
      [.60, 1],
      [.70, 1.03],
      [1, 1],
    ], _bump);
    // suFloat: the logo breathes once it has settled.
    double float = 0;
    if (t > 4) {
      final double cycle = (t - 4) / 3.4;
      final double u = cycle % 1;
      final double k = _easeInOut.transform(cycle.floor().isEven ? u : 1 - u);
      float = -8 * k;
    }
    return SizedBox(
      width: 340,
      height: 340,
      child: Transform.scale(
        scale: bump,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _ConfettiPainter(t, confetti)),
            ),
            _waveRing(t, 1.05, Colors.white.withValues(alpha: .55)),
            _waveRing(t, 1.95, const Color.fromRGBO(139, 108, 255, .6)),
            Positioned.fill(child: CustomPaint(painter: _RingPainter(t))),
            Positioned(
              left: 10,
              top: 10,
              width: 320,
              height: 320,
              child: Transform.translate(
                offset: Offset(0, float),
                child: CustomPaint(painter: _LogoPainter(t, imgA, imgM)),
              ),
            ),
            Positioned(
              left: 253,
              top: 253,
              width: 60,
              height: 60,
              child: _Seal(t: t),
            ),
          ],
        ),
      ),
    );
  }

  /// suWave: a ring that swells past the circle and fades.
  Widget _waveRing(double t, double delay, Color color) {
    final double k = _wave.transform(_prog(t, delay, .9));
    final double opacity = _keys(k, [
      [0, 0],
      [.12, 1],
      [1, 0],
    ]);
    final double scale = _keys(k, [
      [0, 1],
      [1, 1.34],
    ]);
    return Positioned(
      left: 10,
      top: 10,
      width: 320,
      height: 320,
      child: Opacity(
        opacity: _c01(opacity),
        child: Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

/// The ring: a faint track, and the gradient stroke that draws itself
/// closed in under a second, then turns slowly for ever.
class _RingPainter extends CustomPainter {
  final double t;
  _RingPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const Offset c = Offset(170, 170);
    canvas.drawCircle(
      c,
      160,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: .07),
    );
    final double p = _prog(t, .2, .85);
    if (p <= 0) return;
    final double k = const Cubic(.6, 0, .2, 1).transform(p);
    final double opacity = _keys(p, [
      [0, 0],
      [.08, 1],
      [1, 1],
    ]);
    final double spin = t > 1.1 ? ((t - 1.1) / 16 % 1) * 2 * math.pi : 0;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(spin - math.pi / 2);
    // The gradient runs corner to corner of the circle's box, turned with
    // it: yellow, then teal, then violet.
    const Rect box = Rect.fromLTWH(-160, -160, 320, 320);
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFFE14D).withValues(alpha: opacity),
          const Color(0xFF2DE0D2).withValues(alpha: opacity),
          const Color(0xFF8B6CFF).withValues(alpha: opacity),
        ],
        stops: const [0, .55, 1],
      ).createShader(box);
    final double sweep =
        2 * math.pi * math.min(1, k * 1006 / (2 * math.pi * 160));
    if (sweep > 0.001) canvas.drawArc(box, 0, sweep, false, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}

/// The seal on the ring: it pops in with a turn, sends out one small
/// pulse, and its check draws itself.
class _Seal extends StatelessWidget {
  final double t;
  const _Seal({required this.t});

  @override
  Widget build(BuildContext context) {
    final double p = const Cubic(.2, .9, .3, 1.2).transform(_prog(t, 2.9, .7));
    final double opacity = _keys(p, [
      [0, 0],
      [.6, 1],
      [1, 1],
    ]);
    final double scale = _keys(p, [
      [0, .3],
      [.6, 1.12],
      [1, 1],
    ]);
    final double turn = _keys(p, [
      [0, -30],
      [.6, 6],
      [1, 0],
    ]);
    final double w = _wave.transform(_prog(t, 3.05, .8));
    final double wOpacity = _keys(w, [
      [0, 0],
      [.15, .9],
      [1, 0],
    ]);
    final double wScale = _keys(w, [
      [0, 1],
      [1, 1.9],
    ]);
    final double dash = _easeOut.transform(_prog(t, 3.15, .35));
    return Opacity(
      opacity: _c01(opacity),
      child: Transform.rotate(
        angle: turn * math.pi / 180,
        child: Transform.scale(
          scale: scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: _c01(wOpacity),
                  child: Transform.scale(
                    scale: wScale,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color.fromRGBO(241, 239, 234, .7),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  // CSS conic-gradient(from 200deg …): CSS starts at twelve
                  // o'clock, Flutter at three.
                  gradient: SweepGradient(
                    colors: [
                      Color(0xFFFFE14D),
                      Color(0xFF2DE0D2),
                      Color(0xFF8B6CFF),
                      Color(0xFFFF1FA0),
                      Color(0xFFFFE14D),
                    ],
                    transform: GradientRotation(110 * math.pi / 180),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, .55),
                      offset: Offset(0, 12),
                      blurRadius: 26,
                    ),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF1EFEA),
                  ),
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CustomPaint(painter: _CheckPainter(dash)),
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

class _CheckPainter extends CustomPainter {
  final double progress;
  _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    canvas.scale(size.width / 24);
    final Path path = Path()
      ..moveTo(5, 12.5)
      ..lineTo(9.5, 17)
      ..lineTo(19, 7.5);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF111113);
    // The path is 20 long against a dash of 21: drawn in proportion.
    final double total = path.computeMetrics().fold(
      0.0,
      (sum, m) => sum + m.length,
    );
    double left = math.max(0, total - 21 * (1 - progress));
    final Path drawn = Path();
    for (final m in path.computeMetrics()) {
      if (left <= 0) break;
      drawn.addPath(m.extractPath(0, math.min(left, m.length)), Offset.zero);
      left -= m.length;
    }
    canvas.drawPath(drawn, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

/// One bit of confetti, its flight fixed when the screen opens.
class _Piece {
  final double w, h, x, y, r0, r1, dur;
  final bool dot;
  final Color color;

  const _Piece(
    this.w,
    this.h,
    this.x,
    this.y,
    this.r0,
    this.r1,
    this.dur,
    this.dot,
    this.color,
  );

  static const _colors = [
    Color(0xFFFF1FA0),
    Color(0xFF2C4CFF),
    Color(0xFF00D9D9),
    Color(0xFF00D451),
    Color(0xFFFFE600),
    Color(0xFF9B5CFF),
    Color(0xFFF1EFEA),
  ];

  static List<_Piece> burst(int n) {
    final rnd = math.Random();
    return List.generate(n, (i) {
      final bool dot = i % 4 == 3;
      final double w = dot
          ? 5 + rnd.nextDouble() * 3
          : 6 + rnd.nextDouble() * 5;
      final double h = dot ? w : w * 1.45;
      final double a = (i / n) * math.pi * 2 + rnd.nextDouble() * 0.35;
      final double d = 120 + rnd.nextDouble() * 110;
      final double r0 = rnd.nextDouble() * 360;
      final double r1 =
          r0 +
          (rnd.nextDouble() < .5 ? -1 : 1) * (220 + rnd.nextDouble() * 320);
      return _Piece(
        w,
        h,
        math.cos(a) * d,
        math.sin(a) * d,
        r0,
        r1,
        1.6 + rnd.nextDouble() * .8,
        dot,
        _colors[i % _colors.length],
      );
    });
  }
}

/// The confetti, thrown from the centre at 1.05 s — the moment the purchase
/// is confirmed.
class _ConfettiPainter extends CustomPainter {
  final double t;
  final List<_Piece> pieces;
  _ConfettiPainter(this.t, this.pieces);

  static const Curve _fly = Cubic(.12, .7, .3, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final double since = t - 1.05;
    if (since <= 0) return;
    final Offset c = size.center(Offset.zero);
    for (final q in pieces) {
      final double raw = since / q.dur;
      if (raw >= 1) continue;
      final double p = _fly.transform(raw);
      final double opacity = _keys(p, [
        [0, 0],
        [.32, 1],
        [1, 0],
      ]);
      final double tx = _keys(p, [
        [0, 0],
        [.32, q.x * .62],
        [1, q.x],
      ]);
      final double ty = _keys(p, [
        [0, 0],
        [.32, q.y * .62],
        [1, q.y + 150],
      ]);
      final double rot = _keys(p, [
        [0, q.r0],
        [.32, (q.r0 + q.r1) / 2],
        [1, q.r1],
      ]);
      final double scale = _keys(p, [
        [0, .3],
        [.32, 1],
        [1, .85],
      ]);
      if (opacity <= 0) continue;
      canvas.save();
      canvas.translate(c.dx + tx, c.dy + ty);
      canvas.rotate(rot * math.pi / 180);
      canvas.scale(scale);
      final Rect r = Rect.fromCenter(
        center: Offset.zero,
        width: q.w,
        height: q.h,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(q.dot ? q.w / 2 : 2)),
        Paint()..color = q.color.withValues(alpha: _c01(opacity)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// The heart of 129a, drawn as the design draws it on its canvas, in the
/// icon's own 1024 space: the pink and blue cards draw the check, turn into
/// the plus, then open into the logo while three more cards fan out behind
/// the A.
class _LogoPainter extends CustomPainter {
  final double t;
  final ui.Image? imgA;
  final ui.Image? imgM;
  _LogoPainter(this.t, this.imgA, this.imgM);

  static const Curve _draw = Cubic(.45, 0, .2, 1);
  static const Curve _snap = Cubic(.5, 0, .2, 1.1);
  static const Curve _plus = Cubic(.6, 0, .25, 1.12);
  static const Curve _logo = Cubic(.6, 0, .2, 1.1);
  static const Curve _clip = Cubic(.4, 0, .2, 1);
  static const Curve _fan = Cubic(.3, 1.25, .45, 1);
  static const Curve _a = Cubic(.2, .8, .2, 1);
  static const Curve _lin = Curves.linear;

  // Where each card ends: measured from the real icon.
  static const _pl = {'x': 503.8, 'y': 633.0, 'a': 14.0, 'o': 1.0};
  static const _pli = {
    'l': -159.0,
    't': -354.2,
    'w': 300.0,
    'h': 454.1,
    'r': 83.5,
  };
  static const _bl = {'x': 549.2, 'y': 610.4, 'a': 30.0, 'o': 1.0};
  static const _bli = {
    'l': -159.0,
    't': -340.7,
    'w': 300.0,
    'h': 436.8,
    'r': 58.0,
  };

  static final List<(double, Map<String, double>, Curve?)> _pa = [
    (.15, {'x': 406, 'y': 678, 'a': -45, 'o': 0}, _ease),
    (.25, {'x': 406, 'y': 678, 'a': -45, 'o': 1}, _lin),
    (1.5, {'x': 406, 'y': 678, 'a': -45, 'o': 1}, _plus),
    (1.95, {'x': 512, 'y': 749, 'a': 0, 'o': 1}, _lin),
    (2.3, {'x': 512, 'y': 749, 'a': 0, 'o': 1}, _logo),
    (2.9, _pl, null),
  ];
  static final List<(double, Map<String, double>, Curve?)> _pi = [
    (.25, {'l': -115, 't': -295, 'w': 230, 'h': 230, 'r': 77}, _draw),
    (.55, {'l': -115, 't': -295, 'w': 230, 'h': 410, 'r': 77}, _lin),
    (1.5, {'l': -115, 't': -295, 'w': 230, 'h': 410, 'r': 77}, _plus),
    (1.95, {'l': -115, 't': -589, 'w': 230, 'h': 704, 'r': 77}, _lin),
    (2.3, {'l': -115, 't': -589, 'w': 230, 'h': 704, 'r': 77}, _logo),
    (2.9, _pli, null),
  ];
  static final List<(double, Map<String, double>, Curve?)> _ba = [
    (.5, {'x': 406, 'y': 678, 'a': 45, 'o': 0}, _lin),
    (.53, {'x': 406, 'y': 678, 'a': 45, 'o': 1}, _lin),
    (1.5, {'x': 406, 'y': 678, 'a': 45, 'o': 1}, _plus),
    (1.95, {'x': 275, 'y': 512, 'a': 90, 'o': 1}, _lin),
    (2.3, {'x': 275, 'y': 512, 'a': 90, 'o': 1}, _logo),
    (2.9, _bl, null),
  ];
  static final List<(double, Map<String, double>, Curve?)> _bi = [
    (.5, {'l': -115, 't': -115, 'w': 230, 'h': 230, 'r': 77}, _snap),
    (1.05, {'l': -115, 't': -589, 'w': 230, 'h': 704, 'r': 77}, _lin),
    (2.3, {'l': -115, 't': -589, 'w': 230, 'h': 704, 'r': 77}, _logo),
    (2.9, _bli, null),
  ];

  // The three new cards: colour, start, length, final angle.
  static const _fanCards = [
    (Color(0xFFFFE600), 3.15, 1.2, 72.0),
    (Color(0xFF00D451), 3.0, 1.1, 58.0),
    (Color(0xFF00D9D9), 2.85, 1.0, 44.0),
  ];
  static const double _cx0 = 318, _cx1 = 638.5;

  static Map<String, double> _at(
    List<(double, Map<String, double>, Curve?)> tr,
    double t,
  ) {
    if (t <= tr.first.$1) return tr.first.$2;
    for (int i = 0; i < tr.length - 1; i++) {
      final a = tr[i], b = tr[i + 1];
      if (t < b.$1) {
        final double k = a.$3!.transform(_c01((t - a.$1) / (b.$1 - a.$1)));
        return {
          for (final key in a.$2.keys)
            key: a.$2[key]! + (b.$2[key]! - a.$2[key]!) * k,
        };
      }
    }
    return tr.last.$2;
  }

  void _card(
    Canvas canvas,
    double x,
    double y,
    double a,
    double l,
    double tp,
    double w,
    double h,
    double r,
    Color col,
    double al,
  ) {
    if (al <= 0) return;
    r = math.max(0, math.min(r, math.min(w / 2, h / 2)));
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(a * math.pi / 180);
    canvas.drawRRect(
      RRect.fromLTRBR(l, tp, l + w, tp + h, Radius.circular(r)),
      Paint()..color = col.withValues(alpha: _c01(al)),
    );
    canvas.restore();
  }

  void _poly(Canvas canvas, double x0, double x1) {
    canvas.clipPath(
      Path()
        ..moveTo(x0, 0)
        ..lineTo(1024, 0)
        ..lineTo(1024, 1024)
        ..lineTo(x1, 1024)
        ..close(),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1024);
    const Rect full = Rect.fromLTWH(0, 0, 1024, 1024);

    canvas.save();
    _poly(canvas, _cx0, _cx1);
    for (final f in _fanCards) {
      final double p = _c01((t - f.$2) / f.$3);
      if (p <= 0) continue;
      _card(
        canvas,
        _bl['x']!,
        _bl['y']!,
        _bl['a']! + (f.$4 - _bl['a']!) * _fan.transform(p),
        _bli['l']!,
        _bli['t']!,
        _bli['w']!,
        _bli['h']!,
        _bli['r']!,
        f.$1,
        _c01(_fan.transform(_c01(p / .3))),
      );
    }
    canvas.restore();

    final double comp = imgM != null ? _a.transform(_c01((t - 2.95) / .2)) : 0;
    final double fade = comp < 1 ? 1 : 1 - _c01((t - 3.15) / .2);
    if (fade > 0) {
      canvas.save();
      final double c = _clip.transform(_c01((t - 2.55) / .35));
      if (c > 0) _poly(canvas, _cx0 * c, _cx1 * c);
      final ba = _at(_ba, t),
          bi = _at(_bi, t),
          pa = _at(_pa, t),
          pi = _at(_pi, t);
      _card(
        canvas,
        ba['x']!,
        ba['y']!,
        ba['a']!,
        bi['l']!,
        bi['t']!,
        bi['w']!,
        bi['h']!,
        bi['r']!,
        const Color(0xFF2B4BFF),
        ba['o']! * fade,
      );
      _card(
        canvas,
        pa['x']!,
        pa['y']!,
        pa['a']!,
        pi['l']!,
        pi['t']!,
        pi['w']!,
        pi['h']!,
        pi['r']!,
        const Color(0xFFFF1FA0),
        pa['o']! * fade,
      );
      canvas.restore();
    }
    final ui.Image? m = imgM;
    if (comp > 0 && m != null) {
      _image(canvas, m, full, comp);
    }
    final double k = _a.transform(_c01((t - 2.55) / .45));
    final ui.Image? a = imgA;
    if (k > 0 && comp < 1 && a != null) {
      canvas.save();
      canvas.translate(398, 511);
      final double s = .86 + .14 * k;
      canvas.scale(s, s);
      _image(canvas, a, const Rect.fromLTWH(-398, -511, 1024, 1024), k);
      canvas.restore();
    }
    canvas.restore();
  }

  void _image(Canvas canvas, ui.Image image, Rect dst, double alpha) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      Paint()
        ..filterQuality = FilterQuality.high
        ..color = Color.fromRGBO(0, 0, 0, _c01(alpha)),
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.t != t || old.imgA != imgA || old.imgM != imgM;
}
