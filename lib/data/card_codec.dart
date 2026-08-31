/// The wire form of a card, in both directions.
///
/// Cards are no longer only written in Dart: most of them are now written by
/// the generator on the server, arrive as JSON, and are cached on the phone as
/// JSON. This is the one place that translates, so a change to the shape of a
/// card breaks in one file rather than three.
///
/// Reading is deliberately forgiving in one direction only. A card missing
/// anything that makes it a card — an id, a subject the app has a palette
/// for, a question, an answer — is rejected outright, because a half-card on
/// screen is worse than one card fewer. Everything optional degrades: an
/// unknown tone is no tone, an unreadable challenge is a card that simply
/// tells you something.
library;

import '../models/pill.dart';
import 'topics.dart';

/// Reads one card. Null when the JSON does not describe a usable card.
Pill? cardFromJson(Object? raw) {
  if (raw is! Map) return null;

  String text(Object? v) => v is String ? v.trim() : '';
  List<String> lines(Object? v) => v is List
      ? [
          for (final e in v)
            if (e is String && e.trim().isNotEmpty) e.trim(),
        ]
      : const <String>[];

  final id = text(raw['id']);
  final topicKey = text(raw['topic']);
  final question = text(raw['question']);
  final answer = text(raw['answer']);
  final style = kTopics[topicKey];
  if (id.isEmpty || style == null || question.isEmpty || answer.isEmpty) {
    return null;
  }

  final challenge = Challenge.fromJson(raw['challenge']);

  // A graded card with no explanation is the failure mode this whole
  // pipeline has to guard against: being told you were wrong and not being
  // told why teaches nothing. The server checks it too; this is the second
  // gate, because the cache is written by an older build than the one
  // reading it.
  final steps = lines(raw['steps']);
  if (challenge.isGraded && challenge is! NoChallenge && steps.isEmpty) {
    return null;
  }

  final seconds = raw['seconds'];
  return Pill(
    id: id,
    topicKey: topicKey,
    topic: style.name,
    color: style.color,
    ink: style.ink,
    tint: style.tint,
    question: question,
    answer: answer,
    barMove: text(raw['barMove']),
    source: text(raw['source']),
    challenge: challenge,
    hint: text(raw['hint']),
    trap: text(raw['trap']),
    steps: steps,
    simply: text(raw['simply']),
    counterpoint: text(raw['counterpoint']),
    difficulty: _difficulty(raw['difficulty']),
    principle: _principle(raw['move']),
    tags: lines(raw['tags']),
    tone: Tone.byName(raw['tone']),
    seconds: seconds is int && seconds > 0 ? seconds : 30,
  );
}

/// Writes one card. Only what a reader would notice is missing: the palette
/// comes back from the topic key, so it is not stored.
Map<String, dynamic> cardToJson(Pill p) => {
  'id': p.id,
  'topic': p.topicKey,
  'question': p.question,
  'answer': p.answer,
  if (p.barMove.isNotEmpty) 'barMove': p.barMove,
  if (p.source.isNotEmpty) 'source': p.source,
  'challenge': p.challenge.toJson(),
  if (p.hint.isNotEmpty) 'hint': p.hint,
  if (p.trap.isNotEmpty) 'trap': p.trap,
  if (p.steps.isNotEmpty) 'steps': p.steps,
  if (p.simply.isNotEmpty) 'simply': p.simply,
  if (p.counterpoint.isNotEmpty) 'counterpoint': p.counterpoint,
  'difficulty': p.difficulty.name,
  if (p.principle.isReal) 'move': p.principle.name,
  if (p.tags.isNotEmpty) 'tags': p.tags,
  if (p.tone != null) 'tone': p.tone!.name,
  'seconds': p.seconds,
};

Difficulty _difficulty(Object? raw) {
  for (final d in Difficulty.values) {
    if (d.name == raw) return d;
  }
  return Difficulty.easy;
}

Principle _principle(Object? raw) {
  for (final p in Principle.values) {
    if (p.name == raw) return p;
  }
  return Principle.none;
}
