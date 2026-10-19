/// The pieces every bet is built from: the colours a tile is drawn in, the
/// shelf's head, the tile, the track a share is set on, the chips, the step
/// that asks how sure, the wallet, the rows tiles stand in, and the feel of
/// a control under the finger.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/balanced_text.dart';
import '../../../widgets/card_edge.dart';
import '../../../widgets/explore/parts.dart'
    show CardHead, FlatButton, fillOn, hairOn, subOn, upper;
import 'bets_day.dart';
import 'deal.dart';

// ── Colour ───────────────────────────────────────────────────────────────

/// The colours a bet is drawn in: a tile in its card's subject colour, or
/// a panel on the page.
@immutable
class BetInk {
  const BetInk({
    required this.ground,
    required this.ink,
    required this.fill,
    required this.hair,
    required this.sub,
    required this.onInk,
    required this.mark,
    this.edge,
  });

  /// The tile itself.
  final Color ground;

  /// Its words, and a control once chosen.
  final Color ink;

  /// A control at rest.
  final Color fill;

  /// A band on a track, a hairline between rows.
  final Color hair;

  /// The quieter words: a label, a count, a line under a question.
  final Color sub;

  /// Words on a chosen control.
  final Color onInk;

  /// The subject's mark in the head.
  final Color mark;

  /// The hairline that cuts a tile out of a page it would melt into.
  final BoxBorder? edge;

  /// [pill]'s tile, in [tone].
  factory BetInk.of(BuildContext context, Pill pill, BetTone tone) {
    if (tone == BetTone.subject) {
      return BetInk(
        ground: pill.color,
        ink: pill.ink,
        fill: fillOn(pill),
        hair: hairOn(pill),
        sub: subOn(pill),
        onInk: pill.color,
        mark: pill.ink,
        edge: cardHairline(pill.color, context.p.surface),
      );
    }
    final BetInk page = BetInk.page(context);
    // The subject's colour marks the head where it stands out from the
    // panel; where it would not (a pale subject on paper), the ink does.
    final bool shows = colourContrast(pill.color, page.ground) >= 2;
    return BetInk(
      ground: page.ground,
      ink: page.ink,
      fill: page.fill,
      hair: page.hair,
      sub: page.sub,
      onInk: page.onInk,
      mark: shows ? pill.color : page.ink,
    );
  }

  /// A panel on the page: the slip, the friend's card, the comparisons —
  /// the page's ink, a step off the page.
  factory BetInk.page(BuildContext context) {
    final p = context.p;
    return BetInk(
      ground: Color.alphaBlend(p.ink.withValues(alpha: 0.06), p.surface),
      ink: p.ink,
      fill: p.ink.withValues(alpha: 0.1),
      hair: p.ink.withValues(alpha: p.isDark ? 0.16 : 0.2),
      sub: p.ink.withValues(alpha: 0.55),
      onInk: p.onInverse,
      mark: p.ink,
    );
  }
}

/// The green a win is told in, light enough on the night paper and dark
/// enough on the day one, as the shelves above tell it.
Color betWin(BuildContext context) =>
    context.p.isDark ? const Color(0xFF3BE07A) : const Color(0xFF128A43);

// ── Feel ─────────────────────────────────────────────────────────────────

/// What a bet feels like under the finger, in one place: a click at every
/// step a control passes, a firmer one when a bet is laid, a light one
/// when it comes in. Never a heavy one: a bet lost is not an error.
abstract final class BetFeel {
  /// A step passed: a tenth of a track, a stepper's step, a choice.
  static void tick() => HapticFeedback.selectionClick();

  /// A bet laid, or a number locked.
  static void lay() => HapticFeedback.mediumImpact();

  /// A bet that came in.
  static void won() => HapticFeedback.lightImpact();
}

/// [ms], or nothing for a reader who asked for less motion: what a move
/// decorates is the same with it or without.
Duration betMotion(BuildContext context, int ms) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: ms);

// ── Words ────────────────────────────────────────────────────────────────

