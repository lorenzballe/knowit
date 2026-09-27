/// What the onboarding said, read the way a person would read it.
///
/// The onboarding asks two things and no more: how much of each subject
/// (the wheel, a handle per subject pushed up or down) and, one layer
/// down, which genres and strands to leave out. It never asks what the
/// reader knows — that screen went, because a self-rating given before a
/// single card is a guess that ages from the first morning. But the two
/// answers it does take say more than their face value, and a day dealt
/// from their face value alone wastes most of it:
///
/// - **How far a handle went, against the others.** A mix left all the way
///   up everywhere says nothing; one subject kept at the top while the rest
///   came down says *this is mine*. What counts is the gap, not the number.
/// - **Where the reader pruned.** Somebody who opens Space and turns off
///   the Moon but keeps black holes knows the field well enough to have
///   an opinion inside it. Pruning is expertise showing, and the strands
///   left on in a genre that was pruned are the most precise thing the
///   reader has told the app.
/// - **How many subjects stayed.** Four is a specialist, who wants depth;
///   fifteen is a generalist, who wants range. They are served differently.
/// - **Whether anything moved at all.** A reader who walked straight
///   through is not a reader who likes everything equally; they have told
///   the app nothing, and it should not pretend they did.
///
/// From that, three things the dealer uses:
///
/// 1. **A starting level for each subject, a notch above.** Nobody starts
///    as a beginner. The default is *some*, which already leans to cards
///    that ask; a subject the reader clearly claimed — held at the top
///    while others came down, or pruned from the inside — starts *solid*,
///    where the hard questions come first. The first card the app puts in
///    front of somebody should say that this is not a quiz for children:
///    a reader who finds it a stretch feels respected, and one who finds it
///    easy is gone by Thursday. The measured level takes over as soon as
///    there is something to measure (`measuredLevels`).
/// 2. **A lean on the strands they picked by hand.** Strands left on in a
///    genre that was pruned, and genres left whole in a subject that was
///    pruned, are dealt a little sooner — the same lean a like gives, from
///    the moment the onboarding ends rather than after the tenth card.
/// 3. **A first week that opens on what they came for.** The first days
///    are when an app is judged, and a reader who asked for Space above all
///    and is dealt a card on grain prices on the first morning concludes
///    the mix did not work. So the first three days sharpen the mix
///    towards its top — squared and cubed, not replaced — and from the
///    fourth day the mix is exactly what they set, and the range they
///    asked for arrives. A reader who told the app nothing opens instead on
///    the subjects that hook most people (the mind, space, the body, the
///    strange, the past), then gets the whole spread.
library;

import 'dart:math' as math;

import 'genres.dart';

/// Who the onboarding describes, from the shape of their answers.
enum ReaderShape {
  /// Moved nothing and turned nothing off: no signal at all.
  untold,

  /// Four subjects or fewer: wants depth.
  specialist,

  /// Twelve subjects or more, and some of them told apart: wants range.
  generalist,

  /// Anything between.
  curious,
}

/// The reading of a mix. Pure: the same answers always read the same way,
/// so it is computed where it is needed rather than stored, and a reader
/// who changes the mix is read again at once.
class ReaderProfile {
  const ReaderProfile._({
    required this.shape,
    required this.levels,
    required this.lean,
    required this.claimed,
    required this.weights,
  });

  /// Nothing said: every subject even, nothing claimed.
  static const ReaderProfile blank = ReaderProfile._(
    shape: ReaderShape.untold,
    levels: {},
    lean: {},
    claimed: {},
    weights: {},
  );

  /// Below this a handle is out of the mix (the wheel's own floor, 6 of 100).
  static const double floor = 0.06;

  /// A subject held within this share of the top handle is at the top.
  static const double top = 0.85;

  /// A subject at or below this share of the top was told apart from it.
  static const double apart = 0.6;

  /// Specialist at this many subjects or fewer; generalist at this many or
  /// more.
  static const int specialistAt = 4;
  static const int generalistAt = 12;

  /// The lean on a strand left on inside a genre that was pruned, and on a
  /// genre left whole inside a subject that was pruned. A like moves a
  /// trait by 0.08, so a hand-picked strand starts where about four likes
  /// would have put it.
  static const double pickedStrand = 0.3;
  static const double keptGenre = 0.1;

  /// How hard the first days lean to the top of the mix: the weights are
  /// raised to this power on the reader's first, second and third day.
  static const List<double> focus = [3.0, 2.0, 1.5];

  /// The subjects most people are hooked by, for a reader who said nothing
  /// — how the mind fools itself, how big space is, what the body does,
  /// the plainly strange, the past. A judgement, not a measurement: once
  /// the analytics hold enough mixes (`mix set`), replace it with the
  /// subjects readers who do move the wheel push up most. Everything else
  /// counts 0.7.
  static const Map<String, double> hooks = {
    'psychology': 1.0,
    'space': 1.0,
    'human_body': 0.95,
    'weird_facts': 0.95,
    'history': 0.9,
    'science': 0.85,
  };

  final ReaderShape shape;

  /// The starting level of each subject in the mix: 1 some, 2 solid. Never
  /// 0 at the start — see the library comment.
  final Map<String, int> levels;

  /// A lean on tag traits (`strand:…`, `genre:…`) from what was picked by
  /// hand, in the same currency as the taste a like builds.
  final Map<String, double> lean;

