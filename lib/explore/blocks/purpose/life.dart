/// Questions for your own life — the canvas's 138c.
///
/// A card is worth more when it changes a question you ask of your own
/// life. So a shelf can be set under such a question, large — am I paying
/// for what I actually use? — with the cards that ask it in other words;
/// and the reader can pick what they want better questions about, and see
/// those cards here.
library;

import 'package:flutter/material.dart';

import '../../../data/themed_shelves.dart' show shelfHash;
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/balanced_text.dart';
import '../../explore_block.dart';
import 'kit.dart';

/// A part of life to ask better questions about, by the name a section
/// gives it, with the genres its cards come from and the size the canvas
/// draws its cards at.
@immutable
class LifeTopic {
  const LifeTopic(this.name, this.genres, this.size, this.max);

  /// `money`, `work`, `time`, `body`, `relationships`, `belief`.
  final String name;

  /// The genres whose cards ask about it.
  final Set<String> genres;

  /// Its cards' size and their questions' largest size, as the canvas has
  /// them: wide cards for work and time, narrow ones for the body.
  final TileSize size;
  final double max;

  /// The name the app's strings know it by: `time` is a word their format
  /// keeps for itself.
  String get word => name == 'time' ? 'clock' : name;

  /// Whether [p] asks about it: a card of its genres, and not a story about
  /// somebody else.
  bool fits(Pill p) =>
      genres.contains(p.genre) && p.hook != 'story' && p.hook != 'origin';
}

/// Every part of life a section can name, in the order the chips show.
const List<LifeTopic> kLifeTopics = [
  LifeTopic(
    'money',
    {
      'economics.your_money_decisions',
      'economics.everyday_costs',
      'economics.spot_a_bad_deal',
      'economics.pricing_tricks',
      'life.money_and_time',
    },
    TileSize(200, 226),
    18,
  ),
  LifeTopic(
    'work',
    {
      'life.work_and_career',
      'economics.work_and_wages',
      'psychology.motivation',
      'life.habits',
      'life.learn_anything',
      'life.growth',
    },
    TileSize(250, 176),
    17.5,
  ),
  LifeTopic(
    'time',
    {
      'life.time_and_attention',
      'life.money_and_time',
      'psychology.attention',
      'psychology.habits',
      'technology.your_digital_life',
    },
    TileSize(250, 176),
    17.5,
  ),
  LifeTopic(
    'body',
    {
      'human_body.health_claims',
      'human_body.your_body_your_choices',
      'human_body.your_body_in_numbers',
      'human_body.stress_and_the_body',
      'medicine.talk_to_your_doctor',
      'medicine.judge_a_treatment',
      'medicine.medical_myths',
      'food.eat_smarter',
      'food.food_claims',
      'psychology.sleep_and_dreams',
      'sport.training',
    },
    TileSize(176, 200),
    16.5,
  ),
  LifeTopic(
    'relationships',
    {
      'life.relationships',
      'life.people',
      'psychology.other_people',
      'psychology.emotions',
      'language.body_language',
    },
    TileSize(200, 226),
    18,
  ),
  LifeTopic(
    'belief',
    {
      'life.clear_thinking',
      'life.ask_better_questions',
      'psychology.bias',
      'psychology.change_your_mind',
      'psychology.know_your_own_mind',
      'psychology.resist_persuasion',
      'philosophy.knowledge',
      'science.how_science_knows',
    },
    TileSize(290, 196),
    19,
  ),
];

/// A part of life by its name, or null for one this build does not know.
LifeTopic? lifeTopicNamed(Object? name) =>
    kLifeTopics.where((t) => t.name == name).firstOrNull;

/// The fewest cards a question needs in the pool to be asked on its own.
const int kLifeLeast = 3;

/// 138c: a question for your own life, set large over the cards that ask
/// it in other words.
class LifeQuestionBlock extends ExploreBlock {
  const LifeQuestionBlock();

  @override
  String get name => 'purpose.life-question';

