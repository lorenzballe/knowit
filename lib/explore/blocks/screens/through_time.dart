/// Through time — artboard 141c.
///
/// A ruler of years to travel along, one age at a time: where the reader
/// is, said large ("66 million years ago"), the ruler under it, and the
/// cards of that age under the ruler. The ruler is drawn in powers of ten,
/// each tick ten times further back than the next, because that is the only
/// way the first light and last century fit on one phone: the same drag
/// that crosses a billion years at one end crosses a lifetime at the other.
///
/// With no stops of its own, a section travels the ages the bank's cards
/// are tagged with (`era`): the ancient world, the Middle Ages, the early
/// modern age, the nineteenth century, the last one and this one. A section
/// can bring its own stops — the first light, the asteroid — each with its
/// words, how many years ago it was, and where its cards come from.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../data/explore_mix.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/balanced_text.dart';
import '../../explore_block.dart';
import 'memory.dart';
import 'parts.dart';

/// How many cards the ages are looked for among, when a stop has no source
/// of its own.
const int kTimePool = 400;

/// The ages the bank tags its cards with, oldest first.
const List<String> kBankEras = [
  'ancient',
  'medieval',
  'early_modern',
  'nineteenth',
  'twentieth',
  'recent',
];

/// One stop on the ruler, in the reader's language.
@immutable
class TimeStop {
  const TimeStop({
    required this.id,
    required this.label,
    required this.when,
    required this.ago,
    this.era,
    this.source,
  });

  final String id;

  /// What is there, in small capitals: "The asteroid".
  final String label;

  /// When, said large: "66 million years ago".
  final String when;

  /// How many years before now, which is where it sits on the ruler.
  final double ago;

  /// The bank's age its cards are tagged with, if they are found that way.
  final String? era;

  /// Its own source of cards, if it has one.
  final Object? source;
}

/// The middle year of each of the bank's ages, which is where an age sits on
/// the ruler: the ancient world at the turn of the era, since most of the
/// bank's ancient cards are Greek and Roman.
const Map<String, int> _eraYear = {
  'ancient': 0,
  'medieval': 1000,
  'early_modern': 1650,
  'nineteenth': 1850,
  'twentieth': 1950,
  'recent': 2012,
};

/// The stops of [section] in [language]: its own when it gives them, the
/// bank's ages otherwise, oldest first either way.
List<TimeStop> stopsOf(
  ExploreSection section,
  AppLocalizations l,
  String language, {
  DateTime? now,
}) {
  final int year = (now ?? DateTime.now()).year;
  final List<Map<Object?, Object?>> own = sectionItems(section, 'stops');
  if (own.isEmpty) {
    return [
      for (final String era in kBankEras)
        TimeStop(
          id: era,
          label: _eraName(l, era),
          when: _eraWhen(l, era),
          ago: math.max(1, year - _eraYear[era]!).toDouble(),
          era: era,
        ),
    ];
  }
  final List<TimeStop> out = [];
  for (final Map<Object?, Object?> s in own) {
    final Object? id = s['id'];
    final Object? ago = s['ago'];
    final Object? era = s['era'];
    if (id is! String || id.isEmpty || out.any((x) => x.id == id)) continue;
    if (ago is! num || ago < 0) continue;
    final bool tagged = era is String && kBankEras.contains(era);
    if (!tagged && s['source'] == null) continue;
    final String? label =
        itemText(s, 'label', language) ?? (tagged ? _eraName(l, era) : null);
    final String? when =
        itemText(s, 'when', language) ?? (tagged ? _eraWhen(l, era) : null);
    if (label == null || when == null) continue;
    out.add(
      TimeStop(
        id: id,
        label: label,
        when: when,
        ago: ago.toDouble(),
        era: tagged ? era : null,
        source: s['source'],
      ),
    );
  }
  out.sort((a, b) => b.ago.compareTo(a.ago));
  return out;
}

String _eraName(AppLocalizations l, String era) => switch (era) {
  'ancient' => l.screensEraAncient,
  'medieval' => l.screensEraMedieval,
  'early_modern' => l.screensEraEarlyModern,
  'nineteenth' => l.screensEraNineteenth,
  'twentieth' => l.screensEraTwentieth,
  _ => l.screensEraRecent,
};

