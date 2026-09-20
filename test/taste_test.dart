import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/state/app_state.dart';

/// What the app works out about a reader from what they did, never from
/// what they were asked: the taste from likes and throws, the level of a
/// subject from the judgements on it.
void main() {
  Future<AppState> appWith(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      ...prefs,
    });
    final app = AppState();
    await app.init();
    return app;
  }

  setUp(() {
    PillBank.reset();
  });

  group('The taste', () {
    test('is empty until the reader has held or thrown a card', () async {
      final app = await appWith({});
      expect(app.taste, isEmpty);
    });

    test('leans towards what was held and away from what was thrown', () async {
      final liked = PillBank.cards.firstWhere((p) => p.strand.isNotEmpty);
      final thrown = PillBank.cards.lastWhere(
        (p) => p.strand.isNotEmpty && p.genre != liked.genre,
      );
      final app = await appWith({
        'knowit.likedIds': [liked.id],
        'knowit.dislikedIds': [thrown.id],
      });
      final taste = app.taste;
      expect(taste['genre:${liked.genre}'], AppState.kTasteLean);
      expect(taste['strand:${liked.strand}'], AppState.kTasteLean);
      expect(taste['genre:${thrown.genre}'], -AppState.kTasteLean);
      expect(leanOf(liked, taste), greaterThan(1));
      expect(leanOf(thrown, taste), lessThan(1));
    });
  });

  group('The measured level', () {
    List<Map<String, Object>> judged(Iterable<String> ids, List<bool> right) =>
        [
          for (var i = 0; i < right.length; i++)
            {
              'c': 80,
              'k': right[i],
              'p': ids.elementAt(i),
              'd': '2026-09-${10 + i}',
            },
        ];

    test('keeps what the reader said until there is enough to go on', () async {
      final asks = PillBank.cards
          .where((p) => p.topic == 'Thinking' && p.isGraded)
          .map((p) => p.id)
          .toList();
      final app = await appWith({
        'knowit.topicLevels': jsonEncode({'thinking': 0, 'space': 2}),
        'knowit.judgements': jsonEncode(judged(asks, [true, true, true])),
      });
      expect(app.measuredLevels['thinking'], 0, reason: 'three is not enough');
      expect(app.measuredLevels['space'], 2);
    });

    test('is solid at three in four right, curious at two in five', () async {
      final asks = PillBank.cards
          .where((p) => p.topic == 'Thinking' && p.isGraded)
          .map((p) => p.id)
          .toList();
      final solid = await appWith({
        'knowit.judgements': jsonEncode(
          judged(asks, [true, true, true, false, true, true, true, true]),
        ),
      });
      expect(solid.measuredLevels['thinking'], 2);

      final curious = await appWith({
        'knowit.topicLevels': jsonEncode({'thinking': 2}),
        'knowit.judgements': jsonEncode(
          judged(asks, [false, false, true, false, false]),
        ),
      });
      expect(
        curious.measuredLevels['thinking'],
        0,
        reason: 'measured beats said',
      );

      // Only the most recent count: a bad start, then a run of right.
      final learned = await appWith({
        'knowit.judgements': jsonEncode(
          judged(asks, [false, false, false, false, ...List.filled(8, true)]),
        ),
      });
      expect(learned.measuredLevels['thinking'], 2);
    });
  });
}
