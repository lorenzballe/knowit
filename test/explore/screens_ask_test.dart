// Ask first (140e): a question in the reader's own words, read for the
// words that mean something and answered by the cards that hold the most of
// them; a card opened keeps the question with it; a question no card
// answers can be kept, and waits; the questions kept are listed with their
// cards, and can be forgotten. What was typed never reaches a note.
//
//   flutter test test/explore/screens_ask_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/screens/ask_first.dart';
import 'package:astuto/explore/blocks/screens/ask_search.dart';
import 'package:astuto/explore/blocks/screens/memory.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';

import 'fake_host.dart';
import 'screens_harness.dart';

/// A host that answers questions itself, as the server's search would.
class _Searching extends FakeExploreHost implements ScreensSearchHost {
  _Searching(super.app, this.answer);

  final List<Pill> answer;
  final List<String> asked = [];

  @override
  Future<List<Pill>?> search(String question) async {
    asked.add(question);
    return answer;
  }
}

/// Whatever a note says, it is never words: only counts and switches.
void _noWords(FakeExploreHost host) {
  for (final (_, _, Map<String, Object?> facts) in host.notes) {
    for (final Object? v in facts.values) {
      expect(v is String, isFalse, reason: '$facts');
    }
  }
}

void main() {
  setUpAll(loadScreensFonts);

  test('a question is read for the words that mean something', () {
    expect(askWords('Why do onions make you cry?'), ['onion', 'make', 'cry']);
    expect(askWords('Studies of studying'), ['study']);
    // A long word is kept to its first six letters, which is what lets
    // "accurate" meet "accuracy".
    expect(askWords('Is a 99% accurate test good?'), [
      '99%',
      'accura',
      'test',
      'good',
    ]);
    expect(askStem('accuracy'), askStem('accurate'));
    expect(askWords('Perché la Torre è così alta?'), ['torre', 'cosi', 'alta']);
    expect(askWords('the the THE'), isEmpty);
    expect(askStem('pollinators'), askStem('pollinating'));
  });

  test('the cards that answer hold the most of its rarest words', () {
    final List<Pill> found = askCards('Why do onions make you cry?');
    expect(
      found.take(3).any((p) => p.question.toLowerCase().contains('onion')),
      isTrue,
    );
    expect(askCards('qwzx vbnmq plokij'), isEmpty);
    expect(askCards(''), isEmpty);
    final List<Pill> limited = askCards('the history of war', limit: 2);
    expect(limited.length, lessThanOrEqualTo(2));
    // Kept to what may be shown: a subject, say.
    final List<Pill> art = askCards(
      'colour of paint',
      keep: (p) => p.topic == 'Art',
    );
    expect(art.every((p) => p.topic == 'Art'), isTrue);
  });

  testWidgets('a question asked shows the cards that answer it', (
    tester,
  ) async {
    final AppState app = await screensReader();
    final host = FakeExploreHost(app);
    await pumpBlock(
      tester,
      const AskFirstBlock(),
      screensSection('ask-first'),
      host,
    );
    await tester.enterText(
      find.byKey(const ValueKey('ask-field-x')),
      'Why do onions make you cry?',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
    expect(find.byKey(const ValueKey('ask-answers')), findsOneWidget);
    expect(find.textContaining('answer'), findsWidgets);
    final String opened = host.shown.first.$2;
    await tester.tap(find.byKey(ValueKey('explore-$opened')));
    expect(host.opened, [('x', opened)]);
    // Kept with the card that answered it.
    final AskedQuestion kept = ScreensMemory.instance.asked.single;
    expect(kept.question, 'Why do onions make you cry?');
    expect(kept.cardId, opened);
    expect(host.notes.map((n) => n.$2), everyElement('asked'));
    _noWords(host);
  });

  testWidgets('a question no card answers can be kept, and waits', (
    tester,
  ) async {
    final AppState app = await screensReader();
    final host = FakeExploreHost(app);
    await pumpBlock(
      tester,
      const AskFirstBlock(),
      screensSection('ask-first', {
        'style': {'asked': true},
      }),
      host,
    );
    await tester.enterText(
      find.byKey(const ValueKey('ask-field-x')),
      'qwzx vbnmq plokij',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
    expect(find.byKey(const ValueKey('ask-nothing')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ask-keep-x')));
    await settle(tester);
    expect(ScreensMemory.instance.asked.single.cardId, isNull);
    expect(find.text('Kept'), findsOneWidget);
    // The list under the answers shows it at once, waiting.
    expect(find.text('qwzx vbnmq plokij'), findsWidgets);
    expect(host.notes.last.$3['kept'], isTrue);
    _noWords(host);
  });

  testWidgets('a word to try is searched, and the field can be cleared', (
    tester,
  ) async {
    final AppState app = await screensReader();
    final host = FakeExploreHost(app);
    await pumpBlock(
      tester,
      const AskFirstBlock(),
      screensSection('ask-first', {
        'try': {
          'en': ['Oscar', 'Venice'],
          'it': ['Venezia'],
        },
      }),
      host,
    );
    await tester.tap(find.byKey(const ValueKey('ask-try-Oscar')));
    await settle(tester);
    expect(find.byKey(const ValueKey('ask-answers')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ask-clear-x')));
    await settle(tester);
    expect(find.byKey(const ValueKey('ask-answers')), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('ask-field-x')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('with no words of its own, it offers the first words its cards '
      'are filed under', (tester) async {
    final AppState app = await screensReader();
    final List<Pill> cards = PillBank.cards
        .where((p) => p.keywords.isNotEmpty && p.keywords.first.length <= 18)
        .take(3)
        .toList();
    final host = FakeExploreHost(app)..cards['x'] = cards;
    await pumpBlock(
      tester,
      const AskFirstBlock(),
      screensSection('ask-first'),
      host,
    );
    for (final Pill p in cards) {
      expect(find.byKey(ValueKey('ask-try-${p.keywords.first}')), findsWidgets);
    }
  });

  testWidgets('a host that can search is asked first', (tester) async {
    final AppState app = await screensReader();
    final Pill answer = PillBank.cards[7];
    final host = _Searching(app, [answer]);
    await pumpBlock(
      tester,
      const AskFirstBlock(),
      screensSection('ask-first'),
      host,
    );
    await tester.enterText(
      find.byKey(const ValueKey('ask-field-x')),
      'anything',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
    expect(host.asked, ['anything']);
    expect(find.byKey(ValueKey('explore-${answer.id}')), findsOneWidget);
  });

  testWidgets('the questions kept are listed with the cards that answered', (
    tester,
  ) async {
    final Pill card = PillBank.cards.first;
    final AppState app = await screensReader({
      'knowit.explore.screens.asked':
          '[{"q":"A question answered","c":"${card.id}"},'
          '{"q":"Why do onions make you cry?"},'
          '{"q":"qwzx vbnmq plokij"}]',
    });
    final host = FakeExploreHost(app);
    final bool drew = await pumpBlock(
      tester,
      const QuestionsAskedBlock(),
      screensSection('questions-asked'),
      host,
    );
    expect(drew, isTrue);
    expect(find.text('A question answered'), findsOneWidget);
    expect(find.byKey(ValueKey('explore-${card.id}')), findsOneWidget);
    // Kept with no answer, and answered now by the bank: shown answered.
    final Pill onion = answersOn(host, 'Why do onions make you cry?').first;
    expect(find.byKey(ValueKey('explore-${onion.id}')), findsOneWidget);
    // Kept with no answer, and still none.
    expect(find.text('qwzx vbnmq plokij'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('explore-${card.id}')));
    expect(host.opened, [('x', card.id)]);
  });

  testWidgets('a question held down is forgotten, and an undo brings it back', (
    tester,
  ) async {
    final AppState app = await screensReader({
      'knowit.explore.screens.asked':
          '[{"q":"First question"},{"q":"Second question"}]',
    });
    final host = FakeExploreHost(app);
    await pumpBlock(
      tester,
      const QuestionsAskedBlock(),
      screensSection('questions-asked'),
      host,
    );
    await tester.longPress(find.text('Second question'));
    await settle(tester);
    expect(find.text('Second question'), findsNothing);
    expect(ScreensMemory.instance.asked.map((q) => q.question), [
      'First question',
    ]);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(ScreensMemory.instance.asked.map((q) => q.question), [
      'First question',
      'Second question',
    ]);
  });

  testWidgets('with nothing kept, there is no shelf', (tester) async {
    final AppState app = await screensReader();
    final bool drew = await pumpBlock(
      tester,
      const QuestionsAskedBlock(),
      screensSection('questions-asked'),
      FakeExploreHost(app),
    );
    expect(drew, isFalse);
  });
}
