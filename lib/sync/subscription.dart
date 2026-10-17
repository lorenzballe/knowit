import 'dart:async' show Timer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics.dart';
import '../models/trial.dart';
import 'review_access.dart';

/// The one entitlement Astute sells. Everything gated asks this by name.
///
/// Configurable at build time because the name lives in RevenueCat, not here,
/// and the two have to agree exactly — an entitlement the app asks for under
/// the wrong name is a subscriber the app never sees. It also matters when an
/// account holds more than one app: entitlements are scoped to a RevenueCat
/// *project*, so two apps sharing one project would share this name too, and
/// each should have a project of its own.
const String kPlusEntitlement = String.fromEnvironment(
  'REVENUECAT_ENTITLEMENT',
  defaultValue: 'astuto_pro',
);

/// The public RevenueCat keys, one per store.
///
/// Public on purpose — they identify the app to RevenueCat and grant nothing,
/// which is why they ship inside the binary. Passed in at build time so
/// rotating one is not a code change:
///
///     flutter build ipa    --dart-define=REVENUECAT_IOS_KEY=appl_xxx
///     flutter build appbundle --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx
///
/// A key beginning `test_` is RevenueCat's test mode: purchases are simulated
/// and no store is involved. It is the right key for trying the flow and the
/// wrong one for taking money.
const String kRevenueCatIosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');

const String kRevenueCatAndroidKey = String.fromEnvironment(
  'REVENUECAT_ANDROID_KEY',
  defaultValue: 'goog_YaeEfHnlTfzLXeDDjfmQcgCVpKl',
);

/// Package identifiers, tried in order.
///
/// RevenueCat's own accessors only find packages built from its standard
/// types ($rc_annual, $rc_monthly). An offering whose packages were named by
/// hand — "yearly", "monthly" — leaves those null, and the paywall would show
/// its written-in prices while quietly refusing to sell anything. So both are
/// tried.
const List<String> kYearlyPackageIds = ['\$rc_annual', 'yearly', 'annual'];
const List<String> kMonthlyPackageIds = ['\$rc_monthly', 'monthly'];

/// The free trial the yearly plan is sold with: two weeks, set in App Store
/// Connect and Play Console as the year's introductory offer.
///
/// Said only by a debug build with no store behind it (see
/// [Subscription.previewWithoutStore]): everywhere else the days are the
/// store's own, so a trial changed in the store is said right without a new
/// build, and one the store has not been set to give — or has not said it
/// will give — is never promised.
const int kTrialDays = 14;

/// Where the store stands, as the paywall shows it.
enum StoreAnswer {
  /// The plans are on sale, at the store's own prices.
  ready,

  /// Still asking: at launch, or again after a try that failed.
  asking,

  /// No answer: no network, a store that is not set up, a build without a
  /// key. The paywall says so and offers to try again; it never stands a
  /// price written into the app in for the store's.
  unreachable,
}

/// How long the app waits between tries when the store has not answered:
/// soon, then less and less often, and then only when asked — the paywall
/// opening, Try again, the app coming back to the screen.
const List<Duration> kStoreRetries = [
  Duration(seconds: 3),
  Duration(seconds: 10),
  Duration(seconds: 30),
  Duration(minutes: 2),
];

/// The days an introductory offer lasts, from the store's own period.
int? daysOfPeriod(PeriodUnit unit, int units) => switch (unit) {
  PeriodUnit.day => units,
  PeriodUnit.week => 7 * units,
  PeriodUnit.month => 30 * units,
  PeriodUnit.year => 365 * units,
  PeriodUnit.unknown => null,
};

/// How many days free a package starts with, or null when it charges today.
int? freeDaysOf(Package? package) {
  final IntroductoryPrice? intro = package?.storeProduct.introductoryPrice;
  if (intro == null || intro.price != 0) return null;
  return daysOfPeriod(intro.periodUnit, intro.periodNumberOfUnits);
}

