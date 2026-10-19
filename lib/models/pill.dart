import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import 'diagram.dart';
import 'place.dart';
import 'scene.dart';

export 'diagram.dart';
export 'scene.dart';

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

  /// Reads a kept answer, tolerating spaces and either decimal separator.
  ///
  /// What the reader types is put into plain form by [read] before it is
  /// kept, so this only meets the plain form, and the answers kept before
  /// there was a [read].
  static num? parse(String response) {
    final cleaned = response.trim().replaceAll(' ', '').replaceAll(',', '.');
    return cleaned.isEmpty ? null : num.tryParse(cleaned);
  }

  /// What the reader typed, read the way their language writes numbers,
  /// in the plain form an answer is kept in; null when it is no number.
  ///
  /// "9,455" is nine thousand four hundred and fifty-five in English and
  /// nine point four five five in Italian, which writes the first "9.455".
  /// Reading every comma as a decimal point marked an English reader who
  /// was right as wrong. So the language's own decimal mark is a decimal
  /// mark; the other one groups thousands where three digits follow it,
  /// and is a decimal point where they do not ("0,5" typed anywhere is a
  /// half). A mark written twice, or both marks together, can only mean
  /// one thing. Spaces of any width group thousands, as French does.
  static String? read(String typed, {required String locale}) {
    String s = typed.trim().replaceAll(RegExp(r"[\s'’]"), '');
    String sign = '';
    if (s.startsWith('-') || s.startsWith('−')) {
      sign = '-';
      s = s.substring(1);
    } else if (s.startsWith('+')) {
      s = s.substring(1);
    }
    if (!RegExp(r'^[\d.,]*\d[\d.,]*$').hasMatch(s)) return null;
    final String point = _decimalMark(locale);
    bool grouped(String digits, String mark) =>
        RegExp('^\\d{1,3}(${RegExp.escape(mark)}\\d{3})+\$').hasMatch(digits);

    String whole = s;
    String fraction = '';
    final bool dots = s.contains('.');
    final bool commas = s.contains(',');
    if (dots && commas) {
      // Both: the one written last is the decimal point.
      final String last = s.lastIndexOf('.') > s.lastIndexOf(',') ? '.' : ',';
      final String group = last == '.' ? ',' : '.';
      final List<String> parts = s.split(last);
      if (parts.length != 2 || !grouped(parts[0], group)) return null;
      whole = parts[0].replaceAll(group, '');
      fraction = parts[1];
    } else if (dots || commas) {
      final String mark = dots ? '.' : ',';
      final List<String> parts = s.split(mark);
      if (parts.length > 2) {
        if (!grouped(s, mark)) return null;
        whole = s.replaceAll(mark, '');
      } else if (mark != point &&
          parts[1].length == 3 &&
          parts[0].isNotEmpty &&
          parts[0].length <= 3) {
        whole = parts[0] + parts[1];
      } else {
        whole = parts[0];
        fraction = parts[1];
      }
    }
    if (whole.isEmpty) whole = '0';
    final String plain = fraction.isEmpty
        ? '$sign$whole'
        : '$sign$whole.$fraction';
    return num.tryParse(plain) == null ? null : plain;
  }

  /// The decimal mark [locale] writes: a comma across most of Europe, a
  /// point in English and in Chinese, Japanese and Korean.
  static String _decimalMark(String locale) {
    try {
      return NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
    } catch (_) {
      return '.';
    }
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

/// Asked and marked by the card's own page: a free card (see [WebFace]),
/// whose answer can be anything the page makes of it — a pin dropped on a
/// map, chips stacked on a table, a line drawn — which only the page can
/// tell right from wrong.
///
/// So the page says both, what the reader did and whether it was right,
/// and the two are kept together as the response. The card can then be
/// marked again without its page: on its back, on the journey, when it
/// comes back for review, on a phone that cannot show the page at all.
class PageJudged extends Challenge {
  /// Whether the page says right or wrong. A page that asks for a guess
  /// with nothing right about it is not marked, as a debate is not.
  final bool graded;

  const PageJudged({this.graded = true});

  /// The response a page's answer is kept as: what the reader said, after
  /// `1|` when it was right, `0|` when it was wrong, `-|` when nothing is.
  static String encode(String choice, bool? correct) =>
      '${correct == null ? '-' : (correct ? '1' : '0')}|$choice';

  @override
  bool accepts(String response) => graded && response.startsWith('1|');

  @override
  bool get isGraded => graded;

  @override
  String describe(String response) => response.length > 1 && response[1] == '|'
      ? response.substring(2)
      : response;
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

  /// The card it was made on, and the day it was made, as a date key.
  ///
  /// Both are missing on judgements recorded before the app kept them: a
  /// run of confidences is enough to say how calibrated somebody is, but
  /// not which card they were sure and wrong about, nor whether that was
  /// this week. Everything that reads them treats absent as unknown rather
  /// than as a reason to throw the judgement away.
  final String? pillId;
  final String? on;

  const Judgement(
    this.confidence, {
    required this.correct,
    this.pillId,
    this.on,
  });

  Map<String, dynamic> toJson() => {
    'c': confidence,
    'k': correct,
    if (pillId != null) 'p': pillId,
    if (on != null) 'd': on,
  };

  static Judgement? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final confidence = raw['c'];
    final correct = raw['k'];
    if (confidence is! int || correct is! bool) return null;
    final pill = raw['p'];
    final on = raw['d'];
    return Judgement(
      confidence,
      correct: correct,
      pillId: pill is String ? pill : null,
      on: on is String ? on : null,
    );
  }
}

