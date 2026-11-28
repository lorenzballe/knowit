/// A part of a book's summary read aloud, asked of the server (bookClip,
/// functions/src/books.ts): the address of its clip, made once by
/// ElevenLabs for every reader and kept in Storage. The week's free book and
/// the first part of any book are everybody's; the rest are Astute+'s.
///
/// Only the book's id, the part and the day go: the server reads the
/// summary the bank names, so what is heard is what is read.
library;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../cloud.dart';
import 'served.dart' show kFunctionsRegion;
import 'trace.dart';

/// What came back for a part.
sealed class BookAudioReply {
  const BookAudioReply();
}

/// The part's clip, to be played from where it is, and about how long it
/// plays (0 when the server did not say).
class BookAudioClip extends BookAudioReply {
  const BookAudioClip({required this.url, this.seconds = 0});
  final Uri url;
  final int seconds;
}

/// Why there is nothing to play for a part.
class BookAudioNone extends BookAudioReply {
  const BookAudioNone(this.why, {this.detail});
  final BookAudioWhyNot why;

  /// What the server said, word for word, when it said anything: for the
  /// developer tools and the logs, never for the reader.
  final String? detail;
}

/// Why a part cannot be heard.
enum BookAudioWhyNot {
  /// The server has no ElevenLabs key: listening is hidden for the sitting.
  notConfigured,

  /// The book has no summary the server can read, or no such part.
  nothing,

  /// Past the free parts on the free plan: Astute+.
  plus,

  /// Not available right now: the month's characters cannot hold the book,
  /// the ElevenLabs account has no credit, or the voice is busy.
  unavailable,

  /// Nothing came: no network, a server that did not answer.
  later,
}

/// How a part is asked for. Replaceable, so tests never reach the server.
typedef BookAudioCall = Future<BookAudioReply> Function(
  String book,
  int part, {
  required String date,
  required int tz,
});

abstract final class BookAudioClient {
  /// How the app asks: the callable function. Tests replace it.
  static BookAudioCall call = _callable;

  /// Whether the server can be asked at all: Firebase up (lib/cloud.dart),
  /// which it never is in a test or on the web preview. Tests say yes.
  static bool Function() reachable = () => Cloud.ready;

  /// True once the server has said, this sitting, that listening is not
  /// configured: the way to listen goes from every book, and comes back
  /// with the next launch, so a key added on the server reaches the phones
  /// without them doing anything.
  static final ValueNotifier<bool> unconfigured = ValueNotifier<bool>(false);

  @visibleForTesting
  static void resetForTest() {
    call = _callable;
    reachable = () => Cloud.ready;
    unconfigured.value = false;
  }

  static Future<BookAudioReply> _callable(
    String book,
    int part, {
    required String date,
    required int tz,
  }) => _ask(book, part, date, tz, again: true);

  static Future<BookAudioReply> _ask(
    String book,
    int part,
    String date,
    int tz, {
    required bool again,
  }) async {
    try {
      final result =
          await FirebaseFunctions.instanceFor(region: kFunctionsRegion)
              .httpsCallable(
                'bookClip',
                options: HttpsCallableOptions(
                  timeout: const Duration(seconds: 80),
                ),
              )
              .call<Object?>({
                'book': book,
                'part': part,
                'date': date,
                'tz': tz,
              });
      return read(result.data);
    } on FirebaseFunctionsException catch (e) {
      // The server reads the plan from the presence the phone last wrote.
      // Told "Astute+ only" while the phone is on Astute+, the phone has not
      // said so yet: it says so now, and asks once more.
      if (e.code == 'permission-denied' &&
          again &&
          Trace.instance.plus &&
          await Trace.instance.sayPresence()) {
        return _ask(book, part, date, tz, again: false);
      }
      return BookAudioNone(switch (e.code) {
        'permission-denied' => BookAudioWhyNot.plus,
        'resource-exhausted' => BookAudioWhyNot.unavailable,
        _ => BookAudioWhyNot.later,
      }, detail: '${e.code}: ${e.message ?? ''}');
    } catch (error) {
      return BookAudioNone(BookAudioWhyNot.later, detail: '$error');
    }
  }

  /// What the server answered, read.
  static BookAudioReply read(Object? data) {
    if (data is! Map) return const BookAudioNone(BookAudioWhyNot.later);
    final Object? url = data['url'];
    final Uri? uri = url is String ? Uri.tryParse(url) : null;
    if (uri != null && uri.scheme == 'https') {
      final Object? seconds = data['seconds'];
      return BookAudioClip(url: uri, seconds: seconds is int ? seconds : 0);
    }
    final Object? why = data['why'];
    return switch (data['none']) {
      'not-configured' => const BookAudioNone(BookAudioWhyNot.notConfigured),
      'nothing' => const BookAudioNone(BookAudioWhyNot.nothing),
      'unavailable' => BookAudioNone(
        BookAudioWhyNot.unavailable,
        detail: why is String ? why : null,
      ),
      _ => const BookAudioNone(BookAudioWhyNot.later),
    };
  }
}
