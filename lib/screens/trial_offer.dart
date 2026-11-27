part of 'paywall_screen.dart';

// The first run's offer of the free trial, behind the server's switch
// `trial.firstRun` (AppState.kFirstRunTrialFlag), off as built.
//
// Most readers who ever start a trial start it on the day they install, and
// Astute never offered one in the first run: its paywall waited behind the
// locks and the journey. So, with the switch on, the first run ends on one
// real card — the opening's best for this reader (AppState.firstRunCard,
// lib/screens/first_card_screen.dart) — and then on this: one calm screen
// that says what the free days are, day by day, at the store's own price,
// with the way out as plain as the way in. After it, the day's five, as on
// any first day. It is never put during the five, never twice in a day, and
// never to a reader who already has Astute+ (trialOfferDue).
//
// It is the paywall's, drawn with the paywall's own pieces: the three
// lights, the headline with its one painted word, the perks in their tiles.

/// Whether the first run may put the offer now: the switch is on for this
/// reader, Astute+ is not already theirs, the offer has not been put today,
/// and the store has answered with a year that starts with free days for
/// this reader. A price or a trial written into the app never stands in for
/// the store's: no year on sale from the store, no offer.
bool trialOfferDue(AppState app, {Subscription? store}) {
  final Subscription s = store ?? Subscription.instance;
  return app.firstRunTrialOn &&
      !app.isPlus &&
      !s.isPlus &&
      !app.trialOfferedToday &&
      s.yearly != null &&
      s.trialDays != null;
}

/// The offer, as a step of the first run. [onDone] is called once, as the
/// reader leaves it: by "Continue for free"; after the trial has started
/// and the screen a purchase ends on has closed; or the moment Astute+
/// turns out to be theirs already, which leaves nothing to offer.
class TrialOfferScreen extends StatefulWidget {
  const TrialOfferScreen({super.key, required this.app, required this.onDone});

  final AppState app;
  final VoidCallback onDone;

  @override
  State<TrialOfferScreen> createState() => _TrialOfferScreenState();
}

class _TrialOfferScreenState extends State<TrialOfferScreen> {
  /// True from the press that starts the trial until the store answers:
  /// the button says so, and neither button takes a second press.
  bool _buying = false;

  /// True once [TrialOfferScreen.onDone] has been called.
  bool _done = false;

  /// The day the screen went up, which the trial's days are counted from.
  final DateTime _opened = DateTime.now();

  Subscription get _store => Subscription.instance;

  @override
  void initState() {
    super.initState();
    // Noted as it goes up: an app closed on the offer does not put it
    // again the same day.
    unawaited(widget.app.notedTrialOffered());
    unawaited(PurchaseSuccessScreen.precache());
    widget.app.addListener(_watchPlan);
    _store.addListener(_watchPlan);
  }

  @override
  void dispose() {
    widget.app.removeListener(_watchPlan);
    _store.removeListener(_watchPlan);
    super.dispose();
  }

  /// Astute+ already the reader's — restored, an account that has it, an
  /// answer from the store that came late — and there is nothing to offer:
  /// the day's five, at once. Not while a trial is being started, which
  /// ends on the screen a purchase ends on.
  void _watchPlan() {
    if (_buying || _done) return;
    if (widget.app.isPlus || _store.isPlus) scheduleMicrotask(_leave);
  }

  void _leave() {
    if (_done || !mounted) return;
    _done = true;
    widget.onDone();
  }

