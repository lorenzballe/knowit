part of 'paywall_screen.dart';

// The new reader's gift (lib/state/gift.dart says who is given it, and
// when): its moment in the first run, where the offer of the store's trial
// would stand, and the page the morning after it ends.
//
// The moment is a gift and not a sale: Astute+ is the reader's for its
// days, with no card and nothing to cancel, said with the paywall's own
// pieces — the three lights, the headline with its painted words, what it
// opens, the days it goes by — and one button, to the day's five. The page
// at its end says what the days came to, in the reader's own numbers, and
// what goes back to the free plan; then the paywall, or the free plan, as
// plainly as each other.

/// The first run's gift: Astute+ given as the screen goes up, the moment
/// it says so, and [onDone] once, as the reader goes on to the day's five.
class GiftScreen extends StatefulWidget {
  const GiftScreen({super.key, required this.app, required this.onDone});

  final AppState app;
  final VoidCallback onDone;

  @override
  State<GiftScreen> createState() => _GiftScreenState();
}

class _GiftScreenState extends State<GiftScreen> {
  bool _done = false;

  /// The day the gift starts, which its days are counted from.
  final DateTime _opened = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Given as it goes up, before any answer: an app closed on the moment
    // opens the next time on a reader who has it.
    unawaited(widget.app.startGift());
  }

  void _leave() {
    if (_done || !mounted) return;
    _done = true;
    widget.onDone();
  }

  /// Whether the note two days before the end can reach the reader: the
  /// nudge on, and a phone whose notifications are allowed or not asked
  /// about yet. Promised only then.
  bool get _canRemind =>
      remindersSupported &&
      widget.app.notificationsOn &&
      (widget.app.notificationsAllowed || !widget.app.pushAsked);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final bool dark = p.isDark;
    final double homeBar = MediaQuery.viewPaddingOf(context).bottom;
    final double scale = MediaQuery.textScalerOf(context).scale(100) / 100;
    final bool oneScreen = scale <= 1.2;
    final bool short =
        MediaQuery.sizeOf(context).height -
            MediaQuery.paddingOf(context).vertical <
        700;
    final bool ai = cardAiOn(
      widget.app,
      Localizations.localeOf(context).languageCode,
    );

    // What the days open, as the trial's offer says it: every card of the
    // day chosen for the reader, the assistant where it is on, and every
    // path and book whole.
    final List<_Feature> perks = [
      (
        glyph: _Glyph.five,
        title: l.perkOwnFiveTitle,
        sub: l.perkOwnFiveLine,
        fresh: false,
      ),
      if (ai)
        (
          glyph: _Glyph.ask,
          title: l.perkAskTitle,
          sub: l.perkAskLine,
          fresh: false,
        ),
      (
        glyph: _Glyph.books,
        title: l.perkShelvesTitle,
        sub: l.perkShelvesLine,
        fresh: false,
      ),
    ];

    final Widget body = Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: short ? 8 : 14),
          _Headline(
            key: const ValueKey('gift-headline'),
            text: l.giftTitle(AppState.kGiftDays),
            mark: l.giftMark,
            size: short ? 32 : 36,
          ),
          Padding(
            padding: EdgeInsets.only(top: short ? 6 : 8),
            child: Text(
              l.giftLine,
              key: const ValueKey('gift-line'),
              style: AppText.body(
                size: short ? 14 : 15.5,
                weight: FontWeight.w600,
                height: 1.38,
                color: p.ink.withValues(alpha: 0.78),
              ),
            ),
          ),
          SizedBox(height: short ? 16 : 22),
          _FeatureList(features: perks),
          SizedBox(height: short ? 16 : 22),
          _GiftDays(
            key: const ValueKey('gift-days'),
            from: _opened,
            remind: _canRemind,
          ),
        ],
      ),
    );

    // A step of the first run, named for the funnel where the steps are.
    return Scaffold(
      backgroundColor: p.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            left: -80,
            top: -60,
            width: 560,
            height: 380,
            child: _Lights(),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(22, 6, 22, homeBar > 0 ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [_PlusBadge(dark: dark)]),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, room) => _FadeFoot(
                        child: SingleChildScrollView(
                          key: const ValueKey('gift-scroll'),
                          child: oneScreen
                              ? _FitDown(height: room.maxHeight, child: body)
                              : body,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: short ? 8 : 12),
                  ChunkyButton(
                    key: const ValueKey('gift-start'),
                    label: l.giftStart,
                    height: short ? 56 : 60,
                    depth: 5,
                    radius: 22,
                    labelSize: 16.5,
                    labelSpacing: 0.3,
                    fill: p.inverse,
                    ink: p.onInverse,
                    edge: dark ? const Color(0xFFA8A59D) : null,
                    shadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: dark ? 0.45 : 0.15,
                        ),
                        blurRadius: 34,
                        offset: const Offset(0, 16),
                      ),
                    ],
                    onPressed: _leave,
                  ),
                  SizedBox(height: short ? 10 : 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The paywall's badge, as wide as its word.
class _PlusBadge extends StatelessWidget {
  const _PlusBadge({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.inverse,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.4 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        context.l10n.plusNameCaps,
        style: AppText.label(
          size: 12,
          weight: FontWeight.w700,
          spacing: 2.4,
          height: 1,
          color: p.onInverse,
        ),
      ),
    );
  }
}

