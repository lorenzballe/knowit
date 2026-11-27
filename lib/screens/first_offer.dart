part of 'paywall_screen.dart';

// The first week's page, and the first month's (lib/state/first_offers.dart
// says when each comes, and why): what the reader's week or month came to,
// in their own numbers, and under them the year's free days as the days
// they go by, at the store's own price, with "Not now" a button as plain
// as the trial's. Black at night and paper by day, as the app is; the
// numbers in the display face over hairlines, nothing that moves but the
// page coming in.
//
// It is the paywall's, drawn with the paywall's own pieces: the headline
// with its one painted word, the rail of the trial's days, the two buttons
// and the small print under them.

/// True while a page is being looked for: one at a time.
bool _firstOfferLooking = false;

/// Raises the page due now, if one is ([firstOfferDue]), over [context]'s
/// screen: Today, once the shelf has landed after a day finished in this
/// sitting, and only while Today is the screen in front. Noted as it rises,
/// so it rises once whatever happens next. True when it rose.
Future<bool> showFirstOfferIfDue(BuildContext context, AppState app) async {
  if (_firstOfferLooking) return false;
  _firstOfferLooking = true;
  try {
    final String? levelRose = await LevelMemory.roseOn();
    if (!context.mounted) return false;
    final FirstOffer? due = firstOfferDue(
      app,
      levelRoseToday: levelRose == dateKey(app.today),
    );
    if (due == null) return false;
    // Never over another screen, nor from a tab the reader has left.
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    if (!(ScreenPresence.maybeOf(context)?.showing ?? true)) return false;
    await switch (due) {
      FirstOffer.week => app.notedFirstWeekOffered(),
      FirstOffer.month => app.notedFirstMonthOffered(),
    };
    if (!context.mounted) return false;
    unawaited(
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(FirstOfferScreen.route(app, due)),
    );
    return true;
  } finally {
    _firstOfferLooking = false;
  }
}

/// Capitals, with Turkish's dotted capital I.
String _offerCaps(BuildContext context, String text) =>
    Localizations.localeOf(context).languageCode == 'tr'
    ? text.replaceAll('i', 'İ').toUpperCase()
    : text.toUpperCase();

/// The page: "Your first week" or "Your first month", the reader's numbers,
/// the year's free days, "Start the free trial" and "Not now".
class FirstOfferScreen extends StatefulWidget {
  const FirstOfferScreen({
    super.key,
    required this.app,
    required this.which,
    this.numbers,
    this.preview = false,
  });

  final AppState app;
  final FirstOffer which;

  /// What it says: the reader's own numbers, worked out as it opens, when
  /// null; a preview's sample otherwise.
  final FirstOfferNumbers? numbers;

  /// Opened from the developer tools only to be looked at: it says nothing
  /// to the numbers, keeps nothing, and stays up on a phone with Astute+.
  final bool preview;

  /// The page as it rises: a fade over the shelf; for a reader who asked
  /// for less motion, there at once.
  static Route<void> route(
    AppState app,
    FirstOffer which, {
    bool preview = false,
  }) => PageRouteBuilder<void>(
    fullscreenDialog: true,
    transitionDuration: const Duration(milliseconds: 600),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => FirstOfferScreen(
      app: app,
      which: which,
      numbers: preview ? FirstOfferNumbers.sample(which) : null,
      preview: preview,
    ),
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
  State<FirstOfferScreen> createState() => _FirstOfferScreenState();
}

class _FirstOfferScreenState extends State<FirstOfferScreen> {
  /// True from the press that starts the trial until the store answers:
  /// the button says so, and neither button takes a second press.
  bool _buying = false;

  /// True once the page is on its way out, and how it went: "Not now",
  /// the way back, the trial, Astute+ found already the reader's.
  bool _done = false;
  String _leftBy = 'back';

  /// How long the page was up.
  final Stopwatch _open = Stopwatch()..start();

  /// The day the page went up, which the trial's days are counted from.
  final DateTime _opened = DateTime.now();

  late final FirstOfferNumbers _numbers =
      widget.numbers ?? FirstOfferNumbers.of(widget.app, widget.which);

  Subscription get _store => Subscription.instance;

  /// The page's name where it is counted.
  String get _source => widget.which.source;

