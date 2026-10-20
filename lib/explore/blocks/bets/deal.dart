/// What a section of bets says, read with the defaults that make a section
/// of nothing but its id and its block look right, and the cards it is
/// dealt for the day.
library;

import 'dart:convert';

import '../../../data/pill_bank.dart';
import '../../../models/pill.dart';
import '../../explore_block.dart';
import 'answers.dart';
import 'bets_day.dart';

/// How many of the host's cards a section is offered before the ones it
/// can bet on are picked out: enough for the whole bank, so a section with
/// no source of its own bets on every subject's numbers, not on the first
/// few subjects in the bank's order.
const int kBetPool = 6000;

/// Whether a tile is drawn in its card's subject colour, as every card in
/// the app is, or on the page, as the canvas draws its panels.
enum BetTone { subject, page }

/// A section of bets, read defensively: a field of the wrong type is a
/// field not given, and the block's own default stands.
class BetSection {
  const BetSection(this.section);

  final ExploreSection section;

  String get id => section.id;

  /// The section's size if it is one of [sizes], otherwise [fallback].
  String size(List<String> sizes, String fallback) {
    final String? said = section.size;
    return said != null && sizes.contains(said) ? said : fallback;
  }

  /// How many it shows: the section's limit, from 1 to [most], or
  /// [fallback].
  int limit(int fallback, {int most = 12}) =>
      (section.limit ?? fallback).clamp(1, most);

  /// A yes or no the section may say, or [fallback].
  bool flag(String key, bool fallback) => section.get<bool>(key) ?? fallback;

  /// A whole number the section may say, from [min] to [max], or
  /// [fallback].
  int count(String key, int fallback, {required int min, required int max}) {
    final num? said = section.get<num>(key);
    if (said == null || said != said.roundToDouble()) return fallback;
    return said.toInt().clamp(min, max);
  }

  /// The tone of its tiles: `style.tone`, or [fallback].
  BetTone tone([BetTone fallback = BetTone.subject]) =>
      switch (section.style['tone']) {
        'subject' => BetTone.subject,
        'page' => BetTone.page,
        _ => fallback,
      };

  /// Whether a bet that is a card's answer asks how sure before it shows
  /// the answer, as the card does: `sure`, true unless the section says
  /// otherwise.
  bool get asksSure => flag('sure', true);

  /// A list of whole numbers above nought the section may give for
  /// [key], rising, of [length] if given — or [fallback].
  List<int> rising(String key, List<int> fallback, {int? length}) {
    final List<Object?>? raw = section.get<List<Object?>>(key);
    if (raw == null) return fallback;
    final List<int> out = [];
    for (final Object? v in raw) {
      if (v is! num || v <= 0 || v != v.roundToDouble()) return fallback;
      if (out.isNotEmpty && v <= out.last) return fallback;
      out.add(v.toInt());
    }
    if (out.isEmpty || (length != null && out.length != length)) {
      return fallback;
    }
    return out;
  }

  /// A card id the section names under [key], if the bank has it.
  Pill? card(String key) {
    final String? id = section.get<String>(key);
    return id == null ? null : PillBank.byId(id);
  }

  /// What names this section's deal for the day: the section, the subject
  /// Explore is narrowed to, and what the section asks for, so a section
  /// the server changes during the day is dealt again.
  String dealKey(ExploreHost host, String salt) {
    final String asked = jsonEncode({
      'source': section.source,
      'limit': section.limit,
      'size': section.size,
      'salt': salt,
    });
    return '${section.id}|${host.subject ?? ''}|'
        '${(betUnit(asked) * 0xFFFFFFFF).round().toRadixString(36)}';
  }
}

final Expando<_Read> _reads = Expando<_Read>('bets');

class _Read {
  const _Read(this.answer);
  final BetAnswer? answer;
}

/// [pill]'s answer as a number, read once per card.
BetAnswer? answerOf(Pill pill) =>
    (_reads[pill] ??= _Read(BetAnswer.of(pill))).answer;

