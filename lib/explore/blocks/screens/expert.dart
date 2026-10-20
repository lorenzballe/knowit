/// Think like an expert — artboard 140a.
///
/// The expert who turns up between the cat videos and explains a why, made
/// into a shelf: pick an expert, see the one question they always ask, and
/// the cards that need it. The question is the thing to carry away — it
/// works on cards nobody has written yet — so it is set large, in quotation
/// marks, above the cards rather than on them.
///
/// Five experts come with the build, each with their question in every
/// language and the cards they are drawn to: the statistician to base rates
/// and samples, the economist to who pays, the historian to what people
/// knew then, the doctor to the body and its medicine, the scientist to how
/// a claim is tested. A section can name fewer of them, change what one
/// says, or bring its own, with its own words and its own source of cards.
library;

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/balanced_text.dart';
import '../../explore_block.dart';
import 'memory.dart';
import 'parts.dart';

/// How many cards an expert is looked for among, when the section gives no
/// source of its own for them.
const int kExpertPool = 240;

/// The principles a statistician is drawn to: every one that is a question
/// about a number's sample, its base or its comparison.
const Set<Principle> _statistics = {
  Principle.baseRate,
  Principle.survivorship,
  Principle.regression,
  Principle.sampling,
  Principle.confounding,
  Principle.counterfactual,
  Principle.multipleComparisons,
  Principle.conditional,
  Principle.independence,
  Principle.coincidence,
  Principle.simpson,
  Principle.conjunction,
};

const Set<String> _oldEras = {
  'ancient',
  'medieval',
  'early_modern',
  'nineteenth',
};

/// One expert as a section shows them.
@immutable
class ScreenExpert {
  const ScreenExpert({
    required this.id,
    required this.name,
    required this.kicker,
    required this.question,
    required this.mark,
    this.fits,
    this.source,
  });

  final String id;

  /// On the chip.
  final String name;

  /// Over the question: "Think like a statistician".
  final String kicker;

  /// The question they always ask.
  final String question;

  /// The mark on the chip and the badge (see [markPath]).
  final String mark;

  /// Which of the section's cards are theirs; null for all of them.
  final bool Function(Pill)? fits;

  /// Their own source of cards, when the section gives one.
  final Object? source;
}

/// The experts the build carries, by id: what each is called and asks, and
/// the cards each is drawn to.
ScreenExpert? builtInExpert(String id, AppLocalizations l) => switch (id) {
  'statistician' => ScreenExpert(
    id: id,
    name: l.screensExpertStatistician,
    kicker: l.screensExpertStatisticianAs,
    question: l.screensExpertStatisticianAsks,
    mark: 'chart',
    fits: (p) => _statistics.contains(p.principle),
  ),
  'economist' => ScreenExpert(
    id: id,
    name: l.screensExpertEconomist,
    kicker: l.screensExpertEconomistAs,
    question: l.screensExpertEconomistAsks,
    mark: 'economics',
    fits: (p) =>
        p.topic == 'Economics' ||
        p.principle == Principle.sunkCost ||
        p.principle == Principle.anchoring,
  ),
  'historian' => ScreenExpert(
    id: id,
    name: l.screensExpertHistorian,
    kicker: l.screensExpertHistorianAs,
    question: l.screensExpertHistorianAsks,
    mark: 'history',
    fits: (p) =>
        p.topic == 'History' ||
        (_oldEras.contains(p.era) &&
            (p.hook == 'story' ||
                p.hook == 'origin' ||
                p.hook == 'misconception')),
  ),
  'doctor' => ScreenExpert(
    id: id,
    name: l.screensExpertDoctor,
    kicker: l.screensExpertDoctorAs,
    question: l.screensExpertDoctorAsks,
    mark: 'medicine',
    fits: (p) => p.topic == 'Medicine' || p.topic == 'Human body',
  ),
  'scientist' => ScreenExpert(
    id: id,
    name: l.screensExpertScientist,
    kicker: l.screensExpertScientistAs,
    question: l.screensExpertScientistAsks,
    mark: 'science',
    fits: (p) =>
        p.topic == 'Science' ||
        p.topic == 'Space' ||
        p.topic == 'Nature' ||
        p.principle == Principle.confirmation,
  ),
  _ => null,
};

