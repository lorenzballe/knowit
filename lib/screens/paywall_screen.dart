import 'dart:async' show unawaited;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../analytics.dart';
import '../l10n/l10n.dart';
import '../legal.dart';

import 'package:purchases_flutter/purchases_flutter.dart';

import '../state/app_state.dart';
import '../state/progress.dart' show kCalibrationFloor;
import '../store_links.dart'
    show kAppStoreSubscriptionsUrl, kGooglePlaySubscriptionsUrl;
import '../sync/review_access.dart';
import '../sync/subscription.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/fit_text.dart';
import '../data/topics.dart';
import '../widgets/ambient.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart' show ScreenView;
import 'purchase_success_screen.dart';

/// What Astute+ costs, in cents, so the saving can be worked out rather than
/// asserted. A hardcoded "save 37%" is a number that quietly stops being true
/// the first time a price moves.
///
/// €3,99 a month is the anchor; €29,99 a year is the plan, preselected, at
/// two and a half a month. No lifetime, no third tier.
const int kMonthlyCents = 399;
const int kYearlyCents = 2999;

String _euros(int cents) {
  final whole = cents ~/ 100;
  final rest = (cents % 100).toString().padLeft(2, '0');
  return '€$whole,$rest';
}

/// Yearly against twelve months of monthly.
int get kYearlySavingPercent {
  final full = kMonthlyCents * 12;
  return (100 * (full - kYearlyCents) / full).round();
}

// Three things, the record first: the free profile says how far off the
// reader is today, and only the journey says whether that is closing, so it
// is the one thing the free plan cannot show at all. Then the day made of
// the reader's own cards, then every path whole: the free plan opens a
// path's first two cards, and the rest is here. (What you've read gave way
// to the paths: the archive's own door already opens on it, and a path is
// the thing a reader can see they are missing.) Six perks read as a list
// of features; three read as a reason.
//
// Each is drawn rather than marked with an icon: the gap closing on a
// chart, five cards fanned, a month of days read. An icon on a faint square
// said "feature"; the picture says which one, at a glance, and fills the
// card it sits on.
List<({_PerkArt art, String title, String sub})> _perks(
  AppLocalizations l, [
  PaywallVariant? variant,
]) => [
  (art: _PerkArt.gap, title: l.perkGapTitle, sub: l.perkGapLine),
  (art: _PerkArt.five, title: l.perkOwnFiveTitle, sub: l.perkOwnFiveLine),
  // On the paths' own door the headline says them already: what was read
  // takes their place there.
  variant == PaywallVariant.paths
      ? (art: _PerkArt.days, title: l.perkReadTitle, sub: l.perkReadLine)
      : (art: _PerkArt.paths, title: l.perkPathsTitle, sub: l.perkPathsLine),
];

/// The three perks' hues, the headline's three in its order — yellow, teal,
/// violet — bright at night, and deepened on paper enough to draw a line
/// in.
const List<Color> _perkHues = [
  Color(0xFFFFE14D),
  Color(0xFF2DE0D2),
  Color(0xFF8B6CFF),
];
const List<Color> _perkHuesOnPaper = [
  Color(0xFFD9A300),
  Color(0xFF00A99C),
  Color(0xFF6E3AFF),
];

/// What the paywall opens on, by the door it was opened from.
///
/// A reader who reached for the journey wanted to know how they are doing,
/// one who reached for the card after the fifth wanted the rest of the day,
/// one who reached for the archive wanted something they read: the first
/// thing each reads should be that, not one headline for everybody about
/// what the free plan already mostly gives.
enum PaywallVariant {
  /// How sure against how right, and whether the gap closes: the journey.
  record('A'),

  /// What the day Astute+ deals adds up to: every door not named here.
  outcome('B'),

  /// All five of the day, against the free day's two: the card after the
  /// fifth.
  five('C'),

  /// The days read, to open again: the archive.
  read('D'),

  /// Every path whole: a path's free cards read, or its tile.
  paths('E');

  const PaywallVariant(this.letter);

  /// How the paywall's numbers name it.
  final String letter;

  /// The variant [source] opens on. `calibration` is the record's own door
  /// in the paywall's numbers (see the README) and opens on the record,
  /// though no screen passes it today.
  static PaywallVariant of(String source) => switch (source) {
    'journey' || 'calibration' => record,
    'sixth card' => five,
    'archive' => read,
    'paths' => paths,
    _ => outcome,
  };
}

/// The reader's own numbers, once there are enough answers to say them
/// from (the floor the profile and the journey keep): how sure they say
/// they are on average and how often they are right, in whole percent, and
/// the signed gap between the two, positive when more sure than right.
({int sure, int right, double gap})? _readerNumbers(AppState app) {
  final double? gap = app.overconfidence;
  final said = app.sureAgainstRight;
  if (app.judgements.length < kCalibrationFloor ||
      gap == null ||
      said == null) {
    return null;
  }
  return (sure: said.sure.round(), right: said.right.round(), gap: gap);
}

/// What a door opens on: the headline, the words in it painted in the
/// lights, and the line under it.
({String title, String mark, String line}) _opening(
  AppLocalizations l,
  PaywallVariant variant,
  AppState app,
) => switch (variant) {
  PaywallVariant.record => (
    title: l.paywallRecordTitle,
    mark: l.paywallRecordMark,
    line: switch (_readerNumbers(app)) {
      // Said the way the profile says it: within five points either way is
      // a match, and only past that is the reader over or under.
      (:final int sure, :final int right, :final double gap)
          when gap.abs().round() <= 5 =>
        l.paywallRecordEven(sure, right),
      (:final int sure, :final int right, :final double gap) when gap > 0 =>
        l.paywallRecordOver(sure, right),
      (:final int sure, :final int right, gap: _) => l.paywallRecordUnder(
        sure,
        right,
      ),
      null => l.paywallRecordLine,
    },
  ),
  PaywallVariant.outcome => (
    title: l.paywallOutcomeTitle,
    mark: l.paywallOutcomeMark,
    line: l.paywallOutcomeLine,
  ),
  PaywallVariant.five => (
    title: l.paywallFiveTitle,
    mark: l.paywallFiveMark,
    line: l.paywallFiveLine,
  ),
  PaywallVariant.read => (
    title: l.paywallReadTitle,
    mark: l.paywallReadMark,
    line: l.paywallReadLine,
  ),
  PaywallVariant.paths => (
    title: l.paywallPathsTitle,
    mark: l.paywallPathsMark,
    line: l.paywallPathsLine,
  ),
};

/// What the year comes to a month, in the store's own currency once it has
/// answered: an American reader saw "\$29.99" on the tile and "€2,49 a month"
/// under it. The store's figure first, then a twelfth of its price, then the
/// price written into the app. A twelfth worked out here is written the way
/// the reader's language writes money ([locale]), so an Italian reads
/// "2,50 €" under "29,99 €" rather than "€2.50".
String yearPerMonth({String? locale}) {
  final StoreProduct? year = Subscription.instance.yearly?.storeProduct;
  if (year == null) return _euros(kYearlyCents ~/ 12);
  final String? perMonth = year.pricePerMonthString;
  if (perMonth != null && perMonth.isNotEmpty) return perMonth;
  try {
    return NumberFormat.simpleCurrency(
      locale: locale,
      name: year.currencyCode,
    ).format(year.price / 12);
  } catch (_) {
    return _euros(kYearlyCents ~/ 12);
  }
}

/// The year against twelve months of the month, from the store's two prices
/// when it has both — the same currency, so the share is true wherever the
/// reader is — and from the prices written into the app before. Null when
/// the year saves nothing, so no badge claims it does.
int? yearlySaving() {
  final Subscription store = Subscription.instance;
  final double? year = store.yearly?.storeProduct.price;
  final double? month = store.monthly?.storeProduct.price;
  final int saving = year != null && month != null && month > 0
      ? (100 * (month * 12 - year) / (month * 12)).round()
      : kYearlySavingPercent;
  return saving > 0 ? saving : null;
}

