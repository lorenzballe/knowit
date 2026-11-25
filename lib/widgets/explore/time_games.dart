/// The three challenges of time, each played on a screen of its own
/// (challenge_screen.dart) with moments from the cards
/// (lib/data/dated_lines.dart):
///
/// - In order: four moments, each missing its year, tapped in the order
///   they happened; then they slide into their true order, years and all.
/// - What year?: three moments, each missing its year, dialled in on a
///   ruler of the centuries; the closer, the more points.
/// - Before or after?: six moments one after another, each said to have
///   happened before or after the one above it, whose year is shown.
///
/// Each has a round a day that is the same for everybody, and plays again
/// with the day's next round. A round is kept for the day as it is played
/// (`ExplorePlay`), so a screen opened again opens where the reader left
/// off, or on how it went. A moment is a tap from its card in the review;
/// playing one never counts a card read.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../analytics.dart';
import '../../data/dated_lines.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../state/explore_play.dart';
import '../../theme.dart';
import '../../utils/share_link.dart';
import 'challenge_kit.dart';
import 'challenge_screen.dart';
import 'challenges.dart';
import 'parts.dart' show CardHead;

/// What the three games share: the day's deal, the round in play, and the
/// round kept for the day as it is played.
abstract class TimeChallenge extends ChallengeGame {
  TimeChallenge({
    required this.deal,
    required this.onOpen,
    this.onShown,
    int? now,
  }) : now = now ?? DateTime.now().year {
    _restore();
  }

  /// The day's moments.
  final TimeDeal deal;

  /// Opens a moment's card.
  final void Function(List<Pill>, Pill) onOpen;

  /// A moment was put in front of the reader.
  final ValueChanged<Pill>? onShown;

  /// This year, for how far back a year is.
  final int now;

  /// Which game of time this is.
  TimeGame get game;

  /// How many answers a round takes.
  int get needed;

  int _round = 0;

  /// The round's moments, in the order the game deals them.
  List<DatedLine> lines = const [];

  /// The answers so far, as kept: what each game keeps for one.
  List<Object?> answers = [];

  final Set<String> _shown = {};

  @override
  String get id => game.salt;

  /// The round of the day being played: 0 for the day's first.
  int get round => _round;

  String get _key => game.salt;

  void _restore() {
    final Object? kept = ExplorePlay.instance[_key];
    if (kept is Map && kept['r'] is int && kept['ids'] is List) {
      final int r = kept['r'] as int;
      final List<DatedLine> dealt = deal.round(game, r);
      final List<Object?> ids = kept['ids'] as List;
      if (dealt.length == ids.length &&
          [
            for (int i = 0; i < ids.length; i++) dealt[i].pill.id == ids[i],
          ].every((same) => same)) {
        _round = r;
        lines = dealt;
        answers = [...(kept['a'] as List? ?? const [])];
        return;
      }
    }
    _round = 0;
    lines = deal.round(game, 0);
    answers = [];
  }

  void _keep() => ExplorePlay.instance.put(_key, {
    'r': _round,
    'ids': [for (final DatedLine d in lines) d.pill.id],
    'a': answers,
  });

  /// Whether there is a round to play at all.
  bool get playable => lines.length == game.size;

  @override
  bool get over => answers.length >= needed;

  @override
  bool get replays => true;

  @override
  String playLabel(AppLocalizations l) =>
      answers.isNotEmpty && !over ? l.gameContinue : l.gamePlay;

  @override
  void start() {
    if (over) {
      _round++;
      lines = deal.round(game, _round);
      answers = [];
    }
    if (answers.isEmpty) {
      Analytics.capture('explore ${game.salt} started', {'round': _round});
    }
    _keep();
    notifyListeners();
  }

  /// [answer] given: kept for the day; the round over once it is the last.
  void answer(Object? answer) {
    answers.add(answer);
    _keep();
    if (over) {
      Analytics.capture('explore ${game.salt} finished', {
        ...finishedFacts,
        'round': _round,
      });
    }
    notifyListeners();
  }

  /// What a round's end is noted with.
  Map<String, Object> get finishedFacts;

  /// The round's score, as its tile says it once the round is over: "3/4".
  String get tally;

  /// Says [line] was shown.
  void shown(DatedLine line) {
    if (_shown.add(line.pill.id)) onShown?.call(line.pill);
  }

  List<Pill> get pills => [for (final DatedLine d in lines) d.pill];

  /// The share: the game, the day, the score, the squares.
  Future<void> shareScore(
    BuildContext context, {
    required String title,
    required String score,
    required List<bool?> marks,
    required Map<String, Object> facts,
  }) {
    final l = context.l10n;
    return shareGame(
      context,
      text: [
        l.gameShareHead(title, gameDate(context)),
        score,
        gameSquares(marks),
        ShareRef.challenges.link,
      ].join('\n'),
      event: 'explore ${game.salt} shared',
      facts: facts,
    );
  }
}

