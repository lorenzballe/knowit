/// Explore's challenges: four tiles to a page, two by two, and the pages
/// side by side — a swipe brings the next four, and the dots under them
/// say how many pages there are and which one is showing.
///
/// A tile is set like an entry in a serious index, not drawn like a toy:
/// on the app's own raised surface, a hairline round it, the skill the
/// challenge trains in small capitals, its mark in the challenge's tone
/// (challenge_marks.dart), the name in the app's serif, a quiet line on
/// what it asks, and the reader's own figure where there is one, in
/// tabular figures. Every tile is the same size on every page.
///
/// A tile opens its challenge on a screen of its own
/// (challenge_screen.dart): its panel grows into the page, its words fading
/// as it goes ([challengeFlight]), and back.
library;

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../data/topics.dart' show inkOn;
import '../../l10n/l10n.dart';
import '../../theme.dart';
import 'challenge_marks.dart';
import 'parts.dart' show upper;

/// A challenge's colour, from the subjects' wheel as the app's cards
/// have theirs: its tile and its cards that colour, with the ink it
/// carries; a deep tone on paper and a lifted one at night for anything of
/// it set on the page itself.
@immutable
class ChallengeTone {
  const ChallengeTone(this.deep, this.lifted, this.vivid);

  /// The colour itself: the tile's and the challenge's cards'.
  final Color vivid;

  /// The ink the colour carries, black or white.
  Color get ink => inkOn(vivid);

  /// The tile's ground.
  Color tile(Palette p) => vivid;

  /// The screen's ground: the app's own page.
  Color page(Palette p) => p.surface;

  /// The colour the screen is bathed in at its top: deep at night, pale
  /// on paper.
  Color bath(Palette p) {
    final HSLColor c = HSLColor.fromColor(vivid);
    // A yellow deepens through amber, never olive.
    final double hue = c.hue > 40 && c.hue < 75 ? c.hue - 16 : c.hue;
    return c
        .withHue(hue)
        .withSaturation(c.saturation.clamp(0.0, p.isDark ? 0.62 : 0.7))
        .withLightness(p.isDark ? 0.15 : 0.87)
        .toColor();
  }

  /// On the day's paper.
  final Color deep;

  /// On the night's.
  final Color lifted;

  /// The tone on [p].
  Color on(Palette p) => p.isDark ? lifted : deep;

}

/// The challenge a screen is taken on, for whatever on it is drawn in the
/// challenge's colour without being handed it: its cards.
class ChallengeToneScope extends InheritedWidget {
  const ChallengeToneScope({
    super.key,
    required this.tone,
    required super.child,
  });

  final ChallengeTone tone;

  static ChallengeTone? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChallengeToneScope>()?.tone;

  @override
  bool updateShouldNotify(ChallengeToneScope old) => old.tone != tone;
}

/// The colours a verdict is told in, the app's own: its green for right
/// (the one a win is told in), its alert for wrong.
Color challengeRight(Palette p) =>
    p.isDark ? const Color(0xFF3BE07A) : const Color(0xFF128A43);
Color challengeWrong(Palette p) => p.alert;

/// The short rule in a challenge's tone over a small-caps label, as Go
/// deeper's magazine sets its sections.
class ChallengeRule extends StatelessWidget {
  const ChallengeRule({super.key, required this.colour, this.width = 18});

  final Color colour;
  final double width;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(width: width, height: 2, color: colour),
  );
}

/// One of the reader's own figures: what it is, and the figure.
typedef ChallengeFigure = ({String label, String value});

/// How a challenge looks wherever it is drawn: its tile, its screen, the
/// card that offers it as the next.
@immutable
class ChallengeLook {
  const ChallengeLook({
    required this.title,
    required this.skill,
    required this.line,
    required this.tone,
    required this.mark,
    this.figure,
  });

  /// The challenge's name, in the reader's language.
  final String title;

  /// The skill it trains: "Calibration", "Chronology".
  final String skill;

  /// What it asks, in a quiet line.
  final String line;

  /// Its one colour.
  final ChallengeTone tone;

  /// Its mark.
  final ChallengeMark mark;

  /// The reader's own figure on its tile — the best, today's — or none.
  final ChallengeFigure? figure;
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

