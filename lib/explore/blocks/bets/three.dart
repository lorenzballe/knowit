/// The day's challenges: Today's five at the top of Explore for every
/// subject, five questions each from another subject, and Today's three at
/// the top of each subject's page, three of that subject. The same cards
/// for everyone that day (daily_deal.dart), played one after another: a
/// pick tapped and locked in, a share set on the track. A hundred points a
/// card — a right pick, or a guess on the answer itself, three fewer for
/// every point off.
///
/// Then the result, and what everybody else did: the server counts every
/// play of the same cards that day (lib/sync/daily_crowd.dart), so the
/// score is set among today's players, and each card says how many of them
/// got it right, or where their guesses fell. Where the server has not
/// counted enough players yet, the result says so plainly, and falls back
/// on what it already publishes: how often readers get each card right,
/// over every answer it has counted (functions/src/scorecard.ts, crowdOf).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../analytics.dart';
import '../../../data/explore_mix.dart' show subjectKeyOf;
import '../../../data/pill_bank.dart';
import '../../../data/pills_repository.dart' show dateKey;
import '../../../data/topics.dart' show topicKeyForName;
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../sync/daily_crowd.dart';
import '../../../sync/served.dart';
import '../../../theme.dart';
import '../../../utils/share_link.dart';
import '../../../widgets/subject_icon.dart';
import '../../explore_block.dart';
import 'answers.dart';
import 'bet_host.dart';
import 'bets_day.dart';
import 'block.dart';
import 'daily_deal.dart';
import 'deal.dart';
import 'five_challenge.dart';
import 'parts.dart';

/// What a guess is worth: a hundred for the answer itself, three fewer for
/// every point off, nothing past thirty-three; in tens, so a day's score
/// reads at a glance and falls into the crowd's tens.
int threePoints(double guess, double answer) {
  final double raw = (100 - 3 * (guess - answer).abs()).clamp(0, 100);
  return ((raw / 10).round() * 10).clamp(0, 100);
}

/// What an answer on [pill] is worth: a right pick a hundred, a wrong one
/// nothing; a share by how close it came ([threePoints]).
int dailyPoints(Pill pill, String response) {
  if (pill.challenge is PickOne) {
    return pill.challenge.accepts(response) ? 100 : 0;
  }
  final BetAnswer? a = answerOf(pill);
  final double? guess = double.tryParse(response);
  if (a == null || guess == null) return 0;
  return threePoints(guess, a.value);
}

/// The fewest players the crowd is spoken of from: below them, a share of
/// "today's players" would be a share of a handful.
const int kThreeCrowdFloor = 5;

/// The kind of bet a card of the day's games is kept under in the day's
/// bets (BetsDay): the card's answer, given in the game.
const String kDailyBet = 'daily';

/// The days the day's games were played, kept on the phone: each game's
/// score, and whether it was counted on the server — for the days in a
/// row, yesterday's score under today's, and so a play is sent once.
///
/// A game is kept as `day|game` (`2026-11-25|five`, `2026-11-25|three-art`);
/// a day alone is the Today's three Explore opened on before the five,
/// kept for the days in a row.
class ThreeDays extends ChangeNotifier {
  ThreeDays._();

  static ThreeDays instance = ThreeDays._();

  /// A fresh record, for a test.
  @visibleForTesting
  static void resetForTest() => instance = ThreeDays._();

  static const String _kKey = 'knowit.three';

  /// How many scores are kept: months of every game, and the days in a row
  /// worth saying.
  static const int _kept = 400;

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
                _scores.putIfAbsent(
                  e.key as String,
                  () => (e.value as num).round(),
                );
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
    final List<String> keys = _scores.keys.toList()..sort();
    while (keys.length > _kept) {
      _scores.remove(keys.removeAt(0));
    }
    _counted.removeWhere((k) => !_scores.containsKey(k));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kKey,
      jsonEncode({'s': _scores, 'c': _counted.toList()}),
    );
  }

  static String _keyOf(DailyGame game) => '${game.day}|${game.id}';

  /// [game]'s score, or null when it was not played.
  int? scoreOf(DailyGame game) => _scores[_keyOf(game)];

  /// Keeps [game]'s score.
  void put(DailyGame game, int score) {
    _scores[_keyOf(game)] = score;
    notifyListeners();
    unawaited(_save());
  }

  /// Whether [game]'s play is in the server's counts.
  bool counted(DailyGame game) => _counted.contains(_keyOf(game));

  /// Notes that [game]'s play is in the server's counts.
  void markCounted(DailyGame game) {
    _counted.add(_keyOf(game));
    notifyListeners();
    unawaited(_save());
  }

  /// Whether the game on Explore for every subject was played on [day]:
  /// the five, or the three it was before.
  bool _played(String day) =>
      _scores.containsKey('$day|five') || _scores.containsKey(day);

  /// The days in a row up to [today] that Today's five was played, today
  /// counted once it is played, and a run that ended yesterday still
  /// standing until today is over.
  int streak(DateTime today) {
    DateTime d = DateTime(today.year, today.month, today.day);
    if (!_played(dateKey(d))) d = DateTime(d.year, d.month, d.day - 1);
    int n = 0;
    while (_played(dateKey(d))) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }

  /// This week, Monday to Sunday: whether each day's five was played.
  List<bool> week(DateTime today) {
    final DateTime monday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );
    return [
      for (int i = 0; i < 7; i++)
        _played(dateKey(DateTime(monday.year, monday.month, monday.day + i))),
    ];
  }
}

