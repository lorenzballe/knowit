/// A free card's picture, at any size: the card itself, smaller, with its
/// drawing, wherever it is shown outside the deck.
///
/// A free card is a page, and its words alone — the question in the app's
/// type on the subject's colour — leave out the part of it that is the
/// card: the drawing. So the bank names two pictures of each page, taken as
/// the app opens it (tool/cards/thumbs.cjs): the front, as the card is first
/// shown, and the back, once it is played. The day's shelf, the reader's own
/// shelves and Explore's feed show these, and fall back to what they drew
/// before on a card that has none yet, or whose picture will not come.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/card_pages.dart';
import '../../models/pill.dart';
import 'web_card_page.dart';

/// Which of a card's two pictures.
enum CardSide {
  /// The card as first shown: its question and drawing, nothing answered.
  front,

  /// The card once played: its answer, drawing, line to keep and source.
  back,
}

/// How a picture is fetched, from its full address. Replaceable, so tests
/// never touch the network and the cameras can show a picture from disk.
typedef ThumbImage = ImageProvider Function(Uri url);

/// One of a free card's pictures, filling its box on the card's ground.
///
/// [BoxFit.cover] from the top by default: in a box shorter than the card,
/// the card from its head down, which is the question and the drawing. A
/// place that must show the card whole asks for [BoxFit.contain], and the
/// card's ground either side of it, or under it, reads as the card's own
/// margin, since the picture's ground is that colour edge to edge.
///
/// While the picture comes the box is the card's ground, and the picture
/// fades in over it. Where there is none, or it will not load, [fallback]
/// is drawn instead (nothing, when none is given): the place showing the
/// card draws it as it would without a picture.
class CardThumb extends StatelessWidget {
  const CardThumb({
    super.key,
    required this.pill,
    required this.side,
    this.fit = BoxFit.cover,
    this.fallback,
    this.foreground,
    this.large = false,
  });

  /// How the app fetches a picture: over the network, kept in the image
  /// cache like any picture in a feed. Tests replace it.
  static ThumbImage image = _network;

  static ImageProvider _network(Uri url) => NetworkImage(url.toString());

  /// How long the picture takes to come up over the ground.
  static const Duration fade = Duration(milliseconds: 260);

  /// Where [pill]'s picture of [side] is published, relative to the bank,
  /// or null when it has none.
  static String? refOf(Pill pill, CardSide side) {
    final WebThumbs? thumbs = pill.web?.thumbs;
    return switch (side) {
      CardSide.front => thumbs?.front,
      CardSide.back => thumbs?.back,
    };
  }

  /// Where the large picture of [side] is published, the small one's
  /// beside it: `thumbs/large/…` for `thumbs/…`, the same version.
  static String largeOf(String ref) =>
      ref.startsWith('thumbs/') ? 'thumbs/large/${ref.substring(7)}' : ref;

  /// Whether [pill] has a picture of [side].
  static bool has(Pill pill, CardSide side) => refOf(pill, side) != null;

  /// The full address of a picture named [ref].
  static Uri urlOf(String ref) => Uri.parse(kCardsBase).resolve(ref);

  final Pill pill;
  final CardSide side;
  final BoxFit fit;

  /// What is drawn where the card has no picture of [side], or it fails.
  final Widget? fallback;

  /// What is drawn over the picture, and only over the picture: the
  /// controls a place keeps in the card's empty corner. A fallback carries
  /// its own.
  final Widget? foreground;

  /// The picture taken at two and a half times the card's size, for a
  /// place that shows the card at full width, where the small one, blown
  /// up, was soft. Where the large one will not come, the small one.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final String? small = refOf(pill, side);
    final Widget none = fallback ?? const SizedBox.shrink();
    if (small == null) return none;
    final String ref = large ? largeOf(small) : small;
    final bool still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final ImageProvider source = image(urlOf(ref));
    final double dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 3;
    return LayoutBuilder(
      builder: (context, box) =>
          _picture(context, still, none, _sized(source, box, dpr)),
    );
  }

  /// The picture decoded at the size it is shown, not the size it was taken
  /// at. Decoded whole, a picture taken at two and a half times the card
  /// costs megabytes in a fifty-point slot, and a shelf of them is what an
  /// iPhone closes an app for (a Jetsam report, from the owner's phone). The
  /// width is rounded up to a step, so a box a point or two different reuses
  /// the same decode rather than making another.
  ImageProvider _sized(ImageProvider source, BoxConstraints box, double dpr) {
    final double w = box.maxWidth, h = box.maxHeight;
    if (!w.isFinite && !h.isFinite) return source;
    const double aspect = WebThumbs.aspect;
    final double shown = !h.isFinite
        ? w
        : !w.isFinite
        ? h * aspect
        : switch (fit) {
            BoxFit.cover => math.max(w, h * aspect),
            BoxFit.fitWidth => w,
            BoxFit.fitHeight => h * aspect,
            _ => math.min(w, h * aspect),
          };
    if (shown <= 0) return source;
    const int step = 64;
    final int px = ((shown * dpr) / step).ceil() * step;
    return ResizeImage.resizeIfNeeded(px, null, source);
  }

  Widget _picture(
    BuildContext context,
    bool still,
    Widget none,
    ImageProvider provider,
  ) {
    return Image(
      key: ValueKey(
        'card-thumb-${pill.id}-${side.name}${large ? '-large' : ''}',
      ),
      image: provider,
      fit: fit,
      alignment: Alignment.topCenter,
      width: double.infinity,
      height: double.infinity,
      // The picture is read for its words, as the card is.
      semanticLabel: switch (side) {
        CardSide.front => pill.question,
        CardSide.back => '${pill.question} ${pill.answer}',
      },
      // Smoothly scaled down: a 458-pixel picture in a fifty-point slot.
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, synchronous) {
        final Widget shown = synchronous || still
            ? child
            : AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: fade,
                curve: Curves.easeOut,
                child: child,
              );
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: groundOf(pill)),
            shown,
            ?foreground,
          ],
        );
      },
      errorBuilder: (context, error, stack) => large
          ? CardThumb(
              pill: pill,
              side: side,
              fit: fit,
              fallback: fallback,
              foreground: foreground,
            )
          : none,
    );
  }
}
