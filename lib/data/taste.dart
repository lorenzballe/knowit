import 'dart:math';

import '../models/pill.dart';

/// What the reader did with a card, and what it is worth as evidence.
///
/// These are the only inputs the taste model has. Deliberately: an app that
/// asks people to rate cards gets ratings from the few who rate and nothing
/// from everyone else, and what someone says they want to read and what they
/// actually read are different questions.
///
/// The values are ordered by how costly the act is. Keeping a card and
/// sending it to someone are the two things nobody does by accident, so they
/// count most. Reading one is the default and counts least — a positive, but
/// a weak one, or every card ever shown would look liked.
enum Signal {
  /// Moved past it having spent long enough to have read it.
  read(0.2),

  /// Moved past it faster than the card can be read. The only strong
  /// negative the app can observe, and the reason a taste can go down as
  /// well as up.
  skipped(-0.8),

  /// Committed to an answer rather than tapping through.
  answered(0.35),

  /// Asked for the hint. Engagement, not enthusiasm — and it says more about
  /// the difficulty than about the subject, so it is barely worth anything.
  hinted(0.1),

  /// Opened the worked solution or the second explanation: wanted more of
  /// this, which is the closest thing to a stated preference the app gets
  /// without asking.
  explained(0.5),

  /// Kept it.
  saved(1.0),

  /// Took it back out again.
  unsaved(-0.5),

  /// Sent it to someone. Nobody shares a card they were indifferent to.
  shared(1.0);

  const Signal(this.reward);

  /// What this act is worth, -1 to 1.
  final double reward;
}

/// One thing the reader has a taste about, and how sure we are of it.
class Trait {
  /// The running average of what this facet has been worth, -1 to 1.
  double pull;

  /// How many cards carrying this facet the reader has met. Evidence — the
  /// pull is not trusted until there is some.
  int met;

  Trait({this.pull = 0, this.met = 0});
}

/// How much evidence a facet needs before its own average is trusted over
/// what the reader said they wanted.
///
/// Set low on purpose. A reader produces five signals a day, so a model that
/// wants thirty observations before it moves would spend a month agreeing
/// with a questionnaire.
const int kPriorStrength = 4;

/// The floor under the learning rate. Without it a facet met a hundred times
/// stops moving, and a reader who has changed their mind is stuck with the
/// person they were in January.
const double kLearningFloor = 0.08;

/// The success rate a card should aim for.
///
/// Not 1.0: a card everyone gets right teaches nothing and is not why anyone
/// opened the app. Not 0.5 either, which is where a reader decides the app is
/// unfair and stops. Around three in four is where the effort is spent on
/// cards that are winnable and not free.
const double kTargetSuccess = 0.75;

/// What the reader's accuracy is taken to be before they have answered
/// anything at that level.
const double kAssumedSuccess = 0.6;

/// What each part of the score is worth. These are the whole personality of
/// the deck, so they are named and kept together rather than spread through
/// the arithmetic.
const double kwTaste = 1.0;

/// Whether the card is winnable for this particular reader.
const double kwFit = 0.6;

/// Against showing the same kind of card three days running. Without this
/// the model finds one subject the reader likes and then serves only that,
/// which is the failure everyone recognises from a feed.
const double kwFatigue = 0.5;

/// For the moves the reader keeps getting wrong. This is the one term that
/// is about teaching rather than taste, and it is why the deck is not simply
/// a preference engine: what you are worst at is worth meeting again.
const double kwWeakness = 0.45;

/// For the facets there is no evidence about yet. An optimism bonus, the
/// standard shape: the less we know about something, the more it is worth
/// finding out.
const double kwCuriosity = 0.35;

/// A little noise, so two cards that score the same do not always come out
/// in the same order.
const double kwJitter = 0.15;

/// How much of the fatigue count survives to the next day.
const double kFatigueDecay = 0.6;

/// How much of a subject in living memory counts as too much of it.
const double kFatigueFull = 3.0;

/// Facet families, and what each is worth in the overall match.
///
/// Averaged within a family before being averaged across families, so a card
/// carrying four tags does not outvote the fact that the reader dislikes its
/// subject.
const Map<String, double> kFamilyWeight = {
  'topic': 1.0,
  'tag': 1.0,
  'format': 0.8,
  'tone': 0.7,
  'move': 0.5,
  // Difficulty is scored properly by the fit term. It is here only because a
  // few readers genuinely want the hard ones whether or not they get them
  // right, and that is a taste like any other.
  'level': 0.4,
};

