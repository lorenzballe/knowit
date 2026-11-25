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

import '../../l10n/l10n.dart';
import '../../theme.dart';
import 'challenge_marks.dart';
import 'parts.dart' show upper;

/// A challenge's colour, from the subjects' wheel, kept calm: its tile a
/// softened tone of it (a pastel on paper, a deep one at night), its
/// screen a tint of the page, and a deep tone on paper and a lifted one at
/// night for its mark, a fine rule and its primary button.
@immutable
class ChallengeTone {
  const ChallengeTone(this.deep, this.lifted, this.vivid);

  /// The colour as the wheel has it, never shown as it is: what the tile's
  /// and the page's tones are taken from.
  final Color vivid;

  /// The tile's ground: the colour with its saturation taken down, light
  /// on paper and deep at night.
  Color tile(Palette p) {
    final HSLColor c = HSLColor.fromColor(vivid);
    return c
        .withSaturation((c.saturation * (p.isDark ? 0.42 : 0.62)).clamp(0, 1))
        .withLightness(p.isDark ? 0.2 : 0.86)
        .toColor();
  }

  /// The screen's ground: the page, tinted with the tile.
  Color page(Palette p) =>
      Color.lerp(p.surface, tile(p), p.isDark ? 0.6 : 0.55)!;

  /// On the day's paper.
  final Color deep;

  /// On the night's.
  final Color lifted;

  /// The tone on [p].
  Color on(Palette p) => p.isDark ? lifted : deep;

  /// The words on a button of the tone: as on the app's inverse buttons.
  Color inkOn(Palette p) => p.onInverse;
}

/// The calm colours a verdict is told in: a green for right, a red for
/// wrong, each a quiet tone of the page it is on.
Color challengeRight(Palette p) =>
    p.isDark ? const Color(0xFF8CC6A6) : const Color(0xFF2E6A4D);
Color challengeWrong(Palette p) =>
    p.isDark ? const Color(0xFFE8988A) : const Color(0xFF9E3A2D);

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
const double kChallengeCorner = 14;

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
    this.radius = 0,
    this.border,
    this.foreground,
    this.foregroundSize,
    this.foregroundOpacity = 1,
  });

  final Color colour;
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
        color: colour,
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

/// One challenge's tile: the skill it trains across its top, the name, what
/// it asks, and at its foot the reader's own figure and the challenge's
/// mark.
class ChallengeTile extends StatefulWidget {
  const ChallengeTile({super.key, required this.spec});

  final ChallengeTileSpec spec;

  /// The words' room from the tile's edges.
  static const EdgeInsets pad = EdgeInsets.fromLTRB(14, 14, 13, 13);

  /// The mark's side.
  static const double markSide = 24;

  /// Between the skill and the name, the name and its line, and the line
  /// and the foot at the least.
  static const double _afterSkill = 12;
  static const double _afterTitle = 5;
  static const double _beforeFoot = 14;

  /// The skill, the name and what it asks as the tile sets them, at [size].
  static TextStyle skillStyle(Color ink, [double size = 10.5]) =>
      challengeSmallCaps(ink, size);
  static TextStyle titleStyle(Color ink, [double size = 19.5]) =>
      AppText.display(
        size: size,
        weight: FontWeight.w500,
        height: 1.12,
        spacing: -0.012 * size,
        color: ink,
      );
  static TextStyle lineStyle(Color ink, [double size = 12.5]) =>
      AppText.body(size: size, height: 1.36, color: ink);

  /// The figure's name, and the figure, in tabular figures.
  static TextStyle figureLabelStyle(Color ink, [double size = 12]) =>
      AppText.body(
        size: size,
        weight: FontWeight.w500,
        height: 1.2,
        color: ink,
      );
  static TextStyle figureStyle(Color ink) => AppText.body(
    size: 13,
    weight: FontWeight.w600,
    height: 1.2,
    color: ink,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// The reader's text size, as far as a tile of a grid of four follows
  /// it: nearly half as large again, and no further, so four still fit a
  /// page.
  static TextScaler scalerOf(BuildContext context) =>
      MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.45);

