/// Read or do — the canvas's 133a.
///
/// A day of Astute is a mix of cards to read and cards to do, and a shelf
/// that hides which is which asks the reader to open a card to find out.
/// Here every card ends on what it will have them do — bet the number, call
/// it true or false, answer first, move a slider and watch — or, on a card
/// with nothing to answer, Read and how long. Over the shelves, how many
/// there are of each, and a filter that narrows every shelf of the block at
/// once to the cards to read or the cards to do.
library;

import 'package:flutter/material.dart';

import '../../../data/explore_mix.dart';
import '../../../data/themed_shelves.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/card_edge.dart';
import '../../explore_block.dart';
import 'kit.dart';

/// What a card has the reader do, in the order a chip names it.
enum CardVerb {
  read,
  trueFalse,
  pick,
  typeNumber,
  bet,
  side,
  youFirst,
  moveIt,
  whatNext,
  spotTrick,
  drawIt,
  sortThem,
  putInOrder,
  holdIt,
  growSample,
  askWhy,
  sayPlainly,
  pairUp,
  followClues,
  look,
  listen,
}

/// What [p] has the reader do first: its scene, when it has one to play
/// before the answer, or else what it asks.
CardVerb verbOf(Pill p) {
  final CardVerb? played = switch (p.scene) {
    SliderScene() => CardVerb.moveIt,
    StoryScene() => CardVerb.whatNext,
    TrickScene() => CardVerb.spotTrick,
    DrawScene() => CardVerb.drawIt,
    SortScene() => CardVerb.sortThem,
    RankScene() || TimelineScene() => CardVerb.putInOrder,
    HoldScene() => CardVerb.holdIt,
    SampleScene() => CardVerb.growSample,
    WhyScene() => CardVerb.askWhy,
    TranslateScene() => CardVerb.sayPlainly,
    MatchScene() => CardVerb.pairUp,
    CluesScene() => CardVerb.followClues,
    PollScene() => CardVerb.youFirst,
    CountScene() => CardVerb.bet,
    BeautyScene() => CardVerb.look,
    MusicScene() => CardVerb.listen,
    _ => null,
  };
  if (played != null) return played;
  return switch (p.challenge) {
    PickOne() when isTrueOrFalse(p) => CardVerb.trueFalse,
    PickOne() => CardVerb.pick,
    TypeNumber() => CardVerb.typeNumber,
    Estimate() => CardVerb.bet,
    TakeASide() => CardVerb.side,
    // A free card asks on its page: one that holds the finger is moved and
    // watched, one that marks a tap is a pick, and a guess with nothing
    // right about it is the reader's own, said first.
    PageJudged() when p.web?.touch == WebTouch.drags => CardVerb.moveIt,
    PageJudged(:final graded) => graded ? CardVerb.pick : CardVerb.youFirst,
    NoChallenge() => CardVerb.read,
  };
}

/// Whether [verb] asks something of the reader. Looking at a beautiful
/// thing and listening are read, like a card with nothing to answer: the
/// reader takes them in rather than doing anything to them.
bool isToDo(CardVerb verb) =>
    verb != CardVerb.read && verb != CardVerb.look && verb != CardVerb.listen;

/// The mark a chip carries for [verb].
String verbGlyph(CardVerb verb) => switch (verb) {
  CardVerb.read => Glyphs.read,
  CardVerb.trueFalse => Glyphs.trueFalse,
  CardVerb.pick => Glyphs.target,
  CardVerb.typeNumber => Glyphs.type,
  CardVerb.bet => Glyphs.bet,
  CardVerb.side => Glyphs.scales,
  CardVerb.youFirst => Glyphs.person,
  CardVerb.moveIt => Glyphs.slider,
  CardVerb.whatNext => Glyphs.play,
  CardVerb.spotTrick => Glyphs.search,
  CardVerb.drawIt => Glyphs.curve,
  CardVerb.sortThem => Glyphs.sort,
  CardVerb.putInOrder => Glyphs.steps,
  CardVerb.holdIt => Glyphs.hold,
  CardVerb.growSample => Glyphs.dots,
  CardVerb.askWhy => Glyphs.why,
  CardVerb.sayPlainly => Glyphs.speech,
  CardVerb.pairUp => Glyphs.pair,
  CardVerb.followClues => Glyphs.clue,
  CardVerb.look => Glyphs.eye,
  CardVerb.listen => Glyphs.note,
};

