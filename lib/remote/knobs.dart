/// What the server can set inside the app without a release: switches
/// (`app.flags`), numbers and lists (`app.tunables`) and experiments
/// (`app.experiments`) — the rest of the remote document's `app` part.
///
/// Every one of them is declared where it is read, as a constant that says
/// its name and the build's own value — a [RemoteFlag], a [RemoteNumber],
/// [RemoteTimes] or a [RemoteExperiment] — so that the build's app is the
/// floor: a document that says nothing of it, or says something this build
/// cannot take (the wrong type, a number out of its range, a variant it has
/// never heard of), leaves it as built. tool/remote/parts/app_knobs.json
/// lists them all for the checker, and test/remote_knobs_test.dart holds the
/// list and the declarations to each other. docs/REMOTE.md has the table.
library;

import 'package:flutter/foundation.dart';

import '../analytics.dart';
import 'remote.dart';

/// A switch, on or off as built, which the server can throw for some
/// readers or for everybody: `{"push.ask": {"on": false}}`, or with an
/// audience, `{"on": false, "audience": {"platforms": ["android"]}}`.
@immutable
class RemoteFlag {
  const RemoteFlag(this.name, {required this.fallback});

  /// Its key in `app.flags`.
  final String name;

  /// The build's own setting.
  final bool fallback;

  /// Whether it is on for the reader [at] describes.
  bool on(RemoteContext at) => Flags.on(name, at, fallback: fallback);
}

/// A whole number the app tunes by, which the server can move within
/// [min] and [max]: `{"push.askGapDays": 5}`.
@immutable
class RemoteNumber {
  const RemoteNumber(
    this.name, {
    required this.fallback,
    required this.min,
    required this.max,
  });

  /// Its key in `app.tunables`.
  final String name;

  /// The build's own number.
  final int fallback;
  final int min;
  final int max;

  /// The number in force.
  int get value => Tunables.number(name, fallback, min: min, max: max);
}

/// Times of day, as "HH:mm", one for each of [windows]: the server can move
/// each within its own window, `[from, to)`, so that the word the app puts
/// beside it ("Morning", "Lunchtime") stays true.
@immutable
class RemoteTimes {
  const RemoteTimes(this.name, {required this.fallback, required this.windows});

  /// Its key in `app.tunables`.
  final String name;

  /// The build's own times.
  final List<String> fallback;

  /// Where each time may be, as "HH:mm" pairs, the first included and the
  /// second not.
  final List<(String, String)> windows;

  /// The times in force.
  List<String> get value => Tunables.list(name, fallback, valid: fits);

  /// Whether [times] are one for each window, in order, each inside its own.
  bool fits(List<String> times) {
    if (times.length != windows.length) return false;
    for (int i = 0; i < times.length; i++) {
      final int? at = minuteOf(times[i]);
      final int? from = minuteOf(windows[i].$1);
      final int? to = minuteOf(windows[i].$2);
      if (at == null || from == null || to == null) return false;
      if (at < from || at >= to) return false;
    }
    return true;
  }

  /// Minutes after midnight for "HH:mm", or null for anything else.
  static int? minuteOf(String at) {
    final RegExpMatch? m = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(at);
    if (m == null) return null;
    final int h = int.parse(m.group(1)!), min = int.parse(m.group(2)!);
    return h < 24 && min < 60 ? h * 60 + min : null;
  }
}

/// An experiment the server can run on the app: which of [variants] each
/// reader is given, by weight, among the readers its audience allows.
/// Everybody else, and everybody while the document runs no such
/// experiment, is given [fallback], the build's own.
@immutable
class RemoteExperiment {
  const RemoteExperiment(
    this.name, {
    required this.variants,
    required this.fallback,
  });

  /// Its key in `app.experiments`.
  final String name;

  /// The variants this build can show.
  final List<String> variants;

  /// What a reader outside the experiment is shown: one of [variants].
  final String fallback;

  /// The variant for the reader [at] describes. Read it at the moment the
  /// variants part ways, and only then: reading it is what says the reader
  /// was in the experiment (Experiments.variant).
  String variant(RemoteContext at) =>
      Experiments.variant(name, at, known: variants) ?? fallback;
}

/// The switches of `app.flags`.
abstract final class Flags {
  /// Whether the switch [name] is on for the reader [at] describes.
  ///
  /// `true` or `false` sets it for everybody; `{"on": …, "audience": …}`
  /// sets it for the readers the audience allows (Audience.allows, split by
  /// the switch's own name), and leaves everybody else on [fallback], the
  /// build's own. So does anything this build cannot read.
  static bool on(String name, RemoteContext at, {required bool fallback}) {
    final Object? flags = Remote.config.part('app')['flags'];
    if (flags is! Map) return fallback;
    final Object? flag = flags[name];
    if (flag is bool) return flag;
    if (flag is! Map) return fallback;
    final Object? on = flag['on'];
    if (on is! bool) return fallback;
    return Audience.allows(flag['audience'], at, salt: name) ? on : fallback;
  }
}

/// The numbers, words and lists of `app.tunables`. Each is the build's own
/// unless the document sets it to something that passes: the right type,
/// within its range.
abstract final class Tunables {
  static Map<Object?, Object?> get _all {
    final Object? raw = Remote.config.part('app')['tunables'];
    return raw is Map ? raw : const {};
  }