/// The colours the result is drawn in: a card of paper on the night page,
/// of ink on the day one, so it stands apart from every subject's.
BetInk threeInk(BuildContext context) {
  final p = context.p;
  return BetInk(
    ground: p.inverse,
    ink: p.onInverse,
    fill: p.onInverse.withValues(alpha: 0.07),
    hair: p.onInverse.withValues(alpha: 0.16),
    sub: p.onInverse.withValues(alpha: 0.62),
    onInk: p.inverse,
    mark: p.onInverse,
  );
}

/// The block: Today's five on Explore for every subject, and each
/// subject's Today's three at the top of its page.
class ThreeBlock extends BetBlock {
  const ThreeBlock();

  @override
  String get name => 'three';

  /// On a subject's page too: its own three, at the top.
  @override
  bool get onSubjectPages => true;

  @override
  List<String> get sizes => const ['l'];

  @override
  String get defaultSize => 'l';

  @override
  int get defaultLimit => 3;

  /// Of the cards with a number for an answer, the ones a game of the day
  /// can ask: a pick of two or three, or a share set on the track. Cards
  /// whose answers are words are asked too ([dailyKindOf]).
  @override
  bool fits(BetAnswer a) => dailyKindOf(a.pill) != null;

  @override
  String title(AppLocalizations l, BetSection shelf) => l.threeTitle;

  @override
  String line(AppLocalizations l, BetSection shelf) => l.threeSame;

  /// The game on the page [host] is showing: the five on Explore for every
  /// subject, the subject's three on its page; null on a page this build
  /// has no subject for.
  DailyGame? gameOf(ExploreHost host) {
    final String day = BetsDay.instance.today;
    final String? subject = host.subject;
    if (subject == null) return DailyGame.five(day);
    final String? key = topicKeyForName(subject);
    return key == null ? null : DailyGame.three(day, key);
  }

  /// The cards a section names, when it names enough of them for [game]:
  /// on Explore for every subject one a subject, on a subject's page only
  /// its own, in the order named. The server counts no other game.
  List<Pill>? _named(ExploreHost host, BetSection shelf, DailyGame game) {
    if (shelf.section.source == null) return null;
    final Set<String> subjects = {};
    final List<Pill> out = [];
    for (final Pill p in host.cardsFor(shelf.section, limit: kBetPool)) {
      if (out.length == game.size) break;
      if (dailyKindOf(p) == null) continue;
      if (game.kind == DailyGameKind.five && !subjects.add(p.topic)) continue;
      if (game.kind == DailyGameKind.three && subjectKeyOf(p) != game.subject) {
        continue;
      }
      out.add(p);
    }
    return out.length == game.size ? out : null;
  }

  /// The day's deal for [game], from the date alone.
  List<Pill> _dealt(DailyGame game) {
    final DateTime now = BetsDay.instance.now;
    return game.subject == null
        ? DailyDeal.five(now)
        : DailyDeal.three(now, game.subject!);
  }

  /// [game]'s cards: the ones the section names, when it names enough;
  /// otherwise the day's deal. Kept for the day, so a bank that arrives at
  /// noon never changes a game half played, and every other shelf of bets
  /// leaves them alone.
  List<Pill> cardsOf(ExploreHost host, BetSection shelf, DailyGame game) {
    final BetsDay day = BetsDay.instance;
    final String key = shelf.dealKey(host, 'daily');
    final List<String>? kept = day.deal(key);
    if (kept != null) {
      return [
        for (final String id in kept)
          if (PillBank.byId(id) case final Pill p) p,
      ];
    }
    final List<Pill> cards = _named(host, shelf, game) ?? _dealt(game);
    day.keepDeal(key, [for (final Pill p in cards) p.id]);
    return cards;
  }

  @override
  bool canShow(ExploreHost host, BetSection shelf) {
    final DailyGame? game = gameOf(host);
    if (game == null) return false;
    return (_named(host, shelf, game) ?? _dealt(game)).length == game.size;
  }

  /// Never asked: [shelfOf] draws the game, which plays cards that have no
  /// number for an answer as well.
  @override
  Widget body(
    BuildContext context,
    ExploreHost host,
    BetSection shelf,
    List<BetAnswer> cards,
  ) => const SizedBox.shrink();

