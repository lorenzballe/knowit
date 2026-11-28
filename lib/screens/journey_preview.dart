part of 'journey_screen.dart';

// Your journey on the free plan, the preview (`journey.preview`,
// AppState.kJourneyPreviewFlag): a reader who opens the journey without
// Astute+ used to meet the plans with nothing of it shown, and did not know
// what they were missing. With the switch on they see their own journey,
// worked out from their answers exactly as for Astute+, every chapter behind
// a soft veil under its clear name; and over the chapters one figure in the
// clear, a different one each week in turn — the blind spot, the strong
// point, how sure against how right, what they still remember — with one
// quiet line under it, the journey's own door to the plans. Where there is
// not yet enough to say the week's figure, the card says what it takes,
// never a sample.

/// Opens Your journey from any of its doors: the finished day's button,
/// the profile's way in under the score, the looks of What to learn. On
/// Astute+, the journey; on the free plan, the preview while the server has
/// it on, and otherwise the plans on the journey's own door, straight
/// through to the journey if a trial is taken there.
void openJourney(BuildContext context, AppState app) {
  void open() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (routeContext) => JourneyScreen(
        app: app,
        onBack: () => Navigator.of(routeContext).pop(),
      ),
    ),
  );
  if (!journeyIsPreview(app)) {
    requirePlus(context, app, open, source: 'journey');
    return;
  }
  open();
}

/// Whether [app]'s reader sees the journey as the free plan's preview.
bool journeyIsPreview(AppState app) => !app.isPlus && app.journeyPreviewOn;

/// The door to the plans from the preview: the journey's own, so the plans
/// open on the record, in the reader's own numbers where there are enough.
void _toPlans(BuildContext context, AppState app) =>
    requirePlus(context, app, () {}, source: 'journey');

/// A subject as the journey measures it: its key, how often right of its
/// latest answers, and of how many ([subjectShares]).
typedef _Share = ({String key, double share, int of});

/// The figures the preview shows in the clear, a week each, in this order.
enum ClearFigure {
  /// The subject the reader misses most.
  blind,

  /// The subject they are best in.
  strong,

  /// How sure against how right, or its first reading under the floor.
  sure,

  /// What they still remember when cards come back.
  memory,
}

/// Whole weeks from the Monday the turn is counted from to [monday]: on the
/// calendar, so a change of the clocks never makes a week short.
int _clearWeeksFrom(DateTime monday) =>
    DateTime.utc(
      monday.year,
      monday.month,
      monday.day,
    ).difference(DateTime.utc(2026, 1, 5)).inDays ~/
    7;

/// The waits on the review ladder that cards have come back after, the
/// longest first, each with how the cards went then.
List<({int days, Tally tally})> _recalls(JourneyRecord record) => [
  for (var w = kReviewLadder.length - 1; w >= 0; w--)
    if (record.recall(w) case final Tally t when t.of > 0)
      (days: kReviewLadder[w], tally: t),
];

/// Whether [figure] can be said from [app]'s reader's answers yet: the
/// blind spot once two subjects are measured, the strong point once one
/// is, how sure against how right from its first reading, and what stayed
/// once a card has come back.
@visibleForTesting
bool clearFigureReady(AppState app, ClearFigure figure) => switch (figure) {
  ClearFigure.blind => subjectShares(app).length >= 2,
  ClearFigure.strong => subjectShares(app).isNotEmpty,
  ClearFigure.sure => app.sureAgainstRight != null || app.earlyReading != null,
  ClearFigure.memory => _recalls(app.record).isNotEmpty,
};

/// The figure in the clear for [app]'s reader this week, and whether it is
/// to be kept for the week ([AppState.journeyClear]).
///
/// The week's own in the turn, or, while it cannot be said yet, the first
/// after it that can: a reader in their first days sees something real
/// rather than a line on what it takes. Once one is shown it stays for the
/// week, so the figure does not change under the reader as more of the
/// others come to be said. When none can be said yet, the week's own,
/// saying what it takes, and nothing kept.
@visibleForTesting
({ClearFigure figure, bool keep}) clearFigureOf(AppState app) {
  final DateTime monday = mondayOf(app.today);
  final String week = dateKey(monday);
  final String? kept = app.journeyClear;
  if (kept != null && kept.startsWith('$week|')) {
    final ClearFigure? figure = ClearFigure.values
        .asNameMap()[kept.substring(week.length + 1)];
    if (figure != null) return (figure: figure, keep: false);
  }
  const List<ClearFigure> turn = ClearFigure.values;
  final int slot = _clearWeeksFrom(monday) % turn.length;
  for (var i = 0; i < turn.length; i++) {
    final ClearFigure figure = turn[(slot + i) % turn.length];
    if (clearFigureReady(app, figure)) return (figure: figure, keep: true);
  }
  return (figure: turn[slot], keep: false);
}

