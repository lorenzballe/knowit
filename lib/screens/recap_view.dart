import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/subject_icons.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/share_sheet.dart';
import 'deck_viewer_screen.dart';

/// The end of the day, from artboard 58a.
///
/// The day's five come back as the deck itself, fanned, and the whole screen
/// takes the colour of the card at the front — the wash behind, the streak
/// ring, the button and the chips all shift together. The subject chips sit
/// under the deck and drive it. Nothing here asks you to perform a line: the
/// point of the app is sharper thinking, so the footer counts what you have
/// actually worked through.
class RecapView extends StatefulWidget {
  final AppState app;
  const RecapView({super.key, required this.app});

  @override
  State<RecapView> createState() => _RecapViewState();
}

class _RecapViewState extends State<RecapView> {
  /// Which of the five is at the front. The middle one, so the fan opens
  /// both ways.
  late int _at = widget.app.todaysDeck.length ~/ 2;

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final deck = app.todaysDeck;
    if (deck.isEmpty) return const SizedBox.shrink();
    final int at = _at.clamp(0, deck.length - 1);
    final Pill front = deck[at];
    final int daysDone = app.weekCompletion().where((d) => d).length;

    return Stack(
      children: [
        Positioned.fill(child: _Wash(colour: front.color)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            _StreakHead(
              streak: app.streak,
              daysDone: daysDone,
              colour: front.color,
            ),
            const SizedBox(height: 24),
            Text(
              "TODAY'S ${_spelt(deck.length)} · ALL READ",
              style: AppText.label(
                size: 10.5,
                spacing: 1.6,
                color: context.p.ink.withValues(alpha: 0.38),
              ),
            ),
            Expanded(
              child: _Fan(
                deck: deck,
                at: at,
                onPick: (i) => setState(() => _at = i),
                onOpen: (i) => openDeckViewer(
                  context,
                  app,
                  deck,
                  "Today's five",
                  initialIndex: i,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Chips(deck: deck, at: at, onPick: (i) => setState(() => _at = i)),
            const SizedBox(height: 18),
            _Actions(app: app, deck: deck, front: front),
            const SizedBox(height: 15),
            _Footer(worked: app.seenIds.length),
            const SizedBox(height: 6),
          ],
        ),
      ],
    );
  }

  static const _numbers = [
    'NONE',
    'ONE',
    'TWO',
    'THREE',
    'FOUR',
    'FIVE',
    'SIX',
    'SEVEN',
    'EIGHT',
    'NINE',
    'TEN',
  ];
  static String _spelt(int n) => n < _numbers.length ? _numbers[n] : '$n';
}

/// The screen's own colour: the front card's, as an ellipse of light from
/// the top, falling to black by three quarters of the way down.
class _Wash extends StatelessWidget {
  const _Wash({required this.colour});

