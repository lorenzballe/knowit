import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pill.dart';
import '../theme.dart';
import '../widgets/diagram_view.dart';
import '../widgets/glass_round.dart';
import '../widgets/web/card_thumb.dart';
import '../widgets/web/web_card_page.dart';

/// A card's drawing with the whole screen to itself.
///
/// The card stays a card on the table: an object, thrown and turned. Its
/// drawing is the answer to the question the card asked, and it is the one
/// thing on it worth more room than a card has. So once the answer is out,
/// a touch on the drawing opens it here: the card's own colour from edge to
/// edge of the glass, nothing of the app around it, and two fingers to go
/// closer. It is shown after the answer and never before, because a drawing
/// seen first is the answer given away.
///
/// A card the app draws itself brings its diagram, drawn again from nothing
/// at the screen's width, under the question it answers. A free card brings
/// the picture of its back — the card once played, its drawing and the line
/// to keep, taken at two and a half times the card's size — which on its own
/// ground reads as the card itself gone to the edges.
class DrawingScreen extends StatelessWidget {
  const DrawingScreen({super.key, required this.pill});

  final Pill pill;

  /// Whether [pill] has a drawing this screen can show.
  static bool has(Pill pill) =>
      pill.diagram != null || CardThumb.has(pill, CardSide.back);

  /// Opens [pill]'s drawing over everything, the tabs too. It comes up out
  /// of the card rather than sliding in from a side: it is the same card,
  /// nearer.
  static Future<void> open(BuildContext context, Pill pill) {
    HapticFeedback.selectionClick();
    final bool still = MediaQuery.disableAnimationsOf(context);
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: 'drawing'),
        transitionDuration: Duration(milliseconds: still ? 0 : 260),
        reverseTransitionDuration: Duration(milliseconds: still ? 0 : 200),
        pageBuilder: (context, animation, secondary) =>
            DrawingScreen(pill: pill),
        transitionsBuilder: (context, animation, secondary, child) {
          final Animation<double> t = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: t,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(t),
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// The ground the drawing stands on: a free card's own where its page has
  /// one, the subject's otherwise.
  Color get _ground => pill.diagram == null ? groundOf(pill) : pill.color;

  @override
  Widget build(BuildContext context) {
    final Color ground = _ground;
    final bool darkGround =
        ThemeData.estimateBrightnessForColor(ground) == Brightness.dark;
    // On a ground that is not the subject's (a night card), the subject's
    // ink would be dark on dark: the ink is whichever reads.
    final Color ink = pill.diagram != null
        ? pill.ink
        : darkGround
        ? const Color(0xFFF2F1EC)
        : const Color(0xFF10100C);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The clock and the battery read on the card's colour, whichever it
      // is: this screen is not the app's palette, it is the card's.
      value:
          (darkGround ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: ground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The way back, in a row of its own over the drawing: a card's
              // picture carries its subject and its tag in its top corners,
              // and nothing is laid on them.
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _Close(ink: ink),
                ),
              ),
              Expanded(
                child: ClipRect(
                  child: InteractiveViewer(
                    key: const ValueKey('drawing-zoom'),
                    minScale: 1,
                    maxScale: 4,
                    child: pill.diagram != null
                        ? _Diagram(pill: pill)
                        : _Picture(pill: pill, ink: ink),
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

/// The way back: the app's own round button, the ring in the card's ink.
class _Close extends StatelessWidget {
  const _Close({required this.ink});

  final Color ink;

  @override
  Widget build(BuildContext context) {
    final String label = MaterialLocalizations.of(context).closeButtonTooltip;
    void close() => Navigator.of(context).pop();
    return GlassRound(
      symbol: GlassRound.close,
      label: label,
      onPressed: close,
      size: 44,
      iconSize: 17,
      fallback: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          key: const ValueKey('drawing-close'),
          behavior: HitTestBehavior.opaque,
          onTap: close,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ink.withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.close_rounded, size: 18, color: ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A diagram the app draws, under the question it answers: drawn again from
/// its first stroke, at the screen's width, and smaller as a whole only on
/// a screen too short for it.
class _Diagram extends StatelessWidget {
  const _Diagram({required this.pill});

  final Pill pill;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final double width = math.min(box.maxWidth - 44, 560);
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pill.question,
                style: AppText.display(
                  size: 24,
                  weight: FontWeight.w600,
                  height: 1.12,
                  spacing: -0.4,
                  color: pill.ink,
                ),
              ),
              const SizedBox(height: 28),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: width,
                    child: DiagramView(
                      key: const ValueKey('drawing-diagram'),
                      diagram: pill.diagram!,
                      ink: pill.ink,
                      // The screen is still coming up: the first stroke
                      // waits for it.
                      delay: const Duration(milliseconds: 300),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A free card's picture of its back, as large as the screen takes it whole.
/// Where the picture will not come — a phone out of reach of it, a card
/// never photographed — the card's answer in words, so the screen is never
/// an empty colour.
class _Picture extends StatelessWidget {
  const _Picture({required this.pill, required this.ink});

  final Pill pill;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: WebThumbs.aspect,
        child: CardThumb(
          pill: pill,
          side: CardSide.back,
          large: true,
          fit: BoxFit.contain,
          fallback: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pill.question,
                  style: AppText.display(
                    size: 22,
                    weight: FontWeight.w600,
                    height: 1.14,
                    spacing: -0.4,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  pill.answer,
                  style: AppText.body(
                    size: 16,
                    height: 1.45,
                    color: ink.withValues(alpha: 0.92),
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
