import 'dart:typed_data';

/// What keeps a card's picture between runs (see CachedThumb).
abstract class ThumbStore {
  /// The picture kept under [name], or null when none is.
  Future<Uint8List?> read(String name);

  /// Whether a picture is kept under [name].
  Future<bool> has(String name);

  /// Keeps [bytes] under [name].
  Future<void> write(String name, Uint8List bytes);
}

/// Pictures kept in memory only, for as long as the store lives: the web's,
/// whose browser keeps what it fetched, and the tests'.
class MemoryThumbStore implements ThumbStore {
  final Map<String, Uint8List> pictures = {};

  @override
  Future<Uint8List?> read(String name) async => pictures[name];

  @override
  Future<bool> has(String name) async => pictures.containsKey(name);

  @override
  Future<void> write(String name, Uint8List bytes) async =>
      pictures[name] = bytes;
}
