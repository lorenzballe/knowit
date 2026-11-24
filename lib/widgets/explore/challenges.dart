/// Explore's challenges: the games, four tiles to a page, two by two, and
/// the pages side by side — a swipe brings the next four, and the dots
/// under them say how many pages there are and which one is showing.
///
/// Every tile is the same size on every page: the game's colour, its
/// picture (challenge_art.dart), its name, and over the name the reader's
/// record where the game keeps one. A tile that opens its game on a screen
/// of its own (Sixty seconds, sixty_game.dart) grows into that screen: its
/// ground and its picture are a [Hero], flown by [challengeFlight].
library;

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../theme.dart';
import 'challenge_art.dart';

/// How a challenge looks wherever it is drawn: its tile, its screen, the
/// card that offers it as the next.
@immutable
class ChallengeLook {
  const ChallengeLook({
    required this.title,
    required this.colour,
    required this.art,
    this.note,
  });

  /// The game's name, in the reader's language.
  final String title;

  /// Its ground.
  final Color colour;

  /// Its picture.
  final ChallengeArt art;

  /// What its tile says over the name: the record, where it keeps one.
  final String? note;

  /// The ink of its words and lines.
  Color get ink => challengeInk(colour);
}

/// Of the drawn cards' ink and white, whichever reads better on [colour]:
/// the ink on every colour of the wheel the games are drawn in.
Color challengeInk(Color colour) {
  double contrast(Color a, Color b) {
    final double x = a.computeLuminance(), y = b.computeLuminance();
    return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
  }

  return contrast(kArtInk, colour) >= contrast(Colors.white, colour)
      ? kArtInk
      : Colors.white;
}

/// One tile of the challenges: what it shows and what a tap on it does.
@immutable
class ChallengeTileSpec {
  const ChallengeTileSpec({
    required this.id,
    required this.look,
    required this.onTap,
    this.heroTag,
  });

  /// The game's name in a section's `games`: the tile's key.
  final String id;
  final ChallengeLook look;
  final VoidCallback onTap;

  /// Set when the game has a screen of its own its tile grows into.
  final Object? heroTag;
}

/// The corners of a tile.
const double kChallengeCorner = 22;

/// Where a tile's picture stands in a tile of [size]: across its top, inset
/// a little, in the pictures' proportions.
Rect challengeTileArt(Size size) {
  final double inset = (size.width * 0.05).clamp(6.0, 12.0);
  final double width = size.width - inset * 2;
  return Rect.fromLTWH(inset, inset, width, width / kArtAspect);
}

/// The game's ground and its picture at [artAt] — the part of a tile, and
/// of a game's screen, that flies from one to the other — and on a tile its
/// words ([foreground]) at its foot.
class ChallengeGround extends StatelessWidget {
  const ChallengeGround({
    super.key,
    required this.colour,
    required this.art,
    required this.artAt,
    this.time = 0.25,
    this.radius = 0,
    this.foreground,
    this.foregroundWidth,
    this.foregroundOpacity = 1,
  });

  final Color colour;
  final ChallengeArt art;

  /// Where the picture stands, in a ground of the given size.
  final Rect Function(Size size) artAt;

  /// Sixty seconds' time gone, 0 to 1 ([ChallengePainter.time]).
  final double time;

  final double radius;

