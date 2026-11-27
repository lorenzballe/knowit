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

/// What to learn, three other ways, as the developer tools try them beside
/// the one that ships (lib/widgets/learn_looks.dart): the owner did not
/// believe in twelve skills, each with a score, a mark on the cards and a
/// chapter of Your journey, and asked for it to be thought through again.
enum LearnLook {
  /// As it ships: the skills picked on What to learn, a score with no top
  /// in each, their mark on the cards, Your training at the head of Your
  /// journey and a box on the profile.
  today,

  /// A. The Astute score alone: no skills anywhere the reader looks, no
  /// picker, no marks, no scores but the one.
  score,

  /// B. One aim, asked once at the end of the first run and changed from
  /// the profile: where the reader wants to be sharper, one of the six
  /// areas the cards already name on their backs, in words and counts, with
  /// a shelf of it on Explore every day.
  aim,

  /// C. Measured, not picked: nothing to choose, the skills read from the
  /// reader's answers as a profile in Your journey, strongest first, in
  /// right answers out of answers given, with the weakest to practise; on
  /// the free plan the strongest only, the rest with Astute+.
  profile,
}

/// Looks the developer tools let a phone try on, so the owner can compare
/// on his own phone what only pictures showed him before: the finished day
/// with no row over its card, the profile's other tops, and What to learn
/// three other ways. Changed from the debug section at the foot of the
/// profile, kept on the phone, and listened to where each is drawn, so a
/// change shows at once.
///
/// Read only while the tools are on ([debugToolsOn]): a look kept by a
/// TestFlight build is still on the phone when the App Store build is
/// installed over it, and there it is never read.
abstract final class DebugLooks {
  static const String _kNoTopRow = 'knowit.debug.todayNoTopRow';
  static const String _kProfileTop = 'knowit.debug.profileTop';
  static const String _kLearn = 'knowit.debug.learn';

  /// The finished day with no row over its shelf, as kept.
  static final ValueNotifier<bool> noTopRow = ValueNotifier<bool>(false);

  /// The profile's top, as kept.
  static final ValueNotifier<ProfileTopPick> profileTop =
      ValueNotifier<ProfileTopPick>(ProfileTopPick.auto);

  /// What to learn's look, as kept.
  static final ValueNotifier<LearnLook> learn = ValueNotifier<LearnLook>(
    LearnLook.today,
  );

  /// Whether the finished day goes without its top row in this run.
  static bool get todayWithoutTopRow => debugToolsOn && noTopRow.value;

  /// The profile's top as picked for this run: the plan's own, unless the
  /// tools are on and another was picked.
  static ProfileTopPick get profileTopPicked =>
      debugToolsOn ? profileTop.value : ProfileTopPick.auto;

  /// What to learn's look for this run: as it ships, unless the tools are
  /// on and another was picked.
  static LearnLook get learnPicked =>
      debugToolsOn ? learn.value : LearnLook.today;

  /// Reads what this phone keeps. Nothing kept is the app as it ships.
  static void load(SharedPreferences prefs) {
    noTopRow.value = prefs.getBool(_kNoTopRow) ?? false;
    profileTop.value =
        ProfileTopPick.values.asNameMap()[prefs.getString(_kProfileTop)] ??
        ProfileTopPick.auto;
    learn.value =
        LearnLook.values.asNameMap()[prefs.getString(_kLearn)] ??
        LearnLook.today;
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

  /// Picks What to learn's look, and keeps it so.
  static Future<void> setLearn(LearnLook look) async {
    learn.value = look;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLearn, look.name);
  }

  /// Writes the looks back once the profile's wipe has cleared the phone:
  /// they belong to the phone being tried, as the experiment's draws do,
  /// not to the reader the wipe forgets.
  static Future<void> keep(SharedPreferences prefs) async {
    if (noTopRow.value) await prefs.setBool(_kNoTopRow, true);
    if (profileTop.value != ProfileTopPick.auto) {
      await prefs.setString(_kProfileTop, profileTop.value.name);
    }
    if (learn.value != LearnLook.today) {
      await prefs.setString(_kLearn, learn.value.name);
    }
  }

  /// The app as it ships, for a test that changed any of them.
  @visibleForTesting
  static void reset() {
    noTopRow.value = false;
    profileTop.value = ProfileTopPick.auto;
    learn.value = LearnLook.today;
  }
}