/// The one figure only Astute+ shows that Sunday's week puts under its own
/// numbers, blurred (lib/widgets/your_week_sheet.dart): its name, said in
/// the clear, and the reader's own figure, which is not. Where the reader
/// trusts themselves too much, else their blind spot, else what they still
/// remember; null while none of them can be said, and then the week shows
/// none rather than a sample.
({String key, String label, String value})? weekPlusFigure(
  BuildContext context,
  AppState app,
) {
  final l = context.l10n;
  String subject(String key) => l.subjectOf(kTopics[key]?.name ?? key);
  if (overconfidentIn(app) case (:final String key, :final int points)) {
    return (
      key: 'overconfident',
      label: l.weekSheetOverLabel,
      value: l.storyOverconfident(subject(key), points),
    );
  }
  final List<_Share> shares = subjectShares(app);
  if (shares.length >= 2) {
    final _Share blind = shares.reduce(
      (a, b) => b.share != a.share
          ? (b.share < a.share ? b : a)
          : (b.of > a.of ? b : a),
    );
    return (
      key: 'blind',
      label: l.readBlind,
      value:
          '${subject(blind.key)}  ·  '
          '${l.journeyRightShare(_percent(context, blind.share))}',
    );
  }
  final List<({int days, Tally tally})> back = _recalls(app.record);
  if (back.isNotEmpty) {
    final ({int days, Tally tally}) r = back.first;
    return (
      key: 'memory',
      label: l.weekSheetMemoryLabel,
      value: r.days % 7 == 0
          ? l.journeyClearMemoryWeeks(r.days ~/ 7, r.tally.right, r.tally.of)
          : l.journeyClearMemoryDays(r.days, r.tally.right, r.tally.of),
    );
  }
  return null;
}

/// The veil over a chapter of the preview: the chapter as it is, blurred
/// soft, its motion stopped, read to a screen reader as the way to the
/// plans, and a tap anywhere on it the journey's door.
class _Veil extends StatelessWidget {
  const _Veil({required this.app, required this.child});

  final AppState app;
  final Widget child;

