/// What trains each skill of lib/data/skills.dart, and how far a reader has
/// come in it.
///
/// A card trains a skill when it is in one of the skill's genres (the
/// closest fit), trains one of its reasoning moves, or is about one of its
/// subjects, the way a card counts for an area of life (lib/data/goals.dart).
/// Every card of the bank trains at least one, most of them one to three
/// (test/skill_levels_test.dart keeps both true).
///
/// Every answer on a card that trains a skill moves the reader's score in it
/// (lib/data/skill_scores.dart): What to learn shows each
/// (lib/screens/skills_screen.dart), and a card that trains one of the
/// skills they picked carries that skill's mark in its head
/// (lib/widgets/skill_mark.dart).
library;

import '../models/pill.dart';
import 'pill_bank.dart';
import 'skills.dart';
import 'topics.dart' show topicKeyForName;

/// A skill's genres, moves and subjects.
class _Trains {
  const _Trains(this.genres, this.moves, this.subjects);

  /// Genres of cards about the skill, by id ("life.decisions").
  final Set<String> genres;

  /// The reasoning moves the skill is made of.
  final Set<Principle> moves;

  /// The subjects around the skill, by key ("economics").
  final Set<String> subjects;
}

const Map<Skill, _Trains> _trains = {
  Skill.critical: _Trains(
    {
      'philosophy.arguments',
      'philosophy.paradoxes',
      'philosophy.knowledge',
      'philosophy.big_questions',
      'life.clear_thinking',
      'psychology.bias',
      'psychology.change_your_mind',
      'history.learn_from_the_past',
      'technology.think_about_tech',
      'art.look_closer',
    },
    {
      Principle.confirmation,
      Principle.survivorship,
      Principle.conjunction,
      Principle.counterfactual,
      Principle.reflection,
    },
    {'thinking', 'philosophy'},
  ),
  Skill.decisions: _Trains(
    {
      'life.decisions',
      'life.money_and_time',
      'economics.your_money_decisions',
      'history.decisions_that_changed_history',
      'psychology.think_under_pressure',
      'sport.luck_or_skill',
      'medicine.judge_a_treatment',
      'human_body.your_body_your_choices',
      'food.eat_smarter',
    },
    {Principle.sunkCost, Principle.anchoring, Principle.availability},
    {'life'},
  ),
  Skill.money: _Trains(
    {
      'economics.your_money_decisions',
      'economics.spot_a_bad_deal',
      'economics.money_and_banks',
      'economics.everyday_costs',
      'economics.read_money_news',
      'economics.pricing_tricks',
      'economics.crises',
      'economics.markets_and_hype',
      'life.money_and_time',
    },
    {Principle.exponential},
    {'economics'},
  ),
  Skill.numbers: _Trains(
    {
      'maths.statistics',
      'maths.estimation',
      'maths.everyday_maths',
      'maths.growth',
      'science.numbers_and_chance',
      'science.maths_curios',
      'science.read_a_study',
      'sport.sport_and_numbers',
      'human_body.your_body_in_numbers',
      'weird_facts.numbers_that_surprise',
      'space.think_at_scale',
    },
    {
      Principle.baseRate,
      Principle.regression,
      Principle.sampling,
      Principle.multipleComparisons,
      Principle.conditional,
      Principle.independence,
      Principle.coincidence,
      Principle.exponential,
      Principle.simpson,
      Principle.estimation,
      Principle.computation,
    },
    {'maths'},
  ),
  Skill.talk: _Trains(
    {
      'life.ask_better_questions',
      'life.relationships',
      'language.words_that_persuade',
      'language.untranslatable_words',
      'language.slang',
      'language.accents',
      'language.grammar_oddities',
      'language.word_origins',
      'language.writing_systems',
      'medicine.talk_to_your_doctor',
      'philosophy.arguments',
    },
    {},
    {'language'},
  ),
  Skill.persuade: _Trains(
    {
      'language.words_that_persuade',
      'psychology.resist_persuasion',
      'cinema.how_films_persuade',
      'economics.pricing_tricks',
      'economics.markets_and_hype',
      'pop_culture.logos_and_brands',
      'pop_culture.behind_the_hype',
      'pop_culture.why_stories_grip_us',
      'history.propaganda',
      'music.why_songs_work',
      'art.what_makes_it_valuable',
    },
    {Principle.anchoring},
    {},
  ),
  Skill.people: _Trains(
    {
      'life.people',
      'life.relationships',
      'psychology.other_people',
      'psychology.emotions',
      'psychology.motivation',
      'psychology.happiness_research',
      'history.ordinary_people',
      'history.everyday_life',
      'economics.think_in_incentives',
      'philosophy.ethics',
      'philosophy.living_well',
      'music.why_we_like_what_we_like',
      'pop_culture.fame',
    },
    {},
    {'psychology'},
  ),
  Skill.fakes: _Trains(
    {
      'science.spot_bad_science',
      'science.read_a_study',
      'medicine.medical_myths',
      'human_body.health_claims',
      'food.food_claims',
      'nature.nature_myths',
      'technology.truth_online',
      'weird_facts.too_strange_to_be_true',
      'weird_facts.coincidences',
      'art.forgeries',
      'pop_culture.social_media',
      'pop_culture.internet_culture',
      'economics.read_money_news',
      'history.propaganda',
      'cinema.watch_smarter',
    },
    {
      Principle.confirmation,
      Principle.coincidence,
      Principle.multipleComparisons,
      Principle.survivorship,
    },
    {},
  ),
  Skill.science: _Trains(
    {
      'science.how_science_knows',
      'science.think_like_a_scientist',
      'science.read_a_study',
      'science.spot_bad_science',
      'medicine.judge_a_treatment',
      'medicine.diagnosis',
      'medicine.vaccines',
      'medicine.public_health',
      'nature.evolution',
      'nature.systems_thinking',
      'nature.climate',
      'space.questions_with_no_answer_yet',
      'space.are_we_alone',
      'food.cooking_science',
    },
    {
      Principle.confounding,
      Principle.sampling,
      Principle.baseRate,
      Principle.regression,
      Principle.counterfactual,
      Principle.simpson,
    },
    {'science', 'nature', 'space', 'medicine', 'human_body', 'technology'},
  ),
  Skill.focus: _Trains(
    {
      'psychology.attention',
      'psychology.habits',
      'psychology.memory',
      'psychology.sleep_and_dreams',
      'psychology.know_your_own_mind',
      'life.time_and_attention',
      'life.habits',
      'life.learn_anything',
      'life.growth',
      'life.handle_setbacks',
      'human_body.the_brain',
      'human_body.stress_and_the_body',
      'music.music_and_the_brain',
      'technology.your_digital_life',
      'sport.the_mind_in_sport',
      'sport.training',
    },
    {},
    {},
  ),
  Skill.lead: _Trains(
    {
      'life.work_and_career',
      'history.decisions_that_changed_history',
      'history.revolutions',
      'history.empires',
      'sport.tactics',
      'sport.sport_and_society',
      'economics.think_in_incentives',
      'economics.work_and_wages',
      'economics.how_countries_get_rich',
      'economics.inequality',
      'philosophy.justice',
      'art.art_and_power',
      'technology.tech_and_society',
      'music.the_music_business',
    },
    {Principle.sunkCost},
    {},
  ),
  Skill.culture: _Trains({}, {}, {
    'history',
    'art',
    'cinema',
    'music',
    'food',
    'sport',
    'pop_culture',
    'language',
    'weird_facts',
    'philosophy',
  }),
};