/// What a chip says for [verb] on [p]: the verb, or Read and how long.
String verbLabel(AppLocalizations l, CardVerb verb, Pill p) =>
    verb == CardVerb.read
    ? l.purposeVerbRead(minutesFor(p))
    : l.purposeVerb(verb.name);

/// The chip at a card's foot that says what the card will have the reader
/// do: solid in the card's ink for a card to do, a tenth of it for one to
/// read, so the shelf can be read for its mix at a glance.
class VerbChip extends StatelessWidget {
  const VerbChip({super.key, required this.pill, this.height = 32});

  final Pill pill;
  final double height;

  @override
  Widget build(BuildContext context) {
    final CardVerb verb = verbOf(pill);
    final bool doing = isToDo(verb);
    final Color fore = doing ? pill.color : pill.ink;
    return Container(
      key: ValueKey('verb-${pill.id}'),
      height: height,
      padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
      decoration: BoxDecoration(
        color: doing ? pill.ink : fillOn(pill),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PurposeGlyph(verbGlyph(verb), size: 14, color: fore),
          const SizedBox(width: 7),
          // Set down rather than cut: a verb that needs more words in a
          // language than the chip has room for is still the whole verb.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                verbLabel(context.l10n, verb, pill),
                maxLines: 1,
                style: AppText.body(
                  size: 11.5,
                  weight: FontWeight.w700,
                  height: 1,
                  color: fore,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card that ends on what it will have the reader do.
class VerbTile extends StatelessWidget {
  const VerbTile({
    super.key,
    required this.pill,
    required this.size,
    required this.read,
    required this.onOpen,
  });

  final Pill pill;
  final TileSize size;
  final bool read;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final double pad = size.width < 190 ? 14 : 17;
    return CardTap(
      pill: pill,
      onTap: onOpen,
      child: Container(
        width: size.width,
        height: size.height,
        padding: EdgeInsets.all(pad),
        decoration: cardFace(context, pill.color, radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PurposeHead(
              pill: pill,
              trailing: read ? ReadMark(pill: pill) : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 12),
                child: CardQuestion(
                  text: pill.question,
                  color: pill.ink,
                  min: 11,
                  max: size.width < 190 ? 15.5 : 17.5,
                ),
              ),
            ),
            VerbChip(pill: pill),
          ],
        ),
      ),
    );
  }
}

/// The read-or-do filter's three ways: every card, the cards to read, the
/// cards to do.
enum ReadOrDo { all, read, toDo }

/// 133a: shelves whose cards each end on what they will have the reader do,
/// with how many of each over them and the filter that narrows them all.
class ReadOrDoBlock extends ExploreBlock {
  const ReadOrDoBlock();

  @override
  String get name => 'purpose.read-or-do';

  /// The block's sizes; `m` is the canvas's.
  static const Map<String, TileSize> sizes = {
    's': TileSize(176, 212),
    'm': TileSize(206, 244),
    'l': TileSize(240, 280),
  };

  /// How many of the day's turning themes the block shows when the section
  /// names no shelves of its own.
  static const int defaultShelves = 4;

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<ShelfOfVerbs> shelves = shelvesOf(context, host, section);
    if (shelves.isEmpty) return null;
    final Object? filter = section.style['filter'];
    final Object? count = section.style['count'];
    return host.watch(
      section,
      ReadOrDoShelves(
        key: ValueKey('read-or-do-${section.id}'),
        host: host,
        section: section,
        shelves: shelves,
        size: sizeOf(section, sizes),
        filter: filter is bool ? filter : shelves.length >= 2,
        count: count is bool ? count : true,
      ),
    );
  }

