part of 'journey_screen.dart';

// The journey's chapters that tell rather than count (journey_screen.dart
// puts them round the tiles): what the week says about the reader, in one
// sentence; what to practise, as decks a tap away; how they reason, in four
// lines; and their story so far, with its dates. Everything on them is
// counted from what the app already writes down; nothing is invented, and a
// chapter with nothing true to say says what would make it.

// ── What the week says ────────────────────────────────────────────────────

/// Which sentence the week is told in.
enum StoryHeadlineKind { sure, streak, strong, read }

/// The week in one sentence, as numbers: the screen puts the words.
class StoryHeadline {
  const StoryHeadline(
    this.kind, {
    this.n = 0,
    this.week = 0,
    this.firstDay = false,
    this.better,
    this.subject,
    this.share = 0,
  });

  final StoryHeadlineKind kind;

  /// Right in ten when sure; the days in a row; the cards read.
  final int n;

  /// Of the cards read, those first read this week ([weekCards]).
  final int week;

  /// Whether the reader's record starts today: then the cards read are
  /// where the journey starts, and the week has nothing to add.
  final bool firstDay;

  /// Against last week, when there is a last week to say it against and the
  /// difference means something; null otherwise.
  final bool? better;

  /// The strongest subject's key ([kTopics]), and how often it is right.
  final String? subject;
  final double share;
}

/// The strongest true thing to say about the reader this week. First, how
/// often they were right when they said they were sure, once five such
/// answers are in, said in tens the way a person counts; then a run of days;
/// then the subject they are strongest in; then simply what they have read,
/// and, past the first day, how much of it this week: "32 cards read, 9
/// this week." It used to say the journey starts here to a reader with 32
/// cards behind them.
@visibleForTesting
StoryHeadline storyHeadline(AppState app) {
  final DateTime monday = mondayOf(app.today);
  final String now = dateKey(monday);
  final String before = dateKey(dayShift(monday, -7));
  final week = <Judgement>[];
  final last = <Judgement>[];
  for (final Judgement j in app.calibrated) {
    final String? on = j.on;
    if (on == null || j.confidence! < kSureFrom) continue;
    if (on.compareTo(now) >= 0) {
      week.add(j);
    } else if (on.compareTo(before) >= 0) {
      last.add(j);
    }
  }
  if (week.length >= 5) {
    double share(List<Judgement> run) =>
        run.where((j) => j.correct).length / run.length;
    final double was = last.length >= 5 ? share(last) : double.nan;
    final double is_ = share(week);
    return StoryHeadline(
      StoryHeadlineKind.sure,
      n: (is_ * 10).round(),
      better: was.isNaN || (is_ - was).abs() < 0.05 ? null : is_ > was,
    );
  }
  if (app.liveStreak >= 3) {
    return StoryHeadline(StoryHeadlineKind.streak, n: app.liveStreak);
  }
  final shares = subjectShares(app);
  if (shares.isNotEmpty) {
    final best = shares.reduce(
      (a, b) =>
          b.share > a.share || (b.share == a.share && b.of > a.of) ? b : a,
    );
    return StoryHeadline(
      StoryHeadlineKind.strong,
      subject: best.key,
      share: best.share,
    );
  }
  final JourneyRecord record = app.record;
  return StoryHeadline(
    StoryHeadlineKind.read,
    n: app.seenIds.length,
    week: weekCards(app, record).length,
    firstDay: record.daysIn <= 1,
  );
}

/// The cards first read this week, Monday to today, in the order they were
/// read, wherever they were read: what the week's headline counts, and what
/// Review the week plays again. [record] is [app]'s, where it is at hand.
@visibleForTesting
List<Pill> weekCards(AppState app, [JourneyRecord? record]) {
  record ??= app.record;
  return [
    for (final String id in record.readBetween(
      dateKey(record.monday),
      record.todayKey,
    ))
      ?pillById(id),
  ];
}

