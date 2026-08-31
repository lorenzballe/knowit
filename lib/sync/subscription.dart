import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

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
  defaultValue: 'plus',
);

/// The public RevenueCat key for the iOS app.
///
/// Public on purpose — it identifies the app to RevenueCat and grants
/// nothing. Passed in at build time so it is not a code change to rotate it:
///
///     flutter build ipa --dart-define=REVENUECAT_IOS_KEY=appl_xxx
const String kRevenueCatIosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');

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

  String get _key => keyOverride ?? kRevenueCatIosKey;

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