/// The subject key of [p], as its topic names it ("Science" or "science").
String _subjectOf(Pill p) => topicKeyForName(p.topic) ?? p.topic;

/// How a card trains a skill.
extension SkillTraining on Skill {
  /// How closely [p] trains the skill: 0 in one of its genres, 1 training
  /// one of its moves, 2 about one of its subjects, null not at all.
  int? fitOf(Pill p) => _fit(this, p, _subjectOf(p));

  /// Whether [p] trains the skill.
  bool trains(Pill p) => fitOf(p) != null;

  /// The genres, moves and subjects the skill is trained by.
  Set<String> get genres => _trains[this]!.genres;
  Set<Principle> get moves => _trains[this]!.moves;
  Set<String> get subjects => _trains[this]!.subjects;
}

int? _fit(Skill s, Pill p, String subject) {
  final _Trains t = _trains[s]!;
  if (t.genres.contains(p.genre)) return 0;
  if (t.moves.contains(p.principle)) return 1;
  if (t.subjects.contains(subject)) return 2;
  return null;
}

/// The skill among [picked] (skill keys, as AppState.skills keeps them)
/// that [p] trains most closely, of two as close the first in What to
/// learn's order; null when it trains none of them.
Skill? skillMarkOf(Pill p, Iterable<String> picked) {
  final Set<String> keys = picked.toSet();
  if (keys.isEmpty) return null;
  final String subject = _subjectOf(p);
  Skill? best;
  int bestFit = 3;
  for (final Skill s in Skill.values) {
    if (!keys.contains(s.name)) continue;
    final int? fit = _fit(s, p, subject);
    if (fit != null && fit < bestFit) {
      best = s;
      bestFit = fit;
    }
  }
  return best;
}

/// How many of the cards [ids] train each skill. A card the bank no longer
/// has counts for none.
Map<Skill, int> cardsTrainingEach(Iterable<String> ids) {
  final Map<Skill, int> n = {for (final Skill s in Skill.values) s: 0};
  for (final String id in ids) {
    final Pill? p = PillBank.byId(id);
    if (p == null) continue;
    final String subject = _subjectOf(p);
    for (final Skill s in Skill.values) {
      if (_fit(s, p, subject) != null) n[s] = n[s]! + 1;
    }
  }
  return n;
}
