import 'package:flutter/material.dart';

/// What a card asks of the reader before it will turn over.
///
/// Modelled as a sealed hierarchy rather than a kind flag with a drawer of
/// nullable fields: a card either asks nothing, asks you to pick, or asks you
/// to work out a number, and each of those carries exactly the data it needs.
/// Adding a new way to ask means a new subclass, and the switches that render
/// and grade cards stop compiling until they handle it.
sealed class Challenge {
  const Challenge();

  /// Whether [response] — the raw string the reader committed to — is right.
  bool accepts(String response);

  /// Whether being right is even a thing here. A debate card asks the reader
  /// to take a side; scoring that would be telling them their opinion is
  /// wrong. Ungraded cards stay out of the tally entirely.
  bool get isGraded => true;

  /// How the reader's own answer should read back to them on the reveal.
  String describe(String response) => response;
}

/// Nothing to answer. Turn it over and read.
class NoChallenge extends Challenge {
  const NoChallenge();

  @override
  bool accepts(String response) => false;

  @override
  bool get isGraded => false;
}

/// Pick one of the options. The response is the option's index.
class PickOne extends Challenge {
  final List<String> options;
  final int correct;

  const PickOne({required this.options, required this.correct});

  int? _index(String response) => int.tryParse(response);

  @override
  bool accepts(String response) => _index(response) == correct;

  @override
  String describe(String response) {
    final i = _index(response);
    return (i != null && i >= 0 && i < options.length) ? options[i] : response;
  }

  String get correctOption => options[correct];
}

/// Work it out and type the number — the shape a competition problem takes.
class TypeNumber extends Challenge {
  final num answer;

  /// What the number counts, for the reveal: "days", "handshakes".
  final String unit;

  /// Allowed slack, for the rare answer that is not a whole number.
  final num tolerance;

  const TypeNumber({required this.answer, this.unit = '', this.tolerance = 0});

  /// Reads a typed answer, tolerating spaces and either decimal separator.
  static num? parse(String response) {
    final cleaned = response.trim().replaceAll(' ', '').replaceAll(',', '.');
    return cleaned.isEmpty ? null : num.tryParse(cleaned);
  }

  @override
  bool accepts(String response) {
    final given = parse(response);
    if (given == null) return false;
    return (given - answer).abs() <= tolerance;
  }

  String get answerLabel => unit.isEmpty ? '$answer' : '$answer $unit';
}

/// Work out roughly how big something is. Being close is the skill — a Fermi
/// estimate is judged on order of magnitude, not on hitting the number.
class Estimate extends Challenge {
  final num answer;
  final String unit;

  /// Anything between answer/[withinFactor] and answer×[withinFactor] counts.
  final num withinFactor;

  const Estimate({required this.answer, this.unit = '', this.withinFactor = 3});

  @override
  bool accepts(String response) {
    final given = TypeNumber.parse(response);
    if (given == null || given <= 0) return false;
    return given >= answer / withinFactor && given <= answer * withinFactor;
  }

  String get answerLabel => unit.isEmpty ? '$answer' : '$answer $unit';

  /// What counted as close enough, for the reveal.
  String get band =>
      '${(answer / withinFactor).round()} to ${(answer * withinFactor).round()}';
}

/// Take a side. There is no right answer — the point is to commit, then meet
/// the strongest version of the case against you.
class TakeASide extends Challenge {
  final List<String> positions;

  const TakeASide({required this.positions});

  @override
  bool accepts(String response) => false;

  @override
  bool get isGraded => false;

  @override
  String describe(String response) {
    final i = int.tryParse(response);
    return (i != null && i >= 0 && i < positions.length)
        ? positions[i]
        : response;
  }
}

/// What the reader committed to: the answer, and how sure they were.
///
/// Confidence is the whole point of calibration — being right matters less
/// than knowing how likely you are to be right. Null where the card never
/// asked, so old answers and debate cards stay valid.
class Answer {
  final String response;
  final int? confidence;

  /// On an ungraded card, the line the reader wrote before they were shown
  /// the other side. Committing to a reason first is what makes the
  /// counter-argument land instead of being explained away on sight.
  final String? reason;

  /// How far up the review ladder this card has climbed. A wrong answer
  /// knocks it back to the bottom.
  final int stage;

  /// The day this card comes back, as a date key. Null once it has been
  /// answered right often enough to retire.
  final String? dueOn;

  const Answer(
    this.response, {
    this.confidence,
    this.reason,
    this.stage = 0,
    this.dueOn,
  });

  bool get hasReason => (reason ?? '').trim().isNotEmpty;

  Answer copyWith({
    String? response,
    int? confidence,
    String? reason,
    int? stage,
    String? dueOn,
    bool clearDue = false,
  }) => Answer(
    response ?? this.response,
    confidence: confidence ?? this.confidence,
    reason: reason ?? this.reason,
    stage: stage ?? this.stage,
    dueOn: clearDue ? null : (dueOn ?? this.dueOn),
  );

  Map<String, dynamic> toJson() => {
    'r': response,
    if (confidence != null) 'c': confidence,
    if (hasReason) 'w': reason,
    if (stage != 0) 's': stage,
    if (dueOn != null) 'd': dueOn,
  };

  static Answer? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final response = raw['r'];
    if (response is! String) return null;
    final confidence = raw['c'];
    final reason = raw['w'];
    final stage = raw['s'];
    final due = raw['d'];
    return Answer(
      response,
      confidence: confidence is int ? confidence : null,
      reason: reason is String ? reason : null,
      stage: stage is int ? stage : 0,
      dueOn: due is String ? due : null,
    );
  }
}

