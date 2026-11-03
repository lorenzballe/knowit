/// What keeps a free card's page between runs (see CardPages).
abstract class PageStore {
  /// The page kept under [ref], or null when none is.
  Future<String?> read(String ref);

  /// Keeps [html] under [ref].
  Future<void> write(String ref, String html);
}

/// Pages kept in memory only, for as long as the store lives: the web's,
/// whose browser keeps what it fetched, and the tests'.
class MemoryPageStore implements PageStore {
  final Map<String, String> pages = {};

  @override
  Future<String?> read(String ref) async => pages[ref];

  @override
  Future<void> write(String ref, String html) async => pages[ref] = html;
}
