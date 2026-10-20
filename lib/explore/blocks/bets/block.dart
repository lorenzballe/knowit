/// What every block of bets does the same way: waits for the day's bets to
/// be read, deals its cards, says nothing when it has none, and stands
/// under the shelf's head.
library;

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../explore_block.dart';
import 'answers.dart';
import 'bets_day.dart';
import 'deal.dart';
import 'parts.dart';

/// A block of bets.
abstract class BetBlock extends ExploreBlock {
  const BetBlock();

  /// The sizes it is drawn at, in its own words.
  List<String> get sizes => const ['s', 'm', 'l'];

  /// The size it is drawn at when the section says none.
  String get defaultSize => 'm';

  /// How many it shows when the section says no limit.
  int get defaultLimit;

  /// Whether this block can bet on [answer]'s card.
  bool fits(BetAnswer answer);

  /// The shelf's own name and the line under it, when the section gives
  /// none.
  String title(AppLocalizations l, BetSection shelf);
  String line(AppLocalizations l, BetSection shelf);

  /// What sits level with the name: the points left, where it says so.
  Widget? trailing(BetSection shelf) => null;

  /// The size [shelf] is drawn at.
  BetTileSize sizeOf(BetSection shelf) =>
      BetTileSize.named(shelf.size(sizes, defaultSize));

  /// The cards [shelf] bets on today.
  List<BetAnswer> deal(ExploreHost host, BetSection shelf) => dealBets(
    host,
    shelf,
    fits: fits,
    count: shelf.limit(defaultLimit),
    salt: name,
  );

  /// Whether there is anything to deal at all: a card this block can bet
  /// on, not read or answered. Asked before the day's bets are read, so a
  /// shelf with nothing for it is left out at once, title and all.
  bool canShow(ExploreHost host, BetSection shelf) {
    for (final p in host.cardsFor(shelf.section, limit: kBetPool)) {
      if (host.isRead(p) || host.app.answerFor(p.id) != null) continue;
      final BetAnswer? a = answerOf(p);
      if (a != null && fits(a)) return true;
    }
    return false;
  }

  /// The bets under the head, for [cards].
  Widget body(
    BuildContext context,
    ExploreHost host,
    BetSection shelf,
    List<BetAnswer> cards,
  );

  /// The whole shelf, head and bets, or nothing when there is nothing to
  /// deal.
  Widget? shelfOf(BuildContext context, ExploreHost host, BetSection shelf) {
    final List<BetAnswer> cards = deal(host, shelf);
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final ExploreSection section = shelf.section;
    return BetShelf(
      key: ValueKey('bets-${section.id}'),
      title: section.title(host.language) ?? title(l, shelf),
      line: section.subtitle(host.language) ?? line(l, shelf),
      trailing: trailing(shelf),
      child: ListenableBuilder(
        listenable: Listenable.merge([BetsDay.instance, host.app]),
        builder: (context, _) => body(context, host, shelf, cards),
      ),
    );
  }

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final BetSection shelf = BetSection(section);
    final BetsDay day = BetsDay.instance;
    if (day.loaded) {
      final Widget? shelfWidget = shelfOf(context, host, shelf);
      return shelfWidget == null ? null : host.watch(section, shelfWidget);
    }
    // The day's bets are read once, at the first shelf of bets; until then
    // the shelf waits a frame rather than deal cards the morning already
    // dealt differently.
    day.load();
    if (!canShow(host, shelf)) return null;
    return host.watch(
      section,
      ListenableBuilder(
        listenable: day,
        builder: (context, _) => day.loaded
            ? shelfOf(context, host, shelf) ?? const SizedBox.shrink()
            : const SizedBox.shrink(),
      ),
    );
  }
}
