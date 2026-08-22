import 'package:flutter/material.dart';

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
  });
}
