// The whole-screen blocks as a family: every one is in the catalogue under
// the name the server uses for it and the checker knows it by; every one
// draws at every size, on the smallest and the largest phone, at night and
// on paper, at a large text size, without a pixel spilling; and every one
// with nothing to show is left out, title and all.
//
//   flutter test test/explore/screens_blocks_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/screens_blocks.dart' as screens;
import 'package:astuto/explore/catalogue.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/models/pill.dart';

import 'fake_host.dart';
import 'screens_harness.dart';

/// What a bare section of [block] needs to have something to show: the
/// chains of whys are the section's own words, so they come from the
/// example screen; everything else draws from the bank.
Map<String, Object?> _enough(String block) {
  if (block != 'keep-asking') return const {};
  final Object? doc = jsonDecode(
    File('remote/examples/explore-keep-asking.json').readAsStringSync(),
  );
  final Map sections = ((doc as Map)['sections'] as List).first as Map;
  return {'chains': sections['chains']};
}

/// A question kept, for the shelf of questions asked.
const Map<String, Object> _asked = {
  'knowit.explore.screens.asked':
      '[{"q":"Why does the same coffee taste so different?"},'
      '{"q":"Is a 99% accurate test good news?","c":"medicine-false-positives-1"}]',
};

void main() {
  setUpAll(loadScreensFonts);

  test('every block of the family is in the catalogue, once, by its name', () {
    final List<String> names = [for (final b in screens.blocks) b.name];
    expect(names.toSet().length, names.length);
    for (final ExploreBlock b in screens.blocks) {
      expect(identical(kExploreBlocks[b.name], b), isTrue, reason: b.name);
    }
  });

  test('the checker knows every block the family draws, and no other', () {
    final String checker = File('tool/remote/parts/explore_blocks/screens.py')
        .readAsStringSync();
    final String table = checker.substring(checker.indexOf('BLOCKS: dict'));
    final Set<String> checked = {
      for (final RegExpMatch m in RegExp(
        r'"([a-z-]+)": check_',
      ).allMatches(table))
        m.group(1)!,
    };
    expect(checked, {for (final b in screens.blocks) b.name});
  });

  for (final ExploreBlock block in screens.blocks) {
    testWidgets('${block.name} draws at every size, phone, paper and text', (
      tester,
    ) async {
      final app = await screensReader(_asked);
      for (final String size in const ['s', 'm', 'l']) {
        for (final double width in const [375, 430]) {
          for (final bool paper in const [false, true]) {
            for (final double text in const [1, 1.6]) {
              final drew = await pumpBlock(
                tester,
                block,
                screensSection(block.name, {
                  'size': size,
                  ..._enough(block.name),
                }),
                FakeExploreHost(app),
                width: width,
                paper: paper,
                text: text,
              );
              expect(drew, isTrue, reason: '${block.name} $size $width');
              expect(tester.takeException(), isNull);
            }
          }
        }
      }
    });
  }

  testWidgets('with nothing to show, a block is left out', (tester) async {
    final app = await screensReader();
    // No cards at all, no chains, nothing asked: only the parts that need
    // no card — the field to ask in, the masthead, the edition's last line
    // — still have something to say.
    const Set<String> needNoCards = {'ask-first', 'masthead', 'edition-end'};
    for (final ExploreBlock block in screens.blocks) {
      final host = FakeExploreHost(app)..cards['x'] = const [];
      final drew = await pumpBlock(
        tester,
        block,
        screensSection(block.name),
        host,
      );
      expect(drew, needNoCards.contains(block.name), reason: block.name);
    }
  });

  testWidgets('every card a block draws is counted as seen, on its shelf', (
    tester,
  ) async {
    final app = await screensReader(_asked);
    // A chain of whys is the section's words until its bottom, where the
    // cards that go deeper are.
    const Set<String> showNoCards = {
      'ask-first',
      'masthead',
      'edition-end',
      'keep-asking',
    };
    for (final ExploreBlock block in screens.blocks) {
      final host = FakeExploreHost(app);
      await pumpBlock(
        tester,
        block,
        screensSection(block.name, _enough(block.name)),
        host,
      );
      expect(
        host.shown.isEmpty,
        showNoCards.contains(block.name),
        reason: block.name,
      );
      for (final (String section, String id) in host.shown) {
        // Noted under the section itself, never under the parts a block
        // asks its own cards for.
        expect(section, 'x', reason: block.name);
        expect(PillBank.byId(id), isNotNull, reason: block.name);
      }
    }
  });

  testWidgets('a section names a shelf in the reader\'s language', (
    tester,
  ) async {
    final app = await screensReader(_asked);
    const Set<String> headed = {
      'expert',
      'connect-dots',
      'questions-asked',
      'keep-asking',
      'through-time',
      'change-your-mind',
      'say-it-tonight',
    };
    for (final ExploreBlock block in screens.blocks) {
      if (!headed.contains(block.name)) continue;
      await pumpBlock(
        tester,
        block,
        screensSection(block.name, {
          'title': {'en': 'Tonight, in English', 'it': 'Stasera, in italiano'},
          'subtitle': 'One line for all',
          ..._enough(block.name),
        }),
        FakeExploreHost(app, language: 'it'),
        language: 'it',
      );
      expect(find.text('Stasera, in italiano'), findsOneWidget);
      expect(find.text('One line for all'), findsOneWidget);
      // The head can be left out, for a part of a screen that is not a
      // shelf of its own.
      await pumpBlock(
        tester,
        block,
        screensSection(block.name, {
          'title': 'A head',
          'style': {'head': false},
          ..._enough(block.name),
        }),
        FakeExploreHost(app),
      );
      expect(find.text('A head'), findsNothing, reason: block.name);
    }
  });

  testWidgets('an unknown size is the medium one, and never nothing', (
    tester,
  ) async {
    final app = await screensReader();
    for (final ExploreBlock block in screens.blocks) {
      final drew = await pumpBlock(
        tester,
        block,
        screensSection(block.name, {
          'size': 'huge',
          'style': {'mystery': 3},
          ..._enough(block.name),
        }),
        FakeExploreHost(app),
      );
      expect(
        drew || block.name == 'questions-asked',
        isTrue,
        reason: block.name,
      );
    }
  });

  testWidgets('the cards a block opens are the ones it showed', (tester) async {
    final app = await screensReader();
    final Pill card = bankWhere((p) => true).first;
    final host = FakeExploreHost(app)..cards['x'] = [card];
    await pumpBlock(
      tester,
      kExploreBlocks['front-lead']!,
      screensSection('front-lead'),
      host,
    );
    await tester.tap(find.byKey(ValueKey('explore-${card.id}')));
    expect(host.opened, [('x', card.id)]);
  });
}
