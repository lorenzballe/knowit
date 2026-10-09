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
  trueOrFalse,
  reasoning,
  ideas,
  curious,
  moving,
  howItWorks,
  puzzles,
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
  ShelfTheme.trueOrFalse,
  ShelfTheme.ideas,
  ShelfTheme.moving,
  ShelfTheme.reasoning,
  ShelfTheme.curious,
  ShelfTheme.puzzles,
  ShelfTheme.howItWorks,
];

/// How many themed shelves a day shows, and how many cards each holds.
const int kThemesPerDay = 7;
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
    case ShelfTheme.trueOrFalse:
      final c = p.challenge;
      return c is PickOne &&
          c.options.length == 2 &&
          c.options.map((o) => o.toLowerCase()).toSet().containsAll(const {
            'true',
            'false',
          });
    case ShelfTheme.reasoning:
      return p.topic == 'Thinking' || p.principle != Principle.none;
    case ShelfTheme.ideas:
      return p.abstraction == 'abstract';
    case ShelfTheme.curious:
      return p.mood == 'wonder' && p.hook != 'misconception';
    case ShelfTheme.moving:
      return p.shelfLife == 'years' || p.shelfLife == 'months';
    case ShelfTheme.howItWorks:
      return p.hook == 'mechanism';
    case ShelfTheme.puzzles:
      return p.hook == 'puzzle';
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

/// Whether [p] belongs on [theme], in its [variant] where it has more than
/// one: the test every theme deals by, for the shelves that deal their own.
bool fitsTheme(ShelfTheme theme, Pill p, {int variant = 0}) =>
    _fits(theme, variant, p);

/// FNV-1a, so the order is the same on every phone and every run.
int shelfHash(String s) {
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
    final shelf = dealTheme(theme, themeVariant(theme, day), pool, day);
    if (shelf != null) out.add(shelf);
  }
  return out;
}

/// The shelves Explore always shows, each with a card drawn for its kind
/// (the design's "one signature per kind"): the figure itself for numbers,
/// two halves for a debate, a sun about to set for something to try today.
/// They are dealt like the turning themes, afresh each day, and the turning
/// themes leave them out so no theme is on the screen twice.
const List<ShelfTheme> kSignatureThemes = [
  ShelfTheme.numbers,
  ShelfTheme.debates,
  ShelfTheme.practical,
];

List<ThemedShelf> signatureShelves(List<Pill> pool, {required int day}) => [
  for (final theme in kSignatureThemes) ?dealTheme(theme, 0, pool, day),
];

/// The figure a numbers card is about, to be set large on its shelf: the
/// first number in the question that is not a year, kept with its percent
/// sign or its fraction. Null when the question has none worth showing.
String? shelfFigure(Pill p) {
  for (final m in RegExp(
    r'([$€£])?(?<![\w.^/])(\d{1,3}(?:,\d{3})+|\d+(?:\.\d+)?)(\s?%|/\d+)?(?:\s(thousand|million|billion|trillion)\b)?(?![\w^])',
  ).allMatches(p.question)) {
    final money = m.group(1) ?? '';
    final digits = m.group(2)!;
    final n = num.tryParse(digits.replaceAll(',', ''));
    if (n == null) continue;
    final suffix = (m.group(3) ?? '').trim();
    final scale = m.group(4);
    // A four-digit year is when, not how much.
    if (money.isEmpty &&
        suffix.isEmpty &&
        scale == null &&
        !digits.contains(',') &&
        n >= 1000 &&
        n <= 2100 &&
        n == n.round()) {
      continue;
    }
    String body = digits;
    if (scale != null) {
      body =
          '$digits${const {'thousand': 'k', 'million': 'M', 'billion': 'B', 'trillion': 'T'}[scale]}';
    } else if (n >= 1e6) {
      // A long run of digits, said the short way: 1,250,000 is 1.25M.
      final (v, unit) = n >= 1e9 ? (n / 1e9, 'B') : (n / 1e6, 'M');
      body =
          '${v.toStringAsFixed(v >= 10 ? 0 : 2).replaceFirst(RegExp(r'\.?0+$'), '')}$unit';
    }
    final figure = '$money$body$suffix';
    if (figure.length > 7) continue;
    return figure;
  }
  return null;
}

ThemedShelf? dealTheme(
  ShelfTheme theme,
  int variant,
  List<Pill> pool,
  int day,
) {
  {
    final fits =
        pool
            .where(
              (p) =>
                  _fits(theme, variant, p) &&
                  (theme != ShelfTheme.numbers || shelfFigure(p) != null) &&
                  // Something to try today is not an argument to have.
                  (theme != ShelfTheme.practical || p.challenge is! TakeASide),
            )
            .toList()
          ..sort(
            (a, b) =>
                shelfHash('$day:${theme.name}:${a.id}')
                    .compareTo(shelfHash('$day:${theme.name}:${b.id}')),
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
      return ThemedShelf(theme, variant, picked);
    }
    return null;
  }
}

/// Days since the epoch for [on], in local time, which is when the reader's
/// day turns.
int themeDay(DateTime on) =>
    DateTime.utc(on.year, on.month, on.day).millisecondsSinceEpoch ~/ 86400000;
