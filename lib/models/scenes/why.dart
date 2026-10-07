/// `why`: ask why, and keep asking.
///
/// Something everyday the reader takes for granted sits on the surface:
/// coffee costs more at the airport, your ears pop on a plane. Every tap on
/// the card's own "And why?" digs one layer down to the cause underneath,
/// until the last layer, the root, lands at the bottom like a weight hitting
/// bedrock. Each layer is one short line, sometimes with a small figure (a
/// number and what it counts).
///
/// The descent is the reasoning move: the first answer people give is
/// rarely the real one, and the habit the card trains is asking a second and
/// a third time. Before the root the reader can be asked to guess it from two
/// or three options, so the last step is thought, not read.
///
/// JSON fields:
///
/// - `type`: `"why"`.
/// - `ask` (string, ≤ 16 chars): the button that digs one layer deeper,
///   in the card's language ("And why?").
/// - `start` (layer): the everyday thing on the surface.
/// - `levels` (3 to 5 layers): the causes, from the nearest to the root.
///   The last one is the root.
/// - A layer is `{text, figure?, unit?}`:
///   - `text` (string): one short line. The surface ≤ 64 chars, a cause
///     ≤ 72, the root ≤ 64 (it is set larger).
///   - `figure` (string, ≤ 9 chars, optional): a number as it is read,
///     units and signs included ("10–20%", "2,400 m", "×3").
///   - `unit` (string, ≤ 26 chars, optional, only with a figure): what the
///     figure counts ("of every sale, as rent").
/// - `guess` (optional): asked before the root is shown.
///   - `options` (2 or 3 strings, ≤ 34 chars, all different): candidate
///     roots, one of them right.
///   - `answer` (int): the index of the right option.
///
/// Example:
///
/// ```json
/// {
///   "type": "why",
///   "ask": "And why?",
///   "start": {"text": "A coffee at the gate costs more than in town."},
///   "levels": [
///     {"text": "The café hands the airport a cut of every sale as rent.",
///      "figure": "10–20%", "unit": "of sales, typically"},
///     {"text": "Airports live on shops and parking as much as on planes.",
///      "figure": "~40%", "unit": "of airport income"},
///     {"text": "A café there can pay that because its buyers can't leave."},
///     {"text": "Security made a captive crowd: no next street to walk to."}
///   ],
///   "guess": {
///     "options": ["Beans cost more to fly in", "Buyers can't go elsewhere",
///                 "Airport staff earn more"],
///     "answer": 1
///   }
/// }
/// ```
library;

import '../scene.dart';

/// One layer of the descent: a line, and maybe a figure with its unit.
class WhyStep {
  final String text;
  final String figure;
  final String unit;
  const WhyStep(this.text, {this.figure = '', this.unit = ''});

  bool get hasFigure => figure.isNotEmpty;
}

/// The reader's chance to name the root before it is shown.
class WhyGuess {
  final List<String> options;
  final int answer;
  const WhyGuess(this.options, this.answer);
}

/// Ask why, and keep asking.
class WhyScene extends Scene {
  /// The button that digs one layer deeper ("And why?").
  final String ask;

  /// The everyday thing on the surface.
  final WhyStep start;

  /// The causes, nearest first; the last is the root.
  final List<WhyStep> levels;

  /// Asked before the root, or null to dig straight down to it.
  final WhyGuess? guess;

  const WhyScene(
    super.raw, {
    required this.ask,
    required this.start,
    required this.levels,
    required this.guess,
  });

  WhyStep get root => levels.last;

  static WhyScene parse(Map<String, Object?> raw, Object? id) {
    WhyStep step(Object? m, String where) {
      if (m is! Map) throw FormatException('scene.$where: not an object', id);
      final text = m['text'];
      if (text is! String || text.trim().isEmpty) {
        throw FormatException('scene.$where.text: missing', id);
      }
      String opt(String k) {
        final v = m[k];
        if (v == null) return '';
        if (v is! String) throw FormatException('scene.$where.$k', id);
        return v.trim();
      }

      final figure = opt('figure');
      final unit = opt('unit');
      if (unit.isNotEmpty && figure.isEmpty) {
        throw FormatException('scene.$where.unit: needs a figure', id);
      }
      return WhyStep(text.trim(), figure: figure, unit: unit);
    }

    final ask = raw['ask'];
    if (ask is! String || ask.trim().isEmpty) {
      throw FormatException('scene.ask must be a string', id);
    }
    final list = raw['levels'];
    if (list is! List || list.length < 3 || list.length > 5) {
      throw FormatException('scene.levels: between 3 and 5', id);
    }
    final levels = [
      for (var i = 0; i < list.length; i++) step(list[i], 'levels[$i]'),
    ];

    WhyGuess? guess;
    final g = raw['guess'];
    if (g != null) {
      if (g is! Map || g['options'] is! List || g['answer'] is! int) {
        throw FormatException('scene.guess: {options, answer}', id);
      }
      final options = <String>[];
      for (final o in g['options'] as List) {
        if (o is! String || o.trim().isEmpty) {
          throw FormatException('scene.guess.options: strings', id);
        }
        options.add(o.trim());
      }
      final answer = g['answer'] as int;
      if (options.length < 2 ||
          options.length > 3 ||
          options.toSet().length != options.length ||
          answer < 0 ||
          answer >= options.length) {
        throw FormatException('scene.guess: 2 or 3 options, one answer', id);
      }
      guess = WhyGuess(options, answer);
    }

    return WhyScene(
      raw,
      ask: ask.trim(),
      start: step(raw['start'], 'start'),
      levels: levels,
      guess: guess,
    );
  }
}