/// The gift as the days it goes by, on the trial's own rail: today, when
/// all of it opens and nothing is paid; the thirteenth, when the note comes,
/// where it can reach the reader; and the fifteenth, the free plan again,
/// with nothing charged — no price on it, because there is none.
class _GiftDays extends StatelessWidget {
  const _GiftDays({super.key, required this.from, required this.remind});

  /// The gift's first day.
  final DateTime from;

  /// Whether the note two days before the end can reach the reader.
  final bool remind;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final List<Color> hues = p.isDark ? _perkHues : _perkHuesOnPaper;
    final String locale = Localizations.localeOf(context).toString();
    String date(int after) => formatDay(
      DateFormat.MMMd(locale),
      DateTime(from.year, from.month, from.day + after),
    );
    const int days = AppState.kGiftDays;
    const int warn = AppState.kGiftNoticeDays;
    final List<_TrialStep> steps = [
      _TrialStep(
        name: l.trialStepToday,
        date: date(0),
        line: l.trialStepTodayLine,
        hue: hues[0],
        today: true,
      ),
      if (remind)
        _TrialStep(
          // The thirteenth is day 13 counted from today as day 1.
          name: l.trialStepDay(days - warn + 1),
          date: date(days - warn),
          line: l.trialStepReminderLine(warn),
          hue: hues[1],
        ),
      _TrialStep(
        name: l.trialStepDay(days + 1),
        date: date(days),
        line: l.giftStepEndLine,
        hue: hues[2],
      ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.ink.withValues(alpha: 0.09), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (int i, _TrialStep step) in steps.indexed)
            _TrialStepRow(
              key: ValueKey('gift-step-$i'),
              step: step,
              first: i == 0,
              last: i == steps.length - 1,
            ),
        ],
      ),
    );
  }
}

/// True while the gift's end is being looked for: one at a time.
bool _giftEndLooking = false;

/// Raises the page that says the gift is over, if it is due ([giftEndDue]),
/// over [context]'s screen — Today, the morning after the gift, before the
/// five are begun — and only while Today is the screen in front. Noted as
/// it rises, so it rises once whatever happens next. True when it rose.
Future<bool> showGiftEndIfDue(BuildContext context, AppState app) async {
  if (_giftEndLooking || !giftEndDue(app)) return false;
  // Never over another screen, nor from a tab the reader has left.
  if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
  if (!(ScreenPresence.maybeOf(context)?.showing ?? true)) return false;
  _giftEndLooking = true;
  try {
    await app.notedGiftEnd();
    if (!context.mounted) return false;
    unawaited(
      Navigator.of(context, rootNavigator: true).push(GiftEndScreen.route(app)),
    );
    return true;
  } finally {
    _giftEndLooking = false;
  }
}

/// The morning after the gift: what its days came to, in the reader's own
/// numbers, what the free plan deals from today, "Keep Astute+" — the
/// paywall, in its place — and "Continue for free".
class GiftEndScreen extends StatefulWidget {
  const GiftEndScreen({
    super.key,
    required this.app,
    this.numbers,
    this.preview = false,
  });

  final AppState app;

  /// What it says: the reader's own numbers, worked out as it opens, when
  /// null; a preview's otherwise.
  final GiftNumbers? numbers;

  /// Opened only to be looked at, from the developer tools or the camera:
  /// it says nothing to the numbers and stays up on a phone with Astute+.
  final bool preview;

