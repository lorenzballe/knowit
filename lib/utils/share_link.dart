import 'share_text.dart';

/// How a short message — a card's question and its page — is handed to the
/// system's share sheet: the platform's own, false where there is none so
/// the caller copies it. A test, which has no sheet (and whose desktop
/// stand-in never returns), puts its own here.
Future<bool> Function(String text) sendText = shareText;

/// The site, as an image that leaves the app prints it: short enough to be
/// read off a screenshot and typed into a browser.
const String kSiteHost = 'astutetheapp.com';

/// Which share a link left the app in, as the site reads it in `ref`.
///
/// A card, a day or a record in someone else's chat is the only free
/// distribution the app has, and a bare address could not say which of the
/// three brought anybody back. So every shared link carries one of these,
/// and they live here, together, so that the site and the app agree on the
/// spelling and a new share cannot leave without one. The one exception is
/// the challenge on today's five ([fiveChallengeLink]): its page is named
/// for it, so the site counts it by its page, and its link carries the day
/// and the score and nothing else.
enum ShareRef {
  /// The day as five squares (`ShareDay`).
  day('share_day'),

  /// One card, from its share sheet: its page on the site ([cardLink]).
  card('share_card'),

  /// The reader's record, from its share sheet.
  record('share_record'),

  /// One card sent to a friend to play, as builds before the card's own
  /// page sent it: links already in chats still carry it.
  challenge('challenge'),

  /// Today's three: the day's score, a square a card, never the answers.
  three('share_three'),

  /// Sixty seconds: the round's score, a square a claim, never the answers.
  sixty('share_sixty'),

  /// Any other of Explore's challenges: the game's score, a square a card,
  /// never the answers.
  challenges('share_challenges'),

  /// The line of the day (lib/data/day_lines.dart), with where it was
  /// written.
  line('share_line'),

  /// A level of the Astute score reached, as its picture
  /// (lib/widgets/level_up.dart).
  level('share_level');

  const ShareRef(this.ref);

  /// What the site reads in `ref`.
  final String ref;

  /// The site, carrying [ref].
  String get link => 'https://$kSiteHost/?ref=$ref';
}

/// Where a card is met by a friend, with or without the app: its page on
/// the site, under a line saying a friend sent it. A card with a drawing is
/// played there; a card in words asks its question, and shows its answer
/// on a tap (tool/cards/challenge_pages.py writes one for every card). A
/// card of the morning's paper (lib/data/news_paper.dart, ids `news-…`) has
/// no page of its own, so it sends the site, under the same line.
///
/// Short, as a post's link is: `astutetheapp.com/c/<id>`, which the site
/// serves from `c/<id>.html`. On a phone with the app, the phone opens the
/// app on the card instead (WidgetOpen.link).
String cardLink(String cardId) => cardId.startsWith('news-')
    ? ShareRef.card.link
    : 'https://$kSiteHost/c/$cardId?ref=${ShareRef.card.ref}';

/// Where a friend is challenged on today's five ("Challenge a friend"): the
/// site's page for it, where the same five are played in a browser, with
/// or without the app, and the two scores are set side by side
/// (tool/cards/sfida_page.py writes it).
///
/// The link carries the day the five were dealt, `yyyy-mm-dd` on the
/// reader's calendar, so the friend plays the very cards even a day later
/// or in another time zone; and, once the reader has played them, how many
/// of the five were right, 0 to 5. Nothing else: no name, no id, no ref —
/// the page is named for the challenge, and the site counts it by its page.
/// `astutetheapp.com/sfida?d=2026-11-27&s=4`. A day the site no longer has
/// falls back, on the page, to the site's own today.
///
/// Not a link the app opens: on a phone with the app the page still opens
/// in the browser, where the two scores can be compared
/// (site/.well-known/ names `/c/*` alone).
String fiveChallengeLink(String day, {int? score}) {
  assert(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day), day);
  final bool scored = score != null && score >= 0 && score <= 5;
  return 'https://$kSiteHost/sfida?d=$day${scored ? '&s=$score' : ''}';
}
