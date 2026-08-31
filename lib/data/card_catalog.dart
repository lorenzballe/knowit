import '../models/pill.dart';
import 'pills_data.dart';

/// Every card the app can deal right now.
///
/// Two sources, one list. The pool compiled into the binary is what a phone
/// with no network and no account still has — a first day has to work before
/// anything has been fetched, and the web preview has no Firebase at all. On
/// top of that sit the cards written since this build shipped, which is where
/// the catalogue actually grows: five a day against a fixed pool runs out in
/// about eight weeks, and no amount of ranking helps a deck with nothing left
/// in it.
///
/// Deliberately not a repository that goes and gets things. This holds what
/// is known; `sync/card_feed.dart` decides when to go and look. Keeping the
/// two apart is what lets every screen and every test read the catalogue
/// without touching the network.
class CardCatalog {
  const CardCatalog._();

  static List<Pill> _written = const [];
  static List<Pill>? _merged;

  /// The pool, built-in and written together. Ids are unique: a written card
  /// that reuses a built-in id replaces it, which is how a card with a
  /// mistake in it gets fixed without shipping a build.
  static List<Pill> get cards {
    return _merged ??= () {
      final byId = <String, Pill>{for (final p in kPillPool) p.id: p};
      for (final p in _written) {
        byId[p.id] = p;
      }
      return List<Pill>.unmodifiable(byId.values);
    }();
  }

  /// How many of the cards on hand were written after this build shipped.
  static int get writtenCount => _written.length;

  /// Takes a fetched set of cards. Replaces rather than appends: the feed
  /// hands over everything it knows, so appending would double the catalogue
  /// on every refresh.
  static void adopt(List<Pill> written) {
    _written = List<Pill>.unmodifiable(written);
    _merged = null;
  }

  /// Back to the built-in pool. Used when a reader signs out, and by tests
  /// that must not inherit another test's catalogue.
  static void reset() {
    _written = const [];
    _merged = null;
  }
}
