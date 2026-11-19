/// Explore's cover: the first thing on the page, and the one that has to
/// make a reader stop.
///
/// The day's cards in a mosaic, laid as a magazine lays its cover: two
/// cards large, their questions set big, and two small beside each, every
/// one in words, in its subject's colour, as every card on Explore is. The
/// large one stands on the left and then on the right, so the eye goes down
/// the page in a zigzag, as it does down Instagram's Explore. No name above
/// it: the cards are the cover.
///
/// Its cards are the section's source, the same for everyone on the day,
/// less what the reader has read; every card on it is of a subject of its
/// own where the deal has enough. The first time Explore opens it comes up a
/// tile at a time; after that it is simply there.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/pill.dart';
import '../../../widgets/explore/card_tiles.dart';
import '../../explore_block.dart';
import 'layout.dart';

/// The room between two tiles of the cover, across and down.
const double kCoverSpacing = 8;

/// The cover: see the library's own words.
class CoverBlock extends ExploreBlock with SectionLayout {
  const CoverBlock();

  @override
  String get name => 'cover';

  /// Close under the subjects: the cover is the top of the page, not a
  /// shelf a gap below it.
  @override
  double get gap => 6;

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> cards = host.cardsFor(section, limit: 60);
    if (cards.length < 3) return null;
    return SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      child: CoverMosaic(host: host, section: section, cards: cards),
    );
  }
}

/// How the cover measures on a page [across] points wide, less its
/// margins: a large tile three fifths of the width, as tall as a card on
/// the day's shelf of that width; beside it two small ones, one above the
/// other.
@immutable
class CoverGrid {
  CoverGrid(this.across)
    : large = math.max(0, (across - kCoverSpacing) * 3 / 5);

  /// The width the cover takes.
  final double across;

  /// A large tile's width.
  final double large;

  /// A small tile's width.
  double get small => math.max(0, across - kCoverSpacing - large);

  /// How tall a group is: a large tile, or two small ones and the room
  /// between them.
  double get group => large / WebThumbs.shelfAspect;

  /// A large tile.
  Size get largeBox => Size(large, group);

  /// A small tile.
  Size get smallBox => Size(small, math.max(0, (group - kCoverSpacing) / 2));

  /// How tall the cover is with [groups] groups.
  double heightOf(int groups) =>
      groups * group + math.max(0, groups - 1) * kCoverSpacing;
}

/// The cover's cards, a group at a time: the large one, then the two small.
@immutable
class CoverDeal {
  const CoverDeal._(this.groups);

  /// Each group's cards: the large one first.
  final List<List<Pill>> groups;

  /// Every card of the cover, in the order the eye meets them, which is the
  /// order a swipe from one to the next follows once one is open.
  List<Pill> get laid => [for (final List<Pill> g in groups) ...g];

  /// The cover from [cards], in their order, in [grid]'s tiles, at most
  /// [most] groups, or null when not even one can be laid whole.
  ///
  /// The large tiles take the longest questions among the first cards
  /// dealt, a subject each, in the order they were dealt: the question set
  /// big is the cover's poster, and the short ones are left for the small
  /// tiles, where a long one would be set small. A small tile takes the
  /// first card whose question it sets near the top of its type, of a
  /// subject not on the cover yet before one that is, and only where there
  /// is none any card it holds whole. As many groups are laid as there are
  /// a large card and two small ones for.
  static CoverDeal? of(
    BuildContext context,
    List<Pill> cards,
    CoverGrid grid, {
    required bool Function(Pill) isRead,
    int most = 2,
  }) {
    final TileLook small = TileLook.forBox(grid.smallBox);
    final TileLook large = TileLook.forBox(grid.largeBox);
    // A small tile is a glance: a question short enough to be set near the
    // top of its type, never six lines of small print beside the poster.
    final TileLook glance = small.withMin(small.max - 1.5);
    bool holdsSmall(Pill p) =>
        questionFits(context, p, grid.smallBox, small, read: isRead(p));
    bool glancesSmall(Pill p) =>
        questionFits(context, p, grid.smallBox, glance, read: isRead(p));
    bool holdsLarge(Pill p) =>
        questionFits(context, p, grid.largeBox, large, read: isRead(p));
    // The first cards dealt, a subject each: twice as many as the cover
    // shows, so the large tiles have a choice of questions.
    final List<Pill> first = [];
    for (final Pill p in cards) {
      if (first.length == most * 6) break;
      if (!first.any((f) => f.topic == p.topic) && holdsLarge(p)) first.add(p);
    }
    final List<Pill> leads =
        ([...first]..sort((a, b) => b.question.length - a.question.length))
            .take(most)
            .toList()
          ..sort((a, b) => cards.indexOf(a) - cards.indexOf(b));
    final Set<String> used = {for (final Pill p in leads) p.id};
    final Set<String> subjects = {for (final Pill p in leads) p.topic};
    while (leads.length < most) {
      final Pill? next =
          _first(
            cards,
            (p) =>
                !used.contains(p.id) &&
                !subjects.contains(p.topic) &&
                holdsLarge(p),
          ) ??
          _first(cards, (p) => !used.contains(p.id) && holdsLarge(p));
      if (next == null) break;
      leads.add(next);
      used.add(next.id);
      subjects.add(next.topic);
    }
    final List<Pill> smalls = [];
    // Short questions of subjects not on the cover yet first, then short
    // ones of any subject, then any the tile holds whole.
    for (final (bool freshOnly, bool glance) in const [
      (true, true),
      (false, true),
      (true, false),
      (false, false),
    ]) {
      for (final Pill p in cards) {
        if (smalls.length == leads.length * 2) break;
        if (used.contains(p.id) || (freshOnly && subjects.contains(p.topic))) {
          continue;
        }
        if (!(glance ? glancesSmall(p) : holdsSmall(p))) continue;
        smalls.add(p);
        used.add(p.id);
        subjects.add(p.topic);
      }
    }
    final int groups = math.min(leads.length, smalls.length ~/ 2);
    if (groups == 0) return null;
    return CoverDeal._([
      for (int g = 0; g < groups; g++)
        [leads[g], smalls[2 * g], smalls[2 * g + 1]],
    ]);
  }