String _eraWhen(AppLocalizations l, String era) => switch (era) {
  'ancient' => l.screensEraAncientWhen,
  'medieval' => l.screensEraMedievalWhen,
  'early_modern' => l.screensEraEarlyModernWhen,
  'nineteenth' => l.screensEraNineteenthWhen,
  'twentieth' => l.screensEraTwentiethWhen,
  _ => l.screensEraRecentWhen,
};

/// Where a stop [ago] years back sits on a ruler whose far end is [farLog]
/// powers of ten back: 0 at the far end, 1 at now.
double rulerPlace(double ago, double farLog) {
  final double log = math.log(math.max(ago, 1)) / math.ln10;
  return farLog <= 0 ? 1 : ((farLog - log) / farLog).clamp(0, 1);
}

/// The powers of ten a ruler reaching [farLog] back names under it: every
/// third one (a thousand, a million, a billion) on a long ruler, every one
/// on a short, kept clear of each other and of the two ends.
List<int> rulerLabels(double farLog) {
  final List<int> out = [];
  double? last;
  final bool long = farLog >= 6;
  for (int k = farLog.floor(); k >= 1; k--) {
    if (long && k % 3 != 0) continue;
    final double at = (farLog - k) / farLog;
    if (at < 0.15 || at > 0.85) continue;
    if (last != null && (at - last).abs() < 0.2) continue;
    out.add(k);
    last = at;
  }
  return out;
}

/// The block.
class ThroughTimeBlock extends ExploreBlock {
  const ThroughTimeBlock();

  @override
  String get name => 'through-time';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final int most = section.limit ?? 2;
    List<Pill>? pool;
    final List<(TimeStop, List<Pill>)> stops = [];
    for (final TimeStop stop in stopsOf(section, context.l10n, host.language)) {
      final Iterable<Pill> from;
      if (stop.source != null) {
        from = host.cardsFor(
          ExploreSection(
            id: '${section.id}/${stop.id}',
            block: name,
            json: {
              'id': '${section.id}/${stop.id}',
              'block': name,
              'source': stop.source,
            },
          ),
          limit: stop.era == null ? most : kTimePool,
        );
      } else {
        from = pool ??= host.cardsFor(section, limit: kTimePool);
      }
      final List<Pill> cards = [
        for (final Pill p in from)
          if (stop.era == null || p.era == stop.era) p,
      ].take(most).toList();
      if (cards.isNotEmpty) stops.add((stop, cards));
    }
    // One stop is a shelf, not a journey.
    if (stops.length < 2) return null;
    return host.watch(
      section,
      _Time(host: host, section: section, stops: stops),
    );
  }
}

class _Time extends StatelessWidget {
  const _Time({required this.host, required this.section, required this.stops});

  final ExploreHost host;
  final ExploreSection section;
  final List<(TimeStop, List<Pill>)> stops;

  @override
  Widget build(BuildContext context) {
    final ScreensMemory memory = ScreensMemory.instance..open();
    return ListenableBuilder(
      listenable: memory,
      builder: (context, _) {
        final String? kept = memory.pick(section.id);
        final Object? asked = section.json['stop'];
        int at = stops.indexWhere((s) => s.$1.id == kept);
        if (at < 0) at = stops.indexWhere((s) => s.$1.id == asked);
        if (at < 0) at = 0;
        return _view(context, at, memory);
      },
    );
  }

  void _go(ScreensMemory memory, int at, int to) {
    if (to == at || to < 0 || to >= stops.length) return;
    tickPicked();
    memory.setPick(section.id, stops[to].$1.id);
    host.note(section, 'era picked', {'stop': stops[to].$1.id});
  }

