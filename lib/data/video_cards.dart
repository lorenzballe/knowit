/// Video cards: a card that is a short film, drawn in a card's own colours
/// and type, opened to the whole screen with a tap and playing at once
/// (lib/widgets/video_card.dart).
///
/// Each film is made from a page with the card kit's fonts and GSAP, set
/// frame by frame and encoded once per language (docs/cards/video/). The
/// films are on the site, beside the cards' pages (web/cards/video/); the
/// first frame of each ships with the app (assets/video/), so its card is
/// there at once and the film is fetched only when it is played.
library;

import 'card_pages.dart' show kCardsBase;

/// One video card.
class VideoCard {
  const VideoCard({
    required this.id,
    required this.subject,
    required this.title,
    required this.file,
    required this.languages,
    required this.length,
    required this.ground,
    this.posterAt = const Duration(seconds: 4),
  });

  /// The card's id, for what is said about it ("video-eratosthenes").
  final String id;

  /// Its subject's key ("history").
  final String subject;

  /// Its question, by language; English for one it has not.
  final Map<String, String> title;

  /// The name its film and first frame share, before the language
  /// ("eratosthenes" for eratosthenes-en.mp4 and eratosthenes-en.webp).
  final String file;

  /// The languages it is told in, English first.
  final List<String> languages;

  /// How long it runs.
  final Duration length;

  /// The colour of its ground, which the screen takes round the film.
  final int ground;

  /// The moment of the film its first frame in the app is (posterFor): the
  /// film plays on from there when the card is opened, so its picture comes
  /// alive rather than starting over.
  final Duration posterAt;

  /// The language it is told in for a reader of [language]: theirs where it
  /// is told in it, English otherwise.
  String languageFor(String language) =>
      languages.contains(language) ? language : languages.first;

  /// Its question for a reader of [language].
  String titleFor(String language) => title[language] ?? title['en']!;

  /// Its film for a reader of [language], on the site.
  Uri filmFor(String language) =>
      Uri.parse('${kCardsBase}video/$file-${languageFor(language)}.mp4');

  /// Its first frame for a reader of [language], in the app.
  String posterFor(String language) =>
      'assets/video/$file-${languageFor(language)}.webp';
}

/// The video cards there are.
const List<VideoCard> kVideoCards = [
  VideoCard(
    id: 'video-eratosthenes',
    subject: 'history',
    title: {
      'en': 'How do you measure the Earth with a stick?',
      'it': 'Come si misura la Terra con un bastone?',
    },
    file: 'eratosthenes',
    languages: ['en', 'it'],
    length: Duration(milliseconds: 52700),
    ground: 0xFFFFB000,
  ),
];
