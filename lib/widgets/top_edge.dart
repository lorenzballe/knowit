import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// The top edge of a screen whose content runs on under the status bar:
/// a blur strongest at the top and thinning to nothing at the foot, with the
/// page's colour over it, so what passes under the time and the battery goes
/// soft and dissolves into the page, as a list under a bar is drawn on iOS
/// 26. Laid over exactly the status bar's room, and no more.
///
/// The blur is laid in thin slices, each blurring the content itself rather
/// than the slice above it, by a little less than the one before: close
/// enough that no seam shows, and one picture of the content serves them all.
/// Explore's shelves and Your journey's chapters run under it.
class TopEdge extends StatelessWidget {
  const TopEdge({super.key, required this.ground});

  /// The page's colour.
  final Color ground;

  /// From the top of the screen down: how soft each slice is.
  static const List<double> sigmas = [9, 7.5, 6, 4.6, 3.4, 2.4, 1.5, 0.8];

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      BackdropGroup(
        child: Column(
          children: [
            for (final double sigma in sigmas)
              Expanded(
                child: ClipRect(
                  child: BackdropFilter.grouped(
                    filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
          ],
        ),
      ),
      // The page's own colour over the blur, nearly whole at the edge of
      // the screen and gone at the foot: what passes under the time
      // dissolves into the page rather than being cut by a line.
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ground.withValues(alpha: 0.9),
              ground.withValues(alpha: 0.55),
              ground.withValues(alpha: 0.18),
              ground.withValues(alpha: 0),
            ],
            stops: const [0, 0.45, 0.75, 1],
          ),
        ),
      ),
    ],
  );
}