/// What this reader likes, learned from what they did.
///
/// The design in one line: **what they said is the prior, what they did is
/// the evidence, and neither is allowed to win outright.** A reader who
/// picked Space and then skips every space card stops being shown space. A
/// reader who has done four cards is still shown what they asked for,
/// because four cards is not a personality.
///
/// Everything here is a facet — 'topic:space', 'tag:money', 'tone:playful',
/// 'format:estimate' — rather than a card. Cards are learned about one at a
/// time and there will never be many of them per reader; facets are shared
/// across the whole catalogue, so one skipped card is evidence about hundreds
/// of cards not yet written.
class ReaderTaste {
  ReaderTaste({
    Map<String, Trait>? traits,
    Map<String, double>? recent,
    Map<String, double>? priors,
  }) : _traits = traits ?? {},
       _recent = recent ?? {},
       _priors = priors ?? {};

  final Map<String, Trait> _traits;

  /// Fatigue: how much of each facet is in living memory. Decays daily.
  final Map<String, double> _recent;

  /// What the reader said they wanted, as a pull per facet. The starting
  /// point, not the answer.
  final Map<String, double> _priors;

  /// Everything the model has learned, for the profile and for tests.
  Map<String, Trait> get traits => Map.unmodifiable(_traits);

  /// How many cards have been learned from at all.
  int get evidence =>
      _traits.values.fold(0, (a, t) => a + t.met);

  /// Takes the mix the reader dragged into shape as the prior on subjects.
  ///
  /// A weight of 1 means "as much of this as possible" and reads as a pull of
  /// +1; 0.5 is indifference and reads as 0. It is only a starting point:
  /// [pullOf] hands the decision over to behaviour as evidence arrives.
  void declare(Map<String, double> topicWeights) {
    for (final entry in topicWeights.entries) {
      _priors['topic:${entry.key}'] = (entry.value.clamp(0.0, 1.0) * 2) - 1;
    }
  }

  /// Records what the reader did with a card, against every facet of it.
  ///
  /// One card teaches the model about its subject, its shape, its tone and
  /// each of its tags at once. That is the point of facets: five cards a day
  /// is far too little to learn about cards, and plenty to learn about kinds.
  void learn(Pill card, Signal signal) {
    for (final facet in card.facets) {
      final trait = _traits.putIfAbsent(facet, Trait.new);
      trait.met += 1;
      final rate = max(kLearningFloor, 1 / trait.met);
      trait.pull += rate * (signal.reward - trait.pull);
      trait.pull = trait.pull.clamp(-1.0, 1.0);
    }
  }

  /// Notes that a card was dealt, for fatigue. Dealing is what tires a
  /// subject out, not liking it — a card the reader loved and a card they
  /// skipped both mean they have just had one of those.
  void noteDealt(Pill card) {
    for (final facet in card.facets) {
      _recent[facet] = (_recent[facet] ?? 0) + 1;
    }
  }

  /// Lets yesterday matter less than today. Called once when a day turns
  /// over, so a subject rested for a few days comes back available.
  void ageOneDay() {
    _recent.updateAll((_, v) => v * kFatigueDecay);
    _recent.removeWhere((_, v) => v < 0.05);
  }

  /// How much the reader likes one facet, -1 to 1.
  ///
  /// The shrinkage is the whole argument: with no evidence this is exactly
  /// what they asked for, and with plenty it is exactly what they do. In
  /// between it is a weighted blend, which is the only honest answer.
  double pullOf(String facet) {
    final prior = _priors[facet] ?? 0.0;
    final trait = _traits[facet];
    if (trait == null || trait.met == 0) return prior;
    final trust = trait.met / (trait.met + kPriorStrength);
    return trait.pull * trust + prior * (1 - trust);
  }