  /// The page as it rises: a fade over Today; for a reader who asked for
  /// less motion, there at once.
  static Route<void> route(
    AppState app, {
    GiftNumbers? numbers,
    bool preview = false,
  }) => PageRouteBuilder<void>(
    fullscreenDialog: true,
    transitionDuration: const Duration(milliseconds: 600),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) =>
        GiftEndScreen(app: app, numbers: numbers, preview: preview),
    transitionsBuilder: (context, animation, _, child) =>
        MediaQuery.disableAnimationsOf(context)
        ? child
        : FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0.15, 1, curve: Curves.easeOut),
              reverseCurve: Curves.easeIn,
            ),
            child: child,
          ),
  );

  @override
  State<GiftEndScreen> createState() => _GiftEndScreenState();
}

class _GiftEndScreenState extends State<GiftEndScreen> {
  bool _done = false;
  String _leftBy = 'back';
  final Stopwatch _open = Stopwatch()..start();

  late final GiftNumbers _numbers =
      widget.numbers ?? GiftNumbers.of(widget.app);

  @override
  void initState() {
    super.initState();
    widget.app.addListener(_watchPlan);
    Subscription.instance.addListener(_watchPlan);
    if (!widget.preview) {
      Analytics.capture('gift end shown', {
        'days_read': _numbers.days,
        'cards_read': _numbers.cards,
        'has_gap': _numbers.gap != null,
        'gap_moved': _numbers.gapMoved,
        'back_right': _numbers.backRight,
        'random': _numbers.random,
      });
    }
  }

  @override
  void dispose() {
    widget.app.removeListener(_watchPlan);
    Subscription.instance.removeListener(_watchPlan);
    if (!widget.preview) {
      Analytics.capture('gift end closed', {
        'left_by': _leftBy,
        'ms_open': _open.elapsedMilliseconds,
        'is_plus': widget.app.isPlus,
      });
    }
    super.dispose();
  }

  /// Astute+ the reader's after all — bought on another phone, restored —
  /// and there is nothing to say: the page goes. Never on a preview.
  void _watchPlan() {
    if (_done || widget.preview) return;
    if (widget.app.paidPlus || Subscription.instance.isPlus) {
      scheduleMicrotask(() => _leave('plus already'));
    }
  }

  void _leave(String how) {
    if (_done || !mounted) return;
    _done = true;
    _leftBy = how;
    Navigator.of(context).maybePop();
  }

