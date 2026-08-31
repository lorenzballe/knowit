import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cloud.dart';
import '../data/card_catalog.dart';
import '../data/card_codec.dart';
import '../models/pill.dart';

/// Brings the cards written since this build shipped onto the phone.
///
/// Local-first, like everything else here: the phone already holds a pool
/// that works, so this is never on the path to a reader's first card. It
/// loads the cache, hands it over, and only then goes to look for more — and
/// if the network is down, or Firebase never started, or the reader is on the
/// web preview where there is no project at all, nothing happens and the app
/// deals from what it shipped with.
///
/// The cache is the point rather than an optimisation. A catalogue that only
/// exists on the network is a catalogue a reader on a train does not have.
class CardFeed {
  const CardFeed._();

  static const _kCards = 'knowit.writtenCards';
  static const _kFetchedAt = 'knowit.cardsFetchedAt';

  /// How long the app goes before asking for more.
  ///
  /// The generator runs once a day, so asking more often than that is asking
  /// for the same answer. Half a day gives a reader who opens the app every
  /// morning yesterday's cards without a wasted read on every launch.
  static const Duration _stale = Duration(hours: 12);

  /// Reads the cache and hands it to the catalogue. Synchronous as far as the
  /// reader is concerned: this is done before the first card is dealt.
  static Future<void> loadCache(SharedPreferences prefs) async {
    final raw = prefs.getString(_kCards);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      CardCatalog.adopt([
        for (final entry in decoded) ?cardFromJson(entry),
      ]);
    } catch (error) {
      // A cache written by another build, or half-written by a process that
      // was killed. The built-in pool is right here; losing the cache costs
      // a reader nothing they can see.
      debugPrint('Astuto: the card cache would not read, ignoring it: $error');
    }
  }

  /// Goes and looks, unless it looked recently.
  ///
  /// Never throws and never blocks anything a reader is waiting on. Returns
  /// how many cards are now held, or null when it did not go.
  static Future<int?> refresh(
    SharedPreferences prefs, {
    bool force = false,
    FirebaseFirestore? firestore,
  }) async {
    if (!Cloud.ready) return null;
    final last = prefs.getInt(_kFetchedAt) ?? 0;
    final since = DateTime.now().millisecondsSinceEpoch - last;
    if (!force && since < _stale.inMilliseconds) return null;

    try {
      final db = firestore ?? FirebaseFirestore.instance;
      final snap = await db.collection('cards').get();
      final cards = <Pill>[];
      for (final doc in snap.docs) {
        final card = cardFromJson(doc.data());
        // A card that does not read is skipped rather than failing the
        // fetch. One bad document must not cost the reader the other
        // hundred.
        if (card != null) cards.add(card);
      }

      CardCatalog.adopt(cards);
      await prefs.setString(
        _kCards,
        jsonEncode([for (final card in cards) cardToJson(card)]),
      );
      await prefs.setInt(
        _kFetchedAt,
        DateTime.now().millisecondsSinceEpoch,
      );
      return cards.length;
    } catch (error) {
      debugPrint('Astuto: could not fetch cards, dealing from the pool: $error');
      return null;
    }
  }

  /// Forgets the fetched catalogue. Called on sign-out, with everything else.
  static Future<void> clear(SharedPreferences prefs) async {
    CardCatalog.reset();
    await prefs.remove(_kCards);
    await prefs.remove(_kFetchedAt);
  }
}