/// The built-in experts, in the canvas's order.
const List<String> kBuiltInExperts = [
  'statistician',
  'economist',
  'historian',
  'doctor',
  'scientist',
];

/// The experts [section] asks for, each with its words in [language]: the
/// five built in when it names none; a name of one of them, or an object
/// that changes what one says; or an expert of its own, which needs its
/// name, the words over its question and the question itself. One the
/// build cannot make out is passed over, and the rest still show.
List<ScreenExpert> expertsOf(
  ExploreSection section,
  AppLocalizations l,
  String language,
) {
  final Object? raw = section.json['experts'];
  final List<Object?> items = raw is List && raw.isNotEmpty
      ? raw
      : kBuiltInExperts;
  final List<ScreenExpert> out = [];
  for (final Object? item in items) {
    ScreenExpert? expert;
    if (item is String) {
      expert = builtInExpert(item, l);
    } else if (item is Map) {
      final Object? id = item['id'];
      if (id is! String || id.isEmpty) continue;
      final ScreenExpert? base = builtInExpert(id, l);
      final String? name = itemText(item, 'name', language) ?? base?.name;
      final String? kicker = itemText(item, 'as', language) ?? base?.kicker;
      final String? question =
          itemText(item, 'question', language) ?? base?.question;
      if (name == null || kicker == null || question == null) continue;
      final Object? mark = item['mark'];
      expert = ScreenExpert(
        id: id,
        name: name,
        kicker: kicker,
        question: question,
        mark: mark is String && markPath(mark) != null
            ? mark
            : base?.mark ?? 'chart',
        fits: _fitsOf(item) ?? base?.fits,
        source: item['source'],
      );
    }
    if (expert != null && out.every((e) => e.id != expert!.id)) {
      out.add(expert);
    }
  }
  return out;
}

/// The cards an expert of a section's own is drawn to: its subjects, its
/// principles, its hooks, any of them; null when it names none.
bool Function(Pill)? _fitsOf(Map<Object?, Object?> item) {
  Set<String> words(String key) => {
    if (item[key] is List)
      for (final Object? w in item[key] as List)
        if (w is String) w,
  };
  final Set<String> subjects = words('subjects');
  final Set<String> principles = words('principles');
  final Set<String> hooks = words('hooks');
  if (subjects.isEmpty && principles.isEmpty && hooks.isEmpty) return null;
  return (p) =>
      subjects.contains(subjectKeyOf(p)) ||
      principles.contains(p.principle.name) ||
      hooks.contains(p.hook);
}

/// The block.
class ExpertBlock extends ExploreBlock {
  const ExpertBlock();

  @override
  String get name => 'expert';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final l = context.l10n;
    final int most = section.limit ?? 4;
    List<Pill>? pool;
    final List<(ScreenExpert, List<Pill>)> shown = [];
    for (final ScreenExpert e in expertsOf(section, l, host.language)) {
      final List<Pill> cards;
      if (e.source != null) {
        cards = host.cardsFor(
          ExploreSection(
            id: '${section.id}/${e.id}',
            block: name,
            json: {
              'id': '${section.id}/${e.id}',
              'block': name,
              'source': e.source,
            },
          ),
          limit: most,
        );
      } else {
        pool ??= host.cardsFor(section, limit: kExpertPool);
        cards = [
          for (final Pill p in pool)
            if (e.fits == null || e.fits!(p)) p,
        ].take(most).toList();
      }
      // A question with one card under it is a quotation, not a shelf.
      if (cards.length >= 2) shown.add((e, cards));
    }
    if (shown.isEmpty) return null;
    return host.watch(
      section,
      _ExpertShelf(host: host, section: section, experts: shown),
    );
  }
}

class _ExpertShelf extends StatelessWidget {
  const _ExpertShelf({
    required this.host,
    required this.section,
    required this.experts,
  });

  final ExploreHost host;
  final ExploreSection section;
  final List<(ScreenExpert, List<Pill>)> experts;

  @override
  Widget build(BuildContext context) {
    final ScreensMemory memory = ScreensMemory.instance..open();
    return ListenableBuilder(
      listenable: memory,
      builder: (context, _) {
        final String? kept = memory.pick(section.id);
        final Object? asked = section.json['expert'];
        int at = experts.indexWhere((e) => e.$1.id == kept);
        if (at < 0) at = experts.indexWhere((e) => e.$1.id == asked);
        if (at < 0) at = 0;
        return _view(context, at, memory);
      },
    );
  }

