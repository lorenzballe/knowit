/// Today's three: three shares to estimate, the same three for everyone
/// that day, one at a time, about a minute in all, a hundred points each for
/// how close the guess comes. Then the score out of three hundred, where it
/// stands among the readers who played the same three today, counted on the
/// server as they play (lib/sync/crowd.dart), a way to send it on that says how far off, never the answers, and the cards
/// themselves, where each answer is explained.
///
/// It opens Explore: the day's puzzle everyone plays, and talks about.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../analytics.dart';
import '../../../data/pills_repository.dart' show dateKey;
import '../../../l10n/l10n.dart';
import '../../../sync/crowd.dart';
import '../../../theme.dart';
import '../../../utils/share_link.dart';
import '../../explore_block.dart';
import 'answers.dart';
import 'bet_host.dart';
import 'bets_day.dart';
import 'block.dart';
import 'deal.dart';
import 'parts.dart';

/// What a guess is worth: a hundred for the answer itself, three fewer for
/// every point off, nothing past thirty-three; in tens, so a day's score
/// reads at a glance and falls into the crowd's tens.
int threePoints(double guess, double answer) {
  final double raw = (100 - 3 * (guess - answer).abs()).clamp(0, 100);
  return ((raw / 10).round() * 10).clamp(0, 100);
}

/// The fewest readers the crowd is spoken of from: below them, a share of
/// "today's readers" would be a share of a handful.
const int kThreeCrowdFloor = 5;

/// The days today's three was played, kept on the phone: each day's score,
/// and whether it was counted in the crowd, for the days in a row, the
/// week's row of days and yesterday's score.
class ThreeDays extends ChangeNotifier {
  ThreeDays._();

  static ThreeDays instance = ThreeDays._();

  /// A fresh record, for a test.
  @visibleForTesting
  static void resetForTest() => instance = ThreeDays._();

  static const String _kKey = 'knowit.three';

  /// How many days are kept: enough for any streak worth saying.
  static const int _kept = 120;

  final Map<String, int> _scores = {};
  final Set<String> _counted = {};
  bool _loaded = false;
  Future<void>? _loading;

  bool get loaded => _loaded;

  /// Reads what was kept, once.
  Future<void> load() => _loading ??= () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_kKey);
    if (raw != null) {
      try {
        final Object? data = jsonDecode(raw);
        if (data is Map) {
          final Object? s = data['s'];
          if (s is Map) {
            for (final MapEntry<Object?, Object?> e in s.entries) {
              if (e.key is String && e.value is num) {
                _scores[e.key as String] = (e.value as num).round();
              }
            }
          }
          final Object? c = data['c'];
          if (c is List) _counted.addAll(c.whereType<String>());
        }
      } catch (_) {}
    }
    _loaded = true;
    notifyListeners();
  }();

  Future<void> _save() async {
    final List<String> days = _scores.keys.toList()..sort();
    while (days.length > _kept) {
      _scores.remove(days.removeAt(0));
    }
    _counted.removeWhere((d) => !_scores.containsKey(d));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kKey,
      jsonEncode({'s': _scores, 'c': _counted.toList()}),
    );
  }

  /// [day]'s score, or null when it was not played.
  int? score(String day) => _scores[day];

  /// Keeps [day]'s score.
  void put(String day, int score) {
    _scores[day] = score;
    notifyListeners();
    unawaited(_save());
  }

  /// Whether [day]'s score is in the crowd.
  bool counted(String day) => _counted.contains(day);

  /// Notes that [day]'s score is in the crowd.
  void markCounted(String day) {
    _counted.add(day);
    unawaited(_save());
  }

  /// The days in a row up to [today], today's three counted once it is
  /// played, and a run that ended yesterday still standing until today is
  /// over.
  int streak(DateTime today) {
    DateTime d = DateTime(today.year, today.month, today.day);
    if (!_scores.containsKey(dateKey(d))) {
      d = d.subtract(const Duration(days: 1));
    }
    int n = 0;
    while (_scores.containsKey(dateKey(d))) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  /// This week, Monday to Sunday: whether each day was played.
  List<bool> week(DateTime today) {
    final DateTime monday = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    return [
      for (int i = 0; i < 7; i++)
        _scores.containsKey(dateKey(monday.add(Duration(days: i)))),
    ];
  }
}

