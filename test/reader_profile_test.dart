import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/daily.dart';
import 'package:astuto/data/genres.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/data/reader_profile.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/models/pill.dart';

/// Every subject at [at], as the wheel leaves it untouched.
Map<String, double> _even([double at = 1]) => {
  for (final key in kGenres.keys) key: at,
};

void main() {
  group('Reading the onboarding', () {
    test('a reader who moved nothing has told the app nothing', () {
      final p = ReaderProfile.read(weights: _even());
      expect(p.shape, ReaderShape.untold);
      expect(p.claimed, isEmpty);
      expect(p.lean, isEmpty);
      // Nobody starts as a beginner.
      expect(p.levels.values.toSet(), {1});
      expect(ReaderProfile.read(weights: const {}).shape, ReaderShape.untold);
    });

    test('a subject held at the top while the others came down is claimed '
        'and starts solid', () {
      final p = ReaderProfile.read(
        weights: {..._even(0.4), 'space': 1, 'history': 0.9},
      );
      expect(p.shape, ReaderShape.generalist);
      expect(p.claimed, {'space', 'history'});
      expect(p.levels['space'], 2);
      expect(p.levels['history'], 2);
      expect(p.levels['economics'], 1);
      expect(p.levels.values, everyElement(greaterThanOrEqualTo(1)));
    });

    test('four subjects or fewer is a specialist, and every one is chosen', () {
      final p = ReaderProfile.read(
        weights: const {'space': 1, 'science': 1, 'technology': 0.9},
      );
      expect(p.shape, ReaderShape.specialist);
      expect(p.claimed, {'space', 'science', 'technology'});
    });

    test('pruning inside a subject is expertise showing: claimed, and the '
        'strands kept in the pruned genre lean the draw', () {
      final Genre moon = kGenres['space']!.firstWhere(
        (g) => g.id == 'space.the_moon',
      );
      final String off = moon.strands.first.id;
      final p = ReaderProfile.read(weights: _even(0.8), strandsOff: {off});
      expect(p.claimed, contains('space'));
      expect(p.levels['space'], 2);
      for (final s in moon.strands.skip(1)) {
        expect(p.lean['strand:${s.id}'], ReaderProfile.pickedStrand);
      }
      expect(p.lean.containsKey('strand:$off'), isFalse);
      // The genres left whole in the pruned subject lean a little.
      expect(p.lean['genre:space.black_holes'], ReaderProfile.keptGenre);
      // Nothing leans in a subject nobody touched.
      expect(p.lean.keys.where((k) => k.contains('history.')), isEmpty);
    });

    test('the first three days lean to the top of the mix, then let go', () {
      final p = ReaderProfile.read(weights: {..._even(0.5), 'space': 1});
      final Map<String, double> mix = p.weights;
      double ratio(int day) {
        final w = p.weightsOn(day, mix);
        return w['space']! / w['economics']!;
      }

      expect(ratio(0), greaterThan(ratio(1)));
      expect(ratio(1), greaterThan(ratio(2)));
      expect(ratio(2), greaterThan(ratio(3)));
      expect(p.weightsOn(3, mix), mix);
      expect(p.weightsOn(40, mix), mix);
    });

    test('a reader who said nothing opens on the subjects that hook most '
        'people', () {
      final p = ReaderProfile.read(weights: _even());
      final w = p.weightsOn(0, const {});
      expect(w['psychology']!, greaterThan(w['economics']!));
      expect(w['space']!, greaterThan(w['sport']!));
      expect(p.weightsOn(3, const {}), isEmpty, reason: 'then even');
    });

    test('what the reader or the measurement said wins over the start', () {
      final p = ReaderProfile.read(weights: {..._even(0.4), 'space': 1});
      expect(p.levelsUnder(const {'space': 0})['space'], 0);
      expect(p.levelsUnder(const {})['space'], 2);
      expect(
        p.tasteWith(const {'hook:myth': 0.2}),
        containsPair('hook:myth', 0.2),
      );
    });
  });

  group('Dealt from the reading', () {
    setUp(resetCalendar);

    test('a claimed subject is asked hard before medium', () {
      final bank = PillBank.cards;
      int hardAsks(Map<String, int> levels) {
        var hard = 0;
        for (var d = 0; d < 40; d++) {
          final deal = dealDay(
            date: DateTime(2026, 10, 1).add(Duration(days: d)),
            topics: {'space'},
            weights: const {'space': 1},
            levels: levels,
            own: kPillsPerDay,
          );
          hard += deal.cards
              .where(
                (p) =>
                    p.topic == kTopics['space']!.name &&
                    p.asksSomething &&
                    p.difficulty == Difficulty.hard,
              )
              .length;
        }
        return hard;
      }

      expect(bank, isNotEmpty);
      expect(
        hardAsks(const {'space': 2}),
        greaterThan(hardAsks(const {'space': 0})),
      );
    });

    test('the cards at random keep to the reader\'s mix too', () {
      final day = DateTime(2026, 10, 14);
      const keys = {'nature', 'art', 'sport', 'thinking'};
      final wanted = {for (final k in keys) kTopics[k]!.name};
      for (var d = 0; d < 10; d++) {
        final deal = dealDay(
          date: day.add(Duration(days: d)),
          topics: keys,
        );
        final chance = deal.cards.where((p) => !deal.own.contains(p.id));
        expect(chance, hasLength(3));
        for (final p in chance) {
          expect(wanted, contains(p.topic), reason: p.id);
        }
      }
    });
  });
}