  /// Set when the challenge has a screen of its own its tile grows into.
  final Object? heroTag;
}

/// The corners of a tile.
const double kChallengeCorner = 20;

/// The small capitals every challenge names its skill in, and its heads.
TextStyle challengeSmallCaps(Color colour, [double size = 10.5]) =>
    AppText.label(
      size: size,
      weight: FontWeight.w600,
      spacing: size * 0.13,
      height: 1.2,
      color: colour,
    );

/// A challenge's panel — the part of a tile that grows into its screen, and
/// the screen's own page — and on a tile its words ([foreground]), laid out
/// at the tile's size ([foregroundSize]) so they never reflow as the panel
/// grows.
class ChallengeGround extends StatelessWidget {
  const ChallengeGround({
    super.key,
    required this.colour,
    this.bath,
    this.shade = false,
    this.radius = 0,
    this.border,
    this.foreground,
    this.foregroundSize,
    this.foregroundOpacity = 1,
  });

  final Color colour;

  /// Whether it deepens a little to its corner, as the app's tiles do.
  final bool shade;

  /// The colour the page is bathed in at its top, fading into its ground
  /// over most of the screen, as Go deeper's sheet is in its subject's.
  final Color? bath;

  final double radius;

  /// The hairline round it, or none.
  final Color? border;

  final Widget? foreground;
  final Size? foregroundSize;
  final double foregroundOpacity;

  @override
  Widget build(BuildContext context) {
    final Color? line = border;
    final Widget? words = foreground;
    final Size? at = foregroundSize;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: shade || bath != null ? null : colour,
        gradient: bath != null
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bath!, colour],
                stops: const [0, 0.62],
              )
            : shade
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colour,
                  Color.alphaBlend(Colors.black.withValues(alpha: 0.16), colour),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(radius),
        border: line == null || line.a == 0
            ? null
            : Border.all(color: line, width: 1),
      ),
      child: words == null || foregroundOpacity <= 0
          ? const SizedBox.expand()
          : ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Opacity(
                opacity: foregroundOpacity.clamp(0.0, 1.0),
                child: at == null
                    ? SizedBox.expand(child: words)
                    : OverflowBox(
                        alignment: Alignment.topLeft,
                        minWidth: at.width,
                        maxWidth: at.width,
                        minHeight: at.height,
                        maxHeight: at.height,
                        child: words,
                      ),
              ),
            ),
    );
  }
}

/// A tile grows straight into the screen.
RectTween challengeRectTween(Rect? begin, Rect? end) =>
    RectTween(begin: begin, end: end);

/// A challenge's panel on its way from its tile to its screen and back: the
/// box grows from the tile to the whole screen, its corners going square,
/// its surface becoming the page's and its hairline fading, and the tile's
/// words gone in the first part of the way.
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
  final RenderObject? box = tileContext.findRenderObject();
  final Size tileSize = box is RenderBox && box.hasSize
      ? box.size
      : const Size(160, 200);
  final Color line = tile.border ?? Colors.transparent;
  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final double t = animation.value;
      return ChallengeGround(
        colour: Color.lerp(tile.colour, screen.colour, t)!,
        shade: tile.shade && t < 0.5,
        radius: lerpDouble(tile.radius, screen.radius, t)!,
        border: line.withValues(alpha: line.a * (1 - t).clamp(0.0, 1.0)),
        foreground: tile.foreground,
        foregroundSize: tileSize,
        foregroundOpacity: 1 - t / 0.3,
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
  /// challenge, offered at the end of one, opens out of its own tile.
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

  /// To [page], from a dot.
  void _go(int page) {
    if (!_pages.hasClients) return;
    final int to = page.clamp(0, _count - 1);
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(to);
    } else {
      _pages.animateToPage(
        to,
        duration: const Duration(milliseconds: 320),
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
          // A page not full keeps the grid: its tiles where the first page
          // has them, the rest of it empty.
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
                itemBuilder: (context, i) => page(i),
              ),
            ),
            const SizedBox(height: 8),
            ChallengeDots(controller: _pages, count: _count, onPick: _go),
          ],
        );
      },
    );
  }
}

