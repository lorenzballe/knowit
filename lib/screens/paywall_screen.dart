import 'dart:async' show Timer, scheduleMicrotask, unawaited;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show ValueListenable, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import '../utils/reminders.dart' show remindersSupported;
import '../widgets/chunky.dart';
import '../widgets/deeper_sheet.dart' show cardAiOn;
import '../widgets/fit_text.dart';
import '../widgets/ambient.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart' show ScreenView;
import 'purchase_success_screen.dart';
import '../widgets/glass_round.dart';

part 'trial_offer.dart';

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

// Everything Astute+ is, every time, each with its line: the owner asked
// for no screen where the words are there one time and gone the next. One
// short line each, so all of it stands on an ordinary phone's screen with
// nothing to scroll; on the smallest the list scrolls under the plans
// rather than lose a word. The assistant and the coach first, as what is
// new; then the day of the reader's own cards, the paths and the books, the
// record, the archive. The door a reader came through puts its own thing
// first, so the first line under the headline is what they reached for.
// The assistant and the coach only where the answers by Claude are on for
// this reader ([ai], cardAiOn): the paywall never sells what is switched
// off.
//
// Each is marked by a small drawing in one of the headline's colours, in
// the line weight of the app's own marks: a speech bubble, a chart going
// up, cards in a fan, a book, two lines meeting, a clock turned back.
List<_Feature> _features(
  AppLocalizations l,
  PaywallVariant variant, {
  required bool ai,
}) {
  final _Feature ask = (
    glyph: _Glyph.ask,
    title: l.perkAskTitle,
    sub: l.perkAskLine,
    fresh: true,
  );
  final _Feature coach = (
    glyph: _Glyph.coach,
    title: l.perkCoachTitle,
    sub: l.perkCoachLine,
    fresh: true,
  );
  final _Feature five = (
    glyph: _Glyph.five,
    title: l.perkOwnFiveTitle,
    sub: l.perkFiveShort,
    fresh: false,
  );
  final _Feature shelves = (
    glyph: _Glyph.books,
    title: l.perkShelvesTitle,
    sub: l.perkShelvesLine,
    fresh: false,
  );
  final _Feature gap = (
    glyph: _Glyph.gap,
    title: l.perkGapTitle,
    sub: l.perkGapShort,
    fresh: false,
  );
  final _Feature read = (
    glyph: _Glyph.read,
    title: l.perkReadTitle,
    sub: l.perkReadShort,
    fresh: false,
  );
  final List<_Feature> all = [
    if (ai) ...[ask, coach],
    five,
    shelves,
    gap,
    read,
  ];
  final _Feature? first = switch (variant) {
    PaywallVariant.record => gap,
    PaywallVariant.five => five,
    PaywallVariant.read => read,
    PaywallVariant.paths => shelves,
    PaywallVariant.outcome => null,
  };
  return first == null ? all : [first, ...all.where((f) => f != first)];
}