  /// The shelves [section] holds, each with its cards: the ones it lists,
  /// or the day's turning themes its pool can fill.
  static List<ShelfOfVerbs> shelvesOf(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final l = context.l10n;
    final String lang = host.language;
    final int day = today();
    final List<Map<Object?, Object?>> parts = partsOf(section, 'shelves');
    final List<ShelfOfVerbs> out = [];
    if (parts.isNotEmpty) {
      for (final Map<Object?, Object?> part in parts) {
        final ExploreSection sub = partOf(section, part);
        final (ShelfTheme, int)? theme = themeNamed(part['theme'], day: day);
        final String? title =
            sub.title(lang) ??
            (theme == null ? null : themeTitle(l, theme.$1, theme.$2));
        // A shelf is known by its name: one with neither a name nor a
        // theme to take one from is passed over, as rule 2 has it.
        if (title == null) continue;
        final List<Pill> cards = cardsOf(
          host,
          sub,
          limit: kThemeCards,
          fits: theme == null
              ? null
              : (p) => fitsTheme(theme.$1, p, variant: theme.$2),
        );
        if (cards.isEmpty) continue;
        out.add(
          ShelfOfVerbs(
            section: sub,
            title: title,
            line:
                sub.subtitle(lang) ??
                (theme == null ? '' : themeLine(l, theme.$1)),
            cards: cards,
          ),
        );
      }
      return out;
    }
    final Object? wanted = section.style['shelves'];
    final int most = wanted is num && wanted > 0
        ? wanted.toInt().clamp(1, kThemesPerDay)
        : defaultShelves;
    final List<Pill> pool = host.cardsFor(section, limit: kPurposePool);
    for (final ThemedShelf t in themedShelves(pool, day: day).take(most)) {
      final ExploreSection sub = partOf(section, {'id': t.key});
      out.add(
        ShelfOfVerbs(
          section: sub,
          title: themeTitle(l, t.theme, t.variant),
          line: themeLine(l, t.theme),
          cards: t.pills.take(limitOf(section, kThemeCards)).toList(),
        ),
      );
    }
    return out;
  }
}

/// One shelf of the block: the part of the section its cards are noted
/// under, its name and line, and its cards.
@immutable
class ShelfOfVerbs {
  const ShelfOfVerbs({
    required this.section,
    required this.title,
    required this.line,
    required this.cards,
  });

  final ExploreSection section;
  final String title;
  final String line;
  final List<Pill> cards;

  int get toDo => cards.where((p) => isToDo(verbOf(p))).length;
  int get toRead => cards.length - toDo;
}

/// The shelves of a read-or-do block under their count and filter. The
/// filter is kept for the day, so the shelves come back narrowed the way
/// the reader left them.
class ReadOrDoShelves extends StatefulWidget {
  const ReadOrDoShelves({
    super.key,
    required this.host,
    required this.section,
    required this.shelves,
    required this.size,
    required this.filter,
    required this.count,
  });

  final ExploreHost host;
  final ExploreSection section;
  final List<ShelfOfVerbs> shelves;
  final TileSize size;

  /// Whether the filter shows, and each shelf's count.
  final bool filter;
  final bool count;

  @override
  State<ReadOrDoShelves> createState() => _ReadOrDoShelvesState();
}

class _ReadOrDoShelvesState extends State<ReadOrDoShelves> {
  String get _kept => 'filter:${widget.section.id}';

  ReadOrDo get _way {
    final Object? kept = PurposePlay.read(_kept);
    return ReadOrDo.values.where((w) => w.name == kept).firstOrNull ??
        ReadOrDo.all;
  }

  void _pick(ReadOrDo way) {
    PurposePlay.write(_kept, way == ReadOrDo.all ? null : way.name);
    widget.host.note(widget.section, 'read or do', {'filter': way.name});
    setState(() {});
  }