/// How long a card waits before it comes back, once it has been got right
/// that many times in a row. Past the end of the ladder it retires.
const List<int> kReviewLadder = [2, 7, 21];

/// The confidence levels the app offers. Five is enough to see a pattern
/// without turning every card into a form.
const List<int> kConfidenceLevels = [50, 60, 70, 80, 90];

/// The level [sure] is nearest, for how sure a reader said they were
/// somewhere the app did not draw the five: on a free card's page.
int nearestConfidence(int sure) => kConfidenceLevels.reduce(
  (a, b) => (a - sure).abs() <= (b - sure).abs() ? a : b,
);

/// How far a reader leant to a side of a debate, from 1 to 4, kept as how
/// sure they are of that side on the same scale: a step past the middle is
/// 60, the end of the track 90, the most sure the app lets anyone say they
/// are. The middle itself, 50, is no side at all, so it is never kept.
int leanConfidence(int level) => 50 + 10 * level.clamp(1, 4);

/// The lean a side was taken with, from 1 to 4, or null when it was taken
/// with a button, which says nothing of how far.
int? leanLevel(Answer answer) => switch (answer.confidence) {
  final int c => ((c - 50) / 10).round().clamp(1, 4),
  null => null,
};

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

/// The card kit this build carries (docs/cards/kit, shipped as assets). A
/// page made with a later kit may use what this one does not have, so it is
/// never dealt here; a card that reaches the phone anyway — saved on
/// another one, say — is drawn natively instead.
const int kCardKit = 1;

/// How a free card's page shares the finger with the deck.
enum WebTouch {
  /// Taps go to the page; a drag throws the card, as on any card.
  taps,

  /// The page also takes every touch that starts on the parts it holds the
  /// finger itself — a slider, a canvas to draw on, a game — and the deck
  /// keeps every drag that starts anywhere else.
  drags,
}

/// The face of a free card: a web page made with the card kit, drawn
/// inside the native card frame, where anything at all can be on a card.
///
/// The card keeps everything else a card has — its question, answer, line
/// to keep, source and tags — because search, the widgets, notifications,
/// sharing, the journey and screen readers read those, and because a phone
/// that cannot show the page shows them instead.
class WebFace {
  /// The page, whole. It links the kit as `kit/…` and nothing else; the app
  /// puts the kit, its libraries and its fonts inside it before it is shown
  /// (lib/widgets/web/card_kit.dart).
  final String html;

  /// The version of the kit the page was made with (see [kCardKit]).
  final int kit;

  /// How it shares the finger with the deck.
  final WebTouch touch;

  /// What the face shows and asks, said in words, for a reader who cannot
  /// see it.
  final String label;

  /// The colour the page is drawn on, where it is not its subject's: a
  /// night card, dark with the subject only as an accent. The frame and the
  /// poster under the page take it, so nothing flashes when the page is up.
  final Color? ground;

  const WebFace({
    required this.html,
    this.kit = 1,
    this.touch = WebTouch.taps,
    this.label = '',
    this.ground,
  });

  /// Whether this build carries the kit the page needs.
  bool get showable => kit <= kCardKit;
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

  /// The question the reader takes away and asks of their own life: what
  /// the card is for. Empty on a card not yet given one.
  final String ask;

  /// Whether the back shows both boxes, what to keep and the question to
  /// ask yourself. One box is the rule — the back is a card, not a form, and
  /// two panels of take-aways read as homework — so this is off unless the
  /// card itself opts in, when it truly needs the two.
  final bool both;

  /// Whether the one box the back ends on is the question to ask yourself
  /// rather than what to keep: chosen card by card, for the ending that is
  /// stronger on this card. The line to keep is still the card's, and goes
  /// wherever the card is quoted.
  final bool endsOnAsk;
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

  // ── The tags ──────────────────────────────────────────────────────────
  //
  // What the card is about and like, beyond what it asks — the levers the
  // dealer pulls for one reader and not another. Kept as plain strings
  // rather than enums: the bank is the authority on the vocabulary, and a
  // value this build has not heard of must be dealt, not refused.