/// The first lines of a card's answer, under a verdict: a number checked
/// is a number explained, and the rest of the why is a tap away.
String firstLines(String answer, {int max = 150}) {
  final String text = answer.trim();
  final List<String> parts = text.split(
    RegExp(r'(?<=[.!?])\s+(?=[A-Z0-9"“‘(])'),
  );
  String out = parts.first;
  if (out.length < 60 && parts.length > 1) out = '$out ${parts[1]}';
  if (out.length > max) {
    final String cut = out.substring(0, max);
    final int space = cut.lastIndexOf(' ');
    out = '${cut.substring(0, space > 0 ? space : max)}…';
  }
  return out;
}

/// An option as it reads inside a sentence: "about 28", but "UK" and
/// "DNA" left as they are.
String inSentence(String text) {
  if (text.length < 2) return text;
  final String second = text[1];
  if (second.toUpperCase() == second && second.toLowerCase() != second) {
    return text;
  }
  return text[0].toLowerCase() + text.substring(1);
}

/// How tall [text] sets in [style] at [width], at the reader's text size.
double betTextHeight(
  BuildContext context,
  String text,
  TextStyle style,
  double width, {
  int? maxLines,
}) {
  final TextPainter painter = TextPainter(
    text: TextSpan(
      text: text,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: maxLines,
  )..layout(maxWidth: math.max(1, width));
  final double h = painter.height;
  painter.dispose();
  return h;
}

/// How many lines [text] takes in [style] at [width], at the reader's text
/// size, and whether its longest word fits a line whole.
(int, bool) _setIn(
  BuildContext context,
  String text,
  TextStyle style,
  double width,
) {
  final TextScaler scaler = MediaQuery.textScalerOf(context);
  final TextDirection direction = Directionality.of(context);
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: direction,
    textScaler: scaler,
  )..layout(maxWidth: math.max(1, width));
  final int lines = painter.computeLineMetrics().length;
  painter.dispose();
  double widest = 0;
  for (final String word in text.split(RegExp(r'\s+'))) {
    final TextPainter w = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    widest = math.max(widest, w.width);
    w.dispose();
  }
  return (lines, widest <= width);
}

/// A question in the app's voice: Fraunces, tight.
TextStyle questionStyle(double size, Color color) => AppText.display(
  size: size,
  weight: FontWeight.w600,
  height: 1.15,
  spacing: -0.027 * size,
  color: color,
);

/// The largest size from [max] down to [min] at which [text] sets in
/// [lines] lines or fewer at [width], no word broken: a long question set
/// a little smaller rather than a tile made taller for it, as the canvas
/// sets them. At a large text size it may take more lines than [lines];
/// it is never cut.
double questionSizeFor(
  BuildContext context,
  String text,
  double width, {
  double max = 18,
  double min = 14,
  int lines = 4,
}) {
  final TextScaler scaler = MediaQuery.textScalerOf(context);
  final String key =
      '$text|${width.round()}|$max|$min|$lines|${scaler.scale(100)}';
  final double? known = _sizes[key];
  if (known != null) return known;
  if (_sizes.length > 400) _sizes.clear();
  double fit() {
    for (double size = max; size >= min; size -= 0.5) {
      final (int n, bool whole) = _setIn(
        context,
        text,
        questionStyle(size, const Color(0xFF000000)),
        width,
      );
      if (n <= lines && whole) return size;
    }
    for (double size = min; size >= 11; size -= 0.5) {
      final (_, bool whole) = _setIn(
        context,
        text,
        questionStyle(size, const Color(0xFF000000)),
        width,
      );
      if (whole) return size;
    }
    return 11;
  }

  return _sizes[key] = fit();
}

/// Sizes already found: a tile is built again at every step of a drag,
/// and its question does not change size while it is.
final Map<String, double> _sizes = {};

// ── The shelf ────────────────────────────────────────────────────────────

/// A shelf of bets: what it holds and why, level with whatever it keeps
/// count of — the points left — and the bets under it. The same head every
/// shelf of Explore has.
class BetShelf extends StatelessWidget {
  const BetShelf({
    super.key,
    required this.title,
    required this.line,
    required this.child,
    this.trailing,
  });