  /// How well a card matches this reader, -1 to 1. Families are averaged
  /// before being weighed against each other.
  double match(Pill card) {
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final facet in card.facets) {
      final family = facet.split(':').first;
      sums[family] = (sums[family] ?? 0) + pullOf(facet);
      counts[family] = (counts[family] ?? 0) + 1;
    }
    var weighted = 0.0;
    var total = 0.0;
    for (final family in sums.keys) {
      final weight = kFamilyWeight[family] ?? 0.0;
      if (weight == 0) continue;
      weighted += weight * (sums[family]! / counts[family]!);
      total += weight;
    }
    return total == 0 ? 0 : weighted / total;
  }

  /// How tired the reader is of what this card is made of, 0 to 1.
  double fatigue(Pill card) {
    if (card.facets.isEmpty) return 0;
    var worst = 0.0;
    for (final facet in card.facets) {
      final family = facet.split(':').first;
      // Only subjects tire. Meeting three questions in a row is the app
      // working; meeting three cards about bees is the app broken.
      if (family != 'topic' && family != 'tag') continue;
      final seen = (_recent[facet] ?? 0) / kFatigueFull;
      worst = max(worst, seen.clamp(0.0, 1.0));
    }
    return worst;
  }

  /// How little is known about this card's facets, 0 to 1. The optimism
  /// bonus rides on this: an unknown is worth trying.
  double curiosity(Pill card) {
    if (card.facets.isEmpty) return 1;
    var sum = 0.0;
    for (final facet in card.facets) {
      final met = _traits[facet]?.met ?? 0;
      sum += 1 / sqrt(1 + met);
    }
    return (sum / card.facets.length).clamp(0.0, 1.0);
  }

  /// The whole score for one card on one day.
  ///
  /// [successByLevel] is the reader's measured accuracy per difficulty,
  /// [weakMoves] the principles they keep missing, and [daySeed] pins the
  /// noise so a day does not reshuffle under someone part-way through it.
  double score(
    Pill card, {
    Map<Difficulty, double> successByLevel = const {},
    Set<Principle> weakMoves = const {},
    int daySeed = 0,
  }) {
    return kwTaste * match(card) +
        kwFit * fit(card, successByLevel) +
        kwWeakness * (weakMoves.contains(card.principle) ? 1.0 : 0.0) -
        kwFatigue * fatigue(card) +
        kwCuriosity * curiosity(card) +
        kwJitter * jitter(daySeed, card.id);
  }

  /// Whether the card is pitched where this reader can win it, -1 to 1.
  ///
  /// A card that tells you something is not scored on this at all: there is
  /// nothing to get right, so being sure it is winnable says nothing.
  double fit(Pill card, Map<Difficulty, double> successByLevel) {
    if (!card.asksSomething || !card.isGraded) return 0;
    final expected = successByLevel[card.difficulty] ?? kAssumedSuccess;
    final off = (expected - kTargetSuccess).abs();
    return (1 - off / 0.5).clamp(-1.0, 1.0);
  }

  /// Deterministic noise in [0, 1) from the day and the card. A hash, not a
  /// Random: the same day must always come out the same way, on this phone
  /// and on the reader's other one.
  static double jitter(int daySeed, String id) {
    var h = 0x811c9dc5 ^ daySeed;
    for (final unit in id.codeUnits) {
      h = ((h ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return (h & 0xFFFFFF) / 0x1000000;
  }

  Map<String, dynamic> toJson() => {
    't': {
      for (final e in _traits.entries)
        e.key: [double.parse(e.value.pull.toStringAsFixed(4)), e.value.met],
    },
    if (_recent.isNotEmpty)
      'r': {
        for (final e in _recent.entries)
          e.key: double.parse(e.value.toStringAsFixed(3)),
      },
  };

  static ReaderTaste fromJson(Object? raw) {
    final taste = ReaderTaste();
    if (raw is! Map) return taste;
    final traits = raw['t'];
    if (traits is Map) {
      for (final entry in traits.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String || value is! List || value.length < 2) continue;
        final pull = value[0];
        final met = value[1];
        if (pull is! num || met is! int || met < 0) continue;
        taste._traits[key] = Trait(
          pull: pull.toDouble().clamp(-1.0, 1.0),
          met: met,
        );
      }
    }
    final recent = raw['r'];
    if (recent is Map) {
      for (final entry in recent.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && value is num) taste._recent[key] = value.toDouble();
      }
    }
    return taste;
  }

  /// Brings another phone's taste across.
  ///
  /// Evidence adds up and the pulls are averaged by how much evidence each
  /// side has, which is the only merge that does not throw away a device's
  /// history or let the quieter phone overrule the busier one. Fatigue is not
  /// merged: it describes what a phone has just shown, and the other phone's
  /// last week is not this one's.
  ReaderTaste mergedWith(ReaderTaste other) {
    final merged = ReaderTaste(
      recent: Map<String, double>.from(_recent),
      priors: Map<String, double>.from(_priors),
    );
    for (final key in {..._traits.keys, ...other._traits.keys}) {
      final mine = _traits[key];
      final theirs = other._traits[key];
      if (mine == null) {
        merged._traits[key] = Trait(pull: theirs!.pull, met: theirs.met);
        continue;
      }
      if (theirs == null) {
        merged._traits[key] = Trait(pull: mine.pull, met: mine.met);
        continue;
      }
      final met = mine.met + theirs.met;
      merged._traits[key] = Trait(
        pull: met == 0
            ? 0
            : (mine.pull * mine.met + theirs.pull * theirs.met) / met,
        met: met,
      );
    }
    return merged;
  }
}