  void _say(String message) =>
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(message)));

  /// The store as the strings name it.
  static String get _storeName =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'apple' : 'google';

  /// The year's free trial, through the store's own sheet, which says the
  /// terms again before anything is charged.
  Future<void> _start() async {
    if (_buying || _done) return;
    final Package? year = _store.yearly;
    if (year == null) {
      _leave();
      return;
    }
    setState(() => _buying = true);
    final PurchaseOutcome outcome = await _store.buy(year);
    if (!mounted) return;
    final l = context.l10n;
    switch (outcome) {
      case PurchaseOutcome.bought:
        widget.app.setPlan(Plan.year);
        final Future<void> applied = widget.app.applyEntitlement(true);
        // What happened, as it happened: the screen a purchase ends on says
        // a free trial started, and when the first charge comes.
        await showPurchaseSuccess(
          context,
          widget.app,
          source: 'first run',
          plan: Plan.year,
        );
        await applied;
        _leave();
      case PurchaseOutcome.pending:
        // Waiting on someone's approval: said as that, and the store says
        // when it goes through.
        _say(l.purchasePending);
        _leave();
      case PurchaseOutcome.cancelled:
        setState(() => _buying = false);
      case PurchaseOutcome.failed:
        _say(l.thatDidNotGoThrough);
        setState(() => _buying = false);
    }
  }

  /// A reader who already paid, on a new phone: back to their plan, and on
  /// to the day's five.
  Future<void> _restore() async {
    if (_buying || _done) return;
    final RestoreOutcome outcome = await _store.restore();
    if (!mounted) return;
    final l = context.l10n;
    if (outcome == RestoreOutcome.restored) {
      _say(l.plusIsBack);
      await widget.app.applyEntitlement(true);
      _leave();
      return;
    }
    _say(
      outcome == RestoreOutcome.nothing
          ? l.nothingToRestore
          : l.storeUnreachable(_storeName),
    );
  }

  /// Whether the reminder before the charge can reach this reader: a phone
  /// whose notifications are allowed, or not yet asked about — the app's
  /// own sheet asks as soon as the trial has started. Promised only then.
  bool get _canRemind =>
      remindersSupported &&
      (widget.app.notificationsAllowed || !widget.app.pushAsked);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final Package? year = _store.yearly;
      final int? days = _store.trialDays;
      // The store took back what it had on sale: nothing to say a price
      // for, so nothing is offered.
      if (year == null || days == null) {
        scheduleMicrotask(_leave);
        return Scaffold(backgroundColor: context.p.surface);
      }
      return _page(context, price: year.storeProduct.priceString, days: days);
    },
  );

  Widget _page(
    BuildContext context, {
    required String price,
    required int days,
  }) {
    final l = context.l10n;
    final p = context.p;
    final bool dark = p.isDark;
    final double homeBar = MediaQuery.viewPaddingOf(context).bottom;
    final double scale = MediaQuery.textScalerOf(context).scale(100) / 100;
    // As on the paywall: one screen up to a little past the default text
    // size, made a little smaller where it nearly fits; past that the words
    // scroll at their full size. The two buttons stay at the foot either
    // way, so the way out is always in sight.
    final bool oneScreen = scale <= 1.2;
    final bool short =
        MediaQuery.sizeOf(context).height -
            MediaQuery.paddingOf(context).vertical <
        700;

    // The paywall's badge, as wide as its word: there is no cross beside
    // it, the way out is the button at the foot.
    final Widget badge = Row(
      children: [
        Container(
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
            l.plusNameCaps,
            style: AppText.label(
              size: 12,
              weight: FontWeight.w700,
              spacing: 2.4,
              height: 1,
              color: p.onInverse,
            ),
          ),
        ),
      ],
    );

    // Three things a reader can feel in the free days: every card of the
    // day chosen for them, the assistant on any card, and every path and
    // book whole. Said as the paywall says them, without its "new": to a
    // reader on their first day, all of it is.
    final List<_Feature> perks = [
      (
        glyph: _Glyph.five,
        title: l.perkOwnFiveTitle,
        sub: l.perkOwnFiveLine,
        fresh: false,
      ),
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
            key: const ValueKey('trial-offer-headline'),
            text: l.trialOfferTitle,
            mark: l.trialOfferMark,
            size: short ? 32 : 36,
          ),
          Padding(
            padding: EdgeInsets.only(top: short ? 6 : 8),
            child: Text(
              l.trialOfferLine,
              key: const ValueKey('trial-offer-line'),
              style: AppText.body(
                size: short ? 13.5 : 14.5,
                height: 1.38,
                color: p.ink.withValues(alpha: 0.62),
              ),
            ),
          ),
          SizedBox(height: short ? 16 : 22),
          _FeatureList(features: perks),
          SizedBox(height: short ? 16 : 22),
          _TrialDays(
            key: const ValueKey('trial-offer-days'),
            from: _opened,
            days: days,
            price: price,
            remind: _canRemind,
          ),
        ],
      ),
    );

    final List<Widget> foot = [
      SizedBox(height: short ? 8 : 12),
      ChunkyButton(
        key: const ValueKey('trial-offer-start'),
        label: _buying ? l.oneMoment : l.trialOfferStart,
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
            color: Colors.black.withValues(alpha: dark ? 0.45 : 0.15),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
        onPressed: _buying ? null : _start,
      ),
      SizedBox(height: short ? 8 : 10),
      // The way out, a button like the other, in full ink: the free plan
      // is a real choice here, not a word at the foot of the page.
      ChunkyButton(
        key: const ValueKey('trial-offer-free'),
        label: l.trialOfferFree,
        height: short ? 52 : 56,
        depth: 5,
        radius: 22,
        labelSize: 16,
        labelSpacing: 0.3,
        fill: p.surfaceRaised,
        ink: p.ink,
        edge: p.lineStrong,
        onPressed: _buying ? null : _leave,
      ),
      // What Apple asks for beside a subscription: a way back to what was
      // already paid for, the terms and the privacy policy.
      Padding(
        padding: EdgeInsets.only(top: short ? 8 : 12),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _SmallLink(
              l.restorePurchases,
              key: const ValueKey('trial-offer-restore'),
              onTap: _restore,
              link: false,
            ),
            _SmallLink.dot(context),
            _SmallLink(
              l.termsOfUse,
              onTap: () => openLink(termsUrlFor(defaultTargetPlatform)),
            ),
            _SmallLink.dot(context),
            _SmallLink(l.privacyPolicy, onTap: () => openLink(kPrivacyUrl)),
          ],
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: p.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // The paywall's three soft lights, drifting behind the top.
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
                  badge,
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, room) => _FadeFoot(
                        child: SingleChildScrollView(
                          key: const ValueKey('trial-offer-scroll'),
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
        ],
      ),
    );
  }
}

