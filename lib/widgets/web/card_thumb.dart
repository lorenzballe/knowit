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
///
/// As a feed of photos does it: a picture is fetched once and kept on the
/// phone ([CachedThumb]), and the day's are fetched while the reader is still
/// reading them ([warmDay]), so the finished day's shelf has them at once.
/// One still on its way is the card in plain grey, its own shape, with only
/// what works without the picture on it ([waiting]: its save and share), as
/// a photo still coming is a grey square under its post's own buttons; then
/// the picture, at once.
///
/// A hard card is read ringed (lib/widgets/hard_ring.dart), and is shown by
/// the pictures taken of it ringed, on the paper the reader is on: dark at
/// night, on the raised paper by day, the ring round it drawn by the place
/// that shows it, as the deck draws it round the page ([picturesOf]).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/card_pages.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import '../hard_ring.dart';
import 'cached_thumb.dart';
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
/// While the picture comes the box is plain grey with [waiting] on it, and the
/// card, its ground, picture and [foreground] together, comes in over it.
/// Where there is none, or it will not load, [fallback] is drawn instead
/// (nothing, when none is given): the place showing the card draws it as it
/// would without a picture.
class CardThumb extends StatelessWidget {
  const CardThumb({
    super.key,
    required this.pill,
    required this.side,
    this.fit = BoxFit.cover,
    this.fallback,
    this.foreground,
    this.large = false,
    this.shelf = false,
    this.onCome,
    this.waiting,
  });

  /// The grey of a card whose picture is still coming: a shade off the page,
  /// in either theme.
  static Color waitingColour(Palette p) => Color.alphaBlend(
    p.ink.withValues(alpha: p.isDark ? 0.09 : 0.07),
    p.surface,
  );

  /// How the app fetches a picture: from the phone where it is kept, over
  /// the network once otherwise ([CachedThumb]), and kept in the image cache
  /// like any picture in a feed. Tests replace it.
  static ThumbImage image = _kept;

  static ImageProvider _kept(Uri url) => CachedThumb(url);

  /// Fetches the pictures the finished day's shelf will show of [deck],
  /// front and back at the shelf's size, and the fronts the day sent as
  /// five squares shows, while the reader is still reading: the shelf has
  /// them at once. A hard card's are those taken ringed on the paper the
  /// reader is on ([dark]). Quietly, a few at a time; only where the app
  /// fetches its own pictures (a test's stand-in is left alone).
  static Future<void> warmDay(Iterable<Pill> deck, {bool dark = true}) async {
    if (!identical(image, _kept)) return;
    await CachedThumb.warm([
      for (final Pill p in deck)
        for (final CardSide side in CardSide.values)
          if (refOf(p, side, dark: dark) case final String ref)
            urlOf(shelfOf(ref)),
      // The day sent as a picture leaves the app, and shows each card's own.
      for (final Pill p in deck)
        if (refOf(p, CardSide.front, own: true) case final String ref)
          urlOf(ref),
    ]);
  }

  /// How long the picture takes to come up over the grey: a blink, as a
  /// photo in a feed does.
  static const Duration fade = Duration(milliseconds: 140);

  /// The pictures [pill] is shown by in this run. A hard card read ringed
  /// (hard_ring.dart) is shown by those taken of it ringed: on the night
  /// paper, or, [dark] false, on the day one; where they were not taken it
  /// has none, and is drawn as a card without a picture is, ringed, rather
  /// than by a picture of it as it was. Any other card, by its own; and with
  /// [own], every card: for a picture that leaves the app (the day sent as a
  /// picture), whose reader meets the card on the web, as it is drawn there.
  static WebThumbs? picturesOf(
    Pill pill, {
    bool dark = true,
    bool own = false,
  }) {
    final WebThumbs? thumbs = pill.web?.thumbs;
    if (thumbs == null || own || !HardRing.on(pill)) return thumbs;
    return dark ? thumbs.ringed : thumbs.ringedDay;
  }

  /// Where [pill]'s picture of [side] is published, relative to the bank,
  /// or null when it has none: on the night paper, or, [dark] false, on the
  /// day one, which only a hard card's differ by; with [own], the card's
  /// own ([picturesOf]).
  static String? refOf(
    Pill pill,
    CardSide side, {
    bool dark = true,
    bool own = false,
  }) {
    final WebThumbs? thumbs = picturesOf(pill, dark: dark, own: own);
    return switch (side) {
      CardSide.front => thumbs?.front,
      CardSide.back => thumbs?.back,
    };
  }