  /// The tile's words, at the ground's foot, [foregroundWidth] wide.
  final Widget? foreground;
  final double? foregroundWidth;
  final double foregroundOpacity;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: ColoredBox(
      color: colour,
      child: LayoutBuilder(
        builder: (context, box) {
          final Rect at = artAt(box.biggest);
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              if (!at.isEmpty)
                Positioned.fromRect(
                  rect: at,
                  child: ChallengeArtView(art: art, ground: colour, time: time),
                ),
              if (foreground != null && foregroundOpacity > 0)
                Positioned(
                  left: 0,
                  bottom: 0,
                  width: foregroundWidth ?? box.maxWidth,
                  child: Opacity(
                    opacity: foregroundOpacity.clamp(0.0, 1.0),
                    child: foreground,
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

/// A tile grows straight into the screen, as an app opened on a phone does.
RectTween challengeRectTween(Rect? begin, Rect? end) =>
    RectTween(begin: begin, end: end);

/// A challenge's ground on its way from its tile to its screen and back:
/// the box grows from the tile to the whole screen, its corners going
/// square, the picture moving from its place on the tile to its place on
/// the screen, and the tile's words gone in the first part of the way.
Widget challengeFlight(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromContext,
  BuildContext toContext,
) {
  final bool push = direction == HeroFlightDirection.push;
  final BuildContext tileContext = push ? fromContext : toContext;
  final BuildContext screenContext = push ? toContext : fromContext;
  final ChallengeGround tile =
      (tileContext.widget as Hero).child as ChallengeGround;
  final ChallengeGround screen =
      (screenContext.widget as Hero).child as ChallengeGround;
  Size sizeOf(BuildContext context, Size fallback) {
    final RenderObject? box = context.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size : fallback;
  }

  final Size screenSize = sizeOf(
    screenContext,
    MediaQuery.sizeOf(flightContext),
  );
  final Size tileSize = sizeOf(tileContext, const Size(160, 200));
  final Rect from = tile.artAt(tileSize);
  final Rect to = screen.artAt(screenSize);
  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final double t = animation.value;
      return ChallengeGround(
        colour: tile.colour,
        art: tile.art,
        time: lerpDouble(tile.time, screen.time, t)!,
        radius: lerpDouble(tile.radius, screen.radius, t)!,
        artAt: (_) => Rect.lerp(from, to, t)!,
        foreground: tile.foreground,
        foregroundWidth: tileSize.width,
        foregroundOpacity: 1 - t / 0.28,
      );
    },
  );
}

/// The challenges, four to a page, and the dots under the pages.
class ChallengePager extends StatefulWidget {
  const ChallengePager({super.key, required this.id, required this.tiles});

  /// The section's id: what the page shown is kept under while the reader
  /// is elsewhere.
  final String id;
  final List<ChallengeTileSpec> tiles;

  /// Tiles to a page.
  static const int perPage = 4;

  /// The room between two tiles.
  static const double gap = 10;

  /// What each pager is asked to show, by its id: a tile's id.
  static final Map<String, ValueNotifier<String?>> _asked = {};

  static ValueNotifier<String?> _askOf(String id) =>
      _asked.putIfAbsent(id, () => ValueNotifier<String?>(null));

  /// Turns pager [id] to the page with tile [tile] on it — the next
  /// challenge, offered at the end of one, flies out of its own tile.
  static void reveal(String id, String tile) {
    final ValueNotifier<String?> ask = _askOf(id);
    ask.value = null;
    ask.value = tile;
  }

  @override
  State<ChallengePager> createState() => _ChallengePagerState();
}

class _ChallengePagerState extends State<ChallengePager> {
  late final PageController _pages = PageController();
  late ValueNotifier<String?> _ask = ChallengePager._askOf(widget.id)
    ..addListener(_asked);

  @override
  void didUpdateWidget(ChallengePager old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      _ask.removeListener(_asked);
      _ask = ChallengePager._askOf(widget.id)..addListener(_asked);
    }
  }

  @override
  void dispose() {
    _ask.removeListener(_asked);
    _pages.dispose();
    super.dispose();
  }

  /// A tile asked for: its page, at once — the screen in front hides the
  /// turn.
  void _asked() {
    final String? tile = _ask.value;
    if (tile == null || !_pages.hasClients) return;
    final int at = widget.tiles.indexWhere((t) => t.id == tile);
    if (at < 0) return;
    _pages.jumpToPage(at ~/ ChallengePager.perPage);
  }

  int get _count =>
      (widget.tiles.length / ChallengePager.perPage).ceil().clamp(1, 99);

  /// To [page], from a dot: the page turning says so in the hand.
  void _go(int page) {
    if (!_pages.hasClients) return;
    final int to = page.clamp(0, _count - 1);
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(to);
    } else {
      _pages.animateToPage(
        to,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final double width = box.maxWidth;
        final double tileWidth = (width - 40 - ChallengePager.gap) / 2;
        final double tileHeight = ChallengeTile.heightFor(
          context,
          tileWidth,
          widget.tiles.map((t) => t.look),
        );
        final double pageHeight = tileHeight * 2 + ChallengePager.gap;
        Widget page(int index) {
          final List<ChallengeTileSpec> on = widget.tiles
              .skip(index * ChallengePager.perPage)
              .take(ChallengePager.perPage)
              .toList();
          // A page not full keeps the grid, as a phone's last page of apps
          // does: its tiles where the first page has them, the rest of it
          // empty.
          Widget slot(int i) => SizedBox(
            key: i < on.length ? null : ValueKey('challenge-empty-$index-$i'),
            width: tileWidth,
            height: tileHeight,
            child: i < on.length
                ? ChallengeTile(
                    key: ValueKey('challenge-${on[i].id}'),
                    spec: on[i],
                  )
                : null,
          );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    slot(0),
                    const SizedBox(width: ChallengePager.gap),
                    slot(1),
                  ],
                ),
                const SizedBox(height: ChallengePager.gap),
                Row(
                  children: [
                    slot(2),
                    const SizedBox(width: ChallengePager.gap),
                    slot(3),
                  ],
                ),
              ],
            ),
          );
        }

