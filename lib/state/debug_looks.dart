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

/// Which paywall the developer tools put on screen, by the letter the owner
/// knows it by (lib/screens/paywall_looks.dart). The owner chose C on 27
/// November 2026, and C ships ([DebugLooks.paywallShips]); the tools still
/// show the others.
enum PaywallLook {
  /// The paywall as it shipped until C was chosen.
  a,

  /// A, with the product in it: real cards in place of the drawn marks, the
  /// free days as the days they go by, and the plans.
  b,

  /// B, opening on what the reader said they want and the subjects they
  /// chose. The one that ships.
  c,

  /// B in two steps: what Astute+ is, then the plans over it.
  d,
}

/// The picture the day is sent as (lib/widgets/share_day.dart, the new ones
/// in lib/widgets/share_looks.dart), by the letter the owner knows it by.
/// He asked for it nicer, softly graded and coloured, and weighed three ways
/// of showing a card: its drawing whole, a small preview of it, or only its
/// subject's mark. C ships ([DebugLooks.sharePictureShips]); the tools show
/// A, the picture as it was, and B. Each keeps every question whole.
enum SharePictureLook {
  /// A. The picture as it shipped until November 2026: black, each card's
  /// drawing cut down to a square beside its question.
  a,

  /// B. The cards: the day's first drawn card large, the whole card, lit
  /// from behind by its colour; on the list the five cards whole in a row.
  b,

  /// C. Light: no drawing; black lit by the day's colours from its corners,
  /// each card its subject's mark on a disc of its colour. The one that
  /// ships.
  c,
}

/// How a hard card looks wherever it is read, as the developer tools pick
/// it (lib/widgets/hard_ring.dart): as today, in its subject's colour like
/// every card, or ringed, dark and ringed in its subject's colour with HARD
/// on it, as Explore's shelf of the hardest cards draws them.
enum HardCardLook {
  /// As the app ships: a hard card looks like any other.
  today,

  /// Dark, ringed in the subject's colour, the label in it, HARD on it.
  ringed,
}

/// What to learn, five other ways, as the developer tools try them beside
/// the one that ships (lib/widgets/learn_looks.dart): the owner did not
/// believe in twelve skills, each with a score, a mark on the cards and a
/// chapter of Your journey, and asked for it to be thought through again.
/// Where the reader wants to see more clearly, their aim, is now asked on
/// the profile in every look (lib/widgets/aim_picker.dart); the looks are
/// what becomes of the skills beside it.
enum LearnLook {
  /// As it ships: the skills picked on What to learn, a score with no top
  /// in each, their mark on the cards, Your training at the head of Your
  /// journey and a box on the profile.
  today,

  /// A. The Astute score alone: no skills anywhere the reader looks, no
  /// picker, no marks, no scores but the one.
  score,

  /// B. The aim alone: no skills, no box under the question; asked at the
  /// end of the first run too, said on the cards dealt for it, and its week
  /// in words and counts at the head of Your journey.
  aim,

  /// C. Measured, not picked: nothing to choose, the skills read from the
  /// reader's answers as a profile in Your journey, strongest first, in
  /// right answers out of answers given, with the weakest to practise; on
  /// the free plan the strongest only, the rest with Astute+.
  profile,

  /// D. The aim, read: the four skills the reader's aim takes, ranked from
  /// their answers, where they see clearly and their blind spot, under the
  /// question on every plan; the whole profile and five cards on the blind
  /// spot with Astute+.
  aimProfile,

  /// E. A focus a week: one of the aim's skills, Monday to Sunday, its mark
  /// on the cards that train it, a shelf of it on Explore and the day's
  /// own cards leaning to it, and on Sunday how the week went. Chosen in
  /// turn on the free plan, from the reader's answers on Astute+.
  weekly,
}

/// How the reader's first finished day ends, as the developer tools pick it
/// (lib/widgets/first_day.dart): celebrated first, on a screen of its own
/// right after the fifth card, the offer after it; or as it was before, the
/// offer at once.
enum FirstDayEndLook {
  /// The day celebrated: the streak, the points, how sure against how
  /// right, the reminder asked from there and Explore offered. The one that
  /// ships.
  celebration,

  /// As before: the card after the fifth at once, the reminder sheet over
  /// the shelf.
  asBefore,
}

