// Keep asking why (141a): a chain of the section's own words, read in the
// reader's language with English under it; a why opens the next step,
// noted and remembered; at the bottom, how deep it went, where the answers
// come from, the cards that go further and the way back up; the other
// chains as rabbit holes.
//
//   flutter test test/explore/screens_whys_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/screens/keep_asking.dart';
import 'package:astuto/explore/blocks/screens/memory.dart';
import 'package:astuto/explore/explore_block.dart';

import 'fake_host.dart';
import 'screens_harness.dart';

Map<String, Object?> _step(String q, String a, {String? it}) => {
  'q': {'en': q, 'it': ?it},
  'a': a,
};

ExploreSection _section({
  List<String> deeper = const [],
  Map<String, Object?> more = const {},
}) => screensSection('keep-asking', {
  'chains': [
    {
      'id': 'sky',
      'subject': 'science',
      'source': 'Bohren and Clothiaux, 2006',
      'cards': deeper,
      'steps': [
        _step('Why is the sky blue?', 'Air scatters blue.', it: 'Perché?'),
        _step('Then why are sunsets red?', 'More air at sunset.'),
        _step('So why are clouds white?', 'Big droplets scatter all.'),
      ],
    },
    {
      'id': 'onions',
      'subject': 'food',
      'source': 'Imai and colleagues, 2002',
      'steps': [
        _step('Why do onions make you cry?', 'A gas.'),
        _step('Why would an onion make a gas?', 'A defence.'),
      ],
    },
  ],
  ...more,
});

void main() {
  setUpAll(loadScreensFonts);

  test('a chain is read in the reader\'s language, English under it', () {
    final chains = chainsOf(_section(), 'it');
    expect(chains.map((c) => c.id), ['sky', 'onions']);
    expect(chains.first.steps.first.$1, 'Perché?');
    expect(chains.first.steps[1].$1, 'Then why are sunsets red?');
    expect(chains.first.source, 'Bohren and Clothiaux, 2006');
  });

  test(
    'a chain without a source, a known subject or two steps is passed over',
    () {
      final chains = chainsOf(
        screensSection('keep-asking', {
          'chains': [
            {
              'id': 'a',
              'subject': 'science',
              'steps': [_step('Q?', 'A.'), _step('Q2?', 'A2.')],
            },
            {
              'id': 'b',
              'subject': 'astrology',
              'source': 'Somewhere, 2001',
              'steps': [_step('Q?', 'A.'), _step('Q2?', 'A2.')],
            },
            {
              'id': 'c',
              'subject': 'science',
              'source': 'Somewhere, 2001',
              'steps': [_step('Q?', 'A.')],
            },
            {
              'id': 'd',
              'subject': 'science',
              'source': 'Somewhere, 2001',
              'steps': [for (int i = 0; i < 12; i++) _step('Q$i?', 'A$i.')],
            },
          ],
        }),
        'en',
      );
      expect(chains.map((c) => c.id), ['d']);
      expect(chains.single.steps, hasLength(kMostWhys));
    },
  );

  testWidgets('without a chain there is nothing to draw', (tester) async {
    final app = await screensReader();
    expect(
      await pumpBlock(
        tester,
        const KeepAskingBlock(),
        screensSection('keep-asking'),
        FakeExploreHost(app),
      ),
      isFalse,
    );
  });

  testWidgets('a why opens the next step, noted and remembered', (
    tester,
  ) async {
    final app = await screensReader();
    final host = FakeExploreHost(app);
    await pumpBlock(tester, const KeepAskingBlock(), _section(), host);
    expect(find.text('Why is the sky blue?'), findsOneWidget);
    expect(find.text('Then why are sunsets red?'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('why-ask-sky')));
    await settle(tester);
    expect(find.text('Then why are sunsets red?'), findsOneWidget);
    expect(host.notes.last.$2, 'why');
    expect(host.notes.last.$3, {'chain': 'sky', 'depth': 2, 'of': 3});
    expect(ScreensMemory.instance.depth('x', 'sky'), 1);
    // The next visit opens where the reader left it.
    await pumpBlock(tester, const KeepAskingBlock(), _section(), host);
    expect(find.text('Then why are sunsets red?'), findsOneWidget);
  });

  testWidgets('the bottom says how deep, where from, and goes back up', (
    tester,
  ) async {
    final app = await screensReader();
    final List<String> deeper = [PillBank.cards[3].id, PillBank.cards[4].id];
    final host = FakeExploreHost(app);
    await pumpBlock(
      tester,
      const KeepAskingBlock(),
      _section(deeper: deeper),
      host,
    );
    // The cards that go further wait for the bottom.
    expect(find.byKey(ValueKey('explore-${deeper.first}')), findsNothing);
    for (int i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('why-ask-sky')));
      await settle(tester);
    }
    expect(find.byKey(const ValueKey('why-ask-sky')), findsNothing);
    expect(find.textContaining('3 whys deep'), findsOneWidget);
    expect(find.textContaining('Bohren and Clothiaux, 2006'), findsOneWidget);
    expect(find.byKey(ValueKey('explore-${deeper.first}')), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('explore-${deeper.first}')));
    expect(host.opened, [('x', deeper.first)]);
    expect(host.shown.map((s) => s.$2), containsAll(deeper));
    await tester.tap(find.byKey(const ValueKey('why-again-sky')));
    await settle(tester);
    expect(find.text('Then why are sunsets red?'), findsNothing);
    expect(host.notes.last.$2, 'why again');
    expect(ScreensMemory.instance.depth('x', 'sky'), 0);
  });

  testWidgets('another rabbit hole becomes the chain', (tester) async {
    final app = await screensReader();
    final host = FakeExploreHost(app);
    await pumpBlock(tester, const KeepAskingBlock(), _section(), host);
    expect(find.byKey(const ValueKey('why-hole-onions')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('why-hole-onions')));
    await settle(tester);
    expect(find.text('Why do onions make you cry?'), findsOneWidget);
    expect(find.byKey(const ValueKey('why-hole-sky')), findsOneWidget);
    expect(ScreensMemory.instance.pick('x'), 'onions');
    expect(host.notes.last.$2, 'chain picked');
  });

  testWidgets('the rabbit holes and the meter can be left out', (tester) async {
    final app = await screensReader();
    await pumpBlock(
      tester,
      const KeepAskingBlock(),
      _section(
        more: {
          'chain': 'onions',
          'style': {'holes': false, 'meter': false},
        },
      ),
      FakeExploreHost(app),
    );
    expect(find.text('Why do onions make you cry?'), findsOneWidget);
    expect(find.byKey(const ValueKey('why-hole-sky')), findsNothing);
    expect(find.bySemanticsLabel(RegExp('whys? of')), findsNothing);
  });
}
