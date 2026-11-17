/// The coach's note (coachWeek, functions/src/coach.ts), for Astute+: once a
/// week, three or four sentences about how the reader reasoned that week,
/// written by Claude from the numbers the phone counts and sends (the
/// journey's coachStats): numbers and a few names, never anything written.
library;

import 'package:cloud_functions/cloud_functions.dart';

import 'card_ask.dart';
import 'served.dart' show kFunctionsRegion;
import 'trace.dart';

/// How a note is asked for. Replaceable, so tests never reach the server.
typedef CoachCall =
    Future<AskResult> Function(
      String week,
      String language,
      Map<String, Object?> stats,
    );

abstract final class Coach {
  /// How the app asks: the callable function. Tests replace it.
  static CoachCall call = _callable;

  /// The notes already read in this run of the app, by week and language:
  /// the server keeps them too, so this only spares the trip.
  static final Map<String, String> kept = {};

  static Future<AskResult> _callable(
    String week,
    String language,
    Map<String, Object?> stats,
  ) => _ask(week, language, stats, again: true);

  static Future<AskResult> _ask(
    String week,
    String language,
    Map<String, Object?> stats, {
    required bool again,
  }) async {
    try {
      final result =
          await FirebaseFunctions.instanceFor(region: kFunctionsRegion)
              .httpsCallable(
                'coachWeek',
                options: HttpsCallableOptions(
                  timeout: const Duration(seconds: 60),
                ),
              )
              .call<Object?>({
                'week': week,
                'lang': language,
                'stats': stats,
              });
      return CardAsk.read(result.data);
    } on FirebaseFunctionsException catch (e) {
      // As with a card's answers: told Astute+ only while on it, the phone
      // says so, and asks once more.
      if (e.code == 'permission-denied' &&
          again &&
          Trace.instance.plus &&
          await Trace.instance.sayPresence()) {
        return _ask(week, language, stats, again: false);
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
}
