/// A card of the day read aloud, asked of the server (listenCard,
/// functions/src/listen.ts): the addresses of its two clips, the question
/// and the answer, made once by ElevenLabs for every reader and kept in
/// Storage. The first card of a day is everybody's; the rest are Astute+'s.
///
/// Only the card's id and the day go: the server reads the card's words from
/// the bank, so what is read is what the reader sees.
library;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../cloud.dart';
import 'served.dart' show kFunctionsRegion;
import 'trace.dart';

/// What came back for a card.
sealed class ListenReply {
  const ListenReply();
}

/// The card's two clips, to be played from where they are.
class ListenClips extends ListenReply {
  const ListenClips({required this.question, required this.answer});
  final Uri question;
  final Uri answer;
}

/// Why there is nothing to play for a card.
class ListenNone extends ListenReply {
  const ListenNone(this.why, {this.detail});
  final ListenWhyNot why;

  /// What the server said, word for word, when it said anything: for the
  /// developer tools and the logs, never for the reader.
  final String? detail;
}

/// Why a card cannot be heard.
enum ListenWhyNot {
  /// The server has no ElevenLabs key: Listen is hidden for the sitting.
  notConfigured,

  /// The card has nothing sensible to read aloud (a drawn card whose words
  /// are all about its page): it is passed over, and said so.
  nothing,

  /// Past the day's free card on the free plan: Astute+.
  plus,

  /// Not available right now: the characters of the day or the month are
  /// spent, the ElevenLabs account has no credit, or the voice is busy.
  unavailable,

  /// Nothing came: no network, a server that did not answer.
  later,
}

/// How a card is asked for. Replaceable, so tests never reach the server.
typedef ListenCall = Future<ListenReply> Function(
  String card, {
  required String date,
  required int tz,
});

abstract final class ListenClient {
  /// How the app asks: the callable function. Tests replace it.
  static ListenCall call = _callable;

  /// Whether the server can be asked at all: Firebase up (lib/cloud.dart),
  /// which it never is in a test or on the web preview. Tests say yes.
  static bool Function() reachable = () => Cloud.ready;

  /// True once the server has said, this sitting, that Listen is not
  /// configured: the entry on Today goes, and comes back with the next
  /// launch, so a key added on the server reaches the phones without them
  /// doing anything.
  static final ValueNotifier<bool> unconfigured = ValueNotifier<bool>(false);

  @visibleForTesting
  static void resetForTest() {
    call = _callable;
    reachable = () => Cloud.ready;
    unconfigured.value = false;
  }

  static Future<ListenReply> _callable(
    String card, {
    required String date,
    required int tz,
  }) => _ask(card, date, tz, again: true);

  static Future<ListenReply> _ask(
    String card,
    String date,
    int tz, {
    required bool again,
  }) async {
    try {
      final result =
          await FirebaseFunctions.instanceFor(region: kFunctionsRegion)
              .httpsCallable(
                'listenCard',
                options: HttpsCallableOptions(
                  timeout: const Duration(seconds: 50),
                ),
              )
              .call<Object?>({'card': card, 'date': date, 'tz': tz});
      return read(result.data);
    } on FirebaseFunctionsException catch (e) {
      // The server reads the plan from the presence the phone last wrote.
      // Told "Astute+ only" while the phone is on Astute+, the phone has not
      // said so yet: it says so now, and asks once more.
      if (e.code == 'permission-denied' &&
          again &&
          Trace.instance.plus &&
          await Trace.instance.sayPresence()) {
        return _ask(card, date, tz, again: false);
      }
      return ListenNone(switch (e.code) {
        'permission-denied' => ListenWhyNot.plus,
        'resource-exhausted' => ListenWhyNot.unavailable,
        _ => ListenWhyNot.later,
      }, detail: '${e.code}: ${e.message ?? ''}');
    } catch (error) {
      return ListenNone(ListenWhyNot.later, detail: '$error');
    }
  }

  /// What the server answered, read.
  static ListenReply read(Object? data) {
    if (data is! Map) return const ListenNone(ListenWhyNot.later);
    final Uri? question = _url(data['question']);
    final Uri? answer = _url(data['answer']);
    if (question != null && answer != null) {
      return ListenClips(question: question, answer: answer);
    }
    final Object? why = data['why'];
    return switch (data['none']) {
      'not-configured' => const ListenNone(ListenWhyNot.notConfigured),
      'nothing' => const ListenNone(ListenWhyNot.nothing),
      'unavailable' => ListenNone(
        ListenWhyNot.unavailable,
        detail: why is String ? why : null,
      ),
      _ => const ListenNone(ListenWhyNot.later),
    };
  }

  static Uri? _url(Object? value) {
    if (value is! String) return null;
    final Uri? uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' ? uri : null;
  }
}
