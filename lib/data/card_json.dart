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

import 'package:flutter/painting.dart' show Color;

import '../models/pill.dart';
import '../models/place.dart';
import 'topics.dart';

/// A card written for a later build than this one: a subject, a kind, a
/// principle, a difficulty or a place this build does not know. The bank
/// can grow any of them without an app update, so a card like this is
/// passed over, and the rest of what came with it kept: the bundle, a
/// served day, a shelf. Anything else wrong with a card is a bad build,
/// and still refuses the whole of what it came in.
class LaterCard extends FormatException {
  const LaterCard(super.message, [super.source]);
}

/// The card in [raw], or null when it was written for a later build (see
/// [LaterCard]). Throws [FormatException] on anything else, as
/// [cardFromJson] does.
Pill? drawableCard(Map<String, Object?> raw) {
  try {
    return cardFromJson(raw);
  } on LaterCard {
    return null;
  }
}

/// The kinds a card can be, as the bank names them. `page` is a free card
/// that asks on its page and is marked there (see [PageJudged]).
const kCardKinds = ['read', 'pickOne', 'number', 'estimate', 'debate', 'page'];

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
  PageJudged() => 'page',
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
    case NoChallenge() || PageJudged():
      break;
  }
  out['answer'] = p.answer;
  out['move'] = p.barMove;
  if (p.ask.isNotEmpty) out['ask'] = p.ask;
  if (p.both) out['both'] = true;
  if (p.endsOnAsk) out['end'] = 'ask';
  if (p.hasTrap) out['trap'] = p.trap;
  if (p.hasHint) out['hint'] = p.hint;
  if (p.hasSteps) out['steps'] = p.steps;
  if (p.hasSimply) out['simply'] = p.simply;
  if (p.hasCounterpoint) out['counterpoint'] = p.counterpoint;
  if (p.genre.isNotEmpty) out['genre'] = p.genre;
  if (p.strand.isNotEmpty) out['strand'] = p.strand;
  if (p.also.isNotEmpty) out['also'] = p.also;
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
  if (p.place != null) out['place'] = p.place!.toJson();
  if (p.buildsOn.isNotEmpty) out['builds_on'] = p.buildsOn;
  if (p.figure.isNotEmpty) out['figure'] = p.figure;
  if (p.diagram != null) out['diagram'] = p.diagram!.raw;
  if (p.scene != null) out['scene'] = p.scene!.raw;
  if (p.web != null) out['web'] = webToJson(p.web!, challenge: p.challenge);
  out['source'] = p.source;
  return out;
}

/// A free card's face as the bundle carries it: the page, inlined by
/// tool/cards/bundle.py from the file kept beside the card, and what the
/// app needs to show it. Whether a page that asks says right or wrong is
/// the challenge's, and is written here because the bank keeps it here.
Map<String, Object?> webToJson(WebFace web, {required Challenge challenge}) => {
  'kit': web.kit,
  'touch': web.touch.name,
  if (challenge is PageJudged && !challenge.graded) 'graded': false,
  if (web.label.isNotEmpty) 'label': web.label,
  if (web.ground case final Color ground) 'ground': colourHex(ground),
  'html': web.html,
};

/// A colour as the bank writes one: `#rrggbb`.
String colourHex(Color c) =>
    '#${(c.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}';

/// A free card's face from its JSON object, or null when the card has none.
/// Throws [FormatException] on a face the app could not draw: no page, a
/// way of touching it this build does not know, a ground that is no colour.
WebFace? webFromJson(Object? raw, {Object? id}) {
  if (raw == null) return null;
  if (raw is! Map) throw FormatException('web is not an object', id);
  final Object? html = raw['html'];
  if (html is! String || html.trim().isEmpty) {
    throw FormatException('a free card carries its page', id);
  }
  final Object? kit = raw['kit'] ?? 1;
  if (kit is! int || kit < 1) throw FormatException('web.kit is a version', id);
  // A page made with a later kit is not shown here at all, so whatever it
  // says about the finger is the later kit's to read, not a fault in it.
  final Object? touch = raw['touch'] ?? 'taps';
  final WebTouch? way = WebTouch.values
      .where((t) => t.name == touch)
      .firstOrNull;
  if (way == null && kit <= kCardKit) {
    throw FormatException('web.touch "$touch" is unknown', id);
  }
  final Object? label = raw['label'] ?? '';
  if (label is! String) throw FormatException('web.label is not text', id);
  final Object? ground = raw['ground'];
  Color? colour;
  if (ground != null) {
    final Match? m = ground is String
        ? RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(ground)
        : null;
    if (m == null) throw FormatException('web.ground is #rrggbb', id);
    colour = Color(0xff000000 | int.parse(m.group(1)!, radix: 16));
  }
  return WebFace(
    html: html,
    kit: kit,
    touch: way ?? WebTouch.taps,
    label: label,
    ground: colour,
  );
}

/// A card from its JSON object. Throws [LaterCard] on a card written for a
/// later build — an unknown topic, kind, principle or difficulty — and
/// [FormatException] on anything else the app could not draw, a missing
/// question, so a bad bundle is refused whole rather than dealt.
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
  if (style == null) throw LaterCard('unknown topic "$topicKey"', id);
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
    'page' => PageJudged(
      graded: raw['web'] is! Map || (raw['web'] as Map)['graded'] != false,
    ),
    _ => throw LaterCard('unknown kind "$kind"', id),
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
    throw LaterCard('unknown difficulty "$difficultyName"', id);
  }
  final principleName = text('principle', fallback: 'none');
  final principle = Principle.values
      .where((p) => p.name == principleName)
      .firstOrNull;
  if (principle == null) {
    throw LaterCard('unknown principle "$principleName"', id);
  }

  // A card marked on its page has to bring the page.
  final WebFace? web = webFromJson(raw['web'], id: id);
  if (challenge is PageJudged && web == null) {
    throw FormatException('a page card has no page', id);
  }

  // A place the app cannot read refuses the card: read as no place, a card
  // about Modena would be dealt to everybody. Passed over, it is dealt to
  // nobody here, as a later build's card is.
  final Object? rawPlace = raw['place'];
  final CardPlace? place = rawPlace == null
      ? null
      : CardPlace.fromJson(rawPlace);
  if (rawPlace != null && place == null) {
    throw LaterCard('a place the app cannot read', id);
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
    ask: text('ask'),
    both: raw['both'] == true,
    endsOnAsk: raw['end'] == 'ask',
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
    also: list('also'),
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
    diagram: Diagram.fromJson(raw['diagram'], id: id),
    scene: Scene.fromJson(raw['scene'], id: id),
    place: place,
    web: web,
  );
}