// ── In order ─────────────────────────────────────────────────────────────

/// In order: four moments, put in the order they happened.
class InOrderChallenge extends TimeChallenge {
  InOrderChallenge({
    required super.deal,
    required super.onOpen,
    super.onShown,
    super.now,
    required this.title,
  });

  /// The game's name, for the score sent on.
  final String title;

  @override
  TimeGame get game => TimeGame.order;

  /// One answer: the four, by id, in the order the reader put them.
  @override
  int get needed => 1;

  /// The reader's order, by id, once checked.
  List<String> get said => over
      ? [for (final Object? id in answers.first as List) '$id']
      : const [];

  /// The four in the order they happened.
  List<DatedLine> get truth =>
      [...lines]..sort((a, b) => a.year.compareTo(b.year));

  /// Whether the moment at [i] of the true order is where the reader put
  /// it.
  bool rightAt(int i) {
    final List<String> s = said;
    return s.length == lines.length && s[i] == truth[i].pill.id;
  }

  int get right => [
    for (int i = 0; i < lines.length; i++) rightAt(i),
  ].where((r) => r).length;

  /// What a random order puts in its place, on average: one, whatever the
  /// number of moments.
  static const int chance = 1;

  @override
  String get tally => '$right/${lines.length}';

  @override
  Map<String, Object> get finishedFacts => {'right': right};

  @override
  String rules(AppLocalizations l) => l.inOrderRules;

  @override
  Widget play(BuildContext context, GameKit kit) =>
      _InOrderPlay(game: this, kit: kit);

  @override
  GameOutcome outcome(BuildContext context, GameKit kit) {
    final l = context.l10n;
    final List<DatedLine> t = truth;
    final List<String> s = said;
    final int n = lines.length;
    return GameOutcome(
      score: '$right',
      of: '$n',
      label: l.nOfM(right, n),
      line: right == n
          ? l.inOrderPerfect
          : challengeChance(l, right: right, chance: chance, of: n),
      figures: [
        (label: l.challengeAccuracy, value: gamePercent(context, right, n)),
      ],
      review: [
        for (int i = 0; i < n; i++)
          GameReviewItem(
            key: ValueKey('in-order-row-${t[i].pill.id}'),
            text: t[i].text,
            tag: '${t[i].year}',
            tagDark: true,
            mark: rightAt(i),
            detail: l.inOrderYours(s.indexOf(t[i].pill.id) + 1),
            semantics:
                '${t[i].year}. ${t[i].text} '
                '${l.inOrderYours(s.indexOf(t[i].pill.id) + 1)}. '
                '${rightAt(i) ? l.gameRight : l.gameWrong}.',
            onTap: () => onOpen([for (final d in t) d.pill], t[i].pill),
          ),
      ],
    );
  }

  @override
  Future<void> share(BuildContext context) => shareScore(
    context,
    title: title,
    score: context.l10n.gameShareScore(right, lines.length),
    marks: [for (int i = 0; i < lines.length; i++) rightAt(i)],
    facts: {'right': right},
  );
}

class _InOrderPlay extends StatefulWidget {
  const _InOrderPlay({required this.game, required this.kit});

  final InOrderChallenge game;
  final GameKit kit;

  @override
  State<_InOrderPlay> createState() => _InOrderPlayState();
}

class _InOrderPlayState extends State<_InOrderPlay> {
  InOrderChallenge get _game => widget.game;

  /// The moments tapped, by id, earliest first.
  final List<String> _picks = [];

  /// Whether the order has been checked and the moments told.
  bool _told = false;

  @override
  void initState() {
    super.initState();
    for (final DatedLine d in _game.lines) {
      _game.shown(d);
    }
  }

