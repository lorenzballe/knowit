/// What a bet asks of Explore beyond [ExploreHost], and how a bet is laid
/// through whichever host it is given.
library;

import '../../../models/pill.dart';
import '../../explore_block.dart';
import 'bets_day.dart';

/// An [ExploreHost] that can do two things a bet needs and the host's
/// contract does not say. A host that cannot is still enough: the bet is
/// recorded through [ExploreHost.commit], and what the host could not take
/// is noted beside it (see [layBet], [revealCard]).
abstract interface class BetHost implements ExploreHost {
  /// Records [response] as [pill]'s answer, as [ExploreHost.commit] does,
  /// with how sure the reader said they were — 50 to 90, asked the way the
  /// card's own step asks it — so a bet counts towards how sure against
  /// how right like an answer given on the card.
  Future<void> commitSure(Pill pill, String response, int confidence);

  /// [pill]'s answer was shown on a shelf without the reader giving one —
  /// two figures compared, a number closed in on — so it must count as
  /// read, as an answer given on a shelf does, and never be dealt later
  /// with its answer already known.
  void revealed(ExploreSection section, Pill pill);
}

/// Lays [bet] on [section]'s shelf: kept for the day, and when [response]
/// is given, recorded as [pill]'s answer the way the card records one —
/// with how sure, where the bet asked it. Noted as `bet laid` with what
/// the slip keeps of it, so the shelf's numbers can be read on their own.
Future<void> layBet(
  ExploreHost host,
  ExploreSection section,
  Bet bet, {
  Pill? pill,
  String? response,
}) async {
  BetsDay.instance.place(bet);
  host.note(section, 'bet laid', {
    'kind': bet.kind,
    'pill_id': bet.pill,
    if (bet.other != null) 'other_id': bet.other,
    'right': bet.right,
    'points': bet.points,
    'wallet': BetsDay.instance.points,
    if (bet.confidence != null) 'confidence': bet.confidence,
    for (final MapEntry<String, Object?> e in bet.facts.entries)
      if (e.value is num || e.value is bool) e.key: e.value,
  });
  if (pill == null || response == null) return;
  final int? sure = bet.confidence;
  if (sure != null && host is BetHost) {
    await host.commitSure(pill, response, sure);
  } else {
    await host.commit(pill, response);
  }
}

/// Says [pill]'s answer was shown on [section]'s shelf without being
/// answered: to a [BetHost], which counts it read; to any host, as a note.
void revealCard(ExploreHost host, ExploreSection section, Pill pill) {
  host.note(section, 'bet revealed', {'pill_id': pill.id});
  if (host is BetHost) host.revealed(section, pill);
}