  /// The subjects the reader claimed: held at the top while others came
  /// down, or pruned from inside.
  final Set<String> claimed;

  /// The mix as it was set, by topic key.
  final Map<String, double> weights;

  /// Reads the onboarding's answers.
  ///
  /// [weights] is the wheel, 0..1 by topic key, absent for a subject
  /// dragged to nothing — or empty, for a reader who never set it.
  /// [genresOff] and [strandsOff] are what was turned off one layer down.
  factory ReaderProfile.read({
    required Map<String, double> weights,
    Set<String> genresOff = const {},
    Set<String> strandsOff = const {},
  }) {
    final Map<String, double> mix = {
      for (final e in weights.entries)
        if (e.value > floor && kGenres.containsKey(e.key)) e.key: e.value,
    };
    final bool pruned = genresOff.isNotEmpty || strandsOff.isNotEmpty;
    final bool moved =
        mix.length < kGenres.length || mix.values.any((w) => w < 0.99);
    if (mix.isEmpty || (!pruned && !moved)) {
      return ReaderProfile._(
        shape: ReaderShape.untold,
        levels: {for (final key in kGenres.keys) key: 1},
        lean: const {},
        claimed: const {},
        weights: Map.unmodifiable(mix),
      );
    }

    final double highest = mix.values.reduce(math.max);
    double share(String key) => (mix[key] ?? 0) / highest;
    final bool toldApart = mix.keys.any((k) => share(k) <= apart);
    final int n = mix.length;
    final ReaderShape shape = n <= specialistAt
        ? ReaderShape.specialist
        : n >= generalistAt
        ? ReaderShape.generalist
        : ReaderShape.curious;

    // How much of each subject was turned off, in strands: a genre off is
    // its three.
    int strandsOffIn(String key) {
      var off = 0;
      for (final Genre g in kGenres[key]!) {
        if (genresOff.contains(g.id)) {
          off += g.strands.length;
          continue;
        }
        off += g.strands.where((s) => strandsOff.contains(s.id)).length;
      }
      return off;
    }

    final Set<String> claimed = {};
    final Map<String, int> levels = {};
    for (final String key in mix.keys) {
      final bool atTop = share(key) >= top;
      final bool curated = strandsOffIn(key) > 0 && share(key) >= apart;
      // At the top counts as a claim only when the reader told subjects
      // apart, or kept few enough that every one of them is chosen.
      final bool claim =
          curated || (atTop && (toldApart || shape == ReaderShape.specialist));
      if (claim) claimed.add(key);
      levels[key] = claim ? 2 : 1;
    }

    final Map<String, double> lean = {};
    for (final String key in mix.keys) {
      final List<Genre> genres = kGenres[key]!;
      final bool subjectPruned = strandsOffIn(key) > 0;
      for (final Genre g in genres) {
        if (genresOff.contains(g.id)) continue;
        final List<Strand> on = [
          for (final s in g.strands)
            if (!strandsOff.contains(s.id)) s,
        ];
        if (on.length < g.strands.length) {
          // Some of this genre was turned down and these were kept: picked
          // by hand, and the sharpest thing the reader has said.
          for (final s in on) {
            lean['strand:${s.id}'] = pickedStrand;
          }
        } else if (subjectPruned) {
          lean['genre:${g.id}'] = keptGenre;
        }
      }
    }

    return ReaderProfile._(
      shape: shape,
      levels: Map.unmodifiable(levels),
      lean: Map.unmodifiable(lean),
      claimed: Set.unmodifiable(claimed),
      weights: Map.unmodifiable(mix),
    );
  }

  /// The levels to deal at: these, under whatever the reader or the
  /// measurement has said since — a level that exists wins.
  Map<String, int> levelsUnder(Map<String, int> said) => {...levels, ...said};

  /// The taste to deal with: this lean, plus what likes and throws built.
  Map<String, double> tasteWith(Map<String, double> taste) {
    if (lean.isEmpty) return taste;
    final Map<String, double> out = Map.of(lean);
    taste.forEach((k, v) => out[k] = (out[k] ?? 0) + v);
    return out;
  }

  /// The mix for the reader's [day]th day (0 is the first): sharpened
  /// towards its top on the first three, as it was set from the fourth.
  ///
  /// [weights] is the mix as the dealer would use it — already leaned by
  /// likes, or empty for an even spread.
  Map<String, double> weightsOn(int day, Map<String, double> weights) {
    if (day < 0 || day >= focus.length) return weights;
    final double power = focus[day];
    if (shape == ReaderShape.untold) {
      final Iterable<String> keys = weights.isEmpty
          ? kGenres.keys
          : weights.keys;
      // The hooks sharpened the same way a mix is: on the first morning a
      // subject outside them is a third as likely, not a tenth less.
      return {
        for (final key in keys)
          key:
              (weights.isEmpty ? 1.0 : weights[key]!) *
              math.pow(hooks[key] ?? 0.7, power).toDouble(),
      };
    }
    if (weights.isEmpty) return weights;
    return {
      for (final e in weights.entries)
        e.key: math.pow(e.value, power).toDouble(),
    };
  }

  /// For analytics: the shape and how much was claimed, never which.
  Map<String, Object> get facts => {
    'shape': shape.name,
    'claimed': claimed.length,
    'solid_start': levels.values.where((l) => l >= 2).length,
    'hand_picked': lean.keys.where((k) => k.startsWith('strand:')).length,
  };
}