  final String title;
  final String line;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Widget name = Text(
      title,
      style: AppText.body(
        size: 16,
        weight: FontWeight.w600,
        height: 1.15,
        spacing: -0.2,
        color: context.p.ink,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The count sits level with the name, and the line runs under
              // both, so a long one in any language keeps to its width.
              if (trailing == null)
                name
              else
                Row(
                  children: [
                    Expanded(child: name),
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ),
              if (line.isNotEmpty) ...[
                SizedBox(height: trailing == null ? 3 : 4),
                BalancedText(
                  line,
                  style: AppText.body(
                    size: 12,
                    height: 1.3,
                    color: context.p.ink.withValues(alpha: 0.42),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 11),
        child,
      ],
    );
  }
}

/// The day's points, level with a shelf's name: what a bet is paid from.
class BetWallet extends StatelessWidget {
  const BetWallet({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BetsDay.instance,
      builder: (context, _) {
        final int points = BetsDay.instance.points;
        return Semantics(
          label: context.l10n.betsWalletSays(points),
          excludeSemantics: true,
          child: Container(
            key: const ValueKey('bets-wallet'),
            constraints: const BoxConstraints(minHeight: 30),
            padding: const EdgeInsets.fromLTRB(8, 4, 11, 4),
            decoration: BoxDecoration(
              color: context.p.inverse,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.adjust_rounded,
                  size: 15,
                  color: context.p.onInverse,
                ),
                const SizedBox(width: 6),
                Text(
                  '$points',
                  style: AppText.body(
                    size: 12.5,
                    weight: FontWeight.w700,
                    height: 1,
                    color: context.p.onInverse,
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

// ── The tile ─────────────────────────────────────────────────────────────

/// How big a tile is: its width, padding and the most its question is set
/// at. `s` and `m` stand in a row that scrolls sideways; `l` is the width
/// of the page, one under another.
@immutable
class BetTileSize {
  const BetTileSize._(this.name, this.width, this.padding, this.question);

  final String name;

  /// Its width, or null for the page's.
  final double? width;
  final double padding;

  /// The size its question is set at, at most.
  final double question;

  static const BetTileSize s = BetTileSize._('s', 264, 16, 16);
  static const BetTileSize m = BetTileSize._('m', 300, 18, 18);
  static const BetTileSize l = BetTileSize._('l', null, 18, 19.5);

  static BetTileSize named(String name) => switch (name) {
    's' => s,
    'l' => l,
    _ => m,
  };

  /// Whether tiles of this size stand in a row.
  bool get inRow => width != null;

  /// The width its words have, on a page [page] wide.
  double inner(double page) => (width ?? page - 40) - padding * 2;
}

/// A bet's tile: its card's head and question, and under them the game —
/// the options, the track, the steppers. Once the bet is laid, the tile is
/// the card, and a tap opens it.
class BetFrame extends StatelessWidget {
  const BetFrame({
    super.key,
    required this.pill,
    required this.ink,
    required this.size,
    required this.game,
    this.top,
    this.onOpen,
    this.read = false,
    this.questionMax,
  });

  final Pill pill;
  final BetInk ink;
  final BetTileSize size;

  /// What is played.
  final Widget game;

  /// Something over the head: the bet of the day's tag.
  final Widget? top;

  /// Opens the card, once there is nothing left to give away.
  final VoidCallback? onOpen;

  /// Read already: the tick after the subject.
  final bool read;

  /// The most the question is set at, where the tile sets it larger or
  /// smaller than its size does.
  final double? questionMax;

  @override
  Widget build(BuildContext context) {
    final double page = MediaQuery.sizeOf(context).width;
    final double inner = size.inner(page);
    final double qSize = questionSizeFor(
      context,
      pill.question,
      inner,
      max: questionMax ?? size.question,
      min: math.min(14, (questionMax ?? size.question) - 2),
    );
    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (top != null) ...[top!, const SizedBox(height: 14)],
        CardHead(
          pill: pill,
          label: context.l10n.subjectOf(pill.topic),
          ink: ink.mark,
          labelInk: ink.sub,
          trailing: read
              ? Icon(
                  Icons.check_circle_rounded,
                  key: ValueKey('explore-read-${pill.id}'),
                  size: 14,
                  color: ink.ink.withValues(alpha: 0.8),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Text(pill.question, style: questionStyle(qSize, ink.ink)),
        // In a row the tiles are as tall as the tallest, and every game
        // sits on its tile's foot, level with its neighbours'.
        if (size.inRow) const Spacer() else const SizedBox(height: 0),
        const SizedBox(height: 14),
        game,
      ],
    );
    final Widget tile = Container(
      width: size.width,
      padding: EdgeInsets.all(size.padding),
      decoration: BoxDecoration(
        color: ink.ground,
        borderRadius: BorderRadius.circular(22),
        border: ink.edge,
      ),
      child: body,
    );
    if (onOpen == null) return tile;
    return Semantics(
      button: true,
      label: context.l10n.betsOpenCard,
      child: GestureDetector(
        key: ValueKey('explore-${pill.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: tile,
      ),
    );
  }
}

/// What a game came to, in a sentence on the tile.
class BetVerdict extends StatelessWidget {
  const BetVerdict(this.text, {super.key, required this.ink});

  final String text;
  final BetInk ink;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        text,
        style: AppText.body(
          size: 13,
          weight: FontWeight.w600,
          height: 1.4,
          color: ink.ink,
        ),
      ),
    );
  }
}

/// The first lines of the card's answer, under a verdict.
class BetWhy extends StatelessWidget {
  const BetWhy(this.pill, {super.key, required this.ink});

  final Pill pill;
  final BetInk ink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        firstLines(pill.answer),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: AppText.body(
          size: 12,
          weight: FontWeight.w500,
          height: 1.38,
          color: ink.ink.withValues(alpha: 0.78),
        ),
      ),
    );
  }
}

/// Room kept for the tallest of a tile's states, so a row of tiles does
/// not grow under the reader's finger when a bet is laid: the state it
/// will come to laid out unseen, and the one it is in drawn over it, on
/// the tile's foot. In a column, where a tile growing moves nothing the
/// finger is on, the room is not kept.
class BetRoom extends StatelessWidget {
  const BetRoom({
    super.key,
    required this.child,
    this.ghosts = const [],
    this.keep = true,
  });

  final Widget child;

  /// The states to keep room for.
  final List<Widget> ghosts;

  /// Whether to keep it.
  final bool keep;

  @override
  Widget build(BuildContext context) {
    if (ghosts.isEmpty || !keep) return child;
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        for (final Widget g in ghosts)
          ExcludeSemantics(
            child: IgnorePointer(
              child: Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: g,
              ),
            ),
          ),
        child,
      ],
    );
  }
}

// ── Controls ─────────────────────────────────────────────────────────────

/// A chip on a tile: a width, an option, a stake, a step. Lit in the
/// tile's ink once chosen; dimmed once its moment is past; ringed where it
/// was the reader's and not the right one.
class BetChip extends StatelessWidget {
  const BetChip({
    super.key,
    required this.label,
    required this.ink,
    this.on = false,
    this.dim = false,
    this.ring = false,
    this.onTap,
    this.height = 32,
    this.radius = 10,
    this.size = 11,
    this.weight = FontWeight.w700,
    this.semantics,
    this.padding = 6,
    this.icon,
  });

  final String label;
  final BetInk ink;
  final bool on;
  final bool dim;
  final bool ring;
  final VoidCallback? onTap;
  final double height;
  final double radius;
  final double size;
  final FontWeight weight;
  final double padding;

  /// What a screen reader says for it, where the label alone is not enough.
  final String? semantics;

  /// A mark before the label: an arrow for more or less.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Duration motion = betMotion(context, 200);
    final Color fg = on ? ink.onInk : ink.ink;
    final Widget text = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 2,
      style: AppText.body(size: size, weight: weight, height: 1.1, color: fg),
    );
    return Semantics(
      button: onTap != null,
      selected: on,
      label: semantics,
      excludeSemantics: semantics != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          duration: motion,
          opacity: dim ? 0.4 : 1,
          child: AnimatedContainer(
            duration: motion,
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(minHeight: height),
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on
                  ? ink.ink
                  : (ring ? ink.ink.withValues(alpha: 0) : ink.fill),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: ring ? ink.ink : ink.ink.withValues(alpha: 0),
                width: 2,
              ),
            ),
            child: icon == null
                ? text
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(child: Icon(icon, size: 15, color: fg)),
                      const SizedBox(width: 7),
                      Flexible(child: text),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// The tile's one button: filled in its ink, its words in its ground.
class BetButton extends StatelessWidget {
  const BetButton({
    super.key,
    required this.label,
    required this.ink,
    required this.onTap,
    this.height = 36,
    this.expand = false,
  });

  final String label;
  final BetInk ink;
  final VoidCallback? onTap;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    // Taller at a large text size, never cut: the label is the button.
    final double h = math.max(
      height,
      MediaQuery.textScalerOf(context).scale(12.5) + 20,
    );
    return FlatButton(
      label: label,
      background: ink.ink,
      foreground: ink.onInk,
      height: h,
      expand: expand,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      onTap: onTap,
    );
  }
}

/// The step between laying a bet and finding out: how sure are you? The
/// card's own question, at the card's own levels, so a bet on a shelf
/// counts towards how sure against how right like an answer on the card.
class SureStep extends StatelessWidget {
  const SureStep({
    super.key,
    required this.pill,
    required this.ink,
    required this.width,
    required this.onPick,
  });