  /// No shelf's head: the card says what it is itself.
  @override
  Widget? shelfOf(BuildContext context, ExploreHost host, BetSection shelf) {
    final DailyGame? game = gameOf(host);
    if (game == null) return null;
    final List<Pill> cards = cardsOf(host, shelf, game);
    if (cards.length < game.size) return null;
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
        builder: (context, _) =>
            DailyCard(host: host, shelf: shelf, game: game, cards: cards),
      ),
    );
  }
}

/// The game, as far as the reader has come: the card in front of them, what
/// it came to, or the result.
class DailyCard extends StatelessWidget {
  const DailyCard({
    super.key,
    required this.host,
    required this.shelf,
    required this.game,
    required this.cards,
  });

  final ExploreHost host;
  final BetSection shelf;
  final DailyGame game;
  final List<Pill> cards;

  /// How many of the cards the reader has seen through, the answer told
  /// and moved on from.
  String get _atKey => 'daily:${game.id}:at';

  @override
  Widget build(BuildContext context) {
    final BetsDay day = BetsDay.instance;
    final int n = cards.length;
    final int at = (day.draft(_atKey) as num?)?.toInt().clamp(0, n) ?? 0;
    final List<Bet?> bets = [
      for (final Pill c in cards) day.betOn(kDailyBet, c.id),
    ];
    final bool done = at >= n && bets.every((b) => b != null);
    final int step = at.clamp(0, n - 1);
    return AnimatedSwitcher(
      duration: betMotion(context, 260),
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
          ? DailyResult(
              key: const ValueKey('three-result'),
              host: host,
              shelf: shelf,
              game: game,
              cards: cards,
              bets: [for (final Bet? b in bets) b!],
            )
          : _DailyStep(
              key: ValueKey('three-step-$step'),
              host: host,
              shelf: shelf,
              game: game,
              cards: cards,
              at: step,
              bet: bets[step],
              ink: BetInk.of(context, cards[step], BetTone.subject),
              onNext: () => day.keepDraft(_atKey, step + 1),
            ),
    );
  }
}

/// One of the cards: the answer given and locked in, or what it came to.
class _DailyStep extends StatelessWidget {
  const _DailyStep({
    super.key,
    required this.host,
    required this.shelf,
    required this.game,
    required this.cards,
    required this.at,
    required this.bet,
    required this.ink,
    required this.onNext,
  });

  final ExploreHost host;
  final BetSection shelf;
  final DailyGame game;
  final List<Pill> cards;
  final int at;
  final Bet? bet;
  final BetInk ink;
  final VoidCallback onNext;

  bool get _last => at == cards.length - 1;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Pill pill = cards[at];
    final DailyKind kind = dailyKindOf(pill) ?? DailyKind.pick;
    final BetsDay day = BetsDay.instance;
    final BetNumbers n = BetNumbers(
      Localizations.localeOf(context).languageCode,
    );
    final String key = BetsDay.draftKey(kDailyBet, pill.id);
    final Map draft = day.draft(key) is Map ? day.draft(key) as Map : const {};
    final bool laid = bet != null;
    final BetAnswer? share = kind == DailyKind.share ? answerOf(pill) : null;
    final double guess = laid
        ? double.tryParse(bet!.said) ?? 50
        : (draft['g'] as num?)?.toDouble() ?? 50;
    final int? chosen = laid
        ? int.tryParse(bet!.said)
        : (draft['o'] as num?)?.toInt();

    Future<void> lockIn() async {
      final String response = share != null ? plainResponse(guess) : '$chosen';
      BetFeel.lay();
      final int points = dailyPoints(pill, response);
      // A card already answered elsewhere is played all the same, as the
      // same cards are everyone's; only its first answer is the card's.
      final bool fresh = host.app.answerFor(pill.id) == null;
      await layBet(
        host,
        shelf.section,
        Bet(
          kind: kDailyBet,
          section: shelf.id,
          pill: pill.id,
          said: response,
          right: pill.challenge.accepts(response),
          facts: {
            'pts': points,
            'step': at + 1,
            'of': cards.length,
            'game': game.id,
            if (share != null) 'off': (guess - share.value).abs(),
          },
          at: DateTime.now().millisecondsSinceEpoch,
        ),
        pill: fresh ? pill : null,
        response: fresh ? response : null,
      );
      if (_last) finishDaily(game, cards);
    }

    final Widget game0 = share != null
        ? _ShareGame(
            pill: pill,
            answer: share,
            guess: guess,
            laid: laid,
            ink: ink,
            numbers: n,
            onChanged: (v) => day.keepDraft(key, {'g': v}),
          )
        : _PickGame(
            pill: pill,
            chosen: chosen,
            laid: laid,
            ink: ink,
            onPick: (i) {
              BetFeel.tick();
              day.keepDraft(key, {'o': i});
            },
          );

