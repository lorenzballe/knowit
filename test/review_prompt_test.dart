import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/state/app_state.dart';

/// The store's rating sheet is asked for at the end of a seventh day in a
/// row, after the notification prompt has had its own day, and twice more
/// at most: at thirty and a hundred days read, a month after the last.
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

    // Asked, and not again for that week — not even after a restart.
    await state.notedReviewAsked();
    expect(state.shouldAskForReview, isFalse);
    final again = AppState();
    await again.init();
    expect(again.shouldAskForReview, isFalse);
    expect(again.reviewAsks, 1);
  });

  List<String> daysRead(int n) {
    final DateTime now = DateTime.now();
    return [
      for (int i = n - 1; i >= 0; i--)
        dateKey(DateTime(now.year, now.month, now.day - i)),
    ];
  }

  String daysAgo(int n) {
    final DateTime now = DateTime.now();
    return dateKey(DateTime(now.year, now.month, now.day - n));
  }

  test('asked again at thirty days read, a month after the first; then at a '
      'hundred; never a fourth time', () async {
    final Map<String, Object> closed = {
      'knowit.streak': 2,
      'knowit.lastCompletionDate': today,
      'knowit.pushAsked': true,
    };
    // Thirty days read, the first ask forty days ago: the second is due.
    final second = await app({
      ...closed,
      'knowit.completedDates': daysRead(30),
      'knowit.reviewAsks': 1,
      'knowit.reviewAskedOn': daysAgo(40),
    });
    expect(second.shouldAskForReview, isTrue);
    await second.notedReviewAsked();
    expect(second.shouldAskForReview, isFalse);
    expect(second.reviewAsks, 2);

    // Twenty-nine days read is short of it; so is a first ask ten days ago.
    expect(
      (await app({
        ...closed,
        'knowit.completedDates': daysRead(29),
        'knowit.reviewAsks': 1,
        'knowit.reviewAskedOn': daysAgo(40),
      })).shouldAskForReview,
      isFalse,
    );
    expect(
      (await app({
        ...closed,
        'knowit.completedDates': daysRead(30),
        'knowit.reviewAsks': 1,
        'knowit.reviewAskedOn': daysAgo(10),
      })).shouldAskForReview,
      isFalse,
    );

    // A hundred days read: the third. Then none, however long.
    expect(
      (await app({
        ...closed,
        'knowit.completedDates': daysRead(100),
        'knowit.reviewAsks': 2,
        'knowit.reviewAskedOn': daysAgo(31),
      })).shouldAskForReview,
      isTrue,
    );
    expect(
      (await app({
        ...closed,
        'knowit.completedDates': daysRead(300),
        'knowit.reviewAsks': 3,
        'knowit.reviewAskedOn': daysAgo(200),
      })).shouldAskForReview,
      isFalse,
    );
  });

  test('a build that kept only whether it asked counts one ask', () async {
    final state = await app({
      'knowit.streak': 7,
      'knowit.lastCompletionDate': today,
      'knowit.pushAsked': true,
      'knowit.reviewAsked': true,
    });
    expect(state.reviewAsks, 1);
    expect(state.shouldAskForReview, isFalse);
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
