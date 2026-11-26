/// A question about a card, asked of the server (askCard, functions/src/
/// ask.ts) and answered by Claude, for Astute+: the card said simply, its two
/// sides, the reader's own reasoning looked at, or a question of theirs.
///
/// Only the card's id goes: the server reads the card's words from the bank,
/// so what is answered is what the reader saw.
library;

import 'package:cloud_functions/cloud_functions.dart';

import 'served.dart' show kFunctionsRegion;
import 'trace.dart';

/// What a reader can ask for.
enum AskMode {
  /// The card's idea, as to a curious ten-year-old.
  simple,

  /// The strongest case on each side of the question the card raises.
  sides,

  /// One moment from ordinary life where the card's idea shows up.
  example,

  /// A new question on the card's idea, in a case the card does not
  /// mention, to answer there and then ([CardQuiz]).
  quiz,

  /// The reader's own reasoning about the card, looked at.
  take,

  /// A question of the reader's about the card.
  ask,
}

/// A question that carries a card's idea to a new case ([AskMode.quiz]), as
/// the server writes it: the question, three options, which is right, why.
class CardQuiz {
  const CardQuiz({
    required this.question,
    required this.options,
    required this.right,
    required this.why,
  });

  final String question;
  final List<String> options;

  /// Which of [options] is right.
  final int right;
  final String why;

  /// The quiz in [text], or null when it is not one. The server sends it
  /// in one shape (ask.ts, quizText); bold and stray spaces are forgiven.
  static CardQuiz? parse(String text) {
    final List<String> lines = [
      for (final String l in text.replaceAll('**', '').split('\n'))
        if (l.trim().isNotEmpty) l.trim(),
    ];
    String? pick(RegExp re) {
      for (final String l in lines) {
        final RegExpMatch? m = re.firstMatch(l);
        if (m != null) return m.group(1)!.trim();
      }
      return null;
    }

    final String? question = pick(
      RegExp(r'^Q\s*[:.)]\s*(.+)$', caseSensitive: false),
    );
    final String? a = pick(RegExp(r'^A\s*[).:]\s*(.+)$'));
    final String? b = pick(RegExp(r'^B\s*[).:]\s*(.+)$'));
    final String? c = pick(RegExp(r'^C\s*[).:]\s*(.+)$'));
    final String? right = pick(
      RegExp(r'^RIGHT\s*:\s*\(?([ABC])\b', caseSensitive: false),
    );
    final String? why = pick(RegExp(r'^WHY\s*:\s*(.+)$', caseSensitive: false));
    if (question == null ||
        a == null ||
        b == null ||
        c == null ||
        right == null ||
        why == null) {
      return null;
    }
    return CardQuiz(
      question: question,
      options: [a, b, c],
      right: 'ABC'.indexOf(right.toUpperCase()),
      why: why,
    );
  }
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
  const AskNone(this.why, {this.detail});
  final AskWhyNot why;

  /// What the server said, word for word, when it said anything: shown
  /// only with the developer tools, where "it does not work" needs a
  /// reason that can be read off the screen.
  final String? detail;
}

/// Why a question was not answered.
enum AskWhyNot {
  /// Enough for today: the reader's questions, or everybody's.
  tomorrow,

  /// Only for Astute+, as far as the server knows.
  plus,

  /// The model would not answer this one.
  declined,

  /// Not available right now: what the AI may spend this day or month is
  /// spent (functions/src/limits.ts), and comes back when it turns.
  unavailable,

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
  }) => _ask(card, mode, text: text, language: language, again: true);

  static Future<AskResult> _ask(
    String card,
    AskMode mode, {
    required String text,
    required String language,
    required bool again,
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
      // The server reads the plan from the presence the phone last wrote.
      // Told "Astute+ only" while the phone is on Astute+, the phone has not
      // said so yet: it says so now, and asks once more.
      if (e.code == 'permission-denied' &&
          again &&
          Trace.instance.plus &&
          await Trace.instance.sayPresence()) {
        return _ask(card, mode, text: text, language: language, again: false);
      }
      return AskNone(switch (e.code) {
        'resource-exhausted' => AskWhyNot.tomorrow,
        'permission-denied' => AskWhyNot.plus,
        _ => AskWhyNot.later,
      }, detail: '${e.code}: ${e.message ?? ''}');
    } catch (error) {
      return AskNone(AskWhyNot.later, detail: '$error');
    }
  }

  /// What the server answered, read.
  static AskResult read(Object? data) {
    if (data is! Map) return const AskNone(AskWhyNot.later);
    final Object? text = data['text'];
    if (text is String && text.trim().isNotEmpty) return AskAnswer(text.trim());
    return AskNone(switch (data['none']) {
      'declined' => AskWhyNot.declined,
      'unavailable' => AskWhyNot.unavailable,
      _ => AskWhyNot.later,
    });
  }
}