/// One judgement the reader made, kept for as long as the app lives.
///
/// Calibration is a track record, not a property of a card: answering the
/// same card again months later is another data point, not a correction of
/// the first. So judgements are appended, never rewritten.
class Judgement {
  final int confidence;
  final bool correct;

  const Judgement(this.confidence, {required this.correct});

  Map<String, dynamic> toJson() => {'c': confidence, 'k': correct};

  static Judgement? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final confidence = raw['c'];
    final correct = raw['k'];
    if (confidence is! int || correct is! bool) return null;
    return Judgement(confidence, correct: correct);
  }
}

/// How long a card waits before it comes back, once it has been got right
/// that many times in a row. Past the end of the ladder it retires.
const List<int> kReviewLadder = [2, 7, 21];

/// The confidence levels the app offers. Five is enough to see a pattern
/// without turning every card into a form.
const List<int> kConfidenceLevels = [50, 60, 70, 80, 90];

/// The thing a card is actually training.
///
/// A card is one instance; the principle is what should survive it. This
/// distinction is the whole point: meeting base-rate neglect once, in a
/// medical test, teaches medical tests. Meeting it in hiring, in crime
/// figures and in a sales pitch teaches base rates — and transfer to a
/// context you have not seen is the only outcome worth claiming.
///
/// Evidence: a single interactive debiasing session reduced confirmation
/// bias, the bias blind spot and the fundamental attribution error for
/// 8-12 weeks (Morewedge et al., 2015), and transferred to an unannounced
/// business case months later (Sellier, Scopelliti & Morewedge, 2019).
/// Naming the bias and practising it across varied contexts are the parts
/// that carry.
enum Principle {
  none('', ''),
  baseRate('Base rates', 'How accurate a test is, is not how likely you are'),
  survivorship('Survivorship', 'The data you have is the data that survived'),
  regression('Regression to the mean', 'Extremes drift back on their own'),
  confirmation('Confirmation', 'Looking for a yes is not a test'),
  anchoring('Anchoring', 'The first number said moves every number after'),
  sampling('Sampling', 'Who ended up in the sample decides what it can say'),
  confounding('Confounding', 'Something else may be causing both'),
  counterfactual(
    'Compared to what',
    'A change means nothing without a control',
  ),
  multipleComparisons('Multiple looks', 'Test enough things and one will pass'),
  availability('Availability', 'Easy to picture is not the same as common'),
  sunkCost('Sunk cost', 'Spent is spent; only what is left can be decided'),
  conjunction('Conjunction', 'Detail makes a story likelier and less probable'),
  conditional('Conditional odds', 'What you were told changes the odds'),
  independence('Independence', 'Chance has no memory'),
  coincidence(
    'Coincidence',
    'Rare things are common when there are many tries',
  ),
  exponential('Exponential growth', 'Nobody has intuition for doubling'),
  reflection(
    'The quick answer',
    'The answer that arrives first is the one to check',
  ),
  simpson('Aggregates', 'A whole can lean the way no part of it does'),
  estimation('Estimation', 'Break the unanswerable into things you can guess'),
  computation('Working it out', 'A problem you can actually finish');

  const Principle(this.label, this.oneLine);

  /// What it is called, and the one line that names the move.
  final String label;
  final String oneLine;

  bool get isReal => this != Principle.none;
}

/// How much work a card expects.
enum Difficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard');

  const Difficulty(this.label);
  final String label;
}

class Pill {
  final String id;
  final String topic;
  final Color color;
  final Color ink;
  final Color tint;
  final String question;
  final String answer;
  final String barMove;
  final String source;

  /// What the card asks before it turns over.
  final Challenge challenge;

  /// A nudge that points at the idea without giving the answer away.
  final String hint;

  /// The line naming the trap most people fall into.
  final String trap;

  /// The reasoning, worked through. Shown as numbered steps under the answer
  /// so a long solution stays readable.
  final List<String> steps;

  /// A second way in, for the ideas that genuinely have one — a concrete
  /// image rather than the same explanation with smaller words. Left empty
  /// where the main explanation is already the simplest true version.
  final String simply;

  /// Debate only: the strongest case against whichever side you took.
  final String counterpoint;

  final Difficulty difficulty;

  /// What this card is an instance of. Cards sharing a principle are the
  /// varied contexts that make it stick.
  final Principle principle;

  const Pill({
    required this.id,
    required this.topic,
    required this.color,
    required this.ink,
    required this.tint,
    required this.question,
    required this.answer,
    required this.barMove,
    required this.source,
    this.challenge = const NoChallenge(),
    this.hint = '',
    this.trap = '',
    this.steps = const [],
    this.simply = '',
    this.counterpoint = '',
    this.difficulty = Difficulty.easy,
    this.principle = Principle.none,
  });

  bool get asksSomething => challenge is! NoChallenge;
  bool get hasHint => hint.isNotEmpty;
  bool get hasTrap => trap.isNotEmpty;
  bool get hasSteps => steps.isNotEmpty;
  bool get hasSimply => simply.isNotEmpty;
  bool get hasCounterpoint => counterpoint.isNotEmpty;
  bool get isGraded => challenge.isGraded;

  /// A panel fill that shows up on this card. Tinting with white works on a
  /// saturated card and disappears on a pale one, so follow the ink.
  Color get wash => ink.withValues(alpha: 0.09);

  /// The matching hairline for a panel edge.
  Color get washEdge => ink.withValues(alpha: 0.16);
}