  Widget _view(BuildContext context, int at, ScreensMemory memory) {
    final l = context.l10n;
    final Palette p = context.p;
    final ScreenSize size = screenSizeOf(section);
    final (TimeStop stop, List<Pill> cards) = stops[at];
    for (final Pill pill in cards) {
      host.seen(section, pill);
    }

    return ScreenShelf(
      head: styleOn(section, 'head'),
      title: section.title(host.language) ?? l.screensTimeTitle,
      line: section.subtitle(host.language) ?? l.screensTimeLine,
      gap: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: paced(context, 220),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.bottomLeft,
                      children: [...previous, ?current],
                    ),
                    child: Column(
                      key: ValueKey('time-at-${stop.id}'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          upper(context, stop.label),
                          style: AppText.label(
                            size: 9.5,
                            weight: FontWeight.w700,
                            spacing: 1.3,
                            height: 1.2,
                            color: p.ink.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 7),
                        BalancedText(
                          stop.when,
                          style: AppText.display(
                            size: bySize(size, s: 27, m: 32, l: 36),
                            weight: FontWeight.w600,
                            height: 1.02,
                            spacing: -1,
                            color: p.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                RoundButton(
                  key: const ValueKey('time-back'),
                  icon: Icons.chevron_left_rounded,
                  label: l.screensTimeEarlier,
                  onTap: at > 0 ? () => _go(memory, at, at - 1) : null,
                ),
                RoundButton(
                  key: const ValueKey('time-on'),
                  icon: Icons.chevron_right_rounded,
                  label: l.screensTimeLater,
                  onTap: at < stops.length - 1
                      ? () => _go(memory, at, at + 1)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Ruler(
            stops: [for (final s in stops) s.$1],
            at: at,
            onGo: (to) => _go(memory, at, to),
          ),
          if (styleOn(section, 'caption')) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l.screensTimeCaption,
                style: AppText.body(
                  size: 11,
                  weight: FontWeight.w500,
                  height: 1.35,
                  color: p.ink.withValues(alpha: 0.42),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AnimatedSwitcher(
              duration: paced(context, 260),
              child: KeyedSubtree(
                key: ValueKey('time-cards-${stop.id}'),
                child: cards.length == 1
                    ? ColourTile(
                        pill: cards.first,
                        height: bySize(size, s: 190, m: 220, l: 250),
                        radius: 22,
                        padding: 16,
                        min: 13,
                        max: bySize(size, s: 22, m: 26, l: 28),
                        read: host.isRead(cards.first),
                        badge: _year(context, cards.first),
                        onTap: () => host.open(section, cards, cards.first),
                      )
                    : Row(
                        children: [
                          for (int i = 0; i < 2 && i < cards.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(
                              child: ColourTile(
                                pill: cards[i],
                                height: bySize(size, s: 200, m: 236, l: 264),
                                radius: 22,
                                padding: 16,
                                min: 10.5,
                                max: bySize(size, s: 15, m: 17, l: 19),
                                read: host.isRead(cards[i]),
                                badge: _year(context, cards[i]),
                                onTap: () =>
                                    host.open(section, cards, cards[i]),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The year a card's question names, set beside its head as the canvas
  /// sets it; nothing for a card that names none.
  Widget? _year(BuildContext context, Pill pill) {
    final String? year = questionYear(pill);
    if (year == null) return null;
    return Text(
      year,
      style: AppText.display(
        size: 14,
        weight: FontWeight.w600,
        height: 1,
        color: pill.ink,
      ),
    );
  }
}

/// The ruler: a tick for every power of ten, a dot for every stop, the run
/// from the far end to where the reader is filled in, and the ring that is
/// the reader, which a drag or a tap moves to the nearest stop.
class _Ruler extends StatelessWidget {
  const _Ruler({required this.stops, required this.at, required this.onGo});

  final List<TimeStop> stops;
  final int at;
  final ValueChanged<int> onGo;

  static const double _inset = 9;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final double farLog = math.log(math.max(stops.first.ago, 10)) / math.ln10;
    final List<double> places = [
      for (final TimeStop s in stops) rulerPlace(s.ago, farLog),
    ];
    final String locale = Localizations.localeOf(context).toString();
    final TextStyle caption = AppText.body(
      size: 10,
      weight: FontWeight.w600,
      height: 1,
      color: p.ink.withValues(alpha: 0.42),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, box) {
          final double width = box.maxWidth - 2 * _inset;
          double xOf(double place) => _inset + place * width;
          int nearest(double dx) {
            int best = 0;
            for (int i = 1; i < places.length; i++) {
              if ((xOf(places[i]) - dx).abs() <
                  (xOf(places[best]) - dx).abs()) {
                best = i;
              }
            }
            return best;
          }

          final double knob = xOf(places[at]);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                slider: true,
                value: '${stops[at].label}, ${stops[at].when}',
                increasedValue: at < stops.length - 1
                    ? '${stops[at + 1].label}, ${stops[at + 1].when}'
                    : null,
                decreasedValue: at > 0
                    ? '${stops[at - 1].label}, ${stops[at - 1].when}'
                    : null,
                onIncrease: at < stops.length - 1 ? () => onGo(at + 1) : null,
                onDecrease: at > 0 ? () => onGo(at - 1) : null,
                child: GestureDetector(
                  key: const ValueKey('time-ruler'),
                  // A screen reader moves along it as along a slider, a
                  // stop at a time; a tap at its left edge is no way to.
                  excludeFromSemantics: true,
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => onGo(nearest(d.localPosition.dx)),
                  onHorizontalDragUpdate: (d) =>
                      onGo(nearest(d.localPosition.dx)),
                  child: SizedBox(
                    height: 44,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (int k = 0; k <= farLog.floor(); k++)
                          Positioned(
                            left: xOf((farLog - k) / farLog) - 0.5,
                            top: 6,
                            child: Container(
                              width: 1,
                              height: 14,
                              color: p.ink.withValues(alpha: 0.24),
                            ),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 28,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: p.ink.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: paced(context, 350),
                          curve: Curves.easeOutCubic,
                          left: 0,
                          width: knob,
                          top: 28,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: p.ink,
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                        for (int i = 0; i < places.length; i++)
                          Positioned(
                            left: xOf(places[i]) - 4,
                            top: 26,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i <= at
                                    ? p.ink
                                    : p.ink.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        AnimatedPositioned(
                          duration: paced(context, 350),
                          curve: Curves.easeOutCubic,
                          left: knob - 11,
                          top: 19,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: p.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: p.ink, width: 3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ExcludeSemantics(
                child: SizedBox(
                  height: MediaQuery.textScalerOf(context).scale(10) + 4,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        child: Text(
                          _far(stops.first.ago, locale),
                          style: caption,
                        ),
                      ),
                      for (final int k in rulerLabels(farLog))
                        Positioned(
                          left: xOf((farLog - k) / farLog) - 40,
                          width: 80,
                          child: Text(
                            _power(k, locale),
                            textAlign: TextAlign.center,
                            style: caption,
                          ),
                        ),
                      Positioned(
                        right: 0,
                        child: Text(l.screensTimeNow, style: caption),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The far end's distance, as the ruler says it: 13.8 bn, 2,000.
  static String _far(double ago, String locale) {
    if (ago >= 1e6) return _compact(ago, locale);
    // Two figures are enough for an end of a ruler: 2,026 years back is
    // "2,000" there, and the card says the exact year.
    final double tens = math
        .pow(10, (math.log(ago) / math.ln10).floor() - 1)
        .toDouble();
    return _plain((ago / tens).round() * tens, locale);
  }

  static String _power(int k, String locale) {
    final double n = math.pow(10, k).toDouble();
    return n >= 1e6 ? _compact(n, locale) : _plain(n, locale);
  }

  static String _compact(double n, String locale) {
    try {
      return (intl.NumberFormat.compact(locale: locale)
            ..maximumFractionDigits = 1
            ..significantDigitsInUse = false)
          .format(n);
    } catch (_) {
      return intl.NumberFormat.compact(locale: 'en').format(n);
    }
  }

  static String _plain(double n, String locale) {
    try {
      return intl.NumberFormat.decimalPattern(locale).format(n.round());
    } catch (_) {
      return intl.NumberFormat.decimalPattern('en').format(n.round());
    }
  }
}