/// What the store charges for [plan], or the price written into the app
/// when it has not answered — which only a debug build's paywall shows (see
/// Subscription.previewWithoutStore); a store build shows no price until
/// the store has given one.
String planPrice(Plan plan) {
  final Subscription store = Subscription.instance;
  final Package? package = plan == Plan.year ? store.yearly : store.monthly;
  if (package != null) return package.storeProduct.priceString;
  return _euros(plan == Plan.year ? kYearlyCents : kMonthlyCents);
}

/// How many days free [plan] starts with for this reader, or null when it
/// is charged today. The store's word when it has answered — its
/// introductory offer at no charge, for a reader it will still give it to
/// — and otherwise the plans as sold: the year starts with [kTrialDays],
/// the month is charged today. The button and the line under it never
/// promise a day the store will not give.
int? planFreeDays(Plan plan) {
  final Subscription store = Subscription.instance;
  if (plan == Plan.year) return store.trialDays;
  final Package? package = store.monthly;
  return package == null ? null : freeDaysOf(package);
}

/// The screen a purchase ends on (design 129a): what was bought, what it
/// does next, and one button to begin. Returns when the reader starts.
///
/// Shown by the paywall after a purchase the store confirmed, and — to see
/// it without paying — by the debug tools and the site's `?simulate=purchase`.
Future<void> showPurchaseSuccess(
  BuildContext context,
  AppState app, {
  required String source,
  Plan? plan,
}) async {
  final l = context.l10n;
  final Plan bought = plan ?? app.plan;
  final String price = planPrice(bought);
  final String suffix = bought == Plan.year ? l.perYearShort : l.perMonthShort;
  final int? days = planFreeDays(bought);
  final DateTime now = DateTime.now();
  final DateTime renew = bought == Plan.year
      ? DateTime(now.year + 1, now.month, now.day)
      : DateTime(now.year, now.month + 1, now.day);
  final String locale = Localizations.localeOf(context).toString();
  String day(DateTime d) => DateFormat.MMMd(locale).format(d);
  final String? end = days == null ? null : day(now.add(Duration(days: days)));
  final String name = app.name.trim();
  final String? first = name.isEmpty || name == 'You'
      ? null
      : name.split(RegExp(r'\s+')).first;
  // Today's five are the reader's own from now on — unless today's are
  // already read, and then it is tomorrow's.
  final bool tomorrow = app.dayClosed;
  final String welcome = switch (first) {
    null when tomorrow => l.successWelcomeTomorrow,
    null => l.successWelcome,
    final String n when tomorrow => l.successWelcomeTomorrowNamed(n),
    final String n => l.successWelcomeNamed(n),
  };
  final bool iOS = Theme.of(context).platform == TargetPlatform.iOS;
  Analytics.capture('purchase success shown', {
    'source': source,
    'plan': bought.name,
    'trial': days != null,
  });
  // Asked for again here for a screen opened without the paywall — the
  // debug tools, the site — and already done when the paywall opened it.
  unawaited(PurchaseSuccessScreen.precache());
  await Navigator.of(context).push(
    PageRouteBuilder<void>(
      // A short fade: the take starts as the store's sheet goes.
      transitionDuration: const Duration(milliseconds: 150),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, _, _) => PurchaseSuccessScreen(
        // What happened, as it happened: a free trial is not a purchase,
        // and nothing was paid today.
        title: end != null ? l.trialStartedTitle : l.purchaseComplete,
        welcome: welcome,
        planName: l.successPlanName(
          bought == Plan.year ? l.planYearly : l.planMonthly,
        ),
        planLine: end != null
            ? l.successFreeUntil(end, price, suffix)
            : l.successRenewsLine(day(renew), price, suffix),
        foot: end != null
            ? l.successFootFirstCharge(end)
            : l.successFootRenews(day(renew)),
        onReceipt: () => openLink(
          iOS ? kAppStoreSubscriptionsUrl : kGooglePlaySubscriptionsUrl,
        ),
      ),
      transitionsBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Astute+.
///
/// Prices come from the store, so what is shown is what the reader's store
/// will actually charge, in their currency. Until it has answered there is
/// no price on screen at all: the paywall says it is asking, and when the
/// store cannot be reached it says that, with a way to try again. A price
/// written into the app is shown only by a debug build, which has no store
/// to ask (Subscription.previewWithoutStore).
///
/// Pushed over the screen whose door opened it — the card after the fifth,
/// Profile, a locked feature — and never part of the first run: a new
/// reader goes from the subjects to their first cards with nothing in
/// between.
class PaywallScreen extends StatefulWidget {
  final AppState app;

  /// What the reader reached for to end up here. Required, and a plain word
  /// rather than a default, because "where did they come from" is the only
  /// question a paywall's numbers ever really answer — and a default would be
  /// a fifth of the traffic labelled `unknown` within a week.
  final String source;

  const PaywallScreen({super.key, required this.app, required this.source});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late Plan _plan = widget.app.plan;

  /// How long the offer was on screen, how it was left, and how often the
  /// reader went between the plans — the three things a paywall's own
  /// numbers are made of.
  final Stopwatch _open = Stopwatch()..start();
  String _leftBy = 'back';
  int _planChanges = 0;

  /// True from the press that starts a purchase until the store answers:
  /// the button says so and takes no second press. A second press used to
  /// start a second purchase, and one sandbox purchase was counted twice.
  bool _buying = false;

  Subscription get _store => Subscription.instance;

  /// What this door opens on.
  PaywallVariant get _variant => PaywallVariant.of(widget.source);

  /// What the paywall can show of the plans: the store's own, a debug
  /// build's plans as sold (see Subscription.previewWithoutStore), the
  /// web's word that Astute+ is in the app, or where the store stands.
  _Offer get _offer {
    if (_store.answer == StoreAnswer.ready) return _Offer.plans;
    if (kIsWeb) return _Offer.inTheApp;
    if (Subscription.previewWithoutStore) return _Offer.preview;
    return _store.answer == StoreAnswer.asking
        ? _Offer.asking
        : _Offer.unreachable;
  }

  /// The store as the strings name it.
  static String get _storeName =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'apple' : 'google';

  @override
  void initState() {
    super.initState();
    // A store that has not answered is asked again as the paywall opens:
    // the reader is here to look at the prices.
    unawaited(_store.reloadOffering());
    // And the screen a purchase ends on has its pictures ready before it is
    // needed, so its first frames are whole.
    unawaited(PurchaseSuccessScreen.precache());
    Analytics.capture('paywall shown', {
      'source': widget.source,
      // Which opening the door gave, and whether the reader has numbers of
      // their own to be told: on the record's door they are the line under
      // the headline; on any other, they count who could have been told.
      'variant': _variant.letter,
      'has_number': _readerNumbers(widget.app) != null,
      'plan_shown': _plan.name,
      // Whether the store's prices are on screen. A conversion rate measured
      // against a paywall that could not sell is not a conversion rate.
      'store_answered': _store.answer == StoreAnswer.ready,
      'store': _store.answer.name,
    });
  }

  String _priceFor(Plan plan) => planPrice(plan);

  int? _freeDays(Plan plan) => planFreeDays(plan);

  /// The plans there are to choose between: both, unless the store put
  /// only one on sale — a plan the store does not sell is not shown at a
  /// price written into the app.
  List<Plan> get _plansOnSale => _offer == _Offer.preview
      ? Plan.values
      : [
          if (_store.yearly != null) Plan.year,
          if (_store.monthly != null) Plan.month,
        ];

  /// The plan on screen: the one picked, or the one on sale when only one
  /// is.
  Plan get _shown {
    final List<Plan> sale = _plansOnSale;
    return sale.isEmpty || sale.contains(_plan) ? _plan : sale.first;
  }

  String get _cta {
    final l = context.l10n;
    if (widget.app.isPlus) return l.plusIsActive;
    if (_buying) return l.oneMoment;
    final Plan plan = _shown;
    final String suffix = plan == Plan.year ? l.perYearShort : l.perMonthShort;
    final String price = _priceFor(plan);
    final int? days = _freeDays(plan);
    return days != null
        ? l.tryFreeThen(days, price, suffix)
        : l.subscribeFor(price, suffix);
  }

  /// The package for the plan on screen, if the store has offered one.
  Package? get _package => _shown == Plan.year ? _store.yearly : _store.monthly;

  @override
  void dispose() {
    Analytics.capture('paywall closed', {
      'source': widget.source,
      'left_by': _leftBy,
      'ms_open': _open.elapsedMilliseconds,
      'plan': _plan.name,
      'plan_changes': _planChanges,
      'is_plus': widget.app.isPlus,
    });
    super.dispose();
  }

  void _pick(Plan plan) {
    if (plan == _plan || _buying) return;
    _planChanges += 1;
    Analytics.capture('paywall plan selected', {
      'source': widget.source,
      'plan': plan.name,
      'from': _plan.name,
      'ms_open': _open.elapsedMilliseconds,
    });
    setState(() => _plan = plan);
    widget.app.setPlan(plan);
  }

  void _leaveBy(String how) {
    _leftBy = how;
    _leave();
  }

  void _openLink(String which, String url) {
    Analytics.capture('paywall link opened', {
      'source': widget.source,
      'link': which,
    });
    openLink(url);
  }

  /// The way out. Every door pushes the paywall over the screen it was
  /// opened from, so it pops itself.
  void _leave() => Navigator.of(context).pop();

  void _say(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _start() async {
    if (_buying) return;
    final Plan plan = _shown;
    final Package? package = _package;
    Analytics.capture('purchase started', {
      'source': widget.source,
      'plan': plan.name,
      'has_package': package != null,
    });

    // No store to buy from. Only a debug build gets here — anywhere else the
    // button is not on screen until the store has answered — and there it
    // unlocks Astute+ on the phone, so the screens behind it can be seen,
    // and says so rather than let it look like a purchase.
    if (package == null) {
      if (!Subscription.previewWithoutStore) return;
      await widget.app.startPlusTrial();
      if (!mounted) return;
      _say('Astute+ is on for this phone, without a store: a debug build.');
      _leaveBy('unlocked without a store');
      return;
    }

    setState(() => _buying = true);
    final outcome = await _store.buy(package);
    Analytics.capture('purchase ended', {
      'source': widget.source,
      'plan': plan.name,
      'outcome': outcome.name,
      'product': package.storeProduct.identifier,
      'price': package.storeProduct.price,
      'currency': package.storeProduct.currencyCode,
      'trial': package.storeProduct.introductoryPrice?.price == 0,
      'ms_open': _open.elapsedMilliseconds,
      'plan_changes': _planChanges,
    });
    if (!mounted) return;
    switch (outcome) {
      case PurchaseOutcome.bought:
        // The answer to the purchase comes at once: the screen it ends on is
        // pushed while the plan is still being written down, and the plan is
        // waited for only on the way out. Nothing on that screen reads it.
        final Future<void> applied = widget.app.applyEntitlement(true);
        await _celebrate(plan);
        await applied;
        if (mounted) _leaveBy('bought');
        return;
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.pending:
        // Waiting on someone's approval: said as that, and the store says
        // when it goes through.
        _say(context.l10n.purchasePending);
        _leaveBy('pending');
        return;
      case PurchaseOutcome.failed:
        _say(context.l10n.thatDidNotGoThrough);
    }
    setState(() => _buying = false);
  }

  /// The screen a purchase ends on (design 129a). Returns when the reader
  /// starts.
  Future<void> _celebrate(Plan plan) => showPurchaseSuccess(
    context,
    widget.app,
    source: widget.source,
    plan: plan,
  );

  /// Google Play's reviewers cannot pay, so they type the code Play Console
  /// gave them. In English, as Google asks, and shown to nobody else: the
  /// badge only listens for a long press on Android.
  Future<void> _askReviewCode() async {
    final String? code = await showDialog<String>(
      context: context,
      builder: (context) => const _ReviewCodeDialog(),
    );
    if (code == null || code.trim().isEmpty || !mounted) return;
    final bool open = await _store.redeemReviewCode(code);
    if (!mounted) return;
    if (!open) {
      _say('That code is not right.');
      return;
    }
    await widget.app.applyEntitlement(true);
    if (!mounted) return;
    _say('Astute+ is on for this device.');
    _leaveBy('review access');
  }

  /// Apple requires a way back to something already paid for, and a reader
  /// on a new phone needs it before they will trust the first purchase. It
  /// is on screen whether or not the plans have come: it needs none of
  /// them.
  Future<void> _restore() async {
    final RestoreOutcome outcome = await _store.restore();
    Analytics.capture('purchases restored', {
      'found': outcome == RestoreOutcome.restored,
      'outcome': outcome.name,
    });
    if (!mounted) return;
    if (outcome == RestoreOutcome.restored) {
      await widget.app.applyEntitlement(true);
    }
    if (!mounted) return;
    final l = context.l10n;
    _say(switch (outcome) {
      RestoreOutcome.restored => l.plusIsBack,
      RestoreOutcome.nothing => l.nothingToRestore,
      RestoreOutcome.unreachable => l.storeUnreachable(_storeName),
    });
  }

  @override
  Widget build(BuildContext context) => ScreenView(
    name: 'paywall',
    // The store can answer while the screen is open — a try after a wait,
    // Try again — and the plans come in when it does.
    child: ListenableBuilder(
      listenable: _store,
      builder: (context, _) => _page(context),
    ),
  );

  Widget _page(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final bool dark = p.isDark;
    final double homeBar = MediaQuery.viewPaddingOf(context).bottom;
    final opening = _opening(l, _variant, widget.app);
    final double scale = MediaQuery.textScalerOf(context).scale(100) / 100;
    // One screen with nothing to scroll, up to a little past the default
    // text size. Past that the words need more than one screen has, and
    // the page scrolls, everything at its full size, rather than cut the
    // price, the terms or the way out.
    final bool oneScreen = scale <= 1.2;
    // A short phone — an SE, or a test's 800 by 600 — sets the headline and
    // the air around it a size smaller, so the perks keep room for all three
    // under the line the door adds and the trial's days over the links.
    final bool short =
        MediaQuery.sizeOf(context).height -
            MediaQuery.paddingOf(context).vertical <
        700;

    final Widget top = Row(
      children: [
        GestureDetector(
          // Google Play's reviewers get in here with the code Play Console
          // gives them; see review_access.dart.
          onLongPress: reviewCodeOffered ? _askReviewCode : null,
          child: Container(
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
        ),
        const Spacer(),
        Semantics(
          button: true,
          label: l.closeLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _leaveBy('close'),
            // A finger's room around a mark drawn smaller.
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.ink.withValues(alpha: 0.06),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: p.ink.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    final List<Widget> opener = [
      // Ten less than the air under the row used to be, now that the way
      // out is a finger's height: the headline stays where it was.
      SizedBox(height: short ? 4 : 12),
      _Headline(
        key: const ValueKey('paywall-headline'),
        text: opening.title,
        mark: opening.mark,
        size: short ? 34 : 40,
      ),
      // What the door was reached for, in a line: the record, the whole
      // day, the days, or what the habit adds up to.
      Padding(
        padding: EdgeInsets.only(top: short ? 8 : 10),
        child: FitText(
          opening.line,
          key: const ValueKey('paywall-line'),
          maxLines: 3,
          minSize: 12.5,
          style: AppText.body(
            size: short ? 14 : 15,
            height: 1.38,
            color: p.ink.withValues(alpha: 0.62),
          ),
        ),
      ),
    ];

    final List<Widget> foot = [
      SizedBox(height: short ? 8 : 12),
      ..._offerBlock(
        context,
        short: short,
        stacked: scale >= 1.6,
        oneScreen: oneScreen,
      ),
      // What Apple requires beside a subscription, always on screen: a way
      // back to something already paid for — which needs no plans, so it is
      // there while the store is not — and the terms and the privacy
      // policy. The web has no store to restore from.
      Padding(
        padding: EdgeInsets.only(top: short ? 6 : 10),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!kIsWeb) ...[
              _SmallLink(
                l.restorePurchases,
                key: const ValueKey('paywall-restore'),
                onTap: _restore,
                link: false,
              ),
              _SmallLink.dot(context),
            ],
            _SmallLink(
              l.termsOfUse,
              onTap: () =>
                  _openLink('terms', termsUrlFor(defaultTargetPlatform)),
            ),
            _SmallLink.dot(context),
            _SmallLink(
              l.privacyPolicy,
              onTap: () => _openLink('privacy', kPrivacyUrl),
            ),
          ],
        ),
      ),
    ];

    final EdgeInsets padding = EdgeInsets.fromLTRB(
      22,
      6,
      22,
      homeBar > 0 ? 0 : 16,
    );
    return Scaffold(
      backgroundColor: p.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Three soft lights behind the top of the screen, drifting.
          const Positioned(
            left: -80,
            top: -60,
            width: 560,
            height: 380,
            child: _Lights(),
          ),
          SafeArea(
            child: oneScreen
                // One screen, no scrolling. What is for sale is read at a
                // glance or it is not read: the three perks sit in whatever
                // height the opening, the plans and the button leave them,
                // and a phone too short for their lines shows their titles
                // alone rather than a scrollbar.
                ? Padding(
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        top,
                        ...opener,
                        Expanded(child: _perksInRoom(l)),
                        ...foot,
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: padding.copyWith(bottom: padding.bottom + 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        top,
                        ...opener,
                        const SizedBox(height: 18),
                        for (final (int i, perk) in _perks(
                          l,
                          _variant,
                        ).indexed) ...[
                          if (i > 0) const SizedBox(height: _Perk.between),
                          _Perk(
                            art: perk.art,
                            title: perk.title,
                            sub: perk.sub,
                            index: i,
                          ),
                        ],
                        const SizedBox(height: 6),
                        ...foot,
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// The three perks in the height the rest of the screen leaves them:
  /// three cards sharing it, each as tall as a third of it allows, so the
  /// room is filled by the three things rather than by the air between
  /// them. Past [_Perk.most] a card grows no more, and the rest is spread
  /// round the three. The three are set alike: their lines are shown on
  /// all three, at one size, or on none.
  Widget _perksInRoom(AppLocalizations l) => LayoutBuilder(
    builder: (context, room) {
      final perks = _perks(l, _variant);
      // Never right up against the line above or the plans below, however
      // short the phone.
      final double air = math.min(_Perk.air, room.maxHeight / 2);
      final double height = room.maxHeight - 2 * air;
      final double each =
          (height - (perks.length - 1) * _Perk.between) / perks.length;
      // A phone too short even for three of the smallest keeps as many as
      // there is room for, in order, rather than overflow: the record first.
      final int shown = each >= _Perk.least
          ? perks.length
          : math.max(
              0,
              math.min(
                perks.length,
                (height + _Perk.between) ~/ (_Perk.least + _Perk.between),
              ),
            );
      final double card = shown == perks.length
          ? math.min(each, _Perk.most)
          : _Perk.least;
      final _PerkLayout layout = _PerkLayout.fit(
        context,
        width: room.maxWidth,
        height: card,
        titles: [for (final perk in perks.take(shown)) perk.title],
        subs: [for (final perk in perks.take(shown)) perk.sub],
      );
      return Padding(
        padding: EdgeInsets.symmetric(vertical: air),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (int i, perk) in perks.take(shown).indexed) ...[
              if (i > 0) const SizedBox(height: _Perk.between),
              RiseIn.staggered(
                i,
                step: const Duration(milliseconds: 60),
                child: _Perk(
                  art: perk.art,
                  title: perk.title,
                  sub: perk.sub,
                  index: i,
                  layout: layout,
                ),
              ),
            ],
          ],
        ),
      );
    },
  );

  /// The plans, the button and the terms under it — or, where the store has
  /// not put the plans on screen, why not and what to do.
  List<Widget> _offerBlock(
    BuildContext context, {
    required bool short,
    required bool stacked,
    required bool oneScreen,
  }) {
    final l = context.l10n;
    final p = context.p;
    final bool dark = p.isDark;
    final _Offer offer = _offer;
    if (offer != _Offer.plans && offer != _Offer.preview) {
      return [
        _StorePanel(
          key: const ValueKey('paywall-store'),
          offer: offer,
          storeName: _storeName,
          onTryAgain: () => _store.reloadOffering(),
        ),
      ];
    }
    final List<Plan> sale = _plansOnSale;
    final Plan shown = _shown;
    final List<Widget> tiles = [
      for (final Plan plan in sale)
        plan == Plan.year
            ? _PlanTile(
                label: l.planYearly,
                price: _priceFor(Plan.year),
                per: l.perYearShort,
                note: l.aMonth(
                  yearPerMonth(
                    locale: Localizations.localeOf(context).toString(),
                  ),
                ),
                badge: sale.length < 2
                    ? null
                    : switch (yearlySaving()) {
                        final int saving => l.savePercent(saving),
                        null => null,
                      },
                selected: shown == Plan.year,
                onTap: () => _pick(Plan.year),
              )
            : _PlanTile(
                label: l.planMonthly,
                price: _priceFor(Plan.month),
                per: l.perMonthShort,
                note: l.billedMonthly,
                selected: shown == Plan.month,
                onTap: () => _pick(Plan.month),
              ),
    ];
    return [
      // Side by side, the same height on their own: three lines each, every
      // line fitted to the tile's width. At the largest text sizes, one
      // under the other, so a price is never broken across two lines.
      if (stacked || tiles.length < 2)
        for (final (int i, Widget tile) in tiles.indexed) ...[
          if (i > 0) const SizedBox(height: 14),
          tile,
        ]
      else
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: 10),
            Expanded(child: tiles[1]),
          ],
        ),
      SizedBox(height: short ? 10 : 18),
      // Sixty high on a five-point edge: the face and its edge together
      // are sixty-five — five less on a short phone, where the small print
      // under it needs the room.
      // Now and then a glint crosses the button, in the headline's three
      // colours: the one thing on the screen that moves on its own after
      // the opening, and it moves on the thing to press.
      _Sheen(
        on: !(widget.app.isPlus || _buying),
        face: (short ? 60 : 65) - 5,
        radius: 22,
        colours: dark ? _perkHues : _perkHuesOnPaper,
        child: ChunkyButton(
          key: const ValueKey('paywall-buy'),
          label: _cta,
          height: short ? 60 : 65,
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
          onPressed: widget.app.isPlus || _buying ? null : _start,
        ),
      ),
      // A reader already on Astute+ is sent to the store's own place for
      // their plan. This used to say "Cancel the trial" and turn a flag off
      // on the phone, while the store went on and charged them.
      if (widget.app.isPlus)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Analytics.capture('manage subscription opened', {
              'is_plus': true,
              'from': 'paywall',
            });
            Subscription.instance.presentCustomerCenter();
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              l.manageSubscription,
              textAlign: TextAlign.center,
              style: _smallPrintStyle(context),
            ),
          ),
        )
      else
        // Under the button, one line. The price and the plan are on the
        // button and on the tiles, the store's own sheet says the rest
        // before anything is charged, and the owner asked for the room back
        // from the trial's calendar and the two lines of terms that sat
        // here.
        Padding(
          padding: EdgeInsets.only(top: short ? 8 : 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: _smallPrintStyle(context).color,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l.cancelAnyTime,
                  key: const ValueKey('paywall-cancel'),
                  textAlign: TextAlign.center,
                  style: _smallPrintStyle(context),
                ),
              ),
            ],
          ),
        ),
    ];
  }
}

