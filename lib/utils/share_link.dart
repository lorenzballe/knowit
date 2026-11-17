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
/// spelling and a new share cannot leave without one.
enum ShareRef {
  /// The day as five squares (`ShareDay`).
  day('share_day'),

  /// One card, from its share sheet: its page on the site ([cardLink]).
  card('share_card'),

  /// The reader's record, from its share sheet.
  record('share_record'),

  /// One card sent to a friend to play, as builds before the card's own
  /// page sent it: links already in chats still carry it.
  challenge('challenge');

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
String cardLink(String cardId) => cardId.startsWith('news-')
    ? ShareRef.card.link
    : 'https://$kSiteHost/c/$cardId.html?ref=${ShareRef.card.ref}';
