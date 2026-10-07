/// `story`: what happens next?
///
/// A real case told in a few short scenes the reader taps through, each one
/// a big line, a small fact (a place, a date, a number) and a drawn glyph
/// that turns into the next one. Then the story stops and asks. The reader
/// commits to an outcome before seeing it, so the surprise lands on their
/// own prediction, not on a stranger's: the gap between what they expected
/// and what happened is the lesson, and the last line names the mechanism
/// that made the gap.
///
/// JSON fields:
///
/// - `type`: `"story"`.
/// - `scenes` (3 to 5, required): the story so far, in order. Each is
///   `{line, fact, glyph}`:
///   - `line` (text, required, up to 64 characters): what happens, said
///     plainly, one idea. Set big, on up to three lines.
///   - `fact` (text, optional, up to 32): a place, a date or a number that
///     anchors it, set in small spaced capitals above the line
///     ("Hanoi, 1902").
///   - `glyph` (required): the drawing, one of [StoryGlyph]'s names
///     (`pin`, `lights`, `car`, `walker`, `crowd`, `family`, `house`,
///     `clock`, `calendar`, `coin`, `ticket`, `rat`, `drain`, `eye`,
///     `rise`, `fall`, `ban`, `check`, `cross`, `book`, `phone`). Each
///     glyph turns into the next as the scenes change.
/// - `ask` (text, required, up to 56): the question at the stop ("What
///   happens to the crashes?"). The glyph turns into a question mark.
/// - `options` (2 or 3, required): the possible outcomes, each
///   `{label}` with `label` up to 26 characters, one line on a button.
/// - `answer` (whole number, required): the index of the option that came
///   true.
/// - `outcome` (required): what really happened, `{line, fact, glyph}`
///   with the same limits as a scene.
/// - `why` (text, required, up to 100): the last line, the mechanism that
///   explains the outcome ("Nobody told drivers who goes first, so they
///   slowed down and looked.").
///
/// A full example:
///
/// ```json
/// {
///   "type": "story",
///   "scenes": [
///     {"fact": "Drachten, the Netherlands", "glyph": "car",
///      "line": "A busy junction in the town centre. Cars, bikes, buses."},
///     {"fact": "The Laweiplein", "glyph": "lights",
///      "line": "Traffic lights, signs and road lines tell everyone who goes."},
///     {"fact": "Engineer Hans Monderman", "glyph": "ban",
///      "line": "He takes them all away. No lights, no signs, no lines."}
///   ],
///   "ask": "What happens to the crashes?",
///   "options": [
///     {"label": "They go up"},
///     {"label": "No real change"},
///     {"label": "They go down"}
///   ],
///   "answer": 2,
///   "outcome": {"fact": "One year later", "glyph": "fall",
///               "line": "Half as many crashes, with a third more traffic."},
///   "why": "With nothing telling them it was safe, drivers slowed down and looked each other in the eye."
/// }
/// ```
library;

import '../scene.dart';

/// The drawings a scene can carry. Each is line art in a 100 × 100 box,
/// drawn by the view; the names are the JSON's.
enum StoryGlyph {
  pin,
  lights,
  car,
  walker,
  crowd,
  family,
  house,
  clock,
  calendar,
  coin,
  ticket,
  rat,
  drain,
  eye,
  rise,
  fall,
  ban,
  check,
  cross,
  book,
  phone,

  /// The stop: drawn for the question, never named in the JSON.
  question,
}

/// One moment of the story: a line, the fact that anchors it, a drawing.
class StoryBeat {
  final String line;
  final String fact;
  final StoryGlyph glyph;
  const StoryBeat(this.line, this.fact, this.glyph);
}

/// What happens next?
class StoryScene extends Scene {
  /// The story up to the stop, in order.
  final List<StoryBeat> scenes;

  /// The question at the stop.
  final String ask;

  /// The possible outcomes, as the buttons say them.
  final List<String> options;

  /// Which of [options] came true.
  final int answer;

  /// What really happened.
  final StoryBeat outcome;

  /// The mechanism, in one line.
  final String why;

  const StoryScene(
    super.raw, {
    required this.scenes,
    required this.ask,
    required this.options,
    required this.answer,
    required this.outcome,
    required this.why,
  });

  static const minScenes = 3;
  static const maxScenes = 5;

  static StoryScene parse(Map<String, Object?> raw, Object? id) {
    String text(Object? v, String where, {bool required = true}) {
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v != null && v is! String) {
        throw FormatException('scene.$where must be text', id);
      }
      if (required) throw FormatException('scene.$where is missing', id);
      return '';
    }

    StoryBeat beat(Object? v, String where) {
      if (v is! Map) {
        throw FormatException('scene.$where is {line, fact, glyph}', id);
      }
      final name = v['glyph'];
      final glyph = StoryGlyph.values.where(
        (g) => g.name == name && g != StoryGlyph.question,
      );
      if (glyph.isEmpty) {
        throw FormatException('scene.$where.glyph: unknown "$name"', id);
      }
      return StoryBeat(
        text(v['line'], '$where.line'),
        text(v['fact'], '$where.fact', required: false),
        glyph.first,
      );
    }

    final rawScenes = raw['scenes'];
    if (rawScenes is! List ||
        rawScenes.length < minScenes ||
        rawScenes.length > maxScenes) {
      throw FormatException(
        'scene.scenes must be $minScenes to $maxScenes scenes',
        id,
      );
    }
    final scenes = [
      for (var i = 0; i < rawScenes.length; i++)
        beat(rawScenes[i], 'scenes[$i]'),
    ];

    final rawOptions = raw['options'];
    if (rawOptions is! List || rawOptions.length < 2 || rawOptions.length > 3) {
      throw FormatException('scene.options must be 2 or 3 outcomes', id);
    }
    final options = <String>[];
    for (var i = 0; i < rawOptions.length; i++) {
      final o = rawOptions[i];
      if (o is! Map) throw FormatException('scene.options[$i] is {label}', id);
      options.add(text(o['label'], 'options[$i].label'));
    }

    final answer = raw['answer'];
    if (answer is! int || answer < 0 || answer >= options.length) {
      throw FormatException('scene.answer must point at an option', id);
    }

    return StoryScene(
      raw,
      scenes: scenes,
      ask: text(raw['ask'], 'ask'),
      options: options,
      answer: answer,
      outcome: beat(raw['outcome'], 'outcome'),
      why: text(raw['why'], 'why'),
    );
  }

  /// Every stop the reader passes: the scenes, the question, the outcome.
  int get stops => scenes.length + 2;

  /// The stop that asks.
  int get askAt => scenes.length;

  /// The stop that tells.
  int get outcomeAt => scenes.length + 1;
}
