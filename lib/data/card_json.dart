/// A card on disk: the shape every card takes outside the app.
///
/// The bank lives as one JSON file per card under `tool/cards/bank/`, is
/// written there by the generator and read back by a person reviewing the
/// pull request, and reaches the app twice — baked in as the embedded bank
/// and downloaded as `cards.json`. So this is the one place the field names
/// are decided, and the round trip is a test: a card that comes back
/// different from the one that went out is a bug here, not in the bank.
///
/// The colours are not stored. A card carries its topic *key* (`space`, not
/// `Space`) and the app looks the palette up, so a redesign never touches
/// two thousand files.
library;

import '../models/pill.dart';
import 'topics.dart';

/// The kinds a card can be, as the bank names them.
const kCardKinds = ['read', 'pickOne', 'number', 'estimate', 'debate'];

/// The topic key for a card, from the display name the model carries.
String topicKeyOf(String topicName) {
  for (final e in kTopics.entries) {
    if (e.value.name == topicName) return e.key;
  }
  throw FormatException('no topic is called "$topicName"');
}

/// The kind name of a challenge, as the bank writes it.
String kindOf(Challenge c) => switch (c) {
  NoChallenge() => 'read',
  PickOne() => 'pickOne',
  TypeNumber() => 'number',
  Estimate() => 'estimate',
  TakeASide() => 'debate',
};

/// The card as a JSON object. Optional fields are written only when set,
/// so a file in the bank shows what a card has rather than what it could.
Map<String, Object?> cardToJson(Pill p) {
  final out = <String, Object?>{
    'id': p.id,
    'topic': topicKeyOf(p.topic),
    'kind': kindOf(p.challenge),
    'difficulty': p.difficulty.name,
    'principle': p.principle.name,
    'question': p.question,
  };
  switch (p.challenge) {
    case PickOne(:final options, :final correct):
      out['options'] = options;
      out['correct'] = correct;
    case TypeNumber(:final answer, :final unit, :final tolerance):
      out['value'] = answer;
      out['unit'] = unit;
      if (tolerance != 0) out['tolerance'] = tolerance;
    case Estimate(:final answer, :final unit, :final withinFactor):
      out['value'] = answer;
      out['unit'] = unit;
      out['withinFactor'] = withinFactor;
    case TakeASide(:final positions):
      out['sides'] = positions;
    case NoChallenge():
      break;
  }
  out['answer'] = p.answer;
  out['move'] = p.barMove;
  if (p.hasTrap) out['trap'] = p.trap;
  if (p.hasHint) out['hint'] = p.hint;
  if (p.hasSteps) out['steps'] = p.steps;
  if (p.hasSimply) out['simply'] = p.simply;
  if (p.hasCounterpoint) out['counterpoint'] = p.counterpoint;
  if (p.genre.isNotEmpty) out['genre'] = p.genre;
  if (p.strand.isNotEmpty) out['strand'] = p.strand;
  if (p.isTagged) {
    out['keywords'] = p.keywords;
    out['era'] = p.era;
    out['region'] = p.region;
    out['hook'] = p.hook;
    out['mood'] = p.mood;
    out['numeracy'] = p.numeracy;
    out['abstraction'] = p.abstraction;
    out['shelf_life'] = p.shelfLife;
    out['mature'] = p.mature;
    out['language'] = p.language;
  }
  if (p.buildsOn.isNotEmpty) out['builds_on'] = p.buildsOn;
  if (p.figure.isNotEmpty) out['figure'] = p.figure;
  out['source'] = p.source;
  return out;
}

/// A card from its JSON object. Throws [FormatException] on anything the
/// app could not draw — an unknown topic, kind, principle or difficulty, a
/// missing question — so a bad bundle is refused whole rather than dealt.
Pill cardFromJson(Map<String, Object?> raw) {
  String text(String key, {String fallback = ''}) {
    final v = raw[key];
    if (v == null) return fallback;
    if (v is! String) throw FormatException('$key is not text', raw['id']);
    return v;
  }

  List<String> list(String key) {
    final v = raw[key];
    if (v == null) return const [];
    if (v is! List) throw FormatException('$key is not a list', raw['id']);
    return v.map((e) => e.toString()).toList();
  }

  num number(String key, {num? fallback}) {
    final v = raw[key] ?? fallback;
    if (v is! num) throw FormatException('$key is not a number', raw['id']);
    return v;
  }

  final id = text('id');
  if (id.isEmpty) throw const FormatException('a card has no id');
  final topicKey = text('topic');
  final style = kTopics[topicKey];
  if (style == null) throw FormatException('unknown topic "$topicKey"', id);
  final question = text('question');
  if (question.isEmpty) throw FormatException('no question', id);

  final kind = text('kind', fallback: 'read');
  final Challenge challenge = switch (kind) {
    'read' => const NoChallenge(),
    'pickOne' => PickOne(
      options: list('options'),
      correct: number('correct').toInt(),
    ),
    'number' => TypeNumber(
      answer: number('value'),
      unit: text('unit'),
      tolerance: number('tolerance', fallback: 0),
    ),
    'estimate' => Estimate(
      answer: number('value'),
      unit: text('unit'),
      withinFactor: number('withinFactor', fallback: 3),
    ),
    'debate' => TakeASide(positions: list('sides')),
    _ => throw FormatException('unknown kind "$kind"', id),
  };
  if (challenge is PickOne &&
      (challenge.options.length < 2 ||
          challenge.correct < 0 ||
          challenge.correct >= challenge.options.length)) {
    throw FormatException('the options do not hold the answer', id);
  }
  if (challenge is TakeASide && challenge.positions.length != 2) {
    throw FormatException('a debate has two sides', id);
  }

  final difficultyName = text('difficulty', fallback: 'easy');
  final difficulty = Difficulty.values
      .where((d) => d.name == difficultyName)
      .firstOrNull;
  if (difficulty == null) {
    throw FormatException('unknown difficulty "$difficultyName"', id);
  }
  final principleName = text('principle', fallback: 'none');
  final principle = Principle.values
      .where((p) => p.name == principleName)
      .firstOrNull;
  if (principle == null) {
    throw FormatException('unknown principle "$principleName"', id);
  }

  return Pill(
    id: id,
    topic: style.name,
    color: style.color,
    ink: style.ink,
    tint: style.tint,
    question: question,
    answer: text('answer'),
    barMove: text('move'),
    source: text('source'),
    challenge: challenge,
    hint: text('hint'),
    trap: text('trap'),
    steps: list('steps'),
    simply: text('simply'),
    counterpoint: text('counterpoint'),
    difficulty: difficulty,
    principle: principle,
    genre: text('genre'),
    strand: text('strand'),
    keywords: list('keywords'),
    era: text('era'),
    region: text('region'),
    hook: text('hook'),
    mood: text('mood'),
    numeracy: number('numeracy', fallback: 0).toInt(),
    abstraction: text('abstraction'),
    shelfLife: text('shelf_life'),
    mature: raw['mature'] == true,
    language: text('language', fallback: 'en'),
    buildsOn: list('builds_on'),
    figure: text('figure'),
  );
}
