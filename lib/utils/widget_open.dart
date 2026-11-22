/// A tap on a home-screen widget, as the phone kept it until the app asked.
///
/// Every widget opens the app on a link that names itself, and a widget
/// that shows cards names the card that was tapped and where it lives:
/// one of today's five, or a card of today's shelf at the top of Explore.
/// The app opens exactly that card (see `AstutoShell`).
class WidgetOpen {
  const WidgetOpen({required this.from, this.card, this.place});

  /// Which widget, as "kind.family": `card.systemSmall`, `five.home`,
  /// `shelf.systemLarge`.
  final String from;

  /// The card tapped, by id, when the tap landed on one.
  final String? card;

  /// Where that card lives: [today] or [shelf].
  final String? place;

  /// One of today's five.
  static const String today = 'today';

  /// A card of today's shelf, the same for everybody.
  static const String shelf = 'shelf';

  /// Any card of the bank, opened from its link on the site
  /// (`astutetheapp.com/c/<id>`) tapped in a chat, a mail or a browser, as a
  /// post opens from its link: the phone hands the link to the app when it
  /// is installed, and the card opens on its own.
  static const String link = 'link';

  /// The card a card's link names: `https://astutetheapp.com/c/<id>`, with
  /// or without `.html`, `www.` and a query; null for any other address.
  static String? cardOfLink(Uri url) {
    if (url.scheme != 'https' && url.scheme != 'http') return null;
    final String host = url.host.toLowerCase();
    if (host != 'astutetheapp.com' && host != 'www.astutetheapp.com') {
      return null;
    }
    final List<String> parts = url.pathSegments
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.length != 2 || parts.first != 'c') return null;
    final String id = parts.last.replaceFirst(RegExp(r'\.html$'), '');
    return RegExp(r'^[a-z0-9_-]+$').hasMatch(id) ? id : null;
  }

  /// The widget's kind, the part before the dot: `card`, `streak`, `five`,
  /// `shelf`.
  String get kind => from.split('.').first;

  /// What the phone handed over: a map of `from`, `card` and `in` — or, from
  /// a build that only said which widget it was, the name alone.
  static WidgetOpen? read(Object? raw) {
    if (raw is String) {
      return raw.isEmpty ? null : WidgetOpen(from: raw);
    }
    if (raw is! Map) return null;
    String? text(Object? key) {
      final Object? value = raw[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    final String? card = text('card');
    final String? place = text('in');
    final String? from = text('from');
    if (from == null && card == null) return null;
    return WidgetOpen(from: from ?? 'unknown', card: card, place: place);
  }

  @override
  String toString() => 'WidgetOpen($from, card: $card, in: $place)';
}