/// Whether the reader has actually paid, and what it would cost if not.
///
/// The plan used to be a bool the app wrote to itself, which is a wish rather
/// than an entitlement: it survived a reinstall on the same phone and nothing
/// else, and it could not be restored on a new one. This asks the store,
/// through RevenueCat, and believes only the answer.
class Subscription extends ChangeNotifier {
  Subscription({this.keyOverride});

  /// The app's one connection to the store.
  ///
  /// A singleton because RevenueCat's own API is static: there cannot be two,
  /// and threading an injectable one through six screens would pretend
  /// otherwise. Tests replace it rather than receive it.
  static Subscription instance = Subscription();

  @visibleForTesting
  static void useForTest(Subscription value) => instance = value;

  /// Lets a test run the whole thing without a key or a store.
  final String? keyOverride;

  bool _ready = false;
  bool _isPlus = false;
  bool _reviewAccess = false;
  Offering? _offering;

  /// What Apple says about the reader and the year's introductory offer.
  /// Apple gives it once per reader, and a product's offer is the same for
  /// everyone who looks at it, so on an iPhone it has to be asked. Google
  /// Play only hands over the offers the reader can still have.
  IntroEligibilityStatus? _yearlyEligibility;

  /// How many days free the yearly plan starts with for this reader, or
  /// null when it starts with none for them, or when the store has not said:
  /// the store's introductory offer at no charge, unless the store says this
  /// reader has had it. A debug build with no store says the plan as sold.
  int? get trialDays {
    final Package? year = yearly;
    if (year == null) return previewWithoutStore ? kTrialDays : null;
    final int? days = freeDaysOf(year);
    if (days == null) return null;
    return switch (_yearlyEligibility) {
      IntroEligibilityStatus.introEligibilityStatusIneligible ||
      IntroEligibilityStatus.introEligibilityStatusNoIntroOfferExists => null,
      _ => days,
    };
  }

  /// Stands in for the store's answers, for the tests: what is on sale, and
  /// what Apple says about the reader and the year's free days.
  @visibleForTesting
  void answerForTest({
    Offering? offering,
    IntroEligibilityStatus? yearlyEligibility,
  }) {
    _offering = offering;
    _yearlyEligibility = yearlyEligibility;
    notifyListeners();
  }

  /// Stands in for what the store holds for the reader, for the tests: the
  /// Astute+ entitlement as RevenueCat hands it over, or none, as an answer.
  @visibleForTesting
  void holdForTest(EntitlementInfo? plus) {
    _ready = true;
    _plus = plus;
    _isPlus = plus?.isActive ?? false;
    notifyListeners();
  }

  /// The Astute+ entitlement as the store last described it, active or not.
  EntitlementInfo? _plus;

  /// The free trial the reader is in, while the store has it set to turn
  /// into a paid year; null otherwise — no trial, one cancelled (it runs to
  /// its end and charges nothing), or one already turned into the year.
  ///
  /// The price is the year's, and only when the trial is the year's own: the
  /// one plan sold with free days, and the one the warning before the charge
  /// names. Read again whenever the offering arrives, which can be after the
  /// entitlement on a slow launch.
  FreeTrial? get trial {
    final EntitlementInfo? plus = _plus;
    if (plus == null || !plus.isActive || !plus.willRenew) return null;
    if (plus.periodType != PeriodType.trial) return null;
    final DateTime? ends = DateTime.tryParse(plus.expirationDate ?? '');
    if (ends == null) return null;
    return FreeTrial(endsAt: ends.toLocal(), price: _yearPriceFor(plus));
  }

  /// The year's price, if [plus] was unlocked by the year on sale. A Google
  /// Play product is named with its base plan after a colon, so both ways of
  /// naming it are tried.
  String? _yearPriceFor(EntitlementInfo plus) {
    final StoreProduct? year = yearly?.storeProduct;
    if (year == null) return null;
    final String? basePlan = plus.productPlanIdentifier;
    final bool same =
        year.identifier == plus.productIdentifier ||
        (basePlan != null &&
            year.identifier == '${plus.productIdentifier}:$basePlan');
    return same ? year.priceString : null;
  }