  static Pill? _first(List<Pill> cards, bool Function(Pill) test) {
    for (final Pill p in cards) {
      if (test(p)) return p;
    }
    return null;
  }
}

/// The cover's tiles, laid by [CoverDeal], each opening its card.
class CoverMosaic extends StatefulWidget {
  const CoverMosaic({
    super.key,
    required this.host,
    required this.section,
    required this.cards,
  });

  final ExploreHost host;
  final ExploreSection section;

  /// The cards to lay the cover from, in the section's order.
  final List<Pill> cards;

  /// Whether the cover has come up since the app opened: it comes up a tile
  /// at a time the first time only, and is simply there after, so a reader
  /// who comes back to Explore is not made to wait for it.
  static bool cameUp = false;

  /// How long the cover takes to come up, its last tile included.
  static const Duration rise = Duration(milliseconds: 900);

  @override
  State<CoverMosaic> createState() => _CoverMosaicState();
}

class _CoverMosaicState extends State<CoverMosaic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rise = AnimationController(
    vsync: this,
    duration: CoverMosaic.rise,
  );

  /// The tabs' own scroll, listened to while the cover waits to be seen.
  ScrollPosition? _tabs;

  /// Whether a look at the screen is due after the next frame.
  bool _looking = false;

  /// Whether the cover has still to come up.
  bool get _waiting => !CoverMosaic.cameUp && !_rise.isAnimating;

  @override
  void initState() {
    super.initState();
    if (CoverMosaic.cameUp) {
      _rise.value = 1;
    } else {
      _look();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      CoverMosaic.cameUp = true;
      _rise.value = 1;
    }
    if (!_waiting) return;
    // The tabs' scroll, listened to afresh whenever it is another: the tabs
    // make a new one each time they change how they scroll (they stand
    // still while a card is on the table), and one let go of never moves.
    final ScrollPosition? tabs = Scrollable.maybeOf(
      context,
      axis: Axis.horizontal,
    )?.position;
    if (tabs == _tabs) return;
    _tabs?.removeListener(_look);
    _tabs = tabs?..addListener(_look);
    _look();
  }

  /// Looks once the next frame is laid out, when where the cover is drawn
  /// is known: as it is first built, and whenever the tabs move.
  void _look() {
    if (_looking) return;
    _looking = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _looking = false;
      _riseWhenSeen();
    });
  }

  /// Starts the cover coming up once it is on the screen. Explore is built
  /// beside the tab on screen before a reader goes to it, and a cover that
  /// came up there would have come up for no one; so until it is in view it
  /// waits, listening to the tabs slide. Where it is in no tabs, it comes up
  /// at once.
  void _riseWhenSeen() {
    if (!mounted || !_waiting) return;
    if (_tabs != null && !_onScreen()) return;
    _tabs?.removeListener(_look);
    _tabs = null;
    CoverMosaic.cameUp = true;
    _rise.forward();
  }

  /// Whether most of the cover's width is on the screen.
  bool _onScreen() {
    final RenderObject? box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    final Size screen = MediaQuery.sizeOf(context);
    final Rect shown = (box.localToGlobal(Offset.zero) & box.size).intersect(
      Offset.zero & screen,
    );
    return shown.width > box.size.width * 0.6 && shown.height > 0;
  }

  @override
  void dispose() {
    _tabs?.removeListener(_look);
    _rise.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ExploreHost host = widget.host;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, box) {
          final CoverGrid grid = CoverGrid(box.maxWidth);
          final CoverDeal? deal = CoverDeal.of(
            context,
            widget.cards,
            grid,
            isRead: host.isRead,
          );
          if (deal == null) return const SizedBox.shrink();
          final List<Pill> laid = deal.laid;
          final List<Widget> tiles = [];
          int order = 0;
          for (int g = 0; g < deal.groups.length; g++) {
            final List<Pill> group = deal.groups[g];
            final double top = g * (grid.group + kCoverSpacing);
            // The large tile on the left, then on the right, in turn.
            final bool leadLeft = g.isEven;
            final double leadX = leadLeft ? 0 : grid.small + kCoverSpacing;
            final double sideX = leadLeft ? grid.large + kCoverSpacing : 0;
            final List<(Pill, Offset, Size)> placed = [
              (group[0], Offset(leadX, top), grid.largeBox),
              (group[1], Offset(sideX, top), grid.smallBox),
              (
                group[2],
                Offset(sideX, top + grid.smallBox.height + kCoverSpacing),
                grid.smallBox,
              ),
            ];
            // Up the page in the order the eye reads it: across, then down.
            placed.sort((a, b) {
              final int byTop = a.$2.dy.compareTo(b.$2.dy);
              return byTop != 0 ? byTop : a.$2.dx.compareTo(b.$2.dx);
            });
            for (final (Pill pill, Offset at, Size size) in placed) {
              host.seen(widget.section, pill);
              tiles.add(
                Positioned(
                  left: at.dx,
                  top: at.dy,
                  width: size.width,
                  height: size.height,
                  child: _Rising(
                    rise: _rise,
                    index: order++,
                    child: _CoverTile(
                      key: ValueKey('cover-${pill.id}'),
                      pill: pill,
                      box: size,
                      radius: TileLook.forBox(grid.smallBox).radius,
                      read: host.isRead(pill),
                      onTap: () => host.open(widget.section, laid, pill),
                    ),
                  ),
                ),
              );
            }
          }
          return SizedBox(
            key: const ValueKey('explore-cover'),
            height: grid.heightOf(deal.groups.length),
            child: Stack(clipBehavior: Clip.none, children: tiles),
          );
        },
      ),
    );
  }
}

