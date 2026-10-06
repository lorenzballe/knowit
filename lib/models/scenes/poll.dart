/// `poll`: you first.
///
/// A question about the reader, or a choice they would make — €100 today or
/// €120 in a month, a sure thing or a gamble — answered with one tap before
/// they see anyone else's answer. Then the options turn into bars that grow
/// to how the people in a named study answered, the reader's own row stays
/// lit with "YOU" on it, and one line says what the research found about
/// people who chose as they did, and one says why people split at all.
///
/// The reasoning move is the commitment: the reader cannot look at the
/// crowd first, so what they see afterwards is about themself. Nothing in
/// the format grades the answer. A poll is never a quiz in disguise; every
/// option gets a line that would make its chooser nod, not wince.
///
/// With two questions the card becomes an experiment on the reader. The
/// same choice is put twice in different words (lives saved, then lives
/// lost) or with one thing moved (the wait starts today, then in six
/// months). Option *i* of the second question is the same choice as option
/// *i* of the first, so the format can tell whether the reader held steady
/// or switched, and says so with the line the research has for each. The
/// first question's crowd is only shown after the second answer, so it
/// cannot steer it.
///
/// JSON fields:
///
/// - `type`: `"poll"`.
/// - `who` (string, ≤ 40 chars): who answered, and in which study, read as
///   the small heading over the bars ("152 students, Tversky & Kahneman").
/// - `questions` (1 or 2): each `{prompt?, tag?, options}`.
///   - `prompt` (string, ≤ 80 chars): the question in the scene, over its
///     options. Optional with one question, where the card's own question
///     already asks it; required with two.
///   - `tag` (string, ≤ 30 chars): this question's name in the results
///     ("Told as lives saved"). Required with two questions, unused with
///     one. It may say what changed, since it is only read after both
///     answers.
///   - `options`: 2 to 4 with one question, exactly 2 with two. Each is
///     `{label, share, mirror?}`.
///     - `label` (string, ≤ 24 chars): the choice ("€100 today").
///     - `share` (number, 0 to 100): the percentage of the study's people
///       who chose it. A question's shares add up to 100, give or take 2
///       for rounding.
///     - `mirror` (string, ≤ 100 chars): with one question, required on
///       every option: what the research says about people who chose this.
///       Unused with two.
/// - `why` (string, ≤ 100 chars): the one line on why people split.
/// - `same`, `switched` (string, ≤ 100 chars each): with two questions,
///   required: the line for a reader who made the same choice both times,
///   and for one who changed.
///
/// Example (two questions):
///
/// ```json
/// {
///   "type": "poll",
///   "who": "Students, Tversky & Kahneman 1981",
///   "questions": [
///     {"prompt": "Programme A or programme B?", "tag": "Told as lives saved",
///      "options": [{"label": "200 saved for sure", "share": 72},
///                  {"label": "1/3 chance all saved", "share": 28}]},
///     {"prompt": "Now C or D, for the same 600?", "tag": "Told as deaths",
///      "options": [{"label": "400 die for sure", "share": 22},
///                  {"label": "1/3 chance nobody dies", "share": 78}]}
///   ],
///   "why": "A sure gain feels safe. A sure loss feels unbearable, so we gamble to dodge it.",
///   "same": "You held steady. The crowd didn't: the sure option fell from 72% to 22%.",
///   "switched": "You switched, like most people do. The numbers never changed; only the words did."
/// }
/// ```
///
/// With one question, `tag`, `same` and `switched` go, and every option
/// carries its `mirror` instead.
library;

import '../scene.dart';

/// One answer the reader can give, and how the study's people gave it.
class PollOption {
  final String label;

  /// Percentage of the study's people, 0 to 100.
  final double share;

  /// What the research says about people who chose this; empty with two
  /// questions.
  final String mirror;
  const PollOption(this.label, this.share, this.mirror);
}

/// One question put to the reader.
class PollQuestion {
  final String prompt;
  final String tag;
  final List<PollOption> options;
  const PollQuestion(this.prompt, this.tag, this.options);
}

/// You first.
class PollScene extends Scene {
  final String who;
  final List<PollQuestion> questions;
  final String why;
  final String same;
  final String switched;

  const PollScene(
    super.raw, {
    required this.who,
    required this.questions,
    required this.why,
    required this.same,
    required this.switched,
  });

  /// The same choice put twice in different words.
  bool get twice => questions.length == 2;

  static PollScene parse(Map<String, Object?> raw, Object? id) {
    String text(Object? v, String name, {bool required = true}) {
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (!required && v == null) return '';
      throw FormatException('scene.$name must be a string', id);
    }

    final list = raw['questions'];
    if (list is! List || list.isEmpty || list.length > 2) {
      throw FormatException('scene.questions: one or two', id);
    }
    final twice = list.length == 2;
    final questions = <PollQuestion>[];
    for (var q = 0; q < list.length; q++) {
      final m = list[q];
      if (m is! Map) {
        throw FormatException('scene.questions[$q]: not an object', id);
      }
      final opts = m['options'];
      final (lo, hi) = twice ? (2, 2) : (2, 4);
      if (opts is! List || opts.length < lo || opts.length > hi) {
        throw FormatException(
          'scene.questions[$q].options: between $lo and $hi',
          id,
        );
      }
      final options = <PollOption>[];
      var sum = 0.0;
      for (final o in opts) {
        if (o is! Map || o['share'] is! num) {
          throw FormatException('scene.options: each is {label, share}', id);
        }
        final share = (o['share'] as num).toDouble();
        if (!share.isFinite || share < 0 || share > 100) {
          throw FormatException('scene.options: share is 0 to 100', id);
        }
        sum += share;
        options.add(
          PollOption(
            text(o['label'], 'options.label'),
            share,
            text(o['mirror'], 'options.mirror', required: !twice),
          ),
        );
      }
      if ((sum - 100).abs() > 2) {
        throw FormatException('scene.questions[$q]: shares add up to $sum', id);
      }
      questions.add(
        PollQuestion(
          text(m['prompt'], 'questions.prompt', required: twice),
          text(m['tag'], 'questions.tag', required: twice),
          options,
        ),
      );
    }
    return PollScene(
      raw,
      who: text(raw['who'], 'who'),
      questions: questions,
      why: text(raw['why'], 'why'),
      same: text(raw['same'], 'same', required: twice),
      switched: text(raw['switched'], 'switched', required: twice),
    );
  }

  /// The reader's line, given their picks (one per question): the mirror
  /// of the option they chose, or with two questions whether they held
  /// steady or switched.
  String lineFor(List<int> picks) {
    if (twice) return picks[0] == picks[1] ? same : switched;
    return questions[0].options[picks[0]].mirror;
  }
}
