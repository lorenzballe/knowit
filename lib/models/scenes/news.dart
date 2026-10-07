/// `news`: a piece of news, explained.
///
/// A headline sits at the top as a clipping cut from the paper, with the
/// outlet and the date on its masthead. Under it the card promises three
/// things and gives them one tap at a time: what happened, why it happened,
/// and either what it means for the reader or the time it happened before,
/// a past case set under today's as an older clipping.
///
/// The tap is the reasoning move. A headline on its own is the bare news,
/// which Astute never deals; the card makes the reader stop at "why?" before
/// the answer arrives, and ends on a connection — to their own life, or to a
/// past case with the same mechanism — rather than on the event.
///
/// News goes stale, so every news card carries the day after which it must
/// not be dealt ([expires]). The dealer skips it from the day after
/// (lib/data/pills_repository.dart and functions/src/deal.ts), and the bank
/// check refuses an expiry more than 120 days after the card was written
/// (tool/cards/scene_kinds/news.py).
///
/// JSON fields:
///
/// - `type`: `"news"`.
/// - `headline` (string, ≤ 72 chars): the news in a line, as it would be
///   printed. The card's own wording of what the outlet reported.
/// - `outlet` (string, ≤ 26 chars): who reported it ("Reuters", "US Bureau
///   of Labor Statistics"), on the clipping's masthead.
/// - `date` (string, `yyyy-mm-dd`): the day it was reported, on the
///   masthead as "12 Mar 2025".
/// - `panels` (2 or 3): the steps, in order. With `then` there are two,
///   without it three: the reader always taps three times.
///   - `label` (string, ≤ 24 chars): what the step is ("What happened",
///     "Why", "What it means for you"), shown before it opens.
///   - `text` (string, ≤ 140 chars): the step, in two or three sentences.
///   - `figure` (string, ≤ 9 chars, optional): one number that carries the
///     step, as it is read ("$6.23", "×2", "−0.3%"), set large above it.
/// - `then` (optional): the past case, the third step.
///   - `label` (string, ≤ 24 chars): "It happened before".
///   - `year` (int): when, between 1000 and the year of `date`.
///   - `headline` (string, ≤ 56 chars): that time's news, in a line.
///   - `line` (string, ≤ 120 chars): what was the same, and what it shows.
/// - `expires` (string, `yyyy-mm-dd`, required): the last day the card may
///   be dealt.
///
/// Example:
///
/// ```json
/// {
///   "type": "news",
///   "headline": "Japan opens its emergency rice stockpile as prices soar",
///   "outlet": "Japan's farm ministry",
///   "date": "2025-02-07",
///   "panels": [
///     {"label": "What happened", "figure": "210,000 t",
///      "text": "Rice the government keeps for disasters goes on sale, to
///               bring down a price that has soared in a year."},
///     {"label": "Why",
///      "text": "For decades Japan paid farmers to plant less rice, to hold
///               its price up. When the hot 2023 summer spoiled part of the
///               crop, none was spare."}
///   ],
///   "then": {
///     "label": "It happened before",
///     "year": 1993,
///     "headline": "A cold summer, and Japan has to import rice",
///     "line": "Supply kept just tight enough has no cushion: one bad
///              harvest, and the shelves are empty."
///   },
///   "expires": "2026-11-30"
/// }
/// ```
library;

import '../scene.dart';

/// One step of the explanation.
class NewsPanel {
  final String label;
  final String text;
  final String figure;
  const NewsPanel(this.label, this.text, {this.figure = ''});

  bool get hasFigure => figure.isNotEmpty;
}

/// The time it happened before: a past case with the same mechanism.
class NewsThen {
  final String label;
  final int year;
  final String headline;
  final String line;
  const NewsThen(this.label, this.year, this.headline, this.line);
}

/// A piece of news, explained in three taps.
class NewsScene extends Scene {
  final String headline;
  final String outlet;

  /// The day it was reported.
  final DateTime date;

  /// The steps before [then], in order.
  final List<NewsPanel> panels;

  /// The past case, or null when the last step is a panel.
  final NewsThen? then;

  /// The last day the card may be dealt.
  final DateTime expires;

  const NewsScene(
    super.raw, {
    required this.headline,
    required this.outlet,
    required this.date,
    required this.panels,
    required this.then,
    required this.expires,
  });

  /// How many taps open the whole card: always three.
  int get steps => panels.length + (then == null ? 0 : 1);

  /// The label of step [i], a panel's or the past case's.
  String labelOf(int i) => i < panels.length ? panels[i].label : then!.label;

  /// Whether the card is stale on [day]: true from the day after [expires].
  bool expiredOn(DateTime day) =>
      DateTime(day.year, day.month, day.day).isAfter(expires);

  static final _iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// A `yyyy-mm-dd` date that names a real day, or null.
  static DateTime? parseDay(Object? v) {
    if (v is! String) return null;
    final m = _iso.firstMatch(v);
    if (m == null) return null;
    final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
    final out = DateTime(y, mo, d);
    if (out.year != y || out.month != mo || out.day != d) return null;
    return out;
  }

  static NewsScene parse(Map<String, Object?> raw, Object? id) {
    String need(Map m, String k, String where) {
      final v = m[k];
      if (v is! String || v.trim().isEmpty) {
        throw FormatException('scene.$where$k: missing', id);
      }
      return v.trim();
    }

    DateTime day(String k) {
      final v = parseDay(raw[k]);
      if (v == null) throw FormatException('scene.$k: a yyyy-mm-dd date', id);
      return v;
    }

    final list = raw['panels'];
    if (list is! List || list.length < 2 || list.length > 3) {
      throw FormatException('scene.panels: 2 or 3', id);
    }
    final panels = <NewsPanel>[];
    for (var i = 0; i < list.length; i++) {
      final p = list[i];
      if (p is! Map) {
        throw FormatException('scene.panels[$i]: not an object', id);
      }
      final figure = p['figure'];
      if (figure != null && figure is! String) {
        throw FormatException('scene.panels[$i].figure: a string', id);
      }
      panels.add(
        NewsPanel(
          need(p, 'label', 'panels[$i].'),
          need(p, 'text', 'panels[$i].'),
          figure: (figure as String? ?? '').trim(),
        ),
      );
    }

    NewsThen? then;
    final t = raw['then'];
    if (t != null) {
      if (t is! Map || t['year'] is! int) {
        throw FormatException('scene.then: {label, year, headline, line}', id);
      }
      then = NewsThen(
        need(t, 'label', 'then.'),
        t['year'] as int,
        need(t, 'headline', 'then.'),
        need(t, 'line', 'then.'),
      );
    }
    if (panels.length + (then == null ? 0 : 1) != 3) {
      throw FormatException('scene: three steps, panels and then', id);
    }

    return NewsScene(
      raw,
      headline: need(raw, 'headline', ''),
      outlet: need(raw, 'outlet', ''),
      date: day('date'),
      panels: panels,
      then: then,
      expires: day('expires'),
    );
  }
}