/// What the paywall can show of the plans.
enum _Offer {
  /// The store's own plans, at its prices.
  plans,

  /// A debug build's plans as sold, with no store behind them.
  preview,

  /// The web app, which has no store: Astute+ is bought in the app.
  inTheApp,

  /// Waiting on the store's answer.
  asking,

  /// No answer from the store.
  unreachable,
}

/// Where the plans would be, when the store has not put them on screen:
/// still asking, could not be reached — with the one thing to do about it —
/// or, on the web, where Astute+ is sold instead. Never a price written
/// into the app standing in for the store's.
class _StorePanel extends StatelessWidget {
  const _StorePanel({
    super.key,
    required this.offer,
    required this.storeName,
    required this.onTryAgain,
  });

  final _Offer offer;
  final String storeName;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final TextStyle line = AppText.body(
      size: 14,
      height: 1.4,
      color: p.ink.withValues(alpha: 0.62),
    );
    final Widget body = switch (offer) {
      _Offer.asking => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: p.ink.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              l.storeAsking(storeName),
              key: const ValueKey('paywall-asking'),
              style: line,
            ),
          ),
        ],
      ),
      _Offer.inTheApp => Text(
        l.plusInTheApp,
        textAlign: TextAlign.center,
        style: line,
      ),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.storeUnreachable(storeName),
            key: const ValueKey('paywall-unreachable'),
            textAlign: TextAlign.center,
            style: AppText.body(
              size: 16,
              weight: FontWeight.w600,
              height: 1.3,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.storeUnreachableLine,
            textAlign: TextAlign.center,
            style: line,
          ),
          const SizedBox(height: 16),
          ChunkyButton(
            key: const ValueKey('paywall-try-again'),
            label: l.tryAgain,
            height: 56,
            radius: 20,
            fill: p.inverse,
            ink: p.onInverse,
            onPressed: onTryAgain,
          ),
        ],
      ),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.ink.withValues(alpha: 0.09), width: 1.5),
      ),
      child: Semantics(liveRegion: true, child: body),
    );
  }
}