  /// The genre under the topic and the strand under the genre, by id
  /// (`space.the_moon`, `space.the_moon.tides`). Empty on a Thinking card.
  final String genre;
  final String strand;

  /// Other strands the card is genuinely about, in any subject: a card on
  /// tides is the Moon and also Gravity. A reader who turned the strand
  /// off and one of these on still meets it.
  final List<String> also;

  /// Three to six lowercase handles for what is in the card.
  final List<String> keywords;

  /// When and where the matter is set.
  final String era;
  final String region;

  /// What pulls the reader in, and the register it is read in.
  final String hook;
  final String mood;

  /// How much number-sense the card asks for, 0 to 3.
  final int numeracy;

  /// A thing you can picture, an idea, or one through the other.
  final String abstraction;

  /// How soon the answer could go stale: evergreen, years, months.
  final String shelfLife;

  /// Sex, drugs, violence, gambling or death in detail.
  final bool mature;

  /// The language the card is written in.
  final String language;

  /// Cards a reader is better off having met first, by id.
  final List<String> buildsOn;

  /// The picture that would help, if one would.
  final String figure;

  /// The picture itself, as data the app draws and animates, when the card
  /// has one (see [Diagram]).
  final Diagram? diagram;

  /// Something to play with before the answer, when the card has one (see
  /// [Scene]).
  final Scene? scene;

  /// Where the card belongs, for a card about a place: a country, a region,
  /// or a city with the reach around it. Such a card is dealt only to the
  /// readers who live there (lib/data/local_cards.dart, docs/PLACES.md) and
  /// never to anybody else, by any road. Null on a card for everybody.
  final CardPlace? place;

  /// The card's face as a web page, on a free card (see [WebFace]): the
  /// page is the front, and the back is the card's own, as on any card.
  final WebFace? web;

  const Pill({
    required this.id,
    required this.topic,
    required this.color,
    required this.ink,
    required this.tint,
    required this.question,
    required this.answer,
    required this.barMove,
    this.ask = '',
    this.both = false,
    this.endsOnAsk = false,
    required this.source,
    this.challenge = const NoChallenge(),
    this.hint = '',
    this.trap = '',
    this.steps = const [],
    this.simply = '',
    this.counterpoint = '',
    this.difficulty = Difficulty.easy,
    this.principle = Principle.none,
    this.genre = '',
    this.strand = '',
    this.also = const [],
    this.keywords = const [],
    this.era = '',
    this.region = '',
    this.hook = '',
    this.mood = '',
    this.numeracy = 0,
    this.abstraction = '',
    this.shelfLife = '',
    this.mature = false,
    this.language = 'en',
    this.buildsOn = const [],
    this.figure = '',
    this.diagram,
    this.scene,
    this.place,
    this.web,
  });

  /// Whether the card carries its tags. Every card in the bank does; a card
  /// built in a test, or from a bundle older than the tags, may not.
  bool get isTagged => era.isNotEmpty;

  /// Every strand the card is dealt under: its own, then the others.
  List<String> get strands => [if (strand.isNotEmpty) strand, ...also];

  /// The tag values a reader can lean towards or away from, as
  /// `dimension:value`, which is how the taste map keys them. A like on a
  /// card nudges every one of these; a card sharing several with what was
  /// liked is dealt sooner.
  List<String> get traits => [
    if (genre.isNotEmpty) 'genre:$genre',
    if (strand.isNotEmpty) 'strand:$strand',
    for (final s in also) 'strand:$s',
    if (era.isNotEmpty) 'era:$era',
    if (region.isNotEmpty && region != 'none') 'region:$region',
    if (hook.isNotEmpty) 'hook:$hook',
    if (mood.isNotEmpty) 'mood:$mood',
    if (isTagged) 'numeracy:$numeracy',
    if (abstraction.isNotEmpty) 'abstraction:$abstraction',
  ];

  /// Whether the card is about a place, and so goes only to the readers who
  /// live there.
  bool get isAboutAPlace => place != null;

  /// Whether the card's face is a page this build can show.
  bool get hasPage => web?.showable ?? false;

  /// Whether the card's page needs a later kit than this build carries: it
  /// is never dealt here (see [kCardKit]).
  bool get needsLaterKit => web != null && !web!.showable;

  bool get asksSomething => challenge is! NoChallenge;
  bool get hasHint => hint.isNotEmpty;
  bool get hasTrap => trap.isNotEmpty;

  /// The boxes the back of the card ends on. What to keep, when the card has
  /// one; the question to ask yourself only in its place, or beside it on a
  /// card marked [both].
  bool get showsMove =>
      barMove.isNotEmpty && (both || !endsOnAsk || ask.isEmpty);
  bool get showsAsk => ask.isNotEmpty && (both || endsOnAsk || barMove.isEmpty);
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