  /// Whether the tile has room for what the challenge asks: not at the
  /// largest text sizes, where the name and the figure take the tile.
  static bool showsLine(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) <= 1.3;

  /// The size [text] is set at in [style] on a tile whose words are [inner]
  /// wide: [size], or less where its longest word would not fit the line,
  /// down to [least] — a word is never broken in the middle ("Sechzig
  /// Sekunden", "KALIBRIERUNG").
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
      inner,
      size: 10.5,
      least: 7,
    ),
    fitSize(context, look.title, titleStyle, inner, size: 19.5, least: 12),
    fitSize(context, look.line, lineStyle, inner, size: 12.5, least: 9),
  );

  /// How tall every tile is, [width] wide, for [looks] to all fit: the
  /// most lines any of them has of each part — so the tiles are one size
  /// on every page, at any text size.
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

    double skill = 0, title = 0, line = 0, foot = markSide;
    for (final ChallengeLook look in looks) {
      final (double s, double t, double w) = sizesFor(context, look, inner);
      skill = math.max(
        skill,
        measure(upper(context, look.skill), skillStyle(Colors.black, s), inner),
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
            skill +
            _afterSkill +
            title +
            (line > 0 ? _afterTitle + line : 0) +
            _beforeFoot +
            foot +
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
    final Palette p = context.p;
    final TextScaler scaler = ChallengeTile.scalerOf(context);
    final ChallengeFigure? figure = look.figure;
    final Widget words = LayoutBuilder(
      builder: (context, box) {
        final double inner = box.maxWidth - ChallengeTile.pad.horizontal;
        final (double skill, double title, double line) =
            ChallengeTile.sizesFor(context, look, inner);
        // The figure's name as large as its room beside the figure and
        // the mark takes, never broken.
        double figureLabel = 12;
        if (figure != null) {
          final TextPainter value = TextPainter(
            text: TextSpan(
              text: figure.value,
              style: DefaultTextStyle.of(context).style
                  .merge(ChallengeTile.figureStyle(p.ink)),
            ),
            textDirection: Directionality.of(context),
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          figureLabel = ChallengeTile.fitSize(
            context,
            figure.label,
            ChallengeTile.figureLabelStyle,
            inner - ChallengeTile.markSide - 8 - 7 - value.width,
            size: 12,
            least: 8,
          );
          value.dispose();
        }
        return Padding(
          padding: ChallengeTile.pad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                upper(context, look.skill),
                key: const ValueKey('challenge-skill'),
                textScaler: scaler,
                style: ChallengeTile.skillStyle(p.inkMuted, skill),
              ),
              const SizedBox(height: ChallengeTile._afterSkill),
              Text(
                look.title,
                textScaler: scaler,
                style: ChallengeTile.titleStyle(p.ink, title),
              ),
              if (ChallengeTile.showsLine(context)) ...[
                const SizedBox(height: ChallengeTile._afterTitle),
                Text(
                  look.line,
                  textScaler: scaler,
                  style: ChallengeTile.lineStyle(p.inkMuted, line),
                ),
              ],
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: figure == null
                        ? const SizedBox.shrink()
                        : Row(
                            key: const ValueKey('challenge-figure'),
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: Text(
                                  figure.label,
                                  textScaler: scaler,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ChallengeTile.figureLabelStyle(
                                    p.inkMuted,
                                    figureLabel,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                figure.value,
                                textScaler: scaler,
                                style: ChallengeTile.figureStyle(p.ink),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 8),
                  ChallengeMarkView(
                    mark: look.mark,
                    colour: look.tone.on(p),
                    size: ChallengeTile.markSide,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    final Widget ground = ChallengeGround(
      colour: look.tone.tile(p),
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
        child: AnimatedOpacity(
          opacity: _down ? 0.72 : 1,
          duration: calm ? Duration.zero : const Duration(milliseconds: 120),
          curve: Curves.easeOut,
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