TextStyle _smallPrintStyle(BuildContext context) => AppText.body(
  size: 12.5,
  weight: FontWeight.w500,
  height: 1.4,
  color: context.p.ink.withValues(alpha: 0.45),
);

/// Asks a reviewer for their code. Its own widget so the field's controller
/// lives exactly as long as the dialog does.
class _ReviewCodeDialog extends StatefulWidget {
  const _ReviewCodeDialog();

  @override
  State<_ReviewCodeDialog> createState() => _ReviewCodeDialogState();
}

class _ReviewCodeDialogState extends State<_ReviewCodeDialog> {
  final TextEditingController _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _unlock() => Navigator.of(context).pop(_field.text);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Review access'),
    content: TextField(
      controller: _field,
      autofocus: true,
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: TextCapitalization.characters,
      decoration: const InputDecoration(hintText: 'Code from Play Console'),
      onSubmitted: (_) => _unlock(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      TextButton(onPressed: _unlock, child: const Text('Unlock')),
    ],
  );
}

/// A piece of the last line of small print that does something when
/// tapped — restore, the terms, the privacy policy — and the dot between two
/// of them.
class _SmallLink extends StatelessWidget {
  const _SmallLink(
    this.label, {
    super.key,
    required this.onTap,
    this.link = true,
  });

