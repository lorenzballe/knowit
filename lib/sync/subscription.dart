import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// The one entitlement Astuto sells. Everything gated asks this by name.
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
  Offering? _offering;

  /// True once the store has answered at least once. Until then the app
  /// should not claim the reader has nothing.
  bool get ready => _ready;

  bool get isPlus => _isPlus;

  /// What is on sale, or null when the store has not answered — in which
  /// case the paywall falls back to the prices written into the app.
  Offering? get offering => _offering;

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

  /// Starts the SDK, tied to the account so the entitlement follows the
  /// reader rather than the phone. Never throws: a store that will not answer
  /// leaves a reader on the free plan, not in front of a crash.
  Future<void> start({required String? accountId}) async {
    if (_key.isEmpty) return;
    try {
      await Purchases.setLogLevel(LogLevel.warn);
      await Purchases.configure(
        PurchasesConfiguration(_key)..appUserID = accountId,
      );
      Purchases.addCustomerInfoUpdateListener(_apply);
      _apply(await Purchases.getCustomerInfo());
      await _loadOffering();
    } catch (error) {
      debugPrint('RevenueCat did not start: $error');
    }
  }

  /// Follows the reader when they sign in and the account id changes.
  Future<void> switchTo(String? accountId) async {
    if (_key.isEmpty || accountId == null) return;
    try {
      final result = await Purchases.logIn(accountId);
      _apply(result.customerInfo);
    } catch (error) {
      debugPrint('Could not move the subscription to the account: $error');
    }
  }

  Future<void> _loadOffering() async {
    try {
      _offering = (await Purchases.getOfferings()).current;
      notifyListeners();
    } catch (error) {
      debugPrint('Could not read the offerings: $error');
    }
  }

  void _apply(CustomerInfo info) {
    _ready = true;
    final bool active = info.entitlements.active.containsKey(kPlusEntitlement);
    if (active == _isPlus) return;
    _isPlus = active;
    notifyListeners();
  }

  /// Buys a package. Returns whether the reader came away entitled — backing
  /// out of the store sheet is not a failure and is reported as false with
  /// nothing said.
  Future<PurchaseOutcome> buy(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _apply(result.customerInfo);
      return _isPlus ? PurchaseOutcome.bought : PurchaseOutcome.failed;
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      debugPrint('Purchase failed: $code');
      return PurchaseOutcome.failed;
    } catch (error) {
      debugPrint('Purchase failed: $error');
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
    } catch (error) {
      debugPrint('Could not open the customer centre: $error');
    }
  }

  /// Apple requires a way to get back what you already paid for, and a reader
  /// on a new phone needs it before they will believe the first one.
  Future<bool> restore() async {
    try {
      _apply(await Purchases.restorePurchases());
      return _isPlus;
    } catch (error) {
      debugPrint('Could not restore: $error');
      return false;
    }
  }
}

enum PurchaseOutcome { bought, cancelled, failed }
