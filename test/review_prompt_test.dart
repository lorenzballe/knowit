import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/state/app_state.dart';

/// The store's rating sheet is asked for once, at the end of a seventh day
/// in a row, after the notification prompt has had its own day.
void main() {
  Future<AppState> app(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      ...prefs,
    });
    final state = AppState();
    await state.init();
    return state;
  }

  final String today = dateKey(DateTime.now());

  test('a seventh day in a row, just closed, is the moment', () async {
    final state = await app({
      'knowit.streak': 7,
      'knowit.lastCompletionDate': today,
      'knowit.pushAsked': true,
    });
    expect(state.shouldAskForReview, isTrue);

    // Asked once, never again — not even after a restart.
    await state.notedReviewAsked();
    expect(state.shouldAskForReview, isFalse);
    final again = AppState();
    await again.init();
    expect(again.shouldAskForReview, isFalse);
  });

  test('six days, an open day, or a notification prompt still to come '
      'is not', () async {
    expect(
      (await app({
        'knowit.streak': 6,
        'knowit.lastCompletionDate': today,
        'knowit.pushAsked': true,
      })).shouldAskForReview,
      isFalse,
    );
    final DateTime now = DateTime.now();
    expect(
      (await app({
        'knowit.streak': 7,
        'knowit.lastCompletionDate': dateKey(
          DateTime(now.year, now.month, now.day - 1),
        ),
        'knowit.pushAsked': true,
      })).shouldAskForReview,
      isFalse,
    );
    expect(
      (await app({'knowit.streak': 7, 'knowit.lastCompletionDate': today}))
          .shouldAskForReview,
      isFalse,
    );
  });
}
