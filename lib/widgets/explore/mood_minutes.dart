import 'package:flutter/material.dart';

import '../../analytics.dart';
import '../../data/explore_mix.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../state/explore_play.dart';
import '../../theme.dart';
import '../subject_icon.dart';
import 'parts.dart';

/// Your mood, your minutes — artboard 140b.
///
/// A tone and the time there is, and the shelf under them fills to fit:
/// one card for a minute, a handful for five, a sitting for fifteen. Curious
/// is wonder, serious is the sober cards, light is the playful ones, tough is
/// the hardest. Nothing here is the reader's own deck: the cards are dealt
/// from everything, for the day, the way every shelf down here is.
class MoodMinutes extends StatelessWidget {
  const MoodMinutes({
    super.key,
    required this.cardsFor,
    required this.isRead,
    required this.onOpen,
    this.onShown,
  });

  /// The cards for a tone and a number of minutes.
  final List<Pill> Function(Tone tone, int minutes) cardsFor;
  final bool Function(Pill) isRead;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ExplorePlay.instance,
      builder: (context, _) {
        final play = ExplorePlay.instance;
        final int toneAt = (play['mood.tone'] as num?)?.toInt() ?? 0;
        final int timeAt = (play['mood.time'] as num?)?.toInt() ?? 1;
        final Tone tone = Tone.values[toneAt.clamp(0, Tone.values.length - 1)];
        final int minutes =
            kMinutesYouHave[timeAt.clamp(0, kMinutesYouHave.length - 1)];
        final List<Pill> cards = cardsFor(tone, minutes);
        final int spent = cards.fold(0, (s, p) => s + minutesFor(p));
        final l = context.l10n;
        final Color ink = context.p.ink;
        for (final p in cards) {
          onShown?.call(p);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ink.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.moodTitle,
                    style: AppText.display(
                      size: 23,
                      weight: FontWeight.w600,
                      height: 1.15,
                      spacing: -0.5,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Kicker(l.moodTone),
                  const SizedBox(height: 8),
                  Segments(
                    keyPrefix: 'tone',
                    labels: [
                      l.toneCurious,
                      l.toneSerious,
                      l.toneLight,
                      l.toneTough,
                    ],
                    selected: toneAt,
                    onPick: (i) {
                      Analytics.capture('explore mood', {
                        'tone': Tone.values[i].name,
                      });
                      play.put('mood.tone', i);
                    },
                  ),
                  const SizedBox(height: 14),
                  Kicker(l.moodTime),
                  const SizedBox(height: 8),
                  Segments(
                    keyPrefix: 'time',
                    labels: [
                      for (final m in kMinutesYouHave) l.minutesLabel(m),
                    ],
                    selected: timeAt,
                    onPick: (i) {
                      Analytics.capture('explore minutes', {
                        'minutes': kMinutesYouHave[i],
                      });
                      play.put('mood.time', i);
                    },
                  ),
                ],
              ),
            ),
            if (cards.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        l.forYouNow,
                        style: AppText.body(
                          size: 16,
                          weight: FontWeight.w600,
                          height: 1,
                          spacing: -0.2,
                          color: ink,
                        ),
                      ),
                    ),
                    Text(
                      l.moodMeta(cards.length, spent),
                      key: const ValueKey('mood-meta'),
                      style: AppText.body(
                        size: 12,
                        weight: FontWeight.w600,
                        height: 1,
                        color: ink.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _Grid(
                    key: ValueKey('${tone.name}-$minutes'),
                    cards: cards,
                    isRead: isRead,
                    onOpen: onOpen,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The first card large, the rest two by two, an odd one out across both.
class _Grid extends StatelessWidget {
  const _Grid({
    super.key,
    required this.cards,
    required this.isRead,
    required this.onOpen,
  });

  final List<Pill> cards;
  final bool Function(Pill) isRead;
  final void Function(List<Pill>, Pill) onOpen;

  @override
  Widget build(BuildContext context) {
    final List<Pill> rest = cards.skip(1).toList();
    final rows = <List<Pill>>[];
    for (int i = 0; i < rest.length; i += 2) {
      rows.add(rest.sublist(i, (i + 2).clamp(0, rest.length)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 220, child: _tile(context, cards.first, hero: true)),
        for (final row in rows) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int k = 0; k < row.length; k++) ...[
                  if (k > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _tile(context, row[k], wide: row.length == 1),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _tile(
    BuildContext context,
    Pill p, {
    bool hero = false,
    bool wide = false,
  }) {
    return CardTap(
      pill: p,
      onTap: () => onOpen(cards, p),
      child: Container(
        padding: EdgeInsets.all(hero ? 18 : 15),
        decoration: BoxDecoration(
          color: p.color,
          borderRadius: BorderRadius.circular(hero ? 22 : 20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hero)
              CardHead(
                pill: p,
                trailing: isRead(p) ? ReadMark(pill: p) : null,
              )
            else
              Row(
                children: [
                  SubjectIcon(subject: p.topic, size: 15, ink: p.ink),
                  const Spacer(),
                  if (isRead(p)) ReadMark(pill: p, size: 13),
                ],
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: hero ? 12 : 10, bottom: 8),
                child: CardQuestion(
                  text: p.question,
                  color: p.ink,
                  min: 11,
                  max: hero ? 22 : (wide ? 18 : 15.5),
                  height: hero ? 1.12 : 1.15,
                  tracking: hero ? -0.032 : -0.027,
                ),
              ),
            ),
            Text(
              context.l10n.minutesShort(minutesFor(p)),
              style: AppText.label(
                size: 9,
                weight: FontWeight.w700,
                spacing: 1.2,
                color: p.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