  final Pill pill;
  final BetInk ink;

  /// The width the step has.
  final double width;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final TextStyle chip = AppText.body(
      size: 12.5,
      weight: FontWeight.w700,
      height: 1,
    );
    // One row of five where five fit; otherwise as many as fit on a line.
    final double widest = _widthOf(context, '${kConfidenceLevels.last}%', chip);
    final bool row = 5 * (widest + 14) + 4 * 6 <= width;
    Widget level(int pct) => BetChip(
      key: ValueKey('bets-sure-${pill.id}-$pct'),
      label: '$pct%',
      ink: ink,
      height: 34,
      size: 12.5,
      semantics: l.percentSure(pct),
      onTap: () {
        BetFeel.lay();
        onPick(pct);
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.howSureAreYou,
          style: AppText.display(
            size: 15,
            weight: FontWeight.w600,
            height: 1.2,
            spacing: -0.3,
            color: ink.ink,
          ),
        ),
        const SizedBox(height: 10),
        if (row)
          Row(
            children: [
              for (int i = 0; i < kConfidenceLevels.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: level(kConfidenceLevels[i])),
              ],
            ],
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final int pct in kConfidenceLevels)
                SizedBox(width: widest + 24, child: level(pct)),
            ],
          ),
      ],
    );
  }

  static double _widthOf(BuildContext context, String text, TextStyle style) {
    final TextPainter p = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final double w = p.width;
    p.dispose();
    return w;
  }
}