  /// The colour a picture of [pill] is set on, and the place showing it
  /// takes for the card's own: its ground, or, on a hard card read ringed,
  /// the ground its pictures were taken on (HardRing.groundOf).
  static Color groundFor(Pill pill, Palette p) =>
      HardRing.on(pill) ? HardRing.groundOf(p) : groundOf(pill);

  /// Where the large picture of [side] is published, the small one's
  /// beside it: `thumbs/large/…` for `thumbs/…`, the same version.
  static String largeOf(String ref) =>
      ref.startsWith('thumbs/') ? 'thumbs/large/${ref.substring(7)}' : ref;

  /// The picture taken at the shelf's size, beside the small one, the same
  /// version: `thumbs/shelf/…` for `thumbs/…`.
  static String shelfOf(String ref) =>
      ref.startsWith('thumbs/') ? 'thumbs/shelf/${ref.substring(7)}' : ref;

  /// Whether [pill] has a picture of [side], on either paper; with [own],
  /// one of its own ([picturesOf]).
  static bool has(Pill pill, CardSide side, {bool own = false}) => own
      ? refOf(pill, side, own: true) != null
      : refOf(pill, side) != null && refOf(pill, side, dark: false) != null;

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

  /// The picture taken at the finished day's shelf's own size, 324 by 452
  /// (tool/cards/thumbs.cjs), for the shelf's cards: one taken at the deck's
  /// size had to shrink into them, its words smaller and a band of ground
  /// either side. Where it will not come, the small one.
  final bool shelf;

  /// The picture taken at two and a half times the card's size, for a
  /// place that shows the card at full width, where the small one, blown
  /// up, was soft. Where the large one will not come, the small one.
  final bool large;

  /// Told, after the frame, once the picture has come: for a place that
  /// draws round the card (its edge, the light under it) in grey until then.
  final VoidCallback? onCome;

  /// What sits on the grey card while its picture comes: what works without
  /// it, in the grey's own ink (the shelf's save and share). Nothing of the
  /// card's own head, which is in the picture.
  final Widget? waiting;

  @override
  Widget build(BuildContext context) {
    final String? small = refOf(pill, side, dark: context.p.isDark);
    final Widget none = fallback ?? const SizedBox.shrink();
    if (small == null) return none;
    final String ref = shelf
        ? shelfOf(small)
        : large
        ? largeOf(small)
        : small;
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
    final double aspect = shelf ? WebThumbs.shelfAspect : WebThumbs.aspect;
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

  /// What is drawn where the picture will not come, and the place told: the
  /// fallback is the card in full, drawn as it is.
  Widget _gone(Widget none) {
    if (onCome != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onCome!());
    }
    return none;
  }

  Widget _picture(
    BuildContext context,
    bool still,
    Widget none,
    ImageProvider provider,
  ) {
    return Image(
      key: ValueKey(
        'card-thumb-${pill.id}-${side.name}${shelf
            ? '-shelf'
            : large
            ? '-large'
            : ''}',
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
        final bool come = frame != null || synchronous;
        if (come && onCome != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onCome!());
        }
        // The card whole, ground, picture and what sits on it, as one.
        final Widget card = Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: groundFor(pill, context.p)),
            child,
            ?foreground,
          ],
        );
        if (synchronous) return card;
        // Until the picture has come, the card in plain grey with what works
        // without it; then the card over the grey, in a blink where motion
        // is on.
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              key: const ValueKey('card-waiting'),
              color: waitingColour(context.p),
            ),
            if (!come) ?waiting,
            if (still)
              Visibility(
                visible: come,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: true,
                child: card,
              )
            else
              AnimatedOpacity(
                opacity: come ? 1 : 0,
                duration: fade,
                curve: Curves.easeOut,
                child: IgnorePointer(ignoring: !come, child: card),
              ),
          ],
        );
      },
      errorBuilder: (context, error, stack) => large || shelf
          ? CardThumb(
              pill: pill,
              side: side,
              fit: fit,
              fallback: fallback,
              foreground: foreground,
              onCome: onCome,
              waiting: waiting,
            )
          : _gone(none),
    );
  }
}