/// The colours today's three is drawn in: a card of paper on the night
/// page, of ink on the day one, so it stands apart from every subject's.
BetInk threeInk(BuildContext context) {
  final p = context.p;
  return BetInk(
    ground: p.inverse,
    ink: p.onInverse,
    fill: p.onInverse.withValues(alpha: 0.12),
    hair: p.onInverse.withValues(alpha: 0.18),
    sub: p.onInverse.withValues(alpha: 0.6),
    onInk: p.inverse,
    mark: p.onInverse,
  );
}

/// The block.
class ThreeBlock extends BetBlock {
  const ThreeBlock();

  @override
  String get name => 'three';

  /// One game for everybody today, not a subject's.
  @override
  bool get onSubjectPages => false;

  @override
  List<String> get sizes => const ['l'];

  @override
  String get defaultSize => 'l';

  @override
  int get defaultLimit => 3;

  /// A share the card takes as a number: the guess is set on a track.
  @override
  bool fits(BetAnswer a) => a.share && !a.isPick;

  @override
  String title(AppLocalizations l, BetSection shelf) => l.threeTitle;

  @override
  String line(AppLocalizations l, BetSection shelf) => l.threeSame;

  /// The same three for everyone given the section, whatever each has read.
  @override
  List<BetAnswer> deal(ExploreHost host, BetSection shelf) =>
      dealBets(host, shelf, fits: fits, count: 3, salt: 'three', fresh: false);

  @override
  bool canShow(ExploreHost host, BetSection shelf) {
    int n = 0;
    for (final p in host.cardsFor(shelf.section, limit: kBetPool)) {
      final BetAnswer? a = answerOf(p);
      if (a != null && fits(a) && ++n >= 3) return true;
    }
    return false;
  }

  @override
  Widget body(
    BuildContext context,
    ExploreHost host,
    BetSection shelf,
    List<BetAnswer> cards,
  ) => ThreeCard(host: host, shelf: shelf, cards: cards);

  /// No shelf's head: the card says what it is itself.
  @override
  Widget? shelfOf(BuildContext context, ExploreHost host, BetSection shelf) {
    final List<BetAnswer> cards = deal(host, shelf);
    if (cards.length < 3) return null;
    unawaited(ThreeDays.instance.load());
    return Padding(
      key: ValueKey('bets-${shelf.section.id}'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: ListenableBuilder(
        listenable: Listenable.merge([
          BetsDay.instance,
          ThreeDays.instance,
          host.app,
        ]),
        builder: (context, _) => body(context, host, shelf, cards),
      ),
    );
  }
}

/// Today's three, as far as the reader has come: the guess on the card in
/// front of them, what it came to, or the day's score.
class ThreeCard extends StatelessWidget {
  const ThreeCard({
    super.key,
    required this.host,
    required this.shelf,
    required this.cards,
  });

  final ExploreHost host;
  final BetSection shelf;
  final List<BetAnswer> cards;

  /// How many of the three the reader has seen through, the answer told
  /// and moved on from.
  static const String _kAt = 'three:at';

  @override
  Widget build(BuildContext context) {
    final BetsDay day = BetsDay.instance;
    final int at = (day.draft(_kAt) as num?)?.toInt().clamp(0, 3) ?? 0;
    final BetInk ink = threeInk(context);
    final List<Bet?> bets = [
      for (final c in cards) day.betOn('three', c.pill.id),
    ];
    final bool done = at >= 3 && bets.every((b) => b != null);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(a),
          child: child,
        ),
      ),
      child: done
          ? _ThreeResult(
              key: const ValueKey('three-result'),
              host: host,
              shelf: shelf,
              cards: cards,
              bets: [for (final b in bets) b!],
              ink: ink,
            )
          : _ThreeStep(
              key: ValueKey('three-step-$at'),
              host: host,
              shelf: shelf,
              cards: cards,
              at: at.clamp(0, 2),
              bet: bets[at.clamp(0, 2)],
              ink: ink,
              onNext: () => day.keepDraft(_kAt, at + 1),
            ),
    );
  }
}