  void _tap(DatedLine d) {
    if (_told) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (!_picks.remove(d.pill.id)) _picks.add(d.pill.id);
    });
  }

  void _check() {
    if (_told || _picks.length != _game.lines.length) return;
    setState(() => _told = true);
    _game.answer([..._picks]);
    HapticFeedback.lightImpact();
    widget.kit.say(context.l10n.nOfM(_game.right, _game.lines.length));
    widget.kit.finish(after: const Duration(milliseconds: 1900));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final GameKit kit = widget.kit;
    final Palette p = kit.palette;
    final List<DatedLine> shown = _game.lines;
    final List<DatedLine> truth = _game.truth;
    final int n = shown.length;
    final bool all = _picks.length == n;
    final String prompt = _told
        ? l.nOfM(_game.right, n)
        : _picks.isEmpty
        ? l.inOrderFirst
        : all
        ? l.inOrderReady
        : l.inOrderNext;
    return GamePlayFrame(
      kit: kit,
      status: Text(
        prompt,
        key: const ValueKey('in-order-prompt'),
        maxLines: 2,
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4),
        style: AppText.display(
          size: 22,
          weight: FontWeight.w400,
          height: 1.2,
          spacing: -0.3,
          color: p.ink,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          const double gap = 8;
          final double h = (box.maxHeight - gap * (n - 1)) / n;
          return Stack(
            children: [
              for (final DatedLine d in shown)
                () {
                  final int slot = _told ? truth.indexOf(d) : shown.indexOf(d);
                  final int pick = _picks.indexOf(d.pill.id);
                  return AnimatedPositioned(
                    key: ValueKey('in-order-card-${d.pill.id}'),
                    duration: kit.motion(280),
                    curve: Curves.easeOutCubic,
                    left: 0,
                    right: 0,
                    top: slot * (h + gap),
                    height: h,
                    child: _Moment(
                      line: d,
                      rank: pick < 0 ? null : pick + 1,
                      told: _told,
                      right: _told ? _game.rightAt(slot) : null,
                      tone: kit.look.tone,
                      accent: kit.accent,
                      onTap: () => _tap(d),
                    ),
                  );
                }(),
            ],
          );
        },
      ),
      actions: GameButton.primary(
        key: const ValueKey('in-order-check'),
        context: context,
        label: l.inOrderCheck,
        tone: kit.look.tone,
        onTap: all && !_told ? _check : null,
      ),
    );
  }
}

/// One moment of In order, set as a line of a page: in its margin where it
/// was put — an empty ring before it is, its place after — and once told,
/// its year, in the calm green where it stands right and the calm red
/// where it does not.
class _Moment extends StatelessWidget {
  const _Moment({
    required this.line,
    required this.rank,
    required this.told,
    required this.right,
    required this.tone,
    required this.accent,
    required this.onTap,
  });

  final DatedLine line;
  final int? rank;
  final bool told;
  final bool? right;
  final ChallengeTone tone;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final int? r = rank;
    final bool on = r != null && !told;
    return Semantics(
      button: !told,
      selected: on,
      label: [
        if (told) '${line.year}.',
        line.statement,
        if (r != null) l.inOrderPlaced(r),
        if (right case final bool ok) ok ? l.gameRight : l.gameWrong,
      ].join(' '),
      excludeSemantics: true,
      onTap: told ? null : onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: on
                  ? tone.vivid
                  : p.isDark
                  ? p.surfaceRaised
                  : p.line,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              SizedBox(
                width: 62,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _Place(
                    rank: r,
                    year: told ? line.year : null,
                    right: right,
                    tone: tone,
                  ),
                ),
              ),
              Expanded(
                child: MomentText(
                  line: line,
                  shown: told,
                  max: 23,
                  min: 13,
                  ink: p.ink,
                  accent: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where a moment was put — an empty ring before it is, its place in the
/// ring after — and once told, its year, in a calm colour.
class _Place extends StatelessWidget {
  const _Place({
    required this.rank,
    required this.year,
    required this.right,
    required this.tone,
  });

  final int? rank;
  final int? year;
  final bool? right;
  final ChallengeTone tone;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final TextScaler scaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.2);
    final int? y = year;
    if (y != null) {
      final Color c = right == true ? challengeRight(p) : challengeWrong(p);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$y',
          textScaler: scaler,
          style: AppText.body(
            size: 13.5,
            weight: FontWeight.w800,
            height: 1,
            color: c,
          ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      );
    }
    final int? r = rank;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: r == null ? null : tone.vivid,
        border: r == null ? Border.all(color: p.lineStrong, width: 1.5) : null,
      ),
      alignment: Alignment.center,
      child: r == null
          ? null
          : Text(
              '$r',
              textScaler: scaler,
              style: AppText.display(
                size: 16,
                weight: FontWeight.w700,
                height: 1,
                color: tone.ink,
              ),
            ),
    );
  }
}

// ── What year? ───────────────────────────────────────────────────────────

/// What year?: three moments, each year dialled in.
class WhatYearChallenge extends TimeChallenge {
  WhatYearChallenge({
    required super.deal,
    required super.onOpen,
    super.onShown,
    super.now,
    required this.title,
  });

  final String title;

  /// The year the dial stands at when a moment comes up: the middle of
  /// the century most moments are from, the same for every moment.
  static const int startYear = 1950;

  /// The earliest year the dial reaches.
  static const int firstYear = 1000;

  @override
  TimeGame get game => TimeGame.year;

  @override
  int get needed => lines.length;

  /// The year dialled for the moment at [i], once locked.
  int? guessAt(int i) => i < answers.length ? (answers[i] as num).toInt() : null;