  @override
  void initState() {
    super.initState();
    unawaited(PurchaseSuccessScreen.precache());
    widget.app.addListener(_watchPlan);
    _store.addListener(_watchPlan);
    if (!widget.preview) {
      // What the page said, as counts and kinds: never the card or the
      // subject's words.
      Analytics.capture('first offer shown', {
        'source': _source,
        'days_read': _numbers.days,
        'cards_read': _numbers.cards,
        'streak_days': _numbers.streak,
        'has_sure': _numbers.sure != null,
        'has_strongest': _numbers.strongest != null,
        'best_card': _numbers.bestWhy?.name,
        'trial_days': _store.trialDays,
        'remind': _canRemind,
      });
    }
  }

  @override
  void dispose() {
    widget.app.removeListener(_watchPlan);
    _store.removeListener(_watchPlan);
    if (!widget.preview) {
      Analytics.capture('first offer closed', {
        'source': _source,
        'left_by': _leftBy,
        'ms_open': _open.elapsedMilliseconds,
        'is_plus': widget.app.isPlus,
      });
    }
    super.dispose();
  }

  /// Astute+ already the reader's — restored, an account that has it, an
  /// answer from the store that came late — and there is nothing to offer:
  /// the page goes. Not while a trial is being started, which ends on the
  /// screen a purchase ends on; and never on a preview.
  void _watchPlan() {
    if (_buying || _done || widget.preview) return;
    if (widget.app.isPlus || _store.isPlus) {
      scheduleMicrotask(() => _leave('plus already'));
    }
  }

  void _leave(String how) {
    if (_done || !mounted) return;
    _done = true;
    _leftBy = how;
    Navigator.of(context).maybePop();
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
      // Only a preview gets here with no store to buy from: said as that,
      // in the developer tools' English.
      if (widget.preview) {
        _say('A preview: no store on this phone to start a trial with.');
      } else {
        _leave('no offer');
      }
      return;
    }
    setState(() => _buying = true);
    final StoreProduct product = year.storeProduct;
    Analytics.capture('purchase started', {
      'source': _source,
      'plan': Plan.year.name,
      'has_package': true,
    });
    final PurchaseOutcome outcome = await _store.buy(year);
    Analytics.capture('purchase ended', {
      'source': _source,
      'plan': Plan.year.name,
      'outcome': outcome.name,
      'product': product.identifier,
      'price': product.price,
      'currency': product.currencyCode,
      'trial': product.introductoryPrice?.price == 0,
      'ms_open': _open.elapsedMilliseconds,
    });
    if (!mounted) return;
    final l = context.l10n;
    switch (outcome) {
      case PurchaseOutcome.bought:
        if (!widget.preview) {
          Analytics.capture('first offer trial started', {
            'source': _source,
            'product': product.identifier,
            'trial': product.introductoryPrice?.price == 0,
            'trial_days': freeDaysOf(year),
            'ms_open': _open.elapsedMilliseconds,
          });
        }
        widget.app.setPlan(Plan.year);
        final Future<void> applied = widget.app.applyEntitlement(true);
        // What happened, as it happened: the screen a purchase ends on says
        // a free trial started, and when the first charge comes.
        await showPurchaseSuccess(
          context,
          widget.app,
          source: _source,
          plan: Plan.year,
        );
        await applied;
        _leave('trial');
      case PurchaseOutcome.pending:
        // Waiting on someone's approval: said as that, and the store says
        // when it goes through.
        _say(l.purchasePending);
        _leave('pending');
      case PurchaseOutcome.cancelled:
        setState(() => _buying = false);
      case PurchaseOutcome.failed:
        _say(l.thatDidNotGoThrough);
        setState(() => _buying = false);
    }
  }