class _Headline extends StatelessWidget {
  const _Headline({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final StoryHeadline h = storyHeadline(app);
    final String line = switch (h.kind) {
      StoryHeadlineKind.sure => l.storyHeadlineSure(h.n),
      StoryHeadlineKind.streak => l.storyHeadlineStreak(h.n),
      StoryHeadlineKind.strong => l.elided(
        l.storyHeadlineStrong(
          l.subjectOf(kTopics[h.subject]?.name ?? ''),
          _percent(context, h.share),
        ),
      ),
      // The day the record starts, the cards read are where the journey
      // starts; past it, every card read and how many of them this week.
      StoryHeadlineKind.read =>
        h.firstDay || h.n == 0
            ? l.storyHeadlineRead(h.n)
            : h.week >= h.n
            ? l.storyHeadlineReadAllWeek(h.n)
            : l.storyHeadlineReadWeek(h.n, h.week),
    };
    final String? after = switch (h.better) {
      true => l.storyBetter,
      false => l.storyWorse,
      null => null,
    };
    final Color? accent = h.kind == StoryHeadlineKind.strong
        ? kTopics[h.subject]?.color
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (accent != null) ...[
          Container(
            width: 34,
            height: 5,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          line,
          key: ValueKey('story-headline-${h.kind.name}'),
          style: AppText.display(
            size: 29,
            weight: FontWeight.w600,
            height: 1.14,
            spacing: -0.8,
            color: context.p.ink,
          ),
        ),
        if (after != null) ...[
          const SizedBox(height: 10),
          Text(
            after,
            style: AppText.body(
              size: 15,
              weight: FontWeight.w600,
              height: 1.3,
              color: h.better == true
                  ? _green(context)
                  : context.p.ink.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }
}

// ── How you reason ────────────────────────────────────────────────────────

/// Where the reader is surest beyond what they get right: the subject whose
/// said confidence runs furthest past its accuracy, in points, from the
/// answers said with a confidence, once six are in it. Null when no subject
/// runs five points or more past, or none has six.
@visibleForTesting
({String key, int points})? overconfidentIn(AppState app) {
  final Map<String, Pill> byId = {for (final p in PillBank.live) p.id: p};
  final Map<String, List<Judgement>> bySubject = {};
  for (final Judgement j in app.calibrated) {
    final Pill? p = j.pillId == null ? null : byId[j.pillId];
    final String? key = p == null ? null : topicKeyForName(p.topic);
    if (key == null) continue;
    bySubject.putIfAbsent(key, () => []).add(j);
  }
  ({String key, int points})? out;
  for (final MapEntry<String, List<Judgement>> e in bySubject.entries) {
    final List<Judgement> run = e.value.length > 30
        ? e.value.sublist(e.value.length - 30)
        : e.value;
    if (run.length < 6) continue;
    final double said =
        run.fold<int>(0, (a, j) => a + j.confidence!) / run.length;
    final double right = run.where((j) => j.correct).length * 100 / run.length;
    final int points = (said - right).round();
    if (points >= 5 && (out == null || points > out.points)) {
      out = (key: e.key, points: points);
    }
  }
  return out;
}

class _HowYouReason extends StatelessWidget {
  const _HowYouReason({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final said = app.sureAgainstRight;
    final Map<Reaction, int> reacted = app.reactionCounts;
    final shares = subjectShares(app);
    final strong = shares.isEmpty
        ? null
        : shares.reduce((a, b) => b.share > a.share ? b : a);
    final weak = shares.length < 2
        ? null
        : shares.reduce((a, b) => b.share < a.share ? b : a);
    final over = overconfidentIn(app);
    String subject(String key) => l.subjectOf(kTopics[key]?.name ?? '');

    return _Box(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Line(
            icon: Icons.track_changes_rounded,
            text: said == null
                ? l.storySaidRightToGo(
                    math.max(1, kCalibrationFloor - app.calibratedAnswers),
                  )
                : l.elided(
                    l.storySaidRight(
                      _percent(context, said.sure / 100),
                      _percent(context, said.right / 100),
                    ),
                  ),
          ),
          if (app.reactions.isNotEmpty)
            _Line(
              icon: Icons.lightbulb_outline_rounded,
              text:
                  '${l.journeyChangedMind}: ${reacted[Reaction.changed]}  ·  '
                  '${l.journeyNewToYou}: ${reacted[Reaction.fresh]}',
            ),
          if (strong != null)
            _Line(
              icon: Icons.north_east_rounded,
              text: weak == null || weak.key == strong.key
                  ? '${l.journeyStrongest}: ${subject(strong.key)}'
                  : '${l.journeyStrongest}: ${subject(strong.key)}  ·  '
                        '${l.journeyMostMissed}: ${subject(weak.key)}',
            ),
          if (over != null)
            _Locked(
              app: app,
              source: 'journey story overconfident',
              child: _Line(
                icon: Icons.warning_amber_rounded,
                text: l.storyOverconfident(subject(over.key), over.points),
              ),
            ),
        ],
      ),
    );
  }
}

/// One line of the chapter: a mark, and what it says.
class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: context.p.ink.withValues(alpha: 0.55)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppText.body(
              size: 15,
              weight: FontWeight.w600,
              height: 1.35,
              color: context.p.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

/// What Astute+ shows, on the free plan: the reader's own line, behind
/// frosted glass, with the way through. The numbers under the glass are the
/// reader's own, so what they would see is real.
class _Locked extends StatelessWidget {
  const _Locked({required this.app, required this.source, required this.child});

  final AppState app;
  final String source;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (app.isPlus) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => requirePlus(context, app, () {}, source: source),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: child,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: context.p.inverse,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 14, color: context.p.onInverse),
                const SizedBox(width: 6),
                Text(
                  context.l10n.storyUnlock,
                  style: AppText.body(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: context.p.onInverse,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Your coach ────────────────────────────────────────────────────────────

/// The week as the coach is told it: numbers and a few names, in the
/// reader's language, and nothing the reader wrote. The server clamps them
/// again (functions/src/coach.ts).
Map<String, Object?> coachStats(BuildContext context, AppState app) {
  final l = context.l10n;
  final DateTime monday = mondayOf(app.today);
  final String now = dateKey(monday);
  final String before = dateKey(dayShift(monday, -7));
  var read = 0;
  var days = 0;
  for (final MapEntry<String, List<String>> e in app.readDays.entries) {
    if (e.key.compareTo(now) >= 0 && e.value.isNotEmpty) {
      read += e.value.length;
      days++;
    }
  }
  final week = <Judgement>[];
  final last = <Judgement>[];
  for (final Judgement j in app.calibrated) {
    final String? on = j.on;
    if (on == null || j.confidence! < kSureFrom) continue;
    if (on.compareTo(now) >= 0) {
      week.add(j);
    } else if (on.compareTo(before) >= 0) {
      last.add(j);
    }
  }
  int? tens(List<Judgement> run) => run.length < 5
      ? null
      : (run.where((j) => j.correct).length * 10 / run.length).round();
  final shares = subjectShares(app);
  String? subject(String? key) =>
      key == null ? null : l.subjectOf(kTopics[key]?.name ?? '');
  final best = shares.isEmpty
      ? null
      : shares.reduce((a, b) => b.share > a.share ? b : a);
  final worst = shares.length < 2
      ? null
      : shares.reduce((a, b) => b.share < a.share ? b : a);
  final List<String> missed = <String>{
    for (final Judgement j in app.judgements)
      if (!j.correct && (j.on ?? '').compareTo(now) >= 0)
        if (pillById(j.pillId ?? '') case final Pill p when p.principle.isReal)
          p.principle.label,
  }.take(5).toList();
  return {
    'read': read,
    'days': days,
    'streak': app.liveStreak,
    'sure': tens(week),
    'sureBefore': tens(last),
    'strong': subject(best?.key),
    'weak': subject(worst?.key),
    'missed': missed,
    'changed': app.reactions.values
        .where((v) => v == Reaction.changed.key)
        .length,
    'level': rungName(context, app.standing.rung),
    // The first goal alone for a server that reads one; all of them for
    // one that reads them all.
    if (Goal.of(app.goal) case final Goal goal) 'goal': goalName(l, goal),
    if (app.goals.isNotEmpty)
      'goals': [
        for (final String k in app.goals)
          if (Goal.of(k) case final Goal g) goalName(l, g),
      ],
  };
}

/// The coach's note on the week, for Astute+: asked for with a tap, written
/// once a week by the server, and shown here. On the free plan, what it is,
/// behind the lock.
class _Coach extends StatefulWidget {
  const _Coach({required this.app});

  final AppState app;

  @override
  State<_Coach> createState() => _CoachState();
}

class _CoachState extends State<_Coach> {
  bool _busy = false;
  AskResult? _result;

  String get _week => dateKey(mondayOf(widget.app.today));

  String get _key => '$_week~${Localizations.localeOf(context).languageCode}';

  Future<void> _ask() async {
    if (_busy) return;
    final String language = Localizations.localeOf(context).languageCode;
    final Map<String, Object?> stats = coachStats(context, widget.app);
    final String key = _key;
    setState(() {
      _busy = true;
      _result = null;
    });
    Analytics.capture('coach asked', {'week': _week});
    final AskResult result = await Coach.call(_week, language, stats);
    if (result case AskAnswer(:final text)) Coach.kept[key] = text;
    Analytics.capture('coach answered', {
      'ok': result is AskAnswer,
      if (result case AskNone(:final why)) 'why_not': why.name,
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final AppState app = widget.app;
    final Color ink = context.p.ink;
    final TextStyle line = AppText.body(
      size: 14.5,
      height: 1.4,
      color: ink.withValues(alpha: 0.75),
    );
    if (!app.isPlus) {
      return GestureDetector(
        key: const ValueKey('journey-coach-locked'),
        behavior: HitTestBehavior.opaque,
        onTap: () => requirePlus(context, app, () {}, source: 'journey coach'),
        child: _CoachFrame(
          child: Row(
            children: [
              Expanded(child: Text(l.coachTeaser, style: line)),
              const SizedBox(width: 10),
              const PlusLock(locked: true),
            ],
          ),
        ),
      );
    }
    final String? kept = Coach.kept[_key];
    final AskResult? result = kept != null ? AskAnswer(kept) : _result;
    return _CoachFrame(
      key: const ValueKey('journey-coach'),
      child: switch ((_busy, result)) {
        (true, _) => Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ink.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 10),
            Text(l.deeperBusy, style: line),
          ],
        ),
        (_, AskAnswer(:final text)) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 18, color: _pink(context)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                key: const ValueKey('journey-coach-note'),
                style: AppText.body(
                  size: 15.5,
                  weight: FontWeight.w500,
                  height: 1.45,
                  color: ink,
                ),
              ),
            ),
          ],
        ),
        (_, final AskNone none) => Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(switch (none.why) {
                    AskWhyNot.tomorrow => l.deeperTomorrow,
                    AskWhyNot.declined => l.deeperDeclined,
                    AskWhyNot.plus => l.deeperPlusOnly,
                    AskWhyNot.unavailable => l.deeperUnavailable,
                    AskWhyNot.later => l.deeperTryAgain,
                  }, style: line),
                  if (debugToolsOn && (none.detail ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        none.detail!,
                        style: AppText.body(
                          size: 11,
                          color: ink.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (none.why == AskWhyNot.later)
              IconButton(
                onPressed: _ask,
                icon: const Icon(Icons.refresh_rounded),
                color: ink,
              ),
          ],
        ),
        _ => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.coachTeaser, style: line),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('journey-coach-ask'),
              onPressed: _ask,
              style: FilledButton.styleFrom(
                backgroundColor: context.p.inverse,
                foregroundColor: context.p.onInverse,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: Text(
                l.coachRead,
                style: AppText.body(size: 14, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
      },
    );
  }
}

/// The coach's box: the journey's own panel, with a thin outline of every
/// colour the app has turning slowly round it — the one box on the page
/// that is somebody talking to the reader rather than a count, said by its
/// edge and nothing else. The card after the fifth turns the same colours
/// round its rim (magic_card.dart); here they are a hairline, a little
/// light off it and no more, and they take twelve seconds to go round.
/// A phone that asked for less motion gets the outline standing still.
class _CoachFrame extends StatefulWidget {
  const _CoachFrame({super.key, required this.child});

  final Widget child;

  @override
  State<_CoachFrame> createState() => _CoachFrameState();
}

class _CoachFrameState extends State<_CoachFrame>
    with SingleTickerProviderStateMixin {
  /// One turn of the colours.
  static const Duration _period = Duration(seconds: 12);

  /// One clock for every outline, read on every frame: the box is built
  /// again as the page scrolls it out and back in, and an outline counted
  /// from its own build would start its turn over each time.
  static final Stopwatch _clock = Stopwatch()..start();

  static double get _turnNow =>
      (_clock.elapsedMicroseconds % _period.inMicroseconds) /
      _period.inMicroseconds;

  /// Only a heartbeat: it asks for a frame, and the painter asks the clock.
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: _period,
  );

  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_still) {
      _beat.stop();
    } else if (!_beat.isAnimating) {
      _beat.repeat();
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _RainbowEdge(
          turn: _beat,
          still: _still,
          fill: p.ink.withValues(alpha: 0.06),
          dark: p.isDark,
        ),
        child: RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// The panel and its outline: the colours swept round the box's middle,
/// turned by the clock, as a stroke a point and a half wide over a softer
/// one of the same colours, blurred, for a little light.
class _RainbowEdge extends CustomPainter {
  _RainbowEdge({
    required Animation<double> turn,
    required this.still,
    required this.fill,
    required this.dark,
  }) : super(repaint: turn);

  final bool still;
  final Color fill;
  final bool dark;

  static const double radius = 22;
  static const double width = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect panel = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(radius),
    );
    canvas.drawRRect(panel, Paint()..color = fill);
    final double turn = still ? 0.08 : _CoachFrameState._turnNow;
    final Shader sweep = SweepGradient(
      colors: [...kSpectrum, kSpectrum.first],
      transform: GradientRotation(turn * 2 * math.pi),
    ).createShader(rect);
    final RRect edge = panel.deflate(width / 2);
    // The light off it: wider, soft, faint.
    canvas.drawRRect(
      edge,
      Paint()
        ..shader = sweep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Color.fromRGBO(255, 255, 255, dark ? 0.32 : 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRRect(
      edge,
      Paint()
        ..shader = sweep
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(_RainbowEdge old) =>
      old.still != still || old.fill != fill || old.dark != dark;
}

// ── Practise ──────────────────────────────────────────────────────────────

class _Practice extends StatelessWidget {
  const _Practice({required this.app});

  final AppState app;

  void _open(BuildContext context, List<Pill> deck, String title, String what) {
    if (deck.isEmpty) return;
    Analytics.capture('journey practice opened', {
      'what': what,
      'cards': deck.length,
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeckViewerScreen(
          app: app,
          deck: deck,
          title: title,
          answering: true,
          source: 'journey practice',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final List<Pill> misses = [
      for (final Miss m in missesFrom(app.judgements).take(10)) m.pill,
    ];
    final List<Pill> changed = [
      for (final MapEntry<String, String> e in app.reactions.entries)
        if (e.value == Reaction.changed.key)
          if (pillById(e.key) case final Pill p) p,
    ];
    final shares = subjectShares(app);
    final weak = shares.length < 2
        ? null
        : shares.reduce((a, b) => b.share < a.share ? b : a);
    final List<Pill> fresh = weak == null
        ? const []
        : PillBank.cards
              .where(
                (p) =>
                    topicKeyForName(p.topic) == weak.key &&
                    !app.seenIds.contains(p.id) &&
                    p.isGraded,
              )
              .take(5)
              .toList();

    final List<Widget> rows = [
      if (misses.isNotEmpty)
        _PracticeRow(
          key: const ValueKey('story-practice-misses'),
          icon: Icons.replay_rounded,
          label: l.storyPracticeMisses(misses.length),
          onTap: () => _open(
            context,
            misses,
            l.storyPracticeMisses(misses.length),
            'misses',
          ),
        ),
      if (changed.isNotEmpty)
        _PracticeRow(
          key: const ValueKey('story-practice-changed'),
          icon: Icons.lightbulb_outline_rounded,
          label: l.storyPracticeChanged(changed.length),
          onTap: () => _open(
            context,
            changed,
            l.storyPracticeChanged(changed.length),
            'changed',
          ),
        ),
      if (weak != null && fresh.isNotEmpty)
        _PracticeRow(
          key: const ValueKey('story-practice-blind'),
          icon: Icons.center_focus_strong_rounded,
          label: l.storyPracticeBlind(
            l.subjectOf(kTopics[weak.key]?.name ?? ''),
          ),
          accent: kTopics[weak.key]?.color,
          locked: !app.isPlus,
          onTap: () => requirePlus(
            context,
            app,
            () => _open(
              context,
              fresh,
              l.storyPracticeBlind(l.subjectOf(kTopics[weak.key]?.name ?? '')),
              'blind spot',
            ),
            source: 'journey practice blind spot',
          ),
        ),
    ];
    if (rows.isEmpty) {
      return _Box(
        child: Text(
          l.storyPracticeNone,
          style: AppText.body(
            size: 14.5,
            height: 1.4,
            color: context.p.ink.withValues(alpha: 0.7),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          rows[i],
        ],
      ],
    );
  }
}

/// A deck to practise, a tap away.
class _PracticeRow extends StatelessWidget {
  const _PracticeRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
    this.locked = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _Box(
          padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (accent ?? ink).withValues(
                    alpha: accent == null ? 0.08 : 1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: accent == null ? ink : inkOn(accent!),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppText.body(
                    size: 15,
                    weight: FontWeight.w700,
                    height: 1.3,
                    color: ink,
                  ),
                ),
              ),
              PlusLock(locked: locked),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: ink.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Your story ────────────────────────────────────────────────────────────

class _YourStory extends StatelessWidget {
  const _YourStory({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final JourneyRecord record = app.record;
    final List<({String what, String? when, bool now})> steps = [
      (
        what: l.storyFirstCard,
        when: _day(context, dayOfKey(record.start)),
        now: false,
      ),
      for (final Rung r in kRungs.skip(1))
        if (app.rungDates[r.id] case final String on)
          (
            what: l.storyReached(rungName(context, r)),
            when: _day(context, dayOfKey(on)),
            now: false,
          ),
      if (app.bestStreak >= 2)
        (what: l.storyBestStreak(app.bestStreak), when: null, now: false),
      (
        what:
            '${l.storyCardsRead(app.seenIds.length)}  ·  '
            '${l.streakDays(app.completedDates.length)}',
        when: l.storyToday,
        now: true,
      ),
    ];
    final Color ink = context.p.ink;
    // The milestones in full, the path from the first card to the last
    // milestone, one tap under the story.
    return Semantics(
      button: true,
      key: const ValueKey('journey-story'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (routeContext) => PathScreen(
              app: app,
              onBack: () => Navigator.of(routeContext).pop(),
            ),
          ),
        ),
        child: _storyBox(context, steps, ink),
      ),
    );
  }

  Widget _storyBox(
    BuildContext context,
    List<({String what, String? when, bool now})> steps,
    Color ink,
  ) {
    return _Box(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 14,
                    child: Column(
                      children: [
                        Container(
                          width: steps[i].now ? 12 : 9,
                          height: steps[i].now ? 12 : 9,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: steps[i].now
                                ? _green(context)
                                : ink.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: ink.withValues(alpha: 0.12),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        steps[i].what,
                        style: AppText.body(
                          size: 15,
                          weight: steps[i].now
                              ? FontWeight.w700
                              : FontWeight.w600,
                          height: 1.3,
                          color: ink,
                        ),
                      ),
                    ),
                  ),
                  if (steps[i].when case final String date) ...[
                    const SizedBox(width: 10),
                    Text(
                      date,
                      style: AppText.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: ink.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── The frame ─────────────────────────────────────────────────────────────

/// A chapter: its number and name in small capitals, then what it says.
class _Chapter extends StatelessWidget {
  const _Chapter({
    required this.n,
    required this.title,
    required this.child,
    this.trailing,
  });

  final int n;
  final String title;
  final Widget child;

  /// At the end of the chapter's head, where a chapter has a way to change
  /// what it shows (the skills of Your training).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: EdgeInsets.only(
          left: 4,
          right: 4,
          bottom: trailing == null ? 10 : 6,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '$n  ·  ${_upper(context, title)}',
                style: AppText.body(
                  size: 11,
                  weight: FontWeight.w800,
                  spacing: 1.4,
                  color: context.p.ink.withValues(alpha: 0.5),
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
      child,
    ],
  );
}