  int pointsAt(int i) {
    final int? g = guessAt(i);
    return g == null ? 0 : yearPoints(g, lines[i].year, now: now);
  }

  /// A year near enough to count as got: half the points or more.
  bool? rightAt(int i) => guessAt(i) == null ? null : pointsAt(i) >= 5;

  int get points => [
    for (int i = 0; i < lines.length; i++) pointsAt(i),
  ].fold(0, (a, b) => a + b);

  @override
  String get tally => '$points/${lines.length * 10}';

  int get yearsOff => [
    for (int i = 0; i < answers.length; i++) (guessAt(i)! - lines[i].year).abs(),
  ].fold(0, (a, b) => a + b);

  @override
  Map<String, Object> get finishedFacts => {'points': points, 'off': yearsOff};

  @override
  String rules(AppLocalizations l) => l.whatYearRules;

  @override
  Widget play(BuildContext context, GameKit kit) =>
      _WhatYearPlay(game: this, kit: kit);

  @override
  GameOutcome outcome(BuildContext context, GameKit kit) {
    final l = context.l10n;
    final int n = lines.length;
    return GameOutcome(
      score: '$points',
      of: '${n * 10}',
      label: l.whatYearPoints(points, n * 10),
      line: yearsOff == 0 ? l.whatYearPerfect : l.whatYearOffInAll(yearsOff),
      board: GameSquares(marks: [for (int i = 0; i < n; i++) rightAt(i)]),
      review: [
        for (int i = 0; i < n; i++)
          GameReviewItem(
            key: ValueKey('what-year-row-${lines[i].pill.id}'),
            text: lines[i].text,
            tag: '${lines[i].year}',
            tagDark: true,
            mark: rightAt(i),
            detail: guessAt(i) == null
                ? null
                : l.whatYearSaid('${guessAt(i)}', pointsAt(i)),
            semantics:
                '${lines[i].year}. ${lines[i].text} '
                '${guessAt(i) == null ? '' : l.whatYearSaid('${guessAt(i)}', pointsAt(i))}',
            onTap: () => onOpen(pills, lines[i].pill),
          ),
      ],
    );
  }

  @override
  Future<void> share(BuildContext context) => shareScore(
    context,
    title: title,
    score: context.l10n.whatYearPoints(points, lines.length * 10),
    marks: [for (int i = 0; i < lines.length; i++) rightAt(i)],
    facts: {'points': points},
  );
}

class _WhatYearPlay extends StatefulWidget {
  const _WhatYearPlay({required this.game, required this.kit});

  final WhatYearChallenge game;
  final GameKit kit;

  @override
  State<_WhatYearPlay> createState() => _WhatYearPlayState();
}

class _WhatYearPlayState extends State<_WhatYearPlay> {
  WhatYearChallenge get _game => widget.game;

  /// The moment in front, and whether its year has been told.
  late int _at = _game.answers.length.clamp(0, _game.lines.length - 1);
  late bool _told = _at < _game.answers.length;
  int _year = WhatYearChallenge.startYear;

  @override
  void initState() {
    super.initState();
    _game.shown(_game.lines[_at]);
  }

  void _lock() {
    if (_told) return;
    HapticFeedback.mediumImpact();
    setState(() => _told = true);
    _game.answer(_year);
    final int pts = _game.pointsAt(_at);
    final l = context.l10n;
    widget.kit.say(
      '${_game.lines[_at].year}. ${l.whatYearSaid('$_year', pts)}',
    );
    if (pts >= 5) HapticFeedback.lightImpact();
  }