  /// How soft: shapes and colours stay, words and figures do not.
  static const double sigma = 7;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: context.l10n.journeyPreviewDoor,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toPlans(context, app),
      child: IgnorePointer(
        child: TickerMode(
          enabled: false,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// The week's figure in the clear: what it is, in a sentence, the reader's
/// own numbers under it; or, before it can be said, its name and what it
/// takes.
class _ClearCard extends StatelessWidget {
  const _ClearCard({required this.app, required this.figure});

  final AppState app;
  final ClearFigure figure;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final Color ink = p.ink;
    final bool ready = clearFigureReady(app, figure);
    String? tag;
    String title;
    String? line;
    Color? accent;
    double? share;

    String subject(String key) => l.subjectOf(kTopics[key]?.name ?? key);
    _Share? spot(bool strongest) {
      final List<_Share> shares = subjectShares(app);
      if (shares.isEmpty || (!strongest && shares.length < 2)) return null;
      // The more answers break a tie, as the journey's own tiles break it.
      bool beats(_Share a, _Share b) => a.share != b.share
          ? (strongest ? a.share > b.share : a.share < b.share)
          : a.of > b.of;
      return shares.reduce((a, b) => beats(b, a) ? b : a);
    }

    switch (figure) {
      case ClearFigure.blind || ClearFigure.strong:
        final bool strong = figure == ClearFigure.strong;
        final s = spot(strong);
        if (s == null) {
          title = strong ? l.strengthsBest : l.readBlind;
          line = strong
              ? l.journeyClearStrongNotYet
              : subjectShares(app).isEmpty
              ? l.journeyClearBlindNotYet
              : l.journeyMissedEmpty;
        } else {
          title = strong
              ? l.journeyClearStrong(subject(s.key))
              : l.journeyClearBlind(subject(s.key));
          line = l.journeyClearShare(_percent(context, s.share), s.of);
          accent = kTopics[s.key]?.color;
          share = s.share;
        }
      case ClearFigure.sure:
        final said = app.sureAgainstRight;
        final EarlyReading? early = app.earlyReading;
        if (said != null) {
          title = l.elided(
            l.storySaidRight(
              _percent(context, said.sure / 100),
              _percent(context, said.right / 100),
            ),
          );
          final int points = (said.sure - said.right).abs().round();
          line = points <= 5
              ? l.confidenceMatchesAccuracy
              : said.sure > said.right
              ? l.overconfidentBy(points)
              : l.underconfidentBy(points);
        } else if (early != null) {
          tag = l.earlyReadingTag;
          title = earlyReadingText(context, early);
          line = l.journeyOffNotYet(early.toGo);
        } else {
          title = l.howSureAgainstHowRight;
          final int n = app.calibratedAnswers;
          line = kEarlyReadingFrom > n && app.earlyReadingOn
              ? l.journeyClearSureNotYet(kEarlyReadingFrom - n)
              : l.journeyOffNotYet(math.max(1, kCalibrationFloor - n));
        }
      case ClearFigure.memory:
        final List<({int days, Tally tally})> back = _recalls(app.record);
        String after(({int days, Tally tally}) r, {bool sentence = false}) {
          final int days = r.days;
          final Tally t = r.tally;
          if (sentence) {
            return days % 7 == 0
                ? l.journeyClearMemoryWeeks(days ~/ 7, t.right, t.of)
                : l.journeyClearMemoryDays(days, t.right, t.of);
          }
          return days % 7 == 0
              ? l.journeyRecallWeeks(t.right, t.of, days ~/ 7)
              : l.journeyRecallDays(t.right, t.of, days);
        }

        if (back.isEmpty) {
          title = l.weekSheetMemoryLabel;
          line = l.journeyClearMemoryNotYet;
        } else {
          title = after(back.first, sentence: true);
          final int held = app.heldCards;
          final List<String> more = [
            if (held > 0) '$held ${l.journeyStillWithYou(held)}',
            for (final r in back.skip(1)) after(r),
          ];
          line = more.isEmpty ? null : more.join('  ·  ');
        }
    }

    return Container(
      key: ValueKey('journey-clear-${figure.name}'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _upper(context, l.journeyClearEyebrow),
            style: AppText.body(
              size: 10.5,
              weight: FontWeight.w800,
              spacing: 1.4,
              color: ink.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 14),
          if (tag != null) ...[
            Text(
              _upper(context, tag),
              key: const ValueKey('journey-clear-early'),
              style: AppText.body(
                size: 10,
                weight: FontWeight.w700,
                spacing: 1.2,
                color: _green(context),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            title,
            key: const ValueKey('journey-clear-title'),
            style: AppText.display(
              size: ready ? (tag != null ? 21 : 25) : 21,
              weight: FontWeight.w600,
              height: 1.16,
              spacing: -0.6,
              color: ready ? ink : ink.withValues(alpha: 0.8),
            ),
          ),
          if (share != null && accent != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: p.line),
                    FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: share.clamp(0.0, 1.0),
                      child: ColoredBox(color: accent),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (line != null) ...[
            const SizedBox(height: 10),
            Text(
              line,
              key: const ValueKey('journey-clear-line'),
              style: AppText.body(
                size: 13.5,
                height: 1.4,
                color: ink.withValues(alpha: 0.62),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The one quiet line under the figure in the clear: a different one each
/// week, and the rest with Astute+, a tap from the plans, in the lock and
/// the link's colour the journey's other doors to Astute+ have.
class _PreviewDoor extends StatelessWidget {
  const _PreviewDoor({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final Color link = context.p.link;
    return Semantics(
      button: true,
      child: GestureDetector(
        key: const ValueKey('journey-preview-door'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _toPlans(context, app),
        // Under the card's own words, from where they start, the lock on
        // the first line: a line of the page, not a button.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1.5),
                child: Icon(Icons.lock_rounded, size: 14, color: link),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  context.l10n.journeyPreviewDoor,
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w600,
                    height: 1.3,
                    color: link,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
