// The purpose family's words: the moves in English as the app names them
// everywhere else, and in every language every case its blocks ask for,
// so no block ever shows a bare key.
//
//   flutter test test/explore/purpose_strings_test.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/explore/blocks/purpose/life.dart';
import 'package:astuto/explore/blocks/purpose/move.dart';
import 'package:astuto/explore/blocks/purpose/read_or_do.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';

void main() {
  final List<AppLocalizations> all = [
    for (final Locale locale in AppLocalizations.supportedLocales)
      lookupAppLocalizations(locale),
  ];

  test('every language the app has', () {
    expect(all, hasLength(13));
  });

  test('the moves in English are the names and lines the app gives them', () {
    final AppLocalizations en = lookupAppLocalizations(const Locale('en'));
    for (final Principle m in kMoves) {
      expect(en.purposeMoveName(m.name), m.label, reason: m.name);
      expect(en.purposeMoveLine(m.name), m.oneLine, reason: m.name);
    }
  });

  test('every move, verb and part of life has words in every language', () {
    for (final AppLocalizations l in all) {
      final String lang = l.localeName;
      for (final Principle m in kMoves) {
        for (final String said in [
          l.purposeMoveName(m.name),
          l.purposeMoveLine(m.name),
          l.purposeMoveAsk(m.name),
        ]) {
          expect(said, isNot(m.name), reason: '$lang ${m.name}');
          expect(said.trim(), isNotEmpty, reason: '$lang ${m.name}');
        }
      }
      for (final CardVerb verb in CardVerb.values) {
        if (verb == CardVerb.read) continue;
        expect(
          l.purposeVerb(verb.name),
          isNot(verb.name),
          reason: '$lang $verb',
        );
      }
      for (final LifeTopic topic in kLifeTopics) {
        for (final String said in [
          l.purposeLifeAbout(topic.word),
          l.purposeLifeQuestion(topic.word),
          l.purposeLifeChip(topic.word),
        ]) {
          expect(said, isNot(topic.word), reason: '$lang ${topic.name}');
        }
      }
      for (int n = 1; n <= 5; n++) {
        expect(l.purposeKeepHeading('$n'), isNotEmpty, reason: '$lang $n');
      }
    }
  });

  test('counts read in every language, singular and plural', () {
    for (final AppLocalizations l in all) {
      for (final int n in [1, 2, 5, 21]) {
        // One may be written as a word; every other count as a figure.
        if (n > 1) expect(l.purposeMeMarked(n), contains('$n'));
        expect(l.purposeMeMarked(n), isNotEmpty);
        expect(l.purposeSetRead(n, 24), contains('$n'));
        expect(l.purposeOf(n, 24), allOf(contains('$n'), contains('24')));
      }
    }
  });
}