        if (_count == 1) return page(0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: pageHeight,
              child: PageView.builder(
                key: PageStorageKey<String>('challenges-${widget.id}'),
                controller: _pages,
                itemCount: _count,
                onPageChanged: (_) => HapticFeedback.selectionClick(),
                itemBuilder: (context, i) => page(i),
              ),
            ),
            const SizedBox(height: 6),
            ChallengeDots(controller: _pages, count: _count, onPick: _go),
          ],
        );
      },
    );
  }
}

/// The pages, as dots: the one showing long and in full ink, the others
/// short and faint, the long one moving as the finger moves the pages. A
/// tap on a dot goes to its page; to a screen reader it is the pages'
/// control, adjusted up and down as iOS's own is.
class ChallengeDots extends StatelessWidget {
  const ChallengeDots({
    super.key,
    required this.controller,
    required this.count,
    required this.onPick,
  });

  final PageController controller;
  final int count;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final double at =
            controller.hasClients && controller.position.haveDimensions
            ? (controller.page ?? 0)
            : controller.initialPage.toDouble();
        final int shown = at.round().clamp(0, count - 1);
        final l = context.l10n;
        return Semantics(
          key: const ValueKey('challenge-dots'),
          container: true,
          value: l.challengesPage(shown + 1, count),
          increasedValue: shown + 1 < count
              ? l.challengesPage(shown + 2, count)
              : null,
          decreasedValue: shown > 0 ? l.challengesPage(shown, count) : null,
          onIncrease: shown + 1 < count ? () => onPick(shown + 1) : null,
          onDecrease: shown > 0 ? () => onPick(shown - 1) : null,
          child: ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < count; i++)
                  GestureDetector(
                    key: ValueKey('challenge-dot-$i'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onPick(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      child: Builder(
                        builder: (context) {
                          final double near = (1 - (at - i).abs()).clamp(
                            0.0,
                            1.0,
                          );
                          return Container(
                            width: lerpDouble(7, 22, near),
                            height: 7,
                            decoration: BoxDecoration(
                              color: ink.withValues(
                                alpha: lerpDouble(0.24, 1, near),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One challenge's tile: its colour, its picture across the top, and at
/// its foot the record and the name. It gives a little under the finger.
class ChallengeTile extends StatefulWidget {
  const ChallengeTile({super.key, required this.spec});

  final ChallengeTileSpec spec;

  /// The words' room from the tile's edges.
  static const EdgeInsets pad = EdgeInsets.fromLTRB(13, 0, 12, 13);

  /// The name and the record, as the tile sets them: the name at [size].
  static TextStyle titleStyle(Color ink, [double size = 17.5]) =>
      AppText.display(
        size: size,
        weight: FontWeight.w600,
        height: 1.08,
        spacing: -0.3,
        color: ink,
      );
  static TextStyle noteStyle(Color ink) => AppText.body(
    size: 11.5,
    weight: FontWeight.w700,
    height: 1.2,
    color: ink.withValues(alpha: 0.8),
  );

  /// The reader's text size, as far as a tile of a grid of four follows
  /// it: half as large again, and no further, so four still fit a page.
  static TextScaler scalerOf(BuildContext context) =>
      MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.6);

  /// The size [title] is set at on a tile whose words are [inner] wide:
  /// 17.5, or less where its longest word would not fit the line — a name
  /// is never broken in the middle of a word ("Sechzig Sekunden").
  static double titleSizeFor(BuildContext context, String title, double inner) {
    final TextScaler scaler = scalerOf(context);
    final TextDirection direction = Directionality.of(context);
    double widest(double size) {
      double most = 0;
      for (final String word in title.split(RegExp(r'\s+'))) {
        final TextPainter p = TextPainter(
          text: TextSpan(text: word, style: titleStyle(kArtInk, size)),
          textDirection: direction,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        most = math.max(most, p.width);
        p.dispose();
      }
      return most;
    }

    double size = 17.5;
    while (size > 12 && widest(size) > inner) {
      size -= 0.5;
    }
    return size;
  }

  /// How tall every tile is, [width] wide, for [looks] to all fit: the
  /// picture, and under it the most lines of words any of them has — so
  /// the tiles are one size on every page, at any text size.
  static double heightFor(
    BuildContext context,
    double width,
    Iterable<ChallengeLook> looks,
  ) {
    final TextScaler scaler = scalerOf(context);
    final TextDirection direction = Directionality.of(context);
    final double inner = width - pad.horizontal;
    double words = 0;
    for (final ChallengeLook look in looks) {
      double h = 0;
      final String? note = look.note;
      if (note != null) {
        final TextPainter p = TextPainter(
          text: TextSpan(text: note, style: noteStyle(kArtInk)),
          textDirection: direction,
          textScaler: scaler,
        )..layout(maxWidth: inner);
        h += p.height + 4;
        p.dispose();
      }
      final TextPainter t = TextPainter(
        text: TextSpan(
          text: look.title,
          style: titleStyle(kArtInk, titleSizeFor(context, look.title, inner)),
        ),
        textDirection: direction,
        textScaler: scaler,
      )..layout(maxWidth: inner);
      h += t.height;
      t.dispose();
      words = math.max(words, h);
    }
    final Rect art = challengeTileArt(Size(width, width));
    return (art.bottom + 8 + words + pad.bottom).ceilToDouble();
  }

  @override
  State<ChallengeTile> createState() => _ChallengeTileState();
}

class _ChallengeTileState extends State<ChallengeTile> {
  bool _down = false;

  void _press(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final ChallengeTileSpec spec = widget.spec;
    final ChallengeLook look = spec.look;
    final Color ink = look.ink;
    final String? note = look.note;
    final TextScaler scaler = ChallengeTile.scalerOf(context);
    final Widget words = LayoutBuilder(
      builder: (context, box) {
        final double inner = box.maxWidth - ChallengeTile.pad.horizontal;
        return Padding(
          padding: ChallengeTile.pad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (note != null) ...[
                Text(
                  note,
                  key: const ValueKey('game-note'),
                  textScaler: scaler,
                  style: ChallengeTile.noteStyle(ink),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                look.title,
                textScaler: scaler,
                style: ChallengeTile.titleStyle(
                  ink,
                  ChallengeTile.titleSizeFor(context, look.title, inner),
                ),
              ),
            ],
          ),
        );
      },
    );
    final Widget ground = ChallengeGround(
      colour: look.colour,
      art: look.art,
      artAt: challengeTileArt,
      radius: kChallengeCorner,
      foreground: words,
    );
    final bool calm = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: note == null ? look.title : '${look.title}, $note',
      excludeSemantics: true,
      onTap: spec.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: () {
          HapticFeedback.selectionClick();
          spec.onTap();
        },
        child: AnimatedScale(
          scale: _down && !calm ? 0.96 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: spec.heroTag == null
              ? ground
              : Hero(
                  tag: spec.heroTag!,
                  createRectTween: challengeRectTween,
                  flightShuttleBuilder: challengeFlight,
                  child: ground,
                ),
        ),
      ),
    );
  }
}
