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

  /// How the reader's own answer should read back to them on the reveal.
  String describe(String response) => response;
}

/// Nothing to answer. Turn it over and read.
class NoChallenge extends Challenge {
  const NoChallenge();

  @override
  bool accepts(String response) => false;
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

  final Difficulty difficulty;

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
    this.difficulty = Difficulty.easy,
  });

  bool get asksSomething => challenge is! NoChallenge;
  bool get hasHint => hint.isNotEmpty;
  bool get hasSteps => steps.isNotEmpty;

  /// A panel fill that shows up on this card. Tinting with white works on a
  /// saturated card and disappears on a pale one, so follow the ink.
  Color get wash => ink.withValues(alpha: 0.09);

  /// The matching hairline for a panel edge.
  Color get washEdge => ink.withValues(alpha: 0.16);
}
