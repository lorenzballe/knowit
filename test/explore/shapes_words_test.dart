// The shapes family's words, held to the checker's: what every block reads,
// as the app draws it, is what tool/remote/parts/explore_blocks/shapes.json
// says it reads — so a section the checker passes is one the app can draw,
// and a size or a signature added to a block is added to the checker too.
//
//   flutter test test/explore/shapes_words_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/explore_mix.dart';
import 'package:astuto/explore/blocks/shapes/kinds.dart';
import 'package:astuto/explore/blocks/shapes/vocabulary.dart';
import 'package:astuto/explore/catalogue.dart';
import 'package:astuto/l10n/app_localizations.dart';

import 'shapes_harness.dart';

void main() {
  final Map<String, Object?> words = jsonDecode(
    File('tool/remote/parts/explore_blocks/shapes.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final Map<String, Object?> checked = words['blocks']! as Map<String, Object?>;

  test('the checker knows every block, and no block it does not draw', () {
    expect(checked.keys.toSet(), {for (final b in shapeBlocks) b.name});
  });

  for (final b in shapeBlocks) {
    test('${b.name} reads what the checker says it reads', () {
      expect(
        jsonDecode(jsonEncode(b.words.toJson())),
        checked[b.name],
        reason:
            'shapes.json and ${b.name} disagree: write the block\'s words '
            '(ShapeVocabulary.toJson) into shapes.json, or change the block',
      );
    });
  }

  test('the kinds, the months and the languages are the app\'s', () {
    expect(words['kinds'], kShapeKinds);
    expect(words['subjects'], kMonthSubjects);
    expect(words['languages'], [
      for (final l in AppLocalizations.supportedLocales) l.languageCode,
    ]);
  });

  test('every name is the family\'s own, and the catalogue holds each', () {
    final Set<String> names = {};
    for (final b in shapeBlocks) {
      expect(b.name, startsWith('shape-'));
      expect(names.add(b.name), isTrue, reason: '${b.name} twice');
      // Another family's block of the same name would take this one's place
      // in the catalogue without a word.
      expect(identical(kExploreBlocks[b.name], b), isTrue, reason: b.name);
      expect(kShapeKinds, contains(b.words.kind));
      for (final s in b.words.signatures) {
        expect(kShapeSignatures, contains(s), reason: b.name);
      }
      expect(b.words.canvas, isNotEmpty);
      expect(b.words.fewest, inInclusiveRange(1, b.words.limit));
      expect(b.words.limit, inInclusiveRange(1, b.words.most));
    }
    expect(names.length, 34);
  });
}
