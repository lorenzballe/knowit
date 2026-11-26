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

/// Looks the developer tools let a phone try on, so the owner can compare
/// on his own phone what only pictures showed him before: the finished day
/// with no row over its card, and the profile's other tops. Changed from
/// the debug section at the foot of the profile, kept on the phone, and
/// listened to where each is drawn, so a change shows at once.
///
/// Read only while the tools are on ([debugToolsOn]): a look kept by a
/// TestFlight build is still on the phone when the App Store build is
/// installed over it, and there it is never read.
abstract final class DebugLooks {
  static const String _kNoTopRow = 'knowit.debug.todayNoTopRow';
  static const String _kProfileTop = 'knowit.debug.profileTop';

  /// The finished day with no row over its shelf, as kept.
  static final ValueNotifier<bool> noTopRow = ValueNotifier<bool>(false);

  /// The profile's top, as kept.
  static final ValueNotifier<ProfileTopPick> profileTop =
      ValueNotifier<ProfileTopPick>(ProfileTopPick.auto);

  /// Whether the finished day goes without its top row in this run.
  static bool get todayWithoutTopRow => debugToolsOn && noTopRow.value;

  /// The profile's top as picked for this run: the plan's own, unless the
  /// tools are on and another was picked.
  static ProfileTopPick get profileTopPicked =>
      debugToolsOn ? profileTop.value : ProfileTopPick.auto;

  /// Reads what this phone keeps. Nothing kept is the app as it ships.
  static void load(SharedPreferences prefs) {
    noTopRow.value = prefs.getBool(_kNoTopRow) ?? false;
    profileTop.value =
        ProfileTopPick.values.asNameMap()[prefs.getString(_kProfileTop)] ??
        ProfileTopPick.auto;
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

  /// Writes the looks back once the profile's wipe has cleared the phone:
  /// they belong to the phone being tried, as the experiment's draws do,
  /// not to the reader the wipe forgets.
  static Future<void> keep(SharedPreferences prefs) async {
    if (noTopRow.value) await prefs.setBool(_kNoTopRow, true);
    if (profileTop.value != ProfileTopPick.auto) {
      await prefs.setString(_kProfileTop, profileTop.value.name);
    }
  }

  /// The app as it ships, for a test that changed either.
  @visibleForTesting
  static void reset() {
    noTopRow.value = false;
    profileTop.value = ProfileTopPick.auto;
  }
}
