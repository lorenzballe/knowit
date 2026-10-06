/// `clues`: guess from clues.
///
/// A handful of suspects — diseases, causes, centuries — and a pile of
/// evidence cards laid on the table one at a time. The reader may name the
/// answer whenever they like: the earlier they commit, the more points they
/// keep, so every card turned over costs something. At the end each wrong
/// suspect is struck off by the number of the clue that ruled it out, and the
/// clue that settled it turns over: that is the lesson. A clue that fits
/// every suspect proves nothing, however vivid it is; the one that rules
/// options out is the one that counts.
///
/// The writer says, for every clue, which options it rules out. Each wrong
/// option is ruled out exactly once, by the first clue that excludes it, and
/// the answer never is. The decisive clue is the one that strikes off the
/// last wrong option; it is worked out, not written, and it is never the
/// first. Clues after it rule nothing out: they confirm, and they are often
/// the most convincing-looking ones (the pump that fits cholera fits typhoid
/// too).
///
/// JSON fields:
///
/// - `type`: `"clues"`.
/// - `options` (3 to 5 strings, ≤ 16 chars each, all different): the
///   suspects, as the reader taps them ("Cholera", "1920s–50s").
/// - `answer` (int): the index of the true option.
/// - `clues` (3 to 5), in the order they are laid down, each with:
///   - `text` (string, ≤ 84 chars): the evidence, as one or two sentences.
///   - `tag` (string, ≤ 24 chars): its short name, shown on the edge of the
///     card once another card lies over it ("Dead within a day").
///   - `rulesOut` (list of option indices, may be empty): the options this
///     clue excludes, and that no earlier clue already excluded.
/// - `why` (string, ≤ 100 chars): the line shown at the end, saying why the
///   decisive clue decides.
///
/// Example:
///
/// ```json
/// {
///   "type": "clues",
///   "options": ["Cholera", "Plague", "Smallpox", "Typhoid"],
///   "answer": 0,
///   "clues": [
///     {"text": "Over 500 people in a few London streets die within ten days.",
///      "tag": "500 dead in ten days", "rulesOut": []},
///     {"text": "No rash, no swollen glands: violent diarrhoea and vomiting.",
///      "tag": "No rash, no swellings", "rulesOut": [1, 2]},
///     {"text": "Many die within a day of feeling the first cramp.",
///      "tag": "Dead within a day", "rulesOut": [3]},
///     {"text": "The dead drank from one pump. The brewery's men drank beer and lived.",
///      "tag": "One pump, spared brewers", "rulesOut": []}
///   ],
///   "why": "Speed decides: typhoid takes weeks to kill, cholera hours. The pump fits typhoid just as well."
/// }
/// ```
library;

import '../scene.dart';

/// One card of evidence.
class CluesClue {
  final String text;
  final String tag;

  /// Option indices this clue strikes off.
  final List<int> rulesOut;
  const CluesClue(this.text, this.tag, this.rulesOut);
}

/// Guess from clues.
class CluesScene extends Scene {
  final List<String> options;
  final int answer;

  /// In the order they are laid down.
  final List<CluesClue> clues;
  final String why;

  const CluesScene(
    super.raw, {
    required this.options,
    required this.answer,
    required this.clues,
    required this.why,
  });

  static CluesScene parse(Map<String, Object?> raw, Object? id) {
    String text(Object? v, String what) {
      if (v is String && v.trim().isNotEmpty) return v.trim();
      throw FormatException('scene.$what must be a string', id);
    }

    final opts = raw['options'];
    if (opts is! List || opts.length < 3 || opts.length > 5) {
      throw FormatException('scene.options: between 3 and 5', id);
    }
    final options = [
      for (var i = 0; i < opts.length; i++) text(opts[i], 'options[$i]'),
    ];
    if (options.map((o) => o.toLowerCase()).toSet().length != options.length) {
      throw FormatException('scene.options: two options are the same', id);
    }
    final answer = raw['answer'];
    if (answer is! int || answer < 0 || answer >= options.length) {
      throw FormatException('scene.answer: an index into options', id);
    }

    final list = raw['clues'];
    if (list is! List || list.length < 3 || list.length > 5) {
      throw FormatException('scene.clues: between 3 and 5', id);
    }
    final struck = <int>{};
    final clues = <CluesClue>[];
    for (var i = 0; i < list.length; i++) {
      final m = list[i];
      if (m is! Map) throw FormatException('scene.clues[$i]: not an object', id);
      final out = m['rulesOut'] ?? const [];
      if (out is! List) {
        throw FormatException('scene.clues[$i].rulesOut: a list', id);
      }
      final rules = <int>[];
      for (final o in out) {
        if (o is! int || o < 0 || o >= options.length) {
          throw FormatException('scene.clues[$i].rulesOut: bad index', id);
        }
        if (o == answer) {
          throw FormatException('scene.clues[$i] rules out the answer', id);
        }
        if (!struck.add(o)) {
          throw FormatException('scene.clues[$i]: option $o already out', id);
        }
        rules.add(o);
      }
      clues.add(
        CluesClue(
          text(m['text'], 'clues[$i].text'),
          text(m['tag'], 'clues[$i].tag'),
          List.unmodifiable(rules),
        ),
      );
    }
    if (struck.length != options.length - 1) {
      throw FormatException('scene.clues: every wrong option must go', id);
    }
    final scene = CluesScene(
      raw,
      options: List.unmodifiable(options),
      answer: answer,
      clues: List.unmodifiable(clues),
      why: text(raw['why'], 'why'),
    );
    if (scene.decisive == 0) {
      throw FormatException('scene.clues: the first clue cannot decide', id);
    }
    return scene;
  }

  /// The clue that strikes off the last wrong option.
  int get decisive {
    var last = 0;
    for (var i = 0; i < clues.length; i++) {
      if (clues[i].rulesOut.isNotEmpty) last = i;
    }
    return last;
  }

  /// The clue that rules [option] out, or -1 for the answer.
  int outBy(int option) {
    for (var i = 0; i < clues.length; i++) {
      if (clues[i].rulesOut.contains(option)) return i;
    }
    return -1;
  }

  /// Points kept by a right answer named after [seen] clues: 100 for the
  /// first alone, falling by an even step per clue to 100 / n for all.
  int pointsAfter(int seen) {
    final n = clues.length;
    final s = seen.clamp(1, n);
    return (100 * (n - s + 1) / n).round();
  }
}