/// A tile coming up: from a little lower and a little smaller, faded in,
/// each a beat after the one before it.
class _Rising extends StatelessWidget {
  const _Rising({required this.rise, required this.index, required this.child});

  final Animation<double> rise;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double start = math.min(0.5, index * 0.09);
    final Animation<double> t = CurvedAnimation(
      parent: rise,
      curve: Interval(
        start,
        math.min(1, start + 0.5),
        curve: Curves.easeOutCubic,
      ),
    );
    return AnimatedBuilder(
      animation: t,
      child: child,
      builder: (context, child) => t.value >= 1
          ? child!
          : Opacity(
              opacity: t.value,
              child: Transform.translate(
                offset: Offset(0, 22 * (1 - t.value)),
                child: Transform.scale(
                  scale: 0.94 + 0.06 * t.value,
                  child: child,
                ),
              ),
            ),
    );
  }
}

/// One tile of the cover, in words; pressed, it gives a little.
class _CoverTile extends StatefulWidget {
  const _CoverTile({
    super.key,
    required this.pill,
    required this.box,
    required this.radius,
    required this.read,
    required this.onTap,
  });

  final Pill pill;
  final Size box;

  /// The corner, the same on every tile of the cover.
  final double radius;
  final bool read;
  final VoidCallback onTap;

  @override
  State<_CoverTile> createState() => _CoverTileState();
}

class _CoverTileState extends State<_CoverTile> {
  bool _down = false;

  void _press(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final Pill pill = widget.pill;
    final Widget face = BoxTile(
      pill: pill,
      box: widget.box,
      read: widget.read,
      look: TileLook.forBox(widget.box).withRadius(widget.radius),
    );
    return Semantics(
      button: true,
      label: pill.question,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: face,
        ),
      ),
    );
  }
}