/// A small label in capitals: STAKE, 1 IN, STEP 1 OF 3.
class BetKicker extends StatelessWidget {
  const BetKicker(this.text, {super.key, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      upper(context, text),
      style: AppText.label(
        size: 9,
        weight: FontWeight.w700,
        spacing: 1.2,
        height: 1.2,
        color: color,
      ),
    );
  }
}

// ── The track ────────────────────────────────────────────────────────────

/// A share set on a track from nought to a hundred: the rail, what is set
/// — a band either side of the thumb for a range, the rail filled up to it
/// for a guess — the thumb, and once the bet is laid, where the answer is.
///
/// It snaps to whole points and clicks at every tenth, so the scale can be
/// felt without looking; the thumb swells a little while it is held, and
/// glides to where a tap puts it, unless the reader asked for less motion.
class BetTrack extends StatefulWidget {
  const BetTrack({
    super.key,
    required this.ink,
    required this.value,
    required this.label,
    required this.say,
    this.onChanged,
    this.band,
    this.filled = false,
    this.answer,
  });

  final BetInk ink;

  /// Where it is set, 0 to 100.
  final double value;

  /// What a screen reader calls it.
  final String label;

  /// How a value is said: "40%".
  final String Function(double) say;

  /// Null once the bet is laid: the track stays as it was, and shows.
  final ValueChanged<double>? onChanged;