  /// A reader who already paid, on a new phone: back to their plan, and
  /// the page goes.
  Future<void> _restore() async {
    if (_buying || _done) return;
    final RestoreOutcome outcome = await _store.restore();
    if (!mounted) return;
    final l = context.l10n;
    if (outcome == RestoreOutcome.restored) {
      _say(l.plusIsBack);
      await widget.app.applyEntitlement(true);
      _leave('restored');
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
      // A preview says the store's price when it has one, and the plans as
      // sold when it has not; it is only looked at.
      if (widget.preview) {
        return _page(
          context,
          price: planPrice(Plan.year),
          days: days ?? kTrialDays,
        );
      }
      // The store took back what it had on sale, or the free days: nothing
      // to say a price for, so nothing is offered.
      if (year == null || days == null) {
        scheduleMicrotask(() => _leave('no offer'));
        return Scaffold(backgroundColor: context.p.surface);
      }
      return ScreenView(
        name: _source,
        child: _page(context, price: year.storeProduct.priceString, days: days),
      );
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
    final bool week = widget.which == FirstOffer.week;
    final FirstOfferNumbers n = _numbers;
    final double homeBar = MediaQuery.viewPaddingOf(context).bottom;
    final double scale = MediaQuery.textScalerOf(context).scale(100) / 100;
    // As on the paywall: one screen up to a little past the default text
    // size, made a little smaller where it nearly fits; past that the page
    // scrolls at its full size. The two buttons stay at the foot either
    // way, so "Not now" is always in sight.
    final bool oneScreen = scale <= 1.2;
    final bool short =
        MediaQuery.sizeOf(context).height -
            MediaQuery.paddingOf(context).vertical <
        700;

    final Widget body = Padding(
      padding: EdgeInsets.only(bottom: short ? 12 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: short ? 0 : 10),
          // Whose days, and how many: the eyebrow over the title.
          Text(
            _offerCaps(context, l.firstOfferDays(n.days)),
            key: const ValueKey('first-offer-eyebrow'),
            style: AppText.label(
              size: 11,
              weight: FontWeight.w700,
              spacing: 2.4,
              color: p.inkMuted,
            ),
          ),
          SizedBox(height: short ? 4 : 8),
          // On one line as long as it can be, a size smaller where the
          // language is long.
          Semantics(
            header: true,
            child: FitText(
              week ? l.firstWeekTitle : l.firstMonthTitle,
              key: const ValueKey('first-offer-title'),
              maxLines: 1,
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
          _OfferFigures(numbers: n, week: week, short: short),
          SizedBox(height: short ? 14 : 26),
          // Then the offer, under a line of its own: the year's free days,
          // what they open, and the days they go by.
          _Headline(
            key: const ValueKey('first-offer-trial-title'),
            text: l.firstOfferTrialTitle(days),
            mark: 'Astute+',
            size: short ? 19 : 22,
          ),
          // What the free days open, in a line; left out on the smallest
          // phones, as the paywall leaves out what is said elsewhere, rather
          // than scroll the trial's days out of sight.
          if (!short)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l.firstOfferPlusLine,
                key: const ValueKey('first-offer-plus-line'),
                style: AppText.body(
                  size: 13.5,
                  height: 1.33,
                  color: p.ink.withValues(alpha: 0.62),
                ),
              ),
            ),
          SizedBox(height: short ? 8 : 12),
          _TrialDays(
            key: const ValueKey('first-offer-rail'),
            from: _opened,
            days: days,
            price: price,
            remind: _canRemind,
            dense: true,
          ),
        ],
      ),
    );

    final List<Widget> foot = [
      SizedBox(height: short ? 8 : 12),
      // The price on the button itself, as the paywall's says it: whatever
      // the page above has to scroll on the smallest phone, what starting
      // the trial costs is on what is pressed.
      ChunkyButton(
        key: const ValueKey('first-offer-start'),
        label: _buying
            ? l.oneMoment
            : l.tryFreeThen(days, price, l.perYearShort),
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
        onPressed: _buying ? null : _start,
      ),
      SizedBox(height: short ? 8 : 10),
      // The way out, a button like the other, in full ink, and for good:
      // the page is not put again.
      ChunkyButton(
        key: const ValueKey('first-offer-not-now'),
        label: l.firstOfferNotNow,
        height: short ? 50 : 56,
        depth: 5,
        radius: 22,
        labelSize: 16,
        labelSpacing: 0.3,
        fill: p.surfaceRaised,
        ink: p.ink,
        edge: p.lineStrong,
        onPressed: _buying ? null : () => _leave('not now'),
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
              key: const ValueKey('first-offer-restore'),
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
      key: const ValueKey('first-offer'),
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
                      key: const ValueKey('first-offer-scroll'),
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
    );
  }
}

/// One of the reader's numbers: the figure, what it is, and what it is made
/// of where that says more.
typedef _OfferFigure = ({
  String key,
  String value,
  String label,
  String? note,
  bool word,
});

/// The reader's numbers, two to a row between hairlines: the cards read,
/// how often right when sure, the strongest subject, the days in a row; and
/// under them, a row of its own, the best card when there is one. A number
/// the app cannot say yet is left out rather than drawn as a dash, and the
/// last of an odd count has its row to itself.
class _OfferFigures extends StatelessWidget {
  const _OfferFigures({
    required this.numbers,
    required this.week,
    required this.short,
  });