  void _next() {
    if (_at + 1 >= _game.lines.length) {
      widget.kit.finish();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _at++;
      _told = false;
      _year = WhatYearChallenge.startYear;
    });
    _game.shown(_game.lines[_at]);
  }

  void _set(int year) {
    final int y = year.clamp(WhatYearChallenge.firstYear, _game.now);
    if (y == _year || _told) return;
    setState(() => _year = y);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final GameKit kit = widget.kit;
    final DatedLine line = _game.lines[_at];
    final int n = _game.lines.length;
    final int shownYear = _told ? (_game.guessAt(_at) ?? _year) : _year;
    final int pts = _told ? _game.pointsAt(_at) : 0;
    final int off = (shownYear - line.year).abs();
    final bool last = _at + 1 >= n;
    return GamePlayFrame(
      kit: kit,
      count: l.nOfM(_at + 1, n),
      marks: [for (int i = 0; i < n; i++) _game.rightAt(i)],
      at: _at,
      status: Text(
        l.gamePoints(_game.points),
        key: const ValueKey('what-year-points'),
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4),
        style: AppText.display(
          size: 22,
          weight: FontWeight.w700,
          height: 1,
          color: kit.ink,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: kit.motion(260),
              child: GamePaper(
                key: ValueKey('what-year-moment-${line.pill.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CardHead(
                      pill: line.pill,
                      ink: kArtInk,
                      labelInk: kArtInk.withValues(alpha: 0.62),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: MomentText(line: line, shown: _told, max: 30),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // The year, large: what the dial says, and once locked how far off.
          Semantics(
            liveRegion: true,
            label: _told
                ? '${line.year}. ${l.whatYearSaid('$shownYear', pts)}'
                : null,
            excludeSemantics: _told,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _told ? '${line.year}' : '$shownYear',
                  key: const ValueKey('what-year-year'),
                  textScaler: MediaQuery.textScalerOf(
                    context,
                  ).clamp(maxScaleFactor: 1.2),
                  style: AppText.display(
                    size: 56,
                    weight: FontWeight.w700,
                    height: 1,
                    spacing: -2,
                    color: kit.ink,
                  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                const SizedBox(width: 12),
                if (_told)
                  Expanded(
                    child: Text(
                      off == 0
                          ? l.whatYearExact(pts)
                          : '${l.whatYearOff(off)}. '
                                '${l.whatYearSaid('$shownYear', pts)}',
                      key: const ValueKey('what-year-off'),
                      textScaler: MediaQuery.textScalerOf(
                        context,
                      ).clamp(maxScaleFactor: 1.4),
                      style: AppText.body(
                        size: 16,
                        weight: FontWeight.w800,
                        height: 1.2,
                        color: kit.ink,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          YearDial(
            key: const ValueKey('what-year-dial'),
            value: shownYear,
            first: WhatYearChallenge.firstYear,
            last: _game.now,
            answer: _told ? line.year : null,
            onChanged: _told ? null : _set,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final int by in const [-10, -1, 1, 10]) ...[
                if (by != -10) const SizedBox(width: 8),
                Expanded(
                  child: GameButton(
                    key: ValueKey('what-year-step-$by'),
                    label: by > 0 ? '+$by' : '−${by.abs()}',
                    semantics: by < 0
                        ? l.whatYearEarlier(-by)
                        : l.whatYearLater(by),
                    face: kArtCream,
                    ink: kArtInk,
                    height: 52,
                    size: 17,
                    radius: 16,
                    onTap: _told
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            _set(_year + by);
                          },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      actions: _told
          ? GameButton(
              key: const ValueKey('what-year-next'),
              label: last ? l.gameSeeResult : l.gameNextCard,
              icon: Icons.arrow_forward_rounded,
              face: kArtInk,
              ink: kArtCream,
              height: 66,
              onTap: _next,
            )
          : GameButton(
              key: const ValueKey('what-year-lock'),
              label: l.betsLockIn,
              icon: Icons.lock_rounded,
              face: kArtInk,
              ink: kArtCream,
              height: 66,
              onTap: _lock,
            ),
    );
  }
}

/// A ruler of the years, from [first] to [last], dragged under a needle
/// that stays put: a flick runs it on through the decades, and it stops
/// on a whole year. Once [answer] is told, the answer's mark is on it.
class YearDial extends StatefulWidget {
  const YearDial({
    super.key,
    required this.value,
    required this.first,
    required this.last,
    required this.onChanged,
    this.answer,
  });

  final int value;
  final int first;
  final int last;
  final ValueChanged<int>? onChanged;
  final int? answer;

  /// How far apart two years are on the ruler.
  static const double perYear = 9;

  @override
  State<YearDial> createState() => _YearDialState();
}

class _YearDialState extends State<YearDial>
    with SingleTickerProviderStateMixin {
  late double _at = widget.value.toDouble();
  late final AnimationController _fling = AnimationController.unbounded(
    vsync: this,
  )..addListener(_flung);

  @override
  void didUpdateWidget(YearDial old) {
    super.didUpdateWidget(old);
    if (!_fling.isAnimating && widget.value != _at.round()) {
      setState(() => _at = widget.value.toDouble());
    }
  }

  @override
  void dispose() {
    _fling.dispose();
    super.dispose();
  }

  void _move(double to) {
    final double held = to
        .clamp(widget.first.toDouble(), widget.last.toDouble())
        .toDouble();
    final int was = _at.round();
    setState(() => _at = held);
    final int now = held.round();
    if (now != was) {
      if (now % 10 == 0) HapticFeedback.selectionClick();
      widget.onChanged?.call(now);
    }
  }

  void _flung() => _move(_fling.value);

  void _end(DragEndDetails d) {
    final double v = -(d.primaryVelocity ?? 0) / YearDial.perYear;
    if (v.abs() < 4 || MediaQuery.disableAnimationsOf(context)) {
      _settle();
      return;
    }
    _fling.value = _at;
    _fling
        .animateWith(FrictionSimulation(0.04, _at, v))
        .whenCompleteOrCancel(_settle);
  }

  void _settle() {
    if (!mounted) return;
    _move(_at.roundToDouble());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bool open = widget.onChanged != null;
    final int v = _at.round();
    return Semantics(
      slider: open,
      label: l.whatYearDial,
      value: '$v',
      increasedValue: open ? '${math.min(widget.last, v + 1)}' : null,
      decreasedValue: open ? '${math.max(widget.first, v - 1)}' : null,
      onIncrease: open ? () => _move(v + 1.0) : null,
      onDecrease: open ? () => _move(v - 1.0) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: open ? (_) => _fling.stop() : null,
        onHorizontalDragUpdate: open
            ? (d) => _move(_at - d.delta.dx / YearDial.perYear)
            : null,
        onHorizontalDragEnd: open ? _end : null,
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: gameFace(context),
            borderRadius: BorderRadius.circular(18),
            border: gameBorder(context),
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _RulerPainter(
              at: _at,
              first: widget.first,
              last: widget.last,
              answer: widget.answer,
              digits: AppText.body(
                size: 11.5,
                weight: FontWeight.w800,
                height: 1,
                color: kArtInk,
              ),
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.at,
    required this.first,
    required this.last,
    required this.answer,
    required this.digits,
  });

  final double at;
  final int first;
  final int last;
  final int? answer;
  final TextStyle digits;

  @override
  void paint(Canvas canvas, Size size) {
    final double mid = size.width / 2;
    const double px = YearDial.perYear;
    final int from = math.max(first, (at - mid / px).floor() - 1);
    final int to = math.min(last, (at + mid / px).ceil() + 1);
    final Paint tick = Paint()
      ..color = kArtInk
      ..strokeCap = StrokeCap.round;
    for (int y = from; y <= to; y++) {
      final double x = mid + (y - at) * px;
      final double h = y % 100 == 0
          ? 30
          : y % 10 == 0
          ? 22
          : y % 5 == 0
          ? 14
          : 8;
      tick.strokeWidth = y % 10 == 0 ? 2.4 : 1.4;
      canvas.drawLine(Offset(x, size.height - 6), Offset(x, size.height - 6 - h), tick);
      if (y % 10 == 0) {
        final TextPainter t = TextPainter(
          text: TextSpan(text: '$y', style: digits),
          textDirection: TextDirection.ltr,
        )..layout();
        t.paint(canvas, Offset(x - t.width / 2, 8));
        t.dispose();
      }
    }
    final int? a = answer;
    if (a != null) {
      final double x = mid + (a - at) * px;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, size.height / 2 + 6),
            width: 8,
            height: size.height - 16,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = kGameRight,
      );
    }
    // The needle: where the dial stands.
    final Path needle = Path()
      ..moveTo(mid - 9, 0)
      ..lineTo(mid + 9, 0)
      ..lineTo(mid, 12)
      ..close();
    canvas.drawPath(needle, Paint()..color = kArtInk);
    canvas.drawLine(
      Offset(mid, 0),
      Offset(mid, size.height),
      Paint()
        ..color = kArtInk
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.at != at || old.answer != answer;
}

// ── Before or after? ─────────────────────────────────────────────────────

/// Before or after?: six moments, each before or after the one above it.
class BeforeAfterChallenge extends TimeChallenge {
  BeforeAfterChallenge({
    required super.deal,
    required super.onOpen,
    super.onShown,
    super.now,
    required this.title,
  });

  final String title;

  @override
  TimeGame get game => TimeGame.chain;

  /// One call for each moment after the first.
  @override
  int get needed => lines.length - 1;

  /// Whether "after" was said of the moment at [i], from 1.
  bool? saidAt(int i) =>
      i >= 1 && i - 1 < answers.length ? answers[i - 1] == true : null;

  /// Whether the call on the moment at [i], from 1, was right.
  bool? rightAt(int i) {
    final bool? s = saidAt(i);
    if (s == null) return null;
    return s == (lines[i].year > lines[i - 1].year);
  }

  int get right => [
    for (int i = 1; i < lines.length; i++) rightAt(i),
  ].where((r) => r == true).length;

  List<bool?> get marks => [for (int i = 1; i < lines.length; i++) rightAt(i)];

  @override
  String get tally => '$right/$needed';

  @override
  Map<String, Object> get finishedFacts => {'right': right};

  @override
  String rules(AppLocalizations l) => l.beforeAfterRules;

  @override
  Widget play(BuildContext context, GameKit kit) =>
      _BeforeAfterPlay(game: this, kit: kit);

  @override
  GameOutcome outcome(BuildContext context, GameKit kit) {
    final l = context.l10n;
    final int n = needed;
    return GameOutcome(
      score: '$right',
      of: '$n',
      label: l.nOfM(right, n),
      line: right == n ? l.beforeAfterPerfect : l.betsScoreSentence(right, n),
      board: GameSquares(marks: marks),
      review: [
        for (int i = 0; i < lines.length; i++)
          GameReviewItem(
            key: ValueKey('before-after-row-${lines[i].pill.id}'),
            text: lines[i].text,
            tag: '${lines[i].year}',
            tagDark: true,
            mark: rightAt(i),
            detail: i == 0
                ? l.beforeAfterStart
                : saidAt(i) == null
                ? null
                : saidAt(i)!
                ? l.beforeAfterSaidAfter('${lines[i - 1].year}')
                : l.beforeAfterSaidBefore('${lines[i - 1].year}'),
            semantics: '${lines[i].year}. ${lines[i].text}',
            onTap: () => onOpen(pills, lines[i].pill),
          ),
      ],
    );
  }

  @override
  Future<void> share(BuildContext context) => shareScore(
    context,
    title: title,
    score: context.l10n.gameShareScore(right, needed),
    marks: marks,
    facts: {'right': right},
  );
}

class _BeforeAfterPlay extends StatefulWidget {
  const _BeforeAfterPlay({required this.game, required this.kit});

  final BeforeAfterChallenge game;
  final GameKit kit;

  @override
  State<_BeforeAfterPlay> createState() => _BeforeAfterPlayState();
}

class _BeforeAfterPlayState extends State<_BeforeAfterPlay> {
  BeforeAfterChallenge get _game => widget.game;

  /// The moment being asked about, from 1: the one above it is the one
  /// before it in the chain.
  late int _at = (_game.answers.length + 1).clamp(1, _game.lines.length - 1);

  /// Whether the moment in front has been told.
  bool _told = false;

  @override
  void initState() {
    super.initState();
    _game.shown(_game.lines[_at - 1]);
    _game.shown(_game.lines[_at]);
  }

  void _say(bool after) {
    if (_told) return;
    _game.answer(after);
    final bool right = _game.rightAt(_at) ?? false;
    if (right) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    final l = context.l10n;
    widget.kit.say(
      '${right ? l.gameRight : l.gameWrong}. ${_game.lines[_at].year}.',
    );
    setState(() => _told = true);
    final int at = _at;
    Future<void>.delayed(
      widget.kit.calm
          ? const Duration(milliseconds: 900)
          : const Duration(milliseconds: 1100),
      () {
        if (!mounted || _at != at) return;
        if (_game.over) {
          widget.kit.finish();
          return;
        }
        setState(() {
          _at++;
          _told = false;
        });
        _game.shown(_game.lines[_at]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final GameKit kit = widget.kit;
    final DatedLine above = _game.lines[_at - 1];
    final DatedLine here = _game.lines[_at];
    final bool? right = _told ? _game.rightAt(_at) : null;
    return GamePlayFrame(
      kit: kit,
      marks: _game.marks,
      at: _at - 1,
      status: Text(
        l.beforeAfterAsk('${above.year}'),
        key: const ValueKey('before-after-ask'),
        maxLines: 2,
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4),
        style: AppText.display(
          size: 18,
          weight: FontWeight.w700,
          height: 1.1,
          spacing: -0.3,
          color: kit.ink,
        ),
      ),
      body: AnimatedSwitcher(
        duration: kit.motion(360),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: Column(
          key: ValueKey('before-after-$_at'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: _ChainCard(
                key: ValueKey('before-after-above-${above.pill.id}'),
                line: above,
                shown: true,
              ),
            ),
            const _Link(),
            Expanded(
              flex: 6,
              child: _ChainCard(
                key: ValueKey('before-after-here-${here.pill.id}'),
                line: here,
                shown: _told,
                right: right,
              ),
            ),
          ],
        ),
      ),
      actions: Row(
        children: [
          Expanded(
            child: GameButton(
              key: const ValueKey('before-after-before'),
              label: l.beforeAfterBefore,
              icon: Icons.arrow_upward_rounded,
              face: kArtCream,
              ink: kArtInk,
              height: 84,
              onTap: _told ? null : () => _say(false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GameButton(
              key: const ValueKey('before-after-after'),
              label: l.beforeAfterAfter,
              icon: Icons.arrow_downward_rounded,
              face: kArtInk,
              ink: kArtCream,
              height: 84,
              onTap: _told ? null : () => _say(true),
            ),
          ),
        ],
      ),
    );
  }
}

/// The line of time between the moment above and the one asked about.
class _Link extends StatelessWidget {
  const _Link();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 30,
    child: Center(
      child: Container(width: 4, color: kArtInk),
    ),
  );
}

/// A moment of the chain, on its card: its year in a tab once told.
class _ChainCard extends StatelessWidget {
  const _ChainCard({
    super.key,
    required this.line,
    required this.shown,
    this.right,
  });

  final DatedLine line;
  final bool shown;
  final bool? right;

  @override
  Widget build(BuildContext context) {
    final bool? r = right;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: GamePaper(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CardHead(
                  pill: line.pill,
                  ink: kArtInk,
                  labelInk: kArtInk.withValues(alpha: 0.62),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: MomentText(line: line, shown: shown, max: 26, min: 14),
                ),
              ],
            ),
          ),
        ),
        if (r != null)
          Positioned(
            right: -6,
            top: -10,
            child: GameStamp(right: r, size: 52),
          ),
      ],
    );
  }
}

// ── The moment's words ───────────────────────────────────────────────────

/// A moment's words, set as large as the box takes, its year a gap until
/// it is [shown] and then filled in. On a card of paper — no [accent] —
/// the gap is shaded and the year set in the paper's reverse; set as a
/// page is, with an [accent], the words are in the serif's regular weight,
/// the gap a hairline under a space the year's width, and the year comes
/// in the challenge's tone.
class MomentText extends StatelessWidget {
  const MomentText({
    super.key,
    required this.line,
    required this.shown,
    this.max = 28,
    this.min = 15,
    this.ink = kArtInk,
    this.accent,
  });

  final DatedLine line;
  final bool shown;
  final double max;
  final double min;

  /// The words' colour.
  final Color ink;

  /// The challenge's tone, for a moment set as a page is.
  final Color? accent;

  TextSpan _span(double size, String gapLabel, [Color? scoped]) {
    final Color? a = accent ?? scoped;
    if (a != null) {
      // On a challenge's screen the moment is said plainly, as what
      // happened, its year kept back; once told, the year under it — save
      // where the year is told beside it ([accent], In order's margin).
      TextStyle serif(FontWeight weight, Color colour) => AppText.display(
        size: size,
        weight: weight,
        height: 1.24,
        spacing: -0.012 * size,
        color: colour,
      );
      return TextSpan(
        style: serif(FontWeight.w600, ink),
        children: [
          TextSpan(text: line.statement),
          if (shown && accent == null)
            TextSpan(
              text: '\n${line.year}',
              style: serif(FontWeight.w800, a),
            ),
        ],
      );
    }
    final TextStyle base = AppText.display(
      size: size,
      weight: FontWeight.w600,
      height: 1.16,
      spacing: -0.02 * size,
      color: ink,
    );
    return TextSpan(
      style: base,
      children: [
        TextSpan(text: line.before),
        if (shown)
          TextSpan(
            text: ' ${line.year} ',
            style: base.copyWith(
              color: kArtCream,
              fontWeight: FontWeight.w800,
              background: Paint()..color = kArtInk,
            ),
          )
        else
          TextSpan(
            text: '     ',
            semanticsLabel: gapLabel,
            style: base.copyWith(
              background: Paint()..color = kArtInk.withValues(alpha: 0.16),
              decoration: TextDecoration.underline,
              decorationColor: kArtInk,
              decorationThickness: 2.2,
            ),
          ),
        TextSpan(text: line.after),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String gap = context.l10n.timeGap;
    // On a challenge's card of its colour, the year comes in the card's
    // ink, never in a box of ink.
    final Color? scoped = ChallengeToneScope.maybeOf(context) == null
        ? null
        : ink;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection direction = Directionality.of(context);
    final List<String> words = line.text.split(RegExp(r'\s+'));
    return LayoutBuilder(
      builder: (context, box) {
        bool fits(double size) {
          final TextPainter p = TextPainter(
            text: _span(size, gap, scoped),
            textDirection: direction,
            textScaler: scaler,
          )..layout(maxWidth: box.maxWidth);
          final bool tall = p.height <= box.maxHeight;
          p.dispose();
          if (!tall) return false;
          // No word broken across two lines.
          final TextStyle style = AppText.display(
            size: size,
            weight: FontWeight.w800,
            spacing: -0.02 * size,
          );
          for (final String w in words) {
            final TextPainter one = TextPainter(
              text: TextSpan(text: w, style: style),
              textDirection: direction,
              textScaler: scaler,
              maxLines: 1,
            )..layout();
            final bool wide = one.width > box.maxWidth;
            one.dispose();
            if (wide) return false;
          }
          return true;
        }

        double size = max;
        while (size > min && !fits(size)) {
          size -= 1;
        }
        final Widget text = Text.rich(
          _span(size, gap, scoped),
          key: ValueKey('moment-${line.pill.id}-${shown ? 'told' : 'gap'}'),
          textScaler: scaler,
        );
        if (fits(size)) {
          return Align(alignment: Alignment.centerLeft, child: text);
        }
        return SingleChildScrollView(child: text);
      },
    );
  }
}
