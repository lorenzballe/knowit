import '../models/pill.dart';

/// The shelves that turn over: Explore's rotating themes.
///
/// Every card already says what kind of thing it is: a myth it overturns, a
/// paradox, a number that surprises, a story, something to use today; when
/// and where it is set; whether it is a debate or a sum to work out. Each
/// theme here is one of those, so a shelf is a reason to read rather than a
/// heap, and the same for everybody: what changes from one reader to the
/// next is only that a card already read is not shown again.
///
/// They turn over twice. Which themes are up changes every day, round a
/// fixed cycle, so a theme comes back every few days and never two days
/// running; and the cards on a theme are dealt afresh each day. The screen
/// is a different screen tomorrow, which is the point of it.
enum ShelfTheme {
  myths,
  past,
  numbers,
  debates,
  place,
  practical,
  paradoxes,
  stories,
  seen,
  workItOut,
  origins,
  sharpest,
}

/// One theme as it stands today: which, and in what form when the theme
/// has more than one (the ancient world, the 1800s; Asia, the Americas).
class ThemedShelf {
  const ThemedShelf(this.theme, this.variant, this.pills);

  final ShelfTheme theme;

  /// For [ShelfTheme.past]: 0 the ancient and medieval world, 1 the 1600s to
  /// the 1800s, 2 the last century. For [ShelfTheme.place]: 0 Asia and the
  /// Middle East, 1 the Americas, 2 Europe. Otherwise 0.
  final int variant;

  final List<Pill> pills;

  /// A key for analytics and tests: `past-1`, `myths-0`.
  String get key => '${theme.name}-$variant';
}

/// The order themes come up in. Spread by hand so neighbours differ in
/// kind: a myth beside a debate, never two kinds of number side by side.
const List<ShelfTheme> kThemeCycle = [
  ShelfTheme.myths,
  ShelfTheme.past,
  ShelfTheme.numbers,
  ShelfTheme.debates,
  ShelfTheme.place,
  ShelfTheme.practical,
  ShelfTheme.paradoxes,
  ShelfTheme.stories,
  ShelfTheme.seen,
  ShelfTheme.workItOut,
  ShelfTheme.origins,
  ShelfTheme.sharpest,
];

/// How many themed shelves a day shows, and how many cards each holds.
const int kThemesPerDay = 4;
const int kThemeCards = 8;

/// A shelf with fewer unread cards than this is not worth a row.
const int kThemeMinimum = 4;

/// The variant of [theme] on day [day]: the multi-form themes step through
/// their forms each time they come back round.
int themeVariant(ShelfTheme theme, int day) {
  if (theme != ShelfTheme.past && theme != ShelfTheme.place) return 0;
  // The cycle comes round every few days; each time round is the next form.
  return (day * kThemesPerDay ~/ kThemeCycle.length) % 3;
}

bool _fits(ShelfTheme theme, int variant, Pill p) {
  switch (theme) {
    case ShelfTheme.myths:
      return p.hook == 'misconception';
    case ShelfTheme.paradoxes:
      return p.hook == 'paradox';
    case ShelfTheme.numbers:
      return p.hook == 'number';
    case ShelfTheme.practical:
      return p.hook == 'practical' || p.mood == 'practical';
    case ShelfTheme.origins:
      return p.hook == 'origin';
    case ShelfTheme.stories:
      return p.hook == 'story';
    case ShelfTheme.debates:
      return p.challenge is TakeASide;
    case ShelfTheme.workItOut:
      return p.challenge is TypeNumber || p.challenge is Estimate;
    case ShelfTheme.seen:
      return p.diagram != null;
    case ShelfTheme.sharpest:
      return p.difficulty == Difficulty.hard;
    case ShelfTheme.past:
      return switch (variant) {
        0 => p.era == 'ancient' || p.era == 'medieval',
        1 => p.era == 'early_modern' || p.era == 'nineteenth',
        _ => p.era == 'twentieth',
      };
    case ShelfTheme.place:
      return switch (variant) {
        0 => p.region == 'asia' || p.region == 'middle_east',
        1 => p.region == 'americas',
        _ => p.region == 'europe',
      };
  }
}

/// FNV-1a, so the order is the same on every phone and every run.
int _hash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h;
}

/// The day's themed shelves for [pool], days counted from the epoch.
///
/// [pool] is already narrowed to the subject chosen and to cards not read.
/// Themes are taken in cycle order from today's place in it, skipping any
/// that would hold fewer than [kThemeMinimum], until [kThemesPerDay] are up.
/// On each, the cards are dealt in the day's order with at most two from one
/// subject, so a theme reads as a theme and not as one subject's shelf.
List<ThemedShelf> themedShelves(List<Pill> pool, {required int day}) {
  final out = <ThemedShelf>[];
  final start = (day * kThemesPerDay) % kThemeCycle.length;
  for (int i = 0; i < kThemeCycle.length && out.length < kThemesPerDay; i++) {
    final theme = kThemeCycle[(start + i) % kThemeCycle.length];
    final variant = themeVariant(theme, day);
    final fits = pool.where((p) => _fits(theme, variant, p)).toList()
      ..sort(
        (a, b) =>
            _hash('$day:${theme.name}:${a.id}')
                .compareTo(_hash('$day:${theme.name}:${b.id}')),
      );
    final picked = <Pill>[];
    final perTopic = <String, int>{};
    for (final p in fits) {
      if ((perTopic[p.topic] ?? 0) >= 2) continue;
      picked.add(p);
      perTopic[p.topic] = (perTopic[p.topic] ?? 0) + 1;
      if (picked.length == kThemeCards) break;
    }
    // Narrowed to one subject, the two-a-subject rule would leave two; fill
    // from the rest of the theme in the day's order.
    if (picked.length < kThemeCards) {
      for (final p in fits) {
        if (picked.length == kThemeCards) break;
        if (!picked.contains(p)) picked.add(p);
      }
    }
    if (picked.length >= kThemeMinimum) {
      out.add(ThemedShelf(theme, variant, picked));
    }
  }
  return out;
}

/// Days since the epoch for [on], in local time, which is when the reader's
/// day turns.
int themeDay(DateTime on) =>
    DateTime.utc(on.year, on.month, on.day).millisecondsSinceEpoch ~/ 86400000;