/// The free trial as the days it will go by, each with its date: today,
/// when everything opens and nothing is paid; the day the reminder is
/// sent, where it can reach the reader; and the day the year starts, at
/// the store's own price — the largest figure on the screen, as the stores
/// ask of a price beside a free trial — with how it renews and how to pay
/// nothing.
///
/// A rail through three dots in the headline's three colours: today's
/// filled, the days to come open.
class _TrialDays extends StatelessWidget {
  const _TrialDays({
    super.key,
    required this.from,
    required this.days,
    required this.price,
    required this.remind,
    this.dense = false,
  });

  /// The day the trial would start.
  final DateTime from;

  /// How many days free the store gives this reader.
  final int days;

  /// The year's price, as the store writes it.
  final String price;

  /// Whether the reminder before the charge can reach the reader.
  final bool remind;

  /// Set closer, for a page with more above it than the first run's offer
  /// (lib/screens/first_offer.dart): the same days, the same words.
  final bool dense;

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
    const int warn = AppState.kTrialWarningDays;
    final List<_TrialStep> steps = [
      _TrialStep(
        name: l.trialStepToday,
        date: date(0),
        line: l.trialStepTodayLine,
        hue: hues[0],
        today: true,
      ),
      // The warning the app sends before the charge, on the day it is set
      // for; a trial too short to have that day has no step for it.
      if (remind && days > warn)
        _TrialStep(
          name: l.trialStepDay(days - warn),
          date: date(days - warn),
          line: l.trialStepReminderLine(warn),
          hue: hues[1],
        ),
      _TrialStep(
        name: l.trialStepDay(days),
        date: date(days),
        price: price,
        line: l.trialStepChargeLine,
        hue: hues[2],
      ),
    ];
    return Container(
      padding: dense
          ? const EdgeInsets.fromLTRB(14, 12, 16, 12)
          : const EdgeInsets.fromLTRB(16, 16, 18, 16),
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
              key: ValueKey('trial-step-$i'),
              step: step,
              first: i == 0,
              last: i == steps.length - 1,
              dense: dense,
            ),
        ],
      ),
    );
  }
}

