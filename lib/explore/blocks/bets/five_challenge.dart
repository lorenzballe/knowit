/// Today's five, sent to a friend as a challenge: "Challenge a friend".
///
/// The five at the top of Explore are the same for every reader that day,
/// and the site has them too: the deploy publishes the app's own deal for
/// every day (tool/todays_five.dart). So a reader who has played them can
/// send a friend a line in the reader's language and a link to the site's
/// page for the day ([fiveChallengeLink]). The friend plays the same five in
/// a browser, with or without the app, and sees the two scores side by
/// side, each answer with the right one and its why
/// (tool/cards/sfida_page.py). The score is how many of the five were
/// right, as the app judges each card ([Challenge.accepts]); the page judges
/// the friend's the same way, from what the site publishes of each card.
///
/// Before the reader has played, the link goes without a score: the five
/// themselves, and the friend's own score at the end.
///
/// Sent from the end of the five on Explore, and from the finished day's
/// share, while the server says so (AppState.kShareChallengeFlag).
library;

import 'package:flutter/services.dart';

import '../../../analytics.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/pill.dart';
import '../../../utils/share_link.dart';
import 'daily_deal.dart';

/// Whether [cards], in their order, are the five the site has for [day]:
/// the app's own deal for the date. A five the server named for the day
/// instead is not one, and is not sent: the friend would be played other
/// cards.
bool isSitesFive(DateTime day, List<Pill> cards) {
  final List<Pill> five = DailyDeal.five(day);
  if (five.length != 5 || cards.length != 5) return false;
  for (int i = 0; i < 5; i++) {
    if (five[i].id != cards[i].id) return false;
  }
  return true;
}

/// What is sent: a line in the reader's language — how many of the day's
/// five they got right and whether the friend can do better (all five: as
/// well), or, with no score, the five themselves — and the link under it.
String fiveChallengeText(
  AppLocalizations l, {
  required String day,
  int? right,
}) => [
  right == null
      ? l.fiveChallengeInvite
      : right >= 5
      ? l.fiveChallengeAll
      : l.fiveChallengeLine(right),
  fiveChallengeLink(day, score: right),
].join('\n');

/// Sends the challenge through the system's share sheet, or copies it where
/// there is none: true when the sheet took it, so the caller says "copied"
/// otherwise, where it will be seen. Counted as `five challenge shared`,
/// with where it was sent [from] and the score it carried.
Future<bool> sendFiveChallenge(
  AppLocalizations l, {
  required String from,
  required String day,
  int? right,
}) async {
  final String text = fiveChallengeText(l, day: day, right: right);
  final bool shared = await sendText(text);
  Analytics.capture('five challenge shared', {
    'from': from,
    'right': right,
    'as': shared ? 'link' : 'copied',
  });
  if (!shared) await Clipboard.setData(ClipboardData(text: text));
  return shared;
}