  final Color colour;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          // radial-gradient(125% 58% at 50% 6%): a circle drawn at 125% of
          // the width, squashed to 58% of the height, centred near the top.
          final double w = box.maxWidth;
          final double h = box.maxHeight;
          return OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            alignment: Alignment.topCenter,
            child: Transform.translate(
              offset: Offset(0, h * 0.06 - w * 1.25 * 0.58 / 2 * 0.0),
              child: Transform.scale(
                scaleY: (h * 0.58) / (w * 1.25),
                alignment: Alignment.topCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.easeOut,
                  width: w * 1.25 * 2,
                  height: w * 1.25 * 2,
                  transform: Matrix4.translationValues(0, -w * 1.25, 0),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        colour.withValues(alpha: 0.40),
                        colour.withValues(alpha: 0.12),
                        Colors.black,
                      ],
                      stops: const [0, 0.42, 0.78],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The streak as a ring closing on the week, in the day's colour.
class _StreakHead extends StatelessWidget {
  const _StreakHead({
    required this.streak,
    required this.daysDone,
    required this.colour,
  });

  final int streak;
  final int daysDone;
  final Color colour;

  static const _words = [
    '',
    'One day',
    'Two days',
    'Three days',
    'Four days',
    'Five days',
    'Six days',
    'Seven days',
  ];

  @override
  Widget build(BuildContext context) {
    final int left = 7 - daysDone;
    final String head = streak == 0
        ? 'Day one'
        : streak < _words.length
        ? '${_words[streak]} sharper'
        : '$streak days sharper';
    return Row(
      children: [
        _RingIn(
          child: SizedBox(
            width: 60,
            height: 60,
            child: CustomPaint(
              painter: _RingPainter(
                turned: daysDone / 7,
                lit: colour,
                rest: context.p.ink.withValues(alpha: 0.10),
              ),
              child: Center(
                child: Text(
                  '$streak',
                  style: AppText.display(
                    size: 21,
                    weight: FontWeight.w600,
                    height: 1,
                    spacing: -0.6,
                    color: context.p.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                head,
                style: AppText.display(
                  size: 21,
                  weight: FontWeight.w600,
                  height: 1.1,
                  spacing: -0.6,
                  color: context.p.ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                left <= 0
                    ? 'The week is yours'
                    : left == 1
                    ? 'One more and the week is yours'
                    : '$left more and the week is yours',
                style: AppText.body(
                  size: 12.5,
                  height: 1.3,
                  color: context.p.ink.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ringIn: turns up from a quarter back, growing from .85, as it fades in.
class _RingIn extends StatefulWidget {
  const _RingIn({required this.child});
  final Widget child;
  @override
  State<_RingIn> createState() => _RingInState();
}

class _RingInState extends State<_RingIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    final curve = CurvedAnimation(
      parent: _c,
      curve: const Cubic(0.3, 1.2, 0.3, 1),
    );
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        final t = curve.value;
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.rotate(
            angle: -math.pi / 2 * (1 - t),
            child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.turned,
    required this.lit,
    required this.rest,
  });

  final double turned;
  final Color lit;
  final Color rest;

  @override
  void paint(Canvas canvas, Size size) {
    // conic-gradient(colour 0..308deg, rest after): a 5-point band, with
    // the lit share starting at twelve o'clock and running clockwise.
    const double band = 5;
    final Rect box = (Offset.zero & size).deflate(band / 2);
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = band
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(box, 0, math.pi * 2, false, p..color = rest);
    if (turned <= 0) return;
    canvas.drawArc(
      box,
      -math.pi / 2,
      math.pi * 2 * turned.clamp(0, 1),
      false,
      p..color = lit,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.turned != turned || old.lit != lit || old.rest != rest;
}

/// The day's cards as the deck itself, fanned. 250 by 318 on the artboard;
/// on a shorter phone it takes what is there.
class _Fan extends StatelessWidget {
  const _Fan({
    required this.deck,
    required this.at,
    required this.onPick,
    required this.onOpen,
  });

  final List<Pill> deck;
  final int at;
  final ValueChanged<int> onPick;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, box) {
          final double height = math.min(box.maxHeight - 8, 318);
          final double width = math.min(box.maxWidth - 80, height * 250 / 318);
          // Painted furthest-from-the-front first, which is what the
          // artboard's z-index says.
          final order = List<int>.generate(deck.length, (k) => k)
            ..sort((a, b) => (b - at).abs().compareTo((a - at).abs()));
          final layers = <Widget>[];
          for (final k in order) {
            final int off = k - at;
            final int reach = math.min(off.abs(), 2);
            final int side = off.sign;
            final bool front = off == 0;
            final double opacity = switch (off.abs()) {
              0 => 1,
              1 => 0.55,
              2 => 0.24,
              _ => 0,
            };
            layers.add(
              IgnorePointer(
                ignoring: opacity == 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  opacity: opacity,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: const Cubic(0.3, 1.16, 0.3, 1),
                    transform: Matrix4.identity()
                      ..translateByDouble(
                        side * reach * 36.0,
                        reach * 12.0,
                        0,
                        1,
                      )
                      ..rotateZ(side * reach * 5 * math.pi / 180)
                      ..scaleByDouble(front ? 1 : 0.9, front ? 1 : 0.9, 1, 1),
                    transformAlignment: Alignment.center,
                    child: _FanCard(
                      pill: deck[k],
                      index: k,
                      onTap: () => front ? onOpen(k) : onPick(k),
                    ),
                  ),
                ),
              ),
            );
          }
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v.abs() < 120) return;
              final next = v < 0 ? at + 1 : at - 1;
              if (next >= 0 && next < deck.length) onPick(next);
            },
            child: _FanIn(
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(alignment: Alignment.center, children: layers),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// fanIn: rises thirty points from .9, fading in.
class _FanIn extends StatefulWidget {
  const _FanIn({required this.child});
  final Widget child;
  @override
  State<_FanIn> createState() => _FanInState();
}

class _FanInState extends State<_FanIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        final t = curve.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - t)),
            child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _FanCard extends StatelessWidget {
  const _FanCard({
    required this.pill,
    required this.index,
    required this.onTap,
  });

  final Pill pill;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color ink = pill.ink;
    final bool light = ink.computeLuminance() < 0.5;
    final Color sub = ink.withValues(alpha: light ? 0.6 : 0.66);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: pill.color,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 50,
              offset: Offset(0, 22),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      _SubjectIcon(subject: pill.topic, size: 16, ink: ink),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          pill.topic.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.label(
                            size: 9.5,
                            spacing: 1.4,
                            color: sub,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: AppText.label(size: 9.5, color: sub),
                ),
              ],
            ),
            Flexible(
              child: Text(
                pill.question,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 21,
                  weight: FontWeight.w600,
                  height: 1.16,
                  spacing: -0.6,
                  color: ink,
                ),
              ),
            ),
            Text(
              'READ',
              style: AppText.label(size: 10, spacing: 1.2, color: sub),
            ),
          ],
        ),
      ),
    );
  }
}

/// The subject's own mark, recoloured to whatever ink it sits on.
class _SubjectIcon extends StatelessWidget {
  const _SubjectIcon({
    required this.subject,
    required this.size,
    required this.ink,
  });

  final String subject;
  final double size;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final String svg = subjectIconSvg(subject);
    if (svg.isEmpty) return SizedBox(width: size, height: size);
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(
        svg,
        colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
      ),
    );
  }
}

/// The five subjects under the deck, driving it. The one at the front is
/// filled in its own colour; the others sit back.
class _Chips extends StatelessWidget {
  const _Chips({required this.deck, required this.at, required this.onPick});