  final FirstOfferNumbers numbers;

  /// The week's page, or the month's: whose best card it is.
  final bool week;

  /// A short phone: the figures a size smaller, the rows closer.
  final bool short;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final String locale = Localizations.localeOf(context).toString();
    final FirstOfferNumbers n = numbers;
    final List<_OfferFigure> figures = [
      (
        key: 'cards',
        value: NumberFormat.decimalPattern(locale).format(n.cards),
        label: l.pillReadWord(n.cards),
        note: null,
        word: false,
      ),
      if (n.sure case final Tally sure)
        (
          key: 'sure',
          value: NumberFormat.percentPattern(locale).format(sure.share!),
          label: l.journeyRightWhenSure,
          note: l.answersRightOf(sure.right, sure.of),
          word: false,
        ),
      if (n.strongest case (key: final String key, tally: final Tally tally))
        (
          key: 'strongest',
          value: l.subjectOf(kTopics[key]?.name ?? key),
          label: l.journeyStrongest,
          note: l.answersRightOf(tally.right, tally.of),
          word: true,
        ),
      (
        key: 'streak',
        value: l.streakDays(n.streak),
        label: l.journeyInARow,
        note: null,
        word: false,
      ),
    ];
    final BorderSide rule = BorderSide(color: p.line);
    final EdgeInsets row = EdgeInsets.symmetric(vertical: short ? 7 : 11);
    final Pill? best = n.best;
    return Container(
      key: const ValueKey('first-offer-figures'),
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
          if (best != null)
            Container(
              decoration: BoxDecoration(border: Border(top: rule)),
              padding: row.copyWith(bottom: row.bottom + 2),
              child: _OfferBestCard(card: best, why: n.bestWhy!, week: week),
            ),
        ],
      ),
    );
  }
}

class _OfferFigureCell extends StatelessWidget {
  const _OfferFigureCell({required this.figure, required this.short});

  final _OfferFigure figure;
  final bool short;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final _OfferFigure f = figure;
    return Column(
      key: ValueKey('first-offer-figure-${f.key}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A figure in the display face, as large as one line allows; a
        // subject's name a little smaller, on two lines at most.
        FitText(
          f.value,
          maxLines: f.word ? 2 : 1,
          minSize: f.word ? 16 : 18,
          wholeWords: true,
          style: AppText.display(
            size: f.word ? (short ? 19 : 22) : (short ? 22 : 27),
            weight: FontWeight.w500,
            height: 1.08,
            spacing: f.word ? -0.4 : -0.7,
            color: p.ink,
          ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        const SizedBox(height: 4),
        Text(
          _offerCaps(context, f.label),
          style: AppText.label(
            size: 10.5,
            weight: FontWeight.w700,
            spacing: 1.6,
            height: 1.25,
            color: p.inkMuted,
          ),
        ),
        if (f.note case final String note)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              note,
              style: AppText.body(
                size: 12.5,
                height: 1.3,
                color: p.ink.withValues(alpha: 0.5),
              ),
            ),
          ),
      ],
    );
  }
}

/// The best card of the week or the month: its colour, its question in the
/// display face, and why it is the best — the most the reader did with it.
class _OfferBestCard extends StatelessWidget {
  const _OfferBestCard({
    required this.card,
    required this.why,
    required this.week,
  });

  final Pill card;
  final BestCardWhy why;
  final bool week;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    return Column(
      key: const ValueKey('first-offer-best'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _offerCaps(context, week ? l.firstWeekBest : l.firstMonthBest),
          style: AppText.label(
            size: 10.5,
            weight: FontWeight.w700,
            spacing: 1.6,
            height: 1.25,
            color: p.inkMuted,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The card's own colour, as the week's questions stand beside
            // theirs in Your journey.
            ExcludeSemantics(
              child: Container(
                width: 3,
                height: 36,
                margin: const EdgeInsetsDirectional.only(end: 12, top: 2),
                decoration: cardFace(context, card.color, radius: 2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.question,
                    key: const ValueKey('first-offer-best-question'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(
                      size: 16,
                      weight: FontWeight.w500,
                      height: 1.22,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l.firstOfferBestWhy(why.name),
                    key: const ValueKey('first-offer-best-why'),
                    style: AppText.body(
                      size: 12.5,
                      height: 1.3,
                      color: p.ink.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