/// How a card's foot is set, as the developer tools pick it: one of the
/// four ways being tried, by the letter the owner knows it by
/// (lib/widgets/source_foot.dart, SourceFoot).
enum CardFootPick {
  /// A. Go deeper and the source after it, on one line.
  a,

  /// B. Go deeper on a line of its own, the source under it.
  b,

  /// C. Go deeper and Why this card as two small buttons.
  c,

  /// D. Go deeper and Why this card as two links on one line.
  d,
}

/// Looks the developer tools let a phone try on, so the owner can compare
/// on his own phone what only pictures showed him before: the finished day
/// with no row over its card, the profile's other tops, where the day is
/// sent from, the picture it is sent as, What to learn five other ways,
/// the paywall's prototypes, the four feet of a card, the hard cards
/// ringed, and the first day's end as it was before it was celebrated.
/// Changed from the debug section at the foot of the profile, kept on the
/// phone, and listened to where each is drawn, so a change shows at once.
///
/// Read only while the tools are on ([debugToolsOn]): a look kept by a
/// TestFlight build is still on the phone when the App Store build is
/// installed over it, and there it is never read.
abstract final class DebugLooks {
  static const String _kNoTopRow = 'knowit.debug.todayNoTopRow';
  static const String _kProfileTop = 'knowit.debug.profileTop';
  static const String _kShareDay = 'knowit.debug.shareDay';
  static const String _kPaywall = 'knowit.debug.paywallLook';
  static const String _kLearn = 'knowit.debug.learn';
  static const String _kCardFoot = 'knowit.debug.cardFoot';
  static const String _kSharePicture = 'knowit.debug.sharePicture';
  static const String _kHardCards = 'knowit.debug.hardCards';
  static const String _kFirstDayEnd = 'knowit.debug.firstDayEnd';

  /// The finished day with no row over its shelf, as kept.
  static final ValueNotifier<bool> noTopRow = ValueNotifier<bool>(false);

  /// The profile's top, as kept.
  static final ValueNotifier<ProfileTopPick> profileTop =
      ValueNotifier<ProfileTopPick>(ProfileTopPick.auto);

  /// Where the finished day is sent from, as kept.
  static final ValueNotifier<ShareDayPick> shareDay =
      ValueNotifier<ShareDayPick>(ShareDayPick.a);

  /// The paywall that ships: the owner's choice.
  static const PaywallLook paywallShips = PaywallLook.c;

  /// The paywall, as kept.
  static final ValueNotifier<PaywallLook> paywall = ValueNotifier<PaywallLook>(
    paywallShips,
  );

  /// What to learn's look, as kept.
  static final ValueNotifier<LearnLook> learn = ValueNotifier<LearnLook>(
    LearnLook.today,
  );

  /// The foot of a card, as kept: null, the build's own (A, unless the
  /// build names another).
  static final ValueNotifier<CardFootPick?> cardFoot =
      ValueNotifier<CardFootPick?>(null);

  /// The picture the day is sent as that ships.
  static const SharePictureLook sharePictureShips = SharePictureLook.c;

  /// The picture the day is sent as, as kept.
  static final ValueNotifier<SharePictureLook> sharePicture =
      ValueNotifier<SharePictureLook>(sharePictureShips);

  /// How a hard card looks, as kept.
  static final ValueNotifier<HardCardLook> hardCards =
      ValueNotifier<HardCardLook>(HardCardLook.today);

  /// How the first finished day ends that ships: celebrated.
  static const FirstDayEndLook firstDayEndShips = FirstDayEndLook.celebration;

  /// How the first finished day ends, as kept.
  static final ValueNotifier<FirstDayEndLook> firstDayEnd =
      ValueNotifier<FirstDayEndLook>(firstDayEndShips);

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

  /// The paywall as picked for this run: the one that ships, unless the
  /// tools are on and another was picked.
  static PaywallLook get paywallPicked =>
      debugToolsOn ? paywall.value : paywallShips;

  /// What to learn's look for this run: as it ships, unless the tools are
  /// on and another was picked.
  static LearnLook get learnPicked =>
      debugToolsOn ? learn.value : LearnLook.today;

  /// The card's foot as picked for this run: none, so the build's own,
  /// unless the tools are on and one was picked.
  static CardFootPick? get cardFootPicked =>
      debugToolsOn ? cardFoot.value : null;

