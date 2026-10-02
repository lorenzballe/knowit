/// The subjects, one layer down — and one layer down from that.
///
/// A subject is too coarse to pick with. Two readers both ask for Space and
/// one of them means rockets and the other means how big the thing is; the
/// mix wheel cannot tell them apart, and a day dealt from "Space" serves
/// neither. So every subject carries six *genres*, and every genre three
/// *strands* under it — what a reader would actually name if you asked them
/// what they wanted to read about.
///
/// In English, like the cards. These are the names of things to write about
/// rather than words the app says for itself: the chrome around them is
/// translated thirteen ways, and a genre is content.
///
/// Every card in the bank carries one strand (`Pill.strand`), and the dealer
/// puts a card from a genre or strand turned off here behind every card that
/// is on. The generator reads this same file — `tool/cards/genres.py` parses
/// it — and writes towards the strands with the fewest cards, so what a
/// reader turns on has something under it as soon as the bank can manage.
library;

/// One of the three strands inside a genre.
class Strand {
  /// Stable, and built from the name once rather than typed twice.
  final String id;
  final String label;

  const Strand(this.id, this.label);
}

/// One of the six genres inside a subject.
class Genre {
  final String id;
  final String label;
  final List<Strand> strands;

  const Genre(this.id, this.label, this.strands);
}

