import 'package:flutter/material.dart';

/// What a card asks of the reader.
enum PillKind {
  /// Read the question, turn it over, learn the answer.
  fact,

  /// Commit to an answer *before* turning it over. Being wrong on purpose is
  /// the part that teaches — reading the explanation cold does not.
  puzzle,
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

  final PillKind kind;

  /// Puzzle only: the options, in display order.
  final List<String> choices;

  /// Puzzle only: index into [choices]. -1 on a fact.
  final int correctIndex;

  /// Puzzle only: the one line that names the trap most people fall into.
  final String trap;

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
    this.kind = PillKind.fact,
    this.choices = const [],
    this.correctIndex = -1,
    this.trap = '',
  });

  bool get isPuzzle => kind == PillKind.puzzle;

  /// A panel fill that shows up on this card. Tinting with white works on a
  /// saturated card and disappears on a pale one, so follow the ink.
  Color get wash => ink.withValues(alpha: 0.09);

  /// The matching hairline for a panel edge.
  Color get washEdge => ink.withValues(alpha: 0.16);

  String get correctChoice => correctIndex >= 0 && correctIndex < choices.length
      ? choices[correctIndex]
      : '';
}