/// One of the three: the guess set and locked in, or what it came to.
class _ThreeStep extends StatelessWidget {
  const _ThreeStep({
    super.key,
    required this.host,
    required this.shelf,
    required this.cards,
    required this.at,
    required this.bet,
    required this.ink,
    required this.onNext,
  });

  final ExploreHost host;
  final BetSection shelf;
  final List<BetAnswer> cards;
  final int at;
  final Bet? bet;
  final BetInk ink;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final BetAnswer answer = cards[at];
    final pill = answer.pill;
    final BetsDay day = BetsDay.instance;
    final BetNumbers n = BetNumbers(
      Localizations.localeOf(context).languageCode,
    );
    final String key = BetsDay.draftKey('three', pill.id);
    final Map draft = day.draft(key) is Map ? day.draft(key) as Map : const {};
    final double guess = bet != null
        ? double.tryParse(bet!.said) ?? 50
        : (draft['g'] as num?)?.toDouble() ?? 50;
    final bool laid = bet != null;

    Future<void> lockIn() async {
      BetFeel.lay();
      final String response = plainResponse(guess);
      final int points = threePoints(guess, answer.value);
      // A card already answered elsewhere is played all the same, as the
      // same three are everyone's; only its first answer is the card's.
      final bool fresh = host.app.answerFor(pill.id) == null;
      await layBet(
        host,
        shelf.section,
        Bet(
          kind: 'three',
          section: shelf.id,
          pill: pill.id,
          said: response,
          right: answer.accepts(response),
          facts: {
            'off': (guess - answer.value).abs(),
            'pts': points,
            'step': at + 1,
          },
          at: DateTime.now().millisecondsSinceEpoch,
        ),
        pill: fresh ? pill : null,
        response: fresh ? response : null,
      );
      if (at == 2) _finish();
    }

    final List<Widget> foot = laid
        ? [
            Semantics(
              liveRegion: true,
              child: Text(
                '${l.betsItIs(n.percent(answer.value))} '
                '${l.threeYouSaid(n.percent(guess))}',
                key: ValueKey('three-said-${pill.id}'),
                style: AppText.display(
                  size: 17,
                  weight: FontWeight.w600,
                  height: 1.25,
                  spacing: -0.3,
                  color: ink.ink,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.threePoints(threePoints(guess, answer.value)),
              key: ValueKey('three-points-${pill.id}'),
              style: AppText.body(
                size: 14,
                weight: FontWeight.w800,
                color: ink.ink,
              ),
            ),
            BetWhy(pill, ink: ink),
            const SizedBox(height: 14),
            BetButton(
              key: const ValueKey('three-next'),
              label: at == 2 ? l.threeSeeScore : l.threeNext,
              ink: ink,
              height: 50,
              expand: true,
              onTap: onNext,
            ),
          ]
        : [
            BetButton(
              key: ValueKey('three-lock-${pill.id}'),
              label: l.betsLockIn,
              ink: ink,
              height: 50,
              expand: true,
              onTap: lockIn,
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                l.threeSame,
                textAlign: TextAlign.center,
                style: AppText.body(size: 12.5, color: ink.sub),
              ),
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: ink.ground,
            borderRadius: BorderRadius.circular(26),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ThreeHead(at: at, ink: ink),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, box) => Text(
                  pill.question,
                  style: questionStyle(
                    questionSizeFor(
                      context,
                      pill.question,
                      box.maxWidth,
                      max: 24,
                      min: 17,
                      lines: 4,
                    ),
                    ink.ink,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                n.percent(guess),
                style: AppText.display(
                  size: 40,
                  weight: FontWeight.w600,
                  height: 1,
                  spacing: -1,
                  color: ink.ink,
                ),
              ),
              const SizedBox(height: 12),
              BetTrack(
                key: ValueKey('three-track-${pill.id}'),
                ink: ink,
                value: guess,
                filled: true,
                label: l.betsYourGuess,
                say: n.percent,
                answer: laid ? (answer.value, answer.value) : null,
                onChanged: laid ? null : (v) => day.keepDraft(key, {'g': v}),
              ),
              const SizedBox(height: 16),
              ...foot,
            ],
          ),
        ),
      ],
    );
  }

  /// The third is in: the day's score kept, said to the crowd once, and
  /// noted.
  void _finish() {
    final BetsDay day = BetsDay.instance;
    int total = 0;
    for (final BetAnswer c in cards) {
      final Bet? b = day.betOn('three', c.pill.id);
      total += (b?.facts['pts'] as num?)?.toInt() ?? 0;
    }
    final String today = day.today;
    final ThreeDays days = ThreeDays.instance;
    days.put(today, total);
    final int streak = days.streak(BetsDay.instance.now);
    Analytics.capture('three done', {'score': total, 'streak': streak});
    if (!days.counted(today)) {
      final CrowdStore? store = Crowd.store;
      if (store != null) {
        store
            .add(today, total ~/ 10)
            .then((_) => days.markCounted(today))
            .catchError((Object error) {
              Analytics.error(error, null, where: 'three crowd');
            });
      }
    }
  }
}

