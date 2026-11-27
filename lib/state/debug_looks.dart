import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../debug_flags.dart';

/// Which top the profile opens on, as the developer tools pick it: the
/// plan's own, or one of the three by the letter the owner knows it by
/// (lib/widgets/profile_top.dart).
enum ProfileTopPick {
  /// The plan's own: A on the free plan, C on Astute+.
  auto,

  /// The score.
  a,

  /// The week.
  b,

  /// The board.
  c,
}

/// Which paywall the developer tools put on screen, by the letter the owner
/// knows it by (lib/screens/paywall_looks.dart): A as it ships, or one of
/// the three prototypes.
enum PaywallLook {
  /// The paywall as it ships.
  a,

  /// A, with the product in it: real cards in place of the drawn marks, the
  /// free days as the days they go by, and the plans.
  b,

  /// B, opening on what the reader said they want and the subjects they
  /// chose.
  c,

  /// B in two steps: what Astute+ is, then the plans over it.
  d,
}

/// Looks the developer tools let a phone try on, so the owner can compare
/// on his own phone what only pictures showed him before: the finished day
/// with no row over its card, the profile's other tops, and the paywall's
/// prototypes. Changed from the debug section at the foot of the profile,
/// kept on the phone, and listened to where each is drawn, so a change
/// shows at once.
///
/// Read only while the tools are on ([debugToolsOn]): a look kept by a
/// TestFlight build is still on the phone when the App Store build is
/// installed over it, and there it is never read.
abstract final class DebugLooks {
  static const String _kNoTopRow = 'knowit.debug.todayNoTopRow';
  static const String _kProfileTop = 'knowit.debug.profileTop';
  static const String _kPaywall = 'knowit.debug.paywallLook';

  /// The finished day with no row over its shelf, as kept.
  static final ValueNotifier<bool> noTopRow = ValueNotifier<bool>(false);

  /// The profile's top, as kept.
  static final ValueNotifier<ProfileTopPick> profileTop =
      ValueNotifier<ProfileTopPick>(ProfileTopPick.auto);

  /// The paywall, as kept.
  static final ValueNotifier<PaywallLook> paywall = ValueNotifier<PaywallLook>(
    PaywallLook.a,
  );

  /// Whether the finished day goes without its top row in this run.
  static bool get todayWithoutTopRow => debugToolsOn && noTopRow.value;

  /// The profile's top as picked for this run: the plan's own, unless the
  /// tools are on and another was picked.
  static ProfileTopPick get profileTopPicked =>
      debugToolsOn ? profileTop.value : ProfileTopPick.auto;

  /// The paywall as picked for this run: A, as it ships, unless the tools
  /// are on and a prototype was picked.
  static PaywallLook get paywallPicked =>
      debugToolsOn ? paywall.value : PaywallLook.a;

  /// Reads what this phone keeps. Nothing kept is the app as it ships.
  static void load(SharedPreferences prefs) {
    noTopRow.value = prefs.getBool(_kNoTopRow) ?? false;
    profileTop.value =
        ProfileTopPick.values.asNameMap()[prefs.getString(_kProfileTop)] ??
        ProfileTopPick.auto;
    paywall.value =
        PaywallLook.values.asNameMap()[prefs.getString(_kPaywall)] ??
        PaywallLook.a;
  }

  /// Turns the finished day's top row off, or back on, and keeps it so.
  static Future<void> setNoTopRow(bool on) async {
    noTopRow.value = on;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNoTopRow, on);
  }

  /// Picks the profile's top, and keeps it so.
  static Future<void> setProfileTop(ProfileTopPick pick) async {
    profileTop.value = pick;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileTop, pick.name);
  }

  /// Picks the paywall, and keeps it so.
  static Future<void> setPaywall(PaywallLook look) async {
    paywall.value = look;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPaywall, look.name);
  }

  /// Writes the looks back once the profile's wipe has cleared the phone:
  /// they belong to the phone being tried, as the experiment's draws do,
  /// not to the reader the wipe forgets.
  static Future<void> keep(SharedPreferences prefs) async {
    if (noTopRow.value) await prefs.setBool(_kNoTopRow, true);
    if (profileTop.value != ProfileTopPick.auto) {
      await prefs.setString(_kProfileTop, profileTop.value.name);
    }
    if (paywall.value != PaywallLook.a) {
      await prefs.setString(_kPaywall, paywall.value.name);
    }
  }

  /// The app as it ships, for a test that changed any of them.
  @visibleForTesting
  static void reset() {
    noTopRow.value = false;
    profileTop.value = ProfileTopPick.auto;
    paywall.value = PaywallLook.a;
  }
}