  /// The number [name], within [min] and [max] inclusive, or [fallback].
  /// An int [fallback] takes whole numbers only: 2.5 days is no setting.
  static T number<T extends num>(String name, T fallback, {T? min, T? max}) {
    final Object? raw = _all[name];
    if (raw is! num || !raw.isFinite) return fallback;
    final num value;
    if (fallback is int) {
      if (raw != raw.roundToDouble()) return fallback;
      value = raw.toInt();
    } else {
      value = raw.toDouble();
    }
    if ((min != null && value < min) || (max != null && value > max)) {
      return fallback;
    }
    return value as T;
  }

  /// The words [name], or [fallback]: never empty, no longer than
  /// [maxLength], and one of [oneOf] when that is given.
  static String string(
    String name,
    String fallback, {
    Iterable<String>? oneOf,
    int maxLength = 500,
  }) {
    final Object? raw = _all[name];
    if (raw is! String || raw.trim().isEmpty || raw.length > maxLength) {
      return fallback;
    }
    if (oneOf != null && !oneOf.contains(raw)) return fallback;
    return raw;
  }

  /// The list of words [name], or [fallback]: every item a string, as many
  /// as [minLength] to [maxLength], and the whole of it [valid] when that
  /// is given.
  static List<String> list(
    String name,
    List<String> fallback, {
    int minLength = 1,
    int? maxLength,
    bool Function(List<String> items)? valid,
  }) {
    final Object? raw = _all[name];
    if (raw is! List || raw.any((item) => item is! String)) return fallback;
    final List<String> items = List.unmodifiable(raw.cast<String>());
    if (items.length < minLength) return fallback;
    if (maxLength != null && items.length > maxLength) return fallback;
    if (valid != null && !valid(items)) return fallback;
    return items;
  }
}

/// The experiments of `app.experiments`, and the word to PostHog that a
/// reader is in one.
abstract final class Experiments {
  /// The exposures said in this sitting, as `name=variant`.
  static final Set<String> _said = {};

  /// Which variant of the experiment [name] the reader [at] describes is
  /// given, or null when they are in no such experiment: the document runs
  /// none, its audience leaves them out, or it gives them a variant this
  /// build cannot show — one of [known] is all a build can show.
  ///
  /// `{"variants": ["a", "b"], "weights": [1, 1], "audience": {…}}`: the
  /// variant comes from Audience.variantOf, so the same phone has the same
  /// one every time; the audience is split by the experiment's own name,
  /// apart from the variants, so a rollout of 20% does not take the 20% of
  /// one variant. Weights are equal when left out.
  ///
  /// The first time in a sitting that it gives a reader a variant, it says
  /// so: `experiment exposed`, and the variant on every later event and on
  /// the reader's profile, as `experiment_<name>` (docs/TRACKING.md). So it
  /// is read where the variants part ways, and not before.
  static String? variant(
    String name,
    RemoteContext at, {
    required Iterable<String> known,
  }) {
    final Object? all = Remote.config.part('app')['experiments'];
    if (all is! Map) return null;
    final Object? experiment = all[name];
    if (experiment is! Map) return null;
    final Object? rawVariants = experiment['variants'];
    if (rawVariants is! List ||
        rawVariants.isEmpty ||
        rawVariants.any((v) => v is! String || v.isEmpty)) {
      return null;
    }
    final List<String> variants = rawVariants.cast<String>();
    if (variants.toSet().length != variants.length) return null;
    final Object? rawWeights = experiment['weights'];
    List<num>? weights;
    if (rawWeights != null) {
      if (rawWeights is! List ||
          rawWeights.length != variants.length ||
          rawWeights.any((w) => w is! num || !w.isFinite || w < 0) ||
          rawWeights.cast<num>().fold<num>(0, (a, b) => a + b) <= 0) {
        return null;
      }
      weights = rawWeights.cast<num>();
    }
    if (!Audience.allows(experiment['audience'], at, salt: name)) return null;
    final String given = Audience.variantOf(name, variants, weights);
    if (!known.contains(given)) return null;
    _expose(name, given);
    return given;
  }

  static void _expose(String name, String variant) {
    if (!_said.add('$name=$variant')) return;
    Analytics.capture('experiment exposed', {
      'experiment': name,
      'variant': variant,
      'remote_hash': Remote.config.hash,
    });
    // On every later event, and on the profile: a funnel cut by variant
    // needs no join (docs/TRACKING.md, §3 and §4).
    Analytics.register(personProperty(name), variant);
    Analytics.person(set: {personProperty(name): variant});
  }

  /// The profile property an experiment's variant is kept under:
  /// `experiment_` and its name in snake case, `push.firstAsk` as
  /// `experiment_push_first_ask`.
  static String personProperty(String name) {
    final String snake = name
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (m) => '_${m.group(0)!.toLowerCase()}',
        )
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'experiment_$snake';
  }

  /// The sitting is over: the next one says its exposures again, once each.
  /// From main(), as the app leaves the screen.
  static void sittingEnded() => _said.clear();

  /// Forgets the exposures said. Tests, and nothing else.
  @visibleForTesting
  static void resetForTest() => _said.clear();
}
