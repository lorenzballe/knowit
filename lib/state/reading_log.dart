import 'dart:convert';

/// One read of a card, as the deck saw it: kept on the phone and in the
/// account's backup, so the app learns from how the reader reads and not
/// only from what they say. A like and an answer are said; a back read to
/// its end, a card opened again, a card thrown on unturned in a second are
/// done — and they are most of what a reader tells us.
///
/// Facts only, as CardRead keeps them: times and counts, never what was
/// typed or picked (the answer is the answer's own record, a [Judgement]).
class CardReadEntry {
  const CardReadEntry({
    required this.id,
    required this.at,
    required this.msFront,
    required this.msBack,
    this.flips = 0,
    this.hint = false,
    this.changed = 0,
    this.backPct,
    this.thrown = false,
    this.reread = false,
  });

  /// The card.
  final String id;

  /// When the read ended, in seconds since the epoch.
  final int at;

  /// How long the front and the back were in sight, in milliseconds.
  final int msFront;
  final int msBack;

  /// How many times the card was turned.
  final int flips;

  /// Whether the hint was opened.
  final bool hint;

  /// How many times an answer was taken back.
  final int changed;

  /// How much of a back too long for the card was seen, 0 to 100; null
  /// when the back was never seen or fitted the card.
  final int? backPct;

  /// Thrown on, rather than left standing for another screen.
  final bool thrown;

  /// A card read before.
  final bool reread;

  /// From the facts a read is said with ('card advanced', 'card closed';
  /// see CardRead.facts).
  static CardReadEntry fromFacts(
    String id,
    Map<String, Object?> facts, {
    required bool thrown,
    DateTime? at,
  }) {
    int n(String key) => switch (facts[key]) {
      final num v => v.round(),
      _ => 0,
    };
    return CardReadEntry(
      id: id,
      at: (at ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000,
      msFront: n('ms_front'),
      msBack: n('ms_back'),
      flips: n('flips'),
      hint: facts['hint_opened'] == true,
      changed: n('options_changed'),
      backPct: switch (facts['back_scroll_pct']) {
        final num v => v.round().clamp(0, 100),
        _ => null,
      },
      thrown: thrown,
      reread: facts['reread'] == true,
    );
  }

  /// Read with interest: its back given time and read most of the way, or
  /// the card opened again by choice.
  bool get held => reread || (msBack >= 5000 && (backPct ?? 100) >= 60);

  /// Passed over: thrown on within moments, never turned.
  bool get skipped =>
      thrown && !reread && flips == 0 && msBack == 0 && msFront < 2500;

  List<Object> toJson() => [
    id,
    at,
    msFront,
    msBack,
    flips,
    hint ? 1 : 0,
    changed,
    backPct ?? -1,
    thrown ? 1 : 0,
    reread ? 1 : 0,
  ];

  static CardReadEntry? fromJson(Object? raw) {
    if (raw is! List || raw.length < 10 || raw[0] is! String) return null;
    int n(int i) => raw[i] is num ? (raw[i] as num).round() : 0;
    return CardReadEntry(
      id: raw[0] as String,
      at: n(1),
      msFront: n(2),
      msBack: n(3),
      flips: n(4),
      hint: n(5) == 1,
      changed: n(6),
      backPct: n(7) < 0 ? null : n(7),
      thrown: n(8) == 1,
      reread: n(9) == 1,
    );
  }
}

/// The reader's reads, oldest first, the last [keep] of them.
abstract final class ReadingLog {
  /// About a year of days at five cards and some reading again, in under
  /// 100 kB: enough to learn from, small enough to back up whole.
  static const int keep = 1500;

  static List<CardReadEntry> decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final Object? list = jsonDecode(raw);
      if (list is! List) return [];
      return list
          .map(CardReadEntry.fromJson)
          .whereType<CardReadEntry>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  static List<Object> toJson(List<CardReadEntry> log) => [
    for (final CardReadEntry e in log) e.toJson(),
  ];

  static String encode(List<CardReadEntry> log) => jsonEncode(toJson(log));

  /// [log] with [entry] at its end, its oldest let go past [keep].
  static List<CardReadEntry> added(
    List<CardReadEntry> log,
    CardReadEntry entry,
  ) {
    final List<CardReadEntry> out = [...log, entry];
    return out.length <= keep ? out : out.sublist(out.length - keep);
  }

  /// What the reads say of each card, the latest word on it: the cards held
  /// and the cards passed over. A card passed over once and held after is
  /// held; held and later passed over, passed over.
  static ({Set<String> held, Set<String> skipped}) signals(
    List<CardReadEntry> log,
  ) {
    final Map<String, bool> last = {};
    for (final CardReadEntry e in log) {
      if (e.held) {
        last[e.id] = true;
      } else if (e.skipped) {
        last[e.id] = false;
      }
    }
    return (
      held: {
        for (final e in last.entries)
          if (e.value) e.key,
      },
      skipped: {
        for (final e in last.entries)
          if (!e.value) e.key,
      },
    );
  }
}