  /// The picture the day is sent as in this run: the one that ships, unless
  /// the tools are on and another was picked.
  static SharePictureLook get sharePicturePicked =>
      debugToolsOn ? sharePicture.value : sharePictureShips;

  /// How a hard card looks in this run: as today, unless the tools are on
  /// and ringed was picked.
  static HardCardLook get hardCardsPicked =>
      debugToolsOn ? hardCards.value : HardCardLook.today;

  /// How the first finished day ends in this run: celebrated, as it ships,
  /// unless the tools are on and as before was picked.
  static FirstDayEndLook get firstDayEndPicked =>
      debugToolsOn ? firstDayEnd.value : firstDayEndShips;

  /// Reads what this phone keeps. Nothing kept is the app as it ships.
  static void load(SharedPreferences prefs) {
    noTopRow.value = prefs.getBool(_kNoTopRow) ?? false;
    profileTop.value =
        ProfileTopPick.values.asNameMap()[prefs.getString(_kProfileTop)] ??
        ProfileTopPick.auto;
    shareDay.value =
        ShareDayPick.values.asNameMap()[prefs.getString(_kShareDay)] ??
        ShareDayPick.a;
    paywall.value =
        PaywallLook.values.asNameMap()[prefs.getString(_kPaywall)] ??
        paywallShips;
    learn.value =
        LearnLook.values.asNameMap()[prefs.getString(_kLearn)] ??
        LearnLook.today;
    cardFoot.value = CardFootPick.values
        .asNameMap()[prefs.getString(_kCardFoot)];
    sharePicture.value =
        SharePictureLook.values.asNameMap()[prefs.getString(_kSharePicture)] ??
        sharePictureShips;
    hardCards.value =
        HardCardLook.values.asNameMap()[prefs.getString(_kHardCards)] ??
        HardCardLook.today;
    firstDayEnd.value =
        FirstDayEndLook.values.asNameMap()[prefs.getString(_kFirstDayEnd)] ??
        firstDayEndShips;
  }

  /// Picks how the first finished day ends, and keeps it so.
  static Future<void> setFirstDayEnd(FirstDayEndLook look) async {
    firstDayEnd.value = look;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFirstDayEnd, look.name);
  }

  /// Picks the picture the day is sent as, and keeps it so.
  static Future<void> setSharePicture(SharePictureLook look) async {
    sharePicture.value = look;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSharePicture, look.name);
  }

  /// Picks how a hard card looks, and keeps it so.
  static Future<void> setHardCards(HardCardLook look) async {
    hardCards.value = look;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHardCards, look.name);
  }

  /// Picks the paywall, and keeps it so.
  static Future<void> setPaywall(PaywallLook look) async {
    paywall.value = look;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPaywall, look.name);
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

  /// Picks What to learn's look, and keeps it so.
  static Future<void> setLearn(LearnLook look) async {
    learn.value = look;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLearn, look.name);
  }

  /// Picks the card's foot, and keeps it so.
  static Future<void> setCardFoot(CardFootPick pick) async {
    cardFoot.value = pick;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCardFoot, pick.name);
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
    if (paywall.value != paywallShips) {
      await prefs.setString(_kPaywall, paywall.value.name);
    }
    if (learn.value != LearnLook.today) {
      await prefs.setString(_kLearn, learn.value.name);
    }
    if (cardFoot.value case final CardFootPick foot) {
      await prefs.setString(_kCardFoot, foot.name);
    }
    if (sharePicture.value != sharePictureShips) {
      await prefs.setString(_kSharePicture, sharePicture.value.name);
    }
    if (hardCards.value != HardCardLook.today) {
      await prefs.setString(_kHardCards, hardCards.value.name);
    }
    if (firstDayEnd.value != firstDayEndShips) {
      await prefs.setString(_kFirstDayEnd, firstDayEnd.value.name);
    }
  }

  /// The app as it ships, for a test that changed any of them.
  @visibleForTesting
  static void reset() {
    noTopRow.value = false;
    profileTop.value = ProfileTopPick.auto;
    shareDay.value = ShareDayPick.a;
    paywall.value = paywallShips;
    learn.value = LearnLook.today;
    cardFoot.value = null;
    sharePicture.value = sharePictureShips;
    hardCards.value = HardCardLook.today;
    firstDayEnd.value = firstDayEndShips;
  }
}