/// The cards [shelf] bets on today: from the host's cards for the section,
/// those whose answer [fits], neither read nor answered, none another shelf
/// of bets already holds today, at most [count] — each subject once before
/// any twice, in an order drawn for the day. The same all day, kept on the
/// phone, so the shelf does not change under the reader as cards are read
/// elsewhere; another set the next day.
///
/// With [fresh] false the reader's history is not looked at: the cards are
/// the same for everyone who is given the same section.
List<BetAnswer> dealBets(
  ExploreHost host,
  BetSection shelf, {
  required bool Function(BetAnswer) fits,
  required int count,
  String salt = '',
  bool fresh = true,
}) => dealWith(
  host,
  shelf,
  salt: salt,
  fresh: fresh,
  fits: fits,
  pick: (fit, seed) => dealInOrder(fit, seed: seed, count: count),
);

/// The day's deal for [shelf], however it is chosen: the one kept for the
/// day if there is one; otherwise [pick] chooses, from the cards that
/// [fit] and no other shelf holds, in an order drawn from its seed, and
/// what it chooses is kept.
List<BetAnswer> dealWith(
  ExploreHost host,
  BetSection shelf, {
  required String salt,
  required bool Function(BetAnswer) fits,
  required List<BetAnswer> Function(List<BetAnswer> fit, String seed) pick,
  bool fresh = true,
}) {
  final BetsDay day = BetsDay.instance;
  final String key = shelf.dealKey(host, salt);
  final List<Pill> pool = host.cardsFor(shelf.section, limit: kBetPool);
  final Map<String, Pill> byId = {for (final Pill p in pool) p.id: p};
  final List<String>? kept = day.deal(key);
  if (kept != null) {
    return [
      for (final String id in kept)
        if (byId[id] ?? PillBank.byId(id) case final Pill p)
          if (answerOf(p) case final BetAnswer a) a,
    ];
  }
  final Set<String> claimed = day.claimedBesides(key);
  final List<BetAnswer> fit = [
    for (final Pill p in pool)
      if (!claimed.contains(p.id) &&
          (!fresh || (!host.isRead(p) && host.app.answerFor(p.id) == null)))
        if (answerOf(p) case final BetAnswer a when fits(a)) a,
  ];
  final List<BetAnswer> dealt = pick(fit, '${day.today}:${shelf.id}:$salt');
  day.keepDeal(key, [for (final BetAnswer a in dealt) a.pill.id]);
  return dealt;
}

/// [cards] in an order drawn from [seed], each subject once before any
/// subject twice, at most [count].
List<BetAnswer> dealInOrder(
  List<BetAnswer> cards, {
  required String seed,
  required int count,
}) {
  final List<(double, BetAnswer)> keyed = [
    for (final BetAnswer a in cards) (betUnit('$seed:${a.pill.id}'), a),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  final List<BetAnswer> out = [];
  final Map<String, int> perTopic = {};
  for (int round = 1; out.length < count && round <= 4; round++) {
    for (final (_, BetAnswer a) in keyed) {
      if (out.length >= count) break;
      if (out.contains(a)) continue;
      final int had = perTopic[a.pill.topic] ?? 0;
      if (had >= round) continue;
      perTopic[a.pill.topic] = had + 1;
      out.add(a);
    }
  }
  return out;
}

// ── Ranges ───────────────────────────────────────────────────────────────

/// How wide a range reaches either side of the guess, and what it pays.
typedef RangeWidth = ({int half, int pays});

/// The canvas's widths: narrow pays three times what wide does.
const List<RangeWidth> kRangeWidths = [
  (half: 5, pays: 30),
  (half: 10, pays: 20),
  (half: 20, pays: 10),
];

/// The widths [shelf] gives as `widths` — two to four `[half, pays]`, the
/// halves rising from 1 to 50, the pays falling from 1000 to 1 — or the
/// canvas's.
List<RangeWidth> rangeWidthsOf(BetSection shelf) {
  final List<Object?>? raw = shelf.section.get<List<Object?>>('widths');
  if (raw == null || raw.length < 2 || raw.length > 4) return kRangeWidths;
  final List<RangeWidth> out = [];
  for (final Object? w in raw) {
    if (w is! List || w.length != 2) return kRangeWidths;
    final Object? half = w[0], pays = w[1];
    if (half is! int || pays is! int) return kRangeWidths;
    if (half < 1 || half > 50 || pays < 1 || pays > 1000) return kRangeWidths;
    if (out.isNotEmpty && (half <= out.last.half || pays >= out.last.pays)) {
      return kRangeWidths;
    }
    out.add((half: half, pays: pays));
  }
  return out;
}
