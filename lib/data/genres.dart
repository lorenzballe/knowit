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
    ]),
    Genre('science.chemistry_at_home', 'Chemistry at home', [
      Strand('science.chemistry_at_home.cleaning', 'Cleaning'),
      Strand(
        'science.chemistry_at_home.cooking_reactions',
        'Cooking reactions',
      ),
      Strand('science.chemistry_at_home.rust', 'Rust'),
    ]),
    Genre('science.light_and_colour', 'Light and colour', [
      Strand('science.light_and_colour.rainbows', 'Rainbows'),
      Strand('science.light_and_colour.pigments', 'Pigments'),
      Strand('science.light_and_colour.lasers', 'Lasers'),
    ]),
    Genre('science.cold_and_heat', 'Cold and heat', [
      Strand('science.cold_and_heat.absolute_zero', 'Absolute zero'),
      Strand('science.cold_and_heat.insulation', 'Insulation'),
      Strand('science.cold_and_heat.fire', 'Fire'),
    ]),
    Genre('science.maths_curios', 'Maths curios', [
      Strand('science.maths_curios.infinity', 'Infinity'),
      Strand('science.maths_curios.primes', 'Primes'),
      Strand('science.maths_curios.probability', 'Probability'),
    ]),
    Genre('science.materials', 'Materials', [
      Strand('science.materials.glass', 'Glass'),
      Strand('science.materials.steel', 'Steel'),
      Strand('science.materials.plastics', 'Plastics'),
    ]),
    Genre('science.how_science_knows', 'How science knows', [
      Strand('science.how_science_knows.experiments', 'Experiments'),
      Strand(
        'science.how_science_knows.correlation_or_cause',
        'Correlation or cause',
      ),
      Strand('science.how_science_knows.replication', 'Replication'),
      Strand('science.how_science_knows.peer_review', 'Peer review'),
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
    ]),
    Genre('science.numbers_and_chance', 'Numbers and chance', [
      Strand('science.numbers_and_chance.base_rates', 'Base rates'),
      Strand('science.numbers_and_chance.coincidences', 'Coincidences'),
      Strand('science.numbers_and_chance.big_numbers', 'Big numbers'),
      Strand('science.numbers_and_chance.estimating', 'Estimating'),
    ]),
  ],
  'space': [
    Genre('space.black_holes', 'Black holes', [
      Strand('space.black_holes.event_horizons', 'Event horizons'),
      Strand('space.black_holes.supermassive_ones', 'Supermassive ones'),
      Strand('space.black_holes.hawking_radiation', 'Hawking radiation'),
    ]),
    Genre('space.the_moon', 'The Moon', [
      Strand('space.the_moon.tides', 'Tides'),
      Strand('space.the_moon.landing_sites', 'Landing sites'),
      Strand('space.the_moon.moon_dust', 'Moon dust'),
    ]),
    Genre('space.mars_and_rovers', 'Mars and rovers', [
      Strand('space.mars_and_rovers.perseverance', 'Perseverance'),
      Strand('space.mars_and_rovers.martian_weather', 'Martian weather'),
      Strand('space.mars_and_rovers.water_on_mars', 'Water on Mars'),
    ]),
    Genre('space.stars_and_light', 'Stars and light', [
      Strand('space.stars_and_light.star_death', 'Star death'),
      Strand('space.stars_and_light.light_years', 'Light years'),
      Strand('space.stars_and_light.colours_of_stars', 'Colours of stars'),
    ]),
    Genre('space.rockets', 'Rockets', [
      Strand('space.rockets.reusable_boosters', 'Reusable boosters'),
      Strand('space.rockets.fuel_chemistry', 'Fuel chemistry'),
      Strand('space.rockets.launch_windows', 'Launch windows'),
    ]),
    Genre('space.edge_of_the_universe', 'Edge of the universe', [
      Strand('space.edge_of_the_universe.expansion', 'Expansion'),
      Strand('space.edge_of_the_universe.dark_matter', 'Dark matter'),
      Strand(
        'space.edge_of_the_universe.cosmic_background',
        'Cosmic background',
      ),
    ]),
    Genre('space.think_at_scale', 'Think at scale', [
      Strand('space.think_at_scale.sizes', 'Sizes'),
      Strand('space.think_at_scale.distances', 'Distances'),
      Strand('space.think_at_scale.deep_time', 'Deep time'),
    ]),
    Genre('space.are_we_alone', 'Are we alone', [
      Strand('space.are_we_alone.fermi_paradox', 'Fermi paradox'),
      Strand('space.are_we_alone.evidence_and_hope', 'Evidence and hope'),
      Strand('space.are_we_alone.extraordinary_claims', 'Extraordinary claims'),
    ]),
  ],
  'psychology': [
    Genre('psychology.memory', 'Memory', [
      Strand('psychology.memory.forgetting_curve', 'Forgetting curve'),
      Strand('psychology.memory.false_memories', 'False memories'),
      Strand('psychology.memory.mnemonics', 'Mnemonics'),
    ]),
    Genre('psychology.attention', 'Attention', [
      Strand('psychology.attention.focus', 'Focus'),
      Strand('psychology.attention.distraction', 'Distraction'),
      Strand('psychology.attention.flow', 'Flow'),
    ]),
    Genre('psychology.habits', 'Habits', [
      Strand('psychology.habits.cues', 'Cues'),
      Strand('psychology.habits.streaks', 'Streaks'),
      Strand('psychology.habits.breaking_them', 'Breaking them'),
    ]),
    Genre('psychology.emotions', 'Emotions', [
      Strand('psychology.emotions.fear', 'Fear'),
      Strand('psychology.emotions.joy', 'Joy'),
      Strand('psychology.emotions.why_we_cry', 'Why we cry'),
    ]),
    Genre('psychology.bias', 'Bias', [
      Strand('psychology.bias.confirmation', 'Confirmation'),
      Strand('psychology.bias.sunk_cost', 'Sunk cost'),
      Strand('psychology.bias.halo_effect', 'Halo effect'),
    ]),
    Genre('psychology.sleep_and_dreams', 'Sleep and dreams', [
      Strand('psychology.sleep_and_dreams.sleep_stages', 'Sleep stages'),
      Strand('psychology.sleep_and_dreams.why_we_dream', 'Why we dream'),
      Strand('psychology.sleep_and_dreams.insomnia', 'Insomnia'),
    ]),
    Genre('psychology.know_your_own_mind', 'Know your own mind', [
      Strand('psychology.know_your_own_mind.overconfidence', 'Overconfidence'),
      Strand('psychology.know_your_own_mind.hindsight', 'Hindsight'),
      Strand('psychology.know_your_own_mind.blind_spots', 'Blind spots'),
      Strand('psychology.know_your_own_mind.self_deception', 'Self-deception'),
    ]),
    Genre('psychology.resist_persuasion', 'Resist persuasion', [
      Strand('psychology.resist_persuasion.social_proof', 'Social proof'),
      Strand('psychology.resist_persuasion.scarcity_tricks', 'Scarcity tricks'),
      Strand('psychology.resist_persuasion.authority', 'Authority'),
      Strand('psychology.resist_persuasion.framing', 'Framing'),
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
    ]),
    Genre('psychology.change_your_mind', 'Change your mind', [
      Strand('psychology.change_your_mind.being_wrong', 'Being wrong'),
      Strand('psychology.change_your_mind.backfire', 'Backfire'),
      Strand(
        'psychology.change_your_mind.updating_beliefs',
        'Updating beliefs',
      ),
      Strand('psychology.change_your_mind.steelmanning', 'Steelmanning'),
    ]),
    Genre('psychology.motivation', 'Motivation', [
      Strand('psychology.motivation.procrastination', 'Procrastination'),
      Strand('psychology.motivation.willpower_myths', 'Willpower myths'),
      Strand('psychology.motivation.goals_that_work', 'Goals that work'),
      Strand('psychology.motivation.rewards', 'Rewards'),
    ]),
  ],
  'economics': [
    Genre('economics.pricing_tricks', 'Pricing tricks', [
      Strand('economics.pricing_tricks.anchoring', 'Anchoring'),
      Strand('economics.pricing_tricks.charm_prices', 'Charm prices'),
      Strand('economics.pricing_tricks.decoy_options', 'Decoy options'),
    ]),
    Genre('economics.money_and_banks', 'Money and banks', [
      Strand('economics.money_and_banks.printing_cash', 'Printing cash'),
      Strand('economics.money_and_banks.interest', 'Interest'),
      Strand('economics.money_and_banks.digital_money', 'Digital money'),
    ]),
    Genre('economics.work_and_wages', 'Work and wages', [
      Strand('economics.work_and_wages.minimum_wage', 'Minimum wage'),
      Strand('economics.work_and_wages.gig_work', 'Gig work'),
      Strand('economics.work_and_wages.four_day_week', 'Four-day week'),
    ]),
    Genre('economics.trade_routes', 'Trade routes', [
      Strand('economics.trade_routes.container_ships', 'Container ships'),
      Strand('economics.trade_routes.silk_roads', 'Silk roads'),
      Strand('economics.trade_routes.chokepoints', 'Chokepoints'),
    ]),
    Genre('economics.crises', 'Crises', [
      Strand('economics.crises.1929', '1929'),
      Strand('economics.crises.2008', '2008'),
      Strand('economics.crises.hyperinflation', 'Hyperinflation'),
    ]),
    Genre('economics.everyday_costs', 'Everyday costs', [
      Strand('economics.everyday_costs.rent', 'Rent'),
      Strand('economics.everyday_costs.groceries', 'Groceries'),
      Strand('economics.everyday_costs.subscriptions', 'Subscriptions'),
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
    ]),
    Genre('economics.spot_a_bad_deal', 'Spot a bad deal', [
      Strand('economics.spot_a_bad_deal.fine_print', 'Fine print'),
      Strand(
        'economics.spot_a_bad_deal.too_good_to_be_true',
        'Too good to be true',
      ),
      Strand('economics.spot_a_bad_deal.fees_that_grow', 'Fees that grow'),
      Strand('economics.spot_a_bad_deal.free_is_not_free', 'Free is not free'),
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
    ]),
    Genre('economics.markets_and_hype', 'Markets and hype', [
      Strand('economics.markets_and_hype.bubbles', 'Bubbles'),
      Strand(
        'economics.markets_and_hype.experts_forecasts',
        'Experts\' forecasts',
      ),
      Strand('economics.markets_and_hype.survivor_stories', 'Survivor stories'),
      Strand('economics.markets_and_hype.get_rich_quick', 'Get rich quick'),
    ]),
  ],
  'technology': [
    Genre('technology.where_things_come_from', 'Where things come from', [
      Strand('technology.where_things_come_from.chips', 'Chips'),
      Strand('technology.where_things_come_from.rare_metals', 'Rare metals'),
      Strand('technology.where_things_come_from.factories', 'Factories'),
    ]),
    Genre('technology.the_internet', 'The internet', [
      Strand('technology.the_internet.cables', 'Cables'),
      Strand('technology.the_internet.dns', 'DNS'),
      Strand('technology.the_internet.data_centres', 'Data centres'),
    ]),
    Genre('technology.screens', 'Screens', [
      Strand('technology.screens.oled', 'OLED'),
      Strand('technology.screens.refresh_rates', 'Refresh rates'),
      Strand('technology.screens.touch', 'Touch'),
    ]),
    Genre('technology.batteries', 'Batteries', [
      Strand('technology.batteries.lithium', 'Lithium'),
      Strand('technology.batteries.charging', 'Charging'),
      Strand('technology.batteries.recycling', 'Recycling'),
    ]),
    Genre('technology.old_machines', 'Old machines', [
      Strand('technology.old_machines.typewriters', 'Typewriters'),
      Strand('technology.old_machines.telephones', 'Telephones'),
      Strand('technology.old_machines.mainframes', 'Mainframes'),
    ]),
    Genre('technology.ai', 'AI', [
      Strand('technology.ai.training', 'Training'),
      Strand('technology.ai.chatbots', 'Chatbots'),
      Strand('technology.ai.limits', 'Limits'),
    ]),
    Genre('technology.think_about_tech', 'Think about tech', [
      Strand('technology.think_about_tech.hype_cycles', 'Hype cycles'),
      Strand('technology.think_about_tech.who_profits', 'Who profits'),
      Strand(
        'technology.think_about_tech.attention_economy',
        'Attention economy',
      ),
      Strand('technology.think_about_tech.defaults', 'Defaults'),
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
    ]),
    Genre('technology.using_ai_well', 'Using AI well', [
      Strand('technology.using_ai_well.when_ai_is_wrong', 'When AI is wrong'),
      Strand('technology.using_ai_well.asking_well', 'Asking well'),
      Strand(
        'technology.using_ai_well.thinking_for_yourself',
        'Thinking for yourself',
      ),
    ]),
  ],
  'history': [
    Genre('history.ancient_rome', 'Ancient Rome', [
      Strand('history.ancient_rome.roads', 'Roads'),
      Strand('history.ancient_rome.daily_rome', 'Daily Rome'),
      Strand('history.ancient_rome.the_fall', 'The fall'),
    ]),
    Genre('history.middle_ages', 'Middle Ages', [
      Strand('history.middle_ages.cathedrals', 'Cathedrals'),
      Strand('history.middle_ages.plague', 'Plague'),
      Strand('history.middle_ages.guilds', 'Guilds'),
    ]),
    Genre('history.empires', 'Empires', [
      Strand('history.empires.ottoman', 'Ottoman'),
      Strand('history.empires.mongol', 'Mongol'),
      Strand('history.empires.british', 'British'),
    ]),
    Genre('history.everyday_life', 'Everyday life', [
      Strand('history.everyday_life.food', 'Food'),
      Strand('history.everyday_life.clothes', 'Clothes'),
      Strand('history.everyday_life.hygiene', 'Hygiene'),
    ]),
    Genre('history.revolutions', 'Revolutions', [
      Strand('history.revolutions.france', 'France'),
      Strand('history.revolutions.industrial', 'Industrial'),
      Strand('history.revolutions.1848', '1848'),
    ]),
    Genre('history.maps_and_borders', 'Maps and borders', [
      Strand('history.maps_and_borders.straight_lines', 'Straight lines'),
      Strand('history.maps_and_borders.lost_countries', 'Lost countries'),
      Strand('history.maps_and_borders.old_maps', 'Old maps'),
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
      ],
    ),
    Genre('history.propaganda', 'Propaganda', [
      Strand('history.propaganda.posters_and_slogans', 'Posters and slogans'),
      Strand('history.propaganda.rewriting_the_past', 'Rewriting the past'),
      Strand('history.propaganda.enemies_made_up', 'Enemies made up'),
    ]),
  ],
  'human_body': [
    Genre('human_body.the_brain', 'The brain', [
      Strand('human_body.the_brain.neurons', 'Neurons'),
      Strand('human_body.the_brain.left_and_right', 'Left and right'),
      Strand('human_body.the_brain.plasticity', 'Plasticity'),
    ]),
    Genre('human_body.blood_and_heart', 'Blood and heart', [
      Strand('human_body.blood_and_heart.blood_types', 'Blood types'),
      Strand('human_body.blood_and_heart.heartbeat', 'Heartbeat'),
      Strand('human_body.blood_and_heart.circulation', 'Circulation'),
    ]),
    Genre('human_body.skin_and_bone', 'Skin and bone', [
      Strand('human_body.skin_and_bone.healing', 'Healing'),
      Strand('human_body.skin_and_bone.fingerprints', 'Fingerprints'),
      Strand('human_body.skin_and_bone.bone_strength', 'Bone strength'),
    ]),
    Genre('human_body.senses', 'Senses', [
      Strand('human_body.senses.taste', 'Taste'),
      Strand('human_body.senses.smell', 'Smell'),
      Strand('human_body.senses.balance', 'Balance'),
    ]),
    Genre('human_body.gut', 'Gut', [
      Strand('human_body.gut.microbiome', 'Microbiome'),
      Strand('human_body.gut.digestion', 'Digestion'),
      Strand('human_body.gut.gut_and_mood', 'Gut and mood'),
    ]),
    Genre('human_body.ageing', 'Ageing', [
      Strand('human_body.ageing.telomeres', 'Telomeres'),
      Strand('human_body.ageing.grey_hair', 'Grey hair'),
      Strand('human_body.ageing.longevity', 'Longevity'),
    ]),
    Genre('human_body.health_claims', 'Health claims', [
      Strand('human_body.health_claims.miracle_cures', 'Miracle cures'),
      Strand('human_body.health_claims.supplements', 'Supplements'),
      Strand('human_body.health_claims.wellness_trends', 'Wellness trends'),
      Strand('human_body.health_claims.studies_on_mice', 'Studies on mice'),
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
    ]),
  ],
  'philosophy': [
    Genre('philosophy.ethics', 'Ethics', [
      Strand('philosophy.ethics.trolley_problems', 'Trolley problems'),
      Strand('philosophy.ethics.duty', 'Duty'),
      Strand('philosophy.ethics.virtue', 'Virtue'),
    ]),
    Genre('philosophy.knowledge', 'Knowledge', [
      Strand('philosophy.knowledge.certainty', 'Certainty'),
      Strand('philosophy.knowledge.science', 'Science'),
      Strand('philosophy.knowledge.doubt', 'Doubt'),
    ]),
    Genre('philosophy.time', 'Time', [
      Strand('philosophy.time.arrow_of_time', 'Arrow of time'),
      Strand('philosophy.time.presentism', 'Presentism'),
      Strand('philosophy.time.eternity', 'Eternity'),
    ]),
    Genre('philosophy.free_will', 'Free will', [
      Strand('philosophy.free_will.determinism', 'Determinism'),
      Strand('philosophy.free_will.choice', 'Choice'),
      Strand('philosophy.free_will.responsibility', 'Responsibility'),
    ]),
    Genre('philosophy.ancient_thinkers', 'Ancient thinkers', [
      Strand('philosophy.ancient_thinkers.socrates', 'Socrates'),
      Strand('philosophy.ancient_thinkers.stoics', 'Stoics'),
      Strand('philosophy.ancient_thinkers.eastern', 'Eastern'),
    ]),
    Genre('philosophy.paradoxes', 'Paradoxes', [
      Strand('philosophy.paradoxes.ship_of_theseus', 'Ship of Theseus'),
      Strand('philosophy.paradoxes.zeno', 'Zeno'),
      Strand('philosophy.paradoxes.liar', 'Liar'),
    ]),
    Genre('philosophy.arguments', 'Arguments', [
      Strand('philosophy.arguments.good_arguments', 'Good arguments'),
      Strand('philosophy.arguments.fallacies', 'Fallacies'),
      Strand('philosophy.arguments.hidden_premises', 'Hidden premises'),
      Strand('philosophy.arguments.thought_experiments', 'Thought experiments'),
    ]),
    Genre('philosophy.living_well', 'Living well', [
      Strand('philosophy.living_well.happiness', 'Happiness'),
      Strand('philosophy.living_well.meaning', 'Meaning'),
      Strand('philosophy.living_well.stoic_tools', 'Stoic tools'),
    ]),
  ],
  'pop_culture': [
    Genre('pop_culture.logos_and_brands', 'Logos and brands', [
      Strand('pop_culture.logos_and_brands.swooshes', 'Swooshes'),
      Strand('pop_culture.logos_and_brands.rebrands', 'Rebrands'),
      Strand('pop_culture.logos_and_brands.colours', 'Colours'),
    ]),
    Genre('pop_culture.internet_culture', 'Internet culture', [
      Strand('pop_culture.internet_culture.memes', 'Memes'),
      Strand('pop_culture.internet_culture.forums', 'Forums'),
      Strand('pop_culture.internet_culture.virality', 'Virality'),
    ]),
    Genre('pop_culture.fashion', 'Fashion', [
      Strand('pop_culture.fashion.denim', 'Denim'),
      Strand('pop_culture.fashion.sneakers', 'Sneakers'),
      Strand('pop_culture.fashion.fast_fashion', 'Fast fashion'),
    ]),
    Genre('pop_culture.tv', 'TV', [
      Strand('pop_culture.tv.sitcoms', 'Sitcoms'),
      Strand('pop_culture.tv.reality', 'Reality'),
      Strand('pop_culture.tv.streaming', 'Streaming'),
    ]),
    Genre('pop_culture.fame', 'Fame', [
      Strand('pop_culture.fame.celebrity', 'Celebrity'),
      Strand('pop_culture.fame.tabloids', 'Tabloids'),
      Strand('pop_culture.fame.fan_clubs', 'Fan clubs'),
    ]),
    Genre('pop_culture.nineties', 'Nineties', [
      Strand('pop_culture.nineties.gadgets', 'Gadgets'),
      Strand('pop_culture.nineties.music', 'Music'),
      Strand('pop_culture.nineties.style', 'Style'),
    ]),
    Genre('pop_culture.behind_the_hype', 'Behind the hype', [
      Strand(
        'pop_culture.behind_the_hype.manufactured_fame',
        'Manufactured fame',
      ),
      Strand('pop_culture.behind_the_hype.trends', 'Trends'),
      Strand('pop_culture.behind_the_hype.fake_reviews', 'Fake reviews'),
    ]),
  ],
  'nature': [
    Genre('nature.trees_and_forests', 'Trees and forests', [
      Strand('nature.trees_and_forests.root_networks', 'Root networks'),
      Strand('nature.trees_and_forests.ancient_trees', 'Ancient trees'),
      Strand('nature.trees_and_forests.rainforests', 'Rainforests'),
    ]),
    Genre('nature.animal_senses', 'Animal senses', [
      Strand('nature.animal_senses.echolocation', 'Echolocation'),
      Strand('nature.animal_senses.magnetic_sense', 'Magnetic sense'),
      Strand('nature.animal_senses.night_vision', 'Night vision'),
    ]),
    Genre('nature.oceans', 'Oceans', [
      Strand('nature.oceans.deep_sea', 'Deep sea'),
      Strand('nature.oceans.currents', 'Currents'),
      Strand('nature.oceans.coral', 'Coral'),
    ]),
    Genre('nature.weather', 'Weather', [
      Strand('nature.weather.storms', 'Storms'),
      Strand('nature.weather.clouds', 'Clouds'),
      Strand('nature.weather.forecasting', 'Forecasting'),
    ]),
    Genre('nature.insects', 'Insects', [
      Strand('nature.insects.bees', 'Bees'),
      Strand('nature.insects.ants', 'Ants'),
      Strand('nature.insects.migration', 'Migration'),
    ]),
    Genre('nature.extinction', 'Extinction', [
      Strand('nature.extinction.dinosaurs', 'Dinosaurs'),
      Strand('nature.extinction.recent_losses', 'Recent losses'),
      Strand('nature.extinction.bringing_back', 'Bringing back'),
    ]),
    Genre('nature.systems_thinking', 'Systems thinking', [
      Strand('nature.systems_thinking.feedback_loops', 'Feedback loops'),
      Strand('nature.systems_thinking.tipping_points', 'Tipping points'),
      Strand('nature.systems_thinking.chain_reactions', 'Chain reactions'),
    ]),
    Genre('nature.nature_myths', 'Nature myths', [
      Strand('nature.nature_myths.animal_myths', 'Animal myths'),
      Strand('nature.nature_myths.natural_is_better', 'Natural is better'),
      Strand('nature.nature_myths.balance_of_nature', 'Balance of nature'),
    ]),
  ],
  'language': [
    Genre('language.word_origins', 'Word origins', [
      Strand('language.word_origins.latin_roots', 'Latin roots'),
      Strand('language.word_origins.borrowed_words', 'Borrowed words'),
      Strand('language.word_origins.brand_names', 'Brand names'),
    ]),
    Genre('language.writing_systems', 'Writing systems', [
      Strand('language.writing_systems.alphabets', 'Alphabets'),
      Strand(
        'language.writing_systems.chinese_characters',
        'Chinese characters',
      ),
      Strand('language.writing_systems.lost_scripts', 'Lost scripts'),
    ]),
    Genre('language.accents', 'Accents', [
      Strand('language.accents.how_they_form', 'How they form'),
      Strand('language.accents.dialects', 'Dialects'),
      Strand('language.accents.prestige_accents', 'Prestige accents'),
    ]),
    Genre('language.untranslatable_words', 'Untranslatable words', [
      Strand('language.untranslatable_words.japanese', 'Japanese'),
      Strand('language.untranslatable_words.nordic', 'Nordic'),
      Strand('language.untranslatable_words.italian', 'Italian'),
    ]),
    Genre('language.grammar_oddities', 'Grammar oddities', [
      Strand('language.grammar_oddities.irregular_verbs', 'Irregular verbs'),
      Strand('language.grammar_oddities.double_negatives', 'Double negatives'),
      Strand('language.grammar_oddities.gendered_nouns', 'Gendered nouns'),
    ]),
    Genre('language.slang', 'Slang', [
      Strand('language.slang.internet_slang', 'Internet slang'),
      Strand('language.slang.regional_slang', 'Regional slang'),
      Strand('language.slang.old_slang', 'Old slang'),
    ]),
    Genre('language.words_that_persuade', 'Words that persuade', [
      Strand('language.words_that_persuade.loaded_words', 'Loaded words'),
      Strand('language.words_that_persuade.euphemisms', 'Euphemisms'),
      Strand('language.words_that_persuade.spin', 'Spin'),
      Strand('language.words_that_persuade.great_speeches', 'Great speeches'),
    ]),
    Genre('language.say_it_clearly', 'Say it clearly', [
      Strand('language.say_it_clearly.plain_words', 'Plain words'),
      Strand('language.say_it_clearly.arguing_well', 'Arguing well'),
      Strand('language.say_it_clearly.listening', 'Listening'),
    ]),
  ],
  'weird_facts': [
    Genre('weird_facts.animal_oddities', 'Animal oddities', [
      Strand('weird_facts.animal_oddities.wombats', 'Wombats'),
      Strand('weird_facts.animal_oddities.octopuses', 'Octopuses'),
      Strand('weird_facts.animal_oddities.axolotls', 'Axolotls'),
    ]),
    Genre('weird_facts.records', 'Records', [
      Strand('weird_facts.records.tallest', 'Tallest'),
      Strand('weird_facts.records.fastest', 'Fastest'),
      Strand('weird_facts.records.oldest', 'Oldest'),
    ]),
    Genre('weird_facts.strange_laws', 'Strange laws', [
      Strand(
        'weird_facts.strange_laws.still_on_the_books',
        'Still on the books',
      ),
      Strand('weird_facts.strange_laws.local_bans', 'Local bans'),
      Strand('weird_facts.strange_laws.odd_fines', 'Odd fines'),
    ]),
    Genre('weird_facts.coincidences', 'Coincidences', [
      Strand('weird_facts.coincidences.twins', 'Twins'),
      Strand('weird_facts.coincidences.dates', 'Dates'),
      Strand('weird_facts.coincidences.names', 'Names'),
    ]),
    Genre('weird_facts.body_oddities', 'Body oddities', [
      Strand('weird_facts.body_oddities.hiccups', 'Hiccups'),
      Strand('weird_facts.body_oddities.sneezes', 'Sneezes'),
      Strand('weird_facts.body_oddities.goosebumps', 'Goosebumps'),
    ]),
    Genre('weird_facts.odd_places', 'Odd places', [
      Strand('weird_facts.odd_places.ghost_towns', 'Ghost towns'),
      Strand('weird_facts.odd_places.tiny_nations', 'Tiny nations'),
      Strand('weird_facts.odd_places.extreme_spots', 'Extreme spots'),
    ]),
    Genre('weird_facts.too_strange_to_be_true', 'Too strange to be true', [
      Strand(
        'weird_facts.too_strange_to_be_true.myths_that_spread',
        'Myths that spread',
      ),
      Strand('weird_facts.too_strange_to_be_true.hoaxes', 'Hoaxes'),
      Strand('weird_facts.too_strange_to_be_true.how_to_check', 'How to check'),
    ]),
  ],
  'sport': [
    Genre('sport.rules_and_why', 'Rules and why', [
      Strand('sport.rules_and_why.offside', 'Offside'),
      Strand('sport.rules_and_why.fouls', 'Fouls'),
      Strand('sport.rules_and_why.scoring', 'Scoring'),
    ]),
    Genre('sport.records', 'Records', [
      Strand('sport.records.sprint', 'Sprint'),
      Strand('sport.records.marathon', 'Marathon'),
      Strand('sport.records.swimming', 'Swimming'),
    ]),
    Genre('sport.training', 'Training', [
      Strand('sport.training.recovery', 'Recovery'),
      Strand('sport.training.altitude', 'Altitude'),
      Strand('sport.training.diet', 'Diet'),
    ]),
    Genre('sport.equipment', 'Equipment', [
      Strand('sport.equipment.shoes', 'Shoes'),
      Strand('sport.equipment.balls', 'Balls'),
      Strand('sport.equipment.suits', 'Suits'),
    ]),
    Genre('sport.olympics', 'Olympics', [
      Strand('sport.olympics.ancient', 'Ancient'),
      Strand('sport.olympics.modern', 'Modern'),
      Strand('sport.olympics.hosting', 'Hosting'),
    ]),
    Genre('sport.tactics', 'Tactics', [
      Strand('sport.tactics.formations', 'Formations'),
      Strand('sport.tactics.set_pieces', 'Set pieces'),
      Strand('sport.tactics.coaching', 'Coaching'),
    ]),
    Genre('sport.luck_or_skill', 'Luck or skill', [
      Strand('sport.luck_or_skill.hot_hand', 'Hot hand'),
      Strand('sport.luck_or_skill.regression', 'Regression'),
      Strand('sport.luck_or_skill.streaks', 'Streaks'),
    ]),
    Genre('sport.sport_and_numbers', 'Sport and numbers', [
      Strand('sport.sport_and_numbers.analytics', 'Analytics'),
      Strand('sport.sport_and_numbers.bad_stats', 'Bad stats'),
      Strand('sport.sport_and_numbers.betting_odds', 'Betting odds'),
    ]),
  ],
  'cinema': [
    Genre('cinema.how_films_are_made', 'How films are made', [
      Strand('cinema.how_films_are_made.editing', 'Editing'),
      Strand('cinema.how_films_are_made.lighting', 'Lighting'),
      Strand('cinema.how_films_are_made.budgets', 'Budgets'),
    ]),
    Genre('cinema.directors', 'Directors', [
      Strand('cinema.directors.kubrick', 'Kubrick'),
      Strand('cinema.directors.hitchcock', 'Hitchcock'),
      Strand('cinema.directors.new_wave', 'New wave'),
    ]),
    Genre('cinema.special_effects', 'Special effects', [
      Strand('cinema.special_effects.practical', 'Practical'),
      Strand('cinema.special_effects.cgi', 'CGI'),
      Strand('cinema.special_effects.miniatures', 'Miniatures'),
    ]),
    Genre('cinema.sound_design', 'Sound design', [
      Strand('cinema.sound_design.foley', 'Foley'),
      Strand('cinema.sound_design.silence', 'Silence'),
      Strand('cinema.sound_design.music_cues', 'Music cues'),
    ]),
    Genre('cinema.box_office', 'Box office', [
      Strand('cinema.box_office.flops', 'Flops'),
      Strand('cinema.box_office.hits', 'Hits'),
      Strand('cinema.box_office.marketing', 'Marketing'),
    ]),
    Genre('cinema.lost_films', 'Lost films', [
      Strand('cinema.lost_films.destroyed', 'Destroyed'),
      Strand('cinema.lost_films.rediscovered', 'Rediscovered'),
      Strand('cinema.lost_films.unfinished', 'Unfinished'),
    ]),
    Genre('cinema.how_films_persuade', 'How films persuade', [
      Strand('cinema.how_films_persuade.music_and_mood', 'Music and mood'),
      Strand('cinema.how_films_persuade.editing_tricks', 'Editing tricks'),
      Strand(
        'cinema.how_films_persuade.based_on_a_true_story',
        'Based on a true story',
      ),
    ]),
  ],
  'music': [
    Genre('music.why_songs_work', 'Why songs work', [
      Strand('music.why_songs_work.hooks', 'Hooks'),
      Strand('music.why_songs_work.chord_loops', 'Chord loops'),
      Strand('music.why_songs_work.rhythm', 'Rhythm'),
    ]),
    Genre('music.instruments', 'Instruments', [
      Strand('music.instruments.piano', 'Piano'),
      Strand('music.instruments.guitar', 'Guitar'),
      Strand('music.instruments.strange_ones', 'Strange ones'),
    ]),
    Genre('music.studio_tricks', 'Studio tricks', [
      Strand('music.studio_tricks.reverb', 'Reverb'),
      Strand('music.studio_tricks.autotune', 'Autotune'),
      Strand('music.studio_tricks.layering', 'Layering'),
    ]),
    Genre('music.genres', 'Genres', [
      Strand('music.genres.jazz', 'Jazz'),
      Strand('music.genres.techno', 'Techno'),
      Strand('music.genres.folk', 'Folk'),
    ]),
    Genre('music.composers', 'Composers', [
      Strand('music.composers.bach', 'Bach'),
      Strand('music.composers.mozart', 'Mozart'),
      Strand('music.composers.film_scores', 'Film scores'),
    ]),
    Genre('music.sound_itself', 'Sound itself', [
      Strand('music.sound_itself.frequencies', 'Frequencies'),
      Strand('music.sound_itself.acoustics', 'Acoustics'),
      Strand('music.sound_itself.silence', 'Silence'),
    ]),
    Genre('music.why_we_like_what_we_like', 'Why we like what we like', [
      Strand('music.why_we_like_what_we_like.familiarity', 'Familiarity'),
      Strand(
        'music.why_we_like_what_we_like.taste_and_status',
        'Taste and status',
      ),
      Strand('music.why_we_like_what_we_like.earworms', 'Earworms'),
    ]),
  ],
  'art': [
    Genre('art.colour_and_pigment', 'Colour and pigment', [
      Strand('art.colour_and_pigment.ultramarine', 'Ultramarine'),
      Strand('art.colour_and_pigment.mummy_brown', 'Mummy brown'),
      Strand('art.colour_and_pigment.synthetics', 'Synthetics'),
    ]),
    Genre('art.renaissance', 'Renaissance', [
      Strand('art.renaissance.florence', 'Florence'),
      Strand('art.renaissance.patrons', 'Patrons'),
      Strand('art.renaissance.perspective', 'Perspective'),
    ]),
    Genre('art.modern_art', 'Modern art', [
      Strand('art.modern_art.cubism', 'Cubism'),
      Strand('art.modern_art.abstraction', 'Abstraction'),
      Strand('art.modern_art.pop', 'Pop'),
    ]),
    Genre('art.sculpture', 'Sculpture', [
      Strand('art.sculpture.marble', 'Marble'),
      Strand('art.sculpture.bronze', 'Bronze'),
      Strand('art.sculpture.lost_colour', 'Lost colour'),
    ]),
    Genre('art.photography', 'Photography', [
      Strand('art.photography.first_photos', 'First photos'),
      Strand('art.photography.darkroom', 'Darkroom'),
      Strand('art.photography.digital', 'Digital'),
    ]),
    Genre('art.forgeries', 'Forgeries', [
      Strand('art.forgeries.famous_fakes', 'Famous fakes'),
      Strand('art.forgeries.detection', 'Detection'),
      Strand('art.forgeries.motives', 'Motives'),
    ]),
    Genre('art.what_makes_it_valuable', 'What makes it valuable', [
      Strand('art.what_makes_it_valuable.price_and_value', 'Price and value'),
      Strand('art.what_makes_it_valuable.hype_in_art', 'Hype in art'),
      Strand(
        'art.what_makes_it_valuable.seeing_for_yourself',
        'Seeing for yourself',
      ),
    ]),
  ],
  'medicine': [
    Genre('medicine.vaccines', 'Vaccines', [
      Strand('medicine.vaccines.how_they_work', 'How they work'),
      Strand('medicine.vaccines.cold_chain', 'Cold chain'),
      Strand('medicine.vaccines.doubt', 'Doubt'),
    ]),
    Genre('medicine.antibiotics', 'Antibiotics', [
      Strand('medicine.antibiotics.penicillin', 'Penicillin'),
      Strand('medicine.antibiotics.resistance', 'Resistance'),
      Strand('medicine.antibiotics.new_ones', 'New ones'),
    ]),
    Genre('medicine.surgery', 'Surgery', [
      Strand('medicine.surgery.anaesthesia', 'Anaesthesia'),
      Strand('medicine.surgery.transplants', 'Transplants'),
      Strand('medicine.surgery.robots', 'Robots'),
    ]),
    Genre('medicine.pain', 'Pain', [
      Strand('medicine.pain.chronic', 'Chronic'),
      Strand('medicine.pain.painkillers', 'Painkillers'),
      Strand('medicine.pain.placebo', 'Placebo'),
    ]),
    Genre('medicine.diagnosis', 'Diagnosis', [
      Strand('medicine.diagnosis.scans', 'Scans'),
      Strand('medicine.diagnosis.blood_tests', 'Blood tests'),
      Strand('medicine.diagnosis.symptoms', 'Symptoms'),
    ]),
    Genre('medicine.medical_history', 'Medical history', [
      Strand('medicine.medical_history.barbers', 'Barbers'),
      Strand('medicine.medical_history.germ_theory', 'Germ theory'),
      Strand('medicine.medical_history.hospitals', 'Hospitals'),
    ]),
    Genre('medicine.judge_a_treatment', 'Judge a treatment', [
      Strand('medicine.judge_a_treatment.placebo_or_real', 'Placebo or real'),
      Strand('medicine.judge_a_treatment.risk_numbers', 'Risk numbers'),
      Strand('medicine.judge_a_treatment.side_effects', 'Side effects'),
      Strand('medicine.judge_a_treatment.screening', 'Screening'),
    ]),
    Genre('medicine.medical_myths', 'Medical myths', [
      Strand('medicine.medical_myths.old_wives_tales', 'Old wives\' tales'),
      Strand('medicine.medical_myths.online_diagnosis', 'Online diagnosis'),
      Strand('medicine.medical_myths.detox', 'Detox'),
    ]),
  ],
  'food': [
    Genre('food.bread_and_baking', 'Bread and baking', [
      Strand('food.bread_and_baking.sourdough', 'Sourdough'),
      Strand('food.bread_and_baking.yeast', 'Yeast'),
      Strand('food.bread_and_baking.crust', 'Crust'),
    ]),
    Genre('food.coffee', 'Coffee', [
      Strand('food.coffee.roasting', 'Roasting'),
      Strand('food.coffee.espresso', 'Espresso'),
      Strand('food.coffee.origins', 'Origins'),
    ]),
    Genre('food.fermentation', 'Fermentation', [
      Strand('food.fermentation.cheese', 'Cheese'),
      Strand('food.fermentation.kimchi', 'Kimchi'),
      Strand('food.fermentation.beer', 'Beer'),
    ]),
    Genre('food.spices', 'Spices', [
      Strand('food.spices.pepper', 'Pepper'),
      Strand('food.spices.saffron', 'Saffron'),
      Strand('food.spices.chilli', 'Chilli'),
    ]),
    Genre('food.cooking_science', 'Cooking science', [
      Strand('food.cooking_science.maillard', 'Maillard'),
      Strand('food.cooking_science.emulsions', 'Emulsions'),
      Strand('food.cooking_science.salt', 'Salt'),
    ]),
    Genre('food.food_history', 'Food history', [
      Strand('food.food_history.pasta', 'Pasta'),
      Strand('food.food_history.sugar', 'Sugar'),
      Strand('food.food_history.potatoes', 'Potatoes'),
    ]),
    Genre('food.food_claims', 'Food claims', [
      Strand('food.food_claims.superfoods', 'Superfoods'),
      Strand('food.food_claims.labels', 'Labels'),
      Strand('food.food_claims.diet_studies', 'Diet studies'),
    ]),
  ],
  'life': [
    Genre('life.habits', 'Habits', [
      Strand('life.habits.routines', 'Routines'),
      Strand('life.habits.deep_work', 'Deep work'),
      Strand('life.habits.screens', 'Screens'),
    ]),
    Genre('life.decisions', 'Decisions', [
      Strand('life.decisions.big_choices', 'Big choices'),
      Strand('life.decisions.regret', 'Regret'),
      Strand('life.decisions.risk_taking', 'Risk-taking'),
    ]),
    Genre('life.money_and_time', 'Money and time', [
      Strand('life.money_and_time.saving', 'Saving'),
      Strand('life.money_and_time.spending', 'Spending'),
      Strand('life.money_and_time.time', 'Time'),
    ]),
    Genre('life.people', 'People', [
      Strand('life.people.friendship', 'Friendship'),
      Strand('life.people.conversation', 'Conversation'),
      Strand('life.people.kindness', 'Kindness'),
    ]),
    Genre('life.growth', 'Growth', [
      Strand('life.growth.failure', 'Failure'),
      Strand('life.growth.learning', 'Learning'),
      Strand('life.growth.limits', 'Limits'),
    ]),
    Genre('life.meaning', 'Meaning', [
      Strand('life.meaning.purpose', 'Purpose'),
      Strand('life.meaning.gratitude', 'Gratitude'),
      Strand('life.meaning.mortality', 'Mortality'),
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
    ]),
    Genre('life.clear_thinking', 'Clear thinking', [
      Strand('life.clear_thinking.pros_and_cons', 'Pros and cons'),
      Strand(
        'life.clear_thinking.second_order_effects',
        'Second-order effects',
      ),
      Strand('life.clear_thinking.inversion', 'Inversion'),
      Strand('life.clear_thinking.reversible_or_not', 'Reversible or not'),
    ]),
    Genre('life.learn_anything', 'Learn anything', [
      Strand('life.learn_anything.practice_that_works', 'Practice that works'),
      Strand(
        'life.learn_anything.learning_from_mistakes',
        'Learning from mistakes',
      ),
      Strand('life.learn_anything.reading_well', 'Reading well'),
      Strand('life.learn_anything.teaching_it_back', 'Teaching it back'),
    ]),
    Genre('life.handle_setbacks', 'Handle setbacks', [
      Strand('life.handle_setbacks.reframing', 'Reframing'),
      Strand('life.handle_setbacks.what_you_control', 'What you control'),
      Strand('life.handle_setbacks.failing_forward', 'Failing forward'),
      Strand('life.handle_setbacks.comparison', 'Comparison'),
    ]),
    Genre('life.time_and_attention', 'Time and attention', [
      Strand('life.time_and_attention.saying_no', 'Saying no'),
      Strand('life.time_and_attention.deep_focus', 'Deep focus'),
      Strand('life.time_and_attention.priorities', 'Priorities'),
      Strand('life.time_and_attention.rest', 'Rest'),
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