/// One day of the trial: its name and date, the price when it is the day
/// the year starts, and its line.
class _TrialStep {
  const _TrialStep({
    required this.name,
    required this.date,
    required this.line,
    required this.hue,
    this.price,
    this.today = false,
  });

  final String name;
  final String date;
  final String line;
  final Color hue;
  final String? price;
  final bool today;
}

class _TrialStepRow extends StatelessWidget {
  const _TrialStepRow({
    super.key,
    required this.step,
    required this.first,
    required this.last,
    this.dense = false,
  });

  final _TrialStep step;
  final bool first;
  final bool last;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final TextStyle name = AppText.body(
      size: 14.5,
      weight: FontWeight.w700,
      height: 1.25,
      color: p.ink,
    );
    // The dot sits on the middle of the name's line, wherever the phone's
    // text size puts it.
    final double nameLine =
        MediaQuery.textScalerOf(context).scale(name.fontSize!) * name.height!;
    // The words give the row its height, and the rail is drawn down the
    // whole of it, through the room under the words to the next dot.
    return Stack(
      children: [
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: 12,
          child: CustomPaint(
            painter: _RailPainter(
              dotAt: nameLine / 2,
              first: first,
              last: last,
              hue: step.hue,
              filled: step.today,
              rail: p.ink.withValues(alpha: 0.14),
              ground: p.surfaceRaised,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: 26,
            bottom: last ? 0 : (dense ? 10 : 16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(child: Text(step.name, style: name)),
                  const SizedBox(width: 10),
                  Text(
                    step.date,
                    style:
                        AppText.body(
                          size: 12.5,
                          weight: FontWeight.w500,
                          height: 1.25,
                          color: p.ink.withValues(alpha: 0.45),
                        ).copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                ],
              ),
              if (step.price case final String price)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    key: const ValueKey('trial-offer-price'),
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FitText(
                          price,
                          maxLines: 1,
                          minSize: 18,
                          style: AppText.display(
                            size: dense ? 24 : 27,
                            weight: FontWeight.w600,
                            height: 1,
                            spacing: -0.8,
                            color: p.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l.perYearShort,
                        style: AppText.body(
                          size: 13,
                          weight: FontWeight.w500,
                          height: 1,
                          color: p.ink.withValues(alpha: 0.42),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(
                  top: step.price == null ? 3 : (dense ? 5 : 7),
                ),
                child: Text(
                  step.line,
                  style: AppText.body(
                    size: dense ? 13 : 13.5,
                    height: 1.35,
                    color: p.ink.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A day's piece of the trial's rail: the hairline through it, and its dot
/// in its colour — filled for today, an open ring for the days to come.
class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.dotAt,
    required this.first,
    required this.last,
    required this.hue,
    required this.filled,
    required this.rail,
    required this.ground,
  });

  /// How far down the row its dot sits.
  final double dotAt;
  final bool first;
  final bool last;
  final Color hue;
  final bool filled;
  final Color rail;
  final Color ground;

  @override
  void paint(Canvas canvas, Size size) {
    final double x = size.width / 2;
    final Offset dot = Offset(x, dotAt);
    final Paint line = Paint()
      ..strokeWidth = 1.5
      ..color = rail;
    if (!first) canvas.drawLine(Offset(x, 0), dot, line);
    if (!last) canvas.drawLine(dot, Offset(x, size.height), line);
    canvas.drawCircle(dot, 6, Paint()..color = ground);
    if (filled) {
      canvas.drawCircle(dot, 5, Paint()..color = hue);
      return;
    }
    canvas.drawCircle(
      dot,
      4.25,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = hue,
    );
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.dotAt != dotAt ||
      old.first != first ||
      old.last != last ||
      old.hue != hue ||
      old.filled != filled ||
      old.rail != rail ||
      old.ground != ground;
}