  Widget _view(BuildContext context, int at, ScreensMemory memory) {
    final l = context.l10n;
    final Palette p = context.p;
    final ScreenSize size = screenSizeOf(section);
    final (ScreenExpert expert, List<Pill> cards) = experts[at];
    final bool hero = size != ScreenSize.s;
    final Pill? first = hero ? cards.first : null;
    final List<Pill> row = hero ? cards.skip(1).toList() : cards;
    if (first != null) host.seen(section, first);
    void open(Pill pill) => host.open(section, cards, pill);

    return ScreenShelf(
      head: styleOn(section, 'head'),
      title: section.title(host.language) ?? l.screensExpertTitle,
      line: section.subtitle(host.language) ?? l.screensExpertLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (experts.length > 1) ...[
            ChipRow(
              height: 44,
              chips: [
                for (int i = 0; i < experts.length; i++)
                  PickChip(
                    key: ValueKey(
                      'expert-${experts[i].$1.id}-${i == at ? 'on' : 'off'}',
                    ),
                    label: experts[i].$1.name,
                    selected: i == at,
                    height: 38,
                    radius: 99,
                    size: 13,
                    padding: const EdgeInsets.fromLTRB(11, 0, 14, 0),
                    leading: (ink) => ScreenMark(
                      mark: experts[i].$1.mark,
                      size: 15,
                      ink: ink,
                    ),
                    onTap: () {
                      if (i == at) return;
                      tickPicked();
                      memory.setPick(section.id, experts[i].$1.id);
                      host.note(section, 'expert picked', {
                        'expert': experts[i].$1.id,
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          AnimatedSwitcher(
            duration: paced(context, 240),
            child: Column(
              key: ValueKey('expert-at-${expert.id}'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: p.inverse,
                              shape: BoxShape.circle,
                            ),
                            child: ScreenMark(
                              mark: expert.mark,
                              size: 20,
                              ink: p.onInverse,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              upper(context, expert.kicker),
                              style: AppText.label(
                                size: 9.5,
                                weight: FontWeight.w700,
                                spacing: 1.3,
                                height: 1.2,
                                color: p.ink.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      BalancedText(
                        l.screensQuoted(expert.question),
                        style: AppText.display(
                          size: bySize(size, s: 23, m: 27, l: 30),
                          weight: FontWeight.w600,
                          height: 1.12,
                          spacing: -0.7,
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (first != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ColourTile(
                      pill: first,
                      height: bySize(size, s: 200, m: 224, l: 260),
                      radius: 22,
                      padding: 18,
                      min: 13,
                      max: bySize(size, s: 21, m: 23, l: 26),
                      read: host.isRead(first),
                      onTap: () => open(first),
                    ),
                  ),
                  if (row.isNotEmpty) const SizedBox(height: 10),
                ],
                if (row.isNotEmpty)
                  _Row(
                    pills: row,
                    size: size,
                    isRead: host.isRead,
                    onShown: (pill) => host.seen(section, pill),
                    onOpen: open,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The expert's other cards, smaller, sideways.
class _Row extends StatelessWidget {
  const _Row({
    required this.pills,
    required this.size,
    required this.isRead,
    required this.onShown,
    required this.onOpen,
  });

  final List<Pill> pills;
  final ScreenSize size;
  final bool Function(Pill) isRead;
  final ValueChanged<Pill> onShown;
  final ValueChanged<Pill> onOpen;

  @override
  Widget build(BuildContext context) {
    final double width = bySize(size, s: 160, m: 178, l: 196);
    final double height = bySize(size, s: 180, m: 198, l: 220);
    return SizedBox(
      height: height + 4,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        itemCount: pills.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final Pill pill = pills[i];
          onShown(pill);
          return ColourTile(
            pill: pill,
            width: width,
            height: height,
            head: false,
            min: 10.5,
            max: bySize(size, s: 14, m: 15.5, l: 17),
            read: isRead(pill),
            onTap: () => onOpen(pill),
          );
        },
      ),
    );
  }
}
