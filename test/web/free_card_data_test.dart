import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/subject_icons.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/models/pill.dart';

/// A free card as the bundle carries it.
Map<String, Object?> _page({Map<String, Object?> web = const {}}) => {
  'id': 'medicine-polio-chips',
  'topic': 'medicine',
  'kind': 'page',
  'difficulty': 'medium',
  'principle': 'confounding',
  'question': 'Which group of children caught the most polio in 1954?',
  'answer': 'The children given salt water.',
  'move': 'Who picks a treatment can matter as much as the treatment.',
  'web': {
    'kit': 1,
    'touch': 'drags',
    'label': 'A table with three groups of children and ten chips to stake.',
    'html': '<article class="card" id="card"></article>',
    ...web,
  },
  'source': 'Francis et al., 1955',
};

void main() {
  group('a free card on disk', () {
    test('comes back from the app as it went in', () {
      final Map<String, Object?> raw = _page(web: {'ground': '#0b0b14'});
      final Pill pill = cardFromJson(raw);
      expect(pill.challenge, isA<PageJudged>());
      expect(pill.isGraded, isTrue);
      expect(pill.web!.touch, WebTouch.drags);
      expect(pill.web!.ground, const Color(0xff0b0b14));
      expect(pill.hasPage, isTrue);
      expect(kindOf(pill.challenge), 'page');
      expect(cardToJson(pill), {
        ...raw,
        'web': {
          'kit': 1,
          'touch': 'drags',
          'label':
              'A table with three groups of children and ten chips to stake.',
          'ground': '#0b0b14',
          'html': '<article class="card" id="card"></article>',
        },
      });
    });

    test('a page that marks nothing says so, and keeps saying so', () {
      final Pill pill = cardFromJson(_page(web: {'graded': false}));
      expect(pill.isGraded, isFalse);
      expect((cardToJson(pill)['web'] as Map)['graded'], isFalse);
    });

    test('any card may have a page; it keeps its own way of being marked', () {
      final Pill pill = cardFromJson({
        ..._page(),
        'kind': 'pickOne',
        'options': ['Vaccine', 'Salt water', 'Parents said no'],
        'correct': 1,
      });
      expect(pill.challenge, isA<PickOne>());
      expect(pill.hasPage, isTrue);
    });

    test('what the app could not draw is refused', () {
      expect(
        () => cardFromJson({..._page()}..remove('web')),
        throwsFormatException,
        reason: 'a page card without its page',
      );
      expect(
        () => cardFromJson(_page(web: {'html': ''})),
        throwsFormatException,
      );
      expect(
        () => cardFromJson(_page(web: {'touch': 'everything'})),
        throwsFormatException,
      );
      expect(
        () => cardFromJson(_page(web: {'ground': 'black'})),
        throwsFormatException,
      );
    });

    test('a page made with a later kit is read, kept, and never dealt', () {
      final Pill later = cardFromJson(
        _page(web: {'kit': kCardKit + 1, 'touch': 'something new'}),
      );
      expect(later.hasPage, isFalse);
      expect(later.needsLaterKit, isTrue);

      final Map<String, Object?> doc =
          jsonDecode(kEmbeddedBankForTest()) as Map<String, Object?>;
      final List<Object?> cards = [...doc['cards'] as List];
      cards.add({
        ..._page(web: {'kit': kCardKit + 1}),
        'id': 'medicine-later',
      });
      PillBank.adopt(BankBundle.parse(jsonEncode({...doc, 'cards': cards})));
      addTearDown(PillBank.reset);
      expect(PillBank.byId('medicine-later'), isNotNull);
      expect(PillBank.live.map((p) => p.id), contains('medicine-later'));
      expect(
        PillBank.cards.map((p) => p.id),
        isNot(contains('medicine-later')),
      );
    });
  });

  group('the kit and the app in step', () {
    test('the kit dresses each subject as the app does', () {
      final String kit = File('docs/cards/kit/astute-card.js')
          .readAsStringSync();
      final Map<String, List<String>> table = {
        for (final Match m in RegExp(
          r"(\w+): \['([^']+)', '(#[0-9A-Fa-f]{6})', '(#[0-9A-Fa-f]{6})', '(#[0-9A-Fa-f]{6})', '([^']*)'\]",
        ).allMatches(kit))
          m.group(1)!: [m.group(2)!, m.group(3)!, m.group(4)!, m.group(6)!],
      };
      expect(table.keys.toSet(), kTopics.keys.toSet());
      String hex(Color c) =>
          '#${(c.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}';
      for (final MapEntry<String, TopicStyle> e in kTopics.entries) {
        final List<String> row = table[e.key]!;
        expect(row[0], e.value.name, reason: e.key);
        expect(row[1].toLowerCase(), hex(e.value.color), reason: e.key);
        expect(row[2].toLowerCase(), hex(e.value.ink), reason: e.key);
        expect(row[3], kSubjectIcons[e.value.name], reason: e.key);
      }
    });

    test('the gate holds pages to the kit this build carries', () {
      final String pages = File('tool/cards/pages.py').readAsStringSync();
      expect(
        RegExp(
          r'^KIT_VERSION = (\d+)$',
          multiLine: true,
        ).firstMatch(pages)!.group(1),
        '$kCardKit',
      );
    });
  });
}

/// The bank the app ships with, as text.
String kEmbeddedBankForTest() {
  final String dart = File('lib/data/embedded_bank.dart').readAsStringSync();
  return dart.substring(dart.indexOf("r'''") + 4, dart.lastIndexOf("'''"));
}