  /// For a range: how far it reaches either side of the thumb.
  final double? band;

  /// For a guess: the rail filled in the ink up to the thumb.
  final bool filled;

  /// Once laid, the answer: from the first to the second, the same twice
  /// for an answer that is one figure.
  final (double, double)? answer;

  @override
  State<BetTrack> createState() => _BetTrackState();
}

class _BetTrackState extends State<BetTrack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  )..addListener(() => setState(() {}));
  double _from = 0;
  bool _held = false;

  @override
  void dispose() {
    _glide.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BetTrack old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_held) {
      // A jump made by a tap glides; a drag is followed exactly.
      _from = _shown(old.value);
      if (MediaQuery.disableAnimationsOf(context)) {
        _glide.value = 1;
      } else {
        _glide.forward(from: 0);
      }
    }
  }

  double _shown([double? target]) {
    final double to = target ?? widget.value;
    if (!_glide.isAnimating) return to;
    final double t = Curves.easeOutCubic.transform(_glide.value);
    return _from + (to - _from) * t;
  }

  double _at(Offset local, Size size) {
    final double w = math.max(1, size.width - 22);
    return ((local.dx - 11) / w * 100).clamp(0, 100).roundToDouble();
  }

  void _set(double v) {
    final ValueChanged<double>? set = widget.onChanged;
    if (set == null || v == widget.value) return;
    final int was = (widget.value / 10).floor();
    final int now = (v / 10).floor();
    if (was != now || v == 0 || v == 100) BetFeel.tick();
    set(v);
  }

  void _press(Offset local) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    _set(_at(local, box.size));
  }

  @override
  Widget build(BuildContext context) {
    final bool open = widget.onChanged != null;
    final double v = widget.value;
    return Semantics(
      slider: open,
      label: widget.label,
      value: widget.say(v),
      increasedValue: open ? widget.say(math.min(100, v + 1)) : null,
      decreasedValue: open ? widget.say(math.max(0, v - 1)) : null,
      onIncrease: open ? () => _set(math.min(100, v + 1)) : null,
      onDecrease: open ? () => _set(math.max(0, v - 1)) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: open ? (d) => _press(d.localPosition) : null,
        onHorizontalDragStart: open
            ? (d) {
                setState(() => _held = true);
                _press(d.localPosition);
              }
            : null,
        onHorizontalDragUpdate: open ? (d) => _press(d.localPosition) : null,
        onHorizontalDragEnd: open ? (_) => setState(() => _held = false) : null,
        onHorizontalDragCancel: open
            ? () => setState(() => _held = false)
            : null,
        child: SizedBox(
          height: 28,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrackPainter(
              ink: widget.ink,
              value: _shown(),
              band: widget.band,
              filled: widget.filled,
              answer: widget.answer,
              held: _held,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  const _TrackPainter({
    required this.ink,
    required this.value,
    required this.band,
    required this.filled,
    required this.answer,
    required this.held,
  });

  final BetInk ink;
  final double value;
  final double? band;
  final bool filled;
  final (double, double)? answer;
  final bool held;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width - 22;
    double x(double v) => 11 + w * v.clamp(0, 100) / 100;
    final RRect rail = RRect.fromLTRBR(
      0,
      11,
      size.width,
      17,
      const Radius.circular(9),
    );
    canvas.drawRRect(rail, Paint()..color = ink.fill);
    if (filled) {
      canvas.drawRRect(
        RRect.fromLTRBR(0, 11, x(value), 17, const Radius.circular(9)),
        Paint()..color = ink.ink,
      );
    }
    final double? half = band;
    if (half != null) {
      final double lo = x(value - half), hi = x(value + half);
      canvas.drawRRect(
        RRect.fromLTRBR(lo, 6, hi, 22, const Radius.circular(8)),
        Paint()..color = ink.hair,
      );
    }
    final (double, double)? a = answer;
    if (a != null) {
      // A figure is a bar four wide; a stretch ("3–8%") is as wide as it
      // reaches, and never narrower than the bar.
      final double from = x(a.$1), to = x(a.$2);
      final double mid = (from + to) / 2;
      final double half = math.max(2, (to - from) / 2);
      canvas.drawRRect(
        RRect.fromLTRBR(
          mid - half,
          1,
          mid + half,
          27,
          const Radius.circular(2),
        ),
        Paint()..color = ink.ink,
      );
    }
    final Offset centre = Offset(x(value), 14);
    final double r = held ? 12.5 : 11;
    canvas.drawCircle(centre, r, Paint()..color = ink.ground);
    canvas.drawCircle(
      centre,
      r - 1.5,
      Paint()
        ..color = ink.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.value != value ||
      old.band != band ||
      old.answer != answer ||
      old.held != held ||
      old.filled != filled ||
      old.ink.ink != ink.ink ||
      old.ink.ground != ink.ground;
}

// ── Rows ─────────────────────────────────────────────────────────────────

/// Tiles in a row that scrolls sideways, at the margins every shelf keeps,
/// all as tall as the tallest, as the canvas lays them. [onSeen] is told of
/// each tile once, when any of it comes on screen.
class BetRow extends StatefulWidget {
  const BetRow({
    super.key,
    required this.count,
    required this.tileWidth,
    required this.builder,
    this.onSeen,
    this.gap = 10,
  });

  final int count;
  final double tileWidth;
  final IndexedWidgetBuilder builder;
  final ValueChanged<int>? onSeen;
  final double gap;

  @override
  State<BetRow> createState() => _BetRowState();
}

class _BetRowState extends State<BetRow> {
  final ScrollController _scroll = ScrollController();
  final Set<int> _seen = {};

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_look);
    WidgetsBinding.instance.addPostFrameCallback((_) => _look());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _look() {
    if (!mounted || widget.onSeen == null) return;
    final double from = _scroll.hasClients ? _scroll.offset : 0;
    final double to =
        from +
        (_scroll.hasClients
            ? _scroll.position.viewportDimension
            : MediaQuery.sizeOf(context).width);
    for (int i = 0; i < widget.count; i++) {
      final double left = 20 + i * (widget.tileWidth + widget.gap);
      if (left < to && left + widget.tileWidth > from && _seen.add(i)) {
        widget.onSeen!(i);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < widget.count; i++) ...[
              if (i > 0) SizedBox(width: widget.gap),
              SizedBox(
                width: widget.tileWidth,
                child: widget.builder(context, i),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tiles one under another, the width of the page, as 139e lays them.
class BetColumn extends StatelessWidget {
  const BetColumn({
    super.key,
    required this.count,
    required this.builder,
    this.gap = 10,
  });

  final int count;
  final IndexedWidgetBuilder builder;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < count; i++) ...[
            if (i > 0) SizedBox(height: gap),
            builder(context, i),
          ],
        ],
      ),
    );
  }
}

/// Tiles in [size]: a row for `s` and `m`, a column for `l`. Each tile is
/// a card shown, told to [onSeen] once, when it first comes on screen.
class BetTiles extends StatefulWidget {
  const BetTiles({
    super.key,
    required this.size,
    required this.count,
    required this.builder,
    required this.onSeen,
  });

  final BetTileSize size;
  final int count;
  final IndexedWidgetBuilder builder;
  final ValueChanged<int> onSeen;

  @override
  State<BetTiles> createState() => _BetTilesState();
}

class _BetTilesState extends State<BetTiles> {
  final Set<int> _told = {};

  void _seen(int i) {
    if (_told.add(i)) widget.onSeen(i);
  }

  @override
  void initState() {
    super.initState();
    if (!widget.size.inRow) {
      // A column shows all of its tiles at once, as the shelf comes up.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (int i = 0; i < widget.count; i++) {
          _seen(i);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.size.inRow) {
      return BetRow(
        count: widget.count,
        tileWidth: widget.size.width!,
        builder: widget.builder,
        onSeen: _seen,
      );
    }
    return BetColumn(count: widget.count, builder: widget.builder);
  }
}
