/// A question about a card, asked of the server (askCard, functions/src/
/// ask.ts) and answered by Claude, for Astute+: the card said simply, its two
/// sides, the reader's own reasoning looked at, or a question of theirs.
///
/// Only the card's id goes: the server reads the card's words from the bank,
/// so what is answered is what the reader saw.
library;

import 'package:cloud_functions/cloud_functions.dart';

import 'served.dart' show kFunctionsRegion;

/// What a reader can ask for.
enum AskMode {
  /// The card's idea, as to a curious ten-year-old.
  simple,

  /// The strongest case on each side of the question the card raises.
  sides,

  /// The reader's own reasoning about the card, looked at.
  take,

  /// A question of the reader's about the card.
  ask,
}

/// What came back.
sealed class AskResult {
  const AskResult();
}

/// The answer.
class AskAnswer extends AskResult {
  const AskAnswer(this.text);
  final String text;
}

/// Why there is no answer.
class AskNone extends AskResult {
  const AskNone(this.why);
  final AskWhyNot why;
}

/// Why a question was not answered.
enum AskWhyNot {
  /// Enough for today: the reader's questions, or everybody's.
  tomorrow,

  /// Only for Astute+, as far as the server knows.
  plus,

  /// The model would not answer this one.
  declined,

  /// Nothing came: no network, a server that did not answer.
  later,
}

/// How a question is asked. Replaceable, so tests never reach the server.
typedef AskCall = Future<AskResult> Function(
  String card,
  AskMode mode, {
  String text,
  required String language,
});

abstract final class CardAsk {
  /// How the app asks: the callable function. Tests replace it.
  static AskCall call = _callable;

  /// The most a reader may write, as the server cuts it (MAX_TEXT).
  static const int maxText = 600;

  static Future<AskResult> _callable(
    String card,
    AskMode mode, {
    String text = '',
    required String language,
  }) async {
    try {
      final result =
          await FirebaseFunctions.instanceFor(region: kFunctionsRegion)
              .httpsCallable(
                'askCard',
                options: HttpsCallableOptions(
                  timeout: const Duration(seconds: 70),
                ),
              )
              .call<Object?>({
                'card': card,
                'mode': mode.name,
                'text': text,
                'lang': language,
              });
      return read(result.data);
    } on FirebaseFunctionsException catch (e) {
      return AskNone(switch (e.code) {
        'resource-exhausted' => AskWhyNot.tomorrow,
        'permission-denied' => AskWhyNot.plus,
        _ => AskWhyNot.later,
      });
    } catch (_) {
      return const AskNone(AskWhyNot.later);
    }
  }

  /// What the server answered, read.
  static AskResult read(Object? data) {
    if (data is! Map) return const AskNone(AskWhyNot.later);
    final Object? text = data['text'];
    if (text is String && text.trim().isNotEmpty) return AskAnswer(text.trim());
    return AskNone(
      data['none'] == 'declined' ? AskWhyNot.declined : AskWhyNot.later,
    );
  }
}