  /// The sizes a section can ask for; without one, each part of life has
  /// the canvas's own.
  static const Map<String, (TileSize, double)> sizes = {
    's': (TileSize(176, 200), 16.5),
    'm': (TileSize(200, 226), 18),
    'wide': (TileSize(250, 176), 17.5),
    'l': (TileSize(290, 196), 19),
  };

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final l = context.l10n;
    final String lang = host.language;
    final List<Pill> pool = host.cardsFor(section, limit: kPurposePool);
    final Object? named = section.json['topic'];
    final LifeTopic? topic = named == null
        ? _topicFor(pool)
        : lifeTopicNamed(named);
    final String? about = section.text('about', lang);
    final String? question = section.text('question', lang);
    // A part of life this build does not know is drawn only when the
    // section says the question itself, over its source's cards as they
    // come; otherwise it is left out.
    if (topic == null && question == null) return null;
    final bool strict = fitsOnly(section) && topic != null;
    final List<Pill> cards = [
      for (final Pill p in pool)
        if (!strict || topic.fits(p)) p,
    ].take(limitOf(section, 8)).toList();
    if (cards.isEmpty) return null;
    final (TileSize, double) look =
        sizes[section.size] ??
        (topic == null ? sizes['m']! : (topic.size, topic.max));
    return host.watch(
      section,
      LifeShelf(
        about: about ?? (topic == null ? '' : l.purposeLifeAbout(topic.word)),
        question: question ?? l.purposeLifeQuestion(topic!.word),
        child: SideRow(
          height: look.$1.height + 4,
          count: cards.length,
          itemBuilder: (context, i) {
            final Pill p = cards[i];
            host.seen(section, p);
            return PlainTile(
              pill: p,
              size: look.$1,
              radius: 20,
              max: look.$2,
              read: host.isRead(p),
              onOpen: () => host.open(section, cards, p),
            );
          },
        ),
      ),
    );
  }

  /// The question a section that names none asks: one a day among the
  /// parts of life the pool has cards enough for, the same for everybody.
  static LifeTopic? _topicFor(List<Pill> pool) {
    final List<LifeTopic> asked = [
      for (final LifeTopic t in kLifeTopics)
        if (pool.where(t.fits).length >= kLifeLeast) t,
    ];
    if (asked.isEmpty) return null;
    final int day = today();
    asked.sort(
      (a, b) =>
          shelfHash('$day:life:${a.name}')
              .compareTo(shelfHash('$day:life:${b.name}')),
    );
    return asked.first;
  }
}

/// A question for your own life over its cards: what it is about, small,
/// with a rule running out from it, and the question large.
class LifeShelf extends StatelessWidget {
  const LifeShelf({
    super.key,
    required this.about,
    required this.question,
    required this.child,
  });