/// One thing Astute+ gives: its mark, its name, its line, and whether it
/// is new.
typedef _Feature = ({_Glyph glyph, String title, String sub, bool fresh});

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
  if (app.calibratedAnswers < kCalibrationFloor ||
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
        l.elided(l.paywallRecordEven(sure, right)),
      (:final int sure, :final int right, :final double gap) when gap > 0 =>
        l.elided(l.paywallRecordOver(sure, right)),
      (:final int sure, :final int right, gap: _) => l.elided(
        l.paywallRecordUnder(sure, right),
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
  ValueListenable<bool?>? confirmed,
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
    'waiting': confirmed != null && confirmed.value != true,
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
        planLine: l.elided(
          end != null
              ? l.successFreeUntil(end, price, suffix)
              : l.successRenewsLine(day(renew), price, suffix),
        ),
        foot: l.elided(
          end != null
              ? l.successFootFirstCharge(end)
              : l.successFootRenews(day(renew)),
        ),
        onReceipt: () => openLink(
          iOS ? kAppStoreSubscriptionsUrl : kGooglePlaySubscriptionsUrl,
        ),
        confirmed: confirmed,
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

  /// Whether the answers by Claude are on for this reader: the assistant
  /// and the coach are offered only then.
  bool get _ai =>
      cardAiOn(widget.app, Localizations.localeOf(context).languageCode);

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

  /// Whether the store has answered the purchase under way.
  bool _answered = false;

  /// The answer the screen a purchase ends on waits for, when it went up
  /// before the store answered: null until it does, then yes or no.
  ValueNotifier<bool?>? _confirming;

  /// That screen, until it closes.
  Future<void>? _waited;

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
    final Future<PurchaseOutcome> asked = _store.buy(package);
    _watchTheSheet(plan, asked);
    final outcome = await asked;
    _answered = true;
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
    final ValueNotifier<bool?>? confirming = _confirming;
    final Future<void>? waited = _waited;
    _confirming = null;
    _waited = null;
    switch (outcome) {
      case PurchaseOutcome.bought:
        // The answer to the purchase comes at once: the screen it ends on is
        // pushed while the plan is still being written down, and the plan is
        // waited for only on the way out. Nothing on that screen reads it.
        // When that screen is already up, waiting on the answer, the answer
        // starts its take instead.
        final Future<void> applied = widget.app.applyEntitlement(true);
        if (confirming != null && waited != null) {
          confirming.value = true;
          await waited;
        } else {
          await _celebrate(plan);
        }
        await applied;
        if (mounted) _leaveBy('bought');
        return;
      case PurchaseOutcome.cancelled:
      case PurchaseOutcome.pending:
      case PurchaseOutcome.failed:
        // Nothing to celebrate: a screen waiting on the answer closes first,
        // and the paywall says what it says without it.
        if (confirming != null && waited != null) {
          confirming.value = false;
          await waited.timeout(const Duration(seconds: 1), onTimeout: () {});
          if (!mounted) return;
        }
    }
    if (!mounted) return;
    switch (outcome) {
      case PurchaseOutcome.bought:
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

  /// The store's sheet sits over the app while the reader pays: the app is
  /// away until it goes. When it has gone and the store has not answered
  /// within [_answerSoon] — a reader who backed out is answered at once; one
  /// who paid waits on the store's servers and RevenueCat's for a few
  /// seconds more — the screen a purchase ends on goes up on that wait, with
  /// no cross to leave by, and the answer, when it comes, starts its take or
  /// closes it. A purchase answered sooner never shows the wait.
  void _watchTheSheet(Plan plan, Future<PurchaseOutcome> answer) {
    _answered = false;
    bool away = false;
    Timer? soon;
    late final AppLifecycleListener watch;
    void open() {
      if (_answered || !mounted || _confirming != null) return;
      final ValueNotifier<bool?> confirmed = ValueNotifier<bool?>(null);
      _confirming = confirmed;
      _waited = showPurchaseSuccess(
        context,
        widget.app,
        source: widget.source,
        plan: plan,
        confirmed: confirmed,
      );
      // A wait that ran long, and the reader who went on from it: the
      // paywall goes too. Astute+ turns on when the store's answer comes,
      // with nobody waiting for it here (main.dart listens for it).
      _waited!.then((_) {
        if (!_answered && mounted) _leaveBy('went on while confirming');
      });
    }

    watch = AppLifecycleListener(
      onStateChange: (state) {
        if (state != AppLifecycleState.resumed) {
          away = true;
          soon?.cancel();
        } else if (away) {
          soon?.cancel();
          soon = Timer(_answerSoon, open);
        }
      },
    );
    answer.whenComplete(() {
      soon?.cancel();
      watch.dispose();
    });
  }

  /// How long after the store's sheet has gone an answer still counts as
  /// at once: a reader who backed out is answered well within it.
  static const Duration _answerSoon = Duration(milliseconds: 400);

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
        GlassRound(
          symbol: GlassRound.close,
          label: l.closeLabel,
          onPressed: () => _leaveBy('close'),
          size: 44,
          iconSize: 16,
          fallback: Semantics(
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
        ),
      ],
    );

    final List<Widget> opener = [
      // Ten less than the air under the row used to be, now that the way
      // out is a finger's height: the headline stays where it was.
      SizedBox(height: short ? 2 : 6),
      _Headline(
        key: const ValueKey('paywall-headline'),
        text: opening.title,
        mark: opening.mark,
        size: short ? 32 : 37,
      ),
      // What the door was reached for, in a line: the record, the whole
      // day, the days, or what the habit adds up to.
      Padding(
        padding: EdgeInsets.only(top: short ? 6 : 8),
        child: FitText(
          opening.line,
          key: const ValueKey('paywall-line'),
          maxLines: 3,
          minSize: 12.5,
          style: AppText.body(
            size: short ? 13.5 : 14.5,
            height: 1.38,
            color: p.ink.withValues(alpha: 0.62),
          ),
        ),
      ),
    ];

    final List<Widget> foot = [
      SizedBox(height: short ? 6 : 8),
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
                // The plans and the button always on screen, at the foot;
                // above them the opening and every feature, each with its
                // line, scrolling under the plans on a phone too short for
                // all of it, never cut down to fit.
                ? Padding(
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        top,
                        // Still where it all fits, made a little smaller
                        // together where it nearly does, and scrolling
                        // only where it is plainly more than the screen:
                        // never a page that gives under the finger by a
                        // few points on one door and not on another.
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, room) => _FadeFoot(
                              child: SingleChildScrollView(
                                key: const ValueKey('paywall-features-scroll'),
                                child: _FitDown(
                                  height: room.maxHeight,
                                  child: Padding(
                                    // Room under the last feature for the
                                    // fade at the foot to fall in, at any
                                    // size the words are set.
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ...opener,
                                        SizedBox(height: short ? 12 : 16),
                                        _FeatureList(
                                          features: _features(
                                            l,
                                            _variant,
                                            ai: _ai,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ...foot,
                      ],
                    ),
                  )
                // The way out stays put above what scrolls: on iOS 26 it is
                // Apple's own glass button, a native view, and one moved by
                // a scroll can be left drawn away from its place.
                : Padding(
                    padding: padding.copyWith(bottom: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        top,
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(
                              bottom: padding.bottom + 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ...opener,
                                const SizedBox(height: 22),
                                _FeatureList(
                                  features: _features(l, _variant, ai: _ai),
                                ),
                                const SizedBox(height: 6),
                                ...foot,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

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

/// The bottom of the scrolling part fades into the plans, so what goes on
/// under them is seen to go on rather than to stop at a line.
class _FadeFoot extends StatelessWidget {
  const _FadeFoot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (r) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [Colors.white, Colors.white, Colors.transparent],
      stops: [0, 1 - (18 / r.height).clamp(0.0, 1.0), 1],
    ).createShader(r),
    child: child,
  );
}

/// Its child at its own size where it fits in [height]; where it nearly
/// does, made smaller to fit, down to [least] of its size, and set as much
/// wider first, so it keeps the width it is given and its lines break where
/// they would; where even that would not fit, at its own size again, taller
/// than [height], for the scroll it is in to show the rest.
class _FitDown extends SingleChildRenderObjectWidget {
  const _FitDown({required this.height, required super.child});

  final double height;

  /// The smallest it is made: past this the words would be too small to
  /// read with ease, and scrolling them is the better way.
  static const double least = 0.8;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFitDown(height);

  @override
  void updateRenderObject(BuildContext context, _RenderFitDown r) =>
      r.height = height;
}

class _RenderFitDown extends RenderProxyBox {
  _RenderFitDown(this._height);

  double _height;
  set height(double value) {
    if (value == _height) return;
    _height = value;
    markNeedsLayout();
  }

  double _scale = 1;

  /// How much smaller the child is drawn: 1 where it is drawn at its size.
  @visibleForTesting
  double get scale => _scale;

  Matrix4 get _transform => Matrix4.diagonal3Values(_scale, _scale, 1);

  @override
  void performLayout() {
    final RenderBox? child = this.child;
    final double width = constraints.maxWidth;
    if (child == null) {
      size = constraints.constrain(Size(width, 0));
      return;
    }
    double lay(double across) {
      child.layout(
        BoxConstraints.tightFor(width: across),
        parentUsesSize: true,
      );
      return child.size.height;
    }

    _scale = 1;
    final double natural = lay(width);
    if (_height > 0 && natural > _height) {
      double fit = _height / natural;
      bool fits = false;
      if (fit >= _FitDown.least) {
        // Set wider by as much as it is made smaller, so it keeps its width.
        // Words that size themselves to their width can take more room set
        // wider; a few tries find the size they settle at.
        for (int i = 0; i < 4; i++) {
          final double tall = lay(width / fit);
          if (tall * fit <= _height + 0.5) {
            fits = true;
            break;
          }
          fit = _height / tall;
          if (fit < _FitDown.least) break;
        }
        if (!fits) {
          // As it is set at its own width, made smaller: it fits, a touch
          // narrower than its room.
          fit = _height / lay(width);
          fits = true;
        }
      } else if (lay(width / _FitDown.least) * _FitDown.least <= _height) {
        fit = _FitDown.least;
        fits = true;
      }
      if (fits) {
        _scale = fit;
      } else {
        lay(width);
      }
    }
    size = constraints.constrain(Size(width, child.size.height * _scale));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? child = this.child;
    if (child == null) return;
    if (_scale == 1) {
      layer = null;
      context.paintChild(child, offset);
      return;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      _transform,
      (context, offset) => context.paintChild(child, offset),
      oldLayer: layer as TransformLayer?,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final RenderBox? child = this.child;
    if (child == null) return false;
    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_transform);
  }
}

/// Every feature, one under the other: its mark in a colour of the
/// headline's, its name, and its line, always whole.
class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.features});

  final List<_Feature> features;

  /// The marks' colours, by night and on paper: the headline's three, then
  /// three more of the cards' own, so no two features in a row share one.
  static const List<Color> _night = [
    Color(0xFF8B6CFF),
    Color(0xFFFFE14D),
    Color(0xFF2DE0D2),
    Color(0xFFFF5C9A),
    Color(0xFF5C8DFF),
    Color(0xFFFF9A3D),
    Color(0xFF4CDB7A),
  ];
  static const List<Color> _paper = [
    Color(0xFF6E3AFF),
    Color(0xFFC79200),
    Color(0xFF00A99C),
    Color(0xFFE0336F),
    Color(0xFF2B5CFF),
    Color(0xFFE06A00),
    Color(0xFF14A04A),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (int i, _Feature f) in features.indexed)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
          child: RiseIn.staggered(
            i,
            step: const Duration(milliseconds: 45),
            child: _row(context, f),
          ),
        ),
    ],
  );

  Widget _row(BuildContext context, _Feature f) {
    final l = context.l10n;
    final p = context.p;
    final List<Color> hues = p.isDark ? _night : _paper;
    final Color hue = hues[f.glyph.index % hues.length];
    final Color tile = Color.alphaBlend(
      hue.withValues(alpha: p.isDark ? 0.13 : 0.1),
      p.surface,
    );
    return Row(
      key: ValueKey('paywall-feature-${f.glyph.name}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tile,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size.square(22),
            painter: _GlyphPainter(f.glyph, hue, tile),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                // The name, and beside it whether it is new: on the line
                // below when the name is long.
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      f.title,
                      style: AppText.body(
                        size: 15,
                        weight: FontWeight.w700,
                        height: 1.22,
                        color: p.ink,
                      ),
                    ),
                    if (f.fresh)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: hue.withValues(alpha: 0.7)),
                        ),
                        child: Text(
                          l.perkNew,
                          style: AppText.label(
                            size: 9,
                            weight: FontWeight.w800,
                            spacing: 1,
                            height: 1.1,
                            color: hue,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                f.sub,
                style: AppText.body(
                  size: 13.5,
                  height: 1.3,
                  color: p.ink.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A feature's mark.
enum _Glyph { ask, coach, five, books, gap, read }

/// The marks, drawn at 22 by 22 in one weight of line, rounded at the ends
/// as the app's own marks are.
class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, this.colour, this.ground);

  final _Glyph glyph;
  final Color colour;

  /// The tile behind the mark, for what is in front to hide what is behind.
  final Color ground;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 22);
    final Paint line = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Paint fill = Paint()..color = colour;
    switch (glyph) {
      case _Glyph.ask:
        // A speech bubble, and a spark of an answer at its corner.
        final Path bubble = Path()
          ..moveTo(4, 4.5)
          ..lineTo(14, 4.5)
          ..arcToPoint(
            const Offset(16.5, 7),
            radius: const Radius.circular(2.5),
          )
          ..lineTo(16.5, 12.5)
          ..arcToPoint(const Offset(14, 15), radius: const Radius.circular(2.5))
          ..lineTo(8.5, 15)
          ..lineTo(5, 18)
          ..lineTo(5, 15)
          ..arcToPoint(
            const Offset(1.5, 12.5),
            radius: const Radius.circular(2.5),
          )
          ..lineTo(1.5, 7)
          ..arcToPoint(const Offset(4, 4.5), radius: const Radius.circular(2.5))
          ..close();
        canvas.drawPath(bubble, line);
        canvas.drawLine(const Offset(5.5, 9), const Offset(12.5, 9), line);
        canvas.drawLine(const Offset(5.5, 11.8), const Offset(10, 11.8), line);
        final Path spark = Path()
          ..moveTo(18.5, 0.8)
          ..quadraticBezierTo(18.9, 2.9, 21, 3.3)
          ..quadraticBezierTo(18.9, 3.7, 18.5, 5.8)
          ..quadraticBezierTo(18.1, 3.7, 16, 3.3)
          ..quadraticBezierTo(18.1, 2.9, 18.5, 0.8)
          ..close();
        canvas.drawPath(spark, fill);
      case _Glyph.coach:
        // A week's chart, going up.
        canvas.drawLine(const Offset(2, 19.5), const Offset(20, 19.5), line);
        final Path up = Path()
          ..moveTo(3.5, 15)
          ..lineTo(8, 10.5)
          ..lineTo(11.5, 13)
          ..lineTo(18, 5);
        canvas.drawPath(up, line);
        final Path head = Path()
          ..moveTo(13.8, 5)
          ..lineTo(18, 5)
          ..lineTo(18, 9.2);
        canvas.drawPath(head, line);
      case _Glyph.five:
        // Cards in a fan, the front one hiding the ones behind.
        final Paint behind = Paint()..color = ground;
        for (final (double a, Offset at) in const [
          (-0.42, Offset(7.4, 13.2)),
          (-0.14, Offset(10.2, 12.2)),
          (0.16, Offset(13.2, 12.4)),
        ]) {
          canvas.save();
          canvas.translate(at.dx, at.dy);
          canvas.rotate(a);
          final RRect card = RRect.fromLTRBR(
            -4.2,
            -7.2,
            4.2,
            6.6,
            const Radius.circular(1.8),
          );
          canvas.drawRRect(card, behind);
          canvas.drawRRect(card, line);
          canvas.restore();
        }
      case _Glyph.books:
        // A book, open.
        final Path left = Path()
          ..moveTo(11, 6)
          ..quadraticBezierTo(7, 3.8, 2, 4.5)
          ..lineTo(2, 17)
          ..quadraticBezierTo(7, 16.3, 11, 18.5);
        final Path right = Path()
          ..moveTo(11, 6)
          ..quadraticBezierTo(15, 3.8, 20, 4.5)
          ..lineTo(20, 17)
          ..quadraticBezierTo(15, 16.3, 11, 18.5);
        canvas.drawPath(left, line);
        canvas.drawPath(right, line);
        canvas.drawLine(const Offset(11, 6), const Offset(11, 18.5), line);
      case _Glyph.gap:
        // A chart: how sure, and how right, coming together at its end.
        final Path axis = Path()
          ..moveTo(2.5, 2.5)
          ..lineTo(2.5, 19.5)
          ..lineTo(20, 19.5);
        canvas.drawPath(axis, line);
        final Path sure = Path()
          ..moveTo(5.5, 5.5)
          ..quadraticBezierTo(12, 6.5, 18.5, 11);
        final Path right = Path()
          ..moveTo(5.5, 16)
          ..quadraticBezierTo(12, 15, 18.5, 12);
        canvas.drawPath(sure, line);
        canvas.drawPath(right, line);
        canvas.drawCircle(const Offset(18.5, 11.5), 2.1, fill);
      case _Glyph.read:
        // A clock, turned back.
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(11.5, 11.5), radius: 8),
          -2.6,
          5.0,
          false,
          line,
        );
        final Path tip = Path()
          ..moveTo(2.2, 4.8)
          ..lineTo(4.6, 7.9)
          ..lineTo(8.3, 6.7);
        canvas.drawPath(tip, line);
        final Path hands = Path()
          ..moveTo(11.5, 7.5)
          ..lineTo(11.5, 11.8)
          ..lineTo(14.6, 13.6);
        canvas.drawPath(hands, line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.colour != colour || old.ground != ground;
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