  final List<Pill> deck;
  final int at;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (int k = 0; k < deck.length; k++)
          Builder(
            builder: (context) {
              final bool on = k == at;
              final Pill pill = deck[k];
              final Color ink = on
                  ? pill.ink
                  : context.p.ink.withValues(alpha: 0.6);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onPick(k),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  decoration: BoxDecoration(
                    color: on
                        ? pill.color
                        : context.p.ink.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SubjectIcon(subject: pill.topic, size: 14, ink: ink),
                      const SizedBox(width: 7),
                      Text(
                        pill.topic,
                        style: AppText.body(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: ink,
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

class _Actions extends StatelessWidget {
  const _Actions({required this.app, required this.deck, required this.front});

  final AppState app;
  final List<Pill> deck;
  final Pill front;

  @override
  Widget build(BuildContext context) {
    final bool more = app.canOpenExtraSet;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              if (more) {
                await app.openExtraSet();
              } else {
                openDeckViewer(context, app, deck, "Today's five");
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // The button takes the front card's colour, with that
                // card's ink, so it changes with the deck like everything
                // else on the screen.
                color: front.color,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                more ? 'Five more' : "Today's five again",
                style: AppText.body(
                  size: 15,
                  weight: FontWeight.w700,
                  color: front.ink,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Semantics(
          button: true,
          label: 'Share this card',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showShareSheet(context, front),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: context.p.ink.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 20,
                color: context.p.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.worked});

  final int worked;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final left = tomorrow.difference(now);
    final hours = left.inHours;
    final minutes = left.inMinutes % 60;
    final style = AppText.body(
      size: 11.5,
      weight: FontWeight.w500,
      color: context.p.ink.withValues(alpha: 0.32),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            worked == 1
                ? '1 pill worked through'
                : '$worked pills worked through',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          hours >= 1
              ? 'Next five in ${hours}h ${minutes}m'
              : 'Next five in ${minutes}m',
          style: style,
        ),
      ],
    );
  }
}