    final List<Widget> foot;
    if (laid) {
      // The card's words quoted inside the app's own, never run on into
      // them.
      final String said = switch (pill.challenge) {
        PickOne(:final correctOption) =>
          bet!.right
              ? l.dailyPickRight(l.quoted(correctOption))
              : l.dailyPickWrong(l.quoted(correctOption)),
        _ =>
          '${l.betsItIs(n.percent(share?.value ?? 0))} '
              '${l.threeYouSaid(n.percent(guess))}',
      };
      foot = [
        Semantics(
          liveRegion: true,
          child: Text(
            said,
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
          l.threePoints(dailyPoints(pill, bet!.said)),
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
          label: _last ? l.threeSeeScore : l.threeNext,
          ink: ink,
          height: 50,
          expand: true,
          onTap: onNext,
        ),
      ];
    } else {
      final bool ready = share != null || chosen != null;
      foot = [
        Opacity(
          opacity: ready ? 1 : 0.45,
          child: BetButton(
            key: ValueKey('three-lock-${pill.id}'),
            label: ready ? l.betsLockIn : l.betsPickFirst,
            ink: ink,
            height: 50,
            expand: true,
            onTap: ready ? lockIn : null,
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            game.kind == DailyGameKind.five ? l.fiveSame : l.threeSame,
            textAlign: TextAlign.center,
            style: AppText.body(size: 12.5, color: ink.sub),
          ),
        ),
      ];
    }

    return Container(
      key: ValueKey('three-card-${pill.id}'),
      decoration: BoxDecoration(
        color: ink.ground,
        borderRadius: BorderRadius.circular(26),
        border: ink.edge,
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DailyHead(game: game, at: at, of: cards.length, ink: ink),
          const SizedBox(height: 12),
          // The card's subject, as its own head says it.
          Row(
            children: [
              CardMark(pill: pill, size: 14, ink: ink.mark),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  l.subjectOf(pill.topic).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    size: 10.5,
                    spacing: 1.3,
                    color: ink.ink.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
          game0,
          const SizedBox(height: 16),
          ...foot,
        ],
      ),
    );
  }
}

/// A share set on the track: the guess in large figures over it, and once
/// locked in, the answer marked on it.
class _ShareGame extends StatelessWidget {
  const _ShareGame({
    required this.pill,
    required this.answer,
    required this.guess,
    required this.laid,
    required this.ink,
    required this.numbers,
    required this.onChanged,
  });

  final Pill pill;
  final BetAnswer answer;
  final double guess;
  final bool laid;
  final BetInk ink;
  final BetNumbers numbers;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          numbers.percent(guess),
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
          label: context.l10n.betsYourGuess,
          say: numbers.percent,
          answer: laid ? (answer.value, answer.value) : null,
          onChanged: laid ? null : onChanged,
        ),
      ],
    );
  }
}

/// A pick: the card's options one under another, the one chosen lit; once
/// locked in, the right one lit and ticked, a wrong pick ringed, the rest
/// stepped back.
class _PickGame extends StatelessWidget {
  const _PickGame({
    required this.pill,
    required this.chosen,
    required this.laid,
    required this.ink,
    required this.onPick,
  });

  final Pill pill;
  final int? chosen;
  final bool laid;
  final BetInk ink;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final PickOne pick = pill.challenge as PickOne;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < pick.options.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _Option(
            key: ValueKey('three-option-${pill.id}-$i'),
            label: pick.options[i],
            ink: ink,
            state: !laid
                ? (i == chosen ? _OptionState.chosen : _OptionState.idle)
                : i == pick.correct
                ? _OptionState.right
                : i == chosen
                ? _OptionState.wrong
                : _OptionState.out,
            said: !laid
                ? null
                : i == pick.correct
                ? l.betsRight
                : i == chosen
                ? l.betsYourPick
                : null,
            onTap: laid ? null : () => onPick(i),
          ),
        ],
      ],
    );
  }
}

enum _OptionState { idle, chosen, right, wrong, out }

/// One option of a pick, a row the width of the card in its ink: at rest a
/// step off the card, chosen filled, right filled and ticked, a wrong pick
/// ringed and crossed, the others faded.
class _Option extends StatelessWidget {
  const _Option({
    super.key,
    required this.label,
    required this.ink,
    required this.state,
    this.said,
    this.onTap,
  });

  final String label;
  final BetInk ink;
  final _OptionState state;