  /// The paywall, in the page's place.
  void _keep() {
    if (_done || !mounted) return;
    _done = true;
    _leftBy = 'keep';
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PaywallScreen(app: widget.app, source: 'gift end'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final bool dark = p.isDark;
    final GiftNumbers n = _numbers;
    final double homeBar = MediaQuery.viewPaddingOf(context).bottom;
    final double scale = MediaQuery.textScalerOf(context).scale(100) / 100;
    final bool oneScreen = scale <= 1.2;
    final bool short =
        MediaQuery.sizeOf(context).height -
            MediaQuery.paddingOf(context).vertical <
        700;
    final bool ai = cardAiOn(
      widget.app,
      Localizations.localeOf(context).languageCode,
    );
    final List<Color> hues = dark ? _perkHues : _perkHuesOnPaper;
    final List<String> lost = [
      l.giftLossRandom(n.random),
      l.giftLossMisses,
      if (ai) l.giftLossAsk,
    ];

    final Widget body = Padding(
      padding: EdgeInsets.only(bottom: short ? 12 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: short ? 0 : 10),
          Text(
            _offerCaps(context, l.giftEndEyebrow),
            key: const ValueKey('gift-end-eyebrow'),
            style: AppText.label(
              size: 11,
              weight: FontWeight.w700,
              spacing: 2.4,
              color: p.inkMuted,
            ),
          ),
          SizedBox(height: short ? 4 : 8),
          Semantics(
            header: true,
            child: FitText(
              l.giftEndTitle(AppState.kGiftDays),
              key: const ValueKey('gift-end-title'),
              maxLines: 2,
              minSize: 26,
              wholeWords: true,
              style: AppText.display(
                size: short ? 31 : 38,
                weight: FontWeight.w500,
                height: 1.04,
                spacing: -1.1,
                color: p.ink,
              ),
            ),
          ),
          SizedBox(height: short ? 10 : 18),
          _GiftFigures(numbers: n, short: short),
          SizedBox(height: short ? 14 : 26),
          Text(
            _offerCaps(context, l.giftLossTitle),
            key: const ValueKey('gift-end-loss-title'),
            style: AppText.label(
              size: 11,
              weight: FontWeight.w700,
              spacing: 2.4,
              color: p.inkMuted,
            ),
          ),
          SizedBox(height: short ? 8 : 12),
          for (final (int i, String line) in lost.indexed)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : (short ? 8 : 11)),
              child: Container(
                key: ValueKey('gift-end-loss-$i'),
                padding: const EdgeInsetsDirectional.only(
                  start: 13,
                  top: 1,
                  bottom: 1,
                ),
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    start: BorderSide(color: hues[i % hues.length], width: 2),
                  ),
                ),
                child: Text(
                  line,
                  style: AppText.body(
                    size: short ? 14 : 15,
                    weight: FontWeight.w500,
                    height: 1.35,
                    color: p.ink.withValues(alpha: 0.86),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final List<Widget> foot = [
      SizedBox(height: short ? 8 : 12),
      ChunkyButton(
        key: const ValueKey('gift-end-keep'),
        label: l.giftKeep,
        height: short ? 52 : 60,
        depth: 5,
        radius: 22,
        labelSize: 16.5,
        labelSpacing: 0.3,
        fill: p.inverse,
        ink: p.onInverse,
        edge: dark ? const Color(0xFFA8A59D) : null,
        shadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.45 : 0.15),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
        onPressed: _keep,
      ),
      SizedBox(height: short ? 8 : 10),
      // The free plan, a button like the other, in full ink.
      ChunkyButton(
        key: const ValueKey('gift-end-free'),
        label: l.trialOfferFree,
        height: short ? 50 : 56,
        depth: 5,
        radius: 22,
        labelSize: 16,
        labelSpacing: 0.3,
        fill: p.surfaceRaised,
        ink: p.ink,
        edge: p.lineStrong,
        onPressed: () => _leave('free'),
      ),
      SizedBox(height: short ? 10 : 14),
    ];

    return ScreenView(
      name: 'gift end',
      child: Scaffold(
        key: const ValueKey('gift-end'),
        backgroundColor: p.surface,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 6, 24, homeBar > 0 ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, room) => _FadeFoot(
                      child: SingleChildScrollView(
                        key: const ValueKey('gift-end-scroll'),
                        child: oneScreen
                            ? _FitDown(height: room.maxHeight, child: body)
                            : body,
                      ),
                    ),
                  ),
                ),
                ...foot,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The gift's numbers, two to a row between hairlines, as the first week's
/// page sets its own: the cards read, the days read of its days, how far
/// off the reader's sureness ran and from where, and the moves missed and
/// then got right. A number the app cannot say is left out.
class _GiftFigures extends StatelessWidget {
  const _GiftFigures({required this.numbers, required this.short});

  final GiftNumbers numbers;
  final bool short;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final String locale = Localizations.localeOf(context).toString();
    final GiftNumbers n = numbers;
    final List<_OfferFigure> figures = [
      (
        key: 'cards',
        value: NumberFormat.decimalPattern(locale).format(n.cards),
        label: l.pillReadWord(n.cards),
        note: null,
        word: false,
      ),
      (
        key: 'days',
        value: '${n.days}/${n.of}',
        label: l.giftEndDaysLabel,
        note: null,
        word: false,
      ),
      if (n.gap case final double gap)
        (
          key: 'gap',
          value: '${gap.round()}',
          label: n.gapMoved
              ? l.journeyPointsOffFrom(n.gapWas!.round())
              : l.journeyPointsOff,
          note: null,
          word: false,
        ),
      if (n.backRight > 0)
        (
          key: 'back',
          value: '${n.backRight}',
          label: l.giftEndBackRight(n.backRight),
          note: null,
          word: false,
        ),
    ];
    final BorderSide rule = BorderSide(color: p.line);
    final EdgeInsets row = EdgeInsets.symmetric(vertical: short ? 7 : 11);
    return Container(
      key: const ValueKey('gift-end-figures'),
      decoration: BoxDecoration(border: Border(bottom: rule)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < figures.length; i += 2)
            Container(
              decoration: BoxDecoration(border: Border(top: rule)),
              padding: row,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _OfferFigureCell(figure: figures[i], short: short),
                  ),
                  if (i + 1 < figures.length) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _OfferFigureCell(
                        figure: figures[i + 1],
                        short: short,
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
