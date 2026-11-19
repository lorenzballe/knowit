/// A reader's notes on cards: a few lines of their own on a card, kept on the
/// phone and in the account's backup with the rest of what is theirs.
library;

import 'dart:convert';

/// A note on a card: what the reader wrote, and when they last wrote it.
///
/// A note taken away is kept as an empty one, with the time it was taken
/// away, so that an older copy from another phone does not bring it back
/// when the two are put together.
class CardNote {
  const CardNote(this.text, this.at);

  final String text;

  /// When it was last written or taken away, in seconds since the epoch.
  final int at;

  bool get isEmpty => text.isEmpty;

  Map<String, Object> toJson() => {'t': text, 'at': at};

  static CardNote? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final Object? text = raw['t'];
    final Object? at = raw['at'];
    if (text is! String || at is! num) return null;
    return CardNote(text, at.toInt());
  }
}

abstract final class CardNotes {
  /// The longest a note is kept: a few lines, not an essay.
  static const int maxLength = 500;

  /// [notes] as the backup and the phone keep them: by card.
  static Map<String, Object> toJson(Map<String, CardNote> notes) => {
    for (final MapEntry<String, CardNote> e in notes.entries)
      e.key: e.value.toJson(),
  };

  static Map<String, CardNote> fromJson(Object? raw) {
    if (raw is! Map) return {};
    return {
      for (final MapEntry<Object?, Object?> e in raw.entries)
        if (e.key is String && CardNote.fromJson(e.value) != null)
          e.key as String: CardNote.fromJson(e.value)!,
    };
  }

  static String encode(Map<String, CardNote> notes) =>
      jsonEncode(toJson(notes));

  static Map<String, CardNote> decode(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      return fromJson(jsonDecode(raw));
    } catch (_) {
      return {};
    }
  }

  /// [a] and [b] as one: for each card, the note written last, a note taken
  /// away included.
  static Map<String, CardNote> merged(
    Map<String, CardNote> a,
    Map<String, CardNote> b,
  ) {
    final Map<String, CardNote> out = {...a};
    for (final MapEntry<String, CardNote> e in b.entries) {
      final CardNote? mine = out[e.key];
      if (mine == null || e.value.at > mine.at) out[e.key] = e.value;
    }
    return out;
  }
}