  /// What a screen reader adds once the pick is locked in: the right
  /// answer, the reader's pick.
  final String? said;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Duration motion = betMotion(context, 180);
    final bool lit =
        state == _OptionState.chosen || state == _OptionState.right;
    final Color fg = lit ? ink.onInk : ink.ink;
    final IconData? icon = switch (state) {
      _OptionState.right => Icons.check_rounded,
      _OptionState.wrong => Icons.close_rounded,
      _ => null,
    };
    return Semantics(
      button: onTap != null,
      selected: state == _OptionState.chosen,
      label: said == null ? label : '$label. $said',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          duration: motion,
          opacity: state == _OptionState.out ? 0.45 : 1,
          child: AnimatedContainer(
            duration: motion,
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
            decoration: BoxDecoration(
              color: lit
                  ? ink.ink
                  : state == _OptionState.wrong
                  ? ink.ink.withValues(alpha: 0)
                  : ink.fill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: state == _OptionState.wrong
                    ? ink.ink
                    : ink.ink.withValues(alpha: 0),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppText.body(
                      size: 15,
                      weight: FontWeight.w600,
                      height: 1.3,
                      color: fg,
                    ),
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 10),
                  Icon(icon, size: 20, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The card's head: what it is, which of the cards, and a mark a card.
class _DailyHead extends StatelessWidget {
  const _DailyHead({
    required this.game,
    required this.at,
    required this.of,
    required this.ink,
  });

  final DailyGame game;
  final int at;
  final int of;
  final BetInk ink;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      children: [
        Expanded(
          child: BetKicker(
            game.kind == DailyGameKind.five ? l.fiveTitle : l.threeTitle,
            color: ink.ink,
          ),
        ),
        BetKicker(l.threeStep(at + 1, of), color: ink.ink),
        const SizedBox(width: 8),
        ExcludeSemantics(
          child: Row(
            children: [
              for (int i = 0; i < of; i++)
                Container(
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                  width: i == at ? 16 : 10,
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= at ? ink.ink : ink.ink.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The last card is in: the score kept, the play sent to be counted, and
/// noted.
void finishDaily(DailyGame game, List<Pill> cards) {
  final BetsDay day = BetsDay.instance;
  int total = 0;
  int right = 0;
  for (final Pill c in cards) {
    final Bet? b = day.betOn(kDailyBet, c.id);
    total += (b?.facts['pts'] as num?)?.toInt() ?? 0;
    if (b?.right == true) right++;
  }
  final ThreeDays days = ThreeDays.instance;
  days.put(game, total);
  Analytics.capture('three done', {
    'game': game.name,
    'subject': game.subject ?? 'all',
    'score': total,
    'of': game.max,
    'right': right,
    'streak': days.streak(day.now),
  });
  sendDaily(game, cards);
}

/// Sends [game]'s play to be counted, unless it is already: once a run,
/// so one the server could not take is tried again at the next.
void sendDaily(DailyGame game, List<Pill> cards) {
  if (ThreeDays.instance.counted(game)) return;
  final BetsDay day = BetsDay.instance;
  final List<(String, String)> said = [
    for (final Pill c in cards)
      if (day.betOn(kDailyBet, c.id) case final Bet b) (c.id, b.said),
  ];
  if (said.length != cards.length) return;
  unawaited(
    DailyCrowd.send(
      game.keyFor([for (final Pill c in cards) c.id]),
      DailyPlay(
        day: game.day,
        game: game.name,
        said: said,
        tz: day.now.timeZoneOffset.inMinutes,
      ),
      onCounted: () => ThreeDays.instance.markCounted(game),
      onError: (error) => Analytics.error(error, null, where: 'daily crowd'),
    ),
  );
}

/// How many of today's five the reader got right, as a challenge carries
/// it (five_challenge.dart): once all five are locked in today, and only
/// when they are the five the site has for the day — null before then, or
/// for a five the server named instead. Read from the day's bets, which
/// are read once Explore has shown a shelf of bets; [BetsDay.load] first
/// where that may not have happened yet.
int? fiveRightToday() {
  final BetsDay day = BetsDay.instance;
  final List<Pill> five = DailyDeal.five(day.now);
  if (five.length != 5) return null;
  int right = 0;
  for (final Pill p in five) {
    final Bet? b = day.betOn(kDailyBet, p.id);
    if (b == null || b.facts['game'] != DailyGameKind.five.name) return null;
    if (b.right) right++;
  }
  return right;
}

/// The result: the score, where it stands among today's players, and card
/// by card what the reader said, what it is, and how everybody did.
class DailyResult extends StatefulWidget {
  const DailyResult({
    super.key,
    required this.host,
    required this.shelf,
    required this.game,
    required this.cards,
    required this.bets,
  });

  final ExploreHost host;
  final BetSection shelf;
  final DailyGame game;
  final List<Pill> cards;
  final List<Bet> bets;

  @override
  State<DailyResult> createState() => _DailyResultState();
}

class _DailyResultState extends State<DailyResult> {
  /// The game's counts as last read: listened to once for as long as the
  /// result is shown, not again at every rebuild.
  StreamSubscription<DailyCounts?>? _watch;
  DailyCounts? _read;
  late String _key;

  @override
  void initState() {
    super.initState();
    _listen();
    DailyCrowd.revision.addListener(_heard);
    // A play the server could not take when the last card was locked in,
    // on an earlier day of the app's life or a moment ago: tried again,
    // once a run.
    sendDaily(widget.game, widget.cards);
  }

  void _listen() {
    _key = widget.game.keyFor([for (final Pill c in widget.cards) c.id]);
    unawaited(_watch?.cancel());
    _watch = DailyCrowd.store?.watch(_key).listen(
      (counts) {
        if (mounted && counts != null) setState(() => _read = counts);
      },
      // A document the phone may not read yet: the counts the play came
      // back with stand, or the lines that say there are none.
      onError: (Object _) {},
    );
  }

  @override
  void didUpdateWidget(DailyResult old) {
    super.didUpdateWidget(old);
    if (old.game.keyFor([for (final Pill c in old.cards) c.id]) !=
        widget.game.keyFor([for (final Pill c in widget.cards) c.id])) {
      _read = null;
      _listen();
    }
  }

  void _heard() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DailyCrowd.revision.removeListener(_heard);
    unawaited(_watch?.cancel());
    super.dispose();
  }

  int _points(Bet b) => (b.facts['pts'] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final BetInk ink = threeInk(context);
    final BetNumbers n = BetNumbers(
      Localizations.localeOf(context).languageCode,
    );
    final DailyGame game = widget.game;
    final List<Bet> bets = widget.bets;
    final ThreeDays days = ThreeDays.instance;
    final int total = bets.fold(0, (s, b) => s + _points(b));
    final int right = bets.where((b) => b.right).length;
    final DailyCounts? counts = _read ?? DailyCrowd.countedWith(_key);
    final DateTime now = BetsDay.instance.now;
    final String yesterday = dateKey(
      DateTime(now.year, now.month, now.day - 1),
    );
    final int? before = days.scoreOf(
      game.subject == null
          ? DailyGame.five(yesterday)
          : DailyGame.three(yesterday, game.subject!),
    );

    Widget square(int points) => Container(
      width: 20,
      height: 20,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BetKicker(
                game.kind == DailyGameKind.five ? l.fiveDone : l.threeDone,
                color: ink.ink,
              ),
              const SizedBox(height: 10),
              // The score as large as the card allows, a square a card at
              // its right whatever the text size.
              Semantics(
                label:
                    '${l.betsScoreSentence(right, game.size)} '
                    '$total ${l.dailyOf(game.max)}',
                excludeSemantics: true,
                child: Row(
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
                                l.dailyOf(game.max),
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
                        children: [
                          for (final Bet b in bets) square(_points(b)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Standing(
                counts: counts,
                pending: DailyCrowd.isSending(_key),
                game: game,
                cards: widget.cards,
                score: total,
                right: right,
                ink: ink,
                numbers: n,
              ),
              const SizedBox(height: 18),
              BetKicker(l.dailyEach, color: ink.sub),
              const SizedBox(height: 8),
              for (final (int i, Pill c) in widget.cards.indexed)
                _DailyRow(
                  pill: c,
                  bet: bets[i],
                  points: _points(bets[i]),
                  at: i,
                  of: widget.cards.length,
                  counts: counts,
                  ink: ink,
                  numbers: n,
                  onTap: () =>
                      widget.host.open(widget.shelf.section, widget.cards, c),
                ),
              const SizedBox(height: 8),
              // Today's five, where the server says so, goes on as a
              // challenge: the same five for a friend, on the site, with
              // the score to beat. Each button on a line of its own, as
              // "Challenge a friend" is long in most languages and is never
              // cut. Otherwise, and for a subject's three, the score as
              // squares.
              if (_challenges)
                _OutlineButton(
                  key: const ValueKey('three-challenge'),
                  label: l.challengeFriend,
                  ink: ink,
                  filled: true,
                  onTap: () => _challenge(context, right),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: BetButton(
                        key: const ValueKey('three-send'),
                        label: l.threeSend,
                        ink: ink,
                        height: 50,
                        expand: true,
                        onTap: () => _send(context, total),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _why(l, ink)),
                  ],
                ),
              if (_challenges) ...[const SizedBox(height: 10), _why(l, ink)],
            ],
          ),
        ),
        if (before != null) ...[
          const SizedBox(height: 10),
          Text(
            game.kind == DailyGameKind.five
                ? l.fiveYesterday(before)
                : l.threeYesterday(before),
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

  /// The cards again, from the first, where each answer is explained.
  Widget _why(AppLocalizations l, BetInk ink) => _OutlineButton(
    key: const ValueKey('three-why'),
    label: l.threeWhy,
    ink: ink,
    onTap: () => widget.host.open(
      widget.shelf.section,
      widget.cards,
      widget.cards.first,
    ),
  );

  /// Whether the result sends the game on as a challenge: today's five,
  /// while the server says so, and only the five the site has for the day,
  /// which the friend will be played.
  bool get _challenges =>
      widget.game.kind == DailyGameKind.five &&
      widget.host.app.shareChallengeOn &&
      isSitesFive(BetsDay.instance.now, widget.cards);

  /// Sent on as a challenge: a line with how many of the five were right,
  /// and the site's page where a friend plays the same five. Never the
  /// answers.
  Future<void> _challenge(BuildContext context, int right) async {
    final l = context.l10n;
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    final bool shared = await sendFiveChallenge(
      l,
      from: 'five result',
      day: widget.game.day,
      right: right,
    );
    if (!shared) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.copiedToClipboard),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Sent on: the game, the day, the score, a square for each card, and
  /// the way in. How it went, never the answers.
  Future<void> _send(BuildContext context, int total) async {
    final l = context.l10n;
    final DailyGame game = widget.game;
    final String locale = Localizations.localeOf(context).toString();
    final DateTime now = BetsDay.instance.now;
    String date;
    try {
      date = DateFormat.MMMd(locale).format(now);
    } catch (_) {
      date = DateFormat.MMMd('en').format(now);
    }
    String square(int points) => points >= 80
        ? '🟩'
        : points >= 40
        ? '🟨'
        : '⬜';
    final int streak = ThreeDays.instance.streak(now);
    final String text = [
      if (game.kind == DailyGameKind.five)
        l.fiveShareHead(date)
      else
        l.threeShareHeadIn(l.subjectOf(widget.cards.first.topic), date),
      if (game.kind == DailyGameKind.five && streak > 0)
        l.dailyShareScore(total, game.max, streak)
      else
        l.dailyShareScoreAlone(total, game.max),
      [for (final Bet b in widget.bets) square(_points(b))].join(),
      ShareRef.three.link,
    ].join('\n');
    final bool shared = await sendText(text);
    Analytics.capture('three shared', {
      'game': game.name,
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

/// Where the score stands, said as plainly as the numbers allow: among
/// today's players with the spread of their scores, the reader's own band
/// marked, once there are enough of them; among the first few, without a
/// share of a handful; while the play is on its way, that it is; and with
/// no count of today at all, how often readers get these cards right where
/// the server has said, or that today's players cannot be counted.
class _Standing extends StatelessWidget {
  const _Standing({
    required this.counts,
    required this.pending,
    required this.game,
    required this.cards,
    required this.score,
    required this.right,
    required this.ink,
    required this.numbers,
  });

  final DailyCounts? counts;
  final bool pending;
  final DailyGame game;
  final List<Pill> cards;
  final int score;
  final int right;
  final BetInk ink;
  final BetNumbers numbers;

  /// How many of these cards a reader gets right on average, from what the
  /// server publishes of every card (scorecard.ts, crowdOf): null unless it
  /// says it of every one.
  double? _average() {
    final ServedExplore? served = Served.instance.lastExplore;
    if (served == null) return null;
    double sum = 0;
    for (final Pill c in cards) {
      final double? wrong = served.wrongShare(c.id);
      if (wrong == null) return null;
      sum += 1 - wrong;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final DailyCounts? c = counts;
    final ({int players, int beaten})? at = c?.place(score);
    final int players = at?.players ?? 0;
    final String said;
    if (at != null && players >= kThreeCrowdFloor) {
      said = at.beaten >= 50
          ? l.elided(l.dailyBetter(at.beaten, players))
          : l.dailyPlayers(players);
    } else if (players > 0) {
      said = l.dailyFirst(players);
    } else if (pending) {
      said = l.dailyCounting;
    } else {
      final double? average = _average();
      said = average == null
          ? l.dailyUncounted
          : l.dailyAverage(
              right,
              cards.length,
              NumberFormat.decimalPatternDigits(
                locale: numbers.locale,
                decimalDigits: 1,
              ).format(average),
            );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        if (c != null && players >= kThreeCrowdFloor)
          _Spread(
            key: const ValueKey('three-spread'),
            scores: c.scores,
            score: score,
            max: game.max,
            ink: ink,
          )
        else
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / game.max,
                minHeight: 8,
                backgroundColor: ink.ink.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(ink.ink),
              ),
            ),
          ),
      ],
    );
  }
}

/// Today's players by score, in ten bands from none to the most, each bar
/// as tall as its share of the busiest: the reader's band in full ink with
/// "You" under it, the rest faint. The bars grow as players come in.
class _Spread extends StatelessWidget {
  const _Spread({
    super.key,
    required this.scores,
    required this.score,
    required this.max,
    required this.ink,
  });

  /// How many came to each score, in tens.
  final List<int> scores;
  final int score;
  final int max;
  final BetInk ink;

  static const int _bands = 10;
  static const double _tall = 48;
  static const double _gap = 4;

  /// The band a score in tens falls in: the most in the last.
  int _bandOf(int bucket) => (bucket * 100 ~/ max).clamp(0, _bands - 1);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final List<int> n = List.filled(_bands, 0);
    for (int b = 0; b < scores.length; b++) {
      n[_bandOf(b)] += scores[b];
    }
    final int busiest = n.fold(0, (a, b) => b > a ? b : a);
    final int mine = _bandOf(score ~/ 10);
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
                          duration: betMotion(context, 420),
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
                                : ink.ink.withValues(alpha: 0.2),
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
                height: MediaQuery.textScalerOf(context).scale(16),
                child: Stack(
                  children: [
                    if (mine > 1)
                      Positioned(left: 0, child: Text('0', style: small)),
                    if (mine < _bands - 2)
                      Positioned(right: 0, child: Text('$max', style: small)),
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

/// One card on the result: its subject and question, what the reader said
/// against the answer, the points, and how everybody else did — the share
/// of today's players who got it right, or on a share where their guesses
/// came to on average; failing today's, how often readers get it right
/// over every answer counted; failing both, that too few have answered
/// yet. A tap opens the card.
class _DailyRow extends StatelessWidget {
  const _DailyRow({
    required this.pill,
    required this.bet,
    required this.points,
    required this.at,
    required this.of,
    required this.counts,
    required this.ink,
    required this.numbers,
    required this.onTap,
  });

  final Pill pill;
  final Bet bet;
  final int points;
  final int at;
  final int of;
  final DailyCounts? counts;
  final BetInk ink;
  final BetNumbers numbers;
  final VoidCallback onTap;

  /// What the reader said, against the answer: the right answer, and
  /// above it on a line of its own the reader's, when it was another. A
  /// card's words are quoted, so they never run on into the app's.
  String _said(AppLocalizations l) {
    switch (pill.challenge) {
      case PickOne(:final options, :final correctOption):
        final String right = l.dailyPickRight(l.quoted(correctOption));
        if (bet.right) return right;
        final int? i = int.tryParse(bet.said);
        final String given = i != null && i >= 0 && i < options.length
            ? options[i]
            : bet.said;
        return '${l.dailyYourPick(l.quoted(given))}\n$right';
      default:
        final BetAnswer? a = answerOf(pill);
        return '${l.dailyYourPick(numbers.percent(double.tryParse(bet.said) ?? 0))}'
            '\n${l.dailyPickRight(numbers.percent(a?.value ?? 0))}';
    }
  }

  /// How everybody did, and how much of the bar it fills, if a bar says it.
  ({String text, double? share}) _crowd(AppLocalizations l) {
    final DailyItemCounts? today = counts?.items[pill.id];
    if (today != null &&
        (counts?.players ?? 0) >= kThreeCrowdFloor &&
        today.n >= kThreeCrowdFloor) {
      final double? guess = pill.challenge is PickOne ? null : today.meanGuess;
      if (guess != null) {
        return (text: l.dailyItemGuess(numbers.percent(guess)), share: null);
      }
      return (
        text: l.elided(l.dailyItemRight((today.rightShare * 100).round())),
        share: today.rightShare,
      );
    }
    final double? wrong = Served.instance.lastExplore?.wrongShare(pill.id);
    if (wrong != null) {
      return (
        text: l.elided(l.crowdGotRight(((1 - wrong) * 100).round())),
        share: 1 - wrong,
      );
    }
    return (text: l.dailyItemFew, share: null);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final String said = _said(l);
    final ({String text, double? share}) crowd = _crowd(l);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label: [
          l.threeStep(at + 1, of),
          pill.question,
          said,
          l.threePoints(points),
          crowd.text,
        ].join('. '),
        excludeSemantics: true,
        child: Material(
          color: ink.fill,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            key: ValueKey('three-row-${pill.id}'),
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CardMark(pill: pill, size: 11, ink: ink.sub),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    l.subjectOf(pill.topic).toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.label(
                                      size: 9.5,
                                      spacing: 1.2,
                                      color: ink.sub,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            // The whole question, however many lines it
                            // takes: nothing in the game is cut.
                            Text(
                              pill.question,
                              style: AppText.body(
                                size: 13.5,
                                weight: FontWeight.w700,
                                height: 1.25,
                                color: ink.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              said,
                              style: AppText.body(
                                size: 12.5,
                                height: 1.3,
                                color: ink.sub,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$points',
                        key: ValueKey('three-pts-${pill.id}'),
                        style: AppText.display(
                          size: 20,
                          weight: FontWeight.w700,
                          color: ink.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (crowd.share != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: crowd.share,
                        minHeight: 4,
                        backgroundColor: ink.hair,
                        valueColor: AlwaysStoppedAnimation(ink.ink),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    crowd.text,
                    key: ValueKey('three-row-crowd-${pill.id}'),
                    style: AppText.body(
                      size: 12,
                      weight: FontWeight.w600,
                      height: 1.3,
                      color: ink.ink.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
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
    this.filled = false,
  });

  final String label;
  final BetInk ink;
  final VoidCallback onTap;

  /// Filled in the ink, as the first of the two: "Challenge a friend",
  /// whose words, long in most languages, go onto a second line at a large
  /// text size rather than be cut.
  final bool filled;

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
          minHeight: math.max(
            filled ? 50 : 0,
            MediaQuery.textScalerOf(context).scale(12.5) + 34,
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? ink.ink : null,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: ink.ink, width: 1.6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppText.body(
            size: 14,
            weight: FontWeight.w700,
            color: filled ? ink.onInk : ink.ink,
          ),
        ),
      ),
    ),
  );
}