  final String label;
  final VoidCallback onTap;

  /// A page that opens, rather than an action the app takes.
  final bool link;

  static Widget dot(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: ExcludeSemantics(child: Text('·', style: _smallPrintStyle(context))),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    link: link,
    button: !link,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(label, style: _smallPrintStyle(context)),
    ),
  );
}

/// The three lights behind the top of the paywall: yellow, teal and violet,
/// blurred into one another and drifting fourteen points right and ten up
/// and back, seven seconds each way. Still when the phone asks for no
/// motion.
class _Lights extends StatelessWidget {
  const _Lights();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AmbientLoop(
        period: const Duration(seconds: 7),
        builder: (context, t) {
          final double e = Curves.easeInOut.transform(t);
          return Transform.translate(
            offset: Offset(14 * e, -10 * e),
            // Blurred once and moved whole: the drift never repaints it.
            child: const RepaintBoundary(child: _LightField()),
          );
        },
      ),
    );
  }
}

class _LightField extends StatelessWidget {
  const _LightField();

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(
        sigmaX: 38,
        sigmaY: 38,
        tileMode: TileMode.decal,
      ),
      child: const Stack(
        children: [
          _Light(
            left: 40,
            top: 80,
            width: 220,
            height: 180,
            colour: Color(0x29FFE14D),
          ),
          _Light(
            left: 220,
            top: 40,
            width: 240,
            height: 200,
            colour: Color(0x212DE0D2),
          ),
          _Light(
            left: 330,
            top: 150,
            width: 220,
            height: 180,
            colour: Color(0x298B6CFF),
          ),
        ],
      ),
    );
  }
}

class _Light extends StatelessWidget {
  final double left;
  final double top;
  final double width;
  final double height;
  final Color colour;

