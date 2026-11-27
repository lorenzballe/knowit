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

/// Where the finished day is sent from, as the developer tools pick it: the
/// four ways drawn for the owner, by the letter he knows each by
/// (lib/screens/today_done_view.dart, lib/widgets/day_moment.dart).
enum ShareDayPick {
  /// As it ships: "See again" and the day's share mark at the end of the
  /// row over the shelf.
  a,

  /// The share mark alone at the end of the row; the five again from
  /// Explore's "Your five from today".
  b,

  /// The day closed on a screen of its own, once, right after the five: its
  /// picture, the way to send it, and "Later". The shelf after it has the
  /// share mark alone, as in [b].
  c,

  /// The day as a card of its own after the five on the shelf, its picture
  /// and the way to send it; nothing at the end of the row.
  d,
}

/// Looks the developer tools let a phone try on, so the owner can compare
/// on his own phone what only pictures showed him before: the finished day
/// with no row over its card, the profile's other tops, and where the day
/// is sent from. Changed from the debug section at the foot of the profile,
/// kept on the phone, and listened to where each is drawn, so a change
/// shows at once.
///
/// Read only while the tools are on ([debugToolsOn]): a look kept by a
/// TestFlight build is still on the phone when the App Store build is
/// installed over it, and there it is never read.
abstract final class DebugLooks {
  static const String _kNoTopRow = 'knowit.debug.todayNoTopRow';
  static const String _kProfileTop = 'knowit.debug.profileTop';
  static const String _kShareDay = 'knowit.debug.shareDay';

  /// The finished day with no row over its shelf, as kept.
  static final ValueNotifier<bool> noTopRow = ValueNotifier<bool>(false);

  /// The profile's top, as kept.
  static final ValueNotifier<ProfileTopPick> profileTop =
      ValueNotifier<ProfileTopPick>(ProfileTopPick.auto);

  /// Where the finished day is sent from, as kept.
  static final ValueNotifier<ShareDayPick> shareDay =
      ValueNotifier<ShareDayPick>(ShareDayPick.a);

  /// Whether the finished day goes without its top row in this run.
  static bool get todayWithoutTopRow => debugToolsOn && noTopRow.value;

  /// The profile's top as picked for this run: the plan's own, unless the
  /// tools are on and another was picked.
  static ProfileTopPick get profileTopPicked =>
      debugToolsOn ? profileTop.value : ProfileTopPick.auto;

  /// Where the day is sent from in this run: as it ships, unless the tools
  /// are on and another way was picked.
  static ShareDayPick get shareDayPicked =>
      debugToolsOn ? shareDay.value : ShareDayPick.a;

  /// Reads what this phone keeps. Nothing kept is the app as it ships.
  static void load(SharedPreferences prefs) {
    noTopRow.value = prefs.getBool(_kNoTopRow) ?? false;
    profileTop.value =
        ProfileTopPick.values.asNameMap()[prefs.getString(_kProfileTop)] ??
        ProfileTopPick.auto;
    shareDay.value =
        ShareDayPick.values.asNameMap()[prefs.getString(_kShareDay)] ??
        ShareDayPick.a;
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

  /// Picks where the day is sent from, and keeps it so.
  static Future<void> setShareDay(ShareDayPick pick) async {
    shareDay.value = pick;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kShareDay, pick.name);
  }

  /// Writes the looks back once the profile's wipe has cleared the phone:
  /// they belong to the phone being tried, as the experiment's draws do,
  /// not to the reader the wipe forgets.
  static Future<void> keep(SharedPreferences prefs) async {
    if (noTopRow.value) await prefs.setBool(_kNoTopRow, true);
    if (profileTop.value != ProfileTopPick.auto) {
      await prefs.setString(_kProfileTop, profileTop.value.name);
    }
    if (shareDay.value != ShareDayPick.a) {
      await prefs.setString(_kShareDay, shareDay.value.name);
    }
  }

  /// The app as it ships, for a test that changed any of them.
  @visibleForTesting
  static void reset() {
    noTopRow.value = false;
    profileTop.value = ProfileTopPick.auto;
    shareDay.value = ShareDayPick.a;
  }
}