  bool _keeps(ReadOrDo way, Pill p) => switch (way) {
    ReadOrDo.all => true,
    ReadOrDo.read => !isToDo(verbOf(p)),
    ReadOrDo.toDo => isToDo(verbOf(p)),
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final int toDo = widget.shelves.fold(0, (n, s) => n + s.toDo);
    final int toRead = widget.shelves.fold(0, (n, s) => n + s.toRead);
    // A way with nothing in it cannot be chosen; one chosen yesterday that
    // has nothing today is all of them again.
    ReadOrDo way = widget.filter ? _way : ReadOrDo.all;
    if ((way == ReadOrDo.read && toRead == 0) ||
        (way == ReadOrDo.toDo && toDo == 0)) {
      way = ReadOrDo.all;
    }
    final List<Widget> children = [];
    if (widget.filter) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              Text(
                l.purposeReadOrDoCount(toDo, toRead),
                key: ValueKey('read-or-do-count-${widget.section.id}'),
                style: AppText.body(
                  size: 12.5,
                  weight: FontWeight.w600,
                  height: 1.3,
                  color: context.p.ink.withValues(alpha: 0.55),
                ),
              ),
              _Filter(
                keyPrefix: 'read-or-do-${widget.section.id}',
                labels: [l.all, l.purposeFilterToRead, l.purposeFilterToDo],
                selected: way.index,
                enabled: [true, toRead > 0, toDo > 0],
                onPick: (i) => _pick(ReadOrDo.values[i]),
              ),
            ],
          ),
        ),
      );
    }
    for (final ShelfOfVerbs shelf in widget.shelves) {
      final List<Pill> shown = [
        for (final Pill p in shelf.cards)
          if (_keeps(way, p)) p,
      ];
      if (shown.isEmpty) continue;
      if (children.isNotEmpty) children.add(const SizedBox(height: 24));
      children.add(
        PurposeShelf(
          key: ValueKey('read-or-do-shelf-${shelf.section.id}'),
          title: shelf.title,
          line: shelf.line,
          trailing: widget.count
              ? ShelfCount(l.purposeShelfCount(shelf.toDo, shelf.toRead))
              : null,
          trailingAtFoot: true,
          child: SideRow(
            height: widget.size.height + 4,
            count: shown.length,
            itemBuilder: (context, i) {
              final Pill p = shown[i];
              widget.host.seen(shelf.section, p);
              return VerbTile(
                pill: p,
                size: widget.size,
                read: widget.host.isRead(p),
                onOpen: () => widget.host.open(shelf.section, shown, p),
              );
            },
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// Two to four words, one lit, at their own widths: the subject row's chip
/// made into a set small enough to sit beside a count.
class _Filter extends StatelessWidget {
  const _Filter({
    required this.labels,
    required this.selected,
    required this.enabled,
    required this.onPick,
    required this.keyPrefix,
  });

  final List<String> labels;
  final int selected;
  final List<bool> enabled;
  final ValueChanged<int> onPick;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    // The set's ground is drawn 30 high behind targets 44 high, as the top
    // list's week-or-month pair is.
    return Stack(
      children: [
        Positioned.fill(
          top: 7,
          bottom: 7,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.p.ink.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < labels.length; i++)
                Semantics(
                  key: ValueKey(
                    '$keyPrefix-$i-${i == selected ? 'on' : 'off'}',
                  ),
                  button: true,
                  selected: i == selected,
                  enabled: enabled[i],
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: enabled[i] && i != selected ? () => onPick(i) : null,
                    // A 26-point word in a target 44 high: the pair is small,
                    // the place a finger lands on it is not.
                    child: SizedBox(
                      height: 44,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          height: 26,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i == selected
                                ? context.p.inverse
                                : context.p.inverse.withValues(alpha: 0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            style: AppText.body(
                              size: 12,
                              weight: FontWeight.w600,
                              height: 1,
                              color: i == selected
                                  ? context.p.onInverse
                                  : context.p.ink.withValues(
                                      alpha: enabled[i] ? 0.62 : 0.25,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