  const _Light({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.colour,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colour,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

/// The headline, as large as two lines allow, with the word it leans on —
/// "really", "yours." — painted in the three colours of the lights.
///
/// Drawn twice, one over the other: the whole line with that word's place
/// kept but left clear, and over it the word alone through the gradient.
/// The gradient is measured on the word itself, so it runs across "yours."
/// and not across the line, whatever the language puts around it.
class _Headline extends StatelessWidget {
  final String text;

  /// The part painted in the gradient; nothing is when it is not found.
  final String mark;

  /// The size it is set at when two lines hold it.
  final double size;

  const _Headline({
    super.key,
    required this.text,
    required this.mark,
    this.size = _size,
  });

  static const double _size = 40;
  static const double _least = 28;

  static const List<Color> _darkStops = [
    Color(0xFFFFE14D),
    Color(0xFF2DE0D2),
    Color(0xFF8B6CFF),
  ];

  // On paper the same three, deepened enough to read.
  static const List<Color> _lightStops = [
    Color(0xFFD9A300),
    Color(0xFF00A99C),
    Color(0xFF6E3AFF),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final double width = box.maxWidth;
        final DefaultTextStyle inherited = DefaultTextStyle.of(context);
        final TextScaler scaler = MediaQuery.textScalerOf(context);
        final TextDirection direction = Directionality.of(context);
        final TextHeightBehavior? heights =
            inherited.textHeightBehavior ??
            DefaultTextHeightBehavior.maybeOf(context);
        TextStyle styleAt(double size) => inherited.style.merge(
          AppText.display(
            size: size,
            weight: FontWeight.w600,
            height: 1.04,
            spacing: -1.4 * size / _size,
            color: context.p.ink,
          ),
        );
        TextPainter laidOut(double size, {int? lines}) => TextPainter(
          text: TextSpan(text: text, style: styleAt(size)),
          textDirection: direction,
          textScaler: scaler,
          textHeightBehavior: heights,
          maxLines: lines,
        )..layout(maxWidth: width);

        double size = this.size;
        while (size > _least) {
          final TextPainter painter = laidOut(size, lines: 2);
          final bool fits = !painter.didExceedMaxLines;
          painter.dispose();
          if (fits) break;
          size -= 1;
        }
        final TextStyle style = styleAt(size);
        final int at = mark.isEmpty ? -1 : text.lastIndexOf(mark);
        if (at < 0) return Text(text, style: style);

        final TextPainter painter = laidOut(size);
        final List<TextBox> boxes = painter.getBoxesForSelection(
          TextSelection(baseOffset: at, extentOffset: at + mark.length),
        );
        painter.dispose();
        if (boxes.isEmpty) return Text(text, style: style);
        Rect word = boxes.first.toRect();
        for (final TextBox b in boxes.skip(1)) {
          word = word.expandToInclude(b.toRect());
        }

        const Color clear = Color(0x00000000);
        final String lead = text.substring(0, at);
        final String tail = text.substring(at + mark.length);
        return Stack(
          children: [
            Text.rich(
              TextSpan(
                style: style,
                children: [
                  TextSpan(text: lead),
                  TextSpan(
                    text: mark,
                    style: const TextStyle(color: clear),
                  ),
                  TextSpan(text: tail),
                ],
              ),
            ),
            Positioned.fill(
              child: ExcludeSemantics(
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (_) => _gradient(
                    word,
                    context.p.isDark ? _darkStops : _lightStops,
                  ),
                  child: RichText(
                    textDirection: direction,
                    textScaler: scaler,
                    textHeightBehavior: heights,
                    text: TextSpan(
                      style: style.copyWith(color: clear),
                      children: [
                        TextSpan(text: lead),
                        TextSpan(
                          text: mark,
                          style: TextStyle(color: context.p.ink),
                        ),
                        TextSpan(text: tail),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// A 95° linear gradient over [r], stopped at 0, 55 and 100%, drawn the
  /// way a browser draws `linear-gradient(95deg, …)`: along a line through
  /// the middle, long enough that the far corners meet the end colours.
  static Shader _gradient(Rect r, List<Color> colours) {
    const double angle = 95 * math.pi / 180;
    final Offset along = Offset(math.sin(angle), -math.cos(angle));
    final double length =
        r.width * math.sin(angle).abs() + r.height * math.cos(angle).abs();
    return ui.Gradient.linear(
      r.center - along * (length / 2),
      r.center + along * (length / 2),
      colours,
      const [0, 0.55, 1],
    );
  }
}

/// What a perk's picture shows.
enum _PerkArt {
  /// The record: how sure, dashed, and how right, rising to meet it, the
  /// gap between them closing week by week.
  gap,

  /// The reader's own day: five cards, fanned, each its subject's colour.
  five,

  /// The days read: a month of them, filled in, the last one marked.
  days,

  /// A path: ten steps climbing from the easiest card to the hardest, each
  /// a little larger and brighter than the last.
  paths,
}

/// How the three perk cards are set, alike, in the room they share: how
/// tall, the picture's size, the title's, and the size of the line under
/// it, or none when the three lines do not all fit whole.
class _PerkLayout {
  const _PerkLayout({
    required this.height,
    required this.pad,
    required this.picture,
    required this.titleSize,
    required this.subSize,
  });

  final double height;
  final double pad;
  final double picture;
  final double titleSize;
  final double? subSize;

  /// Between the picture and the words.
  double get space => picture >= 56 ? 16 : 12;

  static double padFor(double h) => h >= 96
      ? 14
      : h >= 66
      ? 11
      : 7;

  /// The set that [height] allows cards [width] wide, with [titles] and
  /// [subs] in them.
  static _PerkLayout fit(
    BuildContext context, {
    required double width,
    required double height,
    required List<String> titles,
    required List<String> subs,
  }) {
    final double pad = padFor(height);
    final double picture = (height - 2 * pad).clamp(30.0, 84.0).toDouble();
    final double titleSize = height >= 76 ? 17.5 : (height >= 58 ? 16 : 15);
    final double words =
        width - 2 * (pad + 2) - picture - (picture >= 56 ? 16 : 12);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection direction = Directionality.of(context);
    final TextStyle base = DefaultTextStyle.of(context).style;
    double measure(String text, TextStyle style, int lines) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: text, style: base.merge(style)),
        textDirection: direction,
        textScaler: scaler,
        maxLines: lines,
      )..layout(maxWidth: math.max(0, words));
      final double h = painter.didExceedMaxLines
          ? double.infinity
          : painter.height;
      painter.dispose();
      return h;
    }

    double tallest(List<String> texts, TextStyle style, int lines) =>
        texts.map((t) => measure(t, style, lines)).fold(0, math.max);

    // A pixel or two kept back: what is measured and what is drawn can
    // round apart.
    final double left =
        height -
        2 * pad -
        tallest(titles, _Perk.titleStyle(titleSize, null), 1) -
        _Perk.under -
        2;
    double? subSize;
    for (double s = 13.5; s >= 12; s -= 0.5) {
      if (tallest(subs, _Perk.subStyle(s, null), 3) <= left) {
        subSize = s;
        break;
      }
    }
    return _PerkLayout(
      height: height,
      pad: pad,
      picture: picture,
      titleSize: titleSize,
      subSize: subSize,
    );
  }
}

/// One of the three things, on a card of its own in its hue: its picture,
/// its title, and its line where the cards have the room for it whole.
///
/// Given a [layout], the card is set by it — as tall as a third of the room
/// allows, with the picture a square as tall as the card does. Without one
/// — the page that scrolls, at the largest text sizes — it is as tall as
/// its words.
class _Perk extends StatelessWidget {
  final _PerkArt art;
  final String title;
  final String sub;

  /// Which of the three: its hue, and when its picture draws.
  final int index;
  final _PerkLayout? layout;

  const _Perk({
    required this.art,
    required this.title,
    required this.sub,
    required this.index,
    this.layout,
  });

  /// The least a card is: its picture and its title, a size down.
  static const double least = 46;

  /// The most it grows to.
  static const double most = 128;

  /// Between two cards, and above the first and below the last.
  static const double between = 10;
  static const double air = 8;

  /// Between the title and its line.
  static const double under = 4;

  static TextStyle titleStyle(double size, Color? ink) => AppText.body(
    size: size,
    weight: FontWeight.w700,
    height: 1.18,
    spacing: -0.25,
    color: ink,
  );

  static TextStyle subStyle(double size, Color? ink) =>
      AppText.body(size: size, height: 1.36, color: ink);

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final bool dark = p.isDark;
    final Color hue = (dark ? _perkHues : _perkHuesOnPaper)[index % 3];
    final _PerkLayout? set = layout;
    final double pad = set?.pad ?? 14;
    final double picture = set?.picture ?? 64;
    final double titleSize = set?.titleSize ?? 17.5;
    final double? subSize = set == null ? 13.5 : set.subSize;
    final Color subInk = p.ink.withValues(alpha: dark ? 0.62 : 0.66);

    return Container(
      key: ValueKey('paywall-perk-${art.name}'),
      height: set?.height,
      padding: EdgeInsets.symmetric(horizontal: pad + 2, vertical: pad),
      decoration: BoxDecoration(
        // The card's hue as a wash, stronger at the picture's side.
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.alphaBlend(
              hue.withValues(alpha: dark ? 0.13 : 0.10),
              dark ? p.surface : p.surfaceRaised,
            ),
            Color.alphaBlend(
              hue.withValues(alpha: dark ? 0.04 : 0.03),
              dark ? p.surface : p.surfaceRaised,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(
          set != null && set.height < 60 ? 16 : 22,
        ),
        border: Border.all(color: hue.withValues(alpha: dark ? 0.22 : 0.20)),
      ),
      child: Row(
        children: [
          _PerkPicture(art: art, hue: hue, size: picture, index: index),
          SizedBox(width: set?.space ?? 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                FitText(
                  title,
                  maxLines: 1,
                  minSize: 12,
                  style: titleStyle(titleSize, p.ink),
                ),
                if (subSize != null) ...[
                  const SizedBox(height: under),
                  Text(
                    sub,
                    maxLines: set == null ? null : 3,
                    style: subStyle(subSize, subInk),
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

/// A perk's picture: a square in its hue with the thing drawn in it, drawn
/// in once as the paywall opens — the line rising, the cards fanning, the
/// days filling — and still for anyone who asked for less motion.
class _PerkPicture extends StatefulWidget {
  const _PerkPicture({
    required this.art,
    required this.hue,
    required this.size,
    required this.index,
  });

  final _PerkArt art;
  final Color hue;
  final double size;
  final int index;

  @override
  State<_PerkPicture> createState() => _PerkPictureState();
}

class _PerkPictureState extends State<_PerkPicture>
    with SingleTickerProviderStateMixin {
  // Each a little after the one above, as the cards rise in.
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 1100 + 140 * widget.index),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _draw,
    curve: Interval(
      (140 * widget.index + 180) / (1100 + 140 * widget.index),
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _draw.value = 1;
    } else if (!_draw.isAnimating && _draw.value == 0) {
      _draw.forward();
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = context.p.isDark;
    final double s = widget.size;
    return ExcludeSemantics(
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: widget.hue.withValues(alpha: dark ? 0.16 : 0.12),
          borderRadius: BorderRadius.circular(s * 0.3),
        ),
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _t,
            builder: (context, _) => CustomPaint(
              size: Size.square(s),
              painter: _PerkArtPainter(
                art: widget.art,
                t: _t.value,
                hue: widget.hue,
                ink: context.p.ink,
                dark: dark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PerkArtPainter extends CustomPainter {
  _PerkArtPainter({
    required this.art,
    required this.t,
    required this.hue,
    required this.ink,
    required this.dark,
  });

  final _PerkArt art;
  final double t;
  final Color hue;
  final Color ink;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) => switch (art) {
    _PerkArt.gap => _gap(canvas, size.width),
    _PerkArt.five => _five(canvas, size.width),
    _PerkArt.days => _days(canvas, size.width),
    _PerkArt.paths => _paths(canvas, size.width),
  };

  /// Five weeks: how sure, dashed and level near the top, and how right,
  /// rising from well under it and closing on it, fast and then slowly, as
  /// a gap closes; the gap between the two shaded, each week a bead.
  void _gap(Canvas canvas, double s) {
    final Rect r = Rect.fromLTRB(s * 0.18, s * 0.25, s * 0.82, s * 0.78);
    Offset at(double x, double y) =>
        Offset(r.left + x * r.width, r.top + y * r.height);
    const double sure = 0.0;
    // How right, week by week: the gap halving, near enough.
    double rightAt(double x) => sure + 0.96 * math.pow(0.16, x).toDouble();
    const int steps = 48;
    final double reach = t.clamp(0.0, 1.0);
    final List<Offset> curve = [
      for (int i = 0; i <= steps; i++)
        if (i / steps <= reach + 1e-9) at(i / steps, rightAt(i / steps)),
    ];
    if (curve.isEmpty) return;
    final double sureY = at(0, sure).dy;

    // The gap, shaded between the two lines as far as the line has come.
    final Path wedge = Path()..moveTo(curve.first.dx, sureY);
    wedge.lineTo(curve.last.dx, sureY);
    for (final Offset o in curve.reversed) {
      wedge.lineTo(o.dx, o.dy);
    }
    wedge.close();
    canvas.drawPath(
      wedge,
      Paint()
        ..shader = ui.Gradient.linear(Offset(r.left, 0), Offset(r.right, 0), [
          hue.withValues(alpha: dark ? 0.30 : 0.24),
          hue.withValues(alpha: dark ? 0.10 : 0.08),
        ]),
    );

    // How sure: dashed, the whole width from the start.
    final Paint dash = Paint()
      ..color = ink.withValues(alpha: dark ? 0.6 : 0.5)
      ..strokeWidth = s * 0.032
      ..strokeCap = StrokeCap.round;
    for (double x = r.left; x < r.right - s * 0.01; x += s * 0.08) {
      canvas.drawLine(
        Offset(x, sureY),
        Offset(math.min(x + s * 0.035, r.right), sureY),
        dash,
      );
    }

    // How right, closing on it.
    final Path line = Path()..moveTo(curve.first.dx, curve.first.dy);
    for (final Offset o in curve.skip(1)) {
      line.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = hue
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.055
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // The weeks it has passed, as beads on it; the last ringed once the
    // line has reached it.
    for (int w = 0; w <= 4; w++) {
      final double x = w / 4;
      if (x > reach + 1e-9) break;
      final Offset o = at(x, rightAt(x));
      final bool last = w == 4;
      canvas.drawCircle(o, s * (last ? 0.058 : 0.045), Paint()..color = hue);
      canvas.drawCircle(
        o,
        s * (last ? 0.024 : 0.018),
        Paint()..color = dark ? const Color(0xFF15140A) : Colors.white,
      );
      if (last) {
        canvas.drawCircle(
          o,
          s * 0.1,
          Paint()
            ..color = hue.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.022,
        );
      }
    }
  }

  /// Five cards, fanned open from one held at the foot, each in a subject's
  /// colour, with two lines of words on each.
  void _five(Canvas canvas, double s) {
    const List<Color> cards = [
      Color(0xFFFF3D7F),
      Color(0xFFFF7A1A),
      Color(0xFFFFE600),
      Color(0xFF00D9D9),
      Color(0xFF4C6FFF),
    ];
    final Offset pivot = Offset(s * 0.5, s * 0.86);
    final double w = s * 0.27;
    final double h = s * 0.40;
    for (int i = 0; i < cards.length; i++) {
      final double angle = (i - 2) * 17 * math.pi / 180 * t;
      canvas.save();
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(angle);
      final RRect card = RRect.fromRectAndRadius(
        Rect.fromLTWH(-w / 2, -h - s * 0.06, w, h),
        Radius.circular(s * 0.05),
      );
      canvas.drawRRect(
        card.shift(Offset(0, s * 0.012)),
        Paint()..color = Colors.black.withValues(alpha: dark ? 0.35 : 0.12),
      );
      canvas.drawRRect(card, Paint()..color = cards[i]);
      final Color words = inkOn(cards[i]).withValues(alpha: 0.55);
      final Paint stroke = Paint()
        ..color = words
        ..strokeWidth = s * 0.025
        ..strokeCap = StrokeCap.round;
      final double top = -h - s * 0.06 + s * 0.08;
      canvas.drawLine(
        Offset(-w / 2 + s * 0.05, top),
        Offset(w / 2 - s * 0.05, top),
        stroke,
      );
      canvas.drawLine(
        Offset(-w / 2 + s * 0.05, top + s * 0.05),
        Offset(w / 2 - s * 0.10, top + s * 0.05),
        stroke,
      );
      canvas.restore();
    }
  }

  /// A month of days, four weeks of five, filled in as read; the few
  /// missed left empty, the last one ringed.
  void _days(Canvas canvas, double s) {
    const int cols = 5, rows = 4;
    const Set<int> missed = {3, 9, 14};
    final double cell = s * 0.105;
    final double gap = s * 0.04;
    final double width = cols * cell + (cols - 1) * gap;
    final double height = rows * cell + (rows - 1) * gap;
    final Offset origin = Offset((s - width) / 2, (s - height) / 2);
    final int count = cols * rows;
    for (int k = 0; k < count; k++) {
      final int col = k % cols, row = k ~/ cols;
      final Rect box = Rect.fromLTWH(
        origin.dx + col * (cell + gap),
        origin.dy + row * (cell + gap),
        cell,
        cell,
      );
      // Each day in turn, a little after the one before.
      final double shown = ((t * (count + 4) - k) / 4).clamp(0.0, 1.0);
      final bool read = !missed.contains(k);
      final Paint empty = Paint()
        ..color = ink.withValues(alpha: dark ? 0.12 : 0.10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, Radius.circular(cell * 0.3)),
        empty,
      );
      if (!read || shown == 0) continue;
      final Rect filled = Rect.fromCenter(
        center: box.center,
        width: cell * shown,
        height: cell * shown,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(filled, Radius.circular(cell * 0.3 * shown)),
        Paint()..color = hue.withValues(alpha: k == count - 1 ? 1 : 0.85),
      );
      if (k == count - 1 && t >= 0.999) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            box.inflate(s * 0.03),
            Radius.circular(cell * 0.45),
          ),
          Paint()
            ..color = hue.withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.02,
        );
      }
    }
  }

  /// Ten steps on a rising line, drawn one after another; the last ringed
  /// once it is reached.
  void _paths(Canvas canvas, double s) {
    Offset at(int i) => Offset(
      s * (0.2 + 0.6 * i / 9),
      s * (0.76 - 0.52 * math.pow(i / 9, 1.25)),
    );
    final int shown = (t * 10).ceil().clamp(0, 10);
    if (shown == 0) return;
    final Path line = Path()..moveTo(at(0).dx, at(0).dy);
    for (int i = 1; i < shown; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = hue.withValues(alpha: dark ? 0.45 : 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (int i = 0; i < shown; i++) {
      canvas.drawCircle(
        at(i),
        s * (0.032 + 0.026 * i / 9),
        Paint()..color = hue.withValues(alpha: 0.55 + 0.45 * i / 9),
      );
    }
    if (shown == 10 && t >= 0.999) {
      canvas.drawCircle(
        at(9),
        s * 0.1,
        Paint()
          ..color = hue.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.022,
      );
    }
  }

  @override
  bool shouldRepaint(_PerkArtPainter old) =>
      old.t != t ||
      old.art != art ||
      old.hue != hue ||
      old.ink != ink ||
      old.dark != dark;
}

class _PlanTile extends StatelessWidget {
  final String label;
  final String price;
  final String per;
  final String note;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PlanTile({
    required this.label,
    required this.price,
    required this.per,
    required this.note,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final bool dark = p.isDark;
    final Color off = dark ? const Color(0xFF0F0F11) : p.surfaceRaised;
    final List<Color> on = dark
        ? const [Color(0xFF242427), Color(0xFF161618)]
        : [p.surfaceRaised, p.surface];

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $price $per',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The chosen plan's ring in the headline's three colours, the
            // ones its word and the perks are in: one thread through the
            // screen, from the word it leans on to the plan it ends on.
            TweenAnimationBuilder<double>(
              tween: Tween(end: selected ? 1 : 0),
              duration: const Duration(milliseconds: 220),
              curve: Curves.ease,
              builder: (context, ring, child) => CustomPaint(
                foregroundPainter: ring == 0
                    ? null
                    : _Ring(
                        colours: dark ? _perkHues : _perkHuesOnPaper,
                        width: 2,
                        radius: 24,
                        opacity: ring,
                      ),
                child: child,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.ease,
                // The ring is half a point thicker on the chosen one and the
                // padding half a point thinner, so nothing inside moves.
                padding: selected
                    ? const EdgeInsets.fromLTRB(16, 16, 16, 15)
                    : const EdgeInsets.fromLTRB(16.5, 16.5, 16.5, 15.5),
                decoration: BoxDecoration(
                  // 160°, top to bottom and a little across.
                  gradient: LinearGradient(
                    begin: const Alignment(-0.33, -1.36),
                    end: const Alignment(0.33, 1.36),
                    colors: selected ? on : [off, off],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    // Under the ring, on the chosen one.
                    color: selected
                        ? const Color(0x00000000)
                        : p.ink.withValues(alpha: 0.09),
                    width: selected ? 2 : 1.5,
                  ),
                  boxShadow: selected
                      ? [
                          // A faint glow of the ring's middle colour.
                          BoxShadow(
                            color: (dark ? _perkHues : _perkHuesOnPaper)[1]
                                .withValues(alpha: dark ? 0.16 : 0.12),
                            blurRadius: 22,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: dark ? 0.5 : 0.12,
                            ),
                            blurRadius: 34,
                            offset: const Offset(0, 14),
                          ),
                        ]
                      : const [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _Radio(on: selected),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FitText(
                            label,
                            maxLines: 1,
                            minSize: 12,
                            style: AppText.body(
                              size: 16,
                              weight: FontWeight.w600,
                              height: 1,
                              color: p.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: FitText(
                            price,
                            maxLines: 1,
                            minSize: 16,
                            style: AppText.display(
                              size: 27,
                              weight: FontWeight.w600,
                              height: 1,
                              spacing: -0.8,
                              color: p.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          per,
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w500,
                            height: 1,
                            color: p.ink.withValues(alpha: 0.42),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    FitText(
                      note,
                      maxLines: 1,
                      minSize: 10,
                      style: AppText.body(
                        size: 12.5,
                        weight: FontWeight.w500,
                        height: 1.2,
                        color: p.ink.withValues(alpha: 0.52),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // The saving rides the tile's top edge rather than taking a
            // row inside it, so the two tiles stay the same height.
            if (badge != null)
              Positioned(
                top: -12,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: p.inverse,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: dark ? 0.4 : 0.15,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    badge!,
                    style: AppText.label(
                      size: 10,
                      weight: FontWeight.w700,
                      spacing: 1.4,
                      height: 1,
                      color: p.onInverse,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A glint that crosses [child] — a button whose face is [face] high, with
/// corners of [radius] — every few seconds, in [colours], and rests between.
/// Not at all while [on] is false, or for anyone who asked for less motion.
class _Sheen extends StatelessWidget {
  const _Sheen({
    required this.on,
    required this.face,
    required this.radius,
    required this.colours,
    required this.child,
  });

  final bool on;
  final double face;
  final double radius;
  final List<Color> colours;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!on) return child;
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: face,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: RepaintBoundary(
                  child: AmbientLoop(
                    period: const Duration(milliseconds: 6500),
                    reverse: false,
                    builder: (context, t) => CustomPaint(
                      painter: _SheenPainter(t: t, colours: colours),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheenPainter extends CustomPainter {
  _SheenPainter({required this.t, required this.colours});

  final double t;
  final List<Color> colours;

  /// The part of each cycle the glint takes to cross; the rest is rest.
  static const double crossing = 0.21;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= crossing) return;
    final double k = Curves.easeInOut.transform(t / crossing);
    final double band = size.width * 0.42;
    final double x = -band + k * (size.width + 2 * band);
    // Leaning, as light across a curved face does.
    final Offset from = Offset(x - band / 2, size.height);
    final Offset to = Offset(x + band / 2, 0);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = BlendMode.srcOver
        ..shader = ui.Gradient.linear(
          from,
          to,
          [
            colours.first.withValues(alpha: 0),
            colours[0].withValues(alpha: 0.24),
            colours[1].withValues(alpha: 0.28),
            colours[2].withValues(alpha: 0.24),
            colours.last.withValues(alpha: 0),
          ],
          const [0, 0.3, 0.5, 0.7, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(_SheenPainter old) => old.t != t || old.colours != colours;
}

/// A ring drawn on a tile's edge in a run of colours, corner to corner.
class _Ring extends CustomPainter {
  _Ring({
    required this.colours,
    required this.width,
    required this.radius,
    required this.opacity,
  });

  final List<Color> colours;
  final double width;
  final double radius;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;
    final RRect ring = RRect.fromRectAndRadius(
      r.deflate(width / 2),
      Radius.circular(radius - width / 2),
    );
    canvas.drawRRect(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = ui.Gradient.linear(
          r.topLeft,
          r.bottomRight,
          [for (final Color c in colours) c.withValues(alpha: opacity)],
          const [0, 0.55, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(_Ring old) =>
      old.opacity != opacity ||
      old.colours != colours ||
      old.width != width ||
      old.radius != radius;
}

class _Radio extends StatelessWidget {
  final bool on;
  const _Radio({required this.on});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.ease,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? p.inverse : p.inverse.withValues(alpha: 0),
        border: Border.all(
          color: on
              ? p.inverse.withValues(alpha: 0)
              : p.ink.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: on ? CustomPaint(painter: _Tick(p.onInverse)) : null,
    );
  }
}

/// The tick in the chosen plan's circle: a fourteen-point check, drawn on a
/// twenty-four grid, 2.8 wide on that grid, with round ends.
class _Tick extends CustomPainter {
  final Color colour;
  const _Tick(this.colour);

  @override
  void paint(Canvas canvas, Size size) {
    const double glyph = 14;
    final double unit = glyph / 24;
    final Offset o = Offset(
      (size.width - glyph) / 2,
      (size.height - glyph) / 2,
    );
    Offset at(double x, double y) => o + Offset(x * unit, y * unit);
    final Path path = Path()
      ..moveTo(at(5, 12.5).dx, at(5, 12.5).dy)
      ..lineTo(at(9.5, 17).dx, at(9.5, 17).dy)
      ..lineTo(at(19, 7.5).dx, at(19, 7.5).dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8 * unit
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_Tick old) => old.colour != colour;
}