/// The card's head: what it is, which of the three, and the three marks.
class _ThreeHead extends StatelessWidget {
  const _ThreeHead({required this.at, required this.ink});

  final int at;
  final BetInk ink;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      children: [
        Expanded(child: BetKicker(l.threeTitle, color: ink.ink)),
        BetKicker(l.threeStep(at + 1, 3), color: ink.ink),
        const SizedBox(width: 8),
        for (int i = 0; i < 3; i++)
          Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
            width: i == at ? 18 : 12,
            height: 4,
            decoration: BoxDecoration(
              color: i <= at ? ink.ink : ink.ink.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}

class _ThreeResult extends StatelessWidget {
  const _ThreeResult({
    super.key,
    required this.host,
    required this.shelf,
    required this.cards,
    required this.bets,
    required this.ink,
  });

  final ExploreHost host;
  final BetSection shelf;
  final List<BetAnswer> cards;
  final List<Bet> bets;
  final BetInk ink;

  int _points(Bet b) => (b.facts['pts'] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final BetNumbers n = BetNumbers(
      Localizations.localeOf(context).languageCode,
    );
    final ThreeDays days = ThreeDays.instance;
    final String today = BetsDay.instance.today;
    final int total = bets.fold(0, (s, b) => s + _points(b));
    final int streak = days.streak(BetsDay.instance.now);
    final String yesterday = dateKey(
      BetsDay.instance.now.subtract(const Duration(days: 1)),
    );
    final int? before = days.score(yesterday);

    Widget square(int points) => Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(left: 5),
      decoration: BoxDecoration(
        color: points >= 80
            ? ink.ink
            : points >= 40
            ? ink.ink.withValues(alpha: 0.45)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: ink.ink, width: 1.8),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: ink.ground,
            borderRadius: BorderRadius.circular(26),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The days in a row are the profile's to show, not Explore's.
              BetKicker(l.threeDone, color: ink.ink),
              const SizedBox(height: 10),
              // The score as large as the card allows, the three squares at
              // its right whatever the text size.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$total',
                            key: const ValueKey('three-score'),
                            style: AppText.display(
                              size: 64,
                              weight: FontWeight.w600,
                              height: 0.95,
                              spacing: -2,
                              color: ink.ink,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              l.threeOf300,
                              style: AppText.body(
                                size: 15,
                                weight: FontWeight.w600,
                                color: ink.sub,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [for (final b in bets) square(_points(b))],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ThreeCrowd(day: today, score: total, ink: ink),
              const SizedBox(height: 14),
              for (final (int i, BetAnswer c) in cards.indexed)
                _ThreeRow(
                  answer: c,
                  bet: bets[i],
                  points: _points(bets[i]),
                  ink: ink,
                  numbers: n,
                  onTap: () => host.open(shelf.section, [
                    for (final x in cards) x.pill,
                  ], c.pill),
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: BetButton(
                      key: const ValueKey('three-send'),
                      label: l.threeSend,
                      ink: ink,
                      height: 50,
                      expand: true,
                      onTap: () => _send(context, total, streak),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OutlineButton(
                      key: const ValueKey('three-why'),
                      label: l.threeWhy,
                      ink: ink,
                      onTap: () => host.open(shelf.section, [
                        for (final x in cards) x.pill,
                      ], cards.first.pill),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (before != null) ...[
          const SizedBox(height: 10),
          Text(
            l.threeYesterday(before),
            key: const ValueKey('three-yesterday'),
            style: AppText.body(
              size: 13,
              weight: FontWeight.w600,
              color: context.p.ink.withValues(alpha: 0.55),
            ),
          ),
        ],
      ],
    );
  }

  /// Sent on: the day, the score, a square for each of the three, and the
  /// way in. How far off, never the answers.
  Future<void> _send(BuildContext context, int total, int streak) async {
    final l = context.l10n;
    final String locale = Localizations.localeOf(context).toString();
    String date;
    try {
      date = DateFormat.MMMd(locale).format(BetsDay.instance.now);
    } catch (_) {
      date = DateFormat.MMMd('en').format(BetsDay.instance.now);
    }
    String square(int points) => points >= 80
        ? '🟩'
        : points >= 40
        ? '🟨'
        : '⬜';
    final String text = [
      l.threeShareHead(date),
      l.threeShareScore(total, streak),
      [for (final b in bets) square(_points(b))].join(),
      ShareRef.three.link,
    ].join('\n');
    final bool shared = await sendText(text);
    Analytics.capture('three shared', {
      'score': total,
      'as': shared ? 'link' : 'copied',
    });
    if (!shared) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.copiedToClipboard),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

/// Where the day's score stands among today's readers, as they play: a line
/// that says it, and how they all came out, band by band, the reader's own
/// band in full ink and marked. With too few to count among, the line says
/// so and the score's bar stands alone; with nobody, the bar.
class _ThreeCrowd extends StatefulWidget {
  const _ThreeCrowd({
    required this.day,
    required this.score,
    required this.ink,
  });

  final String day;
  final int score;
  final BetInk ink;

  @override
  State<_ThreeCrowd> createState() => _ThreeCrowdState();
}

class _ThreeCrowdState extends State<_ThreeCrowd> {
  /// The day's counts, listened to once for as long as the score is shown,
  /// not again at every rebuild.
  Stream<Map<int, int>>? _counts;

  @override
  void initState() {
    super.initState();
    _counts = Crowd.store?.watch(widget.day);
  }

  @override
  void didUpdateWidget(_ThreeCrowd old) {
    super.didUpdateWidget(old);
    if (old.day != widget.day) _counts = Crowd.store?.watch(widget.day);
  }

  @override
  Widget build(BuildContext context) {
    final Stream<Map<int, int>>? counts = _counts;
    if (counts == null) return _shown(context, null);
    return StreamBuilder<Map<int, int>>(
      stream: counts,
      builder: (context, snap) =>
          _shown(context, snap.hasError ? null : snap.data),
    );
  }

  Widget _shown(BuildContext context, Map<int, int>? counts) {
    final l = context.l10n;
    final BetInk ink = widget.ink;
    final ({int readers, int beaten})? at = counts == null
        ? null
        : Crowd.place(counts, widget.score);
    final int readers = at?.readers ?? 0;
    // Said kindly and truly: how many it beat when that is most of them,
    // otherwise how many played, and the spread shows the rest.
    final String? said = at == null || readers == 0
        ? null
        : readers < kThreeCrowdFloor
        ? l.threeFirst(readers)
        : at.beaten >= 50
        ? l.threeCloser(at.beaten)
        : l.threeReaders(readers);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (said != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              said,
              key: const ValueKey('three-crowd'),
              style: AppText.body(
                size: 15,
                weight: FontWeight.w700,
                height: 1.3,
                color: ink.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (counts != null && readers >= kThreeCrowdFloor)
          _ThreeSpread(
            key: const ValueKey('three-spread'),
            counts: counts,
            score: widget.score,
            ink: ink,
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: widget.score / 300,
              minHeight: 8,
              backgroundColor: ink.ink.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(ink.ink),
            ),
          ),
      ],
    );
  }
}

/// Today's readers by score, in ten bands of thirty points from none to
/// three hundred, each bar as tall as its share of the busiest: the
/// reader's band in full ink with "You" under it, the rest faint. The bars
/// grow as readers come in.
class _ThreeSpread extends StatelessWidget {
  const _ThreeSpread({
    super.key,
    required this.counts,
    required this.score,
    required this.ink,
  });

  final Map<int, int> counts;
  final int score;
  final BetInk ink;

  static const int _bands = 10;
  static const double _tall = 48;
  static const double _gap = 4;

  /// The band a count's bucket (tens of points) falls in: three buckets to
  /// a band, three hundred in the last.
  static int bandOf(int bucket) => (bucket ~/ 3).clamp(0, _bands - 1);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final List<int> n = List.filled(_bands, 0);
    counts.forEach((b, c) => n[bandOf(b)] += c);
    final int busiest = n.fold(0, (a, b) => b > a ? b : a);
    final int mine = bandOf(score ~/ 10);
    final TextStyle small = AppText.body(
      size: 11,
      weight: FontWeight.w600,
      color: ink.sub,
    );
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, box) {
          final double w = box.maxWidth;
          final double bar = (w - _gap * (_bands - 1)) / _bands;
          final double centre = mine * (bar + _gap) + bar / 2;
          const double label = 56;
          final double left = (centre - label / 2).clamp(0, w - label);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: _tall,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < _bands; i++) ...[
                      if (i > 0) const SizedBox(width: _gap),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutCubic,
                          // The reader's own band never thinner than a
                          // mark: they are in it, however few beside them.
                          height: busiest == 0
                              ? (i == mine ? 8 : 3)
                              : (_tall * n[i] / busiest).clamp(
                                  i == mine ? 8 : 3,
                                  _tall,
                                ),
                          decoration: BoxDecoration(
                            color: i == mine
                                ? ink.ink
                                : ink.ink.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 16,
                child: Stack(
                  children: [
                    if (mine > 1)
                      Positioned(left: 0, child: Text('0', style: small)),
                    if (mine < _bands - 2)
                      Positioned(right: 0, child: Text('300', style: small)),
                    Positioned(
                      left: left,
                      width: label,
                      child: Text(
                        l.threeYou,
                        key: const ValueKey('three-you'),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: small.copyWith(
                          color: ink.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One of the three on the score: its question, the guess against the
/// answer, the points. A tap opens the card.
class _ThreeRow extends StatelessWidget {
  const _ThreeRow({
    required this.answer,
    required this.bet,
    required this.points,
    required this.ink,
    required this.numbers,
    required this.onTap,
  });

  final BetAnswer answer;
  final Bet bet;
  final int points;
  final BetInk ink;
  final BetNumbers numbers;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final double guess = double.tryParse(bet.said) ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: ink.fill,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: ValueKey('three-row-${answer.pill.id}'),
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        answer.pill.question,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          size: 13.5,
                          weight: FontWeight.w700,
                          height: 1.25,
                          color: ink.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.threeRowSaid(
                          numbers.percent(guess),
                          numbers.percent(answer.value),
                        ),
                        style: AppText.body(size: 12.5, color: ink.sub),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$points',
                  style: AppText.display(
                    size: 20,
                    weight: FontWeight.w700,
                    color: ink.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A button drawn in an outline of the card's ink: the second of two.
class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    super.key,
    required this.label,
    required this.ink,
    required this.onTap,
  });

  final String label;
  final BetInk ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.textScalerOf(context).scale(12.5) + 34,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: ink.ink, width: 1.6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppText.body(
            size: 14,
            weight: FontWeight.w700,
            color: ink.ink,
          ),
        ),
      ),
    ),
  );
}