  final String about;
  final String question;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // What it is about, and a rule running from it to the edge: the
              // words never wider than most of the line, so the rule shows.
              LayoutBuilder(
                builder: (context, box) => Row(
                  children: [
                    if (about.isNotEmpty) ...[
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: box.maxWidth * 0.8,
                        ),
                        child: Text(
                          upper(context, about),
                          style: AppText.label(
                            size: 9.5,
                            weight: FontWeight.w700,
                            spacing: 1.3,
                            height: 1.1,
                            color: ink.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Container(
                        height: 1,
                        color: ink.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              Semantics(
                header: true,
                child: BalancedText(
                  question,
                  style: AppText.display(
                    size: 25,
                    weight: FontWeight.w600,
                    height: 1.12,
                    spacing: -0.6,
                    color: ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

/// 138c: what do you want better questions about? Chips to pick any, and
/// under them the cards that ask about what was picked.
class LifeTopicsBlock extends ExploreBlock {
  const LifeTopicsBlock();

  @override
  String get name => 'purpose.life-topics';

  /// The cards' size under the chips, by size; `m` is the canvas's money.
  static const Map<String, TileSize> sizes = {
    's': TileSize(176, 200),
    'm': TileSize(200, 226),
    'l': TileSize(230, 250),
  };

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final l = context.l10n;
    final String lang = host.language;
    final List<Pill> pool = host.cardsFor(section, limit: kPurposePool);
    final Object? named = section.json['topics'];
    final List<LifeTopic> topics = <LifeTopic>{
      for (final LifeTopic t
          in named is List
              ? [for (final Object? n in named) ?lifeTopicNamed(n)]
              : kLifeTopics)
        // A chip with nothing under it is a promise the shelf cannot keep.
        if (pool.any(t.fits)) t,
    }.toList();
    if (topics.isEmpty) return null;
    final TileSize size = sizeOf(section, sizes);
    final String key = 'life:${section.id}';
    return host.watch(
      section,
      PlayWatch<Set<String>>(
        select: () => PurposePlay.setOf(key),
        builder: (context, picked) {
          final List<LifeTopic> on = [
            for (final LifeTopic t in topics)
              if (picked.contains(t.name)) t,
          ];
          final List<Pill> cards = on.isEmpty
              ? const []
              : [
                  for (final Pill p in pool)
                    if (on.any((t) => t.fits(p))) p,
                ].take(limitOf(section, 8)).toList();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TopicPicker(
                question: wordsOf(section, 'question', lang, l.purposeLifeAsk),
                footer: wordsOf(section, 'footer', lang, l.purposeLifeFooter),
                topics: [
                  for (final LifeTopic t in topics)
                    (
                      t.name,
                      l.purposeLifeChip(t.word),
                      picked.contains(t.name),
                    ),
                ],
                onPick: (name) {
                  final Set<String> now = PurposePlay.setOf(key);
                  final bool added = now.add(name);
                  if (!added) now.remove(name);
                  PurposePlay.writeSet(key, now);
                  host.note(section, 'life topics', {
                    'topic': name,
                    'on': added,
                  });
                },
              ),
              if (cards.isNotEmpty) ...[
                const SizedBox(height: 12),
                SideRow(
                  height: size.height + 4,
                  count: cards.length,
                  itemBuilder: (context, i) {
                    final Pill p = cards[i];
                    host.seen(section, p);
                    return PlainTile(
                      pill: p,
                      size: size,
                      radius: 20,
                      read: host.isRead(p),
                      onOpen: () => host.open(section, cards, p),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// The box of chips: the question, a chip for each part of life, and the
/// line that says what picking does.
class TopicPicker extends StatelessWidget {
  const TopicPicker({
    super.key,
    required this.question,
    required this.footer,
    required this.topics,
    required this.onPick,
  });

  final String question;
  final String footer;

  /// Each chip's name, its words, and whether it is picked.
  final List<(String, String, bool)> topics;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final Palette pal = context.p;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: pal.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: AppText.display(
              size: 19,
              weight: FontWeight.w600,
              height: 1.2,
              spacing: -0.4,
              color: pal.ink,
            ),
          ),
          const SizedBox(height: 10),
          // Drawn 36 high, as the canvas draws them, in targets 44 high.
          Wrap(
            spacing: 7,
            children: [
              for (final (String name, String words, bool on) in topics)
                Semantics(
                  button: true,
                  toggled: on,
                  label: words,
                  excludeSemantics: true,
                  child: GestureDetector(
                    key: ValueKey('life-$name-${on ? 'on' : 'off'}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onPick(name),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        decoration: BoxDecoration(
                          color: on ? pal.ink : pal.ink.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        // As wide as its word: a chip, not a row.
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            words,
                            maxLines: 1,
                            style: AppText.body(
                              size: 12.5,
                              weight: FontWeight.w600,
                              height: 1,
                              color: on
                                  ? pal.surface
                                  : pal.ink.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            footer,
            style: AppText.body(
              size: 12,
              weight: FontWeight.w500,
              height: 1.4,
              color: pal.ink.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