/// The pages, as dots: the one showing longer and in full ink, the others
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
                        horizontal: 3,
                        vertical: 12,
                      ),
                      child: Builder(
                        builder: (context) {
                          final double near = (1 - (at - i).abs()).clamp(
                            0.0,
                            1.0,
                          );
                          return Container(
                            width: lerpDouble(5, 18, near),
                            height: 5,
                            decoration: BoxDecoration(
                              color: ink.withValues(
                                alpha: lerpDouble(0.2, 0.9, near),
                              ),
                              borderRadius: BorderRadius.circular(2.5),
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

/// One challenge's tile, in the app's own manner — the colour of its
/// challenge, as a subject's card is its subject's, deepening a little to
/// its corner; its mark large and faint off that corner; across its top
/// its mark and the skill it trains in small capitals, as a card's head
/// carries its subject; the name in the app's serif; what it asks; and at
/// its foot the reader's own figure.
class ChallengeTile extends StatefulWidget {
  const ChallengeTile({super.key, required this.spec});

  final ChallengeTileSpec spec;

  /// The words' room from the tile's edges.
  static const EdgeInsets pad = EdgeInsets.fromLTRB(14, 14, 13, 14);

  /// The head's mark.
  static const double markSide = 16;

  static const double _afterHead = 22;
  static const double _afterTitle = 5;
  static const double _beforeFoot = 12;

  static TextStyle skillStyle(Color ink, [double size = 9.5]) => AppText.label(
    size: size,
    weight: FontWeight.w700,
    spacing: 1.2,
    height: 1.2,
    color: ink,
  );
  static TextStyle titleStyle(Color ink, [double size = 21]) => AppText.display(
    size: size,
    weight: FontWeight.w600,
    height: 1.08,
    spacing: -0.3,
    color: ink,
  );
  static TextStyle lineStyle(Color ink, [double size = 12.5]) => AppText.body(
    size: size,
    weight: FontWeight.w500,
    height: 1.3,
    color: ink,
  );
  static TextStyle figureLabelStyle(Color ink, [double size = 11.5]) =>
      AppText.body(size: size, weight: FontWeight.w700, height: 1.2, color: ink);
  static TextStyle figureStyle(Color ink) => AppText.body(
    size: 12.5,
    weight: FontWeight.w800,
    height: 1.2,
    color: ink,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// The reader's text size, as far as a tile of a grid of four follows it.
  static TextScaler scalerOf(BuildContext context) =>
      MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.45);

  /// Whether the tile has room for what the challenge asks: not at the
  /// largest text sizes, where the name and the figure take the tile.
  static bool showsLine(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) <= 1.3;

  /// The size [text] is set at in [style], [inner] wide: [size], or less
  /// where its longest word would not fit the line — a word is never
  /// broken in the middle ("Sechzig Sekunden").
  static double fitSize(
    BuildContext context,
    String text,
    TextStyle Function(Color ink, double size) style,
    double inner, {
    required double size,
    required double least,
  }) {
    final TextScaler scaler = scalerOf(context);
    final TextDirection direction = Directionality.of(context);
    final TextStyle inherited = DefaultTextStyle.of(context).style;
    double widest(double at) {
      double most = 0;
      for (final String word in text.split(RegExp(r'\s+'))) {
        final TextPainter p = TextPainter(
          text: TextSpan(
            text: word,
            style: inherited.merge(style(Colors.black, at)),
          ),
          textDirection: direction,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        most = math.max(most, p.width);
        p.dispose();
      }
      return most;
    }

    double at = size;
    while (at > least && widest(at) > inner) {
      at -= 0.5;
    }
    return at;
  }

  /// The sizes [look]'s skill, name and line are set at, [inner] wide.
  static (double, double, double) sizesFor(
    BuildContext context,
    ChallengeLook look,
    double inner,
  ) => (
    fitSize(
      context,
      upper(context, look.skill),
      skillStyle,
      inner - markSide - 7,
      size: 9.5,
      least: 7,
    ),
    fitSize(context, look.title, titleStyle, inner, size: 21, least: 12),
    fitSize(context, look.line, lineStyle, inner, size: 12.5, least: 9),
  );

  /// How tall every tile is, [width] wide, for [looks] to all fit — so
  /// the tiles are one size on every page, at any text size.
  static double heightFor(
    BuildContext context,
    double width,
    Iterable<ChallengeLook> looks,
  ) {
    final TextScaler scaler = scalerOf(context);
    final TextDirection direction = Directionality.of(context);
    final TextStyle inherited = DefaultTextStyle.of(context).style;
    final double inner = width - pad.horizontal;
    double measure(String text, TextStyle style, double maxWidth) {
      final TextPainter p = TextPainter(
        text: TextSpan(text: text, style: inherited.merge(style)),
        textDirection: direction,
        textScaler: scaler,
      )..layout(maxWidth: maxWidth);
      final double h = p.height;
      p.dispose();
      return h;
    }

    double head = markSide, title = 0, line = 0, foot = 0;
    for (final ChallengeLook look in looks) {
      final (double s, double t, double w) = sizesFor(context, look, inner);
      head = math.max(
        head,
        measure(
          upper(context, look.skill),
          skillStyle(Colors.black, s),
          inner - markSide - 7,
        ),
      );
      title = math.max(
        title,
        measure(look.title, titleStyle(Colors.black, t), inner),
      );
      if (showsLine(context)) {
        line = math.max(
          line,
          measure(look.line, lineStyle(Colors.black, w), inner),
        );
      }
      if (look.figure case final ChallengeFigure f) {
        foot = math.max(
          foot,
          math.max(
            measure(f.label, figureLabelStyle(Colors.black), inner),
            measure(f.value, figureStyle(Colors.black), inner),
          ),
        );
      }
    }
    return (pad.top +
            head +
            _afterHead +
            title +
            (line > 0 ? _afterTitle + line : 0) +
            (foot > 0 ? _beforeFoot + foot : 0) +
            pad.bottom)
        .ceilToDouble();
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
    final TextScaler scaler = ChallengeTile.scalerOf(context);
    final ChallengeFigure? figure = look.figure;
    final Color ink = look.tone.ink;
    final Widget words = LayoutBuilder(
      builder: (context, box) {
        final double inner = box.maxWidth - ChallengeTile.pad.horizontal;
        final (double skill, double title, double line) = ChallengeTile
            .sizesFor(context, look, inner);
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // The mark again, large and faint, off the corner: the tile is
            // the challenge's colour first and its words second.
            Positioned(
              right: -14,
              bottom: -14,
              child: ChallengeMarkView(
                mark: look.mark,
                colour: ink.withValues(alpha: 0.13),
                size: box.maxWidth * 0.52,
              ),
            ),
            Padding(
              padding: ChallengeTile.pad,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ChallengeMarkView(
                        mark: look.mark,
                        colour: ink,
                        size: ChallengeTile.markSide,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          upper(context, look.skill),
                          key: const ValueKey('challenge-skill'),
                          textScaler: scaler,
                          style: ChallengeTile.skillStyle(
                            ink.withValues(alpha: 0.78),
                            skill,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ChallengeTile._afterHead),
                  Text(
                    look.title,
                    textScaler: scaler,
                    style: ChallengeTile.titleStyle(ink, title),
                  ),
                  if (ChallengeTile.showsLine(context)) ...[
                    const SizedBox(height: ChallengeTile._afterTitle),
                    Text(
                      look.line,
                      textScaler: scaler,
                      style: ChallengeTile.lineStyle(
                        ink.withValues(alpha: 0.74),
                        line,
                      ),
                    ),
                  ],
                  if (figure != null) ...[
                    const Spacer(),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${figure.label}  ',
                            style: ChallengeTile.figureLabelStyle(
                              ink.withValues(alpha: 0.74),
                            ),
                          ),
                          TextSpan(
                            text: figure.value,
                            style: ChallengeTile.figureStyle(ink),
                          ),
                        ],
                      ),
                      key: const ValueKey('challenge-figure'),
                      textScaler: scaler,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
    final Widget ground = ChallengeGround(
      colour: look.tone.vivid,
      shade: true,
      radius: kChallengeCorner,
      foreground: words,
    );
    final bool calm = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: [
        look.skill,
        look.title,
        look.line,
        if (figure != null) '${figure.label} ${figure.value}',
      ].join(', '),
      excludeSemantics: true,
      onTap: spec.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: spec.onTap,
        child: AnimatedScale(
          scale: _down && !calm ? 0.97 : 1,
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