/// Every subject's six, by topic key. Thinking is not here: it is not a
/// subject, it is never off the deck, and it is not on the mix wheel either.
const Map<String, List<Genre>> kGenres = {
  'science': [
    Genre('science.physics', 'Physics', [
      Strand('science.physics.gravity', 'Gravity'),
      Strand('science.physics.quantum', 'Quantum'),
      Strand('science.physics.relativity', 'Relativity'),
      Strand('science.physics.energy', 'Energy'),
      Strand('science.physics.why_things_fall', 'Why things fall'),
    ]),
    Genre('science.chemistry_at_home', 'Chemistry at home', [
      Strand('science.chemistry_at_home.cleaning', 'Cleaning'),
      Strand(
        'science.chemistry_at_home.cooking_reactions',
        'Cooking reactions',
      ),
      Strand('science.chemistry_at_home.rust', 'Rust'),
      Strand('science.chemistry_at_home.mixing_cleaners', 'Mixing cleaners'),
      Strand('science.chemistry_at_home.kitchen_myths', 'Kitchen myths'),
    ]),
    Genre('science.light_and_colour', 'Light and colour', [
      Strand('science.light_and_colour.rainbows', 'Rainbows'),
      Strand('science.light_and_colour.pigments', 'Pigments'),
      Strand('science.light_and_colour.lasers', 'Lasers'),
      Strand(
        'science.light_and_colour.how_eyes_see_colour',
        'How eyes see colour',
      ),
      Strand('science.light_and_colour.optical_illusions', 'Optical illusions'),
    ]),
    Genre('science.cold_and_heat', 'Cold and heat', [
      Strand('science.cold_and_heat.absolute_zero', 'Absolute zero'),
      Strand('science.cold_and_heat.insulation', 'Insulation'),
      Strand('science.cold_and_heat.fire', 'Fire'),
      Strand('science.cold_and_heat.why_ice_floats', 'Why ice floats'),
      Strand('science.cold_and_heat.cold_myths', 'Cold myths'),
    ]),
    Genre('science.maths_curios', 'Maths curios', [
      Strand('science.maths_curios.infinity', 'Infinity'),
      Strand('science.maths_curios.primes', 'Primes'),
      Strand('science.maths_curios.probability', 'Probability'),
      Strand('science.maths_curios.exponential_growth', 'Exponential growth'),
      Strand('science.maths_curios.averages', 'Averages'),
    ]),
    Genre('science.materials', 'Materials', [
      Strand('science.materials.glass', 'Glass'),
      Strand('science.materials.steel', 'Steel'),
      Strand('science.materials.plastics', 'Plastics'),
      Strand('science.materials.why_things_break', 'Why things break'),
      Strand('science.materials.recycling_claims', 'Recycling claims'),
    ]),
    Genre('science.how_science_knows', 'How science knows', [
      Strand('science.how_science_knows.experiments', 'Experiments'),
      Strand(
        'science.how_science_knows.correlation_or_cause',
        'Correlation or cause',
      ),
      Strand('science.how_science_knows.replication', 'Replication'),
      Strand('science.how_science_knows.peer_review', 'Peer review'),
      Strand(
        'science.how_science_knows.theories_and_laws',
        'Theories and laws',
      ),
    ]),
    Genre('science.read_a_study', 'Read a study', [
      Strand('science.read_a_study.sample_size', 'Sample size'),
      Strand(
        'science.read_a_study.relative_or_absolute',
        'Relative or absolute',
      ),
      Strand(
        'science.read_a_study.headlines_and_papers',
        'Headlines and papers',
      ),
      Strand('science.read_a_study.who_funded_it', 'Who funded it'),
      Strand('science.read_a_study.control_groups', 'Control groups'),
    ]),
    Genre('science.numbers_and_chance', 'Numbers and chance', [
      Strand('science.numbers_and_chance.base_rates', 'Base rates'),
      Strand('science.numbers_and_chance.coincidences', 'Coincidences'),
      Strand('science.numbers_and_chance.big_numbers', 'Big numbers'),
      Strand('science.numbers_and_chance.estimating', 'Estimating'),
      Strand('science.numbers_and_chance.risk_in_numbers', 'Risk in numbers'),
    ]),
    Genre('science.spot_bad_science', 'Spot bad science', [
      Strand('science.spot_bad_science.pseudoscience', 'Pseudoscience'),
      Strand(
        'science.spot_bad_science.too_good_to_be_true',
        'Too good to be true',
      ),
      Strand('science.spot_bad_science.quantum_nonsense', 'Quantum nonsense'),
      Strand('science.spot_bad_science.cherry_picking', 'Cherry-picking'),
      Strand('science.spot_bad_science.experts_disagree', 'Experts disagree'),
    ]),
    Genre('science.think_like_a_scientist', 'Think like a scientist', [
      Strand(
        'science.think_like_a_scientist.testable_claims',
        'Testable claims',
      ),
      Strand('science.think_like_a_scientist.falsification', 'Falsification'),
      Strand('science.think_like_a_scientist.occams_razor', 'Occams razor'),
      Strand('science.think_like_a_scientist.uncertainty', 'Uncertainty'),
      Strand('science.think_like_a_scientist.being_wrong', 'Being wrong'),
    ]),
  ],
  'space': [
    Genre('space.black_holes', 'Black holes', [
      Strand('space.black_holes.event_horizons', 'Event horizons'),
      Strand('space.black_holes.supermassive_ones', 'Supermassive ones'),
      Strand('space.black_holes.hawking_radiation', 'Hawking radiation'),
      Strand('space.black_holes.what_we_can_see', 'What we can see'),
      Strand('space.black_holes.myths_about_them', 'Myths about them'),
    ]),
    Genre('space.the_moon', 'The Moon', [
      Strand('space.the_moon.tides', 'Tides'),
      Strand('space.the_moon.landing_sites', 'Landing sites'),
      Strand('space.the_moon.moon_dust', 'Moon dust'),
      Strand('space.the_moon.moon_landing_doubts', 'Moon landing doubts'),
      Strand('space.the_moon.moon_and_sleep', 'Moon and sleep'),
    ]),
    Genre('space.mars_and_rovers', 'Mars and rovers', [
      Strand('space.mars_and_rovers.perseverance', 'Perseverance'),
      Strand('space.mars_and_rovers.martian_weather', 'Martian weather'),
      Strand('space.mars_and_rovers.water_on_mars', 'Water on Mars'),
      Strand('space.mars_and_rovers.living_on_mars', 'Living on Mars'),
      Strand('space.mars_and_rovers.why_go', 'Why go'),
    ]),
    Genre('space.stars_and_light', 'Stars and light', [
      Strand('space.stars_and_light.star_death', 'Star death'),
      Strand('space.stars_and_light.light_years', 'Light years'),
      Strand('space.stars_and_light.colours_of_stars', 'Colours of stars'),
      Strand(
        'space.stars_and_light.looking_back_in_time',
        'Looking back in time',
      ),
      Strand(
        'space.stars_and_light.astrology_or_astronomy',
        'Astrology or astronomy',
      ),
    ]),
    Genre('space.rockets', 'Rockets', [
      Strand('space.rockets.reusable_boosters', 'Reusable boosters'),
      Strand('space.rockets.fuel_chemistry', 'Fuel chemistry'),
      Strand('space.rockets.launch_windows', 'Launch windows'),
      Strand('space.rockets.cost_of_space', 'Cost of space'),
      Strand('space.rockets.space_junk', 'Space junk'),
    ]),
    Genre('space.edge_of_the_universe', 'Edge of the universe', [
      Strand('space.edge_of_the_universe.expansion', 'Expansion'),
      Strand('space.edge_of_the_universe.dark_matter', 'Dark matter'),
      Strand(
        'space.edge_of_the_universe.cosmic_background',
        'Cosmic background',
      ),
      Strand(
        'space.edge_of_the_universe.what_we_do_not_know',
        'What we do not know',
      ),
      Strand('space.edge_of_the_universe.big_bang', 'Big Bang'),
    ]),
    Genre('space.think_at_scale', 'Think at scale', [
      Strand('space.think_at_scale.sizes', 'Sizes'),
      Strand('space.think_at_scale.distances', 'Distances'),
      Strand('space.think_at_scale.deep_time', 'Deep time'),
      Strand('space.think_at_scale.tiny_and_huge', 'Tiny and huge'),
      Strand('space.think_at_scale.odds_of_life', 'Odds of life'),
    ]),
    Genre('space.are_we_alone', 'Are we alone', [
      Strand('space.are_we_alone.fermi_paradox', 'Fermi paradox'),
      Strand('space.are_we_alone.evidence_and_hope', 'Evidence and hope'),
      Strand('space.are_we_alone.extraordinary_claims', 'Extraordinary claims'),
      Strand('space.are_we_alone.ufo_claims', 'UFO claims'),
      Strand('space.are_we_alone.signals', 'Signals'),
    ]),
    Genre('space.space_and_life_on_earth', 'Space and life on Earth', [
      Strand('space.space_and_life_on_earth.satellites', 'Satellites'),
      Strand('space.space_and_life_on_earth.gps', 'GPS'),
      Strand('space.space_and_life_on_earth.spinoffs', 'Spinoffs'),
      Strand('space.space_and_life_on_earth.asteroid_risk', 'Asteroid risk'),
      Strand(
        'space.space_and_life_on_earth.earth_from_above',
        'Earth from above',
      ),
    ]),
    Genre(
      'space.questions_with_no_answer_yet',
      'Questions with no answer yet',
      [
        Strand('space.questions_with_no_answer_yet.dark_energy', 'Dark energy'),
        Strand(
          'space.questions_with_no_answer_yet.before_the_big_bang',
          'Before the Big Bang',
        ),
        Strand('space.questions_with_no_answer_yet.multiverse', 'Multiverse'),
        Strand(
          'space.questions_with_no_answer_yet.life_elsewhere',
          'Life elsewhere',
        ),
        Strand(
          'space.questions_with_no_answer_yet.the_end_of_everything',
          'The end of everything',
        ),
      ],
    ),
  ],
  'psychology': [
    Genre('psychology.memory', 'Memory', [
      Strand('psychology.memory.forgetting_curve', 'Forgetting curve'),
      Strand('psychology.memory.false_memories', 'False memories'),
      Strand('psychology.memory.mnemonics', 'Mnemonics'),
      Strand('psychology.memory.memory_and_stress', 'Memory and stress'),
      Strand('psychology.memory.remembering_better', 'Remembering better'),
    ]),
    Genre('psychology.attention', 'Attention', [
      Strand('psychology.attention.focus', 'Focus'),
      Strand('psychology.attention.distraction', 'Distraction'),
      Strand('psychology.attention.flow', 'Flow'),
      Strand('psychology.attention.multitasking', 'Multitasking'),
      Strand('psychology.attention.phones_and_focus', 'Phones and focus'),
    ]),
    Genre('psychology.habits', 'Habits', [
      Strand('psychology.habits.cues', 'Cues'),
      Strand('psychology.habits.streaks', 'Streaks'),
      Strand('psychology.habits.breaking_them', 'Breaking them'),
      Strand('psychology.habits.tiny_habits', 'Tiny habits'),
      Strand('psychology.habits.environment_design', 'Environment design'),
    ]),
    Genre('psychology.emotions', 'Emotions', [
      Strand('psychology.emotions.fear', 'Fear'),
      Strand('psychology.emotions.joy', 'Joy'),
      Strand('psychology.emotions.why_we_cry', 'Why we cry'),
      Strand('psychology.emotions.anger', 'Anger'),
      Strand('psychology.emotions.naming_feelings', 'Naming feelings'),
    ]),
    Genre('psychology.bias', 'Bias', [
      Strand('psychology.bias.confirmation', 'Confirmation'),
      Strand('psychology.bias.sunk_cost', 'Sunk cost'),
      Strand('psychology.bias.halo_effect', 'Halo effect'),
      Strand('psychology.bias.anchoring_bias', 'Anchoring bias'),
      Strand('psychology.bias.availability', 'Availability'),
    ]),
    Genre('psychology.sleep_and_dreams', 'Sleep and dreams', [
      Strand('psychology.sleep_and_dreams.sleep_stages', 'Sleep stages'),
      Strand('psychology.sleep_and_dreams.why_we_dream', 'Why we dream'),
      Strand('psychology.sleep_and_dreams.insomnia', 'Insomnia'),
      Strand('psychology.sleep_and_dreams.sleep_debt', 'Sleep debt'),
      Strand('psychology.sleep_and_dreams.naps', 'Naps'),
    ]),
    Genre('psychology.know_your_own_mind', 'Know your own mind', [
      Strand('psychology.know_your_own_mind.overconfidence', 'Overconfidence'),
      Strand('psychology.know_your_own_mind.hindsight', 'Hindsight'),
      Strand('psychology.know_your_own_mind.blind_spots', 'Blind spots'),
      Strand('psychology.know_your_own_mind.self_deception', 'Self-deception'),
      Strand(
        'psychology.know_your_own_mind.mood_and_memory',
        'Mood and memory',
      ),
    ]),
    Genre('psychology.resist_persuasion', 'Resist persuasion', [
      Strand('psychology.resist_persuasion.social_proof', 'Social proof'),
      Strand('psychology.resist_persuasion.scarcity_tricks', 'Scarcity tricks'),
      Strand('psychology.resist_persuasion.authority', 'Authority'),
      Strand('psychology.resist_persuasion.framing', 'Framing'),
      Strand('psychology.resist_persuasion.reciprocity', 'Reciprocity'),
    ]),
    Genre('psychology.think_under_pressure', 'Think under pressure', [
      Strand(
        'psychology.think_under_pressure.stress_and_choices',
        'Stress and choices',
      ),
      Strand('psychology.think_under_pressure.fast_and_slow', 'Fast and slow'),
      Strand('psychology.think_under_pressure.gut_feelings', 'Gut feelings'),
      Strand(
        'psychology.think_under_pressure.decision_fatigue',
        'Decision fatigue',
      ),
      Strand('psychology.think_under_pressure.panic', 'Panic'),
    ]),
    Genre('psychology.change_your_mind', 'Change your mind', [
      Strand('psychology.change_your_mind.being_wrong', 'Being wrong'),
      Strand('psychology.change_your_mind.backfire', 'Backfire'),
      Strand(
        'psychology.change_your_mind.updating_beliefs',
        'Updating beliefs',
      ),
      Strand('psychology.change_your_mind.steelmanning', 'Steelmanning'),
      Strand(
        'psychology.change_your_mind.identity_and_beliefs',
        'Identity and beliefs',
      ),
    ]),
    Genre('psychology.motivation', 'Motivation', [
      Strand('psychology.motivation.procrastination', 'Procrastination'),
      Strand('psychology.motivation.willpower_myths', 'Willpower myths'),
      Strand('psychology.motivation.goals_that_work', 'Goals that work'),
      Strand('psychology.motivation.rewards', 'Rewards'),
      Strand('psychology.motivation.comparison', 'Comparison'),
    ]),
    Genre('psychology.other_people', 'Other people', [
      Strand('psychology.other_people.first_impressions', 'First impressions'),
      Strand('psychology.other_people.empathy', 'Empathy'),
      Strand('psychology.other_people.conformity', 'Conformity'),
      Strand('psychology.other_people.group_thinking', 'Group thinking'),
      Strand('psychology.other_people.reading_faces', 'Reading faces'),
    ]),
    Genre('psychology.happiness_research', 'Happiness research', [
      Strand(
        'psychology.happiness_research.money_and_happiness',
        'Money and happiness',
      ),
      Strand('psychology.happiness_research.adaptation', 'Adaptation'),
      Strand('psychology.happiness_research.gratitude', 'Gratitude'),
      Strand(
        'psychology.happiness_research.friends_and_health',
        'Friends and health',
      ),
      Strand('psychology.happiness_research.expectations', 'Expectations'),
    ]),
  ],
  'economics': [
    Genre('economics.pricing_tricks', 'Pricing tricks', [
      Strand('economics.pricing_tricks.anchoring', 'Anchoring'),
      Strand('economics.pricing_tricks.charm_prices', 'Charm prices'),
      Strand('economics.pricing_tricks.decoy_options', 'Decoy options'),
      Strand('economics.pricing_tricks.bundles', 'Bundles'),
      Strand('economics.pricing_tricks.dynamic_pricing', 'Dynamic pricing'),
    ]),
    Genre('economics.money_and_banks', 'Money and banks', [
      Strand('economics.money_and_banks.printing_cash', 'Printing cash'),
      Strand('economics.money_and_banks.interest', 'Interest'),
      Strand('economics.money_and_banks.digital_money', 'Digital money'),
      Strand('economics.money_and_banks.inflation', 'Inflation'),
      Strand('economics.money_and_banks.debt', 'Debt'),
    ]),
    Genre('economics.work_and_wages', 'Work and wages', [
      Strand('economics.work_and_wages.minimum_wage', 'Minimum wage'),
      Strand('economics.work_and_wages.gig_work', 'Gig work'),
      Strand('economics.work_and_wages.four_day_week', 'Four-day week'),
      Strand('economics.work_and_wages.automation', 'Automation'),
      Strand('economics.work_and_wages.why_pay_differs', 'Why pay differs'),
    ]),
    Genre('economics.trade_routes', 'Trade routes', [
      Strand('economics.trade_routes.container_ships', 'Container ships'),
      Strand('economics.trade_routes.silk_roads', 'Silk roads'),
      Strand('economics.trade_routes.chokepoints', 'Chokepoints'),
      Strand('economics.trade_routes.tariffs', 'Tariffs'),
      Strand(
        'economics.trade_routes.who_wins_from_trade',
        'Who wins from trade',
      ),
    ]),
    Genre('economics.crises', 'Crises', [
      Strand('economics.crises.1929', '1929'),
      Strand('economics.crises.2008', '2008'),
      Strand('economics.crises.hyperinflation', 'Hyperinflation'),
      Strand('economics.crises.bank_runs', 'Bank runs'),
      Strand('economics.crises.warning_signs', 'Warning signs'),
    ]),
    Genre('economics.everyday_costs', 'Everyday costs', [
      Strand('economics.everyday_costs.rent', 'Rent'),
      Strand('economics.everyday_costs.groceries', 'Groceries'),
      Strand('economics.everyday_costs.subscriptions', 'Subscriptions'),
      Strand('economics.everyday_costs.hidden_costs', 'Hidden costs'),
      Strand('economics.everyday_costs.buy_or_rent', 'Buy or rent'),
    ]),
    Genre('economics.think_in_incentives', 'Think in incentives', [
      Strand('economics.think_in_incentives.who_pays', 'Who pays'),
      Strand(
        'economics.think_in_incentives.hidden_incentives',
        'Hidden incentives',
      ),
      Strand(
        'economics.think_in_incentives.unintended_effects',
        'Unintended effects',
      ),
      Strand(
        'economics.think_in_incentives.perverse_rewards',
        'Perverse rewards',
      ),
      Strand(
        'economics.think_in_incentives.tragedy_of_the_commons',
        'Tragedy of the commons',
      ),
    ]),
    Genre('economics.spot_a_bad_deal', 'Spot a bad deal', [
      Strand('economics.spot_a_bad_deal.fine_print', 'Fine print'),
      Strand(
        'economics.spot_a_bad_deal.too_good_to_be_true',
        'Too good to be true',
      ),
      Strand('economics.spot_a_bad_deal.fees_that_grow', 'Fees that grow'),
      Strand('economics.spot_a_bad_deal.free_is_not_free', 'Free is not free'),
      Strand('economics.spot_a_bad_deal.loyalty_traps', 'Loyalty traps'),
    ]),
    Genre('economics.read_money_news', 'Read money news', [
      Strand(
        'economics.read_money_news.averages_that_mislead',
        'Averages that mislead',
      ),
      Strand(
        'economics.read_money_news.percent_or_points',
        'Percent or points',
      ),
      Strand('economics.read_money_news.real_or_nominal', 'Real or nominal'),
      Strand(
        'economics.read_money_news.cherry_picked_charts',
        'Cherry-picked charts',
      ),
      Strand(
        'economics.read_money_news.correlation_in_markets',
        'Correlation in markets',
      ),
    ]),
    Genre('economics.your_money_decisions', 'Your money decisions', [
      Strand(
        'economics.your_money_decisions.opportunity_cost',
        'Opportunity cost',
      ),
      Strand('economics.your_money_decisions.present_bias', 'Present bias'),
      Strand(
        'economics.your_money_decisions.mental_accounting',
        'Mental accounting',
      ),
      Strand(
        'economics.your_money_decisions.risk_and_reward',
        'Risk and reward',
      ),
      Strand(
        'economics.your_money_decisions.compound_interest',
        'Compound interest',
      ),
    ]),
    Genre('economics.markets_and_hype', 'Markets and hype', [
      Strand('economics.markets_and_hype.bubbles', 'Bubbles'),
      Strand(
        'economics.markets_and_hype.experts_forecasts',
        'Forecasts by experts',
      ),
      Strand('economics.markets_and_hype.survivor_stories', 'Survivor stories'),
      Strand('economics.markets_and_hype.get_rich_quick', 'Get rich quick'),
      Strand('economics.markets_and_hype.crypto', 'Crypto'),
    ]),
    Genre('economics.how_countries_get_rich', 'How countries get rich', [
      Strand('economics.how_countries_get_rich.institutions', 'Institutions'),
      Strand('economics.how_countries_get_rich.education', 'Education'),
      Strand('economics.how_countries_get_rich.corruption', 'Corruption'),
      Strand('economics.how_countries_get_rich.geography', 'Geography'),
      Strand('economics.how_countries_get_rich.aid', 'Aid'),
    ]),
    Genre('economics.inequality', 'Inequality', [
      Strand('economics.inequality.measuring_it', 'Measuring it'),
      Strand('economics.inequality.luck', 'Luck'),
      Strand('economics.inequality.inheritance', 'Inheritance'),
      Strand('economics.inequality.mobility', 'Mobility'),
      Strand('economics.inequality.taxes', 'Taxes'),
    ]),
  ],
  'technology': [
    Genre('technology.where_things_come_from', 'Where things come from', [
      Strand('technology.where_things_come_from.chips', 'Chips'),
      Strand('technology.where_things_come_from.rare_metals', 'Rare metals'),
      Strand('technology.where_things_come_from.factories', 'Factories'),
      Strand(
        'technology.where_things_come_from.supply_chains',
        'Supply chains',
      ),
      Strand(
        'technology.where_things_come_from.planned_obsolescence',
        'Planned obsolescence',
      ),
    ]),
    Genre('technology.the_internet', 'The internet', [
      Strand('technology.the_internet.cables', 'Cables'),
      Strand('technology.the_internet.dns', 'DNS'),
      Strand('technology.the_internet.data_centres', 'Data centres'),
      Strand('technology.the_internet.privacy', 'Privacy'),
      Strand('technology.the_internet.who_controls_it', 'Who controls it'),
    ]),
    Genre('technology.screens', 'Screens', [
      Strand('technology.screens.oled', 'OLED'),
      Strand('technology.screens.refresh_rates', 'Refresh rates'),
      Strand('technology.screens.touch', 'Touch'),
      Strand('technology.screens.screens_and_sleep', 'Screens and sleep'),
      Strand('technology.screens.blue_light_claims', 'Blue light claims'),
    ]),
    Genre('technology.batteries', 'Batteries', [
      Strand('technology.batteries.lithium', 'Lithium'),
      Strand('technology.batteries.charging', 'Charging'),
      Strand('technology.batteries.recycling', 'Recycling'),
      Strand('technology.batteries.battery_myths', 'Battery myths'),
      Strand('technology.batteries.electric_cars', 'Electric cars'),
    ]),
    Genre('technology.old_machines', 'Old machines', [
      Strand('technology.old_machines.typewriters', 'Typewriters'),
      Strand('technology.old_machines.telephones', 'Telephones'),
      Strand('technology.old_machines.mainframes', 'Mainframes'),
      Strand(
        'technology.old_machines.why_some_tech_wins',
        'Why some tech wins',
      ),
      Strand(
        'technology.old_machines.lessons_from_failures',
        'Lessons from failures',
      ),
    ]),
    Genre('technology.ai', 'AI', [
      Strand('technology.ai.training', 'Training'),
      Strand('technology.ai.chatbots', 'Chatbots'),
      Strand('technology.ai.limits', 'Limits'),
      Strand('technology.ai.bias_in_ai', 'Bias in AI'),
      Strand('technology.ai.jobs_and_ai', 'Jobs and AI'),
    ]),
    Genre('technology.think_about_tech', 'Think about tech', [
      Strand('technology.think_about_tech.hype_cycles', 'Hype cycles'),
      Strand('technology.think_about_tech.who_profits', 'Who profits'),
      Strand(
        'technology.think_about_tech.attention_economy',
        'Attention economy',
      ),
      Strand('technology.think_about_tech.defaults', 'Defaults'),
      Strand('technology.think_about_tech.dark_patterns', 'Dark patterns'),
    ]),
    Genre('technology.truth_online', 'Truth online', [
      Strand(
        'technology.truth_online.fakes_and_deepfakes',
        'Fakes and deepfakes',
      ),
      Strand(
        'technology.truth_online.algorithms_and_bubbles',
        'Algorithms and bubbles',
      ),
      Strand('technology.truth_online.checking_a_source', 'Checking a source'),
      Strand('technology.truth_online.viral_lies', 'Viral lies'),
      Strand('technology.truth_online.bots', 'Bots'),
    ]),
    Genre('technology.using_ai_well', 'Using AI well', [
      Strand('technology.using_ai_well.when_ai_is_wrong', 'When AI is wrong'),
      Strand('technology.using_ai_well.asking_well', 'Asking well'),
      Strand(
        'technology.using_ai_well.thinking_for_yourself',
        'Thinking for yourself',
      ),
      Strand(
        'technology.using_ai_well.checking_ai_answers',
        'Checking AI answers',
      ),
      Strand(
        'technology.using_ai_well.what_to_never_share',
        'What to never share',
      ),
    ]),
    Genre('technology.your_digital_life', 'Your digital life', [
      Strand('technology.your_digital_life.passwords', 'Passwords'),
      Strand('technology.your_digital_life.scams', 'Scams'),
      Strand('technology.your_digital_life.notifications', 'Notifications'),
      Strand(
        'technology.your_digital_life.data_you_give_away',
        'Data you give away',
      ),
      Strand('technology.your_digital_life.digital_detox', 'Digital detox'),
    ]),
    Genre('technology.tech_and_society', 'Tech and society', [
      Strand('technology.tech_and_society.surveillance', 'Surveillance'),
      Strand('technology.tech_and_society.jobs', 'Jobs'),
      Strand(
        'technology.tech_and_society.kids_and_screens',
        'Kids and screens',
      ),
      Strand('technology.tech_and_society.regulation', 'Regulation'),
      Strand('technology.tech_and_society.who_decides', 'Who decides'),
    ]),
  ],
  'history': [
    Genre('history.ancient_rome', 'Ancient Rome', [
      Strand('history.ancient_rome.roads', 'Roads'),
      Strand('history.ancient_rome.daily_rome', 'Daily Rome'),
      Strand('history.ancient_rome.the_fall', 'The fall'),
      Strand('history.ancient_rome.roman_politics', 'Roman politics'),
      Strand('history.ancient_rome.lessons_from_rome', 'Lessons from Rome'),
    ]),
    Genre('history.middle_ages', 'Middle Ages', [
      Strand('history.middle_ages.cathedrals', 'Cathedrals'),
      Strand('history.middle_ages.plague', 'Plague'),
      Strand('history.middle_ages.guilds', 'Guilds'),
      Strand('history.middle_ages.dark_ages_myth', 'Dark Ages myth'),
      Strand('history.middle_ages.faith_and_power', 'Faith and power'),
    ]),
    Genre('history.empires', 'Empires', [
      Strand('history.empires.ottoman', 'Ottoman'),
      Strand('history.empires.mongol', 'Mongol'),
      Strand('history.empires.british', 'British'),
      Strand('history.empires.why_empires_fall', 'Why empires fall'),
      Strand('history.empires.colonialism', 'Colonialism'),
    ]),
    Genre('history.everyday_life', 'Everyday life', [
      Strand('history.everyday_life.food', 'Food'),
      Strand('history.everyday_life.clothes', 'Clothes'),
      Strand('history.everyday_life.hygiene', 'Hygiene'),
      Strand('history.everyday_life.childhood', 'Childhood'),
      Strand('history.everyday_life.work', 'Work'),
    ]),
    Genre('history.revolutions', 'Revolutions', [
      Strand('history.revolutions.france', 'France'),
      Strand('history.revolutions.industrial', 'Industrial'),
      Strand('history.revolutions.1848', '1848'),
      Strand(
        'history.revolutions.why_revolutions_start',
        'Why revolutions start',
      ),
      Strand('history.revolutions.what_came_after', 'What came after'),
    ]),
    Genre('history.maps_and_borders', 'Maps and borders', [
      Strand('history.maps_and_borders.straight_lines', 'Straight lines'),
      Strand('history.maps_and_borders.lost_countries', 'Lost countries'),
      Strand('history.maps_and_borders.old_maps', 'Old maps'),
      Strand('history.maps_and_borders.map_projections', 'Map projections'),
      Strand('history.maps_and_borders.disputed_borders', 'Disputed borders'),
    ]),
    Genre('history.learn_from_the_past', 'Learn from the past', [
      Strand(
        'history.learn_from_the_past.repeated_mistakes',
        'Repeated mistakes',
      ),
      Strand('history.learn_from_the_past.who_wrote_it', 'Who wrote it'),
      Strand(
        'history.learn_from_the_past.hindsight_in_history',
        'Hindsight in history',
      ),
      Strand('history.learn_from_the_past.what_if', 'What if'),
      Strand(
        'history.learn_from_the_past.myths_about_the_past',
        'Myths about the past',
      ),
    ]),
    Genre(
      'history.decisions_that_changed_history',
      'Decisions that changed history',
      [
        Strand('history.decisions_that_changed_history.bad_calls', 'Bad calls'),
        Strand(
          'history.decisions_that_changed_history.groupthink',
          'Groupthink',
        ),
        Strand(
          'history.decisions_that_changed_history.leaders_under_pressure',
          'Leaders under pressure',
        ),
        Strand(
          'history.decisions_that_changed_history.small_causes_big_effects',
          'Small causes, big effects',
        ),
      ],
    ),
    Genre('history.propaganda', 'Propaganda', [
      Strand('history.propaganda.posters_and_slogans', 'Posters and slogans'),
      Strand('history.propaganda.rewriting_the_past', 'Rewriting the past'),
      Strand('history.propaganda.enemies_made_up', 'Enemies made up'),
      Strand('history.propaganda.propaganda_today', 'Propaganda today'),
      Strand('history.propaganda.censorship', 'Censorship'),
    ]),
    Genre('history.ordinary_people', 'Ordinary people', [
      Strand('history.ordinary_people.women_in_history', 'Women in history'),
      Strand('history.ordinary_people.migrants', 'Migrants'),
      Strand('history.ordinary_people.children', 'Children'),
      Strand('history.ordinary_people.workers', 'Workers'),
      Strand('history.ordinary_people.forgotten_heroes', 'Forgotten heroes'),
    ]),
    Genre('history.myths_about_history', 'Myths about history', [
      Strand('history.myths_about_history.columbus', 'Columbus'),
      Strand('history.myths_about_history.vikings', 'Vikings'),
      Strand('history.myths_about_history.flat_earth_myth', 'Flat Earth myth'),
      Strand('history.myths_about_history.napoleon_height', 'Napoleon height'),
      Strand('history.myths_about_history.witch_hunts', 'Witch hunts'),
    ]),
  ],
  'human_body': [
    Genre('human_body.the_brain', 'The brain', [
      Strand('human_body.the_brain.neurons', 'Neurons'),
      Strand('human_body.the_brain.left_and_right', 'Left and right'),
      Strand('human_body.the_brain.plasticity', 'Plasticity'),
      Strand('human_body.the_brain.brain_myths', 'Brain myths'),
      Strand('human_body.the_brain.brain_and_habits', 'Brain and habits'),
    ]),
    Genre('human_body.blood_and_heart', 'Blood and heart', [
      Strand('human_body.blood_and_heart.blood_types', 'Blood types'),
      Strand('human_body.blood_and_heart.heartbeat', 'Heartbeat'),
      Strand('human_body.blood_and_heart.circulation', 'Circulation'),
      Strand('human_body.blood_and_heart.blood_pressure', 'Blood pressure'),
      Strand('human_body.blood_and_heart.heart_and_stress', 'Heart and stress'),
    ]),
    Genre('human_body.skin_and_bone', 'Skin and bone', [
      Strand('human_body.skin_and_bone.healing', 'Healing'),
      Strand('human_body.skin_and_bone.fingerprints', 'Fingerprints'),
      Strand('human_body.skin_and_bone.bone_strength', 'Bone strength'),
      Strand('human_body.skin_and_bone.sun_and_skin', 'Sun and skin'),
      Strand('human_body.skin_and_bone.posture_myths', 'Posture myths'),
    ]),
    Genre('human_body.senses', 'Senses', [
      Strand('human_body.senses.taste', 'Taste'),
      Strand('human_body.senses.smell', 'Smell'),
      Strand('human_body.senses.balance', 'Balance'),
      Strand('human_body.senses.pain', 'Pain'),
      Strand('human_body.senses.senses_fooled', 'Senses fooled'),
    ]),
    Genre('human_body.gut', 'Gut', [
      Strand('human_body.gut.microbiome', 'Microbiome'),
      Strand('human_body.gut.digestion', 'Digestion'),
      Strand('human_body.gut.gut_and_mood', 'Gut and mood'),
      Strand('human_body.gut.probiotic_claims', 'Probiotic claims'),
      Strand('human_body.gut.hunger_signals', 'Hunger signals'),
    ]),
    Genre('human_body.ageing', 'Ageing', [
      Strand('human_body.ageing.telomeres', 'Telomeres'),
      Strand('human_body.ageing.grey_hair', 'Grey hair'),
      Strand('human_body.ageing.longevity', 'Longevity'),
      Strand('human_body.ageing.ageing_well', 'Ageing well'),
      Strand('human_body.ageing.anti_ageing_claims', 'Anti-ageing claims'),
    ]),
    Genre('human_body.health_claims', 'Health claims', [
      Strand('human_body.health_claims.miracle_cures', 'Miracle cures'),
      Strand('human_body.health_claims.supplements', 'Supplements'),
      Strand('human_body.health_claims.wellness_trends', 'Wellness trends'),
      Strand('human_body.health_claims.studies_on_mice', 'Studies on mice'),
      Strand('human_body.health_claims.before_and_after', 'Before and after'),
    ]),
    Genre('human_body.your_body_your_choices', 'Your body, your choices', [
      Strand(
        'human_body.your_body_your_choices.sleep_and_thinking',
        'Sleep and thinking',
      ),
      Strand(
        'human_body.your_body_your_choices.exercise_and_the_brain',
        'Exercise and the brain',
      ),
      Strand(
        'human_body.your_body_your_choices.food_and_mood',
        'Food and mood',
      ),
      Strand(
        'human_body.your_body_your_choices.small_daily_habits',
        'Small daily habits',
      ),
      Strand('human_body.your_body_your_choices.breathing', 'Breathing'),
    ]),
    Genre('human_body.your_body_in_numbers', 'Your body in numbers', [
      Strand('human_body.your_body_in_numbers.steps', 'Steps'),
      Strand('human_body.your_body_in_numbers.heart_rate', 'Heart rate'),
      Strand('human_body.your_body_in_numbers.bmi', 'BMI'),
      Strand(
        'human_body.your_body_in_numbers.calories_burned',
        'Calories burned',
      ),
      Strand('human_body.your_body_in_numbers.body_clock', 'Body clock'),
    ]),
    Genre('human_body.stress_and_the_body', 'Stress and the body', [
      Strand('human_body.stress_and_the_body.cortisol', 'Cortisol'),
      Strand('human_body.stress_and_the_body.burnout', 'Burnout'),
      Strand('human_body.stress_and_the_body.recovery', 'Recovery'),
      Strand('human_body.stress_and_the_body.breath', 'Breath'),
      Strand('human_body.stress_and_the_body.loneliness', 'Loneliness'),
    ]),
  ],
  'philosophy': [
    Genre('philosophy.ethics', 'Ethics', [
      Strand('philosophy.ethics.trolley_problems', 'Trolley problems'),
      Strand('philosophy.ethics.duty', 'Duty'),
      Strand('philosophy.ethics.virtue', 'Virtue'),
      Strand('philosophy.ethics.lying', 'Lying'),
      Strand('philosophy.ethics.animals', 'Animals'),
    ]),
    Genre('philosophy.knowledge', 'Knowledge', [
      Strand('philosophy.knowledge.certainty', 'Certainty'),
      Strand('philosophy.knowledge.science', 'Science'),
      Strand('philosophy.knowledge.doubt', 'Doubt'),
      Strand('philosophy.knowledge.trust_and_experts', 'Trust and experts'),
      Strand('philosophy.knowledge.how_do_you_know', 'How do you know'),
    ]),
    Genre('philosophy.time', 'Time', [
      Strand('philosophy.time.arrow_of_time', 'Arrow of time'),
      Strand('philosophy.time.presentism', 'Presentism'),
      Strand('philosophy.time.eternity', 'Eternity'),
      Strand('philosophy.time.living_in_the_present', 'Living in the present'),
      Strand(
        'philosophy.time.past_and_future_selves',
        'Past and future selves',
      ),
    ]),
    Genre('philosophy.free_will', 'Free will', [
      Strand('philosophy.free_will.determinism', 'Determinism'),
      Strand('philosophy.free_will.choice', 'Choice'),
      Strand('philosophy.free_will.responsibility', 'Responsibility'),
      Strand('philosophy.free_will.luck', 'Luck'),
      Strand('philosophy.free_will.blame', 'Blame'),
    ]),
    Genre('philosophy.ancient_thinkers', 'Ancient thinkers', [
      Strand('philosophy.ancient_thinkers.socrates', 'Socrates'),
      Strand('philosophy.ancient_thinkers.stoics', 'Stoics'),
      Strand('philosophy.ancient_thinkers.eastern', 'Eastern'),
      Strand('philosophy.ancient_thinkers.epicurus', 'Epicurus'),
      Strand('philosophy.ancient_thinkers.confucius', 'Confucius'),
    ]),
    Genre('philosophy.paradoxes', 'Paradoxes', [
      Strand('philosophy.paradoxes.ship_of_theseus', 'Ship of Theseus'),
      Strand('philosophy.paradoxes.zeno', 'Zeno'),
      Strand('philosophy.paradoxes.liar', 'Liar'),
      Strand('philosophy.paradoxes.sorites', 'Sorites'),
      Strand('philosophy.paradoxes.newcomb', 'Newcomb'),
    ]),
    Genre('philosophy.arguments', 'Arguments', [
      Strand('philosophy.arguments.good_arguments', 'Good arguments'),
      Strand('philosophy.arguments.fallacies', 'Fallacies'),
      Strand('philosophy.arguments.hidden_premises', 'Hidden premises'),
      Strand('philosophy.arguments.thought_experiments', 'Thought experiments'),
      Strand('philosophy.arguments.burden_of_proof', 'Burden of proof'),
    ]),
    Genre('philosophy.living_well', 'Living well', [
      Strand('philosophy.living_well.happiness', 'Happiness'),
      Strand('philosophy.living_well.meaning', 'Meaning'),
      Strand('philosophy.living_well.stoic_tools', 'Stoic tools'),
      Strand('philosophy.living_well.enough', 'Enough'),
      Strand('philosophy.living_well.death', 'Death'),
    ]),
    Genre('philosophy.big_questions', 'Big questions', [
      Strand('philosophy.big_questions.what_is_real', 'What is real'),
      Strand('philosophy.big_questions.mind_and_body', 'Mind and body'),
      Strand('philosophy.big_questions.identity', 'Identity'),
      Strand('philosophy.big_questions.god', 'God'),
      Strand('philosophy.big_questions.consciousness', 'Consciousness'),
    ]),
    Genre('philosophy.justice', 'Justice', [
      Strand('philosophy.justice.fairness', 'Fairness'),
      Strand('philosophy.justice.rights', 'Rights'),
      Strand('philosophy.justice.punishment', 'Punishment'),
      Strand('philosophy.justice.equality', 'Equality'),
      Strand('philosophy.justice.freedom', 'Freedom'),
    ]),
  ],
  'pop_culture': [
    Genre('pop_culture.logos_and_brands', 'Logos and brands', [
      Strand('pop_culture.logos_and_brands.swooshes', 'Swooshes'),
      Strand('pop_culture.logos_and_brands.rebrands', 'Rebrands'),
      Strand('pop_culture.logos_and_brands.colours', 'Colours'),
      Strand('pop_culture.logos_and_brands.brand_loyalty', 'Brand loyalty'),
      Strand(
        'pop_culture.logos_and_brands.why_brands_sell_feelings',
        'Why brands sell feelings',
      ),
    ]),
    Genre('pop_culture.internet_culture', 'Internet culture', [
      Strand('pop_culture.internet_culture.memes', 'Memes'),
      Strand('pop_culture.internet_culture.forums', 'Forums'),
      Strand('pop_culture.internet_culture.virality', 'Virality'),
      Strand('pop_culture.internet_culture.cancel_culture', 'Cancel culture'),
      Strand('pop_culture.internet_culture.online_outrage', 'Online outrage'),
    ]),
    Genre('pop_culture.fashion', 'Fashion', [
      Strand('pop_culture.fashion.denim', 'Denim'),
      Strand('pop_culture.fashion.sneakers', 'Sneakers'),
      Strand('pop_culture.fashion.fast_fashion', 'Fast fashion'),
      Strand('pop_culture.fashion.status_signals', 'Status signals'),
      Strand('pop_culture.fashion.why_trends_return', 'Why trends return'),
    ]),
    Genre('pop_culture.tv', 'TV', [
      Strand('pop_culture.tv.sitcoms', 'Sitcoms'),
      Strand('pop_culture.tv.reality', 'Reality'),
      Strand('pop_culture.tv.streaming', 'Streaming'),
      Strand('pop_culture.tv.binge_watching', 'Binge watching'),
      Strand('pop_culture.tv.what_reality_tv_hides', 'What reality TV hides'),
    ]),
    Genre('pop_culture.fame', 'Fame', [
      Strand('pop_culture.fame.celebrity', 'Celebrity'),
      Strand('pop_culture.fame.tabloids', 'Tabloids'),
      Strand('pop_culture.fame.fan_clubs', 'Fan clubs'),
      Strand('pop_culture.fame.influencers', 'Influencers'),
      Strand('pop_culture.fame.parasocial_bonds', 'Parasocial bonds'),
    ]),
    Genre('pop_culture.nineties', 'Nineties', [
      Strand('pop_culture.nineties.gadgets', 'Gadgets'),
      Strand('pop_culture.nineties.music', 'Music'),
      Strand('pop_culture.nineties.style', 'Style'),
      Strand('pop_culture.nineties.nostalgia', 'Nostalgia'),
      Strand('pop_culture.nineties.then_and_now', 'Then and now'),
    ]),
    Genre('pop_culture.behind_the_hype', 'Behind the hype', [
      Strand(
        'pop_culture.behind_the_hype.manufactured_fame',
        'Manufactured fame',
      ),
      Strand('pop_culture.behind_the_hype.trends', 'Trends'),
      Strand('pop_culture.behind_the_hype.fake_reviews', 'Fake reviews'),
      Strand('pop_culture.behind_the_hype.hype_and_money', 'Hype and money'),
      Strand('pop_culture.behind_the_hype.bandwagons', 'Bandwagons'),
    ]),
    Genre('pop_culture.social_media', 'Social media', [
      Strand('pop_culture.social_media.likes', 'Likes'),
      Strand('pop_culture.social_media.comparison', 'Comparison'),
      Strand(
        'pop_culture.social_media.fear_of_missing_out',
        'Fear of missing out',
      ),
      Strand('pop_culture.social_media.algorithms', 'Algorithms'),
      Strand('pop_culture.social_media.going_viral', 'Going viral'),
    ]),
    Genre('pop_culture.why_stories_grip_us', 'Why stories grip us', [
      Strand('pop_culture.why_stories_grip_us.heroes', 'Heroes'),
      Strand('pop_culture.why_stories_grip_us.villains', 'Villains'),
      Strand('pop_culture.why_stories_grip_us.cliffhangers', 'Cliffhangers'),
      Strand('pop_culture.why_stories_grip_us.fan_theories', 'Fan theories'),
      Strand('pop_culture.why_stories_grip_us.spoilers', 'Spoilers'),
    ]),
  ],
  'nature': [
    Genre('nature.trees_and_forests', 'Trees and forests', [
      Strand('nature.trees_and_forests.root_networks', 'Root networks'),
      Strand('nature.trees_and_forests.ancient_trees', 'Ancient trees'),
      Strand('nature.trees_and_forests.rainforests', 'Rainforests'),
      Strand(
        'nature.trees_and_forests.planting_trees_claims',
        'Planting trees claims',
      ),
      Strand(
        'nature.trees_and_forests.forests_and_climate',
        'Forests and climate',
      ),
    ]),
    Genre('nature.animal_senses', 'Animal senses', [
      Strand('nature.animal_senses.echolocation', 'Echolocation'),
      Strand('nature.animal_senses.magnetic_sense', 'Magnetic sense'),
      Strand('nature.animal_senses.night_vision', 'Night vision'),
      Strand('nature.animal_senses.animal_minds', 'Animal minds'),
      Strand(
        'nature.animal_senses.seeing_like_an_animal',
        'Seeing like an animal',
      ),
    ]),
    Genre('nature.oceans', 'Oceans', [
      Strand('nature.oceans.deep_sea', 'Deep sea'),
      Strand('nature.oceans.currents', 'Currents'),
      Strand('nature.oceans.coral', 'Coral'),
      Strand('nature.oceans.plastic', 'Plastic'),
      Strand('nature.oceans.overfishing', 'Overfishing'),
    ]),
    Genre('nature.weather', 'Weather', [
      Strand('nature.weather.storms', 'Storms'),
      Strand('nature.weather.clouds', 'Clouds'),
      Strand('nature.weather.forecasting', 'Forecasting'),
      Strand('nature.weather.weather_or_climate', 'Weather or climate'),
      Strand('nature.weather.forecast_odds', 'Forecast odds'),
    ]),
    Genre('nature.insects', 'Insects', [
      Strand('nature.insects.bees', 'Bees'),
      Strand('nature.insects.ants', 'Ants'),
      Strand('nature.insects.migration', 'Migration'),
      Strand('nature.insects.insect_decline', 'Insect decline'),
      Strand('nature.insects.pests', 'Pests'),
    ]),
    Genre('nature.extinction', 'Extinction', [
      Strand('nature.extinction.dinosaurs', 'Dinosaurs'),
      Strand('nature.extinction.recent_losses', 'Recent losses'),
      Strand('nature.extinction.bringing_back', 'Bringing back'),
      Strand('nature.extinction.why_species_vanish', 'Why species vanish'),
      Strand('nature.extinction.saving_species', 'Saving species'),
    ]),
    Genre('nature.systems_thinking', 'Systems thinking', [
      Strand('nature.systems_thinking.feedback_loops', 'Feedback loops'),
      Strand('nature.systems_thinking.tipping_points', 'Tipping points'),
      Strand('nature.systems_thinking.chain_reactions', 'Chain reactions'),
      Strand('nature.systems_thinking.invasive_species', 'Invasive species'),
      Strand('nature.systems_thinking.unintended_fixes', 'Unintended fixes'),
    ]),
    Genre('nature.nature_myths', 'Nature myths', [
      Strand('nature.nature_myths.animal_myths', 'Animal myths'),
      Strand('nature.nature_myths.natural_is_better', 'Natural is better'),
      Strand('nature.nature_myths.balance_of_nature', 'Balance of nature'),
      Strand(
        'nature.nature_myths.survival_of_the_fittest',
        'Survival of the fittest',
      ),
      Strand('nature.nature_myths.cute_and_dangerous', 'Cute and dangerous'),
    ]),
    Genre('nature.climate', 'Climate', [
      Strand('nature.climate.greenhouse_effect', 'Greenhouse effect'),
      Strand('nature.climate.carbon_footprint', 'Carbon footprint'),
      Strand('nature.climate.climate_myths', 'Climate myths'),
      Strand('nature.climate.adaptation', 'Adaptation'),
      Strand('nature.climate.what_one_person_can_do', 'What one person can do'),
    ]),
    Genre('nature.evolution', 'Evolution', [
      Strand('nature.evolution.natural_selection', 'Natural selection'),
      Strand('nature.evolution.common_myths', 'Common myths'),
      Strand('nature.evolution.humans_evolving', 'Humans evolving'),
      Strand('nature.evolution.mutations', 'Mutations'),
      Strand('nature.evolution.coevolution', 'Coevolution'),
    ]),
  ],
  'language': [
    Genre('language.word_origins', 'Word origins', [
      Strand('language.word_origins.latin_roots', 'Latin roots'),
      Strand('language.word_origins.borrowed_words', 'Borrowed words'),
      Strand('language.word_origins.brand_names', 'Brand names'),
      Strand(
        'language.word_origins.words_that_changed_meaning',
        'Words that changed meaning',
      ),
      Strand('language.word_origins.false_origins', 'False origins'),
    ]),
    Genre('language.writing_systems', 'Writing systems', [
      Strand('language.writing_systems.alphabets', 'Alphabets'),
      Strand(
        'language.writing_systems.chinese_characters',
        'Chinese characters',
      ),
      Strand('language.writing_systems.lost_scripts', 'Lost scripts'),
      Strand('language.writing_systems.spelling', 'Spelling'),
      Strand('language.writing_systems.emoji', 'Emoji'),
    ]),
    Genre('language.accents', 'Accents', [
      Strand('language.accents.how_they_form', 'How they form'),
      Strand('language.accents.dialects', 'Dialects'),
      Strand('language.accents.prestige_accents', 'Prestige accents'),
      Strand('language.accents.accent_bias', 'Accent bias'),
      Strand('language.accents.learning_an_accent', 'Learning an accent'),
    ]),
    Genre('language.untranslatable_words', 'Untranslatable words', [
      Strand('language.untranslatable_words.japanese', 'Japanese'),
      Strand('language.untranslatable_words.nordic', 'Nordic'),
      Strand('language.untranslatable_words.italian', 'Italian'),
      Strand(
        'language.untranslatable_words.words_and_thought',
        'Words and thought',
      ),
      Strand(
        'language.untranslatable_words.feelings_without_names',
        'Feelings without names',
      ),
    ]),
    Genre('language.grammar_oddities', 'Grammar oddities', [
      Strand('language.grammar_oddities.irregular_verbs', 'Irregular verbs'),
      Strand('language.grammar_oddities.double_negatives', 'Double negatives'),
      Strand('language.grammar_oddities.gendered_nouns', 'Gendered nouns'),
      Strand('language.grammar_oddities.correct_or_not', 'Correct or not'),
      Strand('language.grammar_oddities.language_change', 'Language change'),
    ]),
    Genre('language.slang', 'Slang', [
      Strand('language.slang.internet_slang', 'Internet slang'),
      Strand('language.slang.regional_slang', 'Regional slang'),
      Strand('language.slang.old_slang', 'Old slang'),
      Strand('language.slang.jargon', 'Jargon'),
      Strand('language.slang.who_invents_words', 'Who invents words'),
    ]),
    Genre('language.words_that_persuade', 'Words that persuade', [
      Strand('language.words_that_persuade.loaded_words', 'Loaded words'),
      Strand('language.words_that_persuade.euphemisms', 'Euphemisms'),
      Strand('language.words_that_persuade.spin', 'Spin'),
      Strand('language.words_that_persuade.great_speeches', 'Great speeches'),
      Strand(
        'language.words_that_persuade.questions_that_lead',
        'Questions that lead',
      ),
    ]),
    Genre('language.say_it_clearly', 'Say it clearly', [
      Strand('language.say_it_clearly.plain_words', 'Plain words'),
      Strand('language.say_it_clearly.arguing_well', 'Arguing well'),
      Strand('language.say_it_clearly.listening', 'Listening'),
      Strand('language.say_it_clearly.writing_well', 'Writing well'),
      Strand(
        'language.say_it_clearly.hard_conversations',
        'Hard conversations',
      ),
    ]),
    Genre('language.learning_languages', 'Learning languages', [
      Strand('language.learning_languages.kids_and_adults', 'Kids and adults'),
      Strand(
        'language.learning_languages.bilingual_brains',
        'Bilingual brains',
      ),
      Strand('language.learning_languages.mistakes', 'Mistakes'),
      Strand('language.learning_languages.immersion', 'Immersion'),
      Strand('language.learning_languages.apps', 'Apps'),
    ]),
    Genre('language.body_language', 'Body language', [
      Strand('language.body_language.myths', 'Myths'),
      Strand('language.body_language.eye_contact', 'Eye contact'),
      Strand('language.body_language.posture', 'Posture'),
      Strand('language.body_language.lies', 'Lies'),
      Strand('language.body_language.culture', 'Culture'),
    ]),
  ],
  'weird_facts': [
    Genre('weird_facts.animal_oddities', 'Animal oddities', [
      Strand('weird_facts.animal_oddities.wombats', 'Wombats'),
      Strand('weird_facts.animal_oddities.octopuses', 'Octopuses'),
      Strand('weird_facts.animal_oddities.axolotls', 'Axolotls'),
      Strand(
        'weird_facts.animal_oddities.animal_superpowers',
        'Animal superpowers',
      ),
      Strand('weird_facts.animal_oddities.weird_survival', 'Weird survival'),
    ]),
    Genre('weird_facts.records', 'Records', [
      Strand('weird_facts.records.tallest', 'Tallest'),
      Strand('weird_facts.records.fastest', 'Fastest'),
      Strand('weird_facts.records.oldest', 'Oldest'),
      Strand(
        'weird_facts.records.records_that_mislead',
        'Records that mislead',
      ),
      Strand('weird_facts.records.limits_of_the_body', 'Limits of the body'),
    ]),
    Genre('weird_facts.strange_laws', 'Strange laws', [
      Strand(
        'weird_facts.strange_laws.still_on_the_books',
        'Still on the books',
      ),
      Strand('weird_facts.strange_laws.local_bans', 'Local bans'),
      Strand('weird_facts.strange_laws.odd_fines', 'Odd fines'),
      Strand(
        'weird_facts.strange_laws.why_odd_laws_exist',
        'Why odd laws exist',
      ),
      Strand(
        'weird_facts.strange_laws.laws_that_backfired',
        'Laws that backfired',
      ),
    ]),
    Genre('weird_facts.coincidences', 'Coincidences', [
      Strand('weird_facts.coincidences.twins', 'Twins'),
      Strand('weird_facts.coincidences.dates', 'Dates'),
      Strand('weird_facts.coincidences.names', 'Names'),
      Strand(
        'weird_facts.coincidences.why_they_feel_magic',
        'Why they feel magic',
      ),
      Strand('weird_facts.coincidences.birthday_problem', 'Birthday problem'),
    ]),
    Genre('weird_facts.body_oddities', 'Body oddities', [
      Strand('weird_facts.body_oddities.hiccups', 'Hiccups'),
      Strand('weird_facts.body_oddities.sneezes', 'Sneezes'),
      Strand('weird_facts.body_oddities.goosebumps', 'Goosebumps'),
      Strand('weird_facts.body_oddities.yawning', 'Yawning'),
      Strand('weird_facts.body_oddities.phantom_feelings', 'Phantom feelings'),
    ]),
    Genre('weird_facts.odd_places', 'Odd places', [
      Strand('weird_facts.odd_places.ghost_towns', 'Ghost towns'),
      Strand('weird_facts.odd_places.tiny_nations', 'Tiny nations'),
      Strand('weird_facts.odd_places.extreme_spots', 'Extreme spots'),
      Strand(
        'weird_facts.odd_places.places_that_should_not_exist',
        'Places that should not exist',
      ),
      Strand('weird_facts.odd_places.borders_that_bend', 'Borders that bend'),
    ]),
    Genre('weird_facts.too_strange_to_be_true', 'Too strange to be true', [
      Strand(
        'weird_facts.too_strange_to_be_true.myths_that_spread',
        'Myths that spread',
      ),
      Strand('weird_facts.too_strange_to_be_true.hoaxes', 'Hoaxes'),
      Strand('weird_facts.too_strange_to_be_true.how_to_check', 'How to check'),
      Strand(
        'weird_facts.too_strange_to_be_true.urban_legends',
        'Urban legends',
      ),
      Strand(
        'weird_facts.too_strange_to_be_true.why_we_fall_for_them',
        'Why we fall for them',
      ),
    ]),
    Genre('weird_facts.weird_but_useful', 'Weird but useful', [
      Strand(
        'weird_facts.weird_but_useful.odd_tricks_that_work',
        'Odd tricks that work',
      ),
      Strand('weird_facts.weird_but_useful.lucky_accidents', 'Lucky accidents'),
      Strand(
        'weird_facts.weird_but_useful.inventions_by_mistake',
        'Inventions by mistake',
      ),
      Strand(
        'weird_facts.weird_but_useful.counterintuitive',
        'Counterintuitive',
      ),
      Strand(
        'weird_facts.weird_but_useful.strange_but_true',
        'Strange but true',
      ),
    ]),
    Genre('weird_facts.numbers_that_surprise', 'Numbers that surprise', [
      Strand('weird_facts.numbers_that_surprise.big_odds', 'Big odds'),
      Strand('weird_facts.numbers_that_surprise.small_odds', 'Small odds'),
      Strand('weird_facts.numbers_that_surprise.doubling', 'Doubling'),
      Strand(
        'weird_facts.numbers_that_surprise.paper_folding',
        'Paper folding',
      ),
      Strand('weird_facts.numbers_that_surprise.lotteries', 'Lotteries'),
    ]),
  ],
  'sport': [
    Genre('sport.rules_and_why', 'Rules and why', [
      Strand('sport.rules_and_why.offside', 'Offside'),
      Strand('sport.rules_and_why.fouls', 'Fouls'),
      Strand('sport.rules_and_why.scoring', 'Scoring'),
      Strand('sport.rules_and_why.rule_changes', 'Rule changes'),
      Strand('sport.rules_and_why.referees', 'Referees'),
    ]),
    Genre('sport.records', 'Records', [
      Strand('sport.records.sprint', 'Sprint'),
      Strand('sport.records.marathon', 'Marathon'),
      Strand('sport.records.swimming', 'Swimming'),
      Strand('sport.records.why_records_fall', 'Why records fall'),
      Strand('sport.records.doping', 'Doping'),
    ]),
    Genre('sport.training', 'Training', [
      Strand('sport.training.recovery', 'Recovery'),
      Strand('sport.training.altitude', 'Altitude'),
      Strand('sport.training.diet', 'Diet'),
      Strand('sport.training.rest_days', 'Rest days'),
      Strand('sport.training.talent_or_practice', 'Talent or practice'),
    ]),
    Genre('sport.equipment', 'Equipment', [
      Strand('sport.equipment.shoes', 'Shoes'),
      Strand('sport.equipment.balls', 'Balls'),
      Strand('sport.equipment.suits', 'Suits'),
      Strand('sport.equipment.tech_doping', 'Tech doping'),
      Strand('sport.equipment.cheap_or_expensive', 'Cheap or expensive'),
    ]),
    Genre('sport.olympics', 'Olympics', [
      Strand('sport.olympics.ancient', 'Ancient'),
      Strand('sport.olympics.modern', 'Modern'),
      Strand('sport.olympics.hosting', 'Hosting'),
      Strand('sport.olympics.boycotts', 'Boycotts'),
      Strand('sport.olympics.is_it_worth_it', 'Is it worth it'),
    ]),
    Genre('sport.tactics', 'Tactics', [
      Strand('sport.tactics.formations', 'Formations'),
      Strand('sport.tactics.set_pieces', 'Set pieces'),
      Strand('sport.tactics.coaching', 'Coaching'),
      Strand('sport.tactics.home_advantage', 'Home advantage'),
      Strand('sport.tactics.pressure', 'Pressure'),
    ]),
    Genre('sport.luck_or_skill', 'Luck or skill', [
      Strand('sport.luck_or_skill.hot_hand', 'Hot hand'),
      Strand('sport.luck_or_skill.regression', 'Regression'),
      Strand('sport.luck_or_skill.streaks', 'Streaks'),
      Strand('sport.luck_or_skill.penalty_kicks', 'Penalty kicks'),
      Strand('sport.luck_or_skill.coin_tosses', 'Coin tosses'),
    ]),
    Genre('sport.sport_and_numbers', 'Sport and numbers', [
      Strand('sport.sport_and_numbers.analytics', 'Analytics'),
      Strand('sport.sport_and_numbers.bad_stats', 'Bad stats'),
      Strand('sport.sport_and_numbers.betting_odds', 'Betting odds'),
      Strand('sport.sport_and_numbers.moneyball', 'Moneyball'),
      Strand('sport.sport_and_numbers.fantasy_sport', 'Fantasy sport'),
    ]),
    Genre('sport.the_mind_in_sport', 'The mind in sport', [
      Strand('sport.the_mind_in_sport.choking', 'Choking'),
      Strand('sport.the_mind_in_sport.confidence', 'Confidence'),
      Strand('sport.the_mind_in_sport.visualisation', 'Visualisation'),
      Strand('sport.the_mind_in_sport.rituals', 'Rituals'),
      Strand('sport.the_mind_in_sport.flow', 'Flow'),
    ]),
    Genre('sport.sport_and_society', 'Sport and society', [
      Strand('sport.sport_and_society.money_in_sport', 'Money in sport'),
      Strand('sport.sport_and_society.fans', 'Fans'),
      Strand('sport.sport_and_society.nationalism', 'Nationalism'),
      Strand('sport.sport_and_society.gender', 'Gender'),
      Strand('sport.sport_and_society.corruption', 'Corruption'),
    ]),
  ],
  'cinema': [
    Genre('cinema.how_films_are_made', 'How films are made', [
      Strand('cinema.how_films_are_made.editing', 'Editing'),
      Strand('cinema.how_films_are_made.lighting', 'Lighting'),
      Strand('cinema.how_films_are_made.budgets', 'Budgets'),
      Strand('cinema.how_films_are_made.screenwriting', 'Screenwriting'),
      Strand('cinema.how_films_are_made.sequels', 'Sequels'),
    ]),
    Genre('cinema.directors', 'Directors', [
      Strand('cinema.directors.kubrick', 'Kubrick'),
      Strand('cinema.directors.hitchcock', 'Hitchcock'),
      Strand('cinema.directors.new_wave', 'New wave'),
      Strand('cinema.directors.women_directors', 'Women directors'),
      Strand('cinema.directors.auteurs', 'Auteurs'),
    ]),
    Genre('cinema.special_effects', 'Special effects', [
      Strand('cinema.special_effects.practical', 'Practical'),
      Strand('cinema.special_effects.cgi', 'CGI'),
      Strand('cinema.special_effects.miniatures', 'Miniatures'),
      Strand('cinema.special_effects.uncanny_valley', 'Uncanny valley'),
      Strand('cinema.special_effects.fake_or_real', 'Fake or real'),
    ]),
    Genre('cinema.sound_design', 'Sound design', [
      Strand('cinema.sound_design.foley', 'Foley'),
      Strand('cinema.sound_design.silence', 'Silence'),
      Strand('cinema.sound_design.music_cues', 'Music cues'),
      Strand('cinema.sound_design.dialogue', 'Dialogue'),
      Strand('cinema.sound_design.sound_and_fear', 'Sound and fear'),
    ]),
    Genre('cinema.box_office', 'Box office', [
      Strand('cinema.box_office.flops', 'Flops'),
      Strand('cinema.box_office.hits', 'Hits'),
      Strand('cinema.box_office.marketing', 'Marketing'),
      Strand('cinema.box_office.critics_or_crowds', 'Critics or crowds'),
      Strand('cinema.box_office.remakes', 'Remakes'),
    ]),
    Genre('cinema.lost_films', 'Lost films', [
      Strand('cinema.lost_films.destroyed', 'Destroyed'),
      Strand('cinema.lost_films.rediscovered', 'Rediscovered'),
      Strand('cinema.lost_films.unfinished', 'Unfinished'),
      Strand('cinema.lost_films.film_preservation', 'Film preservation'),
      Strand('cinema.lost_films.censored_films', 'Censored films'),
    ]),
    Genre('cinema.how_films_persuade', 'How films persuade', [
      Strand('cinema.how_films_persuade.music_and_mood', 'Music and mood'),
      Strand('cinema.how_films_persuade.editing_tricks', 'Editing tricks'),
      Strand(
        'cinema.how_films_persuade.based_on_a_true_story',
        'Based on a true story',
      ),
      Strand(
        'cinema.how_films_persuade.heroes_and_villains',
        'Heroes and villains',
      ),
      Strand(
        'cinema.how_films_persuade.product_placement',
        'Product placement',
      ),
    ]),
    Genre('cinema.watch_smarter', 'Watch smarter', [
      Strand('cinema.watch_smarter.shots_and_angles', 'Shots and angles'),
      Strand('cinema.watch_smarter.hidden_meanings', 'Hidden meanings'),
      Strand('cinema.watch_smarter.plot_holes', 'Plot holes'),
      Strand('cinema.watch_smarter.reviews', 'Reviews'),
      Strand('cinema.watch_smarter.spot_the_trick', 'Spot the trick'),
    ]),
    Genre('cinema.films_and_history', 'Films and history', [
      Strand('cinema.films_and_history.historical_errors', 'Historical errors'),
      Strand('cinema.films_and_history.biopics', 'Biopics'),
      Strand('cinema.films_and_history.war_films', 'War films'),
      Strand('cinema.films_and_history.propaganda_films', 'Propaganda films'),
      Strand('cinema.films_and_history.what_films_teach', 'What films teach'),
    ]),
  ],
  'music': [
    Genre('music.why_songs_work', 'Why songs work', [
      Strand('music.why_songs_work.hooks', 'Hooks'),
      Strand('music.why_songs_work.chord_loops', 'Chord loops'),
      Strand('music.why_songs_work.rhythm', 'Rhythm'),
      Strand('music.why_songs_work.lyrics', 'Lyrics'),
      Strand('music.why_songs_work.song_length', 'Song length'),
    ]),
    Genre('music.instruments', 'Instruments', [
      Strand('music.instruments.piano', 'Piano'),
      Strand('music.instruments.guitar', 'Guitar'),
      Strand('music.instruments.strange_ones', 'Strange ones'),
      Strand(
        'music.instruments.learning_an_instrument',
        'Learning an instrument',
      ),
      Strand('music.instruments.voice', 'Voice'),
    ]),
    Genre('music.studio_tricks', 'Studio tricks', [
      Strand('music.studio_tricks.reverb', 'Reverb'),
      Strand('music.studio_tricks.autotune', 'Autotune'),
      Strand('music.studio_tricks.layering', 'Layering'),
      Strand('music.studio_tricks.loudness_war', 'Loudness war'),
      Strand('music.studio_tricks.sampling', 'Sampling'),
    ]),
    Genre('music.genres', 'Genres', [
      Strand('music.genres.jazz', 'Jazz'),
      Strand('music.genres.techno', 'Techno'),
      Strand('music.genres.folk', 'Folk'),
      Strand('music.genres.hip_hop', 'Hip hop'),
      Strand('music.genres.classical', 'Classical'),
    ]),
    Genre('music.composers', 'Composers', [
      Strand('music.composers.bach', 'Bach'),
      Strand('music.composers.mozart', 'Mozart'),
      Strand('music.composers.film_scores', 'Film scores'),
      Strand('music.composers.beethoven', 'Beethoven'),
      Strand('music.composers.pop_songwriters', 'Pop songwriters'),
    ]),
    Genre('music.sound_itself', 'Sound itself', [
      Strand('music.sound_itself.frequencies', 'Frequencies'),
      Strand('music.sound_itself.acoustics', 'Acoustics'),
      Strand('music.sound_itself.silence', 'Silence'),
      Strand('music.sound_itself.noise_and_health', 'Noise and health'),
      Strand('music.sound_itself.hearing', 'Hearing'),
    ]),
    Genre('music.why_we_like_what_we_like', 'Why we like what we like', [
      Strand('music.why_we_like_what_we_like.familiarity', 'Familiarity'),
      Strand(
        'music.why_we_like_what_we_like.taste_and_status',
        'Taste and status',
      ),
      Strand('music.why_we_like_what_we_like.earworms', 'Earworms'),
      Strand(
        'music.why_we_like_what_we_like.music_and_memory',
        'Music and memory',
      ),
      Strand('music.why_we_like_what_we_like.music_and_mood', 'Music and mood'),
    ]),
    Genre('music.music_and_the_brain', 'Music and the brain', [
      Strand('music.music_and_the_brain.chills', 'Chills'),
      Strand('music.music_and_the_brain.practice', 'Practice'),
      Strand('music.music_and_the_brain.perfect_pitch', 'Perfect pitch'),
      Strand(
        'music.music_and_the_brain.rhythm_in_the_body',
        'Rhythm in the body',
      ),
      Strand('music.music_and_the_brain.music_therapy', 'Music therapy'),
    ]),
    Genre('music.the_music_business', 'The music business', [
      Strand('music.the_music_business.streaming_pay', 'Streaming pay'),
      Strand('music.the_music_business.charts', 'Charts'),
      Strand('music.the_music_business.copyright', 'Copyright'),
      Strand('music.the_music_business.one_hit_wonders', 'One hit wonders'),
      Strand('music.the_music_business.labels', 'Labels'),
    ]),
  ],
  'art': [
    Genre('art.colour_and_pigment', 'Colour and pigment', [
      Strand('art.colour_and_pigment.ultramarine', 'Ultramarine'),
      Strand('art.colour_and_pigment.mummy_brown', 'Mummy brown'),
      Strand('art.colour_and_pigment.synthetics', 'Synthetics'),
      Strand('art.colour_and_pigment.colour_and_mood', 'Colour and mood'),
      Strand('art.colour_and_pigment.rare_colours', 'Rare colours'),
    ]),
    Genre('art.renaissance', 'Renaissance', [
      Strand('art.renaissance.florence', 'Florence'),
      Strand('art.renaissance.patrons', 'Patrons'),
      Strand('art.renaissance.perspective', 'Perspective'),
      Strand('art.renaissance.leonardo', 'Leonardo'),
      Strand('art.renaissance.myths_about_genius', 'Myths about genius'),
    ]),
    Genre('art.modern_art', 'Modern art', [
      Strand('art.modern_art.cubism', 'Cubism'),
      Strand('art.modern_art.abstraction', 'Abstraction'),
      Strand('art.modern_art.pop', 'Pop'),
      Strand('art.modern_art.my_kid_could_do_that', 'My kid could do that'),
      Strand('art.modern_art.street_art', 'Street art'),
    ]),
    Genre('art.sculpture', 'Sculpture', [
      Strand('art.sculpture.marble', 'Marble'),
      Strand('art.sculpture.bronze', 'Bronze'),
      Strand('art.sculpture.lost_colour', 'Lost colour'),
      Strand('art.sculpture.public_statues', 'Public statues'),
      Strand('art.sculpture.monuments_debate', 'Monuments debate'),
    ]),
    Genre('art.photography', 'Photography', [
      Strand('art.photography.first_photos', 'First photos'),
      Strand('art.photography.darkroom', 'Darkroom'),
      Strand('art.photography.digital', 'Digital'),
      Strand('art.photography.edited_photos', 'Edited photos'),
      Strand('art.photography.photos_that_lied', 'Photos that lied'),
    ]),
    Genre('art.forgeries', 'Forgeries', [
      Strand('art.forgeries.famous_fakes', 'Famous fakes'),
      Strand('art.forgeries.detection', 'Detection'),
      Strand('art.forgeries.motives', 'Motives'),
      Strand('art.forgeries.fakes_today', 'Fakes today'),
      Strand('art.forgeries.experts_fooled', 'Experts fooled'),
    ]),
    Genre('art.what_makes_it_valuable', 'What makes it valuable', [
      Strand('art.what_makes_it_valuable.price_and_value', 'Price and value'),
      Strand('art.what_makes_it_valuable.hype_in_art', 'Hype in art'),
      Strand(
        'art.what_makes_it_valuable.seeing_for_yourself',
        'Seeing for yourself',
      ),
      Strand('art.what_makes_it_valuable.museums', 'Museums'),
      Strand('art.what_makes_it_valuable.art_and_money', 'Art and money'),
    ]),
    Genre('art.look_closer', 'Look closer', [
      Strand('art.look_closer.composition', 'Composition'),
      Strand('art.look_closer.symbols', 'Symbols'),
      Strand('art.look_closer.light', 'Light'),
      Strand('art.look_closer.faces', 'Faces'),
      Strand('art.look_closer.what_artists_hide', 'What artists hide'),
    ]),
    Genre('art.art_and_power', 'Art and power', [
      Strand('art.art_and_power.patrons', 'Patrons'),
      Strand('art.art_and_power.censorship', 'Censorship'),
      Strand('art.art_and_power.protest_art', 'Protest art'),
      Strand('art.art_and_power.stolen_art', 'Stolen art'),
      Strand('art.art_and_power.who_gets_in_museums', 'Who gets in museums'),
    ]),
  ],
  'medicine': [
    Genre('medicine.vaccines', 'Vaccines', [
      Strand('medicine.vaccines.how_they_work', 'How they work'),
      Strand('medicine.vaccines.cold_chain', 'Cold chain'),
      Strand('medicine.vaccines.doubt', 'Doubt'),
      Strand('medicine.vaccines.herd_immunity', 'Herd immunity'),
      Strand(
        'medicine.vaccines.side_effects_in_numbers',
        'Side effects in numbers',
      ),
    ]),
    Genre('medicine.antibiotics', 'Antibiotics', [
      Strand('medicine.antibiotics.penicillin', 'Penicillin'),
      Strand('medicine.antibiotics.resistance', 'Resistance'),
      Strand('medicine.antibiotics.new_ones', 'New ones'),
      Strand(
        'medicine.antibiotics.when_not_to_take_them',
        'When not to take them',
      ),
      Strand('medicine.antibiotics.farm_antibiotics', 'Farm antibiotics'),
    ]),
    Genre('medicine.surgery', 'Surgery', [
      Strand('medicine.surgery.anaesthesia', 'Anaesthesia'),
      Strand('medicine.surgery.transplants', 'Transplants'),
      Strand('medicine.surgery.robots', 'Robots'),
      Strand('medicine.surgery.second_opinions', 'Second opinions'),
      Strand('medicine.surgery.risks_of_surgery', 'Risks of surgery'),
    ]),
    Genre('medicine.pain', 'Pain', [
      Strand('medicine.pain.chronic', 'Chronic'),
      Strand('medicine.pain.painkillers', 'Painkillers'),
      Strand('medicine.pain.placebo', 'Placebo'),
      Strand('medicine.pain.pain_and_mind', 'Pain and mind'),
      Strand('medicine.pain.back_pain', 'Back pain'),
    ]),
    Genre('medicine.diagnosis', 'Diagnosis', [
      Strand('medicine.diagnosis.scans', 'Scans'),
      Strand('medicine.diagnosis.blood_tests', 'Blood tests'),
      Strand('medicine.diagnosis.symptoms', 'Symptoms'),
      Strand('medicine.diagnosis.false_positives', 'False positives'),
      Strand('medicine.diagnosis.too_much_testing', 'Too much testing'),
    ]),
    Genre('medicine.medical_history', 'Medical history', [
      Strand('medicine.medical_history.barbers', 'Barbers'),
      Strand('medicine.medical_history.germ_theory', 'Germ theory'),
      Strand('medicine.medical_history.hospitals', 'Hospitals'),
      Strand('medicine.medical_history.bad_cures', 'Bad cures'),
      Strand(
        'medicine.medical_history.doctors_who_were_right',
        'Doctors who were right',
      ),
    ]),
    Genre('medicine.judge_a_treatment', 'Judge a treatment', [
      Strand('medicine.judge_a_treatment.placebo_or_real', 'Placebo or real'),
      Strand('medicine.judge_a_treatment.risk_numbers', 'Risk numbers'),
      Strand('medicine.judge_a_treatment.side_effects', 'Side effects'),
      Strand('medicine.judge_a_treatment.screening', 'Screening'),
      Strand(
        'medicine.judge_a_treatment.alternative_medicine',
        'Alternative medicine',
      ),
    ]),
    Genre('medicine.medical_myths', 'Medical myths', [
      Strand('medicine.medical_myths.folk_remedies', 'Folk remedies'),
      Strand('medicine.medical_myths.online_diagnosis', 'Online diagnosis'),
      Strand('medicine.medical_myths.detox', 'Detox'),
      Strand('medicine.medical_myths.cold_and_flu_myths', 'Cold and flu myths'),
      Strand('medicine.medical_myths.food_as_medicine', 'Food as medicine'),
    ]),
    Genre('medicine.talk_to_your_doctor', 'Talk to your doctor', [
      Strand(
        'medicine.talk_to_your_doctor.questions_to_ask',
        'Questions to ask',
      ),
      Strand('medicine.talk_to_your_doctor.reading_results', 'Reading results'),
      Strand('medicine.talk_to_your_doctor.risk_explained', 'Risk explained'),
      Strand(
        'medicine.talk_to_your_doctor.shared_decisions',
        'Shared decisions',
      ),
      Strand(
        'medicine.talk_to_your_doctor.getting_a_second_opinion',
        'Getting a second opinion',
      ),
    ]),
    Genre('medicine.public_health', 'Public health', [
      Strand('medicine.public_health.smoking', 'Smoking'),
      Strand('medicine.public_health.clean_water', 'Clean water'),
      Strand('medicine.public_health.pandemics', 'Pandemics'),
      Strand('medicine.public_health.prevention', 'Prevention'),
      Strand('medicine.public_health.health_and_wealth', 'Health and wealth'),
    ]),
  ],
  'food': [
    Genre('food.bread_and_baking', 'Bread and baking', [
      Strand('food.bread_and_baking.sourdough', 'Sourdough'),
      Strand('food.bread_and_baking.yeast', 'Yeast'),
      Strand('food.bread_and_baking.crust', 'Crust'),
      Strand('food.bread_and_baking.gluten_claims', 'Gluten claims'),
      Strand('food.bread_and_baking.bread_and_history', 'Bread and history'),
    ]),
    Genre('food.coffee', 'Coffee', [
      Strand('food.coffee.roasting', 'Roasting'),
      Strand('food.coffee.espresso', 'Espresso'),
      Strand('food.coffee.origins', 'Origins'),
      Strand('food.coffee.caffeine', 'Caffeine'),
      Strand(
        'food.coffee.coffee_and_health_claims',
        'Coffee and health claims',
      ),
    ]),
    Genre('food.fermentation', 'Fermentation', [
      Strand('food.fermentation.cheese', 'Cheese'),
      Strand('food.fermentation.kimchi', 'Kimchi'),
      Strand('food.fermentation.beer', 'Beer'),
      Strand('food.fermentation.gut_health_claims', 'Gut health claims'),
      Strand('food.fermentation.food_safety', 'Food safety'),
    ]),
    Genre('food.spices', 'Spices', [
      Strand('food.spices.pepper', 'Pepper'),
      Strand('food.spices.saffron', 'Saffron'),
      Strand('food.spices.chilli', 'Chilli'),
      Strand('food.spices.spice_trade', 'Spice trade'),
      Strand('food.spices.heat_and_the_brain', 'Heat and the brain'),
    ]),
    Genre('food.cooking_science', 'Cooking science', [
      Strand('food.cooking_science.maillard', 'Maillard'),
      Strand('food.cooking_science.emulsions', 'Emulsions'),
      Strand('food.cooking_science.salt', 'Salt'),
      Strand('food.cooking_science.cooking_myths', 'Cooking myths'),
      Strand('food.cooking_science.taste_and_smell', 'Taste and smell'),
    ]),
    Genre('food.food_history', 'Food history', [
      Strand('food.food_history.pasta', 'Pasta'),
      Strand('food.food_history.sugar', 'Sugar'),
      Strand('food.food_history.potatoes', 'Potatoes'),
      Strand('food.food_history.tomatoes', 'Tomatoes'),
      Strand('food.food_history.fast_food', 'Fast food'),
    ]),
    Genre('food.food_claims', 'Food claims', [
      Strand('food.food_claims.superfoods', 'Superfoods'),
      Strand('food.food_claims.labels', 'Labels'),
      Strand('food.food_claims.diet_studies', 'Diet studies'),
      Strand('food.food_claims.organic', 'Organic'),
      Strand('food.food_claims.calories', 'Calories'),
      Strand('food.food_claims.processed_food', 'Processed food'),
    ]),
    Genre('food.eat_smarter', 'Eat smarter', [
      Strand('food.eat_smarter.portion_sizes', 'Portion sizes'),
      Strand('food.eat_smarter.hunger_or_habit', 'Hunger or habit'),
      Strand('food.eat_smarter.marketing_to_kids', 'Marketing to kids'),
      Strand('food.eat_smarter.sugar', 'Sugar'),
      Strand('food.eat_smarter.eating_together', 'Eating together'),
    ]),
    Genre('food.food_and_the_planet', 'Food and the planet', [
      Strand('food.food_and_the_planet.meat', 'Meat'),
      Strand('food.food_and_the_planet.food_waste', 'Food waste'),
      Strand('food.food_and_the_planet.local_or_not', 'Local or not'),
      Strand('food.food_and_the_planet.water_use', 'Water use'),
      Strand('food.food_and_the_planet.future_food', 'Future food'),
    ]),
  ],
  'life': [
    Genre('life.habits', 'Habits', [
      Strand('life.habits.routines', 'Routines'),
      Strand('life.habits.deep_work', 'Deep work'),
      Strand('life.habits.screens', 'Screens'),
      Strand('life.habits.mornings', 'Mornings'),
      Strand('life.habits.small_wins', 'Small wins'),
    ]),
    Genre('life.decisions', 'Decisions', [
      Strand('life.decisions.big_choices', 'Big choices'),
      Strand('life.decisions.regret', 'Regret'),
      Strand('life.decisions.risk_taking', 'Risk-taking'),
      Strand('life.decisions.good_enough', 'Good enough'),
      Strand('life.decisions.gut_or_data', 'Gut or data'),
    ]),
    Genre('life.money_and_time', 'Money and time', [
      Strand('life.money_and_time.saving', 'Saving'),
      Strand('life.money_and_time.spending', 'Spending'),
      Strand('life.money_and_time.time', 'Time'),
      Strand('life.money_and_time.enough_money', 'Enough money'),
      Strand(
        'life.money_and_time.what_things_cost_in_hours',
        'What things cost in hours',
      ),
    ]),
    Genre('life.people', 'People', [
      Strand('life.people.friendship', 'Friendship'),
      Strand('life.people.conversation', 'Conversation'),
      Strand('life.people.kindness', 'Kindness'),
      Strand('life.people.trust', 'Trust'),
      Strand('life.people.listening', 'Listening'),
    ]),
    Genre('life.growth', 'Growth', [
      Strand('life.growth.failure', 'Failure'),
      Strand('life.growth.learning', 'Learning'),
      Strand('life.growth.limits', 'Limits'),
      Strand('life.growth.feedback', 'Feedback'),
      Strand('life.growth.comfort_zone', 'Comfort zone'),
    ]),
    Genre('life.meaning', 'Meaning', [
      Strand('life.meaning.purpose', 'Purpose'),
      Strand('life.meaning.gratitude', 'Gratitude'),
      Strand('life.meaning.mortality', 'Mortality'),
      Strand('life.meaning.values', 'Values'),
      Strand('life.meaning.legacy', 'Legacy'),
    ]),
    Genre('life.ask_better_questions', 'Ask better questions', [
      Strand(
        'life.ask_better_questions.questions_to_yourself',
        'Questions to yourself',
      ),
      Strand(
        'life.ask_better_questions.questions_to_others',
        'Questions to others',
      ),
      Strand('life.ask_better_questions.the_why_behind', 'The why behind'),
      Strand('life.ask_better_questions.first_principles', 'First principles'),
      Strand('life.ask_better_questions.curiosity', 'Curiosity'),
    ]),
    Genre('life.clear_thinking', 'Clear thinking', [
      Strand('life.clear_thinking.pros_and_cons', 'Pros and cons'),
      Strand(
        'life.clear_thinking.second_order_effects',
        'Second-order effects',
      ),
      Strand('life.clear_thinking.inversion', 'Inversion'),
      Strand('life.clear_thinking.reversible_or_not', 'Reversible or not'),
      Strand(
        'life.clear_thinking.circle_of_competence',
        'Circle of competence',
      ),
    ]),
    Genre('life.learn_anything', 'Learn anything', [
      Strand('life.learn_anything.practice_that_works', 'Practice that works'),
      Strand(
        'life.learn_anything.learning_from_mistakes',
        'Learning from mistakes',
      ),
      Strand('life.learn_anything.reading_well', 'Reading well'),
      Strand('life.learn_anything.teaching_it_back', 'Teaching it back'),
      Strand('life.learn_anything.memory_tricks', 'Memory tricks'),
    ]),
    Genre('life.handle_setbacks', 'Handle setbacks', [
      Strand('life.handle_setbacks.reframing', 'Reframing'),
      Strand('life.handle_setbacks.what_you_control', 'What you control'),
      Strand('life.handle_setbacks.failing_forward', 'Failing forward'),
      Strand('life.handle_setbacks.comparison', 'Comparison'),
      Strand('life.handle_setbacks.starting_again', 'Starting again'),
    ]),
    Genre('life.time_and_attention', 'Time and attention', [
      Strand('life.time_and_attention.saying_no', 'Saying no'),
      Strand('life.time_and_attention.deep_focus', 'Deep focus'),
      Strand('life.time_and_attention.priorities', 'Priorities'),
      Strand('life.time_and_attention.rest', 'Rest'),
      Strand('life.time_and_attention.boredom', 'Boredom'),
    ]),
    Genre('life.relationships', 'Relationships', [
      Strand('life.relationships.arguments', 'Arguments'),
      Strand('life.relationships.love', 'Love'),
      Strand('life.relationships.boundaries', 'Boundaries'),
      Strand('life.relationships.apologies', 'Apologies'),
      Strand('life.relationships.family', 'Family'),
    ]),
    Genre('life.work_and_career', 'Work and career', [
      Strand('life.work_and_career.choosing_work', 'Choosing work'),
      Strand('life.work_and_career.asking_for_more', 'Asking for more'),
      Strand('life.work_and_career.burnout', 'Burnout'),
      Strand('life.work_and_career.side_projects', 'Side projects'),
      Strand('life.work_and_career.meetings', 'Meetings'),
    ]),
  ],
};

/// Every genre there is, which is what the footer counts against.
final List<Genre> kAllGenres = [for (final list in kGenres.values) ...list];

/// One genre by id, or null for an id from a build that carried it and this
/// one does not.
final Map<String, Genre> _genresById = {for (final g in kAllGenres) g.id: g};

Genre? genreById(String id) => _genresById[id];

/// A strand's genre, read off the id rather than searched for: a strand id is
/// its genre's id with one more part on the end.
String genreIdOf(String strandId) =>
    strandId.substring(0, strandId.lastIndexOf('.'));