  /// True once the store has answered at least once. Until then the app
  /// should not claim the reader has nothing.
  bool get ready => _ready;

  /// Astute+ as the store holds it, or as a reviewer's code opened it.
  bool get isPlus => _isPlus || _reviewAccess;

  /// True on the Android phone a Google Play reviewer unlocked with the code
  /// Play Console gave them (see review_access.dart). Nobody else has it.
  bool get reviewAccess => _reviewAccess;

  /// The hash the reviewers' code is checked against; a test brings its own.
  @visibleForTesting
  String reviewCodeHash = kReviewCodeSha256;

  /// Turns Astute+ on for this phone when [code] is the reviewers' code.
  ///
  /// Kept on the phone, so a reviewer who comes back finds it still open.
  /// Nothing is bought and the store is not told: this is not a purchase.
  Future<bool> redeemReviewCode(String code) async {
    if (!reviewCodeOffered) return false;
    final bool right = reviewCodeMatches(code, hash: reviewCodeHash);
    Analytics.capture(right ? 'review access granted' : 'review code refused');
    if (!right) return false;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kReviewAccessPref, true);
    } catch (_) {
      // Still open for this session; it is only the relaunch that forgets.
    }
    _reviewAccess = true;
    notifyListeners();
    return true;
  }

  /// Picks a reviewer's unlock back up after a relaunch.
  Future<void> _loadReviewAccess() async {
    if (!reviewCodeOffered || _reviewAccess) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(kReviewAccessPref) ?? false) {
        _reviewAccess = true;
        notifyListeners();
      }
    } catch (_) {
      // No preferences, no reviewer: the free plan, as for anyone.
    }
  }

  /// What is on sale, or null when the store has not answered — in which
  /// case the paywall says so, and offers to try again.
  Offering? get offering => _offering;

  /// Whether this build has a store to ask: a phone, with its store's key
  /// built in. The web app and a fork have none.
  bool get hasStore => _key.isNotEmpty;

  /// Whether a debug build stands the plans as sold in for the store's while
  /// the store has not answered — and lets the buy button unlock Astute+ on
  /// the phone. It is the only way to see the paywall, and the screens
  /// behind it, on a simulator or under a test. A release build never does:
  /// it says the store could not be reached. A test that wants to see the
  /// release build's paywall turns this off; nothing else sets it.
  static bool previewWithoutStore = kDebugMode;

  bool _asking = false;
  int _tries = 0;
  Timer? _retry;

  /// Where the store stands: on sale, still being asked, or not answering.
  StoreAnswer get answer {
    if (yearly != null || monthly != null) return StoreAnswer.ready;
    if (_asking || (hasStore && !_ready && _tries == 0)) {
      return StoreAnswer.asking;
    }
    return StoreAnswer.unreachable;
  }

  /// Asks the store again now — the paywall opening, Try again, the app
  /// coming back to the screen — unless it has answered or is being asked.
  /// The tries counted since the last answer start over, so the waits
  /// between them are short again.
  Future<void> reloadOffering() async {
    if (!hasStore || !_configured) return;
    if (answer == StoreAnswer.ready || _asking) return;
    _retry?.cancel();
    _retry = null;
    _tries = 0;
    await _loadOffering();
  }

  /// Stands in for a store that is still being asked, or that did not
  /// answer, for the tests.
  @visibleForTesting
  void askingForTest(bool asking) {
    _asking = asking;
    _tries = asking ? 0 : 1;
    notifyListeners();
  }

  /// The yearly package, however the offering happens to name it.
  Package? get yearly => _packageFrom(kYearlyPackageIds, _offering?.annual);

  Package? get monthly => _packageFrom(kMonthlyPackageIds, _offering?.monthly);

  Package? _packageFrom(List<String> identifiers, Package? standard) {
    if (standard != null) return standard;
    final Offering? offering = _offering;
    if (offering == null) return null;
    for (final String id in identifiers) {
      for (final Package package in offering.availablePackages) {
        if (package.identifier == id) return package;
      }
    }
    return null;
  }

  /// Each store has its own key, and giving one the other's is a
  /// configuration error that only shows up as "nothing is for sale".
  String get _key {
    if (keyOverride != null) return keyOverride!;
    if (kIsWeb) return '';
    return defaultTargetPlatform == TargetPlatform.android
        ? kRevenueCatAndroidKey
        : kRevenueCatIosKey;
  }

  bool _configured = false;
  final Stopwatch _sinceStart = Stopwatch();

  /// Starts the SDK, at launch and on its own: tied to the account when the
  /// phone already has one, and to a customer of the store's own when it
  /// does not yet, until [switchTo] names it. Buying used to wait for the
  /// Firebase sign-in and the backup behind it, so a phone whose account
  /// was slow to come up could not buy at all. Never throws: a store that
  /// will not answer leaves a reader on the free plan, not in front of a
  /// crash.
  Future<void> start({required String? accountId}) async {
    await _loadReviewAccess();
    if (_key.isEmpty) return;
    _sinceStart.start();
    try {
      await Purchases.setLogLevel(LogLevel.warn);
      await Purchases.configure(
        PurchasesConfiguration(_key)..appUserID = accountId,
      );
      _configured = true;
      Purchases.addCustomerInfoUpdateListener(_apply);
      _apply(await Purchases.getCustomerInfo());
    } catch (error, stack) {
      debugPrint('RevenueCat did not start: $error');
      Analytics.error(error, stack, where: 'store start');
    }
    // What is on sale is asked for even when the customer could not be
    // read: the two fail apart, and a paywall can sell without the other.
    if (_configured) await _loadOffering();
  }

  /// Follows the reader when they sign in and the account id changes, and
  /// once the phone's own account has come up after the store did. Nothing
  /// to do when the store already knows the reader by that id.
  Future<void> switchTo(String? accountId) async {
    if (_key.isEmpty || accountId == null || !_configured) return;
    try {
      if (await Purchases.appUserID == accountId) return;
      final result = await Purchases.logIn(accountId);
      _apply(result.customerInfo);
    } catch (error) {
      debugPrint('Could not move the subscription to the account: $error');
    }
  }

  /// Lets go of the account when it is deleted: on this phone the store
  /// goes back to a customer of its own. What was bought stays Apple's, and
  /// comes back with Restore on an account that owns it.
  Future<void> logOut() async {
    if (_key.isEmpty) return;
    try {
      _apply(await Purchases.logOut());
    } catch (error) {
      // Already anonymous, or no store: either way nothing is held for the
      // deleted account.
      debugPrint('Could not log out of the store: $error');
    }
  }

  /// Asks what is on sale, and says what came back. A try that finds
  /// nothing on sale — no network, a store not set up yet — is tried again
  /// after a wait from [kStoreRetries], longer each time, and then only
  /// when [reloadOffering] asks.
  Future<void> _loadOffering() async {
    _asking = true;
    notifyListeners();
    Object? failure;
    try {
      _offering = (await Purchases.getOfferings()).current;
    } catch (error, stack) {
      failure = error;
      debugPrint('Could not read the offerings: $error');
      Analytics.error(error, stack, where: 'store offerings');
    }
    _asking = false;
    _tries += 1;
    final bool onSale = yearly != null || monthly != null;
    if (onSale) await _checkTrialEligibility();
    // What the store put on sale, as it priced it, each time it is asked:
    // a plan missing here is a paywall that cannot sell.
    final StoreProduct? year = yearly?.storeProduct;
    final StoreProduct? month = monthly?.storeProduct;
    Analytics.capture('store answered', {
      'ms': _sinceStart.elapsedMilliseconds,
      'try': _tries,
      'offering': _offering?.identifier,
      'yearly_product': year?.identifier,
      'yearly_price': year?.price,
      'yearly_trial': year?.introductoryPrice?.period,
      'monthly_product': month?.identifier,
      'monthly_price': month?.price,
      'currency': year?.currencyCode ?? month?.currencyCode,
      'is_plus': _isPlus,
      'error': failure == null ? null : Analytics.short(failure),
    });
    notifyListeners();
    if (onSale) {
      _tries = 0;
      return;
    }
    if (_tries <= kStoreRetries.length) {
      _retry?.cancel();
      _retry = Timer(kStoreRetries[_tries - 1], () {
        _retry = null;
        if (answer != StoreAnswer.ready && !_asking) _loadOffering();
      });
    }
  }

  /// Asks Apple whether the reader can still have the year's free days:
  /// at launch, and whenever the plan changes, because a trial started or
  /// ended is exactly what turns the answer.
  Future<void> _checkTrialEligibility() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    final String? id = yearly?.storeProduct.identifier;
    if (id == null) return;
    try {
      final Map<String, IntroEligibility> said =
          await Purchases.checkTrialOrIntroductoryPriceEligibility([id]);
      final IntroEligibilityStatus? status = said[id]?.status;
      if (status == _yearlyEligibility) return;
      _yearlyEligibility = status;
      notifyListeners();
    } catch (error) {
      // Unknown, which says the offer as the store has it: Apple itself
      // shows the real terms on its sheet before anything is charged.
      debugPrint('Could not ask about the free trial: $error');
    }
  }

  void _apply(CustomerInfo info) {
    _ready = true;
    final EntitlementInfo? plus = info.entitlements.all[kPlusEntitlement];
    final bool active = info.entitlements.active.containsKey(kPlusEntitlement);
    _noteEntitlement(plus, active);
    // A trial moves without the plan moving: cancelled, it stays active to
    // its end and only stops renewing; turned into the year, it stays active
    // too. Either is something the app has to hear, to warn before a charge
    // or to stop warning about one that will not come.
    final FreeTrial? trialBefore = trial;
    _plus = plus;
    if (active == _isPlus) {
      if (trial != trialBefore) notifyListeners();
      return;
    }
    _isPlus = active;
    notifyListeners();
    _checkTrialEligibility();
  }

  String? _entitlementSaid;

  /// What the store said about the reader, as if it had just said it.
  @visibleForTesting
  void noteForTest(EntitlementInfo? plus, {required bool active}) =>
      _noteEntitlement(plus, active);

  /// The plan as every event and the reader's profile carry it:
  ///
  /// - `plan`: `free`, or the plan held — `year`, `month`, or `plus` for a
  ///   product the app cannot place;
  /// - `is_trial`: true while a free trial is running, cancelled or not;
  /// - `plan_period`: the store's word for the period, as RevenueCat names
  ///   it — `trial`, `intro`, `normal` or `prepaid` — or `none` with no
  ///   entitlement.
  static Map<String, Object> planFacts(
    EntitlementInfo? plus, {
    required bool active,
  }) {
    final String product = (plus?.productIdentifier ?? '').toLowerCase();
    return {
      'plan': !active
          ? 'free'
          : product.contains('year') || product.contains('annual')
          ? 'year'
          : product.contains('month')
          ? 'month'
          : 'plus',
      'is_trial': active && plus?.periodType == PeriodType.trial,
      'plan_period': active ? (plus?.periodType.name ?? 'unknown') : 'none',
    };
  }

  /// Says what the store holds for the reader whenever any of it moves: a
  /// trial started, turned into a paid year, set not to renew, hit a billing
  /// problem, or ran out. Those are the moments a subscription business is
  /// made of, and only the store sees them.
  void _noteEntitlement(EntitlementInfo? plus, bool active) {
    final String state = [
      active,
      plus?.productIdentifier,
      plus?.periodType.name,
      plus?.willRenew,
      plus?.billingIssueDetectedAt,
    ].join('|');
    if (state == _entitlementSaid) return;
    final bool first = _entitlementSaid == null;
    _entitlementSaid = state;
    final Map<String, Object> plan = planFacts(plus, active: active);
    for (final MapEntry<String, Object> e in plan.entries) {
      Analytics.register(e.key, e.value);
    }
    // On the profile as well, at once: a cohort — everyone in a trial — can
    // only be made of what a profile says, and a trial that started is
    // worth knowing before the app next leaves the screen. Written only
    // where it changed, so a launch that finds the plan as it was says
    // nothing.
    Analytics.person(set: plan, now: true);
    // A reader who never subscribed has nothing to report at launch.
    if (first && plus == null) return;
    Analytics.capture(first ? 'entitlement read' : 'entitlement changed', {
      'active': active,
      'product': plus?.productIdentifier,
      'period_type': plus?.periodType.name,
      'will_renew': plus?.willRenew,
      'store': plus?.store.name,
      'sandbox': plus?.isSandbox,
      'expires': plus?.expirationDate,
      'unsubscribed': plus?.unsubscribeDetectedAt != null,
      'billing_issue': plus?.billingIssueDetectedAt != null,
    });
  }

  /// Buys a package. Returns whether the reader came away entitled — backing
  /// out of the store sheet is not a failure and is reported as false with
  /// nothing said.
  Future<PurchaseOutcome> buy(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _apply(result.customerInfo);
      return _isPlus ? PurchaseOutcome.bought : PurchaseOutcome.failed;
    } on PlatformException catch (error, stack) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      // Ask to Buy, a bank that wants to approve it: not a failure, and not
      // a purchase yet. The store says when it goes through, and the
      // listener on the customer turns Astute+ on then.
      if (code == PurchasesErrorCode.paymentPendingError) {
        return PurchaseOutcome.pending;
      }
      debugPrint('Purchase failed: $code');
      Analytics.error(
        error,
        stack,
        where: 'purchase',
        properties: {
          'code': code.name,
          'product': package.storeProduct.identifier,
        },
      );
      return PurchaseOutcome.failed;
    } catch (error, stack) {
      debugPrint('Purchase failed: $error');
      Analytics.error(error, stack, where: 'purchase');
      return PurchaseOutcome.failed;
    }
  }

  /// RevenueCat's own screen for managing a subscription: cancelling,
  /// changing plan, asking for a refund, restoring.
  ///
  /// Worth using rather than building, because it is the part of a paywall
  /// nobody designs and everybody needs — and because the alternative is
  /// sending the reader to iOS Settings and hoping.
  ///
  /// The customer info is read again afterwards: someone who cancelled in
  /// there should not come back to a profile that still says they are on the
  /// plan.
  Future<void> presentCustomerCenter() async {
    if (_key.isEmpty) return;
    try {
      await RevenueCatUI.presentCustomerCenter();
      _apply(await Purchases.getCustomerInfo());
    } catch (error, stack) {
      debugPrint('Could not open the customer centre: $error');
      Analytics.error(error, stack, where: 'customer centre');
    }
  }

  /// Apple requires a way to get back what you already paid for, and a reader
  /// on a new phone needs it before they will believe the first one. It
  /// needs no offering, so it is there whether or not the plans have come.
  /// A store that cannot be reached is said as that, not as "nothing to
  /// restore".
  Future<RestoreOutcome> restore() async {
    if (_key.isEmpty || !_configured) return RestoreOutcome.unreachable;
    try {
      _apply(await Purchases.restorePurchases());
      return _isPlus ? RestoreOutcome.restored : RestoreOutcome.nothing;
    } catch (error, stack) {
      debugPrint('Could not restore: $error');
      Analytics.error(error, stack, where: 'restore');
      return RestoreOutcome.unreachable;
    }
  }

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }
}

/// How a purchase ended. [pending] is a payment waiting on someone else's
/// approval — Ask to Buy, a bank — which is neither bought nor failed.
enum PurchaseOutcome { bought, cancelled, pending, failed }

/// How a restore ended.
enum RestoreOutcome { restored, nothing, unreachable }
